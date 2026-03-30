// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendOtpRequest _$SendOtpRequestFromJson(Map<String, dynamic> json) =>
    SendOtpRequest(
      phone: json['phone'] as String,
    );

Map<String, dynamic> _$SendOtpRequestToJson(SendOtpRequest instance) =>
    <String, dynamic>{
      'phone': instance.phone,
    };

SendOtpResponse _$SendOtpResponseFromJson(Map<String, dynamic> json) =>
    SendOtpResponse(
      message: json['message'] as String?,
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt(),
      retriesRemaining: (json['retriesRemaining'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SendOtpResponseToJson(SendOtpResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'expiresInSeconds': instance.expiresInSeconds,
      'retriesRemaining': instance.retriesRemaining,
    };

VerifyOtpRequest _$VerifyOtpRequestFromJson(Map<String, dynamic> json) =>
    VerifyOtpRequest(
      phone: json['phone'] as String,
      code: json['code'] as String,
    );

Map<String, dynamic> _$VerifyOtpRequestToJson(VerifyOtpRequest instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'code': instance.code,
    };

AuthTokenResponse _$AuthTokenResponseFromJson(Map<String, dynamic> json) =>
    AuthTokenResponse(
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresIn: (json['expiresIn'] as num?)?.toInt(),
      isNewUser: json['isNewUser'] as bool?,
      requiresConsent: json['requiresConsent'] as bool?,
    );

Map<String, dynamic> _$AuthTokenResponseToJson(AuthTokenResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresIn': instance.expiresIn,
      'isNewUser': instance.isNewUser,
      'requiresConsent': instance.requiresConsent,
    };

Address _$AddressFromJson(Map<String, dynamic> json) => Address(
      street: json['street'] as String?,
      city: json['city'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
      'street': instance.street,
      'city': instance.city,
      'postalCode': instance.postalCode,
      'country': instance.country,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

CustomerProfile _$CustomerProfileFromJson(Map<String, dynamic> json) =>
    CustomerProfile(
      id: json['id'] as String?,
      phone: json['phone'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      address: json['address'] == null
          ? null
          : Address.fromJson(json['address'] as Map<String, dynamic>),
      profileComplete: json['profileComplete'] as bool?,
      gdprConsentAt: json['gdprConsentAt'] == null
          ? null
          : DateTime.parse(json['gdprConsentAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CustomerProfileToJson(CustomerProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'address': instance.address,
      'profileComplete': instance.profileComplete,
      'gdprConsentAt': instance.gdprConsentAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

CraftsmanProfile _$CraftsmanProfileFromJson(Map<String, dynamic> json) =>
    CraftsmanProfile(
      id: json['id'] as String?,
      phone: json['phone'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      status: $enumDecodeNullable(_$CraftsmanStatusEnumMap, json['status']),
      serviceCategories: (json['serviceCategories'] as List<dynamic>?)
          ?.map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      radiusKm: (json['radiusKm'] as num?)?.toDouble(),
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble(),
      completedJobsCount: (json['completedJobsCount'] as num?)?.toInt(),
      address: json['address'] == null
          ? null
          : Address.fromJson(json['address'] as Map<String, dynamic>),
      walletBalance: (json['walletBalance'] as num?)?.toDouble(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CraftsmanProfileToJson(CraftsmanProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'status': _$CraftsmanStatusEnumMap[instance.status],
      'serviceCategories': instance.serviceCategories,
      'radiusKm': instance.radiusKm,
      'ratingAvg': instance.ratingAvg,
      'completedJobsCount': instance.completedJobsCount,
      'address': instance.address,
      'walletBalance': instance.walletBalance,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$CraftsmanStatusEnumMap = {
  CraftsmanStatus.pending: 'PENDING',
  CraftsmanStatus.verified: 'VERIFIED',
  CraftsmanStatus.active: 'ACTIVE',
  CraftsmanStatus.inactive: 'INACTIVE',
  CraftsmanStatus.suspended: 'SUSPENDED',
  CraftsmanStatus.deactivated: 'DEACTIVATED',
};

CraftsmanPublicSummary _$CraftsmanPublicSummaryFromJson(
        Map<String, dynamic> json) =>
    CraftsmanPublicSummary(
      id: json['id'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble(),
      completedJobsCount: (json['completedJobsCount'] as num?)?.toInt(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$CraftsmanPublicSummaryToJson(
        CraftsmanPublicSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'profilePhotoUrl': instance.profilePhotoUrl,
      'ratingAvg': instance.ratingAvg,
      'completedJobsCount': instance.completedJobsCount,
      'distanceKm': instance.distanceKm,
    };

WalletBalance _$WalletBalanceFromJson(Map<String, dynamic> json) =>
    WalletBalance(
      balance: (json['balance'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      pendingAmount: (json['pendingAmount'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$WalletBalanceToJson(WalletBalance instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'currency': instance.currency,
      'pendingAmount': instance.pendingAmount,
    };

CraftsmanDocument _$CraftsmanDocumentFromJson(Map<String, dynamic> json) =>
    CraftsmanDocument(
      id: json['id'] as String?,
      craftsmanId: json['craftsmanId'] as String?,
      type: $enumDecodeNullable(_$DocumentTypeEnumMap, json['type']),
      fileUrl: json['fileUrl'] as String?,
      status: $enumDecodeNullable(_$DocumentStatusEnumMap, json['status']),
      expiryDate: json['expiryDate'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
      uploadedAt: json['uploadedAt'] == null
          ? null
          : DateTime.parse(json['uploadedAt'] as String),
    );

Map<String, dynamic> _$CraftsmanDocumentToJson(CraftsmanDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'craftsmanId': instance.craftsmanId,
      'type': _$DocumentTypeEnumMap[instance.type],
      'fileUrl': instance.fileUrl,
      'status': _$DocumentStatusEnumMap[instance.status],
      'expiryDate': instance.expiryDate,
      'rejectionReason': instance.rejectionReason,
      'reviewedAt': instance.reviewedAt?.toIso8601String(),
      'uploadedAt': instance.uploadedAt?.toIso8601String(),
    };

const _$DocumentTypeEnumMap = {
  DocumentType.tradeLicence: 'TRADE_LICENCE',
  DocumentType.insuranceCertificate: 'INSURANCE_CERTIFICATE',
  DocumentType.identityDocument: 'IDENTITY_DOCUMENT',
};

const _$DocumentStatusEnumMap = {
  DocumentStatus.pending: 'PENDING',
  DocumentStatus.approved: 'APPROVED',
  DocumentStatus.rejected: 'REJECTED',
  DocumentStatus.expired: 'EXPIRED',
};

ServiceCategory _$ServiceCategoryFromJson(Map<String, dynamic> json) =>
    ServiceCategory(
      id: json['id'] as String?,
      slug: json['slug'] as String?,
      nameDE: json['nameDe'] as String?,
      nameEN: json['nameEn'] as String?,
    );

Map<String, dynamic> _$ServiceCategoryToJson(ServiceCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'nameDe': instance.nameDE,
      'nameEn': instance.nameEN,
    };

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
      id: json['id'] as String?,
      orderNumber: json['orderNumber'] as String?,
      customerId: json['customerId'] as String?,
      assignedCraftsmanId: json['assignedCraftsmanId'] as String?,
      serviceCategory: json['serviceCategory'] == null
          ? null
          : ServiceCategory.fromJson(
              json['serviceCategory'] as Map<String, dynamic>),
      requestType:
          $enumDecodeNullable(_$RequestTypeEnumMap, json['requestType']),
      status: $enumDecodeNullable(_$OrderStatusEnumMap, json['status']),
      description: json['description'] as String?,
      location: json['location'] == null
          ? null
          : OrderLocation.fromJson(json['location'] as Map<String, dynamic>),
      scheduledAt: json['scheduledAt'] == null
          ? null
          : DateTime.parse(json['scheduledAt'] as String),
      estimatedPriceMin: (json['estimatedPriceMin'] as num?)?.toDouble(),
      estimatedPriceMax: (json['estimatedPriceMax'] as num?)?.toDouble(),
      finalPrice: (json['finalPrice'] as num?)?.toDouble(),
      mediaFiles: (json['mediaFiles'] as List<dynamic>?)
          ?.map((e) => OrderMedia.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
      'id': instance.id,
      'orderNumber': instance.orderNumber,
      'customerId': instance.customerId,
      'assignedCraftsmanId': instance.assignedCraftsmanId,
      'serviceCategory': instance.serviceCategory,
      'requestType': _$RequestTypeEnumMap[instance.requestType],
      'status': _$OrderStatusEnumMap[instance.status],
      'description': instance.description,
      'location': instance.location,
      'scheduledAt': instance.scheduledAt?.toIso8601String(),
      'estimatedPriceMin': instance.estimatedPriceMin,
      'estimatedPriceMax': instance.estimatedPriceMax,
      'finalPrice': instance.finalPrice,
      'mediaFiles': instance.mediaFiles,
      'createdAt': instance.createdAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
    };

const _$RequestTypeEnumMap = {
  RequestType.immediate: 'IMMEDIATE',
  RequestType.scheduled: 'SCHEDULED',
};

const _$OrderStatusEnumMap = {
  OrderStatus.requestCreated: 'REQUEST_CREATED',
  OrderStatus.matching: 'MATCHING',
  OrderStatus.proposalsReceived: 'PROPOSALS_RECEIVED',
  OrderStatus.craftsmanAssigned: 'CRAFTSMAN_ASSIGNED',
  OrderStatus.craftsmanOnTheWay: 'CRAFTSMAN_ON_THE_WAY',
  OrderStatus.craftsmanArrived: 'CRAFTSMAN_ARRIVED',
  OrderStatus.jobInProgress: 'JOB_IN_PROGRESS',
  OrderStatus.priceRevisionRequested: 'PRICE_REVISION_REQUESTED',
  OrderStatus.priceRevisionAccepted: 'PRICE_REVISION_ACCEPTED',
  OrderStatus.jobCompleted: 'JOB_COMPLETED',
  OrderStatus.pendingConfirmation: 'PENDING_CONFIRMATION',
  OrderStatus.paymentCaptured: 'PAYMENT_CAPTURED',
  OrderStatus.disputeOpened: 'DISPUTE_OPENED',
  OrderStatus.disputeResolved: 'DISPUTE_RESOLVED',
  OrderStatus.ratingSubmitted: 'RATING_SUBMITTED',
  OrderStatus.orderClosed: 'ORDER_CLOSED',
  OrderStatus.cancelled: 'CANCELLED',
};

OrderLocation _$OrderLocationFromJson(Map<String, dynamic> json) =>
    OrderLocation(
      postalCode: json['postalCode'] as String?,
      city: json['city'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      fullAddress: json['fullAddress'] as String?,
    );

Map<String, dynamic> _$OrderLocationToJson(OrderLocation instance) =>
    <String, dynamic>{
      'postalCode': instance.postalCode,
      'city': instance.city,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'fullAddress': instance.fullAddress,
    };

OrderMedia _$OrderMediaFromJson(Map<String, dynamic> json) => OrderMedia(
      id: json['id'] as String?,
      type: json['type'] as String?,
      fileUrl: json['fileUrl'] as String?,
      uploadedAt: json['uploadedAt'] == null
          ? null
          : DateTime.parse(json['uploadedAt'] as String),
    );

Map<String, dynamic> _$OrderMediaToJson(OrderMedia instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'fileUrl': instance.fileUrl,
      'uploadedAt': instance.uploadedAt?.toIso8601String(),
    };

CreateOrderRequest _$CreateOrderRequestFromJson(Map<String, dynamic> json) =>
    CreateOrderRequest(
      serviceCategoryId: json['serviceCategoryId'] as String,
      requestType: $enumDecode(_$RequestTypeEnumMap, json['requestType']),
      descriptionText: json['descriptionText'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      addressEncrypted: json['addressEncrypted'] as String,
      scheduledAt: json['scheduledAt'] as String?,
    );

Map<String, dynamic> _$CreateOrderRequestToJson(CreateOrderRequest instance) =>
    <String, dynamic>{
      'serviceCategoryId': instance.serviceCategoryId,
      'requestType': _$RequestTypeEnumMap[instance.requestType]!,
      'descriptionText': instance.descriptionText,
      'lat': instance.lat,
      'lng': instance.lng,
      'addressEncrypted': instance.addressEncrypted,
      'scheduledAt': instance.scheduledAt,
    };

Proposal _$ProposalFromJson(Map<String, dynamic> json) => Proposal(
      id: json['id'] as String?,
      orderId: json['orderId'] as String?,
      craftsman: json['craftsman'] == null
          ? null
          : CraftsmanPublicSummary.fromJson(
              json['craftsman'] as Map<String, dynamic>),
      price: (json['price'] as num?)?.toDouble(),
      etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
      comment: json['comment'] as String?,
      status: $enumDecodeNullable(_$ProposalStatusEnumMap, json['status']),
      responseTimeSeconds: (json['responseTimeSeconds'] as num?)?.toInt(),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ProposalToJson(Proposal instance) => <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'craftsman': instance.craftsman,
      'price': instance.price,
      'etaMinutes': instance.etaMinutes,
      'comment': instance.comment,
      'status': _$ProposalStatusEnumMap[instance.status],
      'responseTimeSeconds': instance.responseTimeSeconds,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$ProposalStatusEnumMap = {
  ProposalStatus.pending: 'PENDING',
  ProposalStatus.accepted: 'ACCEPTED',
  ProposalStatus.rejected: 'REJECTED',
  ProposalStatus.expired: 'EXPIRED',
  ProposalStatus.cancelled: 'CANCELLED',
};

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
      id: json['id'] as String?,
      orderId: json['orderId'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      platformFee: (json['platformFee'] as num?)?.toDouble(),
      craftsmanNet: (json['craftsmanNet'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      status: json['status'] as String?,
      capturedAt: json['capturedAt'] == null
          ? null
          : DateTime.parse(json['capturedAt'] as String),
    );

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'amount': instance.amount,
      'platformFee': instance.platformFee,
      'craftsmanNet': instance.craftsmanNet,
      'currency': instance.currency,
      'status': instance.status,
      'capturedAt': instance.capturedAt?.toIso8601String(),
    };

Payout _$PayoutFromJson(Map<String, dynamic> json) => Payout(
      id: json['id'] as String?,
      craftsmanId: json['craftsmanId'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      bankReference: json['bankReference'] as String?,
      status: json['status'] as String?,
      scheduledAt: json['scheduledAt'] == null
          ? null
          : DateTime.parse(json['scheduledAt'] as String),
      executedAt: json['executedAt'] == null
          ? null
          : DateTime.parse(json['executedAt'] as String),
    );

Map<String, dynamic> _$PayoutToJson(Payout instance) => <String, dynamic>{
      'id': instance.id,
      'craftsmanId': instance.craftsmanId,
      'amount': instance.amount,
      'currency': instance.currency,
      'bankReference': instance.bankReference,
      'status': instance.status,
      'scheduledAt': instance.scheduledAt?.toIso8601String(),
      'executedAt': instance.executedAt?.toIso8601String(),
    };

Rating _$RatingFromJson(Map<String, dynamic> json) => Rating(
      id: json['id'] as String?,
      orderId: json['orderId'] as String?,
      quality: (json['quality'] as num?)?.toInt(),
      punctuality: (json['punctuality'] as num?)?.toInt(),
      professionalism: (json['professionalism'] as num?)?.toInt(),
      value: (json['value'] as num?)?.toInt(),
      wouldRecommend: json['wouldRecommend'] as bool?,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$RatingToJson(Rating instance) => <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'quality': instance.quality,
      'punctuality': instance.punctuality,
      'professionalism': instance.professionalism,
      'value': instance.value,
      'wouldRecommend': instance.wouldRecommend,
      'comment': instance.comment,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

Dispute _$DisputeFromJson(Map<String, dynamic> json) => Dispute(
      id: json['id'] as String?,
      orderId: json['orderId'] as String?,
      openedBy: json['openedBy'] as String?,
      description: json['description'] as String?,
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      craftsmanResponse: json['craftsmanResponse'] as String?,
      status: $enumDecodeNullable(_$DisputeStatusEnumMap, json['status']),
      resolution: json['resolution'] as String?,
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$DisputeToJson(Dispute instance) => <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'openedBy': instance.openedBy,
      'description': instance.description,
      'mediaUrls': instance.mediaUrls,
      'craftsmanResponse': instance.craftsmanResponse,
      'status': _$DisputeStatusEnumMap[instance.status],
      'resolution': instance.resolution,
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$DisputeStatusEnumMap = {
  DisputeStatus.opened: 'OPENED',
  DisputeStatus.craftsmanResponded: 'CRAFTSMAN_RESPONDED',
  DisputeStatus.underReview: 'UNDER_REVIEW',
  DisputeStatus.resolved: 'RESOLVED',
  DisputeStatus.appealed: 'APPEALED',
};

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
      id: json['id'] as String?,
      orderId: json['orderId'] as String?,
      senderId: json['senderId'] as String?,
      senderRole: json['senderRole'] as String?,
      text: json['text'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      sentAt: json['sentAt'] == null
          ? null
          : DateTime.parse(json['sentAt'] as String),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
    );

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'senderId': instance.senderId,
      'senderRole': instance.senderRole,
      'text': instance.text,
      'mediaUrl': instance.mediaUrl,
      'sentAt': instance.sentAt?.toIso8601String(),
      'readAt': instance.readAt?.toIso8601String(),
    };

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    AppNotification(
      id: json['id'] as String?,
      type: json['type'] as String?,
      message: json['message'] as String?,
      channel: json['channel'] as String?,
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      sentAt: json['sentAt'] == null
          ? null
          : DateTime.parse(json['sentAt'] as String),
    );

Map<String, dynamic> _$AppNotificationToJson(AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'message': instance.message,
      'channel': instance.channel,
      'readAt': instance.readAt?.toIso8601String(),
      'sentAt': instance.sentAt?.toIso8601String(),
    };

PageMeta _$PageMetaFromJson(Map<String, dynamic> json) => PageMeta(
      page: (json['page'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt(),
      totalElements: (json['totalElements'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PageMetaToJson(PageMeta instance) => <String, dynamic>{
      'page': instance.page,
      'size': instance.size,
      'totalElements': instance.totalElements,
      'totalPages': instance.totalPages,
    };

PaginatedResponse<T> _$PaginatedResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    PaginatedResponse<T>(
      data: (json['data'] as List<dynamic>?)?.map(fromJsonT).toList(),
      meta: json['meta'] == null
          ? null
          : PageMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PaginatedResponseToJson<T>(
  PaginatedResponse<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'data': instance.data?.map(toJsonT).toList(),
      'meta': instance.meta,
    };
