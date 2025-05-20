import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class PdfPrinter {

  // Method to share PDF file
  Future<void> sharePdf(Uint8List pdfData, String fileName) async {
    await Printing.sharePdf(bytes: pdfData, filename: fileName);
  }

  // Method to save PDF to local storage (mobile devices)
  Future<String?> savePdfToDevice(Uint8List pdfData, String fileName) async {
    try {
      // Get temporary directory for storage
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName');

      // Write PDF data to file
      await file.writeAsBytes(pdfData);

      return file.path;
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      return null;
    }
  }

  // Method to preview and print the PDF
  Future<void> previewPdf(
      BuildContext context,
      Uint8List pdfData,
      String title,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(pdfData: pdfData, title: title),
      ),
    );
  }
}

// Create a preview screen using the printing package
class PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfData;
  final String title;

  const PdfPreviewScreen({
    Key? key,
    required this.pdfData,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share PDF',
            onPressed: () async {
              await Printing.sharePdf(
                bytes: pdfData,
                filename: title.replaceAll(' ', '_') + '.pdf',
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfData,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: title.replaceAll(' ', '_') + '.pdf',
      ),
    );
  }
}