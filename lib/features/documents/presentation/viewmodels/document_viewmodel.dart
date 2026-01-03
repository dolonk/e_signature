import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import '../../../../core/errors/failures.dart';

/// State for document management
class DocumentState {
  final List<DocumentEntity> documents;
  final bool isLoading;
  final bool isInitializing;
  final Failure? failure;
  final String? successMessage;

  const DocumentState({
    this.documents = const [],
    this.isLoading = false,
    this.isInitializing = false,
    this.failure,
    this.successMessage,
  });

  DocumentState copyWith({
    List<DocumentEntity>? documents,
    bool? isLoading,
    bool? isInitializing,
    Failure? failure,
    String? successMessage,
  }) {
    return DocumentState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      failure: failure,
      successMessage: successMessage,
    );
  }

  factory DocumentState.initial() => const DocumentState();
  factory DocumentState.loading() => const DocumentState(isLoading: true);
  factory DocumentState.initializing() => const DocumentState(isInitializing: true);
}

/// ViewModel for document operations
class DocumentViewModel extends StateNotifier<DocumentState> {
  final DocumentRepository? _repository;

  DocumentViewModel(this._repository) : super(DocumentState.initial());

  // Factory for loading state
  factory DocumentViewModel.loading() {
    return DocumentViewModel._internal(null, isInitializing: true);
  }

  // Factory for error state
  factory DocumentViewModel.error(String message) {
    return DocumentViewModel._internal(null, errorMessage: message);
  }

  DocumentViewModel._internal(this._repository, {bool isInitializing = false, String? errorMessage})
    : super(
        isInitializing
            ? DocumentState.initializing()
            : errorMessage != null
            ? DocumentState(failure: CacheFailure(errorMessage))
            : DocumentState.initial(),
      );

  /// Load all documents for a user
  Future<void> loadDocuments(String userId) async {
    if (_repository == null) {
      state = state.copyWith(failure: const CacheFailure('Repository not initialized'));
      return;
    }

    state = state.copyWith(isLoading: true, isInitializing: false);

    final result = await _repository.getDocuments(userId);

    state = result.fold(
      (failure) => state.copyWith(isLoading: false, failure: failure),
      (documents) => state.copyWith(isLoading: false, documents: documents),
    );
  }

  /// Pick and upload a document
  Future<void> pickAndUploadDocument(String userId) async {
    if (_repository == null) {
      state = state.copyWith(failure: const CacheFailure('Repository not initialized'));
      return;
    }

    try {
      // Open file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final file = result.files.first;

      if (file.path == null) {
        state = state.copyWith(failure: const FileFailure('Could not access the file'));
        return;
      }

      state = state.copyWith(isLoading: true);

      // Determine file type
      final fileType = file.extension?.toLowerCase() ?? 'pdf';

      // Save document
      final saveResult = await _repository.saveDocument(
        filePath: file.path!,
        fileName: file.name,
        userId: userId,
        fileType: fileType,
      );

      await saveResult.fold(
        (failure) async {
          state = state.copyWith(isLoading: false, failure: failure);
        },
        (document) async {
          // Reload documents
          await loadDocuments(userId);
          state = state.copyWith(successMessage: 'Document uploaded successfully');
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, failure: FileFailure('Failed to pick file: $e'));
    }
  }

  /// Delete a document
  Future<void> deleteDocument(int id, String userId) async {
    if (_repository == null) {
      state = state.copyWith(failure: const CacheFailure('Repository not initialized'));
      return;
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.deleteDocument(id);

    await result.fold(
      (failure) async {
        state = state.copyWith(isLoading: false, failure: failure);
      },
      (success) async {
        await loadDocuments(userId);
        state = state.copyWith(successMessage: 'Document deleted');
      },
    );
  }

  /// Clear error/success messages
  void clearMessages() {
    state = state.copyWith(failure: null, successMessage: null);
  }
}
