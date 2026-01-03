import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../route/route_name.dart';
import '../../../documents/presentation/widgets/document_card.dart';
import '../../../documents/presentation/widgets/empty_documents.dart';

class HomeTab extends ConsumerWidget {
  final VoidCallback onUploadPressed;
  final VoidCallback onRefresh;

  const HomeTab({super.key, required this.onUploadPressed, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentViewModelProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.documents.isEmpty) {
      return EmptyDocuments(onUploadPressed: onUploadPressed);
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: state.documents.length,
        itemBuilder: (context, index) {
          final document = state.documents[index];
          return DocumentCard(
            document: document,
            onTap: () {
              // Navigate to document editor (Phase 4)
              Navigator.pushNamed(context, RouteName.editor, arguments: document);
            },
            onDelete: () {
              _showDeleteDialog(context, ref, document.id);
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, int documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final user = ref.read(firebaseAuthProvider).currentUser;
              if (user != null) {
                ref.read(documentViewModelProvider.notifier).deleteDocument(documentId, user.uid);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
