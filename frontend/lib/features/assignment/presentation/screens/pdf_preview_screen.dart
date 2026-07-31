import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfPreviewScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfPreviewScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.picture_as_pdf_outlined,
                      color: Colors.red, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat PDF',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            SfPdfViewer.network(
              widget.pdfUrl,
              onDocumentLoaded: (_) {
                if (mounted) setState(() => _isLoading = false);
              },
              onDocumentLoadFailed: (details) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _error = details.description;
                  });
                }
              },
            ),
          if (_isLoading && _error == null)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 12),
                  Text('Memuat PDF...',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
