import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';

/// 처음 들어온 단원에게 쁘레시디움 가입·만들기 방법을 넘겨 보며 알려 준다.
abstract final class PresidiumGuide {
  static const _seenKey = 'guide.presidiumJoin.seen';
  static bool _showing = false;

  /// 아직 안 봤으면 한 번 보여 준다. 쁘레시디움·활동보고 탭이 함께 불러도 한 번만 뜬다.
  /// 마지막 장에서 「가입하러 가기」를 누르면 true.
  static Future<bool> showOnce(BuildContext context) async {
    if (_showing) return false;
    _showing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_seenKey) ?? false) return false;
      await prefs.setBool(_seenKey, true);
      if (!context.mounted) return false;
      return await open(context);
    } catch (e) {
      debugPrint('[PresidiumGuide] 가이드를 띄우지 못했습니다: $e');
      return false;
    } finally {
      _showing = false;
    }
  }

  /// 언제든 다시 보기. [showJoinButton] 이 false 면 마지막 장 버튼이 「닫기」.
  static Future<bool> open(BuildContext context, {bool showJoinButton = true}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PresidiumGuidePage(showJoinButton: showJoinButton),
      ),
    );
    return result ?? false;
  }
}

class PresidiumGuidePage extends StatefulWidget {
  const PresidiumGuidePage({super.key, this.showJoinButton = true});

  final bool showJoinButton;

  @override
  State<PresidiumGuidePage> createState() => _PresidiumGuidePageState();
}

class _PresidiumGuidePageState extends State<PresidiumGuidePage> {
  final _controller = PageController();
  int _page = 0;

  static const _steps = <_GuideStep>[
    _GuideStep(
      icon: Icons.waving_hand_outlined,
      title: '레지오마리애에 오신 걸 환영해요',
      body: '먼저 내가 속한 쁘레시디움(Pr)에 가입해 주세요.\n'
          '가입하면 단원들과 함께 활동보고, 주회합 출석부, 공지사항, 회계 보고를 쓸 수 있어요.',
      preview: _WelcomePreview(),
    ),
    _GuideStep(
      icon: Icons.church_outlined,
      label: '1단계',
      title: '소속 본당을 검색해요',
      body: '가입 화면 위쪽 「본당 이름 검색」에 본당 이름을 입력하고,\n검색 결과에서 내 본당을 눌러 주세요.',
      preview: _SearchPreview(),
    ),
    _GuideStep(
      icon: Icons.touch_app_outlined,
      label: '2단계',
      title: '내 쁘레시디움을 눌러 가입해요',
      body: '본당의 쁘레시디움이 「평의회(Cu) > 쁘레시디움(Pr)」 순서로 보여요.\n'
          '내 쁘레시디움을 누르고 확인하면 바로 가입돼요.',
      preview: _ListPreview(),
    ),
    _GuideStep(
      icon: Icons.add_circle_outline,
      label: '목록에 없다면',
      title: '새 쁘레시디움을 만들어요',
      body: '본당을 고른 뒤 아래쪽 「Pr 만들기」를 누르세요. 어른·소년소녀를 고르고, '
          '평의회(Cu)를 고르거나 새로 입력한 뒤 쁘레시디움(Pr) 이름을 넣으면 돼요.\n'
          '만든 사람이 단장이 되고, 다른 간부는 단원이 가입한 뒤 간부 이동 투표로 임명해요.',
      preview: _CreatePreview(),
    ),
    _GuideStep(
      icon: Icons.checklist_rounded,
      label: '가입한 뒤에는',
      title: '이렇게 시작해 보세요',
      body: '간부라면 설정 → 쁘레시디움 정보에서 승인일과 주회합 요일·시간을 먼저 입력해 주세요. '
          '그래야 주회합 차수와 출석부가 열려요.\n\n'
          '어른 쁘레시디움은 1곳, 소년소녀 쁘레시디움은 여러 곳에 가입할 수 있어요.',
      preview: _AfterJoinPreview(),
    ),
  ];

  bool get _isLast => _page == _steps.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      Navigator.of(context).pop(widget.showJoinButton);
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMid,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(_isLast ? '닫기' : '건너뛰기', style: const TextStyle(color: AppColors.subtitle)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => _GuideStepView(step: _steps[index]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _steps.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.accent : AppColors.accent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isLast ? (widget.showJoinButton ? '쁘레시디움 찾아 가입하기' : '확인') : '다음',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

class _GuideStep {
  const _GuideStep({required this.icon, this.label, required this.title, required this.body, required this.preview});

  final IconData icon;
  final String? label;
  final String title;
  final String body;
  final Widget preview;
}

class _GuideStepView extends StatelessWidget {
  const _GuideStepView({required this.step});

  final _GuideStep step;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.accentLight, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(step.icon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          if (step.label != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                step.label!,
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.title,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.subtitle, height: 1.6),
          ),
          const SizedBox(height: 24),
          step.preview,
        ],
      ),
    );
  }
}

/// 실제 화면을 본뜬 작은 미리보기 카드.
class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.shadow.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _WelcomePreview extends StatelessWidget {
  const _WelcomePreview();

  @override
  Widget build(BuildContext context) {
    Widget feature(IconData icon, String label) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: AppColors.accent),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: AppColors.title, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        );
    return _PreviewFrame(
      child: Row(
        children: [
          feature(Icons.edit_note, '활동보고'),
          feature(Icons.fact_check_outlined, '출석부'),
          feature(Icons.campaign_outlined, '공지사항'),
          feature(Icons.account_balance_wallet_outlined, '회계'),
        ],
      ),
    );
  }
}

class _SearchPreview extends StatelessWidget {
  const _SearchPreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundMid,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent, width: 1.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: AppColors.subtitle, size: 20),
                SizedBox(width: 8),
                Text('명동', style: TextStyle(color: AppColors.title, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _fakeRow(Icons.church_outlined, '명동 대성당', '서울대교구 · 중구', highlighted: true),
        ],
      ),
    );
  }
}

class _ListPreview extends StatelessWidget {
  const _ListPreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fakeRow(Icons.groups_outlined, '성모성심 Cu > 즐거움의 샘 Pr', null, highlighted: true),
          const SizedBox(height: 8),
          _fakeRow(Icons.groups_outlined, '성모성심 Cu > 평화의 모후 Pr', null),
          const SizedBox(height: 8),
          _fakeRow(Icons.groups_outlined, '샛별 Cu > 새싹 Pr', '소년소녀'),
        ],
      ),
    );
  }
}

class _CreatePreview extends StatelessWidget {
  const _CreatePreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fakeField('구분', '어른'),
          const SizedBox(height: 8),
          _fakeField('Cu 이름', '성모성심'),
          const SizedBox(height: 8),
          _fakeField('Pr 이름', '즐거움의 샘'),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text('Pr 만들기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AfterJoinPreview extends StatelessWidget {
  const _AfterJoinPreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fakeRow(Icons.info_outline, '쁘레시디움 정보', '승인일 · 주회합 요일·시간 입력', highlighted: true),
          const SizedBox(height: 8),
          _fakeRow(Icons.fact_check_outlined, '주회합 출석부', '회합 날 회합 시간부터 열려요'),
          const SizedBox(height: 8),
          _fakeRow(Icons.edit_note, '활동보고', '한 주 동안의 활동을 보고해요'),
        ],
      ),
    );
  }
}

Widget _fakeRow(IconData icon, String title, String? subtitle, {bool highlighted = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: highlighted ? AppColors.accent.withValues(alpha: 0.08) : AppColors.backgroundMid,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: highlighted ? AppColors.accent : Colors.transparent, width: 1.5),
    ),
    child: Row(
      children: [
        Icon(icon, color: highlighted ? AppColors.accent : AppColors.subtitle, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.title, fontWeight: FontWeight.w600, fontSize: 14)),
              if (subtitle != null)
                Text(subtitle, style: const TextStyle(color: AppColors.subtitle, fontSize: 12)),
            ],
          ),
        ),
        if (highlighted) const Icon(Icons.touch_app, color: AppColors.accent, size: 20),
      ],
    ),
  );
}

Widget _fakeField(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.backgroundMid,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.subtitle, fontSize: 11)),
        Text(value, style: const TextStyle(color: AppColors.title, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
