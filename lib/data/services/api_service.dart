import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:handwerker_app/core/constants/api_constants.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,  // reads AppEnvironment.baseUrl at runtime
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage, _dio),
      _LoggingInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  // ── Auth ──────────────────────────────────────────────────
  Future<Response> sendOtp(String phone) => _dio.post(
        ApiConstants.sendOtp,
        data: {'phone': phone},
        options: Options(extra: {'noAuth': true}),
      );

  Future<Response> verifyOtp(String phone, String code) => _dio.post(
        ApiConstants.verifyOtp,
        data: {'phone': phone, 'code': code},
        options: Options(extra: {'noAuth': true}),
      );

  Future<Response> refreshToken(String token) => _dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': token},
        options: Options(extra: {'noAuth': true}),
      );

  Future<void> logout(String refreshToken) => _dio.post(
        ApiConstants.logout,
        data: {'refreshToken': refreshToken},
      );

  Future<void> recordConsent({
    required bool terms,
    required bool privacy,
    required bool dataProcessing,
  }) =>
      _dio.post(ApiConstants.consent, data: {
        'termsAccepted': terms,
        'privacyAccepted': privacy,
        'dataProcessingAccepted': dataProcessing,
      });

  // ── Customer ──────────────────────────────────────────────
  Future<Response> getCustomerProfile() =>
      _dio.get(ApiConstants.customerMe);

  Future<Response> updateCustomerProfile(Map<String, dynamic> data) =>
      _dio.put(ApiConstants.customerMe, data: data);

  Future<void> deleteCustomerAccount() =>
      _dio.delete(ApiConstants.customerMe);

  // ── Craftsman ─────────────────────────────────────────────
  Future<Response> getCraftsmanProfile(String id) =>
      _dio.get(ApiConstants.craftsmanById(id));

  Future<Response> updateAvailability(bool isOnline) =>
      _dio.patch(ApiConstants.craftsmanAvailability,
          data: {'isOnline': isOnline});

  Future<void> updateLocation(double lat, double lng) =>
      _dio.patch(ApiConstants.craftsmanLocation,
          data: {'latitude': lat, 'longitude': lng});

  Future<Response> getWallet() =>
      _dio.get(ApiConstants.craftsmanWallet);

  // ── Service Categories ────────────────────────────────────
  // NOTE: this endpoint requires a valid Bearer token (403 if missing)
  Future<Response> getServiceCategories() =>
      _dio.get(ApiConstants.serviceCategories);

  // ── Orders ────────────────────────────────────────────────
  Future<Response> createOrder(Map<String, dynamic> data) =>
      _dio.post(ApiConstants.orders, data: data);

  Future<Response> listOrders({String? status, int page = 0, int size = 20}) =>
      _dio.get(ApiConstants.orders, queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'size': size,
      });

  Future<Response> getOrder(String id) =>
      _dio.get(ApiConstants.orderById(id));

  Future<Response> markOnTheWay(String orderId) =>
      _dio.post(ApiConstants.orderOnTheWay(orderId));

  Future<Response> confirmArrival(String orderId) =>
      _dio.post(ApiConstants.orderConfirmArrival(orderId));

  Future<Response> startJob(String orderId) =>
      _dio.post(ApiConstants.orderStart(orderId));

  Future<Response> requestPriceRevision(
          String orderId, double newPrice, String reason) =>
      _dio.post(ApiConstants.orderPriceRevision(orderId),
          data: {'newPrice': newPrice, 'reason': reason});

  Future<Response> acceptPriceRevision(String orderId) =>
      _dio.post(ApiConstants.orderPriceRevisionAccept(orderId));

  Future<Response> completeOrder(
          String orderId, double finalPrice, String? notes) =>
      _dio.post(ApiConstants.orderComplete(orderId),
          data: {'finalPrice': finalPrice, 'notes': notes});

  Future<Response> customerConfirmOrder(
          String orderId, int? rating, String? review) =>
      _dio.post(ApiConstants.orderCustomerConfirm(orderId),
          data: {'rating': rating, 'review': review});

  Future<Response> cancelOrder(String orderId, String reason) =>
      _dio.post(ApiConstants.orderCancel(orderId), data: {'reason': reason});

  // ── Proposals ─────────────────────────────────────────────
  Future<Response> listProposals(String orderId) =>
      _dio.get(ApiConstants.orderProposals(orderId));

  Future<Response> submitProposal(
    String orderId, {
    required double price,
    required int etaMinutes,
    String? comment,
  }) =>
      _dio.post(ApiConstants.orderProposals(orderId), data: {
        'price': price,
        'etaMinutes': etaMinutes,
        if (comment != null) 'comment': comment,
      });

  Future<Response> acceptProposal(String orderId, String proposalId) =>
      _dio.post(ApiConstants.acceptProposal(orderId),
          data: {'proposalId': proposalId});

  // ── Payments ──────────────────────────────────────────────
  Future<Response> getPayment(String orderId) =>
      _dio.get(ApiConstants.orderPayment(orderId));

  Future<Response> listPayouts({int page = 0, int size = 20}) =>
      _dio.get(ApiConstants.craftsmanPayouts,
          queryParameters: {'page': page, 'size': size});

  Future<Response> requestPayout(double amount) =>
      _dio.post(ApiConstants.craftsmanPayouts, data: {'amount': amount});

  // ── Ratings ───────────────────────────────────────────────
  Future<Response> submitRating(String orderId, Map<String, dynamic> data) =>
      _dio.post(ApiConstants.orderRating(orderId), data: data);

  // ── Disputes ──────────────────────────────────────────────
  Future<Response> openDispute(String orderId, String description,
          {List<String>? mediaUrls}) =>
      _dio.post(ApiConstants.orderDispute(orderId), data: {
        'description': description,
        if (mediaUrls != null) 'mediaUrls': mediaUrls,
      });

  Future<Response> getDispute(String orderId) =>
      _dio.get(ApiConstants.orderDispute(orderId));

  // ── Chat ──────────────────────────────────────────────────
  Future<Response> listMessages(String orderId,
          {int page = 0, int size = 50}) =>
      _dio.get(ApiConstants.orderMessages(orderId),
          queryParameters: {'page': page, 'size': size});

  Future<Response> sendMessage(String orderId,
          {String? text, String? mediaUrl}) =>
      _dio.post(ApiConstants.orderMessages(orderId), data: {
        if (text != null) 'text': text,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
      });

  // ── Notifications ─────────────────────────────────────────
  Future<Response> listNotifications(
          {bool unreadOnly = false, int page = 0, int size = 30}) =>
      _dio.get(ApiConstants.notifications, queryParameters: {
        'unreadOnly': unreadOnly,
        'page': page,
        'size': size,
      });

  Future<void> markNotificationRead(String id) =>
      _dio.patch(ApiConstants.notificationRead(id));

  Future<void> markAllNotificationsRead() =>
      _dio.patch(ApiConstants.notificationsReadAll);

  // ── Admin ─────────────────────────────────────────────────
  Future<Response> adminListOrders({String? status, String? customerId, String? craftsmanId, int page = 0, int size = 20}) =>
      _dio.get(ApiConstants.adminOrders, queryParameters: {
        if (status != null) 'status': status,
        if (customerId != null) 'customerId': customerId,
        if (craftsmanId != null) 'craftsmanId': craftsmanId,
        'page': page,
        'size': size,
      });

  Future<Response> adminListCraftsmen({String? status, int page = 0, int size = 20}) =>
      _dio.get(ApiConstants.adminCraftsmen, queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'size': size,
      });

  Future<Response> adminListDisputes({String? status, int page = 0, int size = 20}) =>
      _dio.get(ApiConstants.adminDisputes, queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'size': size,
      });

  Future<Response> updateCraftsmanStatus(String id, String status, {String? reason}) =>
      _dio.patch(ApiConstants.craftsmanStatus(id), data: {
        'status': status,
        if (reason != null) 'reason': reason,
      });

  Future<Response> resolveDispute(String orderId, String resolution) =>
      _dio.post(ApiConstants.disputeResolve(orderId), data: {
        'resolution': resolution,
      });

  Future<Response> createCraftsman(Map<String, dynamic> data) =>
      _dio.post(ApiConstants.craftsmen, data: data);
}

// ═══════════════════════════════════════════════════════════════
// AUTH INTERCEPTOR
// ═══════════════════════════════════════════════════════════════

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['noAuth'] == true) {
      return handler.next(options);
    }

    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // ── 403 Forbidden ─────────────────────────────────────────
    if (err.response?.statusCode == 403) {
      return handler.next(err);
    }

    // ── 401 Unauthorized ─────────────────────────────────────
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _storage.read(key: 'refresh_token');
        if (refreshToken == null) {
          // No refresh token (user already logged out) – clear any residual
          // credentials and let the error propagate so the router redirects.
          await _storage.deleteAll();
          return handler.next(err);
        }

        final response = await _dio.post(
          ApiConstants.refreshToken,
          data: {'refreshToken': refreshToken},
          options: Options(extra: {'noAuth': true}),
        );

        final newAccessToken = response.data['accessToken'];
        final newRefreshToken = response.data['refreshToken'];

        await _storage.write(key: 'access_token', value: newAccessToken);
        await _storage.write(key: 'refresh_token', value: newRefreshToken);

        // Retry the failed request with the new token
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(opts);
        return handler.resolve(retryResponse);
      } catch (e) {
        // Token refresh failed – clear credentials; router will redirect to login
        await _storage.deleteAll();
      } finally {
        // Always reset so future requests can attempt a refresh again.
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // In debug: log request method, url, body
    // ignore: avoid_print
    print('🌐 [REQUEST] ${options.method} ${options.path}');
    // ignore: avoid_print
    print('   Full URL: ${options.baseUrl}${options.path}');
    if (options.data != null) {
      // ignore: avoid_print
      print('   Data: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // In debug: log status code
    // ignore: avoid_print
    print('✅ [RESPONSE] ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // In debug: log error
    // ignore: avoid_print
    print('❌ [ERROR] ${err.type} - ${err.message}');
    // ignore: avoid_print
    print('   ${err.requestOptions.method} ${err.requestOptions.path}');
    if (err.response != null) {
      // ignore: avoid_print
      print('   Status: ${err.response?.statusCode}');
      // ignore: avoid_print
      print('   Response: ${err.response?.data}');
    }
    handler.next(err);
  }
}
