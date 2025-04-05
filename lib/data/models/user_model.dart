class UserModel {
  final int id;
  final String admissionNumber;
  final String fullName;
  final String facultyCode;
  final String departmentCode;
  final String admissionYear;
  final String sequentialNumber;
  final String? email;
  final String? votingCode;
  final DateTime? votingCodeExpiresAt;
  final bool votingCodeUsed;
  final String voterStatus;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool numberTwo;
  final bool voter;

  UserModel({
    required this.id,
    required this.admissionNumber,
    required this.fullName,
    required this.facultyCode,
    required this.departmentCode,
    required this.admissionYear,
    required this.sequentialNumber,
    this.email,
    this.votingCode,
    this.votingCodeExpiresAt,
    required this.votingCodeUsed,
    required this.voterStatus,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    required this.numberTwo,
    required this.voter,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      admissionNumber: json['admissionNumber'] ?? '',
      fullName: json['fullName'] ?? '',
      facultyCode: json['facultyCode'] ?? '',
      departmentCode: json['departmentCode'] ?? '',
      admissionYear: json['admissionYear'] ?? '',
      sequentialNumber: json['sequentialNumber'] ?? '',
      email: json['email'],
      votingCode: json['votingCode'],
      votingCodeExpiresAt:
          json['votingCodeExpiresAt'] != null
              ? DateTime.parse(json['votingCodeExpiresAt'])
              : null,
      votingCodeUsed: json['votingCodeUsed'] ?? false,
      voterStatus: json['voterStatus'] ?? 'PENDING',
      lastLogin:
          json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
      numberTwo: json['numberTwo'] ?? false,
      voter: json['voter'] ?? false,
    );
  }
}
