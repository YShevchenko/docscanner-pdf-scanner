/// Represents a single scanned page within a document.
/// Named ScanPage to avoid naming conflict with pdf.Page.
class ScanPage {
  final String id;
  final String documentId;
  final int pageNumber;
  final String imagePath;
  final String? thumbnailPath;
  final String? extractedText;
  final DateTime createdAt;

  const ScanPage({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.imagePath,
    this.thumbnailPath,
    this.extractedText,
    required this.createdAt,
  });

  ScanPage copyWith({
    String? id,
    String? documentId,
    int? pageNumber,
    String? imagePath,
    String? thumbnailPath,
    String? extractedText,
    DateTime? createdAt,
  }) {
    return ScanPage(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      imagePath: imagePath ?? this.imagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      extractedText: extractedText ?? this.extractedText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'page_number': pageNumber,
      'image_path': imagePath,
      'thumbnail_path': thumbnailPath,
      'extracted_text': extractedText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ScanPage.fromMap(Map<String, dynamic> map) {
    return ScanPage(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      pageNumber: map['page_number'] as int,
      imagePath: map['image_path'] as String,
      thumbnailPath: map['thumbnail_path'] as String?,
      extractedText: map['extracted_text'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanPage && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ScanPage(id: $id, documentId: $documentId, pageNumber: $pageNumber)';
}
