// models/flight.dart
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
  final String? captainName;

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
    this.captainName,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      // Use null-aware operators for all fields
      flightId: json['flight_id'] ?? 0,
      flightNumber: json['flight_number']?.toString() ?? 'Unknown',
      origin: json['origin']?.toString() ?? 'Unknown',
      destination: json['destination']?.toString() ?? 'Unknown',

      // Handle potentially null DateTime fields
      departureTime: json['departure_time'] != null
          ? DateTime.parse(json['departure_time'].toString())
          : DateTime.now(),
      arrivalTime: json['arrival_time'] != null
          ? DateTime.parse(json['arrival_time'].toString())
          : DateTime.now().add(const Duration(hours: 2)),

      // More string fields with null handling
      status: json['status']?.toString() ?? 'unknown',
      gate: json['gate']?.toString(),
      aircraftModel: json['aircraft_model']?.toString() ?? 'Unknown',
      registrationNumber: json['registration_number']?.toString() ?? 'Unknown',

      // Optional numeric fields
      bookedSeats: json['booked_seats'],
      totalCapacity: json['total_capacity'],
      captainName: json['captain_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flight_id': flightId,
      'flight_number': flightNumber,
      'origin': origin,
      'destination': destination,
      'departure_time': departureTime.toIso8601String(),
      'arrival_time': arrivalTime.toIso8601String(),
      'status': status,
      'gate': gate,
      'aircraft_model': aircraftModel,
      'registration_number': registrationNumber,
      'booked_seats': bookedSeats,
      'total_capacity': totalCapacity,
      'captain_name': captainName,
    };
  }
}