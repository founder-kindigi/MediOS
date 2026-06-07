import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/sale_model.dart';

class InvoiceService {
  Future<Uint8List> generateInvoice(SaleModel sale) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(16),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              children: [
                pw.Text('MediOS Pharmacy',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Pharmacy Management System',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                pw.SizedBox(height: 8),
                pw.Divider(),
              ],
            ),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Bill #: ${sale.billNumber}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(_formatDate(sale.saleDate)),
            ],
          ),
          if (sale.customerName != null)
            pw.Text('Customer: ${sale.customerName}'),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: ['Item', 'Qty', 'Price', 'Total'],
            data: sale.items.map((item) => [
              item.medicineName ?? 'Item',
              '${item.quantity}',
              _formatCurrency(item.unitPrice),
              _formatCurrency(item.totalPrice),
            ]).toList(),
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Subtotal:'),
                  if (sale.discount != null && sale.discount! > 0)
                    pw.Text('Discount:'),
                  if (sale.tax != null && sale.tax! > 0)
                    pw.Text('Tax (${sale.tax}%):'),
                  pw.Divider(),
                  pw.Text('Net Total:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(_formatCurrency(sale.totalAmount)),
                  if (sale.discount != null && sale.discount! > 0)
                    pw.Text('-${_formatCurrency(sale.discount!)}'),
                  if (sale.tax != null && sale.tax! > 0)
                    pw.Text(_formatCurrency(sale.totalAmount * (sale.tax! / 100))),
                  pw.Divider(),
                  pw.Text(_formatCurrency(sale.netAmount),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.Text('Payment: ${sale.paymentMethod.toUpperCase()}',
              style: pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text('Thank you for your business!',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> printInvoice(SaleModel sale) async {
    final pdf = await generateInvoice(sale);
    await Printing.layoutPdf(
      onLayout: (_) => pdf,
    );
  }

  Future<void> shareInvoice(SaleModel sale) async {
    final pdf = await generateInvoice(sale);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_${sale.billNumber.replaceAll('/', '_')}.pdf');
    await file.writeAsBytes(pdf);
    await Share.shareXFiles([XFile(file.path)], text: 'Invoice ${sale.billNumber}');
  }

  String _formatCurrency(double amount) {
    return 'Rs ${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
