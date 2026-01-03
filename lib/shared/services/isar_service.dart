import 'package:path_provider/path_provider.dart';
import 'package:isar_community/isar.dart';
import '../../features/documents/domain/entities/document_entity.dart';

/// Service class to handle Isar database operations
class IsarService {
  static Isar? _isar;

  /// Get Isar instance, initialize if not already done
  static Future<Isar> get instance async {
    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open([DocumentEntitySchema], directory: dir.path, name: 'esignature_db');

    return _isar!;
  }

  /// Close the database
  static Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
      _isar = null;
    }
  }

  /// Clear all data (useful for testing)
  static Future<void> clearAllData() async {
    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}
