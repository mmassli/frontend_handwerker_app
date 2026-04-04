import 'package:flutter/material.dart' show Icons, IconData;
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
  final String? role;

  AuthTokenResponse({
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.isNewUser,
    this.requiresConsent,
    this.role,
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
  final String? userId;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? email;
  final CraftsmanStatus? status;
  final List<ServiceCategory>? serviceCategories;
  final double? radiusKm;
  final double? ratingAvg;
  final int? ratingCount;
  final int? completedJobsCount;
  final Address? address;
  final double? walletBalance;
  final double? lat;
  final double? lng;
  final DateTime? createdAt;

  CraftsmanProfile({
    this.id,
    this.userId,
    this.phone,
    this.firstName,
    this.lastName,
    this.email,
    this.status,
    this.serviceCategories,
    this.radiusKm,
    this.ratingAvg,
    this.ratingCount,
    this.completedJobsCount,
    this.address,
    this.walletBalance,
    this.lat,
    this.lng,
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
// CREATE CRAFTSMAN REQUEST DTO
// Matches POST /craftsmen (Admin only)
// ═══════════════════════════════════════════════════════════════

class CreateCraftsmanRequest {
  final String phone;
  final String firstName;
  final String lastName;
  final String? email;
  final List<String>? categoryIds;
  final double? radiusKm;
  final String? street;
  final String? city;
  final String? postalCode;

  const CreateCraftsmanRequest({
    required this.phone,
    required this.firstName,
    required this.lastName,
    this.email,
    this.categoryIds,
    this.radiusKm,
    this.street,
    this.city,
    this.postalCode,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
    };
    if (email != null && email!.isNotEmpty) map['email'] = email;
    if (categoryIds != null && categoryIds!.isNotEmpty) {
      map['categoryIds'] = categoryIds;
    }
    if (radiusKm != null) map['radiusKm'] = radiusKm;
    if (street != null || city != null || postalCode != null) {
      map['address'] = {
        if (street != null) 'street': street,
        if (city != null) 'city': city,
        if (postalCode != null) 'postalCode': postalCode,
        'country': 'DE',
      };
    }
    return map;
  }
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
  final String? id; // UUID returned by GET /api/v1/service-categories
  final String? slug;
  @JsonKey(name: 'nameDe')
  final String? nameDE;
  @JsonKey(name: 'nameEn')
  final String? nameEN;

  ServiceCategory({
    this.id,
    this.slug,
    this.nameDE,
    this.nameEN,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) =>
      _$ServiceCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceCategoryToJson(this);
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
  final String? orderNumber;
  final String? customerId;
  final String? assignedCraftsmanId;
  final ServiceCategory? serviceCategory;
  // Extra flat fields returned by the enriched OrderResponse
  final String? serviceCategorySlug;
  final String? serviceCategoryNameDe;
  /// Postal code stored directly on the order (added in V7 migration)
  final String? postleitzahl;
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
    this.orderNumber,
    this.customerId,
    this.assignedCraftsmanId,
    this.serviceCategory,
    this.serviceCategorySlug,
    this.serviceCategoryNameDe,
    this.postleitzahl,
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

  /// Parses an [Order] from JSON, normalising differences between the standard
  /// customer-facing response and the craftsman-enriched response shapes:
  ///
  /// | Standard (customer)        | Craftsman-enriched          |
  /// |----------------------------|-----------------------------|
  /// | `"mediaFiles": [{fileUrl}]`| `"media": [{url}]`          |
  /// | `"description": "…"`       | `"descriptionText": "…"`    |
  ///
  /// Both shapes are accepted so that `orderDetailProvider` works correctly
  /// regardless of which endpoint populates the cache.
  factory Order.fromJson(Map<String, dynamic> json) {
    final m = Map<String, dynamic>.from(json);

    // ── description fallback ─────────────────────────────────
    // Some craftsman endpoints return the field as "descriptionText".
    if ((m['description'] == null || (m['description'] as String?)?.isEmpty == true) &&
        m['descriptionText'] != null) {
      m['description'] = m['descriptionText'];
    }

    // ── media / mediaFiles normalisation ─────────────────────
    // Craftsman-enriched endpoints return "media" (list of {url, …})
    // while the standard Order schema uses "mediaFiles" (list of {fileUrl, …}).
    if ((m['mediaFiles'] == null) && m['media'] is List) {
      m['mediaFiles'] = (m['media'] as List).map((e) {
        if (e is Map<String, dynamic>) {
          return <String, dynamic>{
            'id': e['id'],
            'type': e['type'],
            // map 'url' → 'fileUrl' so OrderMedia.fromJson finds the value
            'fileUrl': e['fileUrl'] ?? e['url'],
            'uploadedAt': e['uploadedAt'] ?? e['createdAt'],
          };
        }
        return e;
      }).toList();
    }

    return _$OrderFromJson(m);
  }

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

  /// Handles both standard format (`fileUrl`) and craftsman-enriched format
  /// (`url`) returned by `/craftsmen/me/*` endpoints.
  factory OrderMedia.fromJson(Map<String, dynamic> json) => OrderMedia(
        id: json['id'] as String?,
        type: json['type'] as String?,
        fileUrl: (json['fileUrl'] ?? json['url']) as String?,
        uploadedAt: json['uploadedAt'] == null
            ? null
            : DateTime.tryParse(json['uploadedAt'] as String),
      );

  Map<String, dynamic> toJson() => _$OrderMediaToJson(this);
}

// ═══════════════════════════════════════════════════════════════
// CREATE ORDER REQUEST DTO
// Matches the exact backend DTO shape for POST /api/v1/orders
// ═══════════════════════════════════════════════════════════════

@JsonSerializable()
class CreateOrderRequest {
  /// UUID of the service category returned by GET /api/v1/service-categories
  final String serviceCategoryId;

  /// IMMEDIATE or SCHEDULED
  final RequestType requestType;

  /// Optional description of the problem
  final String? descriptionText;

  /// GPS latitude of the service location
  final double lat;

  /// GPS longitude of the service location
  final double lng;

  /// AES-256-CBC encrypted address string
  final String addressEncrypted;

  /// Postal code (5-digit German PLZ) extracted from the address input
  final String? postleitzahl;

  /// ISO-8601 UTC string for scheduled orders; null for IMMEDIATE
  final String? scheduledAt;

  const CreateOrderRequest({
    required this.serviceCategoryId,
    required this.requestType,
    this.descriptionText,
    required this.lat,
    required this.lng,
    required this.addressEncrypted,
    this.postleitzahl,
    this.scheduledAt,
  });

  factory CreateOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateOrderRequestToJson(this);
}

// ═══════════════════════════════════════════════════════════════
// CRAFTSMAN ORDER DTOs
// Returned by GET /craftsmen/me/orders and /craftsmen/me/available-orders
// ═══════════════════════════════════════════════════════════════

/// Enriched media item with a resolvable URL (pre-signed S3 or direct path).
class OrderMediaItem {
  final String? id;

  /// PHOTO | VIDEO | AUDIO
  final String? type;

  /// Directly loadable URL (pre-signed for S3, direct for local storage)
  final String? url;

  /// true = taken before the job, false = after
  final bool? isBefore;
  final DateTime? createdAt;

  const OrderMediaItem({
    this.id,
    this.type,
    this.url,
    this.isBefore,
    this.createdAt,
  });

  factory OrderMediaItem.fromJson(Map<String, dynamic> json) => OrderMediaItem(
        id: json['id'] as String?,
        type: json['type'] as String?,
        url: json['url'] as String?,
        isBefore: json['isBefore'] as bool?,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.tryParse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'url': url,
        'isBefore': isBefore,
        'createdAt': createdAt?.toIso8601String(),
      };

  IconData get icon {
    switch (type?.toUpperCase()) {
      case 'VIDEO':
        return Icons.videocam_rounded;
      case 'AUDIO':
        return Icons.mic_rounded;
      default:
        return Icons.image_rounded;
    }
  }
}

/// Full order view returned from the craftsman-specific endpoints.
/// Contains enriched category info, PLZ, and pre-signed media URLs.
class CraftsmanOrderView {
  final String? id;
  final String? orderNumber;
  final OrderStatus? status;
  final RequestType? requestType;
  final String? serviceCategoryId;
  final String? serviceCategorySlug;
  final String? serviceCategoryNameDe;
  final String? serviceCategoryNameEn;
  final String? postleitzahl;
  final String? city;
  final String? description;
  final List<OrderMediaItem> media;
  final DateTime? createdAt;
  final DateTime? scheduledAt;

  const CraftsmanOrderView({
    this.id,
    this.orderNumber,
    this.status,
    this.requestType,
    this.serviceCategoryId,
    this.serviceCategorySlug,
    this.serviceCategoryNameDe,
    this.serviceCategoryNameEn,
    this.postleitzahl,
    this.city,
    this.description,
    this.media = const [],
    this.createdAt,
    this.scheduledAt,
  });

  factory CraftsmanOrderView.fromJson(Map<String, dynamic> json) {
    // serviceCategory can be either a nested object or flat fields
    String? catSlug = json['serviceCategorySlug'] as String?;
    String? catNameDe = json['serviceCategoryNameDe'] as String?;
    String? catNameEn = json['serviceCategoryNameEn'] as String?;
    String? catId = json['serviceCategoryId'] as String?;
    if (json['serviceCategory'] is Map) {
      final cat = json['serviceCategory'] as Map<String, dynamic>;
      catId ??= cat['id'] as String?;
      catSlug ??= cat['slug'] as String?;
      catNameDe ??= (cat['nameDe'] ?? cat['nameDE']) as String?;
      catNameEn ??= (cat['nameEn'] ?? cat['nameEN']) as String?;
    }

    // location can be a nested object or flat city/postalCode fields
    String? city = json['city'] as String?;
    String? plz = json['postleitzahl'] as String?;
    if (json['location'] is Map) {
      final loc = json['location'] as Map<String, dynamic>;
      city ??= loc['city'] as String?;
      plz ??= (loc['postalCode'] ?? loc['postleitzahl']) as String?;
    }

    final rawMedia = json['media'] as List<dynamic>? ?? [];

    return CraftsmanOrderView(
      id: json['id'] as String?,
      orderNumber: json['orderNumber'] as String?,
      status: json['status'] == null
          ? null
          : $enumDecodeNullable(_$OrderStatusEnumMap, json['status']),
      requestType: json['requestType'] == null
          ? null
          : $enumDecodeNullable(_$RequestTypeEnumMap, json['requestType']),
      serviceCategoryId: catId,
      serviceCategorySlug: catSlug,
      serviceCategoryNameDe: catNameDe,
      serviceCategoryNameEn: catNameEn,
      postleitzahl: plz,
      city: city,
      description: json['description'] as String?,
      media: rawMedia
          .map((e) => OrderMediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
      scheduledAt: json['scheduledAt'] == null
          ? null
          : DateTime.tryParse(json['scheduledAt'] as String),
    );
  }

  String get serviceName => serviceCategoryNameDe ?? serviceCategoryNameEn ?? 'Auftrag';
  String get locationDisplay => [postleitzahl, city].whereType<String>().join(' ');
  bool get isImmediate => requestType == RequestType.immediate;

  String get statusLabel {
    switch (status) {
      case OrderStatus.requestCreated: return 'Anfrage erstellt';
      case OrderStatus.matching: return 'Suche Handwerker...';
      case OrderStatus.proposalsReceived: return 'Angebote eingegangen';
      case OrderStatus.craftsmanAssigned: return 'Handwerker zugewiesen';
      case OrderStatus.craftsmanOnTheWay: return 'Handwerker unterwegs';
      case OrderStatus.craftsmanArrived: return 'Handwerker eingetroffen';
      case OrderStatus.jobInProgress: return 'Arbeit läuft';
      case OrderStatus.jobCompleted: return 'Arbeit abgeschlossen';
      case OrderStatus.orderClosed: return 'Abgeschlossen';
      case OrderStatus.cancelled: return 'Storniert';
      default: return 'Offen';
    }
  }
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
