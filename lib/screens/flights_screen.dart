import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../services/api_service.dart';
import '../models/flight.dart';
import '../utils/constants.dart';

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

  Future<void> _searchFlights() async {
    // First, validate all required fields
    if (_originController.text.isEmpty ||
        _destinationController.text.isEmpty ||
        _dateController.text.isEmpty) {
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
      final date = _dateController.text.trim();

      final response = await _apiService.searchFlights(
        origin,
        destination,
        date,
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
      _dateController.clear();
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

    String status = isEditing ? flight.status : 'scheduled';

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
                    TextField(
                      controller: flightNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Flight Number',
                      ),
                    ),
                    TextField(
                      controller: originController,
                      decoration: const InputDecoration(
                        labelText: 'Origin',
                      ),
                    ),
                    TextField(
                      controller: destinationController,
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                      ),
                    ),
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

  Future<void> _cancelFlight(Flight flight) async {
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
                        Expanded(
                          child: TextField(
                            controller: _dateController,
                            decoration: const InputDecoration(
                              labelText: 'Date (YYYY-MM-DD)',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            onTap: () => _selectDate(context),
                          ),
                        ),
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
                              size: ColumnSize.L,
                            ),
                            DataColumn2(
                              label: Text('Departure'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Arrival'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Status'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Aircraft'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Actions'),
                              size: ColumnSize.L,
                            ),
                          ],
                          rows: _flights.map((flight) {
                            return DataRow(
                              cells: [
                                DataCell(Text(flight.flightNumber)),
                                DataCell(Text('${flight.origin} → ${flight.destination}')),
                                DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(flight.departureTime))),
                                DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(flight.arrivalTime))),
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
                                DataCell(Text(flight.aircraftModel)),
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
                        ),
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