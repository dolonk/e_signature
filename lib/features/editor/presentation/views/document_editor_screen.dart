import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/entities/document_entity.dart';
import '../../../../shared/entities/field_entity.dart';
import '../../../../core/di/injection_container.dart';
import '../viewmodels/editor_viewmodel.dart';
import '../widgets/draggable_field.dart';
import '../widgets/field_toolbar.dart';
import '../widgets/page_navigation.dart';
import '../widgets/field_input_dialog.dart';
import '../../../../core/theme/app_colors.dart';

class DocumentEditorScreen extends ConsumerStatefulWidget {
  final DocumentEntity document;

  const DocumentEditorScreen({super.key, required this.document});

  @override
  ConsumerState<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends ConsumerState<DocumentEditorScreen> {
  FieldType? _selectedFieldType;

  @override
  void initState() {
    super.initState();
    // Initialize document and render first page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editorViewModelProvider.notifier).initDocumentWithRendering(widget.document);
    });
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorViewModelProvider);
    final isEditMode = editorState.canEdit;

    ref.listen(editorViewModelProvider, (previous, next) {
      if (next.failure != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.failure!.message), backgroundColor: AppColors.error));
        ref.read(editorViewModelProvider.notifier).clearMessages();
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.successMessage!), backgroundColor: AppColors.success));
        ref.read(editorViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(editorState),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Gap(24.h),
          Expanded(child: _buildPdfViewerWithOverlay(editorState, isEditMode)),
          Gap(24.h),

          SizedBox(
            height: 160.h,
            child: Column(
              children: [
                if (editorState.totalPages > 1)
                  PageNavigation(
                    currentPage: editorState.currentPage,
                    totalPages: editorState.totalPages,
                    onFirstPage: () => ref.read(editorViewModelProvider.notifier).firstPage(),
                    onPreviousPage: () => ref.read(editorViewModelProvider.notifier).previousPage(),
                    onNextPage: () => ref.read(editorViewModelProvider.notifier).nextPage(),
                    onLastPage: () => ref.read(editorViewModelProvider.notifier).lastPage(),
                  ),
                if (isEditMode) FieldToolbar(onFieldSelected: _onFieldTypeSelected, isEnabled: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(EditorState state) {
    final isEditMode = state.canEdit;
    final isPublished = state.isPublished;

    return AppBar(
      title: Text(
        widget.document.name,
        style: TextStyle(fontSize: 16.sp),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'export':
                _exportFieldsJson();
                break;
              case 'import':
                _importFieldsJson();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export',
              enabled: state.fields.isNotEmpty,
              child: Row(
                children: [
                  const Icon(Icons.upload_file, size: 20),
                  SizedBox(width: 8.w),
                  const Text('Export Fields (JSON)'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'import',
              enabled: !isPublished,
              child: Row(
                children: [
                  const Icon(Icons.download, size: 20),
                  SizedBox(width: 8.w),
                  const Text('Import Fields (JSON)'),
                ],
              ),
            ),
          ],
        ),

        if (!isPublished)
          TextButton.icon(
            onPressed: _toggleMode,
            icon: Icon(
              isEditMode ? Icons.draw : Icons.edit,
              color: isEditMode ? AppColors.info : AppColors.primary,
            ),
            label: Text(
              isEditMode ? 'Signing' : 'Edit Mode',
              style: TextStyle(color: isEditMode ? AppColors.info : AppColors.primary),
            ),
          ),
        if (isEditMode && !isPublished)
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ElevatedButton.icon(
              onPressed: _onPublish,
              icon: Icon(Icons.publish, size: 18.sp),
              label: const Text('Publish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
              ),
            ),
          ),
        if (state.isPublished)
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ElevatedButton.icon(
              onPressed: _onFinishSigning,
              icon: Icon(Icons.check, size: 18.sp),
              label: const Text('Finish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
              ),
            ),
          ),
      ],
    );
  }

  /// Export fields to JSON file
  Future<void> _exportFieldsJson() async {
    final viewModel = ref.read(editorViewModelProvider.notifier);
    final fileName = '${widget.document.name.replaceAll(' ', '_')}_fields.json';

    try {
      final file = await viewModel.saveExportFile(fileName);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        builder: (ctx) => Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 24.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Exported Successfully!',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Saved to:',
                style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  file.path,
                  style: TextStyle(fontSize: 12.sp, fontFamily: 'monospace'),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(file.path)],
                            subject: 'Field Config - ${widget.document.name}',
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  /// Import fields from JSON file
  Future<void> _importFieldsJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      if (!mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Fields?'),
          content: const Text('This will replace current fields with imported fields.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Import')),
          ],
        ),
      );

      if (confirm == true) {
        // Use ViewModel to parse and update state
        try {
          ref.read(editorViewModelProvider.notifier).importFieldsFromJson(jsonString);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Invalid Import: $e'), backgroundColor: AppColors.error));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Widget _buildPdfViewerWithOverlay(EditorState state, bool isEditMode) {
    // Show loading while PDF is being loaded or page is rendering
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 16.h),
            Text(
              'Loading document...',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Show error if file not found
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

    // Get current page image
    final pageImage = state.pageImages[state.currentPage];

    // Show loading if page is rendering
    if (pageImage == null || state.isRenderingPage) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 16.h),
            Text(
              'Rendering page ${state.currentPage}...',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
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
              // PDF Page displayed as Image
              Center(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.0,
                  child: Image.memory(pageImage, fit: BoxFit.contain, width: constraints.maxWidth),
                ),
              ),
              // Field overlays
              _buildFieldOverlay(state, isEditMode, constraints),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFieldOverlay(EditorState state, bool isEditMode, BoxConstraints constraints) {
    final currentPageFields = state.fields.where((f) => f.page == state.currentPage).toList();
    if (currentPageFields.isEmpty) return const SizedBox.shrink();

    // Calculate actual displayed image dimensions based on PDF page aspect ratio
    // This ensures field positions match the PDF generator output
    double displayWidth = constraints.maxWidth;
    double displayHeight = constraints.maxHeight;

    if (state.pdfPageWidth > 0 && state.pdfPageHeight > 0) {
      final pdfAspectRatio = state.pdfPageWidth / state.pdfPageHeight;
      final containerAspectRatio = constraints.maxWidth / constraints.maxHeight;

      if (containerAspectRatio > pdfAspectRatio) {
        // Container is wider than PDF - height is the limiting factor
        displayHeight = constraints.maxHeight;
        displayWidth = displayHeight * pdfAspectRatio;
      } else {
        // Container is taller than PDF - width is the limiting factor
        displayWidth = constraints.maxWidth;
        displayHeight = displayWidth / pdfAspectRatio;
      }
    }

    // Calculate offset to center the overlay with the image
    final offsetX = (constraints.maxWidth - displayWidth) / 2;
    final offsetY = (constraints.maxHeight - displayHeight) / 2;

    return Positioned(
      left: offsetX,
      top: offsetY,
      width: displayWidth,
      height: displayHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: currentPageFields.map((field) {
          return DraggableField(
            key: ValueKey(field.id),
            field: field,
            isSelected: state.selectedField?.id == field.id,
            isDraggable: isEditMode,
            pageWidth: displayWidth,
            pageHeight: displayHeight,
            onTap: () {
              if (isEditMode) {
                ref.read(editorViewModelProvider.notifier).selectField(field.id);
              } else {
                _showFieldInputDialog(field);
              }
            },
            onDelete: () => ref.read(editorViewModelProvider.notifier).deleteField(field.id),
            onPositionChanged: (x, y) =>
                ref.read(editorViewModelProvider.notifier).updateFieldPosition(field.id, x, y),
            onSizeChanged: (w, h) =>
                ref.read(editorViewModelProvider.notifier).updateFieldSize(field.id, w, h),
          );
        }).toList(),
      ),
    );
  }

  void _onFieldTypeSelected(FieldType type) {
    // Add field directly at center position
    ref.read(editorViewModelProvider.notifier).addField(type, 0.3, 0.4);
  }

  void _onPdfTap(TapUpDetails details, BoxConstraints constraints) {
    if (_selectedFieldType == null) {
      ref.read(editorViewModelProvider.notifier).clearSelection();
      return;
    }

    final state = ref.read(editorViewModelProvider);

    // Calculate actual displayed image dimensions (same as _buildFieldOverlay)
    double displayWidth = constraints.maxWidth;
    double displayHeight = constraints.maxHeight;

    if (state.pdfPageWidth > 0 && state.pdfPageHeight > 0) {
      final pdfAspectRatio = state.pdfPageWidth / state.pdfPageHeight;
      final containerAspectRatio = constraints.maxWidth / constraints.maxHeight;

      if (containerAspectRatio > pdfAspectRatio) {
        displayHeight = constraints.maxHeight;
        displayWidth = displayHeight * pdfAspectRatio;
      } else {
        displayWidth = constraints.maxWidth;
        displayHeight = displayWidth / pdfAspectRatio;
      }
    }

    // Calculate offset from center
    final offsetX = (constraints.maxWidth - displayWidth) / 2;
    final offsetY = (constraints.maxHeight - displayHeight) / 2;

    // Adjust tap position relative to actual image area
    final adjustedX = details.localPosition.dx - offsetX;
    final adjustedY = details.localPosition.dy - offsetY;

    // Skip if tap is outside the image area
    if (adjustedX < 0 || adjustedY < 0 || adjustedX > displayWidth || adjustedY > displayHeight) {
      return;
    }

    final xPercent = adjustedX / displayWidth;
    final yPercent = adjustedY / displayHeight;

    ref
        .read(editorViewModelProvider.notifier)
        .addField(_selectedFieldType!, xPercent.clamp(0.0, 0.85), yPercent.clamp(0.0, 0.9));
    setState(() => _selectedFieldType = null);
  }

  void _showFieldInputDialog(FieldEntity field) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => FieldInputDialog(field: field),
    );

    if (result != null) {
      ref.read(editorViewModelProvider.notifier).updateFieldValue(field.id, result);
    }
  }

  void _toggleMode() {
    final editorNotifier = ref.read(editorViewModelProvider.notifier);
    final currentMode = ref.read(editorViewModelProvider).mode;

    if (currentMode == EditorMode.edit) {
      editorNotifier.enterSignMode();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview mode - Tap fields to test input'),
          backgroundColor: AppColors.info,
        ),
      );
    } else {
      editorNotifier.enterEditMode();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Edit mode - Drag fields to reposition'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  void _onPublish() async {
    final confirm = await showDialog<bool>(
      context: context,

      builder: (context) => AlertDialog(
        title: const Text('Publish Document?'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        content: const Text(
          'Once published, you cannot edit field positions.\n\nThe document will be ready for signing.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Publish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 16.h),
              const Text('Publishing document...'),
            ],
          ),
        ),
      );

      final success = await ref.read(editorViewModelProvider.notifier).publishDocument();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document published successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _onFinishSigning() async {
    final viewModel = ref.read(editorViewModelProvider.notifier);
    final missingIds = viewModel.validateFormSubmission();

    if (missingIds.isEmpty) {
      await viewModel.saveFields();
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _SigningCompleteDialog(
          onClose: () {
            Navigator.pop(dialogContext);
            Navigator.pop(context);
          },
          onDownloadPdf: () async {
            Navigator.pop(dialogContext);
            _generateAndShowPdf();
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${missingIds.length} required field(s) are missing!'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _generateAndShowPdf() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 16.h),
            const Text('Generating PDF...'),
          ],
        ),
      ),
    );

    final viewModel = ref.read(editorViewModelProvider.notifier);
    final file = await viewModel.generateFinalPdf();

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (file != null) {
      // Show success dialog with options
      showModalBottomSheet(
        context: context,
        builder: (ctx) => Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 24.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'PDF Generated!',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Saved to:',
                style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  file.path,
                  style: TextStyle(fontSize: 12.sp, fontFamily: 'monospace'),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context); // Go back to home
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        // Preview signed PDF
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => _PdfPreviewScreen(filePath: file.path)),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Preview'),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await SharePlus.instance.share(
                          ShareParams(files: [XFile(file.path)], subject: 'Signed - ${widget.document.name}'),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate PDF'), backgroundColor: AppColors.error),
      );
    }
  }
}

/// Dialog shown after signing is complete
class _SigningCompleteDialog extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onDownloadPdf;

  const _SigningCompleteDialog({required this.onClose, required this.onDownloadPdf});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Signing Complete'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 64.sp),
          SizedBox(height: 16.h),
          const Text('All required fields have been filled.'),
          SizedBox(height: 8.h),
          Text(
            'Download the signed PDF or close the document.',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: onClose, child: const Text('Close')),
        ElevatedButton.icon(
          onPressed: onDownloadPdf,
          icon: const Icon(Icons.download),
          label: const Text('Download PDF'),
        ),
      ],
    );
  }
}

/// Simple PDF Preview Screen
class _PdfPreviewScreen extends StatelessWidget {
  final String filePath;

  const _PdfPreviewScreen({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signed PDF Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
            },
          ),
        ],
      ),
      body: SfPdfViewer.file(File(filePath)),
    );
  }
}
