class BusDirection {
  final String destination;
  final List<String> via;
  final String estimatedTime;

  BusDirection({
    required this.destination,
    required this.via,
    required this.estimatedTime,
  });

  factory BusDirection.fromJson(Map<String, dynamic> json) {
    return BusDirection(
      destination: json['destination'] as String,
      via: List<String>.from(json['via'] as List),
      estimatedTime: json['estimated_time'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'destination': destination,
      'via': via,
      'estimated_time': estimatedTime,
    };
  }
}

class BusDirectionData {
  final Map<String, BusDirection> directions;
  final String frequency;
  final String status;

  BusDirectionData({
    required this.directions,
    required this.frequency,
    required this.status,
  });

  factory BusDirectionData.fromJson(Map<String, dynamic> json) {
    final directionsJson = json['directions'] as Map<String, dynamic>;
    final directions = directionsJson.map(
      (key, value) => MapEntry(key, BusDirection.fromJson(value)),
    );

    return BusDirectionData(
      directions: directions,
      frequency: json['frequency'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'directions': directions.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'frequency': frequency,
      'status': status,
    };
  }
}
