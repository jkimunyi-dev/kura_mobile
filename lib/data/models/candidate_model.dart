import 'package:kuraa/data/models/user_model.dart';

class CandidateModel {
  final int id;
  final UserModel user;
  final PositionModel position;
  final String facultyCode;
  final String departmentCode;
  final String manifesto;
  final DateTime createdAt;
  final int voteCount;
  final bool active;

  CandidateModel({
    required this.id,
    required this.user,
    required this.position,
    required this.facultyCode,
    required this.departmentCode,
    required this.manifesto,
    required this.createdAt,
    required this.voteCount,
    required this.active,
  });

  factory CandidateModel.fromJson(Map<String, dynamic> json) {
    return CandidateModel(
      id: json['id'] ?? 0,
      user: UserModel.fromJson(json['user'] ?? {}),
      position: PositionModel.fromJson(json['position'] ?? {}),
      facultyCode: json['facultyCode'] ?? '',
      departmentCode: json['departmentCode'] ?? '',
      manifesto: json['manifesto'] ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      voteCount: json['voteCount'] ?? 0,
      active: json['active'] ?? false,
    );
  }
}

class PositionModel {
  final int id;
  final String positionName;
  final int positionLevel;
  final String description;

  PositionModel({
    required this.id,
    required this.positionName,
    required this.positionLevel,
    required this.description,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      id: json['id'],
      positionName: json['positionName'],
      positionLevel: json['positionLevel'],
      description: json['description'],
    );
  }
}
