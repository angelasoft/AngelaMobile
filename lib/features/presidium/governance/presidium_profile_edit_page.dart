import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/korean_date.dart';
import 'presidium_profile.dart';

/// 4간부 전용: 설립일·승인일·주회합 요일/시간/장소·차수 보정값 입력.
class PresidiumProfileEditPage extends StatefulWidget {
  const PresidiumProfileEditPage({super.key, required this.profile});

  final PresidiumProfile profile;

  @override
  State<PresidiumProfileEditPage> createState() => _PresidiumProfileEditPageState();
}

class _PresidiumProfileEditPageState extends State<PresidiumProfileEditPage> {
  final _service = const PresidiumProfileService();
  late final TextEditingController _placeController;
  late final TextEditingController _offsetController;

  DateTime? _foundedDate;
  DateTime? _approvedDate;
  String? _meetingDay;
  TimeOfDay? _meetingTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _foundedDate = p.foundedDate;
    _approvedDate = p.approvedDate;
    _meetingDay = p.meetingDay;
    _meetingTime = p.meetingTime;
    _placeController = TextEditingController(text: p.meetingPlace ?? '');
    _offsetController =
        TextEditingController(text: p.meetingNumberOffset == 0 ? '' : '${p.meetingNumberOffset}');
  }

  @override
  void dispose() {
    _placeController.dispose();
    _offsetController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(1921),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _meetingTime ?? const TimeOfDay(hour: 19, minute: 30),
    );
    if (picked != null) setState(() => _meetingTime = picked);
  }

  Future<void> _save() async {
    final founded = _foundedDate;
    final approved = _approvedDate;
    if (founded != null && approved != null && approved.isBefore(founded)) {
      _showMessage('승인일은 설립일과 같거나 그 뒤여야 해요.');
      return;
    }
    final offsetText = _offsetController.text.trim();
    final offset = offsetText.isEmpty || offsetText == '-' ? 0 : int.tryParse(offsetText);
    if (offset == null) {
      _showMessage('보정값은 숫자로 입력해 주세요.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = await _service.save(
        foundedDate: founded,
        approvedDate: approved,
        meetingDay: _meetingDay,
        meetingTime: _meetingTime,
        meetingPlace: _placeController.text.trim(),
        meetingNumberOffset: offset,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMid,
      appBar: AppBar(title: const Text('쁘레시디움 정보 수정'), backgroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('설립·승인', [
            _pickerTile(
              icon: Icons.flag_outlined,
              label: '설립일',
              value: _foundedDate == null ? null : koreanFullDate(_foundedDate!),
              onTap: () async {
                final picked = await _pickDate(_foundedDate);
                if (picked != null) setState(() => _foundedDate = picked);
              },
              onClear: () => setState(() => _foundedDate = null),
            ),
            _divider(),
            _pickerTile(
              icon: Icons.verified_outlined,
              label: '승인일',
              value: _approvedDate == null ? null : koreanFullDate(_approvedDate!),
              onTap: () async {
                final picked = await _pickDate(_approvedDate ?? _foundedDate);
                if (picked != null) setState(() => _approvedDate = picked);
              },
              onClear: () => setState(() => _approvedDate = null),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              '승인일 이후 첫 회합 요일이 제1차 주회합이고, 매주 한 차씩 늘어요.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subtitle),
            ),
          ),
          const SizedBox(height: 20),
          _section('주회합', [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < meetingDayCodes.length; i++)
                    ChoiceChip(
                      label: Text(meetingDayLabels[i].substring(0, 1)),
                      selected: _meetingDay == meetingDayCodes[i],
                      onSelected: (selected) =>
                          setState(() => _meetingDay = selected ? meetingDayCodes[i] : null),
                    ),
                ],
              ),
            ),
            _pickerTile(
              icon: Icons.schedule,
              label: '시간',
              value: _meetingTime == null ? null : koreanTime(_meetingTime!),
              onTap: _pickTime,
              onClear: () => setState(() => _meetingTime = null),
            ),
            _divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                controller: _placeController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: '장소',
                  hintText: '예) 본당 교육관 2층',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _section('차수 보정', [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: TextField(
                controller: _offsetController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,4}')),
                ],
                decoration: const InputDecoration(
                  labelText: '보정값',
                  hintText: '0',
                  suffixText: '차',
                  prefixIcon: Icon(Icons.tune),
                ),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              '계산한 차수에 더해요. 앱을 쓰기 전 기록과 차수가 다르면 넣으세요 (빼려면 -).\n'
              '실제 차수만 알면 정보 화면의 "차수 맞추기"가 더 편해요.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subtitle),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.title,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required String? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent),
      title: Text(label),
      subtitle: Text(
        value ?? '선택하세요',
        style: TextStyle(color: value == null ? AppColors.subtitle : AppColors.title, fontWeight: FontWeight.w600),
      ),
      trailing: value == null
          ? const Icon(Icons.chevron_right)
          : IconButton(icon: const Icon(Icons.close, size: 18), tooltip: '지우기', onPressed: onClear),
      onTap: onTap,
    );
  }

  Widget _divider() => Divider(height: 1, indent: 16, color: AppColors.shadow.withValues(alpha: 0.08));
}
