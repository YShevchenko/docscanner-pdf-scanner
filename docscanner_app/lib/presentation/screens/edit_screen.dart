import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/services/filter_service.dart';
import '../../core/theme.dart';
import '../providers/document_provider.dart';
import 'camera_screen.dart';

class EditScreen extends StatefulWidget {
  final List<String> imagePaths;
  final String? documentId; // set when adding to existing document

  const EditScreen({
    super.key,
    required this.imagePaths,
    this.documentId,
  });

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late List<_PageData> _pages;
  int _currentIndex = 0;
  bool _isSaving = false;
  final _pageController = PageController();
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pages = widget.imagePaths.map((p) => _PageData(originalPath: p)).toList();
    final now = DateTime.now();
    _titleController.text =
        'Scan ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  _PageData get _currentPage => _pages[_currentIndex];

  Future<void> _applyFilter(FilterType filter) async {
    final page = _currentPage;
    if (page.activeFilter == filter) return;

    setState(() => _pages[_currentIndex] = page.copyWith(isLoading: true));

    Uint8List? filtered;
    if (filter == FilterType.original) {
      filtered = null;
    } else {
      filtered =
          await FilterService.applyFilter(page.originalPath, filter);
    }

    setState(() {
      _pages[_currentIndex] = page.copyWith(
        activeFilter: filter,
        filteredBytes: filtered,
        isLoading: false,
      );
    });
  }

  Future<void> _rotatePage() async {
    final page = _currentPage;
    // Increment rotation by 90
    final newRotation = (page.rotationDegrees + 90) % 360;
    setState(() {
      _pages[_currentIndex] = page.copyWith(rotationDegrees: newRotation);
    });
  }

  void _deletePage(int index) {
    if (_pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot delete the only page.')),
      );
      return;
    }
    setState(() {
      _pages.removeAt(index);
      if (_currentIndex >= _pages.length) {
        _currentIndex = _pages.length - 1;
      }
    });
  }

  Future<void> _addMorePages() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    // CameraScreen saves directly if documentId provided;
    // here we just add to in-memory pages if we get paths from a scan
    // For simplicity, we trigger a fresh scan flow
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final finalPaths = <String>[];
      final tempDir = await getTemporaryDirectory();

      for (int i = 0; i < _pages.length; i++) {
        final page = _pages[i];
        final hasFilter = page.filteredBytes != null;
        final hasRotation = page.rotationDegrees != 0;

        if (!hasFilter && !hasRotation) {
          // No edits — use original file as-is
          finalPaths.add(page.originalPath);
          continue;
        }

        // Start from filtered bytes if a filter was applied, otherwise
        // read the original file
        Uint8List sourceBytes = hasFilter
            ? page.filteredBytes!
            : await File(page.originalPath).readAsBytes();

        // Apply rotation if needed
        if (hasRotation) {
          img.Image? decoded = img.decodeImage(sourceBytes);
          if (decoded != null) {
            decoded = img.copyRotate(decoded, angle: page.rotationDegrees);
            sourceBytes =
                Uint8List.fromList(img.encodeJpg(decoded, quality: 90));
          }
        }

        // Write edited image to a temp file for the provider to pick up
        final tempPath = path_pkg.join(
            tempDir.path, 'edited_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await File(tempPath).writeAsBytes(sourceBytes);
        finalPaths.add(tempPath);
      }

      final provider = context.read<DocumentProvider>();

      if (widget.documentId != null) {
        await provider.addPagesToDocument(widget.documentId!, finalPaths);
      } else {
        await provider.saveScannedPages(
          finalPaths,
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            border: InputBorder.none,
            filled: false,
            hintText: 'Document title',
            hintStyle: TextStyle(color: Colors.white60),
          ),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Main page viewer
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Stack(
                  children: [
                    Center(
                      child: page.isLoading
                          ? const CircularProgressIndicator()
                          : RotatedBox(
                              quarterTurns: page.rotationDegrees ~/ 90,
                              child: page.filteredBytes != null
                                  ? Image.memory(page.filteredBytes!,
                                      fit: BoxFit.contain)
                                  : Image.file(
                                      File(page.originalPath),
                                      fit: BoxFit.contain,
                                    ),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white),
                        style: IconButton.styleFrom(
                            backgroundColor: Colors.black54),
                        onPressed: () => _deletePage(index),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Filter bar
          _FilterBar(
            currentFilter: _currentPage.activeFilter,
            onFilterSelected: _applyFilter,
          ),

          // Bottom toolbar
          Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolButton(
                  icon: Icons.rotate_90_degrees_cw,
                  label: 'Rotate',
                  onTap: _rotatePage,
                ),
                _ToolButton(
                  icon: Icons.add_photo_alternate_outlined,
                  label: 'Add Page',
                  onTap: _addMorePages,
                ),
                Text(
                  '${_currentIndex + 1} / ${_pages.length}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Page strip
          if (_pages.length > 1)
            Container(
              height: 80,
              color: Colors.grey.shade900,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: _pages.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _pages.removeAt(oldIndex);
                    _pages.insert(newIndex, item);
                    _currentIndex = newIndex;
                  });
                  _pageController.jumpToPage(_currentIndex);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return GestureDetector(
                    key: ValueKey(page.originalPath + index.toString()),
                    onTap: () {
                      _pageController.animateToPage(index,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut);
                      setState(() => _currentIndex = index);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 50,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _currentIndex == index
                              ? AppColors.accent
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: page.filteredBytes != null
                            ? Image.memory(page.filteredBytes!,
                                fit: BoxFit.cover)
                            : Image.file(File(page.originalPath),
                                fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final FilterType currentFilter;
  final ValueChanged<FilterType> onFilterSelected;

  const _FilterBar(
      {required this.currentFilter, required this.onFilterSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.grey.shade100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: FilterType.values.map((filter) {
          final isSelected = filter == currentFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(FilterService.filterLabel(filter)),
              selected: isSelected,
              onSelected: (_) => onFilterSelected(filter),
              selectedColor: AppColors.accent,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  final String originalPath;
  final FilterType activeFilter;
  final Uint8List? filteredBytes;
  final int rotationDegrees;
  final bool isLoading;

  _PageData({
    required this.originalPath,
    this.activeFilter = FilterType.original,
    this.filteredBytes,
    this.rotationDegrees = 0,
    this.isLoading = false,
  });

  _PageData copyWith({
    String? originalPath,
    FilterType? activeFilter,
    Uint8List? filteredBytes,
    int? rotationDegrees,
    bool? isLoading,
    bool clearFiltered = false,
  }) {
    return _PageData(
      originalPath: originalPath ?? this.originalPath,
      activeFilter: activeFilter ?? this.activeFilter,
      filteredBytes:
          clearFiltered ? null : (filteredBytes ?? this.filteredBytes),
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
