import 'seat_map.dart';

class Flight {
  final int flightId;
  final String flightNumber;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String status;
  final String? gate;
  final String aircraftModel;
  final String registrationNumber;
  final int? bookedSeats;
  final int? totalCapacity;
  final int? crewId;
  final String? crewName;
  final double? basePrice;
  final double? firstClassMultiplier;
  final double? businessClassMultiplier;
  final double? economyClassMultiplier;
  final double? womanOnlyMultiplier;

  // Add seat stats
  SeatMap? seatMap;

  Flight({
    required this.flightId,
    required this.flightNumber,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.status,
    this.gate,
    required this.aircraftModel,
    required this.registrationNumber,
    this.bookedSeats,
    this.totalCapacity,
    this.crewId,
    this.crewName,
    this.basePrice,
    this.firstClassMultiplier,
    this.businessClassMultiplier,
    this.economyClassMultiplier,
    this.womanOnlyMultiplier,
    this.seatMap,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      // Existing properties
      flightId: json['flight_id'] ?? 0,
      flightNumber: json['flight_number']?.toString() ?? 'Unknown',
      origin: json['origin']?.toString() ?? 'Unknown',
      destination: json['destination']?.toString() ?? 'Unknown',
      departureTime: json['departure_time'] != null
          ? DateTime.parse(json['departure_time'].toString())
          : DateTime.now(),
      arrivalTime: json['arrival_time'] != null
          ? DateTime.parse(json['arrival_time'].toString())
          : DateTime.now().add(const Duration(hours: 2)),
      status: json['status']?.toString() ?? 'unknown',
      gate: json['gate']?.toString(),
      aircraftModel: json['aircraft_model']?.toString() ?? 'Unknown',
      registrationNumber: json['registration_number']?.toString() ?? 'Unknown',
      bookedSeats: json['booked_seats'],
      totalCapacity: json['total_capacity'],
      crewId: json['crew_id'],
      crewName: json['crew_name']?.toString(),

      // New properties
      // In lib/models/flight.dart - update the end of the fromJson method

// Replace the current price and multiplier parsing with this more robust version:
      basePrice: json['base_price'] != null
          ? (json['base_price'] is int
          ? json['base_price'].toDouble()
          : json['base_price'] is double
          ? json['base_price']
          : double.tryParse(json['base_price'].toString()) ?? 0.0)
          : null,
      firstClassMultiplier: json['first_class_multiplier'] != null
          ? (json['first_class_multiplier'] is int
          ? json['first_class_multiplier'].toDouble()
          : json['first_class_multiplier'] is double
          ? json['first_class_multiplier']
          : double.tryParse(json['first_class_multiplier'].toString()) ?? 4.0)
          : 4.0,
      businessClassMultiplier: json['business_class_multiplier'] != null
          ? (json['business_class_multiplier'] is int
          ? json['business_class_multiplier'].toDouble()
          : json['business_class_multiplier'] is double
          ? json['business_class_multiplier']
          : double.tryParse(json['business_class_multiplier'].toString()) ?? 2.5)
          : 2.5,
      economyClassMultiplier: json['economy_class_multiplier'] != null
          ? (json['economy_class_multiplier'] is int
          ? json['economy_class_multiplier'].toDouble()
          : json['economy_class_multiplier'] is double
          ? json['economy_class_multiplier']
          : double.tryParse(json['economy_class_multiplier'].toString()) ?? 1.0)
          : 1.0,
      womanOnlyMultiplier: json['woman_only_multiplier'] != null
          ? (json['woman_only_multiplier'] is int
          ? json['woman_only_multiplier'].toDouble()
          : json['woman_only_multiplier'] is double
          ? json['woman_only_multiplier']
          : double.tryParse(json['woman_only_multiplier'].toString()) ?? 1.2)
          : 1.2,
    );
  }
}