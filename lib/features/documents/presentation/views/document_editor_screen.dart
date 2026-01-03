import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/entities/field_entity.dart';
import '../viewmodels/editor_viewmodel.dart';
import '../widgets/draggable_field.dart';
import '../widgets/field_toolbar.dart';
import '../widgets/page_navigation.dart';
import '../../../../core/theme/app_colors.dart';

/// Document Editor Screen - Phase 4
/// Allows users to view PDF and add/position draggable fields
class DocumentEditorScreen extends ConsumerStatefulWidget {
  final DocumentEntity document;

  const DocumentEditorScreen({super.key, required this.document});

  @override
  ConsumerState<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends ConsumerState<DocumentEditorScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  PdfViewerController? _pdfController;
  FieldType? _selectedFieldType;

  // Page dimensions for field positioning
  double _pageWidth = 0;
  double _pageHeight = 0;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorViewModelProvider);
    final isEditMode = editorState.mode == EditorMode.edit;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(editorState, isEditMode),
      body: Column(
        children: [
          // PDF Viewer with Field Overlay
          Expanded(child: _buildPdfViewerWithOverlay(editorState, isEditMode)),
          // Page Navigation
          if (editorState.totalPages > 1)
            PageNavigation(
              currentPage: editorState.currentPage,
              totalPages: editorState.totalPages,
              onFirstPage: () => ref.read(editorViewModelProvider.notifier).firstPage(),
              onPreviousPage: () => ref.read(editorViewModelProvider.notifier).previousPage(),
              onNextPage: () => ref.read(editorViewModelProvider.notifier).nextPage(),
              onLastPage: () => ref.read(editorViewModelProvider.notifier).lastPage(),
            ),
          // Field Toolbar (only in edit mode)
          if (isEditMode) FieldToolbar(onFieldSelected: _onFieldTypeSelected, isEnabled: true),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(EditorState state, bool isEditMode) {
    return AppBar(
      title: Text(
        widget.document.name,
        style: TextStyle(fontSize: 16.sp),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        // Save button
        if (isEditMode) IconButton(icon: const Icon(Icons.save), onPressed: _onSave, tooltip: 'Save Configuration'),
        // Toggle mode button
        TextButton.icon(
          onPressed: _toggleMode,
          icon: Icon(
            isEditMode ? Icons.play_arrow : Icons.edit,
            color: isEditMode ? AppColors.success : AppColors.primary,
          ),
          label: Text(
            isEditMode ? 'Publish' : 'Edit',
            style: TextStyle(color: isEditMode ? AppColors.success : AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfViewerWithOverlay(EditorState state, bool isEditMode) {
    final file = File(widget.document.localFilePath);

    if (!file.existsSync()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              'Document not found',
              style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: isEditMode ? (details) => _onPdfTap(details, constraints) : null,
          child: Stack(
            children: [
              // PDF Viewer
              SfPdfViewer.file(
                file,
                key: _pdfViewerKey,
                controller: _pdfController,
                canShowScrollHead: false,
                canShowScrollStatus: false,
                enableDoubleTapZooming: true,
                onDocumentLoaded: (details) {
                  ref.read(editorViewModelProvider.notifier).setTotalPages(details.document.pages.count);
                  ref
                      .read(editorViewModelProvider.notifier)
                      .initDocument(widget.document, details.document.pages.count);
                  // Get first page dimensions
                  if (details.document.pages.count > 0) {
                    final page = details.document.pages[0];
                    setState(() {
                      _pageWidth = page.size.width;
                      _pageHeight = page.size.height;
                    });
                  }
                },
                onPageChanged: (details) {
                  ref.read(editorViewModelProvider.notifier).goToPage(details.newPageNumber);
                },
              ),
              // Field Overlay
              _buildFieldOverlay(state, isEditMode, constraints),
              // Selected field type indicator
              if (_selectedFieldType != null && isEditMode)
                Positioned(
                  top: 8.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20.r)),
                      child: Text(
                        'Tap on document to place ${FieldEntity.getDisplayName(_selectedFieldType!)}',
                        style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFieldOverlay(EditorState state, bool isEditMode, BoxConstraints constraints) {
    // Get fields for current page
    final currentPageFields = state.fields.where((f) => f.page == state.currentPage).toList();

    if (currentPageFields.isEmpty) return const SizedBox.shrink();

    // Use constraints as page dimensions if PDF dimensions not available
    final pageW = _pageWidth > 0 ? constraints.maxWidth : constraints.maxWidth;
    final pageH = _pageHeight > 0 ? constraints.maxHeight : constraints.maxHeight;

    return Positioned.fill(
      child: Stack(
        children: currentPageFields.map((field) {
          return DraggableField(
            field: field,
            isSelected: state.selectedField?.id == field.id,
            isDraggable: isEditMode,
            pageWidth: pageW,
            pageHeight: pageH,
            onTap: () {
              if (isEditMode) {
                ref.read(editorViewModelProvider.notifier).selectField(field.id);
              } else {
                _onFieldInteract(field);
              }
            },
            onDelete: () {
              ref.read(editorViewModelProvider.notifier).deleteField(field.id);
            },
            onDragEnd: (xPercent, yPercent) {
              ref.read(editorViewModelProvider.notifier).updateFieldPosition(field.id, xPercent, yPercent);
            },
          );
        }).toList(),
      ),
    );
  }

  void _onFieldTypeSelected(FieldType type) {
    setState(() {
      _selectedFieldType = type;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tap on document to place ${FieldEntity.getDisplayName(type)}'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _onPdfTap(TapUpDetails details, BoxConstraints constraints) {
    if (_selectedFieldType == null) {
      // Clear selection if no field type is selected
      ref.read(editorViewModelProvider.notifier).clearSelection();
      return;
    }

    // Calculate percentage position
    final xPercent = details.localPosition.dx / constraints.maxWidth;
    final yPercent = details.localPosition.dy / constraints.maxHeight;

    // Add field at tapped position
    ref
        .read(editorViewModelProvider.notifier)
        .addField(
          _selectedFieldType!,
          xPercent.clamp(0.0, 0.9), // Prevent field from going off-screen
          yPercent.clamp(0.0, 0.9),
        );

    // Clear selected field type
    setState(() {
      _selectedFieldType = null;
    });
  }

  void _onFieldInteract(FieldEntity field) {
    // This will be implemented in Phase 6 (Signing Mode)
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sign/fill ${FieldEntity.getDisplayName(field.type)} field'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleMode() {
    final editorNotifier = ref.read(editorViewModelProvider.notifier);
    final currentMode = ref.read(editorViewModelProvider).mode;

    if (currentMode == EditorMode.edit) {
      editorNotifier.enterSignMode();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signing mode - Fields are locked'), backgroundColor: AppColors.success),
      );
    } else {
      editorNotifier.enterEditMode();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edit mode - You can now move fields'), backgroundColor: AppColors.info),
      );
    }
  }

  void _onSave() {
    final fields = ref.read(editorViewModelProvider).fields;

    if (fields.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No fields to save'), backgroundColor: AppColors.warning));
      return;
    }

    // Export as JSON (will be saved to file in Phase 5)
    final jsonData = ref.read(editorViewModelProvider.notifier).exportFieldsJson();
    debugPrint('Exported fields: $jsonData');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved ${fields.length} fields'), backgroundColor: AppColors.success));
  }
}
