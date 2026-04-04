import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:handwerker_app/core/utils/app_exception.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/repositories/order_repository.dart';
import 'package:handwerker_app/data/services/api_service.dart';

// ═══════════════════════════════════════════════════════════════
// SERVICE PROVIDERS
// ═══════════════════════════════════════════════════════════════

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final secureStorageProvider =
    Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

// ═══════════════════════════════════════════════════════════════
// AUTH STATE
// ═══════════════════════════════════════════════════════════════

enum AuthStatus { initial, authenticated, unauthenticated, loading, otpSent }

enum UserRole { customer, craftsman, admin }

class AuthState {
  final AuthStatus status;
  final UserRole? role;
  final String? userId;
  final String? phone;
  final bool requiresConsent;
  final bool profileComplete;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.role,
    this.userId,
    this.phone,
    this.requiresConsent = false,
    this.profileComplete = true,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserRole? role,
    String? userId,
    String? phone,
    bool? requiresConsent,
    bool? profileComplete,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        role: role ?? this.role,
        userId: userId ?? this.userId,
        phone: phone ?? this.phone,
        requiresConsent: requiresConsent ?? this.requiresConsent,
        profileComplete: profileComplete ?? this.profileComplete,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._api, this._storage) : super(const AuthState()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final token = await _storage.read(key: 'access_token');
    final role = await _storage.read(key: 'user_role');
    if (token != null && role != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        role: UserRole.values.firstWhere(
          (r) => r.name == role,
          orElse: () => UserRole.customer,
        ),
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(status: AuthStatus.loading, phone: phone);
    try {
      await _api.sendOtp(phone);
      print('✅ [AUTH] OTP sent successfully to $phone');
      state = state.copyWith(status: AuthStatus.otpSent);
    } catch (e) {
      print('❌ [AUTH] OTP send failed: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'OTP konnte nicht gesendet werden',
      );
    }
  }

  Future<void> verifyOtp(String code) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _api.verifyOtp(state.phone!, code);
      final Map<String, dynamic> data = response.data is Map 
          ? response.data 
          : {};
      
      print('🔑 [AUTH] VERIFY RESPONSE: $data');

      final authData = AuthTokenResponse.fromJson(data);

      if (authData.accessToken != null) {
        await _storage.write(key: 'access_token', value: authData.accessToken);
      }
      if (authData.refreshToken != null) {
        await _storage.write(key: 'refresh_token', value: authData.refreshToken);
      }

      // Try to find the role in various possible locations
      String? roleStr;
      if (data['role'] != null) {
        roleStr = data['role'].toString();
      } else if (data['user'] != null && data['user'] is Map && data['user']['role'] != null) {
        roleStr = data['user']['role'].toString();
      } else if (data['userRole'] != null) {
        roleStr = data['userRole'].toString();
      }
      
      roleStr = roleStr?.toLowerCase();
      print('🔑 [AUTH] EXTRACTED ROLE STRING: $roleStr');

      final role = UserRole.values.firstWhere(
        (r) => roleStr != null && (roleStr == r.name || roleStr.contains(r.name)),
        orElse: () {
          print('⚠️ [AUTH] Role not recognized, defaulting to CUSTOMER');
          return UserRole.customer;
        },
      );

      print('🔑 [AUTH] FINAL ROLE OBJECT: $role');
      await _storage.write(key: 'user_role', value: role.name);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        role: role,
        requiresConsent: authData.requiresConsent ?? false,
      );
    } catch (e) {
      print('❌ [AUTH] Verification error: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Ungültiger Code',
      );
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await _storage.read(key: 'refresh_token');
      if (refresh != null) await _api.logout(refresh);
    } finally {
      await _storage.deleteAll();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void setRole(UserRole role) {
    state = state.copyWith(role: role);
    _storage.write(key: 'user_role', value: role.name);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(secureStorageProvider),
  );
});

// ═══════════════════════════════════════════════════════════════
// CUSTOMER PROFILE
// ═══════════════════════════════════════════════════════════════

final customerProfileProvider =
    FutureProvider<CustomerProfile>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.getCustomerProfile();
  return CustomerProfile.fromJson(response.data);
});

// ═══════════════════════════════════════════════════════════════
// REPOSITORIES
// ═══════════════════════════════════════════════════════════════

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(apiServiceProvider));
});

// ═══════════════════════════════════════════════════════════════
// RESPONSE HELPER
// ═══════════════════════════════════════════════════════════════

/// Safely converts a raw Dio response body into a [PaginatedResponse<T>].
///
/// The backend may return:
///   • a paginated wrapper  →  `{"data": [...], "meta": {...}}`
///   • a plain JSON array   →  `[...]`
///
/// Both formats are handled transparently so providers never crash with
/// "type 'List<dynamic>' is not a subtype of type 'Map<String, dynamic>'".
PaginatedResponse<T> _parsePaginated<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw is List) {
    return PaginatedResponse<T>(
      data: raw.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
  return PaginatedResponse.fromJson(
    raw as Map<String, dynamic>,
    (json) => fromJson(json as Map<String, dynamic>),
  );
}

// ═══════════════════════════════════════════════════════════════
// SERVICE CATEGORIES
// ═══════════════════════════════════════════════════════════════

final serviceCategoriesProvider =
    FutureProvider<List<ServiceCategory>>((ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.fetchServiceCategories();
});

// ═══════════════════════════════════════════════════════════════
// ORDERS
// ═══════════════════════════════════════════════════════════════
//
// WHY non-family for ordersProvider?
// The old signature was FutureProvider.family<..., Map<String,dynamic>>.
// Dart's Map uses REFERENCE equality, so `{'page':0} != {'page':0}` when they
// are different object instances.  Every widget rebuild therefore created a
// brand-new provider state → a new HTTP request → an infinite fetch-loop:
//
//   build() → watch(ordersProvider(newMap)) → fetch starts
//   fetch completes → provider state changes → widget rebuilds
//   rebuild  → watch(ordersProvider(anotherNewMap)) → fetch starts  … ∞
//
// The fix: remove the Map family parameter.  ordersProvider is only ever
// called with {page:0, size:50} in the UI, so a plain autoDispose provider
// with those values hard-coded is both simpler and correct.

final ordersProvider =
    FutureProvider.autoDispose<PaginatedResponse<Order>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.listOrders(page: 0, size: 50);
  return _parsePaginated(response.data, Order.fromJson);
});

final activeOrdersProvider =
    FutureProvider.autoDispose<List<Order>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.listOrders();
  final paginated = _parsePaginated(response.data, Order.fromJson);
  return (paginated.data ?? []).where((o) => o.isActive).toList();
});

final orderDetailProvider =
    FutureProvider.autoDispose.family<Order, String>((ref, orderId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.getOrder(orderId);
  return Order.fromJson(response.data);
});

// ═══════════════════════════════════════════════════════════════
// PROPOSALS
// ═══════════════════════════════════════════════════════════════

final proposalsProvider =
    FutureProvider.family<List<Proposal>, String>((ref, orderId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.listProposals(orderId);
  // Backend may return a plain list OR a paginated envelope
  // { "data": [...], "meta": {...} } / { "content": [...] }
  final raw = response.data;
  final list = raw is List ? raw : (raw['data'] ?? raw['content'] ?? raw);
  return (list as List)
      .map((e) => Proposal.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ═══════════════════════════════════════════════════════════════
// CREATE ORDER FLOW
// ═══════════════════════════════════════════════════════════════

class CreateOrderState {
  final bool isLoading;
  final AppException? error;
  final Order? createdOrder;

  const CreateOrderState({
    this.isLoading = false,
    this.error,
    this.createdOrder,
  });

  CreateOrderState copyWith({
    bool? isLoading,
    AppException? error,
    Order? createdOrder,
    bool clearError = false,
  }) =>
      CreateOrderState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        createdOrder: createdOrder ?? this.createdOrder,
      );
}

class CreateOrderNotifier extends StateNotifier<CreateOrderState> {
  final OrderRepository _repository;

  CreateOrderNotifier(this._repository) : super(const CreateOrderState());

  /// Submit a new order to the backend.
  ///
  /// On success, [state.createdOrder] is populated.
  /// On failure, [state.error] is set to a typed [AppException].
  Future<void> submit(
    CreateOrderRequest request, {
    List<String>? mediaPaths,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final order = await _repository.createOrder(request, mediaPaths: mediaPaths);
      state = state.copyWith(isLoading: false, createdOrder: order);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: NetworkException(e.toString()),
      );
    }
  }

  void reset() => state = const CreateOrderState();
}

final createOrderProvider =
    StateNotifierProvider.autoDispose<CreateOrderNotifier, CreateOrderState>(
  (ref) => CreateOrderNotifier(ref.watch(orderRepositoryProvider)),
);

// ═══════════════════════════════════════════════════════════════
// CRAFTSMAN
// ═══════════════════════════════════════════════════════════════

/// Fetches the currently logged-in craftsman's own full profile.
final craftsmanMeProvider = FutureProvider<CraftsmanProfile>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.getCraftsmanMe();
  return CraftsmanProfile.fromJson(response.data as Map<String, dynamic>);
});

/// Fetches the craftsman's own assigned orders with enriched category info,
/// postleitzahl and pre-signed media URLs.
/// Endpoint: GET /craftsmen/me/orders
final craftsmanMyOrdersProvider =
    FutureProvider.autoDispose<List<CraftsmanOrderView>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.getCraftsmanOrders();
  final raw = response.data;
  final list = raw is List ? raw : (raw['data'] ?? raw['content'] ?? raw);
  return (list as List)
      .map((e) => CraftsmanOrderView.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Fetches open orders (MATCHING / PROPOSALS_RECEIVED) that match this
/// craftsman's service categories and geographic radius.
/// Endpoint: GET /craftsmen/me/available-orders  (enriched CraftsmanOrderView)
final availableOrdersProvider =
    FutureProvider.autoDispose<List<CraftsmanOrderView>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.getAvailableOrders();
  final raw = response.data;
  final list = raw is List ? raw : (raw['data'] ?? raw['content'] ?? raw);
  return (list as List)
      .map((e) => CraftsmanOrderView.fromJson(e as Map<String, dynamic>))
      .toList();
});

final craftsmanWalletProvider =
    FutureProvider<WalletBalance>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.getWallet();
  return WalletBalance.fromJson(response.data);
});

// ═══════════════════════════════════════════════════════════════
// NOTIFICATIONS
// ═══════════════════════════════════════════════════════════════

final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  try {
    final api = ref.watch(apiServiceProvider);
    final response = await api.listNotifications();
    final raw = response.data;
    // Backend may return { data: [...] } or a plain list
    final list = raw is Map ? (raw['data'] ?? raw['content'] ?? []) : raw;
    return (list as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    // Backend may not have implemented this endpoint yet (500 / 404).
    // Return empty list rather than propagating the error to the UI.
    // ignore: avoid_print
    print('⚠️ [NOTIFICATIONS] Could not load notifications: $e');
    return <AppNotification>[];
  }
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final notifications = await ref.watch(notificationsProvider.future);
  return notifications.where((n) => !n.isRead).length;
});

// ═══════════════════════════════════════════════════════════════
// THEME MODE
// ═══════════════════════════════════════════════════════════════

final themeModeProvider = StateProvider<bool>((ref) => true); // true = dark

// ═══════════════════════════════════════════════════════════════
// ADMIN
// ═══════════════════════════════════════════════════════════════
//
// IMPORTANT: Three design decisions prevent stale requests after logout:
//
//  1. `.autoDispose` – the provider is disposed as soon as no widget is
//     listening (i.e. when AdminShell unmounts on logout), so any in-flight
//     request is cancelled and no cached state leaks.
//
//  2. Enum family parameter instead of Map<String,dynamic> – Dart's Map uses
//     reference equality, so `{'status': null} != {'status': null}` (different
//     objects). That would create a brand-new provider instance – and a new
//     HTTP request – on every widget rebuild.  Nullable enums use value
//     equality, so Riverpod correctly reuses the cached provider state.
//
//  3. Auth guard – if the user is no longer authenticated/admin when the
//     provider executes (e.g. during the logout transition), it returns an
//     empty result instead of hitting the API.

final adminOrdersProvider =
    FutureProvider.autoDispose.family<PaginatedResponse<Order>, OrderStatus?>(
        (ref, status) async {
  final authState = ref.watch(authProvider);
  if (authState.status != AuthStatus.authenticated ||
      authState.role != UserRole.admin) {
    return PaginatedResponse(data: const [], meta: null);
  }

  final api = ref.watch(apiServiceProvider);
  final response = await api.adminListOrders(
    status: status?.name,
    page: 0,
    size: 20,
  );
  return _parsePaginated(response.data, Order.fromJson);
});

final adminCraftsmenProvider =
    FutureProvider.autoDispose
        .family<PaginatedResponse<CraftsmanProfile>, CraftsmanStatus?>(
        (ref, status) async {
  final authState = ref.watch(authProvider);
  if (authState.status != AuthStatus.authenticated ||
      authState.role != UserRole.admin) {
    return PaginatedResponse(data: const [], meta: null);
  }

  final api = ref.watch(apiServiceProvider);
  final response = await api.adminListCraftsmen(
    status: status?.name,
    page: 0,
    size: 20,
  );
  return _parsePaginated(response.data, CraftsmanProfile.fromJson);
});

final adminDisputesProvider =
    FutureProvider.autoDispose
        .family<PaginatedResponse<Dispute>, DisputeStatus?>(
        (ref, status) async {
  final authState = ref.watch(authProvider);
  if (authState.status != AuthStatus.authenticated ||
      authState.role != UserRole.admin) {
    return PaginatedResponse(data: const [], meta: null);
  }

  final api = ref.watch(apiServiceProvider);
  final response = await api.adminListDisputes(
    status: status?.name,
    page: 0,
    size: 20,
  );
  return _parsePaginated(response.data, Dispute.fromJson);
});

// ═══════════════════════════════════════════════════════════════
// CREATE CRAFTSMAN (Admin only)
// ═══════════════════════════════════════════════════════════════

class CreateCraftsmanState {
  final bool isLoading;
  final String? error;
  final CraftsmanProfile? created;

  const CreateCraftsmanState({
    this.isLoading = false,
    this.error,
    this.created,
  });

  CreateCraftsmanState copyWith({
    bool? isLoading,
    String? error,
    CraftsmanProfile? created,
    bool clearError = false,
  }) =>
      CreateCraftsmanState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        created: created ?? this.created,
      );
}

class CreateCraftsmanNotifier extends StateNotifier<CreateCraftsmanState> {
  final ApiService _api;

  CreateCraftsmanNotifier(this._api) : super(const CreateCraftsmanState());

  Future<void> submit(CreateCraftsmanRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.createCraftsman(request.toJson());
      final data = response.data;
      final profile = CraftsmanProfile.fromJson(
        data is Map<String, dynamic> ? data : data as Map<String, dynamic>,
      );
      state = state.copyWith(isLoading: false, created: profile);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void reset() => state = const CreateCraftsmanState();
}

final createCraftsmanProvider = StateNotifierProvider.autoDispose<
    CreateCraftsmanNotifier, CreateCraftsmanState>(
  (ref) => CreateCraftsmanNotifier(ref.watch(apiServiceProvider)),
);

// ═══════════════════════════════════════════════════════════════
// UPDATE CRAFTSMAN STATUS (Admin only)
// ═══════════════════════════════════════════════════════════════

class UpdateCraftsmanStatusState {
  final bool isLoading;
  final String? error;
  final CraftsmanProfile? updated;

  const UpdateCraftsmanStatusState({
    this.isLoading = false,
    this.error,
    this.updated,
  });

  UpdateCraftsmanStatusState copyWith({
    bool? isLoading,
    String? error,
    CraftsmanProfile? updated,
    bool clearError = false,
  }) =>
      UpdateCraftsmanStatusState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        updated: updated ?? this.updated,
      );
}

class UpdateCraftsmanStatusNotifier
    extends StateNotifier<UpdateCraftsmanStatusState> {
  final ApiService _api;

  UpdateCraftsmanStatusNotifier(this._api)
      : super(const UpdateCraftsmanStatusState());

  /// Calls PATCH /api/v1/craftsmen/{id}/status.
  /// Throws the backend message on a 422 invalid-transition response.
  Future<void> update(
    String craftsmanId,
    CraftsmanStatus newStatus, {
    String? reason,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.updateCraftsmanStatus(
        craftsmanId,
        newStatus.name.toUpperCase(),
        reason: reason,
      );
      final data = response.data;
      final profile = CraftsmanProfile.fromJson(
        data is Map<String, dynamic> ? data : data as Map<String, dynamic>,
      );
      state = state.copyWith(isLoading: false, updated: profile);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message'] as String? ??
              'Status konnte nicht geändert werden')
          : 'Status konnte nicht geändert werden';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const UpdateCraftsmanStatusState();
}

final updateCraftsmanStatusProvider = StateNotifierProvider.autoDispose<
    UpdateCraftsmanStatusNotifier, UpdateCraftsmanStatusState>(
  (ref) => UpdateCraftsmanStatusNotifier(ref.watch(apiServiceProvider)),
);

