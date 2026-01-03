import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_local_datasource.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDataSource _localDataSource;

  DocumentRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, List<DocumentEntity>>> getDocuments(String userId) async {
    try {
      final documents = await _localDataSource.getDocuments(userId);
      return Right(documents);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DocumentEntity?>> getDocumentById(int id) async {
    try {
      final document = await _localDataSource.getDocumentById(id);
      return Right(document);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DocumentEntity>> saveDocument({
    required String filePath,
    required String fileName,
    required String userId,
    required String fileType,
  }) async {
    try {
      final document = await _localDataSource.saveDocument(
        filePath: filePath,
        fileName: fileName,
        userId: userId,
        fileType: fileType,
      );
      return Right(document);
    } on FileException catch (e) {
      return Left(FileFailure(e.message));
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DocumentEntity>> updateDocument(DocumentEntity document) async {
    try {
      final updated = await _localDataSource.updateDocument(document);
      return Right(updated);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteDocument(int id) async {
    try {
      final result = await _localDataSource.deleteDocument(id);
      return Right(result);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DocumentEntity>> updateStatus(int id, String status) async {
    try {
      final document = await _localDataSource.updateStatus(id, status);
      return Right(document);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
