import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../models/seat_stats.dart';
import '../services/api_service.dart';
import '../models/flight.dart';
import '../utils/constants.dart';
import '../models/seat_map.dart';
import '../models/seat_stats.dart';

class FlightsScreen extends StatefulWidget {
  const FlightsScreen({Key? key}) : super(key: key);

  @override
  State<FlightsScreen> createState() => _FlightsScreenState();
}

class _FlightsScreenState extends State<FlightsScreen> {
  final ApiService _apiService = ApiService();
  List<Flight> _flights = [];
  bool _isLoading = true;
  int _page = 1;
  int _limit = 10;
  int _totalPages = 1;

  // Search parameters
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    super.dispose();
  }
  void _showCrewDialog(Map<String, dynamic> crewData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Flight Crew: ${crewData['crew_name']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Status: ${crewData['crew_status']}'),
                const SizedBox(height: 16),

                // Captains
                if ((crewData['captains'] as List).isNotEmpty) ...[
                  const Text(
                    'Captains',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...((crewData['captains'] as List).map((captain) => Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                    child: Text(
                      '${captain['first_name']} ${captain['last_name']} - License: ${captain['license_number']}',
                    ),
                  ))),
                  const SizedBox(height: 16),
                ],

                // Pilots
                if ((crewData['pilots'] as List).isNotEmpty) ...[
                  const Text(
                    'Pilots',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...((crewData['pilots'] as List).map((pilot) => Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                    child: Text(
                      '${pilot['first_name']} ${pilot['last_name']} - License: ${pilot['license_number']}',
                    ),
                  ))),
                  const SizedBox(height: 16),
                ],

                // Flight Attendants
                if ((crewData['flight_attendants'] as List).isNotEmpty) ...[
                  const Text(
                    'Flight Attendants',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...((crewData['flight_attendants'] as List).map((attendant) => Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                    child: Text(
                      '${attendant['first_name']} ${attendant['last_name']} - Exp: ${attendant['experience_years']} years',
                    ),
                  ))),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Add this method to load seat maps for flights
  Future<void> _loadFlightSeatMaps() async {
    // Only load for flights without seat maps
    final flightsToLoad = _flights.where((f) => f.seatMap == null).toList();

    for (final flight in flightsToLoad) {
      try {
        final response = await _apiService.getFlightSeatMap(flight.flightId);

        if (response['success'] && mounted) {
          setState(() {
            flight.seatMap = SeatMap.fromJson(response['data']);
          });
        }
      } catch (e) {
        // Seat map not initialized yet - this is expected for some flights
        if (kDebugMode) {
          print('No seat map for flight ${flight.flightId}: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _loadFlights() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getAllFlights(page: _page, limit: _limit);

      if (response['success']) {
        final List flightsData = response['data'];
        final flights = flightsData.map((data) => Flight.fromJson(data)).toList();

        setState(() {
          _flights = flights;
          _totalPages = response['pagination']['totalPages'] ?? 1;
          _isLoading = false;
        });

        // Load seat maps after loading flights
        _loadFlightSeatMaps();
      } else {
        throw Exception('Failed to load flights');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading flights: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  // Add this method to initialize flight seats
  Future<void> _initializeFlightSeats(Flight flight) async {
    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initialize Flight Seats'),
        content: Text('Are you sure you want to initialize seats for flight ${flight.flightNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Initialize'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        EasyLoading.show(status: 'Initializing seats...');
        final response = await _apiService.initializeFlightSeats(flight.flightId);
        EasyLoading.dismiss();

        if (response['success']) {
          // Update the flight's seat map in our state
          setState(() {
            flight.seatMap = SeatMap.fromJson(response['data']);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seats initialized successfully'),
              backgroundColor: AppColors.successColor,
            ),
          );
        } else {
          throw Exception(response['error'] ?? 'Failed to initialize seats');
        }
      } catch (e) {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing seats: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

// Add this method to view the seat map
  void _viewSeatMap(Flight flight) {
    if (flight.seatMap == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seats not initialized yet'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seat Map: ${flight.flightNumber}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Route and time info
              Text(
                '${flight.origin} → ${flight.destination}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${DateFormat('MMM dd, HH:mm').format(flight.departureTime)} - ${DateFormat('MMM dd, HH:mm').format(flight.arrivalTime)}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Seat stats table
              if (flight.seatMap?.stats != null) ...[
                const Text(
                  'Seat Availability',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _buildSeatStatsTable(flight.seatMap!.stats!),
                const SizedBox(height: 20),
              ],

              // Class prices
              if (flight.seatMap?.prices != null) ...[
                const Text(
                  'Class Prices',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _buildPricesTable(flight.seatMap!.prices!),
                const SizedBox(height: 20),
              ],

              // Seat map visualization
              const Text(
                'Seat Map',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildSeatMapVisualization(flight.seatMap!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

// Helper methods for seat visualization
  Widget _buildSeatStatsTable(SeatStats stats) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1.2),
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: const [
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Available', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Booked', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Occupancy', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        // First Class
        if (stats.first != null)
          _buildStatsRow('First', stats.first!, Colors.indigo.shade100),
        // Business Class
        if (stats.business != null)
          _buildStatsRow('Business', stats.business!, Colors.blue.shade100),
        // Economy Class
        if (stats.economy != null)
          _buildStatsRow('Economy', stats.economy!, Colors.green.shade100),
        // Woman Only Class
        if (stats.womanOnly != null)
          _buildStatsRow('Woman Only', stats.womanOnly!, Colors.pink.shade100),
        // Total
        if (stats.total != null)
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade200),
            children: [
              const TableCell(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(stats.total!.available.toString()),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(stats.total!.booked.toString()),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(stats.total!.total.toString()),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('${stats.total!.occupancyPercentage}%'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  TableRow _buildStatsRow(String className, ClassStats stats, Color bgColor) {
    return TableRow(
      decoration: BoxDecoration(color: bgColor),
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(className),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(stats.available.toString()),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(stats.booked.toString()),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(stats.total.toString()),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('${stats.occupancyPercentage}%'),
          ),
        ),
      ],
    );
  }

  Widget _buildPricesTable(Map<String, double> prices) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: const [
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        // Price rows
        if (prices.containsKey('first'))
          _buildPriceRow('First Class', prices['first']!, Colors.indigo.shade100),
        if (prices.containsKey('business'))
          _buildPriceRow('Business Class', prices['business']!, Colors.blue.shade100),
        if (prices.containsKey('economy'))
          _buildPriceRow('Economy Class', prices['economy']!, Colors.green.shade100),
        if (prices.containsKey('woman_only'))
          _buildPriceRow('Woman Only', prices['woman_only']!, Colors.pink.shade100),
      ],
    );
  }

  TableRow _buildPriceRow(String className, double price, Color bgColor) {
    return TableRow(
      decoration: BoxDecoration(color: bgColor),
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(className),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('\$${price.toStringAsFixed(2)}'),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatMapVisualization(SeatMap seatMap) {
    // Simple version - this could be enhanced with actual seat layout graphics
    return Column(
      children: [
        // First Class
        if (seatMap.seatsByClass.containsKey('first'))
          _buildSeatClassSection('First Class', seatMap.seatsByClass['first']!, Colors.indigo),

        // Business Class
        if (seatMap.seatsByClass.containsKey('business'))
          _buildSeatClassSection('Business Class', seatMap.seatsByClass['business']!, Colors.blue),

        // Woman Only Class
        if (seatMap.seatsByClass.containsKey('woman_only'))
          _buildSeatClassSection('Woman Only', seatMap.seatsByClass['woman_only']!, Colors.pink),

        // Economy Class
        if (seatMap.seatsByClass.containsKey('economy'))
          _buildSeatClassSection('Economy Class', seatMap.seatsByClass['economy']!, Colors.green),
      ],
    );
  }

  Widget _buildSeatClassSection(String className, ClassSeats seats, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          color: color.withOpacity(0.2),
          child: Text(
            className,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Available seats
            ...seats.available.map((seat) => _buildSeatChip(seat, true, color)),
            // Booked seats
            ...seats.booked.map((seat) => _buildSeatChip(seat, false, color)),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSeatChip(String seatNumber, bool available, Color color) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: available ? color.withOpacity(0.1) : Colors.grey.shade300,
        border: Border.all(
          color: available ? color : Colors.grey,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        seatNumber,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Future<void> _searchFlights() async {
    // First, validate all required fields
    if (_originController.text.isEmpty ||
        _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all search fields'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure we're sending non-null values
      final origin = _originController.text.trim();
      final destination = _destinationController.text.trim();

      final response = await _apiService.searchFlightsByRoute(
        origin,
        destination
      );

      if (response['success']) {
        final List flightsData = response['data'] ?? [];
        final flights = flightsData.map((data) {
          // Handle potentially null values when mapping flight data
          try {
            return Flight.fromJson(data);
          } catch (e) {
            print('Error parsing flight data: $e');
            return null;
          }
        })
            .where((flight) => flight != null)
            .cast<Flight>()
            .toList();

        setState(() {
          _flights = flights;
          _isLoading = false;
          _isSearchMode = true;
        });
      } else {
        throw Exception('No flights found for the specified search criteria');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search error: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _resetSearch() {
    setState(() {
      _originController.clear();
      _destinationController.clear();
      _isSearchMode = false;
      _page = 1;
    });
    _loadFlights();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _showFlightDialog({Flight? flight}) async {
    final bool isEditing = flight != null;
    final TextEditingController flightNumberController = TextEditingController(text: isEditing ? flight.flightNumber : '');
    final TextEditingController originController = TextEditingController(text: isEditing ? flight.origin : '');
    final TextEditingController destinationController = TextEditingController(text: isEditing ? flight.destination : '');
    final TextEditingController departureDateController = TextEditingController(
        text: isEditing ? DateFormat('yyyy-MM-dd').format(flight.departureTime) : '');
    final TextEditingController departureTimeController = TextEditingController(
        text: isEditing ? DateFormat('HH:mm').format(flight.departureTime) : '');
    final TextEditingController arrivalDateController = TextEditingController(
        text: isEditing ? DateFormat('yyyy-MM-dd').format(flight.arrivalTime) : '');
    final TextEditingController arrivalTimeController = TextEditingController(
        text: isEditing ? DateFormat('HH:mm').format(flight.arrivalTime) : '');
    final TextEditingController gateController = TextEditingController(text: isEditing ? flight.gate ?? '' : '');
    final TextEditingController aircraftModelController = TextEditingController(text: isEditing ? flight.aircraftModel : '');
    final TextEditingController registrationNumberController = TextEditingController(text: isEditing ? flight.registrationNumber : '');


    // Set a default status that exists in the dropdown options if the current status is not valid
    String status = isEditing ? flight.status : 'scheduled';

    // List of valid status options
    const List<String> validStatusOptions = [
      'scheduled', 'delayed', 'boarding', 'departed', 'arrived', 'canceled'
    ];

    // If the flight's status is not in the valid options, default to 'scheduled'
    if (isEditing && !validStatusOptions.contains(status)) {
      status = 'scheduled';
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Flight' : 'Add New Flight'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // If editing, show flight identifier section
                    if (isEditing) ...[
                      Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: AppColors.infoColor),
                                SizedBox(width: 8),
                                Text(
                                  'Flight Identifiers',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.infoColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'These critical details should rarely be changed',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 12),
                            // Flight number field (read-only in edit mode)
                            TextField(
                              controller: flightNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Flight Number',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              readOnly: true, // Always read-only when editing
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: originController,
                                    decoration: const InputDecoration(
                                      labelText: 'Origin',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    readOnly: true, // Always read-only when editing
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.grey),
                                SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: destinationController,
                                    decoration: const InputDecoration(
                                      labelText: 'Destination',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    readOnly: true, // Always read-only when editing
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      Divider(),
                      SizedBox(height: 16),
                    ] else ...[
                      // If creating new flight, show normal fields
                      TextField(
                        controller: flightNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Flight Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: originController,
                        decoration: const InputDecoration(
                          labelText: 'Origin',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: destinationController,
                        decoration: const InputDecoration(
                          labelText: 'Destination',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: departureDateController,
                            decoration: const InputDecoration(
                              labelText: 'Departure Date',
                            ),
                            readOnly: true,
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: isEditing ? flight!.departureTime : DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() {
                                  departureDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: departureTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Departure Time',
                            ),
                            readOnly: true,
                            onTap: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: isEditing
                                    ? TimeOfDay.fromDateTime(flight!.departureTime)
                                    : TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  departureTimeController.text =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: arrivalDateController,
                            decoration: const InputDecoration(
                              labelText: 'Arrival Date',
                            ),
                            readOnly: true,
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: isEditing ? flight!.arrivalTime : DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() {
                                  arrivalDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: arrivalTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Arrival Time',
                            ),
                            readOnly: true,
                            onTap: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: isEditing
                                    ? TimeOfDay.fromDateTime(flight!.arrivalTime)
                                    : TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  arrivalTimeController.text =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: gateController,
                      decoration: const InputDecoration(
                        labelText: 'Gate',
                      ),
                    ),
                    TextField(
                      controller: aircraftModelController,
                      decoration: const InputDecoration(
                        labelText: 'Aircraft Model',
                      ),
                    ),
                    TextField(
                      controller: registrationNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Registration Number',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                        DropdownMenuItem(value: 'delayed', child: Text('Delayed')),
                        DropdownMenuItem(value: 'boarding', child: Text('Boarding')),
                        DropdownMenuItem(value: 'departed', child: Text('Departed')),
                        DropdownMenuItem(value: 'arrived', child: Text('Arrived')),
                        DropdownMenuItem(value: 'canceled', child: Text('Canceled')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          status = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // Validate inputs
                    if (flightNumberController.text.isEmpty ||
                        originController.text.isEmpty ||
                        destinationController.text.isEmpty ||
                        departureDateController.text.isEmpty ||
                        departureTimeController.text.isEmpty ||
                        arrivalDateController.text.isEmpty ||
                        arrivalTimeController.text.isEmpty ||
                        aircraftModelController.text.isEmpty ||
                        registrationNumberController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
                          backgroundColor: AppColors.warningColor,
                        ),
                      );
                      return;
                    }

                    try {
                      // Parse dates
                      final departureDateTime = DateTime.parse(
                          '${departureDateController.text} ${departureTimeController.text}:00');
                      final arrivalDateTime = DateTime.parse(
                          '${arrivalDateController.text} ${arrivalTimeController.text}:00');

                      // Create flight data
                      final flightData = {
                        'flight_number': flightNumberController.text,
                        'origin': originController.text,
                        'destination': destinationController.text,
                        'departure_time': departureDateTime.toIso8601String(),
                        'arrival_time': arrivalDateTime.toIso8601String(),
                        'gate': gateController.text,
                        'status': status,
                        'aircraft_model': aircraftModelController.text,
                        'registration_number': registrationNumberController.text,
                      };

                      Navigator.of(context).pop();
                      EasyLoading.show(status: isEditing ? 'Updating flight...' : 'Creating flight...');

                      if (isEditing) {
                        await _apiService.updateFlight(flight!.flightId, flightData);
                      } else {
                        await _apiService.createFlight(flightData);
                      }

                      EasyLoading.dismiss();
                      _loadFlights();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Flight updated successfully' : 'Flight created successfully'),
                          backgroundColor: AppColors.successColor,
                        ),
                      );
                    } catch (e) {
                      EasyLoading.dismiss();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: AppColors.errorColor,
                        ),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getSeatAvailabilityColor(int available, int total) {
    if (total == 0) return Colors.grey;

    final ratio = available / total;
    if (ratio < 0.2) return AppColors.errorColor;
    if (ratio < 0.5) return AppColors.warningColor;
    return AppColors.successColor;
  }
  Future<void> _cancelFlight(Flight flight) async {
    // Add confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: Text('Are you sure you want to cancel flight ${flight.flightNumber}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes, Cancel Flight'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
              ),
            ),
          ],
        );
      },
    ) ?? false;

    // Only proceed if user confirmed
    if (confirm) {
      try {
        EasyLoading.show(status: 'Canceling flight...');
        await _apiService.cancelFlight(flight.flightId);
        EasyLoading.dismiss();

        _loadFlights();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flight canceled successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } catch (e) {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error canceling flight: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteFlight(Flight flight) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete flight ${flight.flightNumber}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
              )
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        EasyLoading.show(status: 'Deleting flight...');
        await _apiService.deleteFlight(flight.flightId);
        EasyLoading.dismiss();

        _loadFlights();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flight deleted successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } catch (e) {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting flight: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Panel
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search Flights',
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _originController,
                            decoration: const InputDecoration(
                              labelText: 'Origin',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _destinationController,
                            decoration: const InputDecoration(
                              labelText: 'Destination',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _searchFlights,
                          icon: const Icon(Icons.search),
                          label: const Text('Search'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_isSearchMode)
                          OutlinedButton.icon(
                            onPressed: _resetSearch,
                            icon: const Icon(Icons.clear),
                            label: const Text('Reset'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Flights Table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Flights List',
                            style: AppTextStyles.title,
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showFlightDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add New Flight'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _flights.isEmpty
                            ? const Center(child: Text('No flights found'))
                            : DataTable2(
                          columns: const [
                            DataColumn2(
                              label: Text('Flight'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Route'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Date/Time'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Status'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Economy'),
                              size: ColumnSize.S,
                              numeric: true,
                            ),
                            DataColumn2(
                              label: Text('Business'),
                              size: ColumnSize.S,
                              numeric: true,
                            ),
                            DataColumn2(
                              label: Text('First'),
                              size: ColumnSize.S,
                              numeric: true,
                            ),
                            DataColumn2(
                              label: Text('Woman Only'),
                              size: ColumnSize.S,
                              numeric: true,
                            ),
                            DataColumn2(
                              label: Text('Seats'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Actions'),
                              size: ColumnSize.L,
                            ),
                          ],
                          rows: _flights.map((flight) {
                            final bool seatsInitialized = flight.seatMap != null && flight.seatMap!.isInitialized;

                            return DataRow(
                              cells: [
                                DataCell(Text(flight.flightNumber)),
                                DataCell(Text('${flight.origin} → ${flight.destination}')),
                                DataCell(Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(DateFormat('dd-MM-yyy').format(flight.departureTime)),
                                    Text(DateFormat('HH:mm').format(flight.departureTime)),
                                  ],
                                )),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: flightStatusColors[flight.status] ?? Colors.grey,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      flight.status,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                // Economy Seats
                                DataCell(
                                  seatsInitialized
                                      ? Text(
                                    flight.seatMap!.seatsByClass['economy']?.available.length.toString() ?? 'N/A',
                                    style: TextStyle(
                                      color: _getSeatAvailabilityColor(
                                        flight.seatMap!.stats?.economy?.available ?? 0,
                                        flight.seatMap!.stats?.economy?.total ?? 0,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                      : const Text('--'),
                                ),

                                // Business Seats
                                DataCell(
                                  seatsInitialized
                                      ? Text(
                                    flight.seatMap!.seatsByClass['business']?.available.length.toString() ?? 'N/A',
                                    style: TextStyle(
                                      color: _getSeatAvailabilityColor(
                                        flight.seatMap!.stats?.business?.available ?? 0,
                                        flight.seatMap!.stats?.business?.total ?? 0,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                      : const Text('--'),
                                ),

                                // First Class Seats
                                DataCell(
                                  seatsInitialized
                                      ? Text(
                                    flight.seatMap!.seatsByClass['first']?.available.length.toString() ?? 'N/A',
                                    style: TextStyle(
                                      color: _getSeatAvailabilityColor(
                                        flight.seatMap!.stats?.first?.available ?? 0,
                                        flight.seatMap!.stats?.first?.total ?? 0,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                      : const Text('--'),
                                ),

                                // Woman Only Seats
                                DataCell(
                                  seatsInitialized
                                      ? Text(
                                    flight.seatMap!.seatsByClass['woman_only']?.available.length.toString() ?? 'N/A',
                                    style: TextStyle(
                                      color: _getSeatAvailabilityColor(
                                        flight.seatMap!.stats?.womanOnly?.available ?? 0,
                                        flight.seatMap!.stats?.womanOnly?.total ?? 0,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                      : const Text('--'),
                                ),

                                // Seat Initialization/Visualization
                                DataCell(
                                  seatsInitialized
                                      ? ElevatedButton(
                                    onPressed: () => _viewSeatMap(flight),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.infoColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    child: const Text('View'),
                                  )
                                      : ElevatedButton(
                                    onPressed: () => _initializeFlightSeats(flight),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.warningColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    child: const Text('Initialize'),
                                  ),
                                ),

                                // Actions
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppColors.infoColor),
                                        tooltip: 'Edit Flight',
                                        onPressed: () => _showFlightDialog(flight: flight),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel, color: AppColors.warningColor),
                                        tooltip: 'Cancel Flight',
                                        onPressed: () => _cancelFlight(flight),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.errorColor),
                                        tooltip: 'Delete Flight',
                                        onPressed: () => _deleteFlight(flight),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        )
                      ),


                      // Pagination
                      if (!_isSearchMode && !_isLoading && _flights.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Page $_page of $_totalPages'),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _page > 1
                                    ? () {
                                  setState(() {
                                    _page--;
                                  });
                                  _loadFlights();
                                }
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _page < _totalPages
                                    ? () {
                                  setState(() {
                                    _page++;
                                  });
                                  _loadFlights();
                                }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}