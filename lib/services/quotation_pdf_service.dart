import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/quotation_model.dart';
import '../utils/formatters.dart';
import '../utils/amount_to_words.dart';
import '../config/constants.dart';

class QuotationPdfService {
  Future<Uint8List> generateQuotation({
    required QuotationModel quotation,
    required String quotationNumber,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(quotationNumber),
        footer: (context) => _buildFooter(context),
        build: (pw.Context context) {
          return [
            _buildQuotationInfo(quotation),
            pw.SizedBox(height: 20),
            _buildCustomerDetails(quotation),
            pw.SizedBox(height: 20),
            _buildPlotDetails(quotation),
            pw.SizedBox(height: 20),
            _buildPricingDetails(quotation),
            pw.SizedBox(height: 20),
            _buildPaymentSchedule(quotation),
            pw.SizedBox(height: 20),
            _buildTermsAndConditions(),
            pw.SizedBox(height: 30),
            _buildSignature(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(String quotationNumber) {
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
            'Quotation',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Quotation No: $quotationNumber'),
              pw.Text('Date: ${Formatters.formatDate(DateTime.now())}'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildQuotationInfo(QuotationModel quotation) {
    final statusColor = quotation.isExpired ? PdfColors.red : PdfColors.green;
    final statusText = quotation.isExpired ? 'EXPIRED' : quotation.status.toUpperCase();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: statusColor.shade(50),
        border: pw.Border.all(color: statusColor),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Status: $statusText'),
          if (quotation.validUntil != null)
            pw.Text('Valid Until: ${Formatters.formatDate(quotation.validUntil!)}'),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerDetails(QuotationModel quotation) {
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
          pw.Text('Name: ${quotation.customerName}'),
          if (quotation.phone != null)
            pw.Text('Phone: ${quotation.phone}'),
        ],
      ),
    );
  }

  pw.Widget _buildPlotDetails(QuotationModel quotation) {
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
                    pw.Text('Plot Number: ${quotation.plotNumber}'),
                    pw.Text('Block: ${quotation.block ?? "N/A"}'),
                    pw.Text('Sector: ${quotation.sector ?? "N/A"}'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Location: ${quotation.location ?? "N/A"}'),
                    pw.Text('Length: ${quotation.length} ft'),
                    pw.Text('Breadth: ${quotation.breadth} ft'),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text('Total Area: ${Formatters.formatArea(quotation.totalArea)}'),
        ],
      ),
    );
  }

  pw.Widget _buildPricingDetails(QuotationModel quotation) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Pricing Details',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Rate per Gaj:'),
              pw.Text(Formatters.formatCurrency(quotation.ratePerGaj)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Price:'),
              pw.Text(Formatters.formatCurrency(quotation.totalPrice)),
            ],
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Amount in Words:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Text(
            AmountToWords.convertWithCurrency(quotation.totalPrice),
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentSchedule(QuotationModel quotation) {
    final downPayment = quotation.totalPrice * (quotation.downPaymentPercent / 100);
    final emiAmount = quotation.emiAmount;
    final loanAmount = quotation.totalPrice - downPayment;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Payment Schedule',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Payment Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Down Payment'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('${quotation.downPaymentPercent.toStringAsFixed(0)}%', textAlign: pw.TextAlign.center),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(Formatters.formatCurrency(downPayment), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('EMI (${quotation.emiMonths} months)'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('-', textAlign: pw.TextAlign.center),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('${Formatters.formatCurrency(emiAmount)}/month', textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Loan Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('-', textAlign: pw.TextAlign.center),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(Formatters.formatCurrency(loanAmount), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text('Total EMI Amount: ${Formatters.formatCurrency(emiAmount * quotation.emiMonths)}'),
        ],
      ),
    );
  }

  pw.Widget _buildTermsAndConditions() {
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
            'Terms & Conditions',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Text('1. This quotation is valid for 30 days from the date of issue.', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('2. Prices are subject to change without prior notice.', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('3. Registration and other charges are extra.', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('4. Lease deed execution charges to be borne by the allottee.', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('5. EMI defaults will attract penalty as per company policy.', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('6. This quotation does not constitute an agreement to sell.', style: const pw.TextStyle(fontSize: 10)),
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

  Future<void> printQuotation({
    required QuotationModel quotation,
    required String quotationNumber,
  }) async {
    final pdfData = await generateQuotation(
      quotation: quotation,
      quotationNumber: quotationNumber,
    );
    await Printing.layoutPdf(onLayout: (format) async => pdfData);
  }

  Future<void> shareQuotation({
    required QuotationModel quotation,
    required String quotationNumber,
  }) async {
    final pdfData = await generateQuotation(
      quotation: quotation,
      quotationNumber: quotationNumber,
    );
    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'Quotation_$quotationNumber.pdf',
    );
  }
}
