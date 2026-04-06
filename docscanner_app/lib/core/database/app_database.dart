import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_pkg;
import '../constants.dart';
import '../models/document.dart';
import '../models/scan_page.dart';
import '../models/tag.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _db;

  AppDatabase._internal();

  factory AppDatabase() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final fullPath = path_pkg.join(dbPath, AppConstants.dbName);

    return await openDatabase(
      fullPath,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Documents table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableDocuments} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        page_count INTEGER NOT NULL DEFAULT 0,
        total_size_bytes INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Pages table
    await db.execute('''
      CREATE TABLE ${AppConstants.tablePages} (
        id TEXT PRIMARY KEY,
        document_id TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        thumbnail_path TEXT,
        extracted_text TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (document_id) REFERENCES ${AppConstants.tableDocuments}(id) ON DELETE CASCADE
      )
    ''');

    // Tags table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableTags} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Document-tags join table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableDocumentTags} (
        document_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (document_id, tag_id),
        FOREIGN KEY (document_id) REFERENCES ${AppConstants.tableDocuments}(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES ${AppConstants.tableTags}(id) ON DELETE CASCADE
      )
    ''');

    // FTS5 virtual table for full-text search on extracted_text
    // FTS5 may not be available on all Android versions; degrade gracefully.
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE ${AppConstants.tablePagesFts} USING fts5(
          page_id UNINDEXED,
          document_id UNINDEXED,
          extracted_text,
          content=${AppConstants.tablePages},
          content_rowid=rowid
        )
      ''');

      // Triggers to keep FTS in sync
      await db.execute('''
        CREATE TRIGGER pages_ai AFTER INSERT ON ${AppConstants.tablePages} BEGIN
          INSERT INTO ${AppConstants.tablePagesFts}(rowid, page_id, document_id, extracted_text)
          VALUES (new.rowid, new.id, new.document_id, new.extracted_text);
        END
      ''');

    await db.execute('''
      CREATE TRIGGER pages_ad AFTER DELETE ON ${AppConstants.tablePages} BEGIN
        INSERT INTO ${AppConstants.tablePagesFts}(${AppConstants.tablePagesFts}, rowid, page_id, document_id, extracted_text)
        VALUES('delete', old.rowid, old.id, old.document_id, old.extracted_text);
      END
    ''');

      await db.execute('''
        CREATE TRIGGER pages_au AFTER UPDATE ON ${AppConstants.tablePages} BEGIN
          INSERT INTO ${AppConstants.tablePagesFts}(${AppConstants.tablePagesFts}, rowid, page_id, document_id, extracted_text)
          VALUES('delete', old.rowid, old.id, old.document_id, old.extracted_text);
          INSERT INTO ${AppConstants.tablePagesFts}(rowid, page_id, document_id, extracted_text)
          VALUES (new.rowid, new.id, new.document_id, new.extracted_text);
        END
      ''');
    } catch (e) {
      // FTS5 not available on this platform — full-text search will fall back
      // to LIKE queries. The app remains fully functional.
    }

    // Indexes for common queries
    await db.execute(
        'CREATE INDEX idx_pages_document_id ON ${AppConstants.tablePages}(document_id)');
    await db.execute(
        'CREATE INDEX idx_documents_created_at ON ${AppConstants.tableDocuments}(created_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here, keyed on version numbers
    // e.g. if (oldVersion < 2) { ... }
  }

  // ── Documents ──────────────────────────────────────────────────────────────

  Future<void> insertDocument(Document doc) async {
    final db = await database;
    await db.insert(AppConstants.tableDocuments, doc.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateDocument(Document doc) async {
    final db = await database;
    await db.update(
      AppConstants.tableDocuments,
      doc.toMap(),
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }

  Future<void> deleteDocument(String id) async {
    final db = await database;
    await db.delete(
      AppConstants.tableDocuments,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Document>> getAllDocuments() async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableDocuments,
      orderBy: 'created_at DESC',
    );
    final docs = <Document>[];
    for (final row in rows) {
      final tags = await getTagsForDocument(row['id'] as String);
      docs.add(Document.fromMap(row, tags: tags.map((t) => t.name).toList()));
    }
    return docs;
  }

  Future<Document?> getDocument(String id) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableDocuments,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    final tags = await getTagsForDocument(id);
    return Document.fromMap(rows.first,
        tags: tags.map((t) => t.name).toList());
  }

  // ── Pages ──────────────────────────────────────────────────────────────────

  Future<void> insertPage(ScanPage page) async {
    final db = await database;
    await db.insert(AppConstants.tablePages, page.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePage(ScanPage page) async {
    final db = await database;
    await db.update(
      AppConstants.tablePages,
      page.toMap(),
      where: 'id = ?',
      whereArgs: [page.id],
    );
  }

  Future<void> deletePage(String pageId) async {
    final db = await database;
    await db.delete(
      AppConstants.tablePages,
      where: 'id = ?',
      whereArgs: [pageId],
    );
  }

  Future<List<ScanPage>> getPagesForDocument(String documentId) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tablePages,
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'page_number ASC',
    );
    return rows.map(ScanPage.fromMap).toList();
  }

  Future<void> deleteAllPagesForDocument(String documentId) async {
    final db = await database;
    await db.delete(
      AppConstants.tablePages,
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }

  // ── FTS Search ─────────────────────────────────────────────────────────────

  /// Returns document IDs that contain pages matching the full-text query.
  Future<List<String>> searchDocumentIds(String query) async {
    if (query.trim().isEmpty) return [];
    final db = await database;

    try {
      // Escape FTS special characters and append wildcard for prefix matching
      final escaped = query.trim().replaceAll('"', '""');
      final ftsQuery = '"$escaped"*';

      final rows = await db.rawQuery('''
        SELECT DISTINCT document_id
        FROM ${AppConstants.tablePagesFts}
        WHERE ${AppConstants.tablePagesFts} MATCH ?
      ''', [ftsQuery]);

      return rows.map((r) => r['document_id'] as String).toList();
    } catch (_) {
      // FTS5 not available — fall back to LIKE query on pages table
      final rows = await db.rawQuery('''
        SELECT DISTINCT document_id FROM ${AppConstants.tablePages}
        WHERE LOWER(extracted_text) LIKE ?
      ''', ['%${query.trim().toLowerCase()}%']);
      return rows.map((r) => r['document_id'] as String).toList();
    }
  }

  /// Full document search: returns matching Documents.
  Future<List<Document>> searchDocuments(String query) async {
    if (query.trim().isEmpty) return getAllDocuments();

    // Also search by title
    final db = await database;
    final ftsIds = await searchDocumentIds(query);

    final titleRows = await db.query(
      AppConstants.tableDocuments,
      where: 'LOWER(title) LIKE ?',
      whereArgs: ['%${query.toLowerCase()}%'],
    );
    final titleIds = titleRows.map((r) => r['id'] as String).toList();

    final allIds = {...ftsIds, ...titleIds}.toList();
    if (allIds.isEmpty) return [];

    final placeholders = allIds.map((_) => '?').join(', ');
    final rows = await db.rawQuery(
      'SELECT * FROM ${AppConstants.tableDocuments} WHERE id IN ($placeholders) ORDER BY created_at DESC',
      allIds,
    );

    final docs = <Document>[];
    for (final row in rows) {
      final tags = await getTagsForDocument(row['id'] as String);
      docs.add(Document.fromMap(row, tags: tags.map((t) => t.name).toList()));
    }
    return docs;
  }

  // ── Tags ───────────────────────────────────────────────────────────────────

  Future<Tag> upsertTag(String name) async {
    final db = await database;
    final existing = await db.query(
      AppConstants.tableTags,
      where: 'name = ?',
      whereArgs: [name],
    );
    if (existing.isNotEmpty) {
      return Tag.fromMap(existing.first);
    }
    final id = name.toLowerCase().replaceAll(' ', '_');
    final tag = Tag(id: id, name: name);
    await db.insert(AppConstants.tableTags, tag.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
    return tag;
  }

  Future<List<Tag>> getTagsForDocument(String documentId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT t.* FROM ${AppConstants.tableTags} t
      INNER JOIN ${AppConstants.tableDocumentTags} dt ON dt.tag_id = t.id
      WHERE dt.document_id = ?
    ''', [documentId]);
    return rows.map(Tag.fromMap).toList();
  }

  Future<void> addTagToDocument(String documentId, String tagId) async {
    final db = await database;
    await db.insert(
      AppConstants.tableDocumentTags,
      {'document_id': documentId, 'tag_id': tagId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeTagFromDocument(String documentId, String tagId) async {
    final db = await database;
    await db.delete(
      AppConstants.tableDocumentTags,
      where: 'document_id = ? AND tag_id = ?',
      whereArgs: [documentId, tagId],
    );
  }

  Future<List<Tag>> getAllTags() async {
    final db = await database;
    final rows = await db.query(AppConstants.tableTags, orderBy: 'name ASC');
    return rows.map(Tag.fromMap).toList();
  }

  /// Delete all rows from every table and reset the database.
  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete(AppConstants.tableDocumentTags);
    await db.delete(AppConstants.tablePages);
    await db.delete(AppConstants.tableDocuments);
    await db.delete(AppConstants.tableTags);
    // Rebuild the FTS index after clearing pages (if FTS5 is available)
    try {
      await db.execute(
          "INSERT INTO ${AppConstants.tablePagesFts}(${AppConstants.tablePagesFts}) VALUES('rebuild')");
    } catch (_) {
      // FTS5 not available — nothing to rebuild
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
