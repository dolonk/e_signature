import 'dart:io';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/document_entity.dart';
import '../../../../core/errors/exceptions.dart';

/// Local data source for document operations
abstract class DocumentLocalDataSource {
  Future<List<DocumentEntity>> getDocuments(String userId);
  Future<DocumentEntity?> getDocumentById(int id);
  Future<DocumentEntity> saveDocument({
    required String filePath,
    required String fileName,
    required String userId,
    required String fileType,
  });
  Future<DocumentEntity> updateDocument(DocumentEntity document);
  Future<bool> deleteDocument(int id);
  Future<DocumentEntity> updateStatus(int id, String status);
}

class DocumentLocalDataSourceImpl implements DocumentLocalDataSource {
  final Isar _isar;

  DocumentLocalDataSourceImpl(this._isar);

  @override
  Future<List<DocumentEntity>> getDocuments(String userId) async {
    try {
      return await _isar.documentEntitys.filter().userIdEqualTo(userId).sortByUploadedAtDesc().findAll();
    } catch (e) {
      throw CacheException('Failed to fetch documents: $e');
    }
  }

  @override
  Future<DocumentEntity?> getDocumentById(int id) async {
    try {
      return await _isar.documentEntitys.get(id);
    } catch (e) {
      throw CacheException('Failed to fetch document: $e');
    }
  }

  @override
  Future<DocumentEntity> saveDocument({
    required String filePath,
    required String fileName,
    required String userId,
    required String fileType,
  }) async {
    try {
      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final documentsDir = Directory('${appDir.path}/documents');

      // Create documents folder if it doesn't exist
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${timestamp}_$fileName';
      final newFilePath = '${documentsDir.path}/$newFileName';

      // Copy file to app directory
      final sourceFile = File(filePath);
      final fileSize = await sourceFile.length();
      await sourceFile.copy(newFilePath);

      // Create document entity
      final document = DocumentEntity()
        ..name = fileName
        ..localFilePath = newFilePath
        ..userId = userId
        ..fileType = fileType
        ..uploadedAt = DateTime.now()
        ..status = 'draft'
        ..fileSize = fileSize;

      // Save to Isar
      await _isar.writeTxn(() async {
        await _isar.documentEntitys.put(document);
      });

      return document;
    } catch (e) {
      throw FileException('Failed to save document: $e');
    }
  }

  @override
  Future<DocumentEntity> updateDocument(DocumentEntity document) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.documentEntitys.put(document);
      });
      return document;
    } catch (e) {
      throw CacheException('Failed to update document: $e');
    }
  }

  @override
  Future<bool> deleteDocument(int id) async {
    try {
      // Get document first to delete file
      final document = await _isar.documentEntitys.get(id);
      if (document != null) {
        // Delete local file
        final file = File(document.localFilePath);
        if (await file.exists()) {
          await file.delete();
        }

        // Delete config file if exists
        if (document.configPath != null) {
          final configFile = File(document.configPath!);
          if (await configFile.exists()) {
            await configFile.delete();
          }
        }

        // Delete signed PDF if exists
        if (document.signedPdfPath != null) {
          final signedFile = File(document.signedPdfPath!);
          if (await signedFile.exists()) {
            await signedFile.delete();
          }
        }
      }

      // Delete from Isar
      await _isar.writeTxn(() async {
        await _isar.documentEntitys.delete(id);
      });

      return true;
    } catch (e) {
      throw CacheException('Failed to delete document: $e');
    }
  }

  @override
  Future<DocumentEntity> updateStatus(int id, String status) async {
    try {
      final document = await _isar.documentEntitys.get(id);
      if (document == null) {
        throw CacheException('Document not found');
      }

      document.status = status;

      await _isar.writeTxn(() async {
        await _isar.documentEntitys.put(document);
      });

      return document;
    } catch (e) {
      throw CacheException('Failed to update status: $e');
    }
  }
}
