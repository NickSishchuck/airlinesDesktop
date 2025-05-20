import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/report.dart';
import '../utils/constants.dart';

class PdfService {
  Future<Uint8List> generateTicketPdf(Map<String, dynamic> ticketData) async {
    final pdf = pw.Document();

    final PdfService _pdfService = PdfService();

    // Use standard fonts
    final regular = pw.Font.helvetica();
    final bold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with airline name and boarding pass title
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'AIRLINE NAME',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 24,
                      color: PdfColor.fromInt(0xFF1976D2), // primaryColor
                    ),
                  ),
                  pw.Text(
                    'BOARDING PASS',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 20,
                      color: PdfColor.fromInt(0xFF1976D2), // primaryColor
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Flight Number and Route
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'FLIGHT ${ticketData['flight_number']}',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 18,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'FROM',
                                style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
                              ),
                              pw.Text(
                                ticketData['origin'],
                                style: pw.TextStyle(font: bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Container(
                          height: 30,
                          child: pw.Center(
                            child: pw.LayoutBuilder(
                                builder: (context, constraints) {
                                  return pw.SvgImage(
                                    svg: '''
                                <svg xmlns="http://www.w3.org/2000/svg" width="${constraints?.maxWidth}" height="${constraints?.maxHeight}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                  <path d="M22 12H2M14 18l8-6-8-6"/>
                                </svg>
                                ''',
                                  );
                                }
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'TO',
                                style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
                              ),
                              pw.Text(
                                ticketData['destination'],
                                style: pw.TextStyle(font: bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Date and Time Information
              pw.Row(
                children: [
                  // Departure info
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DEPARTURE',
                            style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            DateFormat('dd MMM yyyy').format(DateTime.parse(ticketData['departure_time'])),
                            style: pw.TextStyle(font: bold, fontSize: 14),
                          ),
                          pw.Text(
                            DateFormat('HH:mm').format(DateTime.parse(ticketData['departure_time'])),
                            style: pw.TextStyle(font: bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),

                  pw.SizedBox(width: 15),

                  // Arrival info
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'ARRIVAL',
                            style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            DateFormat('dd MMM yyyy').format(DateTime.parse(ticketData['arrival_time'])),
                            style: pw.TextStyle(font: bold, fontSize: 14),
                          ),
                          pw.Text(
                            DateFormat('HH:mm').format(DateTime.parse(ticketData['arrival_time'])),
                            style: pw.TextStyle(font: bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Passenger Information
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PASSENGER INFORMATION',
                      style: pw.TextStyle(font: bold, fontSize: 14),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'NAME',
                                style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
                              ),
                              pw.Text(
                                ticketData['passenger_name'],
                                style: pw.TextStyle(font: bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'PASSPORT',
                                style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
                              ),
                              pw.Text(
                                ticketData['passport_number'],
                                style: pw.TextStyle(font: bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Seat and Class Information
              pw.Row(
                children: [
                  // Seat info
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'SEAT',
                            style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            ticketData['seat_number'],
                            style: pw.TextStyle(font: bold, fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                  ),

                  pw.SizedBox(width: 15),

                  // Class info
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'CLASS',
                            style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            _formatTicketClass(ticketData['class']),
                            style: pw.TextStyle(font: bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Additional Information
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'GATE',
                            style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
                          ),
                          pw.Text(
                            ticketData['gate'] ?? 'TBA',
                            style: pw.TextStyle(font: bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'AIRCRAFT',
                            style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
                          ),
                          pw.Text(
                            ticketData['aircraft_model'],
                            style: pw.TextStyle(font: bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PAYMENT',
                            style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
                          ),
                          pw.Text(
                            ticketData['payment_status']?.toUpperCase() ?? 'PENDING',
                            style: pw.TextStyle(
                              font: bold,
                              fontSize: 14,
                              color: _getPaymentStatusColor(ticketData['payment_status']),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Barcode and Ticket ID
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.code128(),
                      data: 'TKT${ticketData['ticket_id']}',
                      width: 200,
                      height: 60,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'TICKET ID: ${ticketData['ticket_id']}',
                      style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),

              // Footer information
              pw.Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: pw.Center(
                  child: pw.Text(
                    'This is an electronic ticket. Please present your ID at check-in.',
                    style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

// Helper method to get payment status color
  PdfColor _getPaymentStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return PdfColor.fromInt(0xFF4CAF50); // Green - success
      case 'pending':
        return PdfColor.fromInt(0xFFFFC107); // Amber - warning
      case 'refunded':
        return PdfColor.fromInt(0xFFF44336); // Red - error
      default:
        return PdfColors.grey700;
    }
  }

// Helper method to format ticket class
  String _formatTicketClass(String ticketClass) {
    switch (ticketClass.toLowerCase()) {
      case 'economy':
        return 'ECONOMY';
      case 'business':
        return 'BUSINESS';
      case 'first':
        return 'FIRST CLASS';
      case 'woman_only':
        return 'WOMAN ONLY';
      default:
        return ticketClass.toUpperCase();
    }
  }


  Future<Uint8List> generateTicketSalesReport({
    required List<SalesReport> salesReports,
    required DateTime startDate,
    required DateTime endDate,
    required double totalRevenue,
    required int totalTicketsSold,
    required double averageOccupancy,
    required Map<String, double> revenueByClass,
  }) async {
    final pdf = pw.Document();

    // Use a standard font
    final regular = pw.Font.helvetica();
    final bold = pw.Font.helveticaBold();

    // Add company logo if available
    // ByteData logoData = await rootBundle.load('assets/logo.png');
    // final logoImage = pw.MemoryImage(
    //   (logoData.buffer.asUint8List()),
    // );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header with title and date range
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Ticket Sales Report',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 24,
                      color: PdfColor.fromInt(0xFF1976D2), // primaryColor
                    ),
                  ),
                  // Logo could go here
                  // pw.Image(logoImage, width: 50, height: 50),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // Date Range
            pw.Paragraph(
              text: 'Date Range: ${DateFormat('MMMM d, yyyy').format(startDate)} - ${DateFormat('MMMM d, yyyy').format(endDate)}',
              style: pw.TextStyle(
                font: regular,
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),

            pw.SizedBox(height: 20),

            // Summary section
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Summary',
                    style: pw.TextStyle(font: bold, fontSize: 16),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryCard(
                        'Total Revenue',
                        '\$${totalRevenue.toStringAsFixed(2)}',
                        PdfColor.fromInt(0xFF4CAF50), // accentColor
                        regular,
                        bold,
                      ),
                      _buildSummaryCard(
                        'Tickets Sold',
                        totalTicketsSold.toString(),
                        PdfColor.fromInt(0xFF2196F3), // infoColor
                        regular,
                        bold,
                      ),
                      _buildSummaryCard(
                        'Average Occupancy',
                        '${averageOccupancy.toStringAsFixed(2)}%',
                        PdfColor.fromInt(0xFF1976D2), // primaryColor
                        regular,
                        bold,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Revenue by Class
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Revenue by Class',
                    style: pw.TextStyle(font: bold, fontSize: 16),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryCard(
                        'Economy',
                        '\$${revenueByClass['economy']?.toStringAsFixed(2) ?? '0.00'}',
                        PdfColor.fromInt(0xFF4CAF50), // green
                        regular,
                        bold,
                      ),
                      _buildSummaryCard(
                        'Business',
                        '\$${revenueByClass['business']?.toStringAsFixed(2) ?? '0.00'}',
                        PdfColor.fromInt(0xFF2196F3), // blue
                        regular,
                        bold,
                      ),
                      _buildSummaryCard(
                        'First Class',
                        '\$${revenueByClass['first']?.toStringAsFixed(2) ?? '0.00'}',
                        PdfColor.fromInt(0xFF3F51B5), // indigo
                        regular,
                        bold,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  revenueByClass.containsKey('woman_only') ? pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      _buildSummaryCard(
                        'Woman Only',
                        '\$${revenueByClass['woman_only']?.toStringAsFixed(2) ?? '0.00'}',
                        PdfColor.fromInt(0xFFE91E63), // pink
                        regular,
                        bold,
                      ),
                    ],
                  ) : pw.SizedBox(),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Detailed Sales Report
            pw.Header(
              level: 1,
              child: pw.Text(
                'Detailed Sales Report',
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 18,
                  color: PdfColor.fromInt(0xFF1976D2), // primaryColor
                ),
              ),
            ),

            pw.SizedBox(height: 10),

            // Table header
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1976D2), // primaryColor
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(8),
                  topRight: pw.Radius.circular(8),
                ),
              ),
              padding: const pw.EdgeInsets.all(8),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Flight',
                      style: pw.TextStyle(
                        font: bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text(
                      'Route',
                      style: pw.TextStyle(
                        font: bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Date',
                      style: pw.TextStyle(
                        font: bold,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Class',
                      style: pw.TextStyle(
                        font: bold,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Tickets',
                      style: pw.TextStyle(
                        font: bold,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Revenue',
                      style: pw.TextStyle(
                        font: bold,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Occupancy',
                      style: pw.TextStyle(
                        font: bold,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),

            // Table rows
            ...List.generate(salesReports.length, (index) {
              final report = salesReports[index];
              return pw.Container(
                decoration: pw.BoxDecoration(
                  color: index % 2 == 0 ? PdfColors.white : PdfColors.grey100,
                  border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.grey300),
                    right: pw.BorderSide(color: PdfColors.grey300),
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        report.flightNumber,
                        style: pw.TextStyle(font: regular),
                      ),
                    ),
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text(
                        '${report.origin} - ${report.destination}',
                        style: pw.TextStyle(font: regular),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        DateFormat('MM/dd/yyyy').format(report.flightDate),
                        style: pw.TextStyle(font: regular),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        formatTicketClass(report.ticketClass),
                        style: pw.TextStyle(font: regular),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        report.ticketsSold.toString(),
                        style: pw.TextStyle(font: regular),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        '\$${report.totalRevenue.toStringAsFixed(2)}',
                        style: pw.TextStyle(font: regular),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        '${report.occupancyPercentage.toStringAsFixed(2)}%',
                        style: pw.TextStyle(font: regular),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Total row
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1976D2),
                borderRadius: const pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(8),
                  bottomRight: pw.Radius.circular(8),
                ),
                border: pw.Border.all(color: PdfColor.fromInt(0xFF1976D2)),
              ),
              padding: const pw.EdgeInsets.all(8),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(font: bold),
                    ),
                  ),
                  pw.Expanded(
                    flex: 5,
                    child: pw.SizedBox(),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.SizedBox(),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.SizedBox(),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      totalTicketsSold.toString(),
                      style: pw.TextStyle(font: bold),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      '\$${totalRevenue.toStringAsFixed(2)}',
                      style: pw.TextStyle(font: bold),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      '${averageOccupancy.toStringAsFixed(2)}%',
                      style: pw.TextStyle(font: bold),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Report generated on ${DateFormat('MM/dd/yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColors.grey700),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // Helper method for formatting ticket classes (reused from constants.dart)
  String formatTicketClass(String ticketClass) {
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
        return ticketClass.toUpperCase();
    }
  }

  // Helper method to build a summary card widget
  pw.Container _buildSummaryCard(
      String title,
      String value,
      PdfColor color,
      pw.Font regularFont,
      pw.Font boldFont,
      ) {
    return pw.Container(
      width: 145,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        border: pw.Border.all(color: color),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey300,
            offset: const PdfPoint(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 10,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}