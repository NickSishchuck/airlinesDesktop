// models/report.dart
class SalesReport {
  final String flightNumber;
  final String origin;
  final String destination;
  final DateTime flightDate;
  final int ticketsSold;
  final double totalRevenue;
  final String ticketClass;
  final int totalCapacity;
  final double occupancyPercentage;

  SalesReport({
    required this.flightNumber,
    required this.origin,
    required this.destination,
    required this.flightDate,
    required this.ticketsSold,
    required this.totalRevenue,
    required this.ticketClass,
    required this.totalCapacity,
    required this.occupancyPercentage,
  });

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    return SalesReport(
      // Add null checks for string fields
      flightNumber: json['flight_number'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',

      // Handle potentially null date
      flightDate: json['flight_date'] != null
          ? DateTime.parse(json['flight_date'])
          : DateTime.now(),

      // Handle tickets_sold with null check and type conversions
      ticketsSold: json['tickets_sold'] == null
          ? 0
          : (json['tickets_sold'] is String
          ? int.parse(json['tickets_sold'])
          : json['tickets_sold']),

      // Handle total_revenue with null check and type conversions
      totalRevenue: json['total_revenue'] == null
          ? 0.0
          : (json['total_revenue'] is int
          ? json['total_revenue'].toDouble()
          : (json['total_revenue'] is String
          ? double.parse(json['total_revenue'])
          : json['total_revenue'])),

      // Add null check for ticket_class
      ticketClass: json['ticket_class'] ?? '',

      // Handle total_capacity with null check and type conversions
      totalCapacity: json['total_capacity'] == null
          ? 0
          : (json['total_capacity'] is String
          ? int.parse(json['total_capacity'])
          : json['total_capacity']),

      // Handle occupancy_percentage with null check and type conversions
      occupancyPercentage: json['occupancy_percentage'] == null
          ? 0.0
          : (json['occupancy_percentage'] is int
          ? json['occupancy_percentage'].toDouble()
          : (json['occupancy_percentage'] is String
          ? double.parse(json['occupancy_percentage'])
          : json['occupancy_percentage'])),
    );
  }
}