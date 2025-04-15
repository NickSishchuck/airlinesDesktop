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

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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

                      TextField(
                        controller: flightIdController,
                        decoration: const InputDecoration(
                          labelText: 'Flight ID',
                          border: OutlineInputBorder(),
                          helperText: 'Enter the ID of an existing flight',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 12),

                      TextField(
                        controller: passengerIdController,
                        decoration: const InputDecoration(
                          labelText: 'Passenger ID',
                          border: OutlineInputBorder(),
                          helperText: 'Enter the ID of an existing passenger',
                        ),
                        keyboardType: TextInputType.number,
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
                      decoration: const InputDecoration(
                        labelText: 'Seat Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.airline_seat_recline_normal),
                      ),
                    ),
                    SizedBox(height: 12),

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
                      ],
                      onChanged: (value) {
                        setState(() {
                          ticketClass = value!;
                        });
                      },
                    ),
                    SizedBox(height: 12),

                    // Price - Always editable
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
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
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate inputs
                    if (seatNumberController.text.isEmpty ||
                        priceController.text.isEmpty ||
                        (flightIdController.text.isEmpty && !isEditing) ||
                        (passengerIdController.text.isEmpty && !isEditing)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
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
                      // Create ticket data - for editing, we only update the editable fields
                      final ticketData = isEditing ? {
                        'seat_number': seatNumberController.text,
                        'class': ticketClass,
                        'price': price,
                        'payment_status': paymentStatus,
                      } : {
                        'passenger_id': int.parse(passengerIdController.text),
                        'flight_id': int.parse(flightIdController.text),
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
                            DataColumn2(
                              label: Text('Ticket ID'),
                              size: ColumnSize.S,
                            ),
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
                                DataCell(Text('#${ticket.ticketId}')),
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