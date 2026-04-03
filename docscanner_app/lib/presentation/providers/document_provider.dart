import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/models/document.dart';
import '../../core/models/scan_page.dart';
import '../../core/models/tag.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/thumbnail_service.dart';

enum SortOrder { date, name }

class DocumentProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  final _uuid = const Uuid();

  List<Document> _documents = [];
  List<Document> _filtered = [];
  String _searchQuery = '';
  SortOrder _sortOrder = SortOrder.date;
  bool _isLoading = false;
  String? _error;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<Document> get documents =>
      _searchQuery.isEmpty ? _documents : _filtered;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SortOrder get sortOrder => _sortOrder;
  String get searchQuery => _searchQuery;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _documents = await _db.getAllDocuments();
      _applySort();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<Document> addDocument(Document doc) async {
    await _db.insertDocument(doc);
    _documents.insert(0, doc);
    _applySort();
    notifyListeners();
    return doc;
  }

  Future<void> updateDocument(Document doc) async {
    await _db.updateDocument(doc);
    final idx = _documents.indexWhere((d) => d.id == doc.id);
    if (idx != -1) {
      _documents[idx] = doc;
      _applySort();
      notifyListeners();
    }
  }

  Future<void> deleteDocument(String id) async {
    // Delete pages from disk first
    final pages = await _db.getPagesForDocument(id);
    for (final page in pages) {
      _deleteFileIfExists(page.imagePath);
      _deleteFileIfExists(page.thumbnailPath);
    }
    await PdfService.deletePdf(id);
    await _db.deleteDocument(id);
    _documents.removeWhere((d) => d.id == id);
    _filtered.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  /// Rename a document.
  Future<void> renameDocument(String id, String newTitle) async {
    final doc = _documents.firstWhere((d) => d.id == id);
    final updated = doc.copyWith(
        title: newTitle, updatedAt: DateTime.now());
    await updateDocument(updated);
  }

  // ── Scan & Save ────────────────────────────────────────────────────────────

  /// Save a new document from scanned image paths.
  /// Runs OCR on each page, generates thumbnails, compiles PDF.
  /// Returns the created Document.
  Future<Document> saveScannedPages(
    List<String> imagePaths, {
    String? title,
    String quality = 'medium',
  }) async {
    final docId = _uuid.v4();
    final now = DateTime.now();
    final docTitle = title ??
        'Scan ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

    // Copy images to app documents dir (source paths may be temp)
    final appDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory(path_pkg.join(appDir.path, 'scans', docId));
    scansDir.createSync(recursive: true);

    final pages = <ScanPage>[];
    int totalSize = 0;
    Uint8List? firstThumb;

    for (int i = 0; i < imagePaths.length; i++) {
      final srcPath = imagePaths[i];
      final pageId = _uuid.v4();
      final destPath =
          path_pkg.join(scansDir.path, '${i + 1}_$pageId.jpg');

      // Copy image file
      await File(srcPath).copy(destPath);
      final fileSize = await File(destPath).length();
      totalSize += fileSize;

      // OCR
      final text = await OcrService.extractText(destPath);

      // Thumbnail
      final thumbPath =
          await ThumbnailService.generateThumbnail(destPath, pageId);

      if (i == 0) {
        firstThumb = await ThumbnailService.generateThumbnailBytes(destPath);
      }

      pages.add(ScanPage(
        id: pageId,
        documentId: docId,
        pageNumber: i + 1,
        imagePath: destPath,
        thumbnailPath: thumbPath,
        extractedText: text,
        createdAt: now,
      ));
    }

    // Create document
    final doc = Document(
      id: docId,
      title: docTitle,
      pageCount: pages.length,
      totalSizeBytes: totalSize,
      createdAt: now,
      updatedAt: now,
      tags: [],
      thumbnailBytes: firstThumb,
    );

    await _db.insertDocument(doc);
    for (final page in pages) {
      await _db.insertPage(page);
    }

    // Compile PDF in background
    final imagePaths2 = pages.map((p) => p.imagePath).toList();
    PdfService.compilePdf(docId, imagePaths2, quality: quality).ignore();

    _documents.insert(0, doc);
    _applySort();
    notifyListeners();
    return doc;
  }

  /// Add more pages to an existing document.
  Future<void> addPagesToDocument(
      String documentId, List<String> imagePaths) async {
    final docIdx = _documents.indexWhere((d) => d.id == documentId);
    if (docIdx == -1) return;

    final now = DateTime.now();
    final existingPages = await _db.getPagesForDocument(documentId);
    int startPageNum = existingPages.length + 1;

    final appDir = await getApplicationDocumentsDirectory();
    final scansDir =
        Directory(path_pkg.join(appDir.path, 'scans', documentId));
    scansDir.createSync(recursive: true);

    int addedSize = 0;
    for (int i = 0; i < imagePaths.length; i++) {
      final srcPath = imagePaths[i];
      final pageId = _uuid.v4();
      final pageNum = startPageNum + i;
      final destPath =
          path_pkg.join(scansDir.path, '${pageNum}_$pageId.jpg');

      await File(srcPath).copy(destPath);
      final fileSize = await File(destPath).length();
      addedSize += fileSize;

      final text = await OcrService.extractText(destPath);
      final thumbPath =
          await ThumbnailService.generateThumbnail(destPath, pageId);

      await _db.insertPage(ScanPage(
        id: pageId,
        documentId: documentId,
        pageNumber: pageNum,
        imagePath: destPath,
        thumbnailPath: thumbPath,
        extractedText: text,
        createdAt: now,
      ));
    }

    final oldDoc = _documents[docIdx];
    final updatedDoc = oldDoc.copyWith(
      pageCount: oldDoc.pageCount + imagePaths.length,
      totalSizeBytes: oldDoc.totalSizeBytes + addedSize,
      updatedAt: now,
    );
    await _db.updateDocument(updatedDoc);
    _documents[docIdx] = updatedDoc;
    _applySort();
    notifyListeners();

    // Recompile PDF
    final allPages = await _db.getPagesForDocument(documentId);
    PdfService.compilePdf(documentId, allPages.map((p) => p.imagePath).toList())
        .ignore();
  }

  // ── Pages ──────────────────────────────────────────────────────────────────

  Future<List<ScanPage>> getPagesForDocument(String documentId) async {
    return _db.getPagesForDocument(documentId);
  }

  Future<void> deletePage(String documentId, String pageId) async {
    final page = (await _db.getPagesForDocument(documentId))
        .firstWhere((p) => p.id == pageId);
    _deleteFileIfExists(page.imagePath);
    _deleteFileIfExists(page.thumbnailPath);
    await _db.deletePage(pageId);

    // Re-number remaining pages
    final remaining = await _db.getPagesForDocument(documentId);
    for (int i = 0; i < remaining.length; i++) {
      final updated = remaining[i].copyWith(pageNumber: i + 1);
      await _db.updatePage(updated);
    }

    final docIdx = _documents.indexWhere((d) => d.id == documentId);
    if (docIdx != -1) {
      final oldDoc = _documents[docIdx];
      final updatedDoc = oldDoc.copyWith(
        pageCount: remaining.length,
        updatedAt: DateTime.now(),
      );
      await _db.updateDocument(updatedDoc);
      _documents[docIdx] = updatedDoc;
      _applySort();
      notifyListeners();
    }
  }

  Future<void> reorderPages(
      String documentId, List<ScanPage> reorderedPages) async {
    for (int i = 0; i < reorderedPages.length; i++) {
      final updated = reorderedPages[i].copyWith(pageNumber: i + 1);
      await _db.updatePage(updated);
    }
    notifyListeners();
  }

  // ── Search & Sort ──────────────────────────────────────────────────────────

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _filtered = [];
      notifyListeners();
      return;
    }
    _filtered = await _db.searchDocuments(query);
    notifyListeners();
  }

  void setSortOrder(SortOrder order) {
    _sortOrder = order;
    _applySort();
    notifyListeners();
  }

  void _applySort() {
    if (_sortOrder == SortOrder.date) {
      _documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      _documents.sort((a, b) => a.title.compareTo(b.title));
    }
  }

  // ── Tags ───────────────────────────────────────────────────────────────────

  Future<void> addTag(String documentId, String tagName) async {
    final tag = await _db.upsertTag(tagName);
    await _db.addTagToDocument(documentId, tag.id);

    final docIdx = _documents.indexWhere((d) => d.id == documentId);
    if (docIdx != -1) {
      final oldDoc = _documents[docIdx];
      if (!oldDoc.tags.contains(tagName)) {
        _documents[docIdx] = oldDoc.copyWith(tags: [...oldDoc.tags, tagName]);
        notifyListeners();
      }
    }
  }

  Future<void> removeTag(String documentId, String tagName) async {
    final tags = await _db.getTagsForDocument(documentId);
    final tag = tags.where((t) => t.name == tagName).firstOrNull;
    if (tag != null) {
      await _db.removeTagFromDocument(documentId, tag.id);
    }

    final docIdx = _documents.indexWhere((d) => d.id == documentId);
    if (docIdx != -1) {
      final oldDoc = _documents[docIdx];
      _documents[docIdx] =
          oldDoc.copyWith(tags: oldDoc.tags.where((t) => t != tagName).toList());
      notifyListeners();
    }
  }

  Future<List<Tag>> getAllTags() => _db.getAllTags();

  // ── Clear All Data ─────────────────────────────────────────────────────────

  /// Wipe all documents, images, PDFs, thumbnails, and database rows.
  Future<void> clearAllData() async {
    // Delete scans, pdfs, and thumbnails directories from disk
    final appDir = await getApplicationDocumentsDirectory();
    final dirs = ['scans', 'pdfs', 'thumbnails'];
    for (final dirName in dirs) {
      final dir = Directory(path_pkg.join(appDir.path, dirName));
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    }

    // Clear all database rows
    await _db.deleteAllData();

    // Reset in-memory state
    _documents = [];
    _filtered = [];
    _searchQuery = '';
    _error = null;
    notifyListeners();
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  void _deleteFileIfExists(String? filePath) {
    if (filePath == null) return;
    try {
      final f = File(filePath);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }
}
