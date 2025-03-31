class Ticket {
  final int ticketId;
  final String seatNumber;
  final String ticketClass;
  final double price;
  final DateTime bookingDate;
  final String paymentStatus;
  final String? flightNumber;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final String? origin;
  final String? destination;
  final String? passengerName;
  final String? passportNumber;
  final int? passengerId;
  final int? flightId;

  Ticket({
    required this.ticketId,
    required this.seatNumber,
    required this.ticketClass,
    required this.price,
    required this.bookingDate,
    required this.paymentStatus,
    this.flightNumber,
    this.departureTime,
    this.arrivalTime,
    this.origin,
    this.destination,
    this.passengerName,
    this.passportNumber,
    this.passengerId,
    this.flightId,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      ticketId: json['ticket_id'],
      seatNumber: json['seat_number'],
      ticketClass: json['class'],

      price: json['price'] is int
          ? json['price'].toDouble()
          : (json['price'] is String
          ? double.parse(json['price'])
          : json['price']),

      bookingDate: DateTime.parse(json['booking_date']),
      paymentStatus: json['payment_status'],
      flightNumber: json['flight_number'],
      departureTime: json['departure_time'] != null ? DateTime.parse(json['departure_time']) : null,
      arrivalTime: json['arrival_time'] != null ? DateTime.parse(json['arrival_time']) : null,
      origin: json['origin'],
      destination: json['destination'],
      passengerName: json['passenger_name'],
      passportNumber: json['passport_number'],
      passengerId: json['passenger_id'],
      flightId: json['flight_id'],
    );
  }
}