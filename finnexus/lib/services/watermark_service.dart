// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

class WatermarkService {
  static Future<Uint8List> watermarkImage(
    Uint8List bytes,
    String extension,
    String watermarkText,
  ) async {
    if (extension.toLowerCase() == 'pdf') {
      return bytes;
    }

    try {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final img = html.ImageElement(src: url);
      await img.onLoad.first
          .timeout(const Duration(seconds: 5));

      final w =
          img.naturalWidth > 0 ? img.naturalWidth : 800;
      final h =
          img.naturalHeight > 0 ? img.naturalHeight : 600;

      final canvas =
          html.CanvasElement(width: w, height: h);
      final ctx = canvas.context2D;

      ctx.drawImage(img, 0, 0);

      final fontSize =
          (w * 0.045).clamp(14.0, 52.0).toInt();
      ctx.save();
      ctx.globalAlpha = 0.22;
      ctx.fillStyle = '#7B6BFF';
      ctx.font = 'bold ${fontSize}px Arial';
      ctx.textAlign = 'center';

      ctx.translate(w / 2, h / 2);
      ctx.rotate(-0.42);

      final spacingX = w * 0.55;
      final spacingY = fontSize * 3.2;
      final cols = (w / spacingX * 2).ceil() + 1;
      final rows = (h / spacingY * 2).ceil() + 1;

      for (int r = -rows; r <= rows; r++) {
        for (int c = -cols; c <= cols; c++) {
          ctx.fillText(
              watermarkText, c * spacingX, r * spacingY);
        }
      }

      ctx.restore();
      html.Url.revokeObjectUrl(url);

      final resultBlob =
          await canvas.toBlob('image/png');
      final reader = html.FileReader();
      reader.readAsArrayBuffer(resultBlob);
      await reader.onLoad.first
          .timeout(const Duration(seconds: 5));

      // dart:typed_data ByteBuffer — NOT html.ByteBuffer
      final result = reader.result;
      if (result is ByteBuffer) {
        return result.asUint8List();
      }
      return bytes;
    } catch (_) {
      return bytes;
    }
  }

  static String buildWatermarkText(
      String customerId, String businessName) {
    final date =
        DateTime.now().toIso8601String().split('T')[0];
    return 'FinNexus • $customerId • $date';
  }
}