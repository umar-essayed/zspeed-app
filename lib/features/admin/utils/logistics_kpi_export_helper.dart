import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:z_speed/features/admin/model/logistics_kpi_models.dart';
import 'package:z_speed/features/order/model/order.dart';

class LogisticsKpiExportHelper {
  LogisticsKpiExportHelper._();

  static final currencyFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
  static final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  /// Export Logistics KPI Order records to Excel
  static Future<Uint8List?> exportToExcel({
    required List<Order> orders,
    required LogisticsKpiStats stats,
    required bool calculateWithFees,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Logistics KPI Report'];

    // Header Styles
    sheet.appendRow([
      TextCellValue('Z Speed Logistics Master Report'),
      TextCellValue('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}'),
    ]);
    sheet.appendRow([]);

    // KPI Summary
    sheet.appendRow([TextCellValue('--- KPI Summary ---')]);
    sheet.appendRow([TextCellValue('Restaurant Gross Sales'), TextCellValue(currencyFormat.format(stats.restaurantGrossSales))]);
    sheet.appendRow([TextCellValue('Total Delivery Fees'), TextCellValue(currencyFormat.format(stats.totalDeliveryFeesCollected))]);
    sheet.appendRow([TextCellValue('Trips Completed'), TextCellValue('${stats.totalTripsCompleted}')]);
    sheet.appendRow([TextCellValue('Active Orders'), TextCellValue('${stats.activeOrdersCount}')]);
    sheet.appendRow([
      TextCellValue(calculateWithFees ? 'Master Net Profit (With 15% Fee)' : 'Master Admin Commission (10%)'),
      TextCellValue(currencyFormat.format(stats.totalNetProfit)),
    ]);
    sheet.appendRow([]);

    // Orders Table Header
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Order ID'),
      TextCellValue('Customer ID'),
      TextCellValue('Status'),
      TextCellValue('Subtotal'),
      TextCellValue('Delivery Fee'),
      TextCellValue('Rider Share (85%)'),
      TextCellValue('Admin Comm (10%)'),
      TextCellValue('Platform Fee (15%)'),
    ]);

    for (final order in orders) {
      final rCut = order.deliveryFee * 0.85;
      final aComm = order.subtotal * 0.10;
      final pCut = order.deliveryFee * 0.15;

      sheet.appendRow([
        TextCellValue(dateFormat.format(order.createdAt)),
        TextCellValue(order.id),
        TextCellValue(order.customerId),
        TextCellValue(order.status.name),
        TextCellValue(currencyFormat.format(order.subtotal)),
        TextCellValue(currencyFormat.format(order.deliveryFee)),
        TextCellValue(currencyFormat.format(rCut)),
        TextCellValue(currencyFormat.format(aComm)),
        TextCellValue(currencyFormat.format(pCut)),
      ]);
    }

    final fileBytes = excel.save();
    return fileBytes != null ? Uint8List.fromList(fileBytes) : null;
  }

  /// Export Logistics KPI Order records to PDF & triggering print/save dialog
  static Future<void> exportToPdf({
    required List<Order> orders,
    required LogisticsKpiStats stats,
    required bool calculateWithFees,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Title Header
            pw.Header(
              level: 0,
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'Z Speed Logistics Master Report',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Summary Table
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Executive Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('Gross Sales: ${currencyFormat.format(stats.restaurantGrossSales)}')),
                      pw.Expanded(child: pw.Text('Delivery Fees: ${currencyFormat.format(stats.totalDeliveryFeesCollected)}')),
                      pw.Expanded(child: pw.Text('Completed Trips: ${stats.totalTripsCompleted}')),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          calculateWithFees ? 'Net Profit (With Fees): ${currencyFormat.format(stats.totalNetProfit)}' : 'Master Comm (10%): ${currencyFormat.format(stats.totalNetProfit)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
                        ),
                      ),
                      pw.Expanded(child: pw.Text('Active Orders: ${stats.activeOrdersCount}')),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Orders Table
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Order ID', 'Status', 'Subtotal', 'Delivery Fee', 'Rider (85%)', 'Comm (10%)', 'Platform (15%)'],
              data: orders.take(100).map((order) {
                final rCut = order.deliveryFee * 0.85;
                final aComm = order.subtotal * 0.10;
                final pCut = order.deliveryFee * 0.15;
                return [
                  dateFormat.format(order.createdAt),
                  order.id.length > 8 ? order.id.substring(0, 8) : order.id,
                  order.status.name,
                  currencyFormat.format(order.subtotal),
                  currencyFormat.format(order.deliveryFee),
                  currencyFormat.format(rCut),
                  currencyFormat.format(aComm),
                  currencyFormat.format(pCut),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'zspeed_logistics_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }
}
