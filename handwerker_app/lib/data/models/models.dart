import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

// ═══════════════════════════════════════════════════════════════
// AUTH MODELS
// ═══════════════════════════════════════════════════════════════

@JsonSerializable()
class SendOtpRequest {
  final String phone;
  SendOtpRequest({required this.phone});
  factory SendOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$SendOtpRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SendOtpRequestToJson(this);
}

@JsonSerializable()
class SendOtpResponse {
  final String? message;
  final int? expiresInSeconds;
  final int? retriesRemaining;
  SendOtpResponse({this.message, this.expiresInSeconds, this.retriesRemaining});
  factory SendOtpResponse.fromJson(Map<String, dynamic> json) =>
      _$SendOtpResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SendOtpResponseToJson(this);
}

@JsonSerializable()
class VerifyOtpRequest {
  final String phone;
  final String code;
  VerifyOtpRequest({required this.phone, required this.code});
  factory VerifyOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpRequestFromJson(json);
  Map<String, dynamic> toJson() => _$VerifyOtpRequestToJson(this);
}

@JsonSerializable()
class AuthTokenResponse {
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final bool? isNewUser;
  final bool? requiresConsent;
  AuthTokenResponse({
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.isNewUser,
    this.requiresConsent,
  });
  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthTokenResponseToJson(this);
}

// ═══════════════════════════════════════════════════════════════
// ADDRESS
// ═══════════════════════════════════════════════════════════════

@JsonSerializable()
class Address {
  final String? street;
  final String? city;
  final String? postalCode;
  final String? country;
  final double? latitude;
  final double? longitude;

  Address({
    this.street,
    this.city,
    this.postalCode,
    this.country,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);

  String get displayShort => [city, postalCode].whereType<String>().join(', ');
  String get displayFull =>
      [street, postalCode, city, country].whereType<String>().join(', ');
}

// ═══════════════════════════════════════════════════════════════
// CUSTOMER
// ═══════════════════════════════════════════════════════════════

@JsonSerializable()
class CustomerProfile {
  final String? id;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? email;
  final Address? address;
  final bool? profileComplete;
  final DateTime? gdprConsentAt;
  final DateTime? createdAt;

  CustomerProfile({
    this.id,
    this.phone,
    this.firstName,
    this.lastName,
    this.email,
    this.address,
    this.profileComplete,
    this.gdprConsentAt,
    this.createdAt,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) =>
      _$CustomerProfileFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerProfileToJson(this);

  String get displayName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  bool get isComplete =>
      firstName != null &&
      lastName != null &&
      address?.street != null;
}

// ═══════════════════════════════════════════════════════════════
// CRAFTSMAN
// ═══════════════════════════════════════════════════════════════

enum CraftsmanStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('VERIFIED')
  verified,
  @JsonValue('ACTIVE')
  active,
  @JsonValue('INACTIVE')
  inactive,
  @JsonValue('SUSPENDED')
  suspended,
  @JsonValue('DEACTIVATED')
  deactivated,
}

@JsonSerializable()
class CraftsmanProfile {
  final String? id;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? email;
  final CraftsmanStatus? status;
  final List<ServiceCategory>? serviceCategories;
  final double? radiusKm;
  final double? ratingAvg;
  final int? completedJobsCount;
  final Address? address;
  final double? walletBalance;
  final DateTime? createdAt;

  CraftsmanProfile({
    this.id,
    this.phone,
    this.firstName,
    this.lastName,
    this.email,
    this.status,
    this.serviceCategories,
    this.radiusKm,
    this.ratingAvg,
    this.completedJobsCount,
    this.address,
    this.walletBalance,
    this.createdAt,
  });

  factory CraftsmanProfile.fromJson(Map<String, dynamic> json) =>
      _$CraftsmanProfileFromJson(json);
  Map<String, dynamic> toJson() => _$CraftsmanProfileToJson(this);

  String get displayName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  bool get isOnline => status == CraftsmanStatus.active;
}

@JsonSerializable()
class CraftsmanPublicSummary {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? profilePhotoUrl;
  final double? ratingAvg;
  final int? completedJobsCount;
  final double? distanceKm;

  CraftsmanPublicSummary({
    this.id,
    this.firstName,
    this.lastName,
    this.profilePhotoUrl,
    this.ratingAvg,
    this.completedJobsCount,
    this.distanceKm,
  });

  factory CraftsmanPublicSummary.fromJson(Map<String, dynamic> json) =>
      _$CraftsmanPublicSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$CraftsmanPublicSummaryToJson(this);

  String get displayName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}

@JsonSerializable()
class WalletBalance {
  final double? balance;
  final String? currency;
  final double? pendingAmount;

  WalletBalance({this.balance, this.currency, this.pendingAmount});
  factory WalletBalance.fromJson(Map<String, dynamic> json) =>
      _$WalletBalanceFromJson(json);
  Map<String, dynamic> toJson() => _$WalletBalanceToJson(this);
}

// ═══════════════════════════════════════════════════════════════
// DOCUMENTS
// ═══════════════════════════════════════════════════════════════

enum DocumentType {
  @JsonValue('TRADE_LICENCE')
  tradeLicence,
  @JsonValue('INSURANCE_CERTIFICATE')
  insuranceCertificate,
  @JsonValue('IDENTITY_DOCUMENT')
  identityDocument,
}

enum DocumentStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('APPROVED')
  approved,
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('EXPIRED')
  expired,
}

@JsonSerializable()
class CraftsmanDocument {
  final String? id;
  final String? craftsmanId;
  final DocumentType? type;
  final String? fileUrl;
  final DocumentStatus? status;
  final String? expiryDate;
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final DateTime? uploadedAt;

  CraftsmanDocument({
    this.id,
    this.craftsmanId,
    this.type,
    this.fileUrl,
    this.status,
    this.expiryDate,
    this.rejectionReason,
    this.reviewedAt,
    this.uploadedAt,
  });

  factory CraftsmanDocument.fromJson(Map<String, dynamic> json) =>
      _$CraftsmanDocumentFromJson(json);
  Map<String, dynamic> toJson() => _$CraftsmanDocumentToJson(this);
}

// ═══════════════════════════════════════════════════════════════
// SERVICE CATEGORIES
// ═══════════════════════════════════════════════════════════════

@JsonSerializable()
class ServiceCategory {
  final int? id;
  final String? nameDE;
  final String? nameEN;
  final String? icon;
  final double? priceMin;
  final double? priceMax;
  final bool? active;

  ServiceCategory({
    this.id,
    this.nameDE,
    this.nameEN,
    this.icon,
    this.priceMin,
    this.priceMax,
    this.active,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) =>
      _$ServiceCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceCategoryToJson(this);

  String get priceRange =>
      '€${priceMin?.toStringAsFixed(0) ?? '?'} – €${priceMax?.toStringAsFixed(0) ?? '?'}';
}

// ═══════════════════════════════════════════════════════════════
// ORDERS
// ═══════════════════════════════════════════════════════════════

enum OrderStatus {
  @JsonValue('REQUEST_CREATED')
  requestCreated,
  @JsonValue('MATCHING')
  matching,
  @JsonValue('PROPOSALS_RECEIVED')
  proposalsReceived,
  @JsonValue('CRAFTSMAN_ASSIGNED')
  craftsmanAssigned,
  @JsonValue('CRAFTSMAN_ON_THE_WAY')
  craftsmanOnTheWay,
  @JsonValue('CRAFTSMAN_ARRIVED')
  craftsmanArrived,
  @JsonValue('JOB_IN_PROGRESS')
  jobInProgress,
  @JsonValue('PRICE_REVISION_REQUESTED')
  priceRevisionRequested,
  @JsonValue('PRICE_REVISION_ACCEPTED')
  priceRevisionAccepted,
  @JsonValue('JOB_COMPLETED')
  jobCompleted,
  @JsonValue('PENDING_CONFIRMATION')
  pendingConfirmation,
  @JsonValue('PAYMENT_CAPTURED')
  paymentCaptured,
  @JsonValue('DISPUTE_OPENED')
  disputeOpened,
  @JsonValue('DISPUTE_RESOLVED')
  disputeResolved,
  @JsonValue('RATING_SUBMITTED')
  ratingSubmitted,
  @JsonValue('ORDER_CLOSED')
  orderClosed,
  @JsonValue('CANCELLED')
  cancelled,
}

enum RequestType {
  @JsonValue('IMMEDIATE')
  immediate,
  @JsonValue('SCHEDULED')
  scheduled,
}

@JsonSerializable()
class Order {
  final String? id;
  final String? customerId;
  final String? assignedCraftsmanId;
  final ServiceCategory? serviceCategory;
  final RequestType? requestType;
  final OrderStatus? status;
  final String? description;
  final OrderLocation? location;
  final DateTime? scheduledAt;
  final double? estimatedPriceMin;
  final double? estimatedPriceMax;
  final double? finalPrice;
  final List<OrderMedia>? mediaFiles;
  final DateTime? createdAt;
  final DateTime? completedAt;

  Order({
    this.id,
    this.customerId,
    this.assignedCraftsmanId,
    this.serviceCategory,
    this.requestType,
    this.status,
    this.description,
    this.location,
    this.scheduledAt,
    this.estimatedPriceMin,
    this.estimatedPriceMax,
    this.finalPrice,
    this.mediaFiles,
    this.createdAt,
    this.completedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);

  bool get isActive => status != OrderStatus.orderClosed &&
      status != OrderStatus.cancelled;

  bool get isInProgress => status == OrderStatus.jobInProgress ||
      status == OrderStatus.craftsmanOnTheWay ||
      status == OrderStatus.craftsmanArrived;

  String get statusLabel {
    switch (status) {
      case OrderStatus.requestCreated:
        return 'Anfrage erstellt';
      case OrderStatus.matching:
        return 'Suche Handwerker...';
      case OrderStatus.proposalsReceived:
        return 'Angebote eingegangen';
      case OrderStatus.craftsmanAssigned:
        return 'Handwerker zugewiesen';
      case OrderStatus.craftsmanOnTheWay:
        return 'Handwerker unterwegs';
      case OrderStatus.craftsmanArrived:
        return 'Handwerker eingetroffen';
      case OrderStatus.jobInProgress:
        return 'Arbeit läuft';
      case OrderStatus.priceRevisionRequested:
        return 'Preisänderung angefragt';
      case OrderStatus.priceRevisionAccepted:
        return 'Preisänderung akzeptiert';
      case OrderStatus.jobCompleted:
        return 'Arbeit abgeschlossen';
      case OrderStatus.pendingConfirmation:
        return 'Bestätigung ausstehend';
      case OrderStatus.paymentCaptured:
        return 'Bezahlt';
      case OrderStatus.disputeOpened:
        return 'Reklamation offen';
      case OrderStatus.disputeResolved:
        return 'Reklamation gelöst';
      case OrderStatus.ratingSubmitted:
        return 'Bewertet';
      case OrderStatus.orderClosed:
        return 'Abgeschlossen';
      case OrderStatus.cancelled:
        return 'Storniert';
      default:
        return 'Unbekannt';
    }
  }
}

@JsonSerializable()
class OrderLocation {
  final String? postalCode;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? fullAddress;

  OrderLocation({
    this.postalCode,
    this.city,
    this.latitude,
    this.longitude,
    this.fullAddress,
  });

  factory OrderLocation.fromJson(Map<String, dynamic> json) =>
      _$OrderLocationFromJson(json);
  Map<String, dynamic> toJson() => _$OrderLocationToJson(this);
}

@JsonSerializable()
class OrderMedia {
  final String? id;
  final String? type;
  final String? fileUrl;
  final DateTime? uploadedAt;

  OrderMedia({this.id, this.type, this.fileUrl, this.uploadedAt});
  factory OrderMedia.fromJson(Map<String, dynamic> json) =>
      _$OrderMediaFromJson(json);
  Map<String, dynamic> toJson() => _$OrderMediaToJson(this);
}

// ═══════════════════════════════════════════════════════════════
// PROPOSALS
// ═══════════════════════════════════════════════════════════════

enum ProposalStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('ACCEPTED')
  accepted,
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('EXPIRED')
  expired,
  @JsonValue('CANCELLED')
  cancelled,
}

@JsonSerializable()
class Proposal {
  final String? id;
  final String? orderId;
  final CraftsmanPublicSummary? craftsman;
  final double? price;
  final int? etaMinutes;
  final String? comment;
  final ProposalStatus? status;
  final int? responseTimeSeconds;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  Proposal({
    this.id,
    this.orderId,
    this.craftsman,
    this.price,
    this.etaMinutes,
    this.comment,
    this.status,
    this.responseTimeSeconds,
    this.expiresAt,
    this.createdAt,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) =>
      _$ProposalFromJson(json);
  Map<String, dynamic> toJson() => _$ProposalToJson(this);

  String get priceFormatted => '€${price?.toStringAsFixed(2) ?? '—'}';
  String get etaFormatted => '${etaMinutes ?? '?'} min';
}

// ═══════════════════════════════════════════════════════════════
// PAYMENTS
// ═══════════════════════════════════════════════════════════════

@JsonSerializable()
class Payment {
  final String? id;
  final String? orderId;
  final double? amount;
  final double? platformFee;
  final double? craftsmanNet;
  final String? currency;
  final String? status;
  final DateTime? capturedAt;

  Payment({
    this.id,
    this.orderId,
    this.amount,
    this.platformFee,
    this.craftsmanNet,
    this.currency,
    this.status,
    this.capturedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentToJson(this);
}

@JsonSerializable()
class Payout {
  final String? id;
  final String? craftsmanId;
  final double? amount;
  final String? currency;
  final String? bankReference;
  final String? status;
  final DateTime? scheduledAt;
  final DateTime? executedAt;

  Payout({
    this.id,
    this.craftsmanId,
    this.amount,
    this.currency,
    this.bankReference,
    this.status,
    this.scheduledAt,
    this.executedAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) =>
      _$PayoutFromJson(json);
  Map<String, dynamic> toJson() => _$PayoutToJson(this);
}

// ═══════════════════════════════════════════════════════════════
// RATINGS
// ═══════════════════════════════════════════════════════════════

@JsonSerializable()
class Rating {
  final String? id;
  final String? orderId;
  final int? quality;
  final int? punctuality;
  final int? professionalism;
  final int? value;
  final bool? wouldRecommend;
  final String? comment;
  final DateTime? createdAt;

  Rating({
    this.id,
    this.orderId,
    this.quality,
    this.punctuality,
    this.professionalism,
    this.value,
    this.wouldRecommend,
    this.comment,
    this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) =>
      _$RatingFromJson(json);
  Map<String, dynamic> toJson() => _$RatingToJson(this);

  double get average {
    final vals = [quality, punctuality, professionalism, value]
        .whereType<int>()
        .toList();
    if (vals.isEmpty) return 0;
    return vals.reduce((a, b) => a + b) / vals.length;
  }
}

// ═══════════════════════════════════════════════════════════════
// DISPUTES
// ═══════════════════════════════════════════════════════════════

enum DisputeStatus {
  @JsonValue('OPENED')
  opened,
  @JsonValue('CRAFTSMAN_RESPONDED')
  craftsmanResponded,
  @JsonValue('UNDER_REVIEW')
  underReview,
  @JsonValue('RESOLVED')
  resolved,
  @JsonValue('APPEALED')
  appealed,
}

@JsonSerializable()
class Dispute {
  final String? id;
  final String? orderId;
  final String? openedBy;
  final String? description;
  final List<String>? mediaUrls;
  final String? craftsmanResponse;
  final DisputeStatus? status;
  final String? resolution;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  Dispute({
    this.id,
    this.orderId,
    this.openedBy,
    this.description,
    this.mediaUrls,
    this.craftsmanResponse,
    this.status,
    this.resolution,
    this.resolvedAt,
    this.createdAt,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) =>
      _$DisputeFromJson(json);
  Map<String, dynamic> toJson() => _$DisputeToJson(this);
}

// ═══════════════════════════════════════════════════════════════
// CHAT
// ═══════════════════════════════════════════════════════════════

@JsonSerializable()
class ChatMessage {
  final String? id;
  final String? orderId;
  final String? senderId;
  final String? senderRole;
  final String? text;
  final String? mediaUrl;
  final DateTime? sentAt;
  final DateTime? readAt;

  ChatMessage({
    this.id,
    this.orderId,
    this.senderId,
    this.senderRole,
    this.text,
    this.mediaUrl,
    this.sentAt,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

// ═══════════════════════════════════════════════════════════════
// NOTIFICATIONS
// ═══════════════════════════════════════════════════════════════

@JsonSerializable()
class AppNotification {
  final String? id;
  final String? type;
  final String? message;
  final String? channel;
  final DateTime? readAt;
  final DateTime? sentAt;

  AppNotification({
    this.id,
    this.type,
    this.message,
    this.channel,
    this.readAt,
    this.sentAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);

  bool get isRead => readAt != null;
}

// ═══════════════════════════════════════════════════════════════
// PAGINATION
// ═══════════════════════════════════════════════════════════════

@JsonSerializable()
class PageMeta {
  final int? page;
  final int? size;
  final int? totalElements;
  final int? totalPages;

  PageMeta({this.page, this.size, this.totalElements, this.totalPages});
  factory PageMeta.fromJson(Map<String, dynamic> json) =>
      _$PageMetaFromJson(json);
  Map<String, dynamic> toJson() => _$PageMetaToJson(this);

  bool get hasNext => (page ?? 0) < (totalPages ?? 0) - 1;
}

@JsonSerializable(genericArgumentFactories: true)
class PaginatedResponse<T> {
  final List<T>? data;
  final PageMeta? meta;

  PaginatedResponse({this.data, this.meta});

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PaginatedResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$PaginatedResponseToJson(this, toJsonT);
}
