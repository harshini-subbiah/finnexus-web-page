class UserModel {
  final String uid;
  final String email;
  final String role;
  final String businessName;
  final String gstin;
  final String pan;
  final String address;
  final String bankAccount;
  final String kycStatus;
  final String? customerId;
  final String? rejectionReason;
  final bool kycSubmitted;
  final DateTime createdAt;

  final bool isBanned;
  final String? banReason;
  final String? bannedBy;
  final String? bannedAt;
  final bool deletionRequested;
  final String? deletionScheduledAt;

  final bool isResubmission;
  final String? resubmittedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.businessName,
    required this.gstin,
    required this.pan,
    required this.address,
    required this.bankAccount,
    required this.kycStatus,
    this.customerId,
    this.rejectionReason,
    this.kycSubmitted = false,
    required this.createdAt,
    this.isBanned = false,
    this.banReason,
    this.bannedBy,
    this.bannedAt,
    this.deletionRequested = false,
    this.deletionScheduledAt,
    this.isResubmission = false,
    this.resubmittedAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'role': role,
        'businessName': businessName,
        'gstin': gstin,
        'pan': pan,
        'address': address,
        'bankAccount': bankAccount,
        'kycStatus': kycStatus,
        'customerId': customerId,
        'rejectionReason': rejectionReason,
        'kycSubmitted': kycSubmitted,
        'createdAt': createdAt.toIso8601String(),
        'isBanned': isBanned,
        'banReason': banReason,
        'bannedBy': bannedBy,
        'bannedAt': bannedAt,
        'deletionRequested': deletionRequested,
        'deletionScheduledAt': deletionScheduledAt,
        'isResubmission': isResubmission,
        'resubmittedAt': resubmittedAt,
      };

  factory UserModel.fromMap(Map<String, dynamic> m) =>
      UserModel(
        uid: m['uid'] ?? '',
        email: m['email'] ?? '',
        role: m['role'] ?? '',
        businessName: m['businessName'] ?? '',
        gstin: m['gstin'] ?? '',
        pan: m['pan'] ?? '',
        address: m['address'] ?? '',
        bankAccount: m['bankAccount'] ?? '',
        kycStatus: m['kycStatus'] ?? 'pending',
        customerId: m['customerId'],
        rejectionReason: m['rejectionReason'],
        kycSubmitted: m['kycSubmitted'] ?? false,
        createdAt: DateTime.parse(m['createdAt'] ??
            DateTime.now().toIso8601String()),
        isBanned: m['isBanned'] ?? false,
        banReason: m['banReason'],
        bannedBy: m['bannedBy'],
        bannedAt: m['bannedAt'],
        deletionRequested:
            m['deletionRequested'] ?? false,
        deletionScheduledAt:
            m['deletionScheduledAt'],
        isResubmission: m['isResubmission'] ?? false,
        resubmittedAt: m['resubmittedAt'],
      );

  UserModel copyWith({
    String? kycStatus,
    String? customerId,
    String? rejectionReason,
    bool? kycSubmitted,
    bool? isBanned,
    String? banReason,
    String? bannedBy,
    String? bannedAt,
    bool? deletionRequested,
    String? deletionScheduledAt,
    bool? isResubmission,
    String? resubmittedAt,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      role: role,
      businessName: businessName,
      gstin: gstin,
      pan: pan,
      address: address,
      bankAccount: bankAccount,
      kycStatus: kycStatus ?? this.kycStatus,
      customerId: customerId ?? this.customerId,
      rejectionReason:
          rejectionReason ?? this.rejectionReason,
      kycSubmitted: kycSubmitted ?? this.kycSubmitted,
      createdAt: createdAt,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      bannedBy: bannedBy ?? this.bannedBy,
      bannedAt: bannedAt ?? this.bannedAt,
      deletionRequested:
          deletionRequested ?? this.deletionRequested,
      deletionScheduledAt: deletionScheduledAt ??
          this.deletionScheduledAt,
      isResubmission:
          isResubmission ?? this.isResubmission,
      resubmittedAt: resubmittedAt ?? this.resubmittedAt,
    );
  }
}