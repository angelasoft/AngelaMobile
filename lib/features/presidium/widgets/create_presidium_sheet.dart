import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/curia_item.dart';
import '../models/parish_summary.dart';
import '../models/presidium_info.dart';
import '../presidium_service.dart';

/// Pr 만들기 바텀시트. 생성 성공 시 만든 사람이 단장으로 가입된 [PresidiumInfo]를 반환한다.
Future<PresidiumInfo?> showCreatePresidiumSheet({
  required BuildContext context,
  required ParishSummary parish,
  required List<CuriaItem> curias,
  PresidiumService service = const PresidiumService(),
}) {
  return showModalBottomSheet<PresidiumInfo?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CreatePresidiumSheet(
      parish: parish,
      curias: curias,
      service: service,
    ),
  );
}

class _CreatePresidiumSheet extends StatefulWidget {
  const _CreatePresidiumSheet({
    required this.parish,
    required this.curias,
    required this.service,
  });

  final ParishSummary parish;
  final List<CuriaItem> curias;
  final PresidiumService service;

  @override
  State<_CreatePresidiumSheet> createState() => _CreatePresidiumSheetState();
}

class _CreatePresidiumSheetState extends State<_CreatePresidiumSheet> {
  final _nameController = TextEditingController();
  final _newCuriaController = TextEditingController();

  int? _selectedCuriaId;
  bool _useNewCuria = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _useNewCuria = widget.curias.isEmpty;
    if (widget.curias.isNotEmpty) {
      _selectedCuriaId = widget.curias.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newCuriaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Pr 이름을 입력해 주세요.');
      return;
    }

    if (!_useNewCuria && _selectedCuriaId == null) {
      _showMessage('Cu를 선택해 주세요.');
      return;
    }

    if (_useNewCuria && _newCuriaController.text.trim().isEmpty) {
      _showMessage('Cu 이름을 입력해 주세요.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final joined = await widget.service.createPresidium(
        parishId: widget.parish.id,
        curiaId: _useNewCuria ? null : _selectedCuriaId,
        curiaName: _useNewCuria ? _newCuriaController.text.trim() : null,
        name: name,
      );
      if (!mounted) return;
      Navigator.of(context).pop(joined);
    } on PresidiumServiceException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('쁘레시디움 생성에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          // 키보드가 올라와 높이가 부족해도 잘리지 않고 스크롤되도록 한다.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.shadow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Pr 만들기',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.title,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.parish.displayLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.subtitle,
                      ),
                ),
                const SizedBox(height: 20),
                if (widget.curias.isNotEmpty) ...[
                  Text(
                    'Cu',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.title,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _useNewCuria ? null : _selectedCuriaId,
                    decoration: _fieldDecoration('기존 Cu 선택'),
                    items: [
                      for (final c in widget.curias)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: _useNewCuria
                        ? null
                        : (v) => setState(() => _selectedCuriaId = v),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('새 Cu 만들기'),
                    value: _useNewCuria,
                    activeThumbColor: AppColors.accent,
                    onChanged: (v) => setState(() => _useNewCuria = v),
                  ),
                ],
                if (_useNewCuria || widget.curias.isEmpty) ...[
                  Text(
                    'Cu 이름',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.title,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newCuriaController,
                    decoration: _fieldDecoration('예: 황금궁전'),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Pr 이름',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.title,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: _fieldDecoration('예: 즐거움의 샘'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '만들기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.backgroundMid,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
