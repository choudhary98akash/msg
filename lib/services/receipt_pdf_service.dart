import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/payment_model.dart';
import '../models/booking_model.dart';
import '../models/customer_model.dart';
import '../utils/formatters.dart';
import '../utils/amount_to_words.dart';
import '../config/constants.dart';

class ReceiptPdfService {
  Future<Uint8List> generateReceipt({
    required PaymentModel payment,
    required BookingModel booking,
    required CustomerModel customer,
    required String receiptNumber,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(receiptNumber, payment.paymentDate),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(customer),
              pw.SizedBox(height: 20),
              _buildPaymentDetails(payment, booking),
              pw.SizedBox(height: 20),
              _buildAmountInWords(payment.amount),
              pw.SizedBox(height: 20),
              _buildPaymentMode(payment),
              pw.Spacer(),
              _buildSignature(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(String receiptNumber, DateTime date) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey800, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            AppConstants.companyName,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Payment Receipt',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Receipt No: $receiptNumber'),
              pw.Text('Date: ${Formatters.formatDate(date)}'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerInfo(CustomerModel customer) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Customer Details',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Name: ${customer.name}'),
                    pw.Text('Phone: ${customer.phone ?? "N/A"}'),
                    pw.Text('Email: ${customer.email ?? "N/A"}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentDetails(PaymentModel payment, BookingModel booking) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Payment Details',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Plot Number: ${booking.plotNumber}'),
              pw.Text('Block: ${booking.block ?? "N/A"}'),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Payment Type: ${Formatters.formatPaymentType(payment.paymentType)}'),
              pw.Text('Payment Date: ${Formatters.formatDate(payment.paymentDate)}'),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Amount Received:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
              ),
              pw.Text(
                Formatters.formatCurrency(payment.amount),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAmountInWords(double amount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'Amount in Words: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Expanded(
            child: pw.Text(
              AmountToWords.convertWithCurrency(amount),
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentMode(PaymentModel payment) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Payment Mode',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Mode: ${Formatters.formatPaymentMode(payment.paymentMode)}'),
          if (payment.bankName != null && payment.bankName!.isNotEmpty)
            pw.Text('Bank: ${payment.bankName}'),
          if (payment.chequeNumber != null && payment.chequeNumber!.isNotEmpty)
            pw.Text('Cheque/DD No: ${payment.chequeNumber}'),
          if (payment.transactionId != null && payment.transactionId!.isNotEmpty)
            pw.Text('Transaction ID: ${payment.transactionId}'),
        ],
      ),
    );
  }

  pw.Widget _buildSignature() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 150,
              child: pw.Divider(),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Authorized Signatory'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'This is a computer generated receipt.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Terms & Conditions Apply',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Future<void> printReceipt({
    required PaymentModel payment,
    required BookingModel booking,
    required CustomerModel customer,
    required String receiptNumber,
  }) async {
    final pdfData = await generateReceipt(
      payment: payment,
      booking: booking,
      customer: customer,
      receiptNumber: receiptNumber,
    );
    await Printing.layoutPdf(onLayout: (format) async => pdfData);
  }

  Future<void> shareReceipt({
    required PaymentModel payment,
    required BookingModel booking,
    required CustomerModel customer,
    required String receiptNumber,
  }) async {
    final pdfData = await generateReceipt(
      payment: payment,
      booking: booking,
      customer: customer,
      receiptNumber: receiptNumber,
    );
    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'Receipt_$receiptNumber.pdf',
    );
  }
}
