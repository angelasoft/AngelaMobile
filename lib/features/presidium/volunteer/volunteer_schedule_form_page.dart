import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/korean_date.dart';
import 'volunteer_service.dart';

/// 봉사 일정 등록·수정. [initial] 이 있으면 수정. 저장한 일정을 돌려준다.
class VolunteerScheduleFormPage extends StatefulWidget {
  const VolunteerScheduleFormPage({super.key, this.initial});

  final VolunteerSchedule? initial;

  @override
  State<VolunteerScheduleFormPage> createState() => _VolunteerScheduleFormPageState();
}

class _VolunteerScheduleFormPageState extends State<VolunteerScheduleFormPage> {
  final _service = const VolunteerService();
  late final _placeController = TextEditingController(text: widget.initial?.place ?? '');
  late final _contentController = TextEditingController(text: widget.initial?.content ?? '');

  late DateTime? _date = widget.initial?.date;
  late TimeOfDay? _time = widget.initial?.time;
  bool _isSaving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    _placeController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final date = _date;
    final time = _time;
    final place = _placeController.text.trim();
    final content = _contentController.text.trim();
    final missing = [
      if (date == null) '날짜',
      if (time == null) '시간',
      if (place.isEmpty) '장소',
      if (content.isEmpty) '봉사 내용',
    ];
    if (missing.isNotEmpty) {
      _showMessage('${missing.join(', ')}을(를) 입력해 주세요.');
      return;
    }

    final input = VolunteerScheduleInput(date: date!, time: time!, place: place, content: content);
    setState(() => _isSaving = true);
    try {
      final saved = _isEdit
          ? await _service.update(widget.initial!.id, input)
          : await _service.create(input);
      if (!mounted) return;
      _showMessage(_isEdit ? '봉사 일정을 수정했습니다.' : '봉사 일정을 등록했습니다.');
      Navigator.of(context).pop(saved);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(e.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMid,
      appBar: AppBar(title: Text(_isEdit ? '봉사 수정' : '봉사 등록')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          _label('날짜'),
          _pickerField(
            icon: Icons.calendar_today_outlined,
            text: _date == null ? '날짜 선택' : koreanFullDate(_date!),
            isEmpty: _date == null,
            onTap: _pickDate,
          ),
          _label('시간'),
          _pickerField(
            icon: Icons.schedule,
            text: _time == null ? '시간 선택' : koreanTime(_time!),
            isEmpty: _time == null,
            onTap: _pickTime,
          ),
          _label('장소'),
          TextField(
            controller: _placeController,
            maxLength: 100,
            textInputAction: TextInputAction.next,
            decoration: _decoration('예: 효성동 성당 마당'),
          ),
          _label('봉사 내용'),
          TextField(
            controller: _contentController,
            maxLength: 1000,
            minLines: 5,
            maxLines: 10,
            decoration: _decoration('예: 본당 주변 환경 정리, 준비물: 장갑'),
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

  Widget _pickerField({
    required IconData icon,
    required String text,
    required bool isEmpty,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.accent),
              const SizedBox(width: 12),
              Text(text, style: TextStyle(color: isEmpty ? AppColors.subtitle : AppColors.title, fontSize: 15)),
            ],
          ),
        ),
      ),
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
