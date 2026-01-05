import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/entities/field_entity.dart';
import '../../shared/entities/document_entity.dart';
import 'package:flutter/services.dart' show rootBundle;

class PdfGeneratorService {
  /// Generate a signed PDF by overlaying field values onto the original document
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
      final x = field.xPercent * pageSize.width;
      final y = field.yPercent * pageSize.height;
      final width = field.widthPercent * pageSize.width;
      final height = field.heightPercent * pageSize.height;

      final bounds = Rect.fromLTWH(x, y, width, height);

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

  // Text draw Box
  void _drawText(PdfPage page, String text, Rect bounds) {
    final fontSize = (bounds.height * 0.55).clamp(8.0, 20.0);
    final font = PdfStandardFont(PdfFontFamily.helvetica, fontSize, style: PdfFontStyle.bold);
    final brush = PdfSolidBrush(PdfColor(33, 33, 33));

    page.graphics.drawString(
      text,
      font,
      brush: brush,
      bounds: bounds,
      format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
    );
  }

  // Signature text Box
  void _drawSignatureText(PdfPage page, String text, Rect bounds) async {
    final ByteData fontData = await rootBundle.load('assets/fonts/DancingScript-Regular.ttf');
    final Uint8List fontBytes = fontData.buffer.asUint8List();

    // Create PdfTrueTypeFont with custom font
    final PdfTrueTypeFont font = PdfTrueTypeFont(fontBytes, 14);

    // Define brush color (Colors.black87 equivalent)
    final PdfBrush brush = PdfSolidBrush(PdfColor(33, 33, 33));

    // Draw text on PDF
    page.graphics.drawString(
      text,
      font,
      brush: brush,
      bounds: bounds,
      format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
    );
  }

  // Image signature
  void _drawSignature(PdfPage page, dynamic value, Rect bounds) {
    if (value is Uint8List) {
      try {
        final image = PdfBitmap(value);
        page.graphics.drawImage(image, bounds);
      } catch (e) {
        _drawSignatureText(page, 'Signature', bounds);
      }
    } else if (value is String && value.isNotEmpty) {
      _drawSignatureText(page, value, bounds);
    }
  }

  // Checkbox draw
  void _drawCheckbox(PdfPage page, bool isChecked, Rect bounds) {
    final checkBrush = PdfSolidBrush(PdfColor(255, 152, 0));
    //final borderPen = PdfPen(PdfColor(255, 152, 0), width: 1.5);

    // Dynamic font size for checkbox symbol
    final fontSize = (bounds.height * 0.7).clamp(10.0, 24.0);
    page.graphics.drawRectangle(/*pen: borderPen,*/ bounds: bounds);

    if (isChecked) {
      final font = PdfStandardFont(PdfFontFamily.zapfDingbats, fontSize);
      page.graphics.drawString(
        '4',
        font,
        brush: checkBrush,
        bounds: bounds,
        format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
      );
    }
  }

  // Get output directory
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
