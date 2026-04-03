import 'dart:typed_data';

class Document {
  final String id;
  final String title;
  final int pageCount;
  final int totalSizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  // Thumbnail bytes kept in memory for display (not persisted in model)
  final Uint8List? thumbnailBytes;

  const Document({
    required this.id,
    required this.title,
    required this.pageCount,
    required this.totalSizeBytes,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.thumbnailBytes,
  });

  Document copyWith({
    String? id,
    String? title,
    int? pageCount,
    int? totalSizeBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    Uint8List? thumbnailBytes,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      pageCount: pageCount ?? this.pageCount,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'page_count': pageCount,
      'total_size_bytes': totalSizeBytes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Document.fromMap(Map<String, dynamic> map, {List<String>? tags}) {
    return Document(
      id: map['id'] as String,
      title: map['title'] as String,
      pageCount: map['page_count'] as int,
      totalSizeBytes: map['total_size_bytes'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      tags: tags ?? [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Document && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Document(id: $id, title: $title, pageCount: $pageCount)';
}
