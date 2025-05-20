import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../services/api_service.dart';
import '../models/ticket.dart';
import '../utils/constants.dart';
import 'package:flutter/foundation.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({Key? key}) : super(key: key);

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final ApiService _apiService = ApiService();
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  int _page = 1;
  int _limit = 10;
  int _totalPages = 1;
  Map<String, dynamic>? _foundPassenger;
  Map<String, dynamic>? _foundFlight;
  int? _selectedPassengerId;
  int? _selectedFlightId;

  // Search parameters
  final TextEditingController _searchFlightController = TextEditingController();
  final TextEditingController _searchPassengerController = TextEditingController();
  final TextEditingController _searchFlightNumberController = TextEditingController();
  final TextEditingController _searchPassportNumberController = TextEditingController();

  bool _isSearchMode = false;
  String _searchType = 'flight'; // 'flight', 'passenger', 'flightNumber', or 'passportNumber'

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _searchFlightController.dispose();
    _searchPassengerController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSeats(int flightId, String seatClass, TextEditingController seatNumberController) async {
    try {
      EasyLoading.show(status: 'Loading available seats...');
      final response = await _apiService.getAvailableSeatsByClass(flightId, seatClass);
      EasyLoading.dismiss();

      if (response['success']) {
        final availableSeats = List<String>.from(response['data']['available_seats']);

        if (availableSeats.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No ${seatClass.replaceAll('_', ' ')} seats available'),
              backgroundColor: AppColors.warningColor,
            ),
          );
          return;
        }

        // Show available seats dialog
        final selected = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Available ${_formatTicketClass(seatClass)} Seats'),
            content: SizedBox(
              width: 300,
              height: 400,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableSeats.map((seat) {
                    final Color classColor = _getClassColor(seatClass);

                    return InkWell(
                      onTap: () => Navigator.of(context).pop(seat),
                      child: Container(
                        width: 45,
                        height: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: classColor.withOpacity(0.1),
                          border: Border.all(color: classColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          seat,
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );

        // Update seat number if a seat was selected
        if (selected != null && mounted) {
          setState(() {
            seatNumberController.text = selected;
          });
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to load available seats');
      }
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading seats: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

// Add a helper to format ticket classes
  String _formatTicketClass(String ticketClass) {
    switch (ticketClass) {
      case 'economy':
        return 'Economy';
      case 'business':
        return 'Business';
      case 'first':
        return 'First Class';
      case 'woman_only':
        return 'Woman Only';
      default:
        return ticketClass.replaceAll('_', ' ');
    }
  }

// Add a helper to get class colors
  Color _getClassColor(String ticketClass) {
    switch (ticketClass) {
      case 'economy':
        return Colors.green;
      case 'business':
        return Colors.blue;
      case 'first':
        return Colors.indigo;
      case 'woman_only':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  Future<Map<String, dynamic>> _getFlightPricing(int flightId) async {
    try {
      final response = await _apiService.get('/flights/$flightId/pricing');
      if (response['success']) {
        return response['data'];
      }
      throw Exception('Failed to get flight pricing');
    } catch (e) {
      throw Exception('Error getting flight pricing: $e');
    }
  }

  void _calculateAndUpdatePrice(TextEditingController priceController, Map<String, dynamic> pricingData, String ticketClass) {
    double basePrice = pricingData['base_price'].toDouble();
    Map<String, double> classMultipliers = {
      'economy': 1.0,
      'business': pricingData['business_multiplier'].toDouble(),
      'first': pricingData['first_multiplier'].toDouble(),
      'woman_only': pricingData['woman_only_multiplier'].toDouble(),
    };

    double multiplier = classMultipliers[ticketClass] ?? 1.0;
    double finalPrice = basePrice * multiplier;
    priceController.text = finalPrice.toStringAsFixed(2);
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getAllTickets(page: _page, limit: _limit);

      if (response['success']) {
        final List ticketsData = response['data'];
        final tickets = ticketsData.map((data) => Ticket.fromJson(data)).toList();

        tickets.sort((a, b) => a.ticketId.compareTo(b.ticketId));

        setState(() {
          _tickets = tickets;
          _totalPages = response['pagination']['totalPages'] ?? 1;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load tickets');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading tickets: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }


  Future<void> _searchTickets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> response;

      switch (_searchType) {
        case 'flight':
          if (_searchFlightController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a Flight ID'),
                backgroundColor: AppColors.warningColor,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }

          final flightId = int.tryParse(_searchFlightController.text);
          if (flightId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Flight ID must be a number'),
                backgroundColor: AppColors.warningColor,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }

          response = await _apiService.getTicketsByFlightId(flightId);
          break;

        case 'passenger':
          if (_searchPassengerController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a Passenger ID'),
                backgroundColor: AppColors.warningColor,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }

          final passengerId = int.tryParse(_searchPassengerController.text);
          if (passengerId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Passenger ID must be a number'),
                backgroundColor: AppColors.warningColor,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }

          response = await _apiService.getTicketsByPassengerId(passengerId);
          break;

        case 'flightNumber':
          if (_searchFlightNumberController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a Flight Number'),
                backgroundColor: AppColors.warningColor,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }

          response = await _apiService.getTicketsByFlightNumber(_searchFlightNumberController.text);
          break;

        case 'passportNumber':
          if (_searchPassportNumberController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a Passport Number'),
                backgroundColor: AppColors.warningColor,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }

          response = await _apiService.getTicketsByPassportNumber(_searchPassportNumberController.text);
          break;

        default:
          throw Exception('Invalid search type');
      }

      if (response['success']) {
        final List ticketsData = response['data'];
        final tickets = ticketsData.map((data) => Ticket.fromJson(data)).toList();

        setState(() {
          _tickets = tickets;
          _isLoading = false;
          _isSearchMode = true;
        });
      } else {
        throw Exception('No tickets found for the specified search criteria');
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
      _searchFlightController.clear();
      _searchPassengerController.clear();
      _isSearchMode = false;
      _page = 1;
    });
    _loadTickets();
  }


  Future<void> _searchFlightByNumber(String flightNumber) async {
    if (flightNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a flight number'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    try {
      EasyLoading.show(status: 'Searching for flight...');
      final response = await _apiService.getFlightByNumber(flightNumber);
      EasyLoading.dismiss();

      if (response['success'] && response['data'] != null) {
        setState(() {
          _foundFlight = response['data'];
          _selectedFlightId = _foundFlight!['flight_id'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Flight found: ${_foundFlight!['flight_number']} - ${_foundFlight!['origin']} to ${_foundFlight!['destination']}'),
            backgroundColor: AppColors.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _foundFlight = null;
          _selectedFlightId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No flight found with number: $flightNumber'),
            backgroundColor: AppColors.warningColor,
          ),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching for flight: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _searchPassengerByPassport(String passportNumber) async {
    if (passportNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a passport number'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    try {
      EasyLoading.show(status: 'Searching for passenger...');
      final response = await _apiService.getPassengerByPassport(passportNumber);
      EasyLoading.dismiss();

      if (response['success'] && response['data'] != null) {
        setState(() {
          _foundPassenger = response['data'];
          _selectedPassengerId = _foundPassenger!['user_id'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Passenger found: ${_foundPassenger!['first_name']} ${_foundPassenger!['last_name']}'),
            backgroundColor: AppColors.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _foundPassenger = null;
          _selectedPassengerId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No passenger found with passport number: $passportNumber'),
            backgroundColor: AppColors.warningColor,
          ),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching for passenger: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _showTicketDialog({Ticket? ticket}) async {
    final bool isEditing = ticket != null;

    final TextEditingController seatNumberController = TextEditingController(text: isEditing ? ticket.seatNumber : '');
    final TextEditingController priceController = TextEditingController(text: isEditing ? ticket.price.toString() : '');
    final TextEditingController passengerIdController = TextEditingController(text: isEditing && ticket.passengerId != null ? ticket.passengerId.toString() : '');
    final TextEditingController flightIdController = TextEditingController(text: isEditing && ticket.flightId != null ? ticket.flightId.toString() : '');

    // Additional controllers for display purposes only (might be null in original ticket)
    final TextEditingController passengerNameController = TextEditingController(text: isEditing ? ticket.passengerName ?? 'Unknown' : '');
    final TextEditingController passportNumberController = TextEditingController(text: isEditing ? ticket.passportNumber ?? 'N/A' : '');
    final TextEditingController flightNumberController = TextEditingController(text: isEditing ? ticket.flightNumber ?? 'Unknown' : '');
    final TextEditingController routeController = TextEditingController(
        text: isEditing && ticket.origin != null && ticket.destination != null
            ? '${ticket.origin} → ${ticket.destination}'
            : ''
    );

    String ticketClass = isEditing ? ticket.ticketClass : 'economy';
    String paymentStatus = isEditing ? ticket.paymentStatus : 'pending';

    Map<String, dynamic>? flightPricing;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void searchFlightInDialog() async {
              await _searchFlightByNumber(flightNumberController.text);
              if (_foundFlight != null && !isEditing) {
                try {
                  flightPricing = await _getFlightPricing(_foundFlight!['flight_id']);
                  _calculateAndUpdatePrice(priceController, flightPricing!, ticketClass);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error calculating price: ${e.toString()}'),
                      backgroundColor: AppColors.warningColor,
                    ),
                  );
                }
              }
              setState(() {});
            }

            void searchPassengerInDialog() async {
              await _searchPassengerByPassport(passportNumberController.text);
              setState(() {});
            }

            void updatePrice() {
              if (flightPricing != null && !isEditing) {
                _calculateAndUpdatePrice(priceController, flightPricing!, ticketClass);
              }
            }

            return AlertDialog(
              title: Text(isEditing ? 'Edit Ticket' : 'Book New Ticket'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: FLIGHT INFORMATION (Critical, rarely changed)
                    if (isEditing) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.flight, color: AppColors.primaryColor),
                                SizedBox(width: 8),
                                Text(
                                  'Flight Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'These details identify the flight and cannot be changed',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 16),

                            // Flight ID - Read only
                            TextField(
                              controller: flightIdController,
                              decoration: InputDecoration(
                                labelText: 'Flight ID',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(Icons.numbers, color: Colors.grey),
                              ),
                              readOnly: true,
                              enabled: false,
                            ),
                            SizedBox(height: 12),

                            // Flight Number - Read only
                            TextField(
                              controller: flightNumberController,
                              decoration: InputDecoration(
                                labelText: 'Flight Number',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(Icons.flight_takeoff, color: Colors.grey),
                              ),
                              readOnly: true,
                              enabled: false,
                            ),
                            SizedBox(height: 12),

                            // Route - Read only
                            TextField(
                              controller: routeController,
                              decoration: InputDecoration(
                                labelText: 'Route',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(Icons.route, color: Colors.grey),
                              ),
                              readOnly: true,
                              enabled: false,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      // SECTION 2: PASSENGER INFORMATION (Critical, rarely changed)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, color: AppColors.accentColor),
                                SizedBox(width: 8),
                                Text(
                                  'Passenger Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.accentColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Passenger details are linked to this ticket',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 16),

                            // Passenger ID - Read only
                            TextField(
                              controller: passengerIdController,
                              decoration: InputDecoration(
                                labelText: 'Passenger ID',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(Icons.numbers, color: Colors.grey),
                              ),
                              readOnly: true,
                              enabled: false,
                            ),
                            SizedBox(height: 12),

                            // Passenger Name - Read only
                            if (ticket.passengerName != null) ...[
                              TextField(
                                controller: passengerNameController,
                                decoration: InputDecoration(
                                  labelText: 'Passenger Name',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                                ),
                                readOnly: true,
                                enabled: false,
                              ),
                              SizedBox(height: 12),
                            ],

                            // Passport Number - Read only
                            if (ticket.passportNumber != null) ...[
                              TextField(
                                controller: passportNumberController,
                                decoration: InputDecoration(
                                  labelText: 'Passport Number',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: Icon(Icons.book, color: Colors.grey),
                                ),
                                readOnly: true,
                                enabled: false,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      // CREATE MODE: Show editable fields for flight and passenger
                      Text(
                        'Basic Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Flight number instead of flight ID
                      TextField(
                        controller: flightNumberController,
                        decoration: InputDecoration(
                          labelText: 'Flight Number',
                          border: OutlineInputBorder(),
                          helperText: 'Enter the flight number (e.g., PS101)',
                          prefixIcon: Icon(Icons.flight),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: searchFlightInDialog,
                            tooltip: 'Search for flight',
                          ),
                        ),
                      ),
                      SizedBox(height: 8),

                      // Found flight info container (initially hidden)
                      if (_foundFlight != null) ...[
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.blue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Flight found: ${_foundFlight!['flight_number']} - ${_foundFlight!['origin']} to ${_foundFlight!['destination']}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                      ],

                      // Update passenger search button
                      TextField(
                        controller: passportNumberController,
                        decoration: InputDecoration(
                          labelText: 'Passport Number',
                          border: OutlineInputBorder(),
                          helperText: 'Enter passport number of existing passenger',
                          prefixIcon: Icon(Icons.book),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: searchPassengerInDialog, // Use the local function
                            tooltip: 'Search for passenger',
                          ),
                        ),
                      ),
                      SizedBox(height: 8),

                      // Found passenger info container (initially hidden)
                      if (_foundPassenger != null) ...[
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Found: ${_foundPassenger!['first_name']} ${_foundPassenger!['last_name']}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                      ],

                      // New Passenger button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateUserDialog(passportNumberController),
                          icon: Icon(Icons.person_add),
                          label: Text('Create New Passenger'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentColor,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 24),
                    Divider(),
                    SizedBox(height: 16),

                    // SECTION 3: TICKET DETAILS (Frequently edited)
                    Text(
                      'Ticket Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),


                    // Seat Number - Always editable
                    TextField(
                      controller: seatNumberController,
                      decoration: InputDecoration(
                        labelText: 'Seat Number',
                        border: OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.airline_seat_recline_normal),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.list),
                            tooltip: 'Select from available seats',
                            onPressed: () {
                              // Make sure we have a flight ID first
                              if (_selectedFlightId == null && !isEditing) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a flight first'),
                                    backgroundColor: AppColors.warningColor,
                                  ),
                                );
                                return;
                              }

                              final flightId = isEditing
                                  ? ticket!.flightId!
                                  : _selectedFlightId;

                              if (flightId != null) {
                                // Pass the seatNumberController to the method
                                _loadAvailableSeats(flightId, ticketClass, seatNumberController);
                              }
                            },
                          )
                      ),
                    ),

                    SizedBox(height: 16),

                    // Ticket Class - Always editable
                    DropdownButtonFormField<String>(
                      value: ticketClass,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.class_),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'economy', child: Text('Economy')),
                        DropdownMenuItem(value: 'business', child: Text('Business')),
                        DropdownMenuItem(value: 'first', child: Text('First Class')),
                        DropdownMenuItem(value: 'woman_only', child: Text('Woman Only')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          ticketClass = value!;
                          updatePrice();
                        });
                      },
                    ),
                    SizedBox(height: 12),

                    // Price field and calculate button
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              prefixText: '\$',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: TextInputType.number,
                            readOnly: !isEditing, // Make read-only when creating new ticket
                            enabled: isEditing, // Disable when creating new ticket
                          ),
                        ),
                        if (!isEditing) ...[
                          SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (_selectedFlightId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a flight first'),
                                    backgroundColor: AppColors.warningColor,
                                  ),
                                );
                                return;
                              }
                              
                              try {
                                flightPricing = await _getFlightPricing(_selectedFlightId!);
                                _calculateAndUpdatePrice(priceController, flightPricing!, ticketClass);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Price calculated based on flight and class'),
                                    backgroundColor: AppColors.successColor,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error calculating price: ${e.toString()}'),
                                    backgroundColor: AppColors.errorColor,
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.calculate),
                            label: Text('Calculate'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 12),

                    // Payment Status - Always editable
                    DropdownButtonFormField<String>(
                      value: paymentStatus,
                      decoration: const InputDecoration(
                        labelText: 'Payment Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'refunded', child: Text('Refunded')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          paymentStatus = value!;
                        });
                      },
                    ),

                    if (isEditing) ...[
                      SizedBox(height: 24),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.warningColor),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'To change flight or passenger, please delete this ticket and create a new one.',
                                style: TextStyle(
                                  color: AppColors.warningColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Clear selections and text fields
                    setState(() {
                      _foundFlight = null;
                      _selectedFlightId = null;
                      _foundPassenger = null;
                      _selectedPassengerId = null;

                      // Clear text controllers
                      flightNumberController.clear();
                      passportNumberController.clear();
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate inputs
                    if (seatNumberController.text.isEmpty ||
                        priceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
                          backgroundColor: AppColors.warningColor,
                        ),
                      );
                      return;
                    }

// Validate that we have flight and passenger IDs
                    if (_selectedFlightId == null && !isEditing) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please search for a valid flight first'),
                          backgroundColor: AppColors.warningColor,
                        ),
                      );
                      return;
                    }

                    if (_selectedPassengerId == null && !isEditing) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please search for a valid passenger or create a new one'),
                          backgroundColor: AppColors.warningColor,
                        ),
                      );
                      return;
                    }

                    final price = double.tryParse(priceController.text);
                    if (price == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Price must be a valid number'),
                          backgroundColor: AppColors.warningColor,
                        ),
                      );
                      return;
                    }

                    try {
                      // Validate that we have flight and passenger IDs
                      if (_selectedFlightId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please search for a valid flight first'),
                            backgroundColor: AppColors.warningColor,
                          ),
                        );
                        return;
                      }

                      if (_selectedPassengerId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please search for a valid passenger or create a new one'),
                            backgroundColor: AppColors.warningColor,
                          ),
                        );
                        return;
                      }

                      // Create ticket data - for editing, we only update the editable fields
                      final ticketData = isEditing ? {
                        'seat_number': seatNumberController.text,
                        'class': ticketClass,
                        'price': price,
                        'payment_status': paymentStatus,
                      } : {
                        'user_id': _selectedPassengerId,
                        'flight_id': _selectedFlightId,
                        'seat_number': seatNumberController.text,
                        'class': ticketClass,
                        'price': price,
                        'payment_status': paymentStatus,
                      };

                      Navigator.of(context).pop();
                      EasyLoading.show(status: isEditing ? 'Updating ticket...' : 'Booking ticket...');

                      if (isEditing) {
                        await _apiService.updateTicket(ticket!.ticketId, ticketData);
                      } else {
                        await _apiService.bookTicket(ticketData);
                      }

                      EasyLoading.dismiss();
                      _loadTickets();
                      // Clear selections and text fields
                      setState(() {
                        _foundFlight = null;
                        _selectedFlightId = null;
                        _foundPassenger = null;
                        _selectedPassengerId = null;

                        // Clear text controllers
                        _searchFlightNumberController.clear();
                        _searchPassportNumberController.clear();
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Ticket updated successfully' : 'Ticket booked successfully'),
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
                  child: Text(isEditing ? 'Update' : 'Book'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<void> _showCreateUserDialog(TextEditingController passportNumberController) async {
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    // If a passport number was provided, use it
    final TextEditingController passportController = TextEditingController(text: passportNumberController.text);
    final TextEditingController contactNumberController = TextEditingController();
    final TextEditingController dateOfBirthController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    DateTime? selectedDate;
    String gender = 'male';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.person_add, color: AppColors.accentColor),
                  SizedBox(width: 8),
                  Text('Create New Passenger'),
                ],
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: 500, // Set a fixed width for the dialog
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      SizedBox(height: 12),


                      // First and Last Name (in a row)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Email and Password
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                          helperText: 'Will be used for login and notifications',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16),

                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                          helperText: 'Create a temporary password for the passenger',
                        ),
                        obscureText: true,
                      ),
                      SizedBox(height: 16),

                      // Passport Number
                      TextField(
                        controller: passportController,
                        decoration: InputDecoration(
                          labelText: 'Passport Number *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.book),
                          helperText: 'Required for international flights',
                        ),
                      ),
                      SizedBox(height: 16),

                      // Date of Birth
                      TextField(
                        controller: dateOfBirthController,
                        decoration: InputDecoration(
                          labelText: 'Date of Birth *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now().subtract(Duration(days: 365 * 25)),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );

                          if (picked != null && picked != selectedDate) {
                            setState(() {
                              selectedDate = picked;
                              dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                      ),
                      SizedBox(height: 16),

                      // Contact Number
                      TextField(
                        controller: contactNumberController,
                        decoration: InputDecoration(
                          labelText: 'Contact Number *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                          helperText: 'For flight notifications and updates',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 16),

                      // Address (optional)
                      TextField(
                        controller: addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home),
                          helperText: 'Optional',
                        ),
                        maxLines: 2,
                      ),
                      SizedBox(height: 16),

                      // Gender Selection
                      Text(
                        'Gender: *',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'male',
                            groupValue: gender,
                            onChanged: (value) {
                              setState(() {
                                gender = value!;
                              });
                            },
                          ),
                          Text('Male'),
                          SizedBox(width: 16),
                          Radio<String>(
                            value: 'female',
                            groupValue: gender,
                            onChanged: (value) {
                              setState(() {
                                gender = value!;
                              });
                            },
                          ),
                          Text('Female'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '* Required fields',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate inputs
                    if (firstNameController.text.isEmpty ||
                        lastNameController.text.isEmpty ||
                        emailController.text.isEmpty ||
                        passwordController.text.isEmpty ||
                        passportController.text.isEmpty ||
                        dateOfBirthController.text.isEmpty ||
                        contactNumberController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill all required fields'),
                          backgroundColor: AppColors.warningColor,
                        ),
                      );
                      return;
                    }

                    try {
                      // Prepare passenger data
                      final passengerData = {
                        'first_name': firstNameController.text,
                        'last_name': lastNameController.text,
                        'email': emailController.text,
                        'password': passwordController.text,
                        'passport_number': passportController.text,
                        'date_of_birth': dateOfBirthController.text,
                        'contact_number': contactNumberController.text,
                        'gender': gender,
                        'address': addressController.text,
                        'role': 'passenger', // Default role for passengers
                      };

                      Navigator.of(context).pop();
                      EasyLoading.show(status: 'Creating new passenger...');

                      final response = await _apiService.createPassenger(passengerData);

                      EasyLoading.dismiss();

                      if (response['success']) {
                        // Get the new passenger ID and store it for ticket creation
                        final newPassengerId = response['data']['user_id']; // Assuming your API returns user_id
                        setState(() {
                          _foundPassenger = response['data'];
                          _selectedPassengerId = newPassengerId;
                        });

                        // Also update the passport number field in the parent dialog if it was empty
                        if (passportNumberController.text.isEmpty) {
                          passportNumberController.text = passportController.text;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Passenger created successfully'),
                            backgroundColor: AppColors.successColor,
                          ),
                        );
                      } else {
                        throw Exception(response['error'] ?? 'Failed to create passenger');
                      }
                    } catch (e) {
                      EasyLoading.dismiss();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error creating passenger: ${e.toString()}'),
                          backgroundColor: AppColors.errorColor,
                        ),
                      );
                    }
                  },
                  child: Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updatePaymentStatus(Ticket ticket) async {
    String newStatus = ticket.paymentStatus;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Payment Status'),
              content: DropdownButtonFormField<String>(
                value: newStatus,
                decoration: const InputDecoration(
                  labelText: 'Payment Status',
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'refunded', child: Text('Refunded')),
                ],
                onChanged: (value) {
                  setState(() {
                    newStatus = value!;
                  });
                },
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
                    Navigator.of(context).pop();
                    try {
                      EasyLoading.show(status: 'Updating payment status...');
                      await _apiService.updateTicketPaymentStatus(ticket.ticketId, newStatus);
                      EasyLoading.dismiss();

                      _loadTickets();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment status updated successfully'),
                          backgroundColor: AppColors.successColor,
                        ),
                      );
                    } catch (e) {
                      EasyLoading.dismiss();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating payment status: ${e.toString()}'),
                          backgroundColor: AppColors.errorColor,
                        ),
                      );
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTicket(Ticket ticket) async {
    // Get additional ticket information to display in the confirmation dialog
    String ticketInfo = '';
    if (ticket.flightNumber != null && ticket.passengerName != null) {
      ticketInfo = '\n\nFlight: ${ticket.flightNumber}\nPassenger: ${ticket.passengerName}';
    }

    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: AppColors.errorColor),
              SizedBox(width: 8),
              Text('Confirm Delete'),
            ],
          ),
          content: Text('Are you sure you want to delete ticket #${ticket.ticketId}?$ticketInfo\n\nThis action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        EasyLoading.show(status: 'Deleting ticket...');
        await _apiService.deleteTicket(ticket.ticketId);
        EasyLoading.dismiss();

        _loadTickets();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket deleted successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } catch (e) {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting ticket: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _printTicket(Ticket ticket) async {
    try {
      EasyLoading.show(status: 'Generating printable ticket...');
      final response = await _apiService.get('/tickets/${ticket.ticketId}/print');
      EasyLoading.dismiss();

      if (response['success']) {
        final ticketData = response['data'];

        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Center(
                      child: Text(
                        'BOARDING PASS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Flight ${ticketData['flight_number']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('FROM:'),
                              Text(
                                ticketData['origin'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.flight),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('TO:'),
                              Text(
                                ticketData['destination'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DEPARTURE:'),
                            Text(
                              DateFormat('dd-MM').format(DateTime.parse(ticketData['departure_time'])),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              DateFormat('HH:mm').format(DateTime.parse(ticketData['departure_time'])),
                            ),

                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('ARRIVAL:'),
                            Text(
                              DateFormat('dd-MM').format(DateTime.parse(ticketData['arrival_time'])),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              DateFormat('HH:mm').format(DateTime.parse(ticketData['arrival_time'])),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PASSENGER:'),
                            Text(
                              ticketData['passenger_name'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('PASSPORT:'),
                            Text(
                              ticketData['passport_number'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SEAT:'),
                            Text(
                              ticketData['seat_number'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('CLASS:'),
                            Text(
                              ticketData['class'].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('GATE:'),
                            Text(
                              ticketData['gate'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('AIRCRAFT:'),
                            Text(
                              ticketData['aircraft_model'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'TICKET ID: ${ticketData['ticket_id']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Printing functionality would be implemented here'),
                        backgroundColor: AppColors.infoColor,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to generate printable ticket');
      }
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating printable ticket: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
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
                      'Search Tickets',
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: _searchType,
                          items: const [
                            DropdownMenuItem(
                              value: 'flight',
                              child: Text('By Flight ID'),
                            ),
                            DropdownMenuItem(
                              value: 'passenger',
                              child: Text('By Passenger ID'),
                            ),
                            DropdownMenuItem(
                              value: 'flightNumber',
                              child: Text('By Flight Number'),
                            ),
                            DropdownMenuItem(
                              value: 'passportNumber',
                              child: Text('By Passport Number'),
                            ),
                          ],
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _searchType = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        if (_searchType == 'flight')
                          Expanded(
                            child: TextField(
                              controller: _searchFlightController,
                              decoration: const InputDecoration(
                                labelText: 'Flight ID',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          )
                        else if (_searchType == 'passenger')
                          Expanded(
                            child: TextField(
                              controller: _searchPassengerController,
                              decoration: const InputDecoration(
                                labelText: 'Passenger ID',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          )
                        else if (_searchType == 'flightNumber')
                            Expanded(
                              child: TextField(
                                controller: _searchFlightNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Flight Number (e.g., PS101)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            )
                          else // passportNumber
                            Expanded(
                              child: TextField(
                                controller: _searchPassportNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Passport Number',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _searchTickets,
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

          // Tickets Table
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
                            'Tickets List',
                            style: AppTextStyles.title,
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showTicketDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Book New Ticket'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _tickets.isEmpty
                            ? const Center(child: Text('No tickets found'))
                            : DataTable2(
                          columns: const [
                            // DataColumn2(
                            //   label: Text('Ticket ID'),
                            //   size: ColumnSize.S,
                            // ),
                            DataColumn2(
                              label: Text('Flight'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Passenger'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Seat'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Class'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Price'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Payment'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Actions'),
                              size: ColumnSize.L,
                            ),
                          ],
                          rows: _tickets.map((ticket) {
                            return DataRow(
                              cells: [
                                //DataCell(Text('#${ticket.ticketId}')),
                                DataCell(
                                  ticket.flightNumber != null
                                      ? Text('${ticket.flightNumber}\n${ticket.origin} → ${ticket.destination}')
                                      : const Text('-'),
                                ),
                                DataCell(
                                  ticket.passengerName != null
                                      ? Text('${ticket.passengerName}\n${ticket.passportNumber}')
                                      : Text('ID: ${ticket.passengerId}'),
                                ),
                                DataCell(Text(ticket.seatNumber)),
                                DataCell(Text(ticket.ticketClass.toUpperCase())),
                                DataCell(Text('\$${ticket.price.toStringAsFixed(2)}')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ticket.paymentStatus == 'completed'
                                          ? AppColors.successColor
                                          : ticket.paymentStatus == 'pending'
                                          ? AppColors.warningColor
                                          : AppColors.errorColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      ticket.paymentStatus,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppColors.infoColor),
                                        tooltip: 'Edit Ticket',
                                        onPressed: () => _showTicketDialog(ticket: ticket),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.payment, color: AppColors.primaryColor),
                                        tooltip: 'Update Payment Status',
                                        onPressed: () => _updatePaymentStatus(ticket),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.print, color: AppColors.accentColor),
                                        tooltip: 'Print Ticket',
                                        onPressed: () => _printTicket(ticket),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.errorColor),
                                        tooltip: 'Delete Ticket',
                                        onPressed: () => _deleteTicket(ticket),
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
                      if (!_isSearchMode && !_isLoading && _tickets.isNotEmpty)
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
                                  _loadTickets();
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
                                  _loadTickets();
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