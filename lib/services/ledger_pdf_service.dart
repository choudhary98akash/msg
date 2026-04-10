import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/ledger_party_model.dart';
import '../models/ledger_transaction_model.dart';
import '../utils/formatters.dart';
import '../config/theme.dart';

class LedgerPdfService {
  static Future<void> generatePartyStatement({
    required LedgerParty party,
    required List<LedgerTransaction> transactions,
    required double totalGive,
    required double totalTake,
    required double balance,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(party),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildPartyInfo(party),
          pw.SizedBox(height: 20),
          _buildBalanceSummary(party, totalGive, totalTake, balance),
          pw.SizedBox(height: 20),
          _buildTransactionTable(party, transactions),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${party.name}_ledger_statement.pdf',
    );
  }

  static Future<void> generateFullLedgerReport({
    required List<LedgerPartyWithBalance> parties,
    required double totalYouWillGet,
    required double totalYouWillGive,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildFullReportHeader(),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildFullLedgerSummary(totalYouWillGet, totalYouWillGive),
          pw.SizedBox(height: 20),
          _buildPartiesTable(parties),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'ledger_full_report.pdf',
    );
  }

  static pw.Widget _buildHeader(LedgerParty party) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border:
            pw.Border(bottom: pw.BorderSide(color: PdfColors.orange, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'M.S. Group Properties',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#FF6600'),
                ),
              ),
              pw.Text(
                'Ledger Account Statement',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Text(
            'Generated: ${Formatters.formatDate(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFullReportHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border:
            pw.Border(bottom: pw.BorderSide(color: PdfColors.orange, width: 2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'M.S. Group Properties',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#FF6600'),
            ),
          ),
          pw.Text(
            'Complete Ledger Report',
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPartyInfo(LedgerParty party) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Party Name',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  party.name,
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          if (party.phone != null && party.phone!.isNotEmpty)
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Phone',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    party.phone!,
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Type',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  party.isDebtor ? 'Debtor' : 'Creditor',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color:
                        party.isDebtor ? PdfColors.green700 : PdfColors.red700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBalanceSummary(
    LedgerParty party,
    double totalGive,
    double totalTake,
    double balance,
  ) {
    final isPositive = balance >= 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryBox('Total Given', totalGive, PdfColors.red700),
              _buildSummaryBox('Total Taken', totalTake, PdfColors.green700),
              _buildSummaryBox(
                'Current Balance',
                balance.abs(),
                isPositive ? PdfColors.green700 : PdfColors.red700,
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: (isPositive ? PdfColors.green700 : PdfColors.red700)
                  .shade(0.1),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              party.isDebtor
                  ? (isPositive ? 'They will pay you' : 'You have to pay')
                  : (isPositive ? 'You have to give' : 'They will give you'),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: isPositive ? PdfColors.green700 : PdfColors.red700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryBox(
      String label, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          Formatters.formatCurrency(amount),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionTable(
    LedgerParty party,
    List<LedgerTransaction> transactions,
  ) {
    if (transactions.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Text(
          'No transactions found',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey500),
        ),
      );
    }

    double runningBalance = party.openingBalance;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.orange100),
          children: [
            _buildTableHeader('Date'),
            _buildTableHeader('Given'),
            _buildTableHeader('Taken'),
            _buildTableHeader('Amount'),
            _buildTableHeader('Remark'),
          ],
        ),
        if (party.openingBalance != 0)
          pw.TableRow(
            children: [
              _buildTableCell('Opening', isHeader: true),
              _buildTableCell(''),
              _buildTableCell(''),
              _buildTableCell(Formatters.formatCurrency(party.openingBalance),
                  isBold: true),
              _buildTableCell('Opening Balance'),
            ],
          ),
        ...transactions.map((t) {
          if (t.isGive) {
            runningBalance -= t.amount;
          } else {
            runningBalance += t.amount;
          }
          return pw.TableRow(
            children: [
              _buildTableCell(Formatters.formatDate(t.date)),
              _buildTableCell(
                  t.isGive ? Formatters.formatCurrency(t.amount) : '-',
                  color: PdfColors.red700),
              _buildTableCell(
                  t.isTake ? Formatters.formatCurrency(t.amount) : '-',
                  color: PdfColors.green700),
              _buildTableCell(Formatters.formatCurrency(t.amount)),
              _buildTableCell(t.remark ?? '-'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text,
      {bool isHeader = false, bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight:
              isBold || isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildFullLedgerSummary(double totalGet, double totalGive) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text(
                'You Will Get',
                style:
                    const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                Formatters.formatCurrency(totalGet),
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700),
              ),
            ],
          ),
          pw.Column(
            children: [
              pw.Text(
                'You Will Give',
                style:
                    const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                Formatters.formatCurrency(totalGive),
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red700),
              ),
            ],
          ),
          pw.Column(
            children: [
              pw.Text(
                'Net Balance',
                style:
                    const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                Formatters.formatCurrency(totalGet - totalGive),
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPartiesTable(List<LedgerPartyWithBalance> parties) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.orange100),
          children: [
            _buildTableHeader('Party Name'),
            _buildTableHeader('Type'),
            _buildTableHeader('Phone'),
            _buildTableHeader('Balance'),
          ],
        ),
        ...parties.map((item) {
          final isPositive = item.currentBalance >= 0;
          return pw.TableRow(
            children: [
              _buildTableCell(item.party.name, isBold: true),
              _buildTableCell(item.party.isDebtor ? 'Debtor' : 'Creditor'),
              _buildTableCell(item.party.phone ?? '-'),
              _buildTableCell(
                Formatters.formatCurrency(item.currentBalance.abs()),
                color: isPositive ? PdfColors.green700 : PdfColors.red700,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'M.S. Group Properties',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }
}
