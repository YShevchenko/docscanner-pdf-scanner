import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../providers/document_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _exportQuality = AppConstants.defaultExportQuality;
  String _cacheSize = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final thumbDir =
          Directory(path_pkg.join(dir.path, 'thumbnails'));
      int total = 0;
      if (thumbDir.existsSync()) {
        await for (final entity in thumbDir.list(recursive: true)) {
          if (entity is File) total += await entity.length();
        }
      }
      setState(() {
        _cacheSize =
            total > 1024 * 1024
                ? '${(total / (1024 * 1024)).toStringAsFixed(1)} MB'
                : '${(total / 1024).toStringAsFixed(0)} KB';
      });
    } catch (_) {
      setState(() => _cacheSize = 'Unknown');
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Thumbnail Cache'),
        content: const Text(
            'This will remove cached thumbnails. They will be regenerated on next view.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final thumbDir =
          Directory(path_pkg.join(dir.path, 'thumbnails'));
      if (thumbDir.existsSync()) {
        await thumbDir.delete(recursive: true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared')),
        );
        _calculateCacheSize();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'This will permanently delete ALL documents, scanned images, '
            'PDFs, and cached data. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await context.read<DocumentProvider>().clearAllData();
      if (mounted) {
        _calculateCacheSize();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Export'),
          ListTile(
            title: const Text('Default Export Quality'),
            subtitle: Text(_qualityLabel(_exportQuality)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showQualityPicker(),
          ),

          const Divider(),
          const _SectionHeader(title: 'Storage'),
          ListTile(
            title: const Text('Thumbnail Cache'),
            subtitle: Text(_cacheSize),
            trailing: TextButton(
              onPressed: _clearCache,
              child: const Text('Clear'),
            ),
          ),
          ListTile(
            title: const Text('Clear All Data'),
            subtitle: const Text(
                'Delete all documents, scans, PDFs, and cached data'),
            trailing: TextButton(
              onPressed: _clearAllData,
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Clear'),
            ),
          ),

          const Divider(),
          const _SectionHeader(title: 'About'),
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('${AppConstants.appName} ${AppConstants.appVersion}'),
          ),
          ListTile(
            title: const Text('Publisher'),
            subtitle: const Text('Heldig Lab'),
          ),
          ListTile(
            title: const Text('Privacy'),
            subtitle: const Text(
                'All data stays on your device. No backend, no tracking.'),
          ),
        ],
      ),
    );
  }

  String _qualityLabel(String quality) {
    switch (quality) {
      case 'low':
        return 'Low (smaller file)';
      case 'high':
        return 'High (best quality)';
      default:
        return 'Medium (balanced)';
    }
  }

  void _showQualityPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Export Quality',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final q in ['low', 'medium', 'high'])
              ListTile(
                title: Text(_qualityLabel(q)),
                trailing: _exportQuality == q
                    ? const Icon(Icons.check_circle, color: AppColors.accent)
                    : const Icon(Icons.circle_outlined, color: Colors.grey),
                onTap: () {
                  setState(() => _exportQuality = q);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
