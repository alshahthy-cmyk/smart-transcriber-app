import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ResultsScreen extends StatefulWidget {
  final String text;

  const ResultsScreen({super.key, required this.text});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _displayText;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _displayText = widget.text;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _wordCount {
    if (_displayText.trim().isEmpty) return 0;
    return _displayText.trim().split(RegExp(r'\s+')).length;
  }

  int get _charCount {
    return _displayText.length;
  }

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _displayText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ النص إلى الحافظة')),
      );
    }
  }

  void _shareText() {
    Share.share(_displayText, subject: 'تفريغ النص الصوتي');
  }

  Future<void> _saveAsTxt() async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/transcription_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(_displayText);
      
      Share.shareXFiles([XFile(file.path)], text: 'مشاركة ملف النص');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
        );
      }
    }
  }

  Future<void> _saveAsPdf() async {
    try {
      final pdf = pw.Document();
      // Use predefined Arabic font for PDF, as standard fonts might not support Arabic
      final font = await PdfGoogleFonts.cairoRegular();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Text(
              _displayText,
              style: pw.TextStyle(font: font, fontSize: 14),
              textDirection: pw.TextDirection.rtl,
            ),
          ],
        ),
      );

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/transcription_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      Share.shareXFiles([XFile(file.path)], text: 'مشاركة ملف PDF');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حفظ PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Basic search highlighting logic
    List<TextSpan> _buildHighlightedText() {
      if (_searchQuery.isEmpty) {
        return [TextSpan(text: _displayText, style: TextStyle(color: Theme.of(context).colorScheme.onSurface))];
      }

      final List<TextSpan> spans = [];
      int start = 0;
      int indexOfMatch;

      while ((indexOfMatch = _displayText.toLowerCase().indexOf(_searchQuery.toLowerCase(), start)) != -1) {
        spans.add(TextSpan(text: _displayText.substring(start, indexOfMatch), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)));
        spans.add(TextSpan(
          text: _displayText.substring(indexOfMatch, indexOfMatch + _searchQuery.length),
          style: const TextStyle(backgroundColor: Colors.yellow, color: Colors.black, fontWeight: FontWeight.bold),
        ));
        start = indexOfMatch + _searchQuery.length;
      }

      spans.add(TextSpan(text: _displayText.substring(start), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)));
      return spans;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('النتائج'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'مشاركة',
            onPressed: _shareText,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'نسخ',
            onPressed: _copyToClipboard,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats & Tools
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('الكلمات', _wordCount.toString()),
                    _buildStatItem('الأحرف', _charCount.toString()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('حفظ PDF'),
                        onPressed: _saveAsPdf,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.description),
                        label: const Text('حفظ TXT'),
                        onPressed: _saveAsTxt,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'البحث داخل النص...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                )
              ],
            ),
          ),
          
          // Result Text
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: SingleChildScrollView(
                child: SelectableText.rich(
                  TextSpan(children: _buildHighlightedText()),
                  style: const TextStyle(fontSize: 16, height: 1.8),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
