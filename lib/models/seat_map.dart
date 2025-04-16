import 'seat_stats.dart';

class SeatMap {
  final Map<String, ClassSeats> seatsByClass;
  final SeatStats? stats;
  final Map<String, double>? prices;

  SeatMap({
    required this.seatsByClass,
    this.stats,
    this.prices,
  });

  factory SeatMap.fromJson(Map<String, dynamic> json) {
    final Map<String, ClassSeats> seatsByClass = {};

    if (json['seat_map'] != null) {
      json['seat_map'].forEach((className, seats) {
        seatsByClass[className] = ClassSeats.fromJson(seats);
      });
    }

    return SeatMap(
      seatsByClass: seatsByClass,
      stats: json['stats'] != null ? SeatStats.fromJson(json['stats']) : null,
      prices: json['prices'] != null ? Map<String, double>.from(json['prices']) : null,
    );
  }

  bool get isInitialized => seatsByClass.isNotEmpty;
}

class ClassSeats {
  final List<String> available;
  final List<String> booked;

  ClassSeats({
    required this.available,
    required this.booked,
  });

  factory ClassSeats.fromJson(Map<String, dynamic> json) {
    return ClassSeats(
      available: List<String>.from(json['available'] ?? []),
      booked: List<String>.from(json['booked'] ?? []),
    );
  }
}