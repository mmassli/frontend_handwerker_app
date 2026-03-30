import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:handwerker_app/data/models/models.dart';
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

enum AuthStatus { initial, authenticated, unauthenticated, loading }

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
    // _storage.deleteAll(); // Uncomment this line, run the app once, then comment it back.
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
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
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
      final authData = AuthTokenResponse.fromJson(response.data);

      await _storage.write(
          key: 'access_token', value: authData.accessToken);
      await _storage.write(
          key: 'refresh_token', value: authData.refreshToken);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        role: UserRole.customer, // Determined by backend
        requiresConsent: authData.requiresConsent ?? false,
      );
    } catch (e) {
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
// SERVICE CATEGORIES
// ═══════════════════════════════════════════════════════════════

final serviceCategoriesProvider =
    FutureProvider<List<ServiceCategory>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.getServiceCategories();
  return (response.data as List)
      .map((e) => ServiceCategory.fromJson(e))
      .toList();
});

// ═══════════════════════════════════════════════════════════════
// ORDERS
// ═══════════════════════════════════════════════════════════════

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(apiServiceProvider));
});

// ═══════════════════════════════════════════════════════════════
// RESPONSE HELPER
// ═══════════════════════════════════════════════════════════════

/// Safely converts a raw Dio response body into a [PaginatedResponse<T>].
/// Handles both `{"data":[...]}` wrapper and plain `[...]` array responses.
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
  return (response.data as List)
      .map((e) => Proposal.fromJson(e))
      .toList();
});

// ═══════════════════════════════════════════════════════════════
// CRAFTSMAN
// ═══════════════════════════════════════════════════════════════

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
  final api = ref.watch(apiServiceProvider);
  final response = await api.listNotifications();
  final data = response.data['data'] as List;
  return data.map((e) => AppNotification.fromJson(e)).toList();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final notifications = await ref.watch(notificationsProvider.future);
  return notifications.where((n) => !n.isRead).length;
});

// ═══════════════════════════════════════════════════════════════
// THEME MODE
// ═══════════════════════════════════════════════════════════════

final themeModeProvider = StateProvider<bool>((ref) => true); // true = dark
