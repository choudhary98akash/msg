import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../../services/database_service.dart';
import '../../models/quotation_model.dart';
import '../../utils/formatters.dart';
import '../../config/theme.dart';

class QuotationDetailScreen extends StatefulWidget {
  final QuotationModel quotation;

  const QuotationDetailScreen({super.key, required this.quotation});

  @override
  State<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  final GlobalKey _captureKey = GlobalKey();

  QuotationModel? _quotation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _quotation = widget.quotation;
    _loadQuotation();
  }

  Future<void> _loadQuotation() async {
    setState(() => _isLoading = true);
    try {
      final quotation = await _dbService.getQuotation(widget.quotation.id!);
      if (mounted) {
        if (quotation == null) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quotation not found')),
          );
        } else {
          setState(() {
            _quotation = quotation;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _generatePdf({required bool print}) async {
    if (_quotation == null) return;
    // PDF generation using existing service if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotation Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'print' || value == 'share') {
                _takeScreenshot();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'print',
                child: ListTile(
                  leading: Icon(Icons.print),
                  title: Text('Print'),
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _quotation == null
                    ? const Center(child: Text('Quotation not found'))
                    : RefreshIndicator(
                        onRefresh: _loadQuotation,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: RepaintBoundary(
                            key: _captureKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCustomerCard(),
                                const SizedBox(height: 16),
                                _buildPlotCard(),
                                const SizedBox(height: 16),
                                _buildDimensionsCard(),
                                const SizedBox(height: 16),
                                _buildPricingCard(),
                                const SizedBox(height: 16),
                                _buildPaymentScheduleCard(),
                                if (_quotation?.remarks != null) ...[
                                  const SizedBox(height: 16),
                                  _buildRemarksCard(),
                                ],
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildShareButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Customer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Name', _quotation!.customerName),
            if (_quotation!.phone != null)
              _buildInfoRow('Phone', _quotation!.phone!),
          ],
        ),
      ),
    );
  }

  Widget _buildPlotCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.home, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Plot Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Plot Number', _quotation!.plotNumber),
            if (_quotation!.block != null)
              _buildInfoRow('Block', _quotation!.block!),
            if (_quotation!.sector != null)
              _buildInfoRow('Sector', _quotation!.sector!),
            if (_quotation!.location != null)
              _buildInfoRow('Location', _quotation!.location!),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionsCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.straighten,
                      color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Dimensions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Length', '${_quotation!.length} ft'),
            _buildInfoRow('Breadth', '${_quotation!.breadth} ft'),
            _buildInfoRow(
                'Total Area', Formatters.formatArea(_quotation!.totalArea)),
            _buildInfoRow(
                'Rate', Formatters.formatCurrency(_quotation!.ratePerGaj)),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    final downPayment =
        _quotation!.totalPrice * (_quotation!.downPaymentPercent / 100);

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.currency_rupee,
                      color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Pricing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Total Price',
                Formatters.formatCurrency(_quotation!.totalPrice)),
            _buildInfoRow('Down Payment',
                '${_quotation!.downPaymentPercent.toStringAsFixed(0)}% (${Formatters.formatCurrency(downPayment)})'),
            _buildInfoRow('EMI',
                '${Formatters.formatCurrency(_quotation!.emiAmount)} x ${_quotation!.emiMonths} months'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentScheduleCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.schedule, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Payment Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF388E3C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Immediate Payment', style: TextStyle(fontSize: 12)),
                      Text('Down Payment',
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  Text(
                    Formatters.formatCurrency(_quotation!.downPaymentAmount),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF388E3C)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Monthly EMI', style: TextStyle(fontSize: 12)),
                      Text('${_quotation!.emiMonths} months',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 11)),
                    ],
                  ),
                  Text(
                    Formatters.formatCurrency(_quotation!.emiAmount),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1976D2)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.note, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Remarks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(_quotation!.remarks ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _takeScreenshot,
        icon: const Icon(Icons.share),
        label: const Text('Share Quote'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  Future<void> _takeScreenshot() async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  const Text('Creating PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null && mounted) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        await _createAndSharePdf(pngBytes);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _createAndSharePdf(Uint8List imageBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final PdfPageFormat format = PdfPageFormat(
        image.width.toDouble(),
        image.height.toDouble(),
        marginAll: 0,
      );

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );

      final bytes = await pdf.save();

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'quotation_${_quotation?.plotNumber ?? 'share'}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating PDF: $e')),
        );
      }
    }
  }
}
