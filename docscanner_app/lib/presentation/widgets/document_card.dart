import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/document.dart';
import '../../core/theme.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final bool isGrid;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const DocumentCard({
    super.key,
    required this.document,
    required this.isGrid,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return _GridCard(
          document: document, onTap: onTap, onDelete: onDelete);
    }
    return _ListCard(document: document, onTap: onTap, onDelete: onDelete);
  }
}

class _GridCard extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GridCard({
    required this.document,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ThumbnailWidget(document: document),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
              child: Text(
                document.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Row(
                children: [
                  Text(
                    '${document.pageCount} page${document.pageCount != 1 ? 's' : ''}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM d').format(document.createdAt),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ListCard({
    required this.document,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(document.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: SizedBox(
            width: 44,
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: _ThumbnailWidget(document: document, small: true),
            ),
          ),
          title: Text(
            document.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${document.pageCount} page${document.pageCount != 1 ? 's' : ''} · ${DateFormat('MMM d, y').format(document.createdAt)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () {
              // Show options
            },
          ),
        ),
      ),
    );
  }
}

class _ThumbnailWidget extends StatelessWidget {
  final Document document;
  final bool small;

  const _ThumbnailWidget({required this.document, this.small = false});

  @override
  Widget build(BuildContext context) {
    // Try thumbnail bytes first (loaded in memory)
    if (document.thumbnailBytes != null) {
      return Image.memory(
        document.thumbnailBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Placeholder
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.description_outlined,
          size: small ? 24 : 48,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
