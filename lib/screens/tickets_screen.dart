import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../services/api_service.dart';
import '../models/ticket.dart';
import '../utils/constants.dart';

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
  bool _isSearchMode = false;
  String _searchType = 'flight'; // 'flight' or 'passenger'

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

      if (_searchType == 'flight') {
        if (_searchFlightController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a flight ID'),
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
      } else {
        if (_searchPassengerController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a passenger ID'),
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
                  children: [
                    TextField(
                      controller: passengerIdController,
                      decoration: const InputDecoration(
                        labelText: 'Passenger ID',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: flightIdController,
                      decoration: const InputDecoration(
                        labelText: 'Flight ID',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: seatNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Seat Number',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: ticketClass,
                      decoration: const InputDecoration(
                        labelText: 'Class',
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
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    DropdownButtonFormField<String>(
                      value: paymentStatus,
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
                          paymentStatus = value!;
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
                    if (seatNumberController.text.isEmpty ||
                        priceController.text.isEmpty ||
                        passengerIdController.text.isEmpty ||
                        flightIdController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
                          backgroundColor: AppColors.warningColor,
                        ),
                      );
                      return;
                    }

                    final passengerId = int.tryParse(passengerIdController.text);
                    final flightId = int.tryParse(flightIdController.text);
                    final price = double.tryParse(priceController.text);

                    if (passengerId == null || flightId == null || price == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid number format'),
                          backgroundColor: AppColors.warningColor,
                        ),
                      );
                      return;
                    }

                    try {
                      // Create ticket data
                      final ticketData = {
                        'passenger_id': passengerId,
                        'flight_id': flightId,
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
                  DropdownMenuItem(value: 'failed', child: Text('Failed')),
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
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete ticket #${ticket.ticketId}?'),
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'flight',
                              icon: Icon(Icons.flight),
                              label: Text('By Flight'),
                            ),
                            ButtonSegment(
                              value: 'passenger',
                              icon: Icon(Icons.person),
                              label: Text('By Passenger'),
                            ),
                          ],
                          selected: {_searchType},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _searchType = newSelection.first;
                            });
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
                        else
                          Expanded(
                            child: TextField(
                              controller: _searchPassengerController,
                              decoration: const InputDecoration(
                                labelText: 'Passenger ID',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
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