import 'package:isar_community/isar.dart';
import '../../../../shared/entities/document_entity.dart';
import '../../../../core/errors/exceptions.dart';

abstract class HomeLocalDataSource {
  /// Get all documents for a user
  Future<List<DocumentEntity>> getDocuments(String userId);

  /// Get document count
  Future<int> getDocumentCount(String userId);
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  final Isar _isar;

  HomeLocalDataSourceImpl(this._isar);

  @override
  Future<List<DocumentEntity>> getDocuments(String userId) async {
    try {
      final documents = await _isar.documentEntitys.filter().userIdEqualTo(userId).sortByUploadedAtDesc().findAll();
      return documents;
    } catch (e) {
      throw CacheException('Failed to load documents: $e');
    }
  }

  @override
  Future<int> getDocumentCount(String userId) async {
    try {
      return await _isar.documentEntitys.filter().userIdEqualTo(userId).count();
    } catch (e) {
      throw CacheException('Failed to count documents: $e');
    }
  }
}
