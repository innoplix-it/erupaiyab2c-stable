class ProfileModel {
  /// Response keys that can carry the Billing & Delivery percentage. Confirm
  /// the final key with the backend and keep only that one here.
  static const List<String> _billingDeliveryPercentKeys = [
    'billing_delivery_percent',
    'billing_and_delivery_percent',
    'address_completion_percent',
    'billing_percent',
  ];

  const ProfileModel({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    this.address,
    this.billingAddress,
    this.addresses = const [],
    this.isVerified = false,
    this.isKycVerified = false,
    this.isEmailVerified = false,
    this.walletBalance = 0.0,
    this.dailyFreeSpin = 0,
    this.normalSpinRemaining = 0,
    this.isPushNotification = true,
    this.isRazorpayDisabled = false,
    this.accountStatus = ProfileAccountStatus.active,
    this.blockedReason,
    this.blockedAt,
    this.kycStatus = ProfileKycStatus.pending,
    this.isKycStep1Completed = false,
    this.aadhaarMasked,
    this.panMasked,
    this.panNo,
    this.permanentAddress,
    this.dob,
    this.createdAt,
    this.updatedAt,
    this.profilePhotoUrl,
    this.profileCompletionPercent = 0,
    this.billingDeliveryPercent = 0,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final addressesJson = json['addresses'];
    final parsedAddresses = addressesJson is List
        ? addressesJson
            .whereType<Map>()
            .map((entry) => AddressEntry.fromJson(
                  Map<String, dynamic>.from(entry),
                ))
            .toList()
        : <AddressEntry>[];
    final billingFromList = parsedAddresses
        .where((entry) => entry.type == AddressType.billing)
        .toList();
    final billingEntry =
        billingFromList.isNotEmpty ? billingFromList.first : null;

    return ProfileModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      email: json['email'] as String?,
      address: json['address'] as String?,
      billingAddress: billingEntry != null
          ? BillingAddress(
              addressLine1: billingEntry.addressLine1,
              addressLine2: billingEntry.addressLine2,
              city: billingEntry.city,
              state: billingEntry.state,
              stateCode: billingEntry.stateCode,
              country: billingEntry.country,
              pincode: billingEntry.zip,
              billingMobile: billingEntry.mobile,
            )
          : json['billing_address'] is Map<String, dynamic>
              ? BillingAddress.fromJson(
                  json['billing_address'] as Map<String, dynamic>,
                )
              : null,
      addresses: parsedAddresses,
      isVerified: json['is_verified'] == '1',
      isKycVerified: _parseBool(json['is_kyc_verified']),
      kycStatus: _parseKycStatus(json['kyc_status']),
      isKycStep1Completed: _parseBool(json['is_kyc_step1_completed']),
      isEmailVerified: json['is_email_verified'] == 'VERIFIED',
      walletBalance:
          double.tryParse(json['wallet_balance']?.toString() ?? '') ?? 0.0,
      dailyFreeSpin:
          int.tryParse(json['daily_free_spin']?.toString() ?? '') ?? 0,
      normalSpinRemaining:
          int.tryParse(json['normal_spin_remaining']?.toString() ?? '') ?? 0,
      isPushNotification: _parseBool(json['is_push_notification']),
      isRazorpayDisabled: _parseBool(json['is_razorpay_disable']),
      accountStatus: _parseAccountStatus(json['account_status']),
      blockedReason: json['blocked_reason'] as String?,
      blockedAt: json['blocked_at'] as String?,
      aadhaarMasked: json['aadhaar_masked'] as String?,
      panMasked: json['pan_masked'] as String?,
      panNo: json['pan_no'] as String?,
      permanentAddress:
          (json['permanant_address'] ?? json['permanent_address']) as String?,
      dob: json['dob'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      profileCompletionPercent: _parseInt(
        json['profile_completion_percent'] ??
            json['completion_percent'] ??
            json['profile_completion'] ??
            json['kyc_completion_percent'],
      ),
      // Badge value for the Billing & Delivery section. Straight from the API;
      // no value in the response means 0 (never computed on the client).
      billingDeliveryPercent: _parseInt(
        _firstValue(json, _billingDeliveryPercentKeys),
      ),
    );
  }

  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String? address;
  final BillingAddress? billingAddress;
  final List<AddressEntry> addresses;
  final bool isVerified;
  final bool isKycVerified;
  final bool isEmailVerified;
  final double walletBalance;
  final int dailyFreeSpin;
  final int normalSpinRemaining;
  final bool isPushNotification;
  final bool isRazorpayDisabled;
  final ProfileAccountStatus accountStatus;
  final String? blockedReason;
  final String? blockedAt;
  final ProfileKycStatus kycStatus;
  final bool isKycStep1Completed;
  final String? aadhaarMasked;
  final String? panMasked;
  final String? panNo;
  final String? permanentAddress;
  final String? dob;
  final String? createdAt;
  final String? updatedAt;
  final String? profilePhotoUrl;

  /// Profile completion percentage reported by the backend. Defaults to 0
  /// when the API provides no value.
  final int profileCompletionPercent;

  /// Billing & Delivery completion percentage reported by the backend. 0 when
  /// the API sends no value for it.
  final int billingDeliveryPercent;

  AddressEntry? get billingAddressEntry =>
      addresses.firstWhere((e) => e.type == AddressType.billing, orElse: () {
        if (billingAddress == null)
          return AddressEntry.empty(AddressType.billing);
        return AddressEntry(
          type: AddressType.billing,
          addressLine1: billingAddress!.addressLine1,
          addressLine2: billingAddress!.addressLine2,
          city: billingAddress!.city,
          state: billingAddress!.state,
          stateCode: billingAddress!.stateCode,
          zip: billingAddress!.pincode,
          country: billingAddress!.country,
          mobile: billingAddress!.billingMobile,
          isDefault: true,
        );
      });

  AddressEntry? get deliveryAddressEntry =>
      addresses.firstWhere((e) => e.type == AddressType.delivery, orElse: () {
        return AddressEntry.empty(AddressType.delivery);
      });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '';
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    final text = value?.toString().trim().toLowerCase();
    return text == '1' || text == 'true' || text == 'verified' || text == 'yes';
  }

  static int _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  /// First present, non-null value among [keys] in [json].
  static dynamic _firstValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value;
    }
    return null;
  }

  static ProfileKycStatus _parseKycStatus(dynamic value) {
    final text = value?.toString().trim().toUpperCase() ?? '';
    switch (text) {
      case 'VERIFIED':
        return ProfileKycStatus.verified;
      case 'REJECTED':
        return ProfileKycStatus.rejected;
      case 'IN_PROGRESS':
        return ProfileKycStatus.inProgress;
      case 'PENDING':
      default:
        return ProfileKycStatus.pending;
    }
  }

  static ProfileAccountStatus _parseAccountStatus(dynamic value) {
    final text = value?.toString().trim().toUpperCase() ?? '';
    switch (text) {
      case 'BLOCKED':
      case 'TEMP_BLOCKED':
      case 'TEMPORARY_BLOCKED':
        return ProfileAccountStatus.blocked;
      case 'ACTIVE':
      default:
        return ProfileAccountStatus.active;
    }
  }
}

enum ProfileKycStatus { pending, verified, rejected, inProgress }

enum ProfileAccountStatus { active, blocked }

class BillingAddress {
  const BillingAddress({
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.stateCode,
    required this.country,
    required this.pincode,
    required this.billingMobile,
  });

  factory BillingAddress.fromJson(Map<String, dynamic> json) {
    return BillingAddress(
      addressLine1: json['address_line1']?.toString() ?? '',
      addressLine2: json['address_line2']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      stateCode: json['state_code']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      pincode: (json['pincode'] ?? json['zip'])?.toString() ?? '',
      billingMobile:
          (json['billing_mobile'] ?? json['mobile'])?.toString() ?? '',
    );
  }

  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String stateCode;
  final String country;
  final String pincode;
  final String billingMobile;
}

enum AddressType { billing, delivery, other }

class AddressEntry {
  const AddressEntry({
    required this.type,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.stateCode,
    required this.zip,
    required this.country,
    required this.mobile,
    required this.isDefault,
  });

  factory AddressEntry.empty(AddressType type) {
    return AddressEntry(
      type: type,
      addressLine1: '',
      addressLine2: '',
      city: '',
      state: '',
      stateCode: '',
      zip: '',
      country: '',
      mobile: '',
      isDefault: false,
    );
  }

  factory AddressEntry.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? '').toString().toLowerCase();
    final type = rawType == 'billing'
        ? AddressType.billing
        : rawType == 'delivery'
            ? AddressType.delivery
            : AddressType.other;
    return AddressEntry(
      type: type,
      addressLine1: json['address_line1']?.toString() ?? '',
      addressLine2: json['address_line2']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      stateCode: (json['state_code'] ?? '').toString(),
      zip: (json['zip'] ?? json['pincode'] ?? '').toString(),
      country: json['country']?.toString() ?? '',
      mobile: (json['mobile'] ?? json['billing_mobile'] ?? '').toString(),
      isDefault: (json['is_default'] ?? '0').toString() == '1',
    );
  }

  final AddressType type;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String stateCode;
  final String zip;
  final String country;
  final String mobile;
  final bool isDefault;
}
