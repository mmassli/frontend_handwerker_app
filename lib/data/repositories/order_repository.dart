import 'package:dio/dio.dart';
import 'package:handwerker_app/core/utils/app_exception.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/services/api_service.dart';

/// Repository layer for service-category and order operations.
///
/// Wraps [ApiService] calls, maps [DioException] to typed [AppException]
/// subclasses, and performs all JSON deserialization in one place.
class OrderRepository {
  final ApiService _api;

  OrderRepository(this._api);

  // ── Service Categories ──────────────────────────────────────

  /// Fetches all active service categories.
  /// Returns real UUID [ServiceCategory.id] values from the backend.
  Future<List<ServiceCategory>> fetchServiceCategories() async {
    try {
      final response = await _api.getServiceCategories();
      final raw = response.data;
      final list = raw is List ? raw : (raw['data'] ?? raw['content'] ?? raw);
      return (list as List)
          .map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Orders ─────────────────────────────────────────────────

  /// Creates a new order.
  ///
  /// Sends the exact DTO expected by POST /api/v1/orders:
  ///   { serviceCategoryId, requestType, descriptionText, lat, lng,
  ///     addressEncrypted, scheduledAt }
  ///
  /// [mediaPaths] are optional local file paths that are uploaded as
  /// multipart media parts alongside the order JSON.
  Future<Order> createOrder(
    CreateOrderRequest request, {
    List<String>? mediaPaths,
  }) async {
    // Validate before sending
    if (request.lat.isNaN || request.lng.isNaN) {
      throw const ValidationException(
        errors: {'location': 'Ungültige GPS-Koordinaten.'},
      );
    }
    if (request.requestType == RequestType.scheduled &&
        request.scheduledAt == null) {
      throw const ValidationException(
        errors: {'scheduledAt': 'Bitte wählen Sie einen Termin.'},
      );
    }

    try {
      final response = await _api.createOrder(request.toJson(), mediaPaths: mediaPaths);
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Error Mapping ───────────────────────────────────────────

  AppException _mapDioException(DioException e) {
    if (e.response == null) {
      return NetworkException(e.message ?? 'Keine Verbindung zum Server.');
    }

    final status = e.response!.statusCode ?? 0;
    final data = e.response!.data;

    // Helper: extract string from data map
    String? str(String key) {
      if (data is Map) return data[key]?.toString();
      return null;
    }

    switch (status) {
      case 401:
        return const UnauthorizedException();

      case 403:
        return const ForbiddenException();

      case 404:
        return NotFoundException(
          detail: str('detail') ?? str('message') ??
              'Ressource nicht gefunden (404).',
        );

      case 400:
      case 422:
        final errors = <String, String>{};
        if (data is Map && data['errors'] is Map) {
          (data['errors'] as Map).forEach(
            (k, v) => errors[k.toString()] = v.toString(),
          );
        }
        return ValidationException(
          errors: errors,
          detail: str('message') ?? str('detail'),
        );

      default:
        return ServerException(
          statusCode: status,
          message: str('message'),
        );
    }
  }
}


