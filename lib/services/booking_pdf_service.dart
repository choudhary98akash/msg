import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/booking_model.dart';
import '../models/customer_model.dart';
import '../models/nominee_model.dart';
import '../utils/formatters.dart';
import '../utils/calculator.dart';
import '../utils/amount_to_words.dart';
import '../config/constants.dart';

class BookingPdfService {
  Future<Uint8List> generateBookingForm({
    required BookingModel booking,
    required CustomerModel customer,
    required List<NomineeModel> nominees,
    required String bookingNumber,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(bookingNumber),
        footer: (context) => _buildFooter(context),
        build: (pw.Context context) {
          return [
            _buildCustomerSection(customer),
            pw.SizedBox(height: 20),
            _buildPlotSection(booking),
            pw.SizedBox(height: 20),
            _buildPaymentSection(booking),
            pw.SizedBox(height: 20),
            _buildNomineeSection(nominees),
            pw.SizedBox(height: 20),
            _buildEmiSchedule(booking),
            pw.SizedBox(height: 30),
            _buildDeclaration(),
            pw.SizedBox(height: 30),
            _buildSignature(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(String bookingNumber) {
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
          pw.SizedBox(height: 4),
          pw.Text(
            'Plot Booking Form',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Booking No: $bookingNumber'),
              pw.Text('Date: ${Formatters.formatDate(DateTime.now())}'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerSection(CustomerModel customer) {
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
            'Customer Information',
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
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Address: ${customer.address ?? "N/A"}'),
                    pw.Text('Occupation: ${customer.occupation ?? "N/A"}'),
                    if (customer.dob != null)
                      pw.Text('DOB: ${Formatters.formatDate(customer.dob!)}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPlotSection(BookingModel booking) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Plot Details',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Plot Number: ${booking.plotNumber}'),
                    pw.Text('Block: ${booking.block ?? "N/A"}'),
                    pw.Text('Sector: ${booking.sector ?? "N/A"}'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Location: ${booking.location ?? "N/A"}'),
                    pw.Text('Length: ${booking.length} ft'),
                    pw.Text('Breadth: ${booking.breadth} ft'),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text('Total Area: ${Formatters.formatArea(booking.totalArea)}'),
          pw.Text('Rate per Gaj: ${Formatters.formatCurrency(booking.ratePerGaj)}'),
          pw.Text('Total Price: ${Formatters.formatCurrency(booking.totalPrice)}'),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentSection(BookingModel booking) {
    final downPayment = booking.totalPrice * (booking.downPaymentPercent / 100);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Payment Terms',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Down Payment:'),
              pw.Text('${booking.downPaymentPercent.toStringAsFixed(0)}% (${Formatters.formatCurrency(downPayment)})'),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Token Amount:'),
              pw.Text(Formatters.formatCurrency(booking.tokenAmount)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('EMI Duration:'),
              pw.Text('${booking.emiMonths} months'),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('EMI Amount:'),
              pw.Text('${Formatters.formatCurrency(booking.emiAmount)}/month'),
            ],
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Amount in Words:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Text(
            AmountToWords.convertWithCurrency(booking.totalPrice),
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildNomineeSection(List<NomineeModel> nominees) {
    if (nominees.isEmpty) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Nominee Details',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          ...nominees.map((nominee) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text('${nominee.name} (${nominee.relation ?? "N/A"}) - ${nominee.phone ?? "N/A"}'),
          )),
        ],
      ),
    );
  }

  pw.Widget _buildEmiSchedule(BookingModel booking) {
    final startDate = booking.bookingDate;
    final emiSchedule = Calculator.generateEmiSchedule(
      emiAmount: booking.emiAmount,
      emiMonths: booking.emiMonths > 12 ? 12 : booking.emiMonths,
      startDate: DateTime(startDate.year, startDate.month + 1, startDate.day),
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'EMI Schedule (First 12 Months)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('No.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Due Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              ...emiSchedule.map((item) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('${item['emiNumber']}', textAlign: pw.TextAlign.center),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(Formatters.formatMonthYear(item['dueDate'] as DateTime), textAlign: pw.TextAlign.center),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(Formatters.formatCurrency(item['amount'] as double), textAlign: pw.TextAlign.right),
                  ),
                ],
              )),
            ],
          ),
          if (booking.emiMonths > 12)
            pw.SizedBox(height: 8),
          if (booking.emiMonths > 12)
            pw.Text('... and ${booking.emiMonths - 12} more EMI installments', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildDeclaration() {
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
            'Declaration',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'I/We hereby declare that the above information is true and correct to the best of my/our knowledge. I/We have read and understood the terms and conditions of booking.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'I/We agree to pay the installments on time and abide by the rules and regulations of M.S. Group Properties.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignature() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 120,
              child: pw.Divider(),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Applicant Signature', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 120,
              child: pw.Divider(),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Co-Applicant Signature', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 120,
              child: pw.Divider(),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated on ${Formatters.formatDateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  Future<void> printBookingForm({
    required BookingModel booking,
    required CustomerModel customer,
    required List<NomineeModel> nominees,
    required String bookingNumber,
  }) async {
    final pdfData = await generateBookingForm(
      booking: booking,
      customer: customer,
      nominees: nominees,
      bookingNumber: bookingNumber,
    );
    await Printing.layoutPdf(onLayout: (format) async => pdfData);
  }

  Future<void> shareBookingForm({
    required BookingModel booking,
    required CustomerModel customer,
    required List<NomineeModel> nominees,
    required String bookingNumber,
  }) async {
    final pdfData = await generateBookingForm(
      booking: booking,
      customer: customer,
      nominees: nominees,
      bookingNumber: bookingNumber,
    );
    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'Booking_$bookingNumber.pdf',
    );
  }
}
