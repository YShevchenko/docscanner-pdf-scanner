import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';
import '../widgets/document_card.dart';
import '../widgets/filter_chip_bar.dart';
import '../../core/models/document.dart';
import '../../core/theme.dart';
import 'camera_screen.dart';
import 'document_detail_screen.dart';
import 'settings_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isGrid = true;
  bool _searchActive = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final Set<String> _selectedTags = {};
  List<String> _allTags = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DocumentProvider>();
      provider.loadAll().then((_) => _refreshTags());
    });
  }

  Future<void> _refreshTags() async {
    final tags = await context.read<DocumentProvider>().getAllTags();
    if (mounted) {
      setState(() {
        _allTags = tags.map((t) => t.name).toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<DocumentProvider>().search(query);
  }

  Future<void> _openCamera() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (result == true && mounted) {
      await context.read<DocumentProvider>().loadAll();
      _refreshTags();
    }
  }

  Future<void> _openDocument(Document doc) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => DocumentDetailScreen(document: doc)),
    );
    if (mounted) {
      await context.read<DocumentProvider>().loadAll();
    }
  }

  List<Document> _applyTagFilter(List<Document> docs) {
    if (_selectedTags.isEmpty) return docs;
    return docs
        .where((d) => _selectedTags.any((t) => d.tags.contains(t)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searchActive
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search documents...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text('DocScan'),
        actions: [
          if (!_searchActive) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() => _searchActive = true);
              },
            ),
            PopupMenuButton<SortOrder>(
              icon: const Icon(Icons.sort),
              onSelected: (order) {
                context.read<DocumentProvider>().setSortOrder(order);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: SortOrder.date,
                  child: Text('Sort by Date'),
                ),
                const PopupMenuItem(
                  value: SortOrder.name,
                  child: Text('Sort by Name'),
                ),
              ],
            ),
            IconButton(
              icon: Icon(_isGrid ? Icons.list : Icons.grid_view),
              onPressed: () => setState(() => _isGrid = !_isGrid),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _searchActive = false;
                  _searchController.clear();
                });
                context.read<DocumentProvider>().search('');
              },
            ),
        ],
      ),
      body: Consumer<DocumentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = provider.documents;
          final docs = _applyTagFilter(allDocs);

          return Column(
            children: [
              if (_allTags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilterChipBar(
                    tags: _allTags,
                    selectedTags: _selectedTags,
                    onTagToggled: (tag) {
                      setState(() {
                        if (_selectedTags.contains(tag)) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                  ),
                ),
              Expanded(
                child: docs.isEmpty
                    ? _EmptyState(onCamera: _openCamera)
                    : _isGrid
                        ? _GridView(
                            docs: docs,
                            onTap: _openDocument,
                            onDelete: (doc) => _confirmDelete(context, doc),
                          )
                        : _ListView(
                            docs: docs,
                            onTap: _openDocument,
                            onDelete: (doc) => _confirmDelete(context, doc),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCamera,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Document doc) async {
    final provider = context.read<DocumentProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${doc.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await provider.deleteDocument(doc.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCamera;
  const _EmptyState({required this.onCamera});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.document_scanner_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'No Documents Yet',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the camera to scan your first document.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan Document'),
          ),
        ],
      ),
    );
  }
}

class _GridView extends StatelessWidget {
  final List<Document> docs;
  final ValueChanged<Document> onTap;
  final ValueChanged<Document> onDelete;

  const _GridView(
      {required this.docs, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return DocumentCard(
          document: doc,
          isGrid: true,
          onTap: () => onTap(doc),
          onDelete: () => onDelete(doc),
        );
      },
    );
  }
}

class _ListView extends StatelessWidget {
  final List<Document> docs;
  final ValueChanged<Document> onTap;
  final ValueChanged<Document> onDelete;

  const _ListView(
      {required this.docs, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return DocumentCard(
          document: doc,
          isGrid: false,
          onTap: () => onTap(doc),
          onDelete: () => onDelete(doc),
        );
      },
    );
  }
}
