import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/entities/field_entity.dart';
import '../../../../shared/entities/document_entity.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/pdf_generator_service.dart';
import '../../../../core/services/pdf_page_renderer_service.dart';
import '../../domain/repositories/editor_repository.dart';

/// Editor mode enum
enum EditorMode { edit, sign }

/// State for document editor
class EditorState {
  final DocumentEntity? document;
  final List<FieldEntity> fields;
  final FieldEntity? selectedField;
  final int currentPage;
  final int totalPages;
  final Map<int, Uint8List> pageImages;
  final double pdfPageWidth;
  final double pdfPageHeight;
  final EditorMode mode;
  final bool isLoading;
  final bool isRenderingPage;
  final bool isSaving;
  final bool isPublished;
  final Failure? failure;
  final String? successMessage;

  const EditorState({
    this.document,
    this.fields = const [],
    this.selectedField,
    this.currentPage = 1,
    this.totalPages = 1,
    this.pageImages = const {},
    this.pdfPageWidth = 0,
    this.pdfPageHeight = 0,
    this.mode = EditorMode.edit,
    this.isLoading = false,
    this.isRenderingPage = false,
    this.isSaving = false,
    this.isPublished = false,
    this.failure,
    this.successMessage,
  });

  /// Check if editing is allowed
  bool get canEdit => !isPublished && mode == EditorMode.edit;

  EditorState copyWith({
    DocumentEntity? document,
    List<FieldEntity>? fields,
    FieldEntity? selectedField,
    bool clearSelection = false,
    int? currentPage,
    int? totalPages,
    Map<int, Uint8List>? pageImages,
    double? pdfPageWidth,
    double? pdfPageHeight,
    EditorMode? mode,
    bool? isLoading,
    bool? isRenderingPage,
    bool? isSaving,
    bool? isPublished,
    Failure? failure,
    String? successMessage,
  }) {
    return EditorState(
      document: document ?? this.document,
      fields: fields ?? this.fields,
      selectedField: clearSelection ? null : (selectedField ?? this.selectedField),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      pageImages: pageImages ?? this.pageImages,
      pdfPageWidth: pdfPageWidth ?? this.pdfPageWidth,
      pdfPageHeight: pdfPageHeight ?? this.pdfPageHeight,
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
      isRenderingPage: isRenderingPage ?? this.isRenderingPage,
      isSaving: isSaving ?? this.isSaving,
      isPublished: isPublished ?? this.isPublished,
      failure: failure,
      successMessage: successMessage,
    );
  }

  /// Get current page image
  Uint8List? get currentPageImage => pageImages[currentPage];

  factory EditorState.initial() => const EditorState();
  factory EditorState.loading() => const EditorState(isLoading: true);
}

/// ViewModel for document editor
class EditorViewModel extends StateNotifier<EditorState> {
  final EditorRepository? _repository;
  final PdfPageRendererService _pdfRenderer = PdfPageRendererService();

  EditorViewModel([this._repository]) : super(EditorState.initial());

  /// Initialize with document and render the first page
  Future<void> initDocumentWithRendering(DocumentEntity document) async {
    state = state.copyWith(document: document, isLoading: true);

    try {
      // Open PDF and get page count
      final totalPages = await _pdfRenderer.openPdf(document.localFilePath);
      state = state.copyWith(totalPages: totalPages, currentPage: 1);

      // Load saved fields if repository available
      if (_repository != null) {
        await _loadSavedFields(document.id);
      }

      // Render first page
      await renderCurrentPage();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, failure: FileFailure('Failed to open PDF: $e'));
    }
  }

  /// Render the current page as image
  Future<void> renderCurrentPage() async {
    final pageIndex = state.currentPage - 1; // 0-based index

    // Check if already rendered
    if (state.pageImages.containsKey(state.currentPage)) {
      return;
    }

    state = state.copyWith(isRenderingPage: true);

    try {
      // Get actual PDF page size for accurate field positioning
      final pageSize = await _pdfRenderer.getPageSize(pageIndex);

      final imageBytes = await _pdfRenderer.renderPage(pageIndex: pageIndex, scale: 2.0);

      if (imageBytes != null) {
        final updatedImages = Map<int, Uint8List>.from(state.pageImages);
        updatedImages[state.currentPage] = imageBytes;
        state = state.copyWith(
          pageImages: updatedImages,
          pdfPageWidth: pageSize?.width.toDouble() ?? 0,
          pdfPageHeight: pageSize?.height.toDouble() ?? 0,
          isRenderingPage: false,
        );
      } else {
        state = state.copyWith(isRenderingPage: false, failure: const FileFailure('Failed to render page'));
      }
    } catch (e) {
      state = state.copyWith(isRenderingPage: false, failure: FileFailure('Error rendering page: $e'));
    }
  }

  /// Legacy init method (for backward compatibility)
  void initDocument(DocumentEntity document, int totalPages) {
    state = state.copyWith(document: document, totalPages: totalPages, isLoading: false);
    if (_repository != null) {
      _loadSavedFields(document.id);
    }
  }

  /// Clean up resources
  @override
  void dispose() {
    _pdfRenderer.closePdf();
    super.dispose();
  }

  /// Load saved fields from repository
  Future<void> _loadSavedFields(int documentId) async {
    if (_repository == null) return;

    final result = await _repository.loadFieldConfig(documentId);
    result.fold((failure) => state = state.copyWith(failure: failure), (fields) {
      if (fields.isNotEmpty) {
        state = state.copyWith(fields: fields);
      }
    });
  }

  /// Save fields to repository
  Future<void> saveFields() async {
    if (_repository == null || state.document == null) {
      state = state.copyWith(failure: const FileFailure('Cannot save: repository not available'));
      return;
    }

    state = state.copyWith(isSaving: true);

    final result = await _repository.saveFieldConfig(documentId: state.document!.id, fields: state.fields);

    result.fold(
      (failure) => state = state.copyWith(isSaving: false, failure: failure),
      (configPath) => state = state.copyWith(isSaving: false),
    );
  }

  /// Publish document - locks fields permanently
  Future<bool> publishDocument() async {
    if (state.fields.isEmpty) {
      state = state.copyWith(failure: const FileFailure('Add at least one field before publishing'));
      return false;
    }

    // Save fields first
    await saveFields();

    if (state.failure != null) {
      return false;
    }

    // Mark as published and enter sign mode
    state = state.copyWith(isPublished: true, mode: EditorMode.sign, clearSelection: true);

    return true;
  }

  /// Add a new field at position (only if not published)
  void addField(FieldType type, double xPercent, double yPercent) {
    if (state.isPublished) return;

    final newField = FieldEntity.create(type: type, page: state.currentPage, xPercent: xPercent, yPercent: yPercent);
    state = state.copyWith(fields: [...state.fields, newField], selectedField: newField);
  }

  /// Update field position (only if not published)
  void updateFieldPosition(String fieldId, double xPercent, double yPercent) {
    if (state.isPublished) return;

    final updatedFields = state.fields.map((field) {
      if (field.id == fieldId) {
        return field.copyWith(xPercent: xPercent, yPercent: yPercent);
      }
      return field;
    }).toList();

    FieldEntity? updatedSelected;
    if (state.selectedField?.id == fieldId) {
      updatedSelected = updatedFields.firstWhere((f) => f.id == fieldId);
    }

    state = state.copyWith(fields: updatedFields, selectedField: updatedSelected);
  }

  /// Update field size (only if not published)
  void updateFieldSize(String fieldId, double widthPercent, double heightPercent) {
    if (state.isPublished) return;

    final updatedFields = state.fields.map((field) {
      if (field.id == fieldId) {
        return field.copyWith(widthPercent: widthPercent, heightPercent: heightPercent);
      }
      return field;
    }).toList();

    state = state.copyWith(fields: updatedFields);
  }

  /// Select a field
  void selectField(String fieldId) {
    final field = state.fields.firstWhere((f) => f.id == fieldId, orElse: () => state.fields.first);
    state = state.copyWith(selectedField: field);
  }

  /// Clear selection
  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }

  /// Delete a field (only if not published)
  void deleteField(String fieldId) {
    if (state.isPublished) return;

    final updatedFields = state.fields.where((f) => f.id != fieldId).toList();
    state = state.copyWith(fields: updatedFields, clearSelection: state.selectedField?.id == fieldId);
  }

  /// Delete selected field
  void deleteSelectedField() {
    if (state.selectedField != null) {
      deleteField(state.selectedField!.id);
    }
  }

  /// Navigate to page and render it
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= state.totalPages) {
      state = state.copyWith(currentPage: page, clearSelection: true);
      await renderCurrentPage();
    }
  }

  Future<void> nextPage() => goToPage(state.currentPage + 1);
  Future<void> previousPage() => goToPage(state.currentPage - 1);
  Future<void> firstPage() => goToPage(1);
  Future<void> lastPage() => goToPage(state.totalPages);

  /// Get fields for current page
  List<FieldEntity> get currentPageFields {
    return state.fields.where((f) => f.page == state.currentPage).toList();
  }

  /// Switch to sign mode (only if not published)
  void enterSignMode() {
    state = state.copyWith(mode: EditorMode.sign, clearSelection: true);
  }

  /// Switch back to edit mode (only if not published)
  void enterEditMode() {
    if (state.isPublished) return; // Cannot edit after publishing
    state = state.copyWith(mode: EditorMode.edit);
  }

  /// Update field value (for signing mode)
  void updateFieldValue(String fieldId, dynamic value) {
    final updatedFields = state.fields.map((field) {
      if (field.id == fieldId) {
        return field.copyWith(value: value);
      }
      return field;
    }).toList();

    state = state.copyWith(fields: updatedFields);
  }

  /// Generate JSON string for export
  Future<File> exportFieldsToJson(String fileName) async {
    final jsonData = {'fields': state.fields.map((f) => f.toJson()).toList()};
    final jsonString = JsonEncoder.withIndent('  ').convert(jsonData);
    debugPrint("jsonString: $jsonString");

    try {
      Directory? exportDir;
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final pathParts = extDir.path.split('/');
          final downloadPath = '/${pathParts[1]}/${pathParts[2]}/${pathParts[3]}/Download';
          exportDir = Directory(downloadPath);
        }
      }

      exportDir ??= await getApplicationDocumentsDirectory();
      debugPrint("exportDir: $exportDir");

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final file = File('${exportDir.path}/$fileName');

      // Explicitly delete if exists to ensure clean overwrite
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('Error deleting existing file: $e');
        }
      }

      await file.writeAsString(jsonString, flush: true);

      debugPrint("File: $file");
      return file;
    } catch (e) {
      throw FileFailure('Failed to save export file: $e');
    }
  }

  /// Import fields from JSON string
  int importFieldsFromJson(String jsonString) {
    if (state.isPublished) throw Exception('Cannot import into published document');

    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      print("Import fields: $jsonData");

      if (!jsonData.containsKey('fields')) {
        throw FormatException('Invalid JSON: missing "fields" array');
      }

      final fieldsList = jsonData['fields'] as List<dynamic>;
      final importedFields = <FieldEntity>[];

      for (final fieldJson in fieldsList) {
        final map = fieldJson as Map<String, dynamic>;

        // Use FieldEntity.fromJson to properly handle signature value conversion
        try {
          importedFields.add(FieldEntity.fromJson(map));
        } catch (e) {
          debugPrint('Error parsing field from JSON: $e');
          // Fallback to manual construction for backward compatibility
          double xPercent =
              map['xPercent']?.toDouble() ?? (map['x'] != null ? (map['x'] as num).toDouble() / 1000 : 0.0);
          double yPercent =
              map['yPercent']?.toDouble() ?? (map['y'] != null ? (map['y'] as num).toDouble() / 1000 : 0.0);
          double widthPercent =
              map['widthPercent']?.toDouble() ?? (map['width'] != null ? (map['width'] as num).toDouble() / 1000 : 0.1);
          double heightPercent =
              map['heightPercent']?.toDouble() ??
              (map['height'] != null ? (map['height'] as num).toDouble() / 1000 : 0.05);

          importedFields.add(
            FieldEntity(
              id: map['id'] as String? ?? FieldEntity.generateId(),
              type: FieldType.values.firstWhere((t) => t.name == map['type'], orElse: () => FieldType.text),
              page: map['page'] as int? ?? 1,
              xPercent: xPercent.clamp(0.0, 1.0),
              yPercent: yPercent.clamp(0.0, 1.0),
              widthPercent: widthPercent.clamp(0.01, 1.0),
              heightPercent: heightPercent.clamp(0.01, 1.0),
              value: map['value'],
              isRequired: map['isRequired'] as bool? ?? false,
              label: map['label'] as String?,
            ),
          );
        }
      }

      state = state.copyWith(fields: importedFields, successMessage: 'Imported ${importedFields.length} fields');
      return importedFields.length;
    } catch (e) {
      state = state.copyWith(failure: FileFailure('Failed to import fields: $e'));
      rethrow;
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(failure: null, successMessage: null);
  }

  /// Validate if all required fields are filled
  List<String> validateFormSubmission() {
    final missingFieldIds = <String>[];

    for (final field in state.fields) {
      if (field.isRequired) {
        final value = field.value;
        if (value == null) {
          missingFieldIds.add(field.id);
        } else if (value is String && value.trim().isEmpty) {
          missingFieldIds.add(field.id);
        }
      }
    }

    return missingFieldIds;
  }

  /// Set total pages (called from PDF viewer)
  void setTotalPages(int pages) {
    state = state.copyWith(totalPages: pages);
  }

  /// Generate final signed PDF with all field values overlaid
  Future<File?> generateFinalPdf() async {
    if (state.document == null) {
      state = state.copyWith(failure: const FileFailure('No document loaded'));
      return null;
    }

    state = state.copyWith(isLoading: true);

    try {
      final pdfService = PdfGeneratorService();
      final outputFile = await pdfService.generateSignedPdf(document: state.document!, fields: state.fields);

      state = state.copyWith(isLoading: false, successMessage: 'PDF generated successfully!');

      return outputFile;
    } catch (e) {
      state = state.copyWith(isLoading: false, failure: FileFailure('Failed to generate PDF: $e'));
      return null;
    }
  }
}
