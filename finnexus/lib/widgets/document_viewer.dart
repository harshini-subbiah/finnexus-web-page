// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:convert';

class DocumentViewer extends StatelessWidget {
  final Map<String, dynamic> documents;
  const DocumentViewer(
      {super.key, required this.documents});

  bool _isImage(String? ext) {
    if (ext == null) return false;
    return ['jpg', 'jpeg', 'png']
        .contains(ext.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final valid = <String, Map<String, dynamic>>{};
    for (final entry in documents.entries) {
      final val = entry.value;
      if (val != null &&
          val is Map<String, dynamic> &&
          val['data'] != null) {
        valid[entry.key] = val;
      }
    }

    if (valid.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No documents uploaded',
            style: TextStyle(
                color: Colors.white38, fontSize: 13)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: valid.entries.map((entry) {
        final label = entry.key
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isEmpty
                ? ''
                : w[0].toUpperCase() + w.substring(1))
            .join(' ');
        final doc = entry.value;
        final base64Data = doc['data'] as String;
        final extension = doc['extension'] as String?;
        final fileName =
            doc['fileName'] as String? ?? label;
        final isImg = _isImage(extension);

        return _DocTile(
          label: label,
          fileName: fileName,
          base64Data: base64Data,
          isImage: isImg,
          extension: extension ?? 'pdf',
        );
      }).toList(),
    );
  }
}

class _DocTile extends StatefulWidget {
  final String label;
  final String fileName;
  final String base64Data;
  final bool isImage;
  final String extension;

  const _DocTile({
    required this.label,
    required this.fileName,
    required this.base64Data,
    required this.isImage,
    required this.extension,
  });

  @override
  State<_DocTile> createState() => _DocTileState();
}

class _DocTileState extends State<_DocTile> {
  bool _expanded = false;

  void _openInNewTab() {
    final mimeType = widget.isImage
        ? 'image/${widget.extension.toLowerCase()}'
        : 'application/pdf';
    final bytes = base64Decode(widget.base64Data);
    // ignore: avoid_web_libraries_in_flutter
    final blob = html.Blob([bytes], mimeType);
    // ignore: avoid_web_libraries_in_flutter
    final url = html.Url.createObjectUrlFromBlob(blob);
    // ignore: avoid_web_libraries_in_flutter
    html.window.open(url, '_blank');
    Future.delayed(const Duration(seconds: 10), () {
      // ignore: avoid_web_libraries_in_flutter
      html.Url.revokeObjectUrl(url);
    });
  }

  void _download() {
    final mimeType = widget.isImage
        ? 'image/${widget.extension.toLowerCase()}'
        : 'application/pdf';
    final bytes = base64Decode(widget.base64Data);
    // ignore: avoid_web_libraries_in_flutter
    final blob = html.Blob([bytes], mimeType);
    // ignore: avoid_web_libraries_in_flutter
    final url = html.Url.createObjectUrlFromBlob(blob);
    // ignore: avoid_web_libraries_in_flutter
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', widget.fileName)
      ..click();
    // ignore: unused_local_variable
    final _ = anchor;
    // ignore: avoid_web_libraries_in_flutter
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFF2D2D4E)),
      ),
      child: Column(children: [
        // Header row
        GestureDetector(
          onTap: () =>
              setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(10),
                topRight: const Radius.circular(10),
                bottomLeft:
                    Radius.circular(_expanded ? 0 : 10),
                bottomRight:
                    Radius.circular(_expanded ? 0 : 10),
              ),
            ),
            child: Row(children: [
              Icon(
                widget.isImage
                    ? Icons.image_outlined
                    : Icons.picture_as_pdf_outlined,
                color: widget.isImage
                    ? const Color(0xFF6C63FF)
                    : Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
              TextButton.icon(
                onPressed: _openInNewTab,
                icon: const Icon(Icons.open_in_new,
                    color: Color(0xFF6C63FF), size: 15),
                label: const Text('Open',
                    style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: _download,
                icon: const Icon(Icons.download,
                    color: Colors.greenAccent, size: 15),
                label: const Text('Download',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12)),
              ),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.white38,
                size: 18,
              ),
            ]),
          ),
        ),

        // Expanded preview
        if (_expanded) ...[
          if (widget.isImage)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(widget.base64Data),
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'Could not display image',
                        style: TextStyle(
                            color: Colors.redAccent)),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.picture_as_pdf,
                    color: Colors.redAccent, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text(widget.fileName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w500)),
                    const SizedBox(height: 4),
                    const Text(
                        'Click "Open" to view in browser or "Download" to save',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11)),
                  ]),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openInNewTab,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.open_in_new,
                      color: Colors.white, size: 16),
                  label: const Text('Open in Browser',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13)),
                ),
              ]),
            ),
        ],
      ]),
    );
  }
}