class SeatStats {
  final ClassStats? economy;
  final ClassStats? business;
  final ClassStats? first;
  final ClassStats? womanOnly;
  final TotalStats? total;

  SeatStats({
    this.economy,
    this.business,
    this.first,
    this.womanOnly,
    this.total,
  });




  factory SeatStats.fromJson(Map<String, dynamic> json) {
    return SeatStats(
      economy: json['by_class']?['economy'] != null
          ? ClassStats.fromJson(json['by_class']['economy'])
          : null,
      business: json['by_class']?['business'] != null
          ? ClassStats.fromJson(json['by_class']['business'])
          : null,
      first: json['by_class']?['first'] != null
          ? ClassStats.fromJson(json['by_class']['first'])
          : null,
      womanOnly: json['by_class']?['woman_only'] != null
          ? ClassStats.fromJson(json['by_class']['woman_only'])
          : null,
      total: json['total'] != null ? TotalStats.fromJson(json['total']) : null,
    );
  }
}

class ClassStats {
  final int available;
  final int booked;
  final int total;
  final int occupancyPercentage;

  ClassStats({
    required this.available,
    required this.booked,
    required this.total,
    required this.occupancyPercentage,
  });

  factory ClassStats.fromJson(Map<String, dynamic> json) {
    return ClassStats(
      available: json['available'] is String
          ? int.tryParse(json['available']) ?? 0
          : json['available'] ?? 0,
      booked: json['booked'] is String
          ? int.tryParse(json['booked']) ?? 0
          : json['booked'] ?? 0,
      total: json['total'] is String
          ? int.tryParse(json['total']) ?? 0
          : json['total'] ?? 0,
      occupancyPercentage: json['occupancy_percentage'] is int
          ? json['occupancy_percentage']
          : json['occupancy_percentage'] is double
          ? json['occupancy_percentage'].toInt()
          : json['occupancy_percentage'] is String
          ? int.tryParse(json['occupancy_percentage']) ?? 0
          : 0,
    );
  }
}

class TotalStats {
  final int available;
  final int booked;
  final int total;
  final int occupancyPercentage;

  TotalStats({
    required this.available,
    required this.booked,
    required this.total,
    required this.occupancyPercentage,
  });

  factory TotalStats.fromJson(Map<String, dynamic> json) {
    return TotalStats(
      available: json['available'] is String
          ? int.tryParse(json['available']) ?? 0
          : json['available'] ?? 0,
      booked: json['booked'] is String
          ? int.tryParse(json['booked']) ?? 0
          : json['booked'] ?? 0,
      total: json['total'] is String
          ? int.tryParse(json['total']) ?? 0
          : json['total'] ?? 0,
      occupancyPercentage: json['occupancy_percentage'] is int
          ? json['occupancy_percentage']
          : json['occupancy_percentage'] is double
          ? json['occupancy_percentage'].toInt()
          : json['occupancy_percentage'] is String
          ? int.tryParse(json['occupancy_percentage']) ?? 0
          : 0,
    );
  }
}