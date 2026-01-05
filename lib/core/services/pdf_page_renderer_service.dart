import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf_image_renderer/pdf_image_renderer.dart';

/// Service to render PDF pages as images for consistent field overlay
class PdfPageRendererService {
  PdfImageRenderer? _pdf;
  String? _currentPath;
  int _pageCount = 0;

  /// Open a PDF file for rendering
  Future<int> openPdf(String filePath) async {
    // Close any previously opened PDF
    if (_pdf != null) {
      await closePdf();
    }

    if (filePath.toLowerCase().endsWith('.doc') || filePath.toLowerCase().endsWith('.docx')) {
      return 0;
    }

    _pdf = PdfImageRenderer(path: filePath);
    await _pdf!.open();
    _pageCount = await _pdf!.getPageCount();
    _currentPath = filePath;

    return _pageCount;
  }

  /// Get the number of pages in the PDF
  int get pageCount => _pageCount;

  /// Check if PDF is currently open
  bool get isOpen => _pdf != null;

  Future<Uint8List?> renderPage({required int pageIndex, double scale = 2.0}) async {
    if (_pdf == null) {
      throw Exception('PDF not opened. Call openPdf() first.');
    }

    if (pageIndex < 0 || pageIndex >= _pageCount) {
      throw Exception('Invalid page index: $pageIndex. PDF has $_pageCount pages.');
    }

    try {
      // Open the page
      await _pdf!.openPage(pageIndex: pageIndex);

      // Get page size
      final size = await _pdf!.getPageSize(pageIndex: pageIndex);

      final imageBytes = await _pdf!.renderPage(
        pageIndex: pageIndex,
        x: 0,
        y: 0,
        width: size.width.toInt(),
        height: size.height.toInt(),
        scale: scale,
        background: Colors.white,
      );

      // Close the page to free memory
      await _pdf!.closePage(pageIndex: pageIndex);

      return imageBytes;
    } catch (e) {
      // Ensure page is closed even on error
      try {
        await _pdf!.closePage(pageIndex: pageIndex);
      } catch (_) {}
      rethrow;
    }
  }

  /// Get page dimensions (useful for aspect ratio calculations)
  Future<PdfImageRendererPageSize?> getPageSize(int pageIndex) async {
    if (_pdf == null) return null;

    try {
      await _pdf!.openPage(pageIndex: pageIndex);
      final size = await _pdf!.getPageSize(pageIndex: pageIndex);
      await _pdf!.closePage(pageIndex: pageIndex);
      return size;
    } catch (e) {
      return null;
    }
  }

  /// Close the PDF and release resources
  Future<void> closePdf() async {
    if (_pdf != null) {
      try {
        _pdf!.close();
      } catch (_) {}
      _pdf = null;
      _currentPath = null;
      _pageCount = 0;
    }
  }

  /// Get current file path
  String? get currentPath => _currentPath;
}
