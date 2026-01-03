import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/document_entity.dart';

/// Repository interface for document operations
abstract class DocumentRepository {
  /// Get all documents for a user
  Future<Either<Failure, List<DocumentEntity>>> getDocuments(String userId);

  /// Get a single document by ID
  Future<Either<Failure, DocumentEntity?>> getDocumentById(int id);

  /// Save a new document (copy file + save metadata)
  Future<Either<Failure, DocumentEntity>> saveDocument({
    required String filePath,
    required String fileName,
    required String userId,
    required String fileType,
  });

  /// Update document metadata
  Future<Either<Failure, DocumentEntity>> updateDocument(DocumentEntity document);

  /// Delete a document (file + metadata)
  Future<Either<Failure, bool>> deleteDocument(int id);

  /// Update document status
  Future<Either<Failure, DocumentEntity>> updateStatus(int id, String status);
}
