import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OcrSheet extends StatelessWidget {
  final String? text;

  const OcrSheet({super.key, required this.text});

  static Future<void> show(BuildContext context, String? text) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => OcrSheet(text: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasText = text != null && text!.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  const Text(
                    'Extracted Text',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (hasText)
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: text!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Text copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: hasText
                  ? SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: SelectableText(
                        text!,
                        style: const TextStyle(
                            fontSize: 14, height: 1.6),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.text_fields_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No text recognized',
                            style: TextStyle(
                                fontSize: 15, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'OCR could not extract text from this page.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
