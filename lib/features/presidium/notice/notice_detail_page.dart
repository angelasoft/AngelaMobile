import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/korean_date.dart';
import 'notice_form_page.dart';
import 'notice_service.dart';

/// 공지 상세. 4간부는 수정·삭제할 수 있다. 변경이 있으면 true 를 돌려준다.
class NoticeDetailPage extends StatefulWidget {
  const NoticeDetailPage({super.key, required this.notice, required this.canManage});

  final Notice notice;
  final bool canManage;

  @override
  State<NoticeDetailPage> createState() => _NoticeDetailPageState();
}

class _NoticeDetailPageState extends State<NoticeDetailPage> {
  final _service = const NoticeService();

  late Notice _notice = widget.notice;
  bool _changed = false;
  bool _isDeleting = false;

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<Notice>(
      MaterialPageRoute(builder: (_) => NoticeFormPage(initial: _notice)),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _notice = updated;
      _changed = true;
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공지를 삭제할까요?'),
        content: Text('「${_notice.title}」\n삭제하면 되돌릴 수 없어요.'),
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
      await _service.delete(_notice.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('공지를 삭제했습니다.')));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _notice;
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundMid,
        appBar: AppBar(
          title: const Text('공지사항'),
          actions: [
            if (widget.canManage) ...[
              IconButton(onPressed: _isDeleting ? null : _edit, icon: const Icon(Icons.edit_outlined), tooltip: '수정'),
              IconButton(onPressed: _isDeleting ? null : _delete, icon: const Icon(Icons.delete_outline), tooltip: '삭제'),
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
                  Text(
                    n.title,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.title, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${n.createdByName} · ${koreanFullDate(n.createdAt)}${n.isEdited ? ' (수정됨)' : ''}',
                    style: TextStyle(color: AppColors.subtitle, fontSize: 13),
                  ),
                  const Divider(height: 28),
                  SelectableText(n.content, style: const TextStyle(color: AppColors.title, fontSize: 15, height: 1.7)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
