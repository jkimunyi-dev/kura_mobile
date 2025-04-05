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
      id: json['id'] ?? 0,
      positionName: json['positionName'] ?? '',
      positionLevel: json['positionLevel'] ?? 0,
      description: json['description'] ?? '',
    );
  }
}