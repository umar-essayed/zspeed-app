import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:z_speed/core/utils/download_bytes.dart';

class ReceiptGenerator {
  static Future<void> generateAndShareReceipt({
    required String orderId,
    required String restaurantName,
    required double totalAmount,
    required DateTime date,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Receipt',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text('Order ID: $orderId'),
              pw.Text('Date: ${date.toLocal().toString().split('.')[0]}'),
              pw.SizedBox(height: 24),
              pw.Text('Restaurant: $restaurantName',
                  style: const pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Amount:',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${totalAmount.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 16)),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 32),
              pw.Center(
                child: pw.Text('Thank you for ordering with Z Speed!',
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    if (kIsWeb) {
      await downloadBytes(
        bytes,
        'receipt_$orderId.pdf',
        'Here is your receipt for order $orderId',
      );
      return;
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipt_$orderId.pdf');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Here is your receipt for order $orderId',
      ),
    );
  }
}
