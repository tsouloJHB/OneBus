class BusRouteInfo {
  final int id;
  final String busNumber;
  final String companyName;
  final String routeName;
  final String description;
  final String startDestination;
  final String endDestination;
  final String direction;
  final double distanceKm;
  final int estimatedDurationMinutes;
  final int frequencyMinutes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusRouteInfo({
    required this.id,
    required this.busNumber,
    required this.companyName,
    required this.routeName,
    required this.description,
    required this.startDestination,
    required this.endDestination,
    required this.direction,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.frequencyMinutes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusRouteInfo.fromJson(Map<String, dynamic> json) {
    return BusRouteInfo(
      id: json['id'] ?? 0,
      busNumber: json['busNumber'] ?? '',
      companyName: json['companyName'] ?? '',
      routeName: json['routeName'] ?? '',
      description: json['description'] ?? '',
      startDestination: json['startDestination'] ?? '',
      endDestination: json['endDestination'] ?? '',
      direction: json['direction'] ?? '',
      distanceKm: (json['distanceKm'] ?? 0).toDouble(),
      estimatedDurationMinutes: json['estimatedDurationMinutes'] ?? 0,
      frequencyMinutes: json['frequencyMinutes'] ?? 0,
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'busNumber': busNumber,
      'companyName': companyName,
      'routeName': routeName,
      'description': description,
      'startDestination': startDestination,
      'endDestination': endDestination,
      'direction': direction,
      'distanceKm': distanceKm,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'frequencyMinutes': frequencyMinutes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'BusRouteInfo(id: $id, busNumber: $busNumber, companyName: $companyName, routeName: $routeName)';
  }
}
