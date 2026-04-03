import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/document.dart';
import '../../core/models/scan_page.dart';
import '../../core/services/pdf_service.dart';
import '../../core/theme.dart';
import '../providers/document_provider.dart';
import '../widgets/ocr_sheet.dart';
import 'camera_screen.dart';

class DocumentDetailScreen extends StatefulWidget {
  final Document document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  State<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late Document _document;
  List<ScanPage> _pages = [];
  bool _isLoading = true;
  bool _isEditingTitle = false;
  final _titleController = TextEditingController();
  final _titleFocus = FocusNode();
  int _selectedPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _titleController.text = _document.title;
    _loadPages();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  Future<void> _loadPages() async {
    setState(() => _isLoading = true);
    try {
      _pages =
          await context.read<DocumentProvider>().getPagesForDocument(_document.id);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _renameDocument() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty || newTitle == _document.title) {
      setState(() => _isEditingTitle = false);
      return;
    }
    await context.read<DocumentProvider>().renameDocument(_document.id, newTitle);
    setState(() {
      _document = _document.copyWith(title: newTitle);
      _isEditingTitle = false;
    });
  }

  Future<void> _sharePdf(String quality) async {
    final snackbar = ScaffoldMessenger.of(context);
    snackbar.showSnackBar(
        const SnackBar(content: Text('Preparing PDF...')));

    try {
      final pdfPath = await PdfService.compilePdf(
        _document.id,
        _pages.map((p) => p.imagePath).toList(),
        quality: quality,
      );
      await Share.shareXFiles(
        [XFile(pdfPath, mimeType: 'application/pdf')],
        subject: _document.title,
      );
    } catch (e) {
      if (mounted) {
        snackbar.showSnackBar(SnackBar(content: Text('Export error: $e')));
      }
    }
  }

  Future<void> _shareJpeg(ScanPage page) async {
    try {
      await Share.shareXFiles(
        [XFile(page.imagePath, mimeType: 'image/jpeg')],
        subject: '${_document.title} - Page ${page.pageNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Share error: $e')));
      }
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Export',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF — Low Quality'),
              subtitle: const Text('Smaller file size'),
              onTap: () {
                Navigator.pop(ctx);
                _sharePdf('low');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF — Medium Quality'),
              subtitle: const Text('Balanced'),
              onTap: () {
                Navigator.pop(ctx);
                _sharePdf('medium');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF — High Quality'),
              subtitle: const Text('Best quality, larger file'),
              onTap: () {
                Navigator.pop(ctx);
                _sharePdf('high');
              },
            ),
            if (_pages.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('JPEG — Current Page'),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareJpeg(_pages[_selectedPageIndex]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOcrText() async {
    if (_pages.isEmpty) return;
    final text = _pages[_selectedPageIndex].extractedText;
    await OcrSheet.show(context, text);
  }

  Future<void> _addPages() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    // After camera returns, reload pages (user scanned more)
    if (mounted) await _loadPages();
  }

  Future<void> _deleteDocument() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${_document.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<DocumentProvider>().deleteDocument(_document.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isEditingTitle
            ? TextField(
                controller: _titleController,
                focusNode: _titleFocus,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  filled: false,
                ),
                onSubmitted: (_) => _renameDocument(),
              )
            : GestureDetector(
                onTap: () {
                  setState(() => _isEditingTitle = true);
                  Future.delayed(const Duration(milliseconds: 50), () {
                    _titleFocus.requestFocus();
                  });
                },
                child: Text(
                  _document.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        actions: [
          if (_isEditingTitle)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _renameDocument,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.ios_share),
              onPressed: _showExportOptions,
              tooltip: 'Export',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.description_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No pages found'),
                      TextButton(
                          onPressed: _addPages,
                          child: const Text('Add Pages')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Page count indicator
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Text(
                            '${_pages.length} page${_pages.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                          const Spacer(),
                          Text(
                            '${(_document.totalSizeBytes / 1024).toStringAsFixed(0)} KB',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),

                    // Pages list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _pages.length,
                        itemBuilder: (context, index) {
                          final page = _pages[index];
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedPageIndex = index),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _selectedPageIndex == index
                                      ? AppColors.accent
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Page image
                                    AspectRatio(
                                      aspectRatio: 0.77,
                                      child: File(page.imagePath)
                                              .existsSync()
                                          ? Image.file(
                                              File(page.imagePath),
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                  Icons
                                                      .broken_image_outlined,
                                                  size: 48),
                                            ),
                                    ),
                                    // Page number label
                                    Container(
                                      color:
                                          Colors.grey.shade100,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Page ${page.pageNumber}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w500),
                                          ),
                                          const Spacer(),
                                          if (page.extractedText != null &&
                                              page.extractedText!.isNotEmpty)
                                            const Icon(Icons.text_fields,
                                                size: 14,
                                                color: AppColors.accent),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

      // Bottom action bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomAction(
              icon: Icons.add_photo_alternate_outlined,
              label: 'Add Page',
              onTap: _addPages,
            ),
            _BottomAction(
              icon: Icons.text_fields_outlined,
              label: 'OCR Text',
              onTap: _showOcrText,
            ),
            _BottomAction(
              icon: Icons.ios_share,
              label: 'Export',
              onTap: _showExportOptions,
            ),
            _BottomAction(
              icon: Icons.delete_outline,
              label: 'Delete',
              onTap: _deleteDocument,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: effectiveColor),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(fontSize: 11, color: effectiveColor)),
          ],
        ),
      ),
    );
  }
}
