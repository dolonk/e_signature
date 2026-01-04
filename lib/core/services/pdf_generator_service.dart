import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/entities/field_entity.dart';
import '../../shared/entities/document_entity.dart';

/// Service to generate final signed PDF with field overlays
class PdfGeneratorService {
  /// Generate a signed PDF by overlaying field values onto the original document
  /// Returns the File path of the generated PDF
  Future<File> generateSignedPdf({required DocumentEntity document, required List<FieldEntity> fields}) async {
    // Load original PDF
    final originalFile = File(document.localFilePath);
    if (!await originalFile.exists()) {
      throw Exception('Original PDF file not found: ${document.localFilePath}');
    }

    final bytes = await originalFile.readAsBytes();
    final pdfDocument = PdfDocument(inputBytes: bytes);

    // Process each field
    for (final field in fields) {
      if (field.value == null) continue;

      // Ensure page index is valid
      final pageIndex = field.page - 1;
      if (pageIndex < 0 || pageIndex >= pdfDocument.pages.count) continue;

      final page = pdfDocument.pages[pageIndex];
      final pageSize = page.size;

      // Convert percentage coordinates to actual PDF coordinates
      // PDF coordinates are bottom-left origin, Flutter uses top-left
      // So we need to flip the Y coordinate: pdfY = pageHeight - flutterY - elementHeight
      final x = field.xPercent * pageSize.width;
      final width = field.widthPercent * pageSize.width;
      final height = field.heightPercent * pageSize.height;

      // CRITICAL: Flip Y coordinate for PDF coordinate system
      final flutterY = field.yPercent * pageSize.height;
      final pdfY = pageSize.height - flutterY - height;

      final bounds = Rect.fromLTWH(x, pdfY, width, height);

      switch (field.type) {
        case FieldType.text:
        case FieldType.date:
          _drawText(page, field.value.toString(), bounds);
          break;
        case FieldType.signature:
          _drawSignature(page, field.value, bounds);
          break;
        case FieldType.checkbox:
          _drawCheckbox(page, field.value == true, bounds);
          break;
      }
    }

    // Save to output file
    final outputDir = await _getOutputDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = document.name.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
    final outputPath = '${outputDir.path}/${sanitizedName}_signed_$timestamp.pdf';

    final outputFile = File(outputPath);
    final savedBytes = pdfDocument.saveSync();
    await outputFile.writeAsBytes(savedBytes);

    pdfDocument.dispose();

    return outputFile;
  }

  void _drawText(PdfPage page, String text, Rect bounds) {
    final font = PdfStandardFont(PdfFontFamily.helvetica, 11);
    final brush = PdfSolidBrush(PdfColor(0, 0, 0));

    page.graphics.drawString(
      text,
      font,
      brush: brush,
      bounds: bounds,
      format: PdfStringFormat(alignment: PdfTextAlignment.left, lineAlignment: PdfVerticalAlignment.middle),
    );
  }

  void _drawSignature(PdfPage page, dynamic value, Rect bounds) {
    if (value is Uint8List) {
      // Image signature (drawn or uploaded)
      try {
        final image = PdfBitmap(value);
        page.graphics.drawImage(image, bounds);
      } catch (e) {
        // Fallback to text if image fails
        _drawSignatureText(page, 'Signature', bounds);
      }
    } else if (value is String && value.isNotEmpty) {
      // Typed signature - use italic/cursive style
      _drawSignatureText(page, value, bounds);
    }
  }

  void _drawSignatureText(PdfPage page, String text, Rect bounds) {
    // Use italic style to simulate handwriting
    final font = PdfStandardFont(PdfFontFamily.timesRoman, 16, style: PdfFontStyle.italic);
    final brush = PdfSolidBrush(PdfColor(0, 0, 139)); // Dark blue for signature

    page.graphics.drawString(
      text,
      font,
      brush: brush,
      bounds: bounds,
      format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
    );
  }

  void _drawCheckbox(PdfPage page, bool isChecked, Rect bounds) {
    final font = PdfStandardFont(PdfFontFamily.zapfDingbats, 14);
    final brush = PdfSolidBrush(PdfColor(0, 128, 0)); // Green for checked

    // Zapf Dingbats: ✓ = char 52, ✗ = char 56
    final symbol = isChecked ? '4' : ''; // '4' in Zapf Dingbats is checkmark

    if (isChecked) {
      page.graphics.drawString(
        symbol,
        font,
        brush: brush,
        bounds: bounds,
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );
    }

    // Draw checkbox border
    final pen = PdfPen(PdfColor(100, 100, 100), width: 1);
    page.graphics.drawRectangle(pen: pen, bounds: bounds);
  }

  Future<Directory> _getOutputDirectory() async {
    Directory? outputDir;

    if (Platform.isAndroid) {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final pathParts = extDir.path.split('/');
        final downloadPath = '/${pathParts[1]}/${pathParts[2]}/${pathParts[3]}/Download';
        outputDir = Directory(downloadPath);
      }
    }

    outputDir ??= await getApplicationDocumentsDirectory();

    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    return outputDir;
  }
}
