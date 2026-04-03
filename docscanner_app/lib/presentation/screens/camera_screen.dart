import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:torch_light/torch_light.dart';
import 'edit_screen.dart';
import 'manual_crop_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isProcessing = false;
  bool _torchEnabled = false;
  bool _torchAvailable = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _checkTorchAvailability();
  }

  Future<void> _checkTorchAvailability() async {
    try {
      final available = await TorchLight.isTorchAvailable();
      if (mounted) setState(() => _torchAvailable = available);
    } catch (_) {
      // Device has no torch — hide the button silently
    }
  }

  Future<void> _toggleTorch() async {
    try {
      if (_torchEnabled) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      if (mounted) setState(() => _torchEnabled = !_torchEnabled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Torch error: $e')),
        );
      }
    }
  }

  /// Ensures the torch is off after the native scanner returns.
  Future<void> _ensureTorchOff() async {
    if (_torchEnabled) {
      try {
        await TorchLight.disableTorch();
      } catch (_) {}
      if (mounted) setState(() => _torchEnabled = false);
    }
  }

  @override
  void dispose() {
    // Ensure torch is turned off when screen is disposed
    if (_torchEnabled) {
      TorchLight.disableTorch().catchError((_) {});
    }
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _scanWithCamera() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 20,
        isGalleryImportAllowed: false,
      );

      // Native scanner has taken control — ensure torch is off now
      await _ensureTorchOff();

      if (pictures == null || pictures.isEmpty) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      if (mounted) {
        setState(() => _isProcessing = false);
        // Route each image through ManualCropScreen before EditScreen
        final navigator = Navigator.of(context);
        final croppedPaths = <String>[];
        for (final path in pictures) {
          if (!mounted) break;
          final cropped = await navigator.push<String>(
            MaterialPageRoute(
              builder: (_) => ManualCropScreen(imagePath: path),
            ),
          );
          if (cropped == null) {
            // User cancelled crop for this image — use the original
            croppedPaths.add(path);
          } else {
            croppedPaths.add(cropped);
          }
        }

        if (!mounted) return;
        final saved = await navigator.push<bool>(
          MaterialPageRoute(
            builder: (_) => EditScreen(imagePaths: croppedPaths),
          ),
        );
        if (saved == true && mounted) {
          navigator.pop(true);
        }
      }
    } catch (e) {
      await _ensureTorchOff();
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _importFromGallery() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final picked = await ImagePicker().pickMultiImage();

      if (picked.isEmpty) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      if (mounted) {
        setState(() => _isProcessing = false);
        // Route each image through ManualCropScreen before EditScreen
        final navigator = Navigator.of(context);
        final croppedPaths = <String>[];
        for (final xFile in picked) {
          if (!mounted) break;
          final cropped = await navigator.push<String>(
            MaterialPageRoute(
              builder: (_) => ManualCropScreen(imagePath: xFile.path),
            ),
          );
          if (cropped == null) {
            // User cancelled crop — use the original image
            croppedPaths.add(xFile.path);
          } else {
            croppedPaths.add(cropped);
          }
        }

        if (!mounted) return;
        final saved = await navigator.push<bool>(
          MaterialPageRoute(
            builder: (_) => EditScreen(imagePaths: croppedPaths),
          ),
        );
        if (saved == true && mounted) {
          navigator.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Document'),
        actions: [
          if (_torchAvailable)
            IconButton(
              tooltip: _torchEnabled ? 'Turn off flash' : 'Turn on flash',
              icon: Icon(
                _torchEnabled ? Icons.flashlight_on : Icons.flashlight_off,
              ),
              onPressed: _toggleTorch,
            ),
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.document_scanner_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _scanWithCamera,
                    icon: const Icon(Icons.camera_alt, size: 22),
                    label: const Text('Scan with Camera',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _importFromGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 22),
                    label: const Text('Import from Gallery',
                        style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Edge detection and perspective correction\nhappen automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
    );
  }
}
