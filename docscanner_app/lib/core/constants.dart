class AppConstants {
  static const String appName = 'DocScan';
  static const String appVersion = '1.0.1';

  // Database
  static const String dbName = 'docscanner.db';
  static const int dbVersion = 1;

  // Table names
  static const String tableDocuments = 'documents';
  static const String tablePages = 'pages';
  static const String tableTags = 'tags';
  static const String tableDocumentTags = 'document_tags';
  static const String tablePagesFts = 'pages_fts';

  // Export quality presets
  static const Map<String, int> exportDpi = {
    'low': 72,
    'medium': 150,
    'high': 300,
  };

  static const String defaultExportQuality = 'medium';

  // Thumbnail size
  static const int thumbnailWidth = 200;
  static const int thumbnailHeight = 280;

  // PDF image JPEG quality (0-100)
  static const Map<String, int> jpegQuality = {
    'low': 50,
    'medium': 75,
    'high': 95,
  };
}
