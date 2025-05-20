import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/api_service.dart';
import '../models/report.dart';
import '../utils/constants.dart';
import '../services/pdf_service.dart';
import '../services/pdf_printer.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final PdfService _pdfService = PdfService();
  final PdfPrinter _pdfPrinter = PdfPrinter();
  final ApiService _apiService = ApiService();
  List<SalesReport> _salesReports = [];
  bool _isLoading = false;

  // Date range for reports
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Summary metrics
  double _totalRevenue = 0;
  int _totalTicketsSold = 0;
  double _averageOccupancy = 0;
  Map<String, double> _revenueByClass = {
    'economy': 0,
    'business': 0,
    'first': 0,
  };

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _exportAsPdf() async {
    try {
      EasyLoading.show(status: 'Generating PDF...');

      // Generate the PDF document
      final pdfData = await _pdfService.generateTicketSalesReport(
        salesReports: _salesReports,
        startDate: _startDate,
        endDate: _endDate,
        totalRevenue: _totalRevenue,
        totalTicketsSold: _totalTicketsSold,
        averageOccupancy: _averageOccupancy,
        revenueByClass: _revenueByClass,
      );

      EasyLoading.dismiss();

      if (!mounted) return;

      // Generate a filename based on date range
      final fileName = 'ticket_sales_report_${DateFormat('yyyyMMdd').format(_startDate)}_to_${DateFormat('yyyyMMdd').format(_endDate)}.pdf';

      // Show options dialog
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('PDF Generated'),
            content: const Text('Your sales report has been generated. What would you like to do next?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.preview),
                label: const Text('Preview & Print'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _pdfPrinter.previewPdf(
                      context,
                      pdfData,
                      'Ticket Sales Report'
                  );
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share PDF'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _pdfPrinter.sharePdf(pdfData, fileName);
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }
  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(_startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(_endDate);

      final response = await _apiService.generateTicketSalesReport(
        formattedStartDate,
        formattedEndDate,
      );

      if (response['success']) {
        final List reportData = response['data'];
        final salesReports = reportData.map((data) => SalesReport.fromJson(data)).toList();

        // Calculate summary metrics
        double totalRevenue = 0;
        int totalTicketsSold = 0;
        double totalOccupancy = 0;
        int flightCount = 0;
        Map<String, double> revenueByClass = {
          'economy': 0,
          'business': 0,
          'first': 0,
        };

        for (var report in salesReports) {
          totalRevenue += report.totalRevenue;
          totalTicketsSold += report.ticketsSold;
          totalOccupancy += report.occupancyPercentage;
          flightCount++;

          // Add to revenue by class
          if (revenueByClass.containsKey(report.ticketClass)) {
            revenueByClass[report.ticketClass] =
                (revenueByClass[report.ticketClass] ?? 0) + report.totalRevenue;
          }
        }

        setState(() {
          _salesReports = salesReports;
          _totalRevenue = totalRevenue;
          _totalTicketsSold = totalTicketsSold;
          _averageOccupancy = flightCount > 0 ? totalOccupancy / flightCount : 0;
          _revenueByClass = revenueByClass;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to generate sales report');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _generateReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Header and Date Range Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ticket Sales Report',
                          style: AppTextStyles.headline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Date Range: ${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                          style: AppTextStyles.subtitle,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _selectDateRange(context),
                          icon: const Icon(Icons.date_range),
                          label: const Text('Change Date Range'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _generateReport,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // // Summary Cards
            // SizedBox(
            //   height: 120,
            //   child: _isLoading
            //       ? const Center(child: CircularProgressIndicator())
            //       : Row(
            //     children: [
            //       Expanded(
            //         child: _buildSummaryCard(
            //           'Total Revenue',
            //           '\$${_totalRevenue.toStringAsFixed(2)}',
            //           Icons.attach_money,
            //           AppColors.accentColor,
            //         ),
            //       ),
            //       const SizedBox(width: 16),
            //       Expanded(
            //         child: _buildSummaryCard(
            //           'Tickets Sold',
            //           _totalTicketsSold.toString(),
            //           Icons.confirmation_number,
            //           AppColors.infoColor,
            //         ),
            //       ),
            //       const SizedBox(width: 16),
            //       Expanded(
            //         child: _buildSummaryCard(
            //           'Average Occupancy',
            //           '${_averageOccupancy.toStringAsFixed(2)}%',
            //           Icons.airline_seat_recline_normal,
            //           AppColors.primaryColor,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 16),

            // Charts and Tables
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _salesReports.isEmpty
                  ? const Center(
                child: Text('No report data available for the selected date range.'),
              )
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // // Charts
                  // Expanded(
                  //   flex: 1,
                  //   child: Card(
                  //     child: Padding(
                  //       padding: const EdgeInsets.all(16.0),
                  //       child: Column(
                  //         crossAxisAlignment: CrossAxisAlignment.start,
                  //         children: [
                  //           const Text(
                  //             'Revenue by Class',
                  //             style: AppTextStyles.title,
                  //           ),
                  //           const SizedBox(height: 16),
                  //           Expanded(
                  //             child: SfCircularChart(
                  //               legend: Legend(
                  //                 isVisible: true,
                  //                 position: LegendPosition.bottom,
                  //               ),
                  //               series: <CircularSeries>[
                  //                 PieSeries<MapEntry<String, double>, String>(
                  //                   dataSource: _revenueByClass.entries.toList(),
                  //                   xValueMapper: (entry, _) => entry.key.toUpperCase(),
                  //                   yValueMapper: (entry, _) => entry.value,
                  //                   dataLabelMapper: (entry, _) => '\$${entry.value.toStringAsFixed(0)}',
                  //                   pointColorMapper: (entry, _) {
                  //                     switch (entry.key) {
                  //                       case 'economy':
                  //                         return AppColors.infoColor;
                  //                       case 'business':
                  //                         return AppColors.accentColor;
                  //                       case 'first':
                  //                         return AppColors.primaryColor;
                  //                       default:
                  //                         return Colors.grey;
                  //                     }
                  //                   },
                  //                   dataLabelSettings: const DataLabelSettings(
                  //                     isVisible: true,
                  //                     labelPosition: ChartDataLabelPosition.outside,
                  //                   ),
                  //                 ),
                  //               ],
                  //               tooltipBehavior: TooltipBehavior(enable: true),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(width: 16),

                  // Data Table
                  Expanded(
                    flex: 2,
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
                                  'Detailed Sales Report',
                                  style: AppTextStyles.title,
                                ),


                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Export functionality would be implemented here
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Export functionality would be implemented here'),
                                            backgroundColor: AppColors.infoColor,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.download),
                                      label: const Text('Export CSV'),
                                    ),



                                    ElevatedButton.icon(
                                      onPressed: _exportAsPdf,
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text('Export PDF'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: DataTable2(
                                columns: const [
                                  DataColumn2(
                                    label: Text('Flight Number'),
                                    size: ColumnSize.S,
                                  ),
                                  DataColumn2(
                                    label: Text('Route'),
                                    size: ColumnSize.M,
                                  ),
                                  DataColumn2(
                                    label: Text('Date'),
                                    size: ColumnSize.M,
                                  ),
                                  DataColumn2(
                                    label: Text('Class'),
                                    size: ColumnSize.S,
                                  ),
                                  DataColumn2(
                                    label: Text('Tickets Sold'),
                                    size: ColumnSize.S,
                                    numeric: true,
                                  ),
                                  DataColumn2(
                                    label: Text('Revenue'),
                                    size: ColumnSize.S,
                                    numeric: true,
                                  ),
                                  DataColumn2(
                                    label: Text('Occupancy'),
                                    size: ColumnSize.S,
                                    numeric: true,
                                  ),
                                ],
                                rows: [
                                  // Existing report rows
                                  ..._salesReports.map((report) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(report.flightNumber)),
                                        DataCell(Text('${report.origin} → ${report.destination}')),
                                        DataCell(Text(DateFormat('MMM d, yyyy').format(report.flightDate))),
                                        DataCell(Text(report.ticketClass.toUpperCase())),
                                        DataCell(Text(report.ticketsSold.toString())),
                                        DataCell(Text('\$${report.totalRevenue.toStringAsFixed(2)}')),
                                        DataCell(Text('${report.occupancyPercentage.toStringAsFixed(2)}%')),
                                      ],
                                    );
                                  }).toList(),

                                  // Add a divider row
                                  DataRow(
                                    cells: List.generate(7, (index) => DataCell(Divider(color: Colors.grey.shade300, thickness: 2))),
                                  ),

                                  // Add the summary row
                                  DataRow(
                                    color: MaterialStateProperty.all(Colors.grey.shade200),
                                    cells: [
                                      DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text('')),  // Empty cell for Route
                                      DataCell(Text('')),  // Empty cell for Date
                                      DataCell(Text('')),  // Empty cell for Class
                                      DataCell(Text(
                                        _totalTicketsSold.toString(),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      )),
                                      DataCell(Text(
                                        '\$${_totalRevenue.toStringAsFixed(2)}',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      )),
                                      DataCell(Text(
                                        '${_averageOccupancy.toStringAsFixed(2)}%',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      )),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}