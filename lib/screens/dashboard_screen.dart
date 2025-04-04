import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

//TODO remove the dashboard


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  int _totalFlights = 0;
  int _scheduledFlights = 0;
  int _delayedFlights = 0;
  int _canceledFlights = 0;
  int _totalTickets = 0;
  double _totalRevenue = 0;
  List<Map<String, dynamic>> _flightStatusData = [];
  List<Map<String, dynamic>> _recentFlights = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current date
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final yesterday = DateFormat('yyyy-MM-dd').format(
          now.subtract(const Duration(days: 1)));
      final tomorrow = DateFormat('yyyy-MM-dd').format(
          now.add(const Duration(days: 1)));

      // Load flights for today and tomorrow
      final flightsResponse = await _apiService.generateFlightSchedule(
          yesterday, tomorrow);

      if (flightsResponse['success'] && flightsResponse['data'] != null) {
        final flights = flightsResponse['data'] as List;

        // Count flights by status
        int scheduled = 0;
        int delayed = 0;
        int canceled = 0;

        for (var flight in flights) {
          final status = flight['status'] as String;
          if (status == 'scheduled') scheduled++;
          if (status == 'delayed') delayed++;
          if (status == 'canceled') canceled++;
        }

        // Get sales report for the current month
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        final salesResponse = await _apiService.generateTicketSalesReport(
          DateFormat('yyyy-MM-dd').format(startOfMonth),
          DateFormat('yyyy-MM-dd').format(endOfMonth),
        );

        double totalRevenue = 0;
        int totalTickets = 0;

        if (salesResponse['success'] && salesResponse['data'] != null) {
          final salesData = salesResponse['data'] as List;
          for (var sale in salesData) {
            // Handle total_revenue which might be a string, int, or double
            if (sale['total_revenue'] is String) {
              totalRevenue += double.parse(sale['total_revenue']);
            } else if (sale['total_revenue'] is num) {
              totalRevenue += (sale['total_revenue'] as num).toDouble();
            }

            // Handle tickets_sold which might be a string or int
            if (sale['tickets_sold'] is String) {
              totalTickets += int.parse(sale['tickets_sold']);
            } else if (sale['tickets_sold'] is int) {
              totalTickets += sale['tickets_sold'] as int;
            }
          }
        }

        // Flight status data for chart
        _flightStatusData = [
          {
            'status': 'Scheduled',
            'count': scheduled,
            'color': AppColors.scheduledColor
          },
          {
            'status': 'Delayed',
            'count': delayed,
            'color': AppColors.delayedColor
          },
          {
            'status': 'Canceled',
            'count': canceled,
            'color': AppColors.canceledColor
          },
        ];

        // Get recent flights
        final recentFlights = flights
            .where((flight) => flight['departure_time'] != null)
            .toList()
            .cast<Map<String, dynamic>>();

        recentFlights.sort((a, b) {
          final aTime = DateTime.parse(a['departure_time']);
          final bTime = DateTime.parse(b['departure_time']);
          return aTime.compareTo(bTime);
        });

        setState(() {
          _totalFlights = flights.length;
          _scheduledFlights = scheduled;
          _delayedFlights = delayed;
          _canceledFlights = canceled;
          _totalTickets = totalTickets;
          _totalRevenue = totalRevenue;
          _recentFlights = recentFlights.take(5).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load flight data');
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading dashboard data: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Refresh Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dashboard - ${DateFormat('EEEE, MMMM d, yyyy').format(
                        DateTime.now())}',
                    style: AppTextStyles.headline,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadDashboardData,
                    tooltip: 'Refresh data',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats Cards
              GridView.count(
                crossAxisCount: 4,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    'Total Flights',
                    _totalFlights.toString(),
                    Icons.flight,
                    AppColors.primaryColor,
                  ),
                  _buildStatCard(
                    'Scheduled',
                    _scheduledFlights.toString(),
                    Icons.schedule,
                    AppColors.scheduledColor,
                  ),
                  _buildStatCard(
                    'Delayed',
                    _delayedFlights.toString(),
                    Icons.hourglass_bottom,
                    AppColors.delayedColor,
                  ),
                  _buildStatCard(
                    'Canceled',
                    _canceledFlights.toString(),
                    Icons.cancel,
                    AppColors.canceledColor,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 24),

              // Flight Status Chart and Recent Flights
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(width: 16),

                  // Recent Flights
                  Expanded(
                    child: Container(
                      height: 500,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent Flights',
                            style: AppTextStyles.title,
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _recentFlights.isEmpty
                                ? const Center(
                              child: Text('No recent flights found'),
                            )
                                : ListView.builder(
                              itemCount: _recentFlights.length,
                              itemBuilder: (context, index) {
                                final flight = _recentFlights[index];
                                final departureTime = DateTime.parse(
                                    flight['departure_time']);
                                final arrivalTime = DateTime.parse(
                                    flight['arrival_time']);
                                final formattedDepTime = DateFormat(
                                    'MMM d, HH:mm').format(departureTime);
                                final formattedArrTime = DateFormat(
                                    'MMM d, HH:mm').format(arrivalTime);

                                return ListTile(
                                  leading: const Icon(Icons.flight),
                                  title: Text(
                                    '${flight['flight_number']} - ${flight['origin']} -> ${flight['destination']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                      '$formattedDepTime - $formattedArrTime'),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: flightStatusColors[flight['status']] ??
                                          Colors.grey,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      flight['status'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {double height = 160}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        // Add this to use minimum required space
        children: [
          Icon(
            icon,
            size: 40,
            color: color,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}