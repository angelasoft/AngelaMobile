import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'models/presidium_info.dart';
import 'presidium_join_page.dart';
import 'presidium_service.dart';
import 'widgets/presidium_header.dart';

class PresidiumPage extends StatefulWidget {
  const PresidiumPage({super.key});

  @override
  State<PresidiumPage> createState() => _PresidiumPageState();
}

class _PresidiumPageState extends State<PresidiumPage> {
  final _service = const PresidiumService();
  PresidiumInfo? _presidium;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyPresidium();
  }

  Future<void> _loadMyPresidium() async {
    try {
      final info = await _service.fetchMyPresidium();
      if (!mounted) return;
      setState(() {
        _presidium = info;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onJoinTap() async {
    final joined = await Navigator.of(context).push<PresidiumInfo>(
      MaterialPageRoute(builder: (_) => const PresidiumJoinPage()),
    );
    if (!mounted || joined == null) return;
    setState(() => _presidium = joined);
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_presidium == null) {
      return _EmptyPresidiumBody(onJoinTap: _onJoinTap);
    }
    return _JoinedPresidiumBody(presidium: _presidium!);
  }

  void _onSettingsTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('쁘레시디움 설정 (구현 예정)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundMid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PresidiumHeader(
            presidium: _presidium,
            onSettingsTap: _onSettingsTap,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}

class _EmptyPresidiumBody extends StatelessWidget {
  const _EmptyPresidiumBody({required this.onJoinTap});

  final VoidCallback onJoinTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color: AppColors.accent.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 20),
            Text(
              '아직 가입한 쁘레시디움이 없어요',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.title,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '소속 쁘레시디움에 가입하고\n활동을 함께 기록해 보세요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.subtitle.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onJoinTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '쁘레시디움 가입',
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
    );
  }
}

class _JoinedPresidiumBody extends StatelessWidget {
  const _JoinedPresidiumBody({required this.presidium});

  final PresidiumInfo presidium;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '${presidium.name} 콘텐츠 (구현 예정)',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.subtitle,
            ),
      ),
    );
  }
}
