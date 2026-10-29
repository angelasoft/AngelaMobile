import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import 'notice_service.dart';

/// 공지 등록·수정. [initial] 이 있으면 수정. 저장한 공지를 돌려준다.
class NoticeFormPage extends StatefulWidget {
  const NoticeFormPage({super.key, this.initial});

  final Notice? initial;

  @override
  State<NoticeFormPage> createState() => _NoticeFormPageState();
}

class _NoticeFormPageState extends State<NoticeFormPage> {
  final _service = const NoticeService();
  late final _titleController = TextEditingController(text: widget.initial?.title ?? '');
  late final _contentController = TextEditingController(text: widget.initial?.content ?? '');
  bool _isSaving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(title.isEmpty ? '제목을 입력해 주세요.' : '내용을 입력해 주세요.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saved = _isEdit
          ? await _service.update(widget.initial!.id, title: title, content: content)
          : await _service.create(title: title, content: content);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '공지를 수정했습니다.' : '공지를 등록했습니다.')),
      );
      Navigator.of(context).pop(saved);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMid,
      appBar: AppBar(title: Text(_isEdit ? '공지 수정' : '공지 등록')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          _label('제목'),
          TextField(
            controller: _titleController,
            maxLength: 100,
            textInputAction: TextInputAction.next,
            decoration: _decoration('예: 11월 정기 회합 안내'),
          ),
          _label('내용'),
          TextField(
            controller: _contentController,
            maxLength: 3000,
            minLines: 8,
            maxLines: 16,
            decoration: _decoration('공지할 내용을 입력해 주세요.'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(_isEdit ? '수정' : '등록', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
      child: Text(text, style: const TextStyle(color: AppColors.title, fontWeight: FontWeight.w600)),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}
