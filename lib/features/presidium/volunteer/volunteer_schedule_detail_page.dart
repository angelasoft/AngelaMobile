import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/korean_date.dart';
import 'volunteer_schedule_form_page.dart';
import 'volunteer_service.dart';

/// 봉사 일정 상세. 4간부는 수정·삭제할 수 있다. 변경이 있으면 true 를 돌려준다.
class VolunteerScheduleDetailPage extends StatefulWidget {
  const VolunteerScheduleDetailPage({super.key, required this.schedule, required this.canManage});

  final VolunteerSchedule schedule;
  final bool canManage;

  @override
  State<VolunteerScheduleDetailPage> createState() => _VolunteerScheduleDetailPageState();
}

class _VolunteerScheduleDetailPageState extends State<VolunteerScheduleDetailPage> {
  final _service = const VolunteerService();

  late VolunteerSchedule _schedule = widget.schedule;
  bool _changed = false;
  bool _isDeleting = false;

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<VolunteerSchedule>(
      MaterialPageRoute(builder: (_) => VolunteerScheduleFormPage(initial: _schedule)),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _schedule = updated;
      _changed = true;
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('봉사 일정을 삭제할까요?'),
        content: Text('${_schedule.whenLabel} · ${_schedule.place}\n삭제하면 되돌릴 수 없어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD9534F)),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await _service.delete(_schedule.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('봉사 일정을 삭제했습니다.')));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _schedule;
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundMid,
        appBar: AppBar(
          title: const Text('봉사 상세'),
          actions: [
            if (widget.canManage) ...[
              IconButton(onPressed: _isDeleting ? null : _edit, icon: const Icon(Icons.edit_outlined), tooltip: '수정'),
              IconButton(
                onPressed: _isDeleting ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                tooltip: '삭제',
              ),
            ],
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(Icons.calendar_today_outlined, '날짜', koreanFullDate(s.date)),
                  _row(Icons.schedule, '시간', koreanTime(s.time)),
                  _row(Icons.place_outlined, '장소', s.place),
                  const Divider(height: 28),
                  Text('봉사 내용', style: TextStyle(color: AppColors.subtitle, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SelectableText(s.content, style: const TextStyle(color: AppColors.title, height: 1.6, fontSize: 15)),
                  if (s.createdByName.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('등록: ${s.createdByName}', style: TextStyle(color: AppColors.subtitle, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 10),
          SizedBox(width: 40, child: Text(label, style: TextStyle(color: AppColors.subtitle))),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.title, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
