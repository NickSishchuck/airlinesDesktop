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

    // Handle prices with type safety
    Map<String, double>? prices;
    if (json['prices'] != null) {
      prices = {};
      json['prices'].forEach((key, value) {
        if (value is int) {
          prices![key] = value.toDouble();
        } else if (value is double) {
          prices![key] = value;
        } else if (value is String) {
          prices![key] = double.tryParse(value) ?? 0.0;
        }
      });
    }

    return SeatMap(
      seatsByClass: seatsByClass,
      stats: json['stats'] != null ? SeatStats.fromJson(json['stats']) : null,
      prices: prices,
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