import 'package:isar_community/isar.dart';

part 'document_entity.g.dart';

/// Document entity for Isar database
@collection
class DocumentEntity {
  Id id = Isar.autoIncrement;

  /// Document name (file name)
  late String name;

  /// Local file path where PDF is stored
  late String localFilePath;

  /// User ID who owns this document
  late String userId;

  /// File type: 'pdf' or 'docx'
  late String fileType;

  /// When document was uploaded
  @Index()
  late DateTime uploadedAt;

  /// Document status: 'draft', 'pending', 'signed'
  @Index()
  late String status;

  /// Optional: JSON configuration file path
  String? configPath;

  /// Optional: Final signed PDF path
  String? signedPdfPath;

  /// File size in bytes
  int? fileSize;
}
