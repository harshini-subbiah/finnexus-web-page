class LoanModel {
  final String id;
  final String uid;
  final String customerId;
  final String businessName;
  final String lenderUid;
  final String lenderName;
  final double amount;
  final int tenureMonths;
  final String purpose;
  final String loanType;
  final double? annualIncome;
  final String? existingLoans;
  final String? collateral;
  final String? collateralValue;
  final String bankAccount;
  final String ifscCode;
  final String status;
  final double? interestRate;
  final String? rejectionReason;
  final List<Map<String, dynamic>> emiHistory;
  final DateTime createdAt;
  final String? disbursedAt;

  LoanModel({
    required this.id,
    required this.uid,
    required this.customerId,
    required this.businessName,
    required this.lenderUid,
    required this.lenderName,
    required this.amount,
    required this.tenureMonths,
    required this.purpose,
    required this.loanType,
    this.annualIncome,
    this.existingLoans,
    this.collateral,
    this.collateralValue,
    required this.bankAccount,
    required this.ifscCode,
    required this.status,
    this.interestRate,
    this.rejectionReason,
    required this.emiHistory,
    required this.createdAt,
    this.disbursedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'customerId': customerId,
        'businessName': businessName,
        'lenderUid': lenderUid,
        'lenderName': lenderName,
        'amount': amount,
        'tenureMonths': tenureMonths,
        'purpose': purpose,
        'loanType': loanType,
        'annualIncome': annualIncome,
        'existingLoans': existingLoans,
        'collateral': collateral,
        'collateralValue': collateralValue,
        'bankAccount': bankAccount,
        'ifscCode': ifscCode,
        'status': status,
        'interestRate': interestRate,
        'rejectionReason': rejectionReason,
        'emiHistory': emiHistory,
        'createdAt': createdAt.toIso8601String(),
        'disbursedAt': disbursedAt,
      };

  factory LoanModel.fromMap(Map<String, dynamic> map) => LoanModel(
        id: map['id'] ?? '',
        uid: map['uid'] ?? '',
        customerId: map['customerId'] ?? '',
        businessName: map['businessName'] ?? '',
        lenderUid: map['lenderUid'] ?? '',
        lenderName: map['lenderName'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        tenureMonths: map['tenureMonths'] ?? 0,
        purpose: map['purpose'] ?? '',
        loanType: map['loanType'] ?? '',
        annualIncome: map['annualIncome']?.toDouble(),
        existingLoans: map['existingLoans'],
        collateral: map['collateral'],
        collateralValue: map['collateralValue'],
        bankAccount: map['bankAccount'] ?? '',
        ifscCode: map['ifscCode'] ?? '',
        status: map['status'] ?? 'pending',
        interestRate: map['interestRate']?.toDouble(),
        rejectionReason: map['rejectionReason'],
        emiHistory: List<Map<String, dynamic>>.from(map['emiHistory'] ?? []),
        createdAt: DateTime.parse(map['createdAt']),
        disbursedAt: map['disbursedAt'],
      );
}