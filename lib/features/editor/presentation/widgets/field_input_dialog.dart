import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/entities/field_entity.dart';
import '../../../../core/theme/app_colors.dart';

/// Dialog for inputting field values
class FieldInputDialog extends StatefulWidget {
  final FieldEntity field;

  const FieldInputDialog({super.key, required this.field});

  @override
  State<FieldInputDialog> createState() => _FieldInputDialogState();
}

class _FieldInputDialogState extends State<FieldInputDialog> with SingleTickerProviderStateMixin {
  late TextEditingController _textController;
  late TabController _tabController;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  bool _checkboxValue = false;
  DateTime? _selectedDate;
  Uint8List? _uploadedSignature;
  String? _uploadedFileName;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize values based on field type
    if (widget.field.type == FieldType.text) {
      _textController.text = widget.field.value?.toString() ?? '';
    } else if (widget.field.type == FieldType.checkbox) {
      _checkboxValue = widget.field.value == true;
    } else if (widget.field.type == FieldType.date && widget.field.value != null) {
      try {
        _selectedDate = DateTime.parse(widget.field.value.toString());
      } catch (_) {
        _selectedDate = DateTime.now();
      }
    } else if (widget.field.type == FieldType.signature) {
      if (widget.field.value is String && !(widget.field.value as String).startsWith('BM')) {
        _textController.text = widget.field.value.toString();
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _signatureController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(_getFieldIcon(), color: _getFieldColor()),
          SizedBox(width: 8.w),
          Text(FieldEntity.getDisplayName(widget.field.type)),
        ],
      ),
      content: _buildContent(),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _onSubmit,
          style: ElevatedButton.styleFrom(backgroundColor: _getFieldColor()),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildContent() {
    double width = 300.w;

    switch (widget.field.type) {
      case FieldType.text:
        return SizedBox(width: width, child: _buildTextInput());
      case FieldType.signature:
        return SizedBox(
          width: width,
          height: 280.h,
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Type', icon: Icon(Icons.keyboard)),
                  Tab(text: 'Draw', icon: Icon(Icons.draw)),
                  Tab(text: 'Upload', icon: Icon(Icons.upload)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_buildSignatureTypeInput(), _buildSignatureDrawInput(), _buildSignatureUploadInput()],
                ),
              ),
            ],
          ),
        );
      case FieldType.checkbox:
        return SizedBox(width: width, child: _buildCheckboxInput());
      case FieldType.date:
        return SizedBox(width: width, child: _buildDateInput());
    }
  }

  Widget _buildTextInput() {
    return TextField(
      controller: _textController,
      decoration: InputDecoration(
        hintText: 'Enter text...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: _getFieldColor(), width: 2),
        ),
      ),
      autofocus: true,
      maxLines: 2,
    );
  }

  // Signature Tabs
  Widget _buildSignatureTypeInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: 'Type your name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          style: TextStyle(fontFamily: 'Cursive', fontSize: 24.sp, fontStyle: FontStyle.italic),
        ),
        SizedBox(height: 8.h),
        Text(
          'Your name will be converted to a signature style',
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSignatureDrawInput() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Signature(controller: _signatureController, height: 140.h, backgroundColor: Colors.grey.shade50),
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _signatureController.clear(),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignatureUploadInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_uploadedSignature != null)
          Column(
            children: [
              Container(
                height: 150.h,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Image.memory(_uploadedSignature!, fit: BoxFit.contain),
              ),
              SizedBox(height: 8.h),

              TextButton(
                onPressed: () => setState(() {
                  _uploadedSignature = null;
                  _uploadedFileName = null;
                }),
                child: const Text('Remove'),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 48.sp, color: AppColors.primary),
                  SizedBox(height: 8.h),
                  const Text('Tap to upload signature image'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _uploadedSignature = bytes;
        _uploadedFileName = image.name;
      });
    }
  }

  // Other Inputs matching original file
  Widget _buildCheckboxInput() {
    return StatefulBuilder(
      builder: (context, setState) {
        return CheckboxListTile(
          title: const Text('Check this box'),
          value: _checkboxValue,
          activeColor: _getFieldColor(),
          onChanged: (value) {
            setState(() => _checkboxValue = value ?? false);
          },
          controlAffinity: ListTileControlAffinity.leading,
        );
      },
    );
  }

  Widget _buildDateInput() {
    final displayDate = _selectedDate ?? DateTime.now();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('MMM dd, yyyy').format(displayDate), style: TextStyle(fontSize: 16.sp)),
              Icon(Icons.calendar_today, color: _getFieldColor()),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.edit_calendar),
            label: const Text('Change Date'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _onSubmit() async {
    dynamic result;

    switch (widget.field.type) {
      case FieldType.text:
        result = _textController.text.trim();
        if (result.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a value')));
          return;
        }
        break;

      case FieldType.signature:
        // Check active tab
        if (_tabController.index == 0) {
          // Type
          result = _textController.text.trim();
          if (result.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please type your name')));
            return;
          }
        } else if (_tabController.index == 1) {
          // Draw
          if (_signatureController.isNotEmpty) {
            final Uint8List? data = await _signatureController.toPngBytes();
            if (data != null) {
              result = data; // Return bytes
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please draw your signature')));
            return;
          }
        } else {
          // Upload
          if (_uploadedSignature != null) {
            result = _uploadedSignature; // Return bytes
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Please upload a signature image')));
            return;
          }
        }
        break;

      case FieldType.checkbox:
        result = _checkboxValue;
        break;

      case FieldType.date:
        final date = _selectedDate ?? DateTime.now();
        result = DateFormat('yyyy-MM-dd').format(date);
        break;
    }

    if (mounted) {
      Navigator.pop(context, result);
    }
  }

  IconData _getFieldIcon() {
    switch (widget.field.type) {
      case FieldType.signature:
        return Icons.draw;
      case FieldType.text:
        return Icons.text_fields;
      case FieldType.checkbox:
        return Icons.check_box;
      case FieldType.date:
        return Icons.calendar_today;
    }
  }

  Color _getFieldColor() {
    switch (widget.field.type) {
      case FieldType.signature:
        return Colors.blue;
      case FieldType.text:
        return Colors.green;
      case FieldType.checkbox:
        return Colors.orange;
      case FieldType.date:
        return Colors.purple;
    }
  }
}
