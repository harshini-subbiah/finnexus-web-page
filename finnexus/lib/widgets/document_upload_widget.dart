import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class DocumentUploadWidget extends StatelessWidget {
  final Map<String, PlatformFile?> files;
  final Function(String docType, PlatformFile file)
      onFileSelected;

  const DocumentUploadWidget({
    super.key,
    required this.files,
    required this.onFileSelected,
  });

  Future<void> _pickFile(
      BuildContext context, String docType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null) {
      final file = result.files.first;
      if (file.size > 500 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'File is large. Use files under 500KB for best results.'),
              backgroundColor: Color(0xFFFFB347),
            ),
          );
        }
      }
      onFileSelected(docType, file);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final uploaded =
        files.values.where((f) => f != null).length;
    final total = files.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...files.keys.map((docType) {
          final file = files[docType];
          return GestureDetector(
            onTap: () => _pickFile(context, docType),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: file != null
                    ? const Color(0xFF1A3A2A)
                    : const Color(0xFF0D0D1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: file != null
                      ? Colors.greenAccent
                      : const Color(0xFF2D2D4E),
                ),
              ),
              child: Row(children: [
                Icon(
                  file != null
                      ? Icons.check_circle
                      : Icons.upload_file_rounded,
                  color: file != null
                      ? Colors.greenAccent
                      : Colors.white38,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text(docType,
                        style: TextStyle(
                            color: file != null
                                ? Colors.greenAccent
                                : Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 13)),
                    if (file != null)
                      Text(
                          '${file.name}  •  ${_formatSize(file.size)}',
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11))
                    else
                      const Text(
                          'Tap to upload (PDF, JPG, PNG — max 500KB)',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11)),
                  ]),
                ),
                if (file != null)
                  const Icon(Icons.edit_rounded,
                      color: Colors.white38, size: 14),
              ]),
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(children: [
          Text('$uploaded of $total uploaded',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12)),
          const SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: total > 0 ? uploaded / total : 0,
              backgroundColor: const Color(0xFF2D2D4E),
              color: uploaded == total
                  ? Colors.greenAccent
                  : const Color(0xFF6C63FF),
            ),
          ),
        ]),
      ],
    );
  }
}