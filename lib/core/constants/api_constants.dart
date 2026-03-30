import 'package:handwerker_app/core/constants/app_environment.dart';

/// API configuration and endpoint constants
class ApiConstants {
  ApiConstants._();

  // Base URL is injected at build time via --dart-define=API_BASE_URL=...
  // See AppEnvironment for defaults.
  static String get baseUrl => AppEnvironment.baseUrl;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Auth ──────────────────────────────────────────────────
  static const String sendOtp = '/auth/otp/send';
  static const String verifyOtp = '/auth/otp/verify';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String consent = '/auth/consent';

  // ── Customers ─────────────────────────────────────────────
  static const String customerMe = '/customers/me';

  // ── Craftsmen ─────────────────────────────────────────────
  static const String craftsmen = '/craftsmen';
  static String craftsmanById(String id) => '/craftsmen/$id';
  static String craftsmanStatus(String id) => '/craftsmen/$id/status';
  static const String craftsmanAvailability = '/craftsmen/me/availability';
  static const String craftsmanLocation = '/craftsmen/me/location';
  static const String craftsmanWallet = '/craftsmen/me/wallet';

  // ── Documents ─────────────────────────────────────────────
  static String craftsmanDocuments(String id) => '/craftsmen/$id/documents';
  static String reviewDocument(String craftsmanId, String docId) =>
      '/craftsmen/$craftsmanId/documents/$docId/review';

  // ── Service Categories ────────────────────────────────────
  static const String serviceCategories = '/service-categories';
  static String serviceCategoryById(String id) => '/service-categories/$id';

  // ── Orders ────────────────────────────────────────────────
  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';
  static String orderMedia(String id) => '/orders/$id/media';
  static String orderOnTheWay(String id) => '/orders/$id/on-the-way';
  static String orderConfirmArrival(String id) => '/orders/$id/confirm-arrival';
  static String orderStart(String id) => '/orders/$id/start';
  static String orderPriceRevision(String id) => '/orders/$id/price-revision';
  static String orderPriceRevisionAccept(String id) =>
      '/orders/$id/price-revision/accept';
  static String orderPriceRevisionReject(String id) =>
      '/orders/$id/price-revision/reject';
  static String orderComplete(String id) => '/orders/$id/complete';
  static String orderCustomerConfirm(String id) =>
      '/orders/$id/customer-confirm';
  static String orderCancel(String id) => '/orders/$id/cancel';

  // ── Proposals ─────────────────────────────────────────────
  static String orderProposals(String orderId) => '/orders/$orderId/proposals';
  static String acceptProposal(String orderId) =>
      '/orders/$orderId/proposals/accept';
  static String rejectProposal(String orderId, String proposalId) =>
      '/orders/$orderId/proposals/$proposalId/reject';

  // ── Payments ──────────────────────────────────────────────
  static String orderPayment(String orderId) => '/orders/$orderId/payment';
  static const String craftsmanPayouts = '/craftsmen/me/payouts';

  // ── Ratings ───────────────────────────────────────────────
  static String orderRating(String orderId) => '/orders/$orderId/rating';

  // ── Disputes ──────────────────────────────────────────────
  static String orderDispute(String orderId) => '/orders/$orderId/dispute';
  static String disputeRespond(String orderId) =>
      '/orders/$orderId/dispute/respond';
  static String disputeResolve(String orderId) =>
      '/orders/$orderId/dispute/resolve';

  // ── Chat ──────────────────────────────────────────────────
  static String orderMessages(String orderId) => '/orders/$orderId/messages';

  // ── Notifications ─────────────────────────────────────────
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';

  // ── Admin ─────────────────────────────────────────────────
  static const String adminOrders = '/admin/orders';
  static String adminForceClose(String id) => '/admin/orders/$id/force-close';
  static const String adminDisputes = '/admin/disputes';
  static const String adminCraftsmen = '/admin/craftsmen';
}

class AppConstants {
  AppConstants._();

  static const int otpLength = 6;
  static const int otpExpirySeconds = 300;
  static const int maxOtpRetries = 3;
  static const int lockoutMinutes = 15;
  static const int accessTokenLifetimeSeconds = 900;
  static const int refreshTokenLifetimeDays = 30;
  static const int maxMediaFiles = 5;
  static const int maxPhotoSizeMB = 10;
  static const int maxVideoSeconds = 60;
  static const int maxAudioSeconds = 120;
  static const int maxDescriptionChars = 1000;
  static const int maxReviewChars = 300;
  static const double minPayoutAmount = 10.0;
  static const int proposalExpiryMinutes = 30;
  static const int customerConfirmMinutes = 30;
  static const int disputeWindowHours = 48;
  static const int ratingExpiryHours = 48;
}
