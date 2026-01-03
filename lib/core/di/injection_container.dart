import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/authentication/data/datasources/auth_remote_datasource.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/documents/data/datasources/document_local_datasource.dart';
import '../../features/documents/data/repositories/document_repository_impl.dart';
import '../../features/documents/domain/repositories/document_repository.dart';
import '../../features/documents/presentation/viewmodels/document_viewmodel.dart';
import '../../shared/services/isar_service.dart';

// Auth Providers
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.read(firebaseAuthProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider));
});

// Document Providers - uses IsarService which is initialized in main.dart
final documentLocalDataSourceProvider = FutureProvider<DocumentLocalDataSource>((ref) async {
  final isar = await IsarService.instance;
  return DocumentLocalDataSourceImpl(isar);
});

final documentRepositoryProvider = FutureProvider<DocumentRepository>((ref) async {
  final dataSource = await ref.watch(documentLocalDataSourceProvider.future);
  return DocumentRepositoryImpl(dataSource);
});

final documentViewModelProvider = StateNotifierProvider<DocumentViewModel, DocumentState>((ref) {
  // We'll initialize with a placeholder and then load actual data
  final repoAsync = ref.watch(documentRepositoryProvider);
  return repoAsync.when(
    data: (repo) => DocumentViewModel(repo),
    loading: () => DocumentViewModel.loading(),
    error: (e, _) => DocumentViewModel.error(e.toString()),
  );
});
