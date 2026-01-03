import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/field_entity.dart';
import '../../domain/entities/document_entity.dart';
import '../../../../core/errors/failures.dart';

/// Editor mode enum
enum EditorMode { edit, sign }

/// State for document editor
class EditorState {
  final DocumentEntity? document;
  final List<FieldEntity> fields;
  final FieldEntity? selectedField;
  final int currentPage;
  final int totalPages;
  final EditorMode mode;
  final bool isLoading;
  final bool isSaving;
  final Failure? failure;
  final String? successMessage;

  const EditorState({
    this.document,
    this.fields = const [],
    this.selectedField,
    this.currentPage = 1,
    this.totalPages = 1,
    this.mode = EditorMode.edit,
    this.isLoading = false,
    this.isSaving = false,
    this.failure,
    this.successMessage,
  });

  EditorState copyWith({
    DocumentEntity? document,
    List<FieldEntity>? fields,
    FieldEntity? selectedField,
    bool clearSelection = false,
    int? currentPage,
    int? totalPages,
    EditorMode? mode,
    bool? isLoading,
    bool? isSaving,
    Failure? failure,
    String? successMessage,
  }) {
    return EditorState(
      document: document ?? this.document,
      fields: fields ?? this.fields,
      selectedField: clearSelection ? null : (selectedField ?? this.selectedField),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      failure: failure,
      successMessage: successMessage,
    );
  }

  factory EditorState.initial() => const EditorState();
  factory EditorState.loading() => const EditorState(isLoading: true);
}

/// ViewModel for document editor
class EditorViewModel extends StateNotifier<EditorState> {
  EditorViewModel() : super(EditorState.initial());

  /// Initialize with document
  void initDocument(DocumentEntity document, int totalPages) {
    state = state.copyWith(document: document, totalPages: totalPages, isLoading: false);
  }

  /// Add a new field at position
  void addField(FieldType type, double xPercent, double yPercent) {
    final newField = FieldEntity.create(type: type, page: state.currentPage, xPercent: xPercent, yPercent: yPercent);

    state = state.copyWith(fields: [...state.fields, newField], selectedField: newField);
  }

  /// Update field position (during drag)
  void updateFieldPosition(String fieldId, double xPercent, double yPercent) {
    final updatedFields = state.fields.map((field) {
      if (field.id == fieldId) {
        return field.copyWith(xPercent: xPercent, yPercent: yPercent);
      }
      return field;
    }).toList();

    // Also update selected field if it's the one being moved
    FieldEntity? updatedSelected;
    if (state.selectedField?.id == fieldId) {
      updatedSelected = updatedFields.firstWhere((f) => f.id == fieldId);
    }

    state = state.copyWith(fields: updatedFields, selectedField: updatedSelected);
  }

  /// Update field size
  void updateFieldSize(String fieldId, double widthPercent, double heightPercent) {
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

  /// Delete a field
  void deleteField(String fieldId) {
    final updatedFields = state.fields.where((f) => f.id != fieldId).toList();
    state = state.copyWith(fields: updatedFields, clearSelection: state.selectedField?.id == fieldId);
  }

  /// Delete selected field
  void deleteSelectedField() {
    if (state.selectedField != null) {
      deleteField(state.selectedField!.id);
    }
  }

  /// Navigate to page
  void goToPage(int page) {
    if (page >= 1 && page <= state.totalPages) {
      state = state.copyWith(currentPage: page, clearSelection: true);
    }
  }

  /// Next page
  void nextPage() {
    goToPage(state.currentPage + 1);
  }

  /// Previous page
  void previousPage() {
    goToPage(state.currentPage - 1);
  }

  /// First page
  void firstPage() {
    goToPage(1);
  }

  /// Last page
  void lastPage() {
    goToPage(state.totalPages);
  }

  /// Get fields for current page
  List<FieldEntity> get currentPageFields {
    return state.fields.where((f) => f.page == state.currentPage).toList();
  }

  /// Switch to sign mode (locks field positions)
  void enterSignMode() {
    state = state.copyWith(mode: EditorMode.sign, clearSelection: true);
  }

  /// Switch back to edit mode
  void enterEditMode() {
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

  /// Export fields as JSON
  List<Map<String, dynamic>> exportFieldsJson() {
    return state.fields.map((f) => f.toJson()).toList();
  }

  /// Import fields from JSON
  void importFieldsFromJson(List<dynamic> jsonList) {
    try {
      final importedFields = jsonList.map((json) => FieldEntity.fromJson(json as Map<String, dynamic>)).toList();

      state = state.copyWith(fields: importedFields, successMessage: 'Imported ${importedFields.length} fields');
    } catch (e) {
      state = state.copyWith(failure: FileFailure('Failed to import fields: $e'));
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(failure: null, successMessage: null);
  }

  /// Set total pages (called from PDF viewer)
  void setTotalPages(int pages) {
    state = state.copyWith(totalPages: pages);
  }
}

/// Provider for editor viewmodel
final editorViewModelProvider = StateNotifierProvider.autoDispose<EditorViewModel, EditorState>((ref) {
  return EditorViewModel();
});
