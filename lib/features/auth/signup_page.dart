import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/angela_page_background.dart';
import 'auth_service.dart';
import 'models/gender.dart';
import 'models/oauth_identity.dart';
import 'data/agreement_documents.dart';
import 'models/sign_up_request.dart';
import 'widgets/agreement_sheet.dart';
import 'widgets/agreement_tile.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/gender_selector.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, required this.identity});

  /// 소셜 로그인에서 받은 본인 식별 정보 (폼 초기값).
  final OAuthIdentity identity;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _authService = const AuthService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  final _baptismalController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _birthDate;
  Gender? _gender;

  bool _showBirthError = false;
  bool _showGenderError = false;

  bool _agreedTerms = false;
  bool _agreedPrivacy = false;
  bool _agreedMarketing = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baptismalController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _agreedRequired => _agreedTerms && _agreedPrivacy;
  bool get _allAgreed => _agreedTerms && _agreedPrivacy && _agreedMarketing;

  void _toggleAll(bool value) {
    setState(() {
      _agreedTerms = value;
      _agreedPrivacy = value;
      _agreedMarketing = value;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: '생년월일 선택',
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _showBirthError = false;
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final formValid = _formKey.currentState?.validate() ?? false;
    final birthValid = _birthDate != null;
    final genderValid = _gender != null;

    setState(() {
      _showBirthError = !birthValid;
      _showGenderError = !genderValid;
    });

    if (!formValid || !birthValid || !genderValid) return;

    if (!_agreedRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관에 동의해 주세요.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final request = SignUpRequest(
      provider: widget.identity.provider,
      providerId: widget.identity.providerId,
      email: widget.identity.email,
      name: _nameController.text.trim(),
      baptismalName: _baptismalController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      birthDate: _birthDate!,
      gender: _gender!,
      agreedTerms: _agreedTerms,
      agreedPrivacy: _agreedPrivacy,
      agreedMarketing: _agreedMarketing,
    );

    try {
      await _authService.register(request);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입에 실패했습니다. 다시 시도해 주세요.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.title,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AngelaPageBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                _Header(provider: widget.identity.provider.label),
                const SizedBox(height: 24),
                AuthTextField(
                  label: '이메일',
                  initialValue: widget.identity.email,
                  enabled: false,
                  readOnly: true,
                  suffixIcon: Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: AppColors.subtitle.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: '이름',
                  controller: _nameController,
                  hintText: '실명을 입력하세요',
                  required: true,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '이름을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: '세례명',
                  controller: _baptismalController,
                  hintText: '예: 유스티노',
                  required: true,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '세례명을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: '휴대폰 번호',
                  controller: _phoneController,
                  hintText: '01012345678',
                  required: true,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return '휴대폰 번호를 입력해 주세요.';
                    if (value.length < 10) return '올바른 번호를 입력해 주세요.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: '생년월일',
                  readOnly: true,
                  required: true,
                  onTap: _pickBirthDate,
                  hintText: '생년월일 선택',
                  initialValue:
                      _birthDate == null ? null : _formatDate(_birthDate!),
                  key: ValueKey(_birthDate),
                  suffixIcon: Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppColors.subtitle.withValues(alpha: 0.7),
                  ),
                ),
                if (_showBirthError)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, top: 8),
                    child: Text(
                      '생년월일을 선택해 주세요.',
                      style: TextStyle(color: Color(0xFFD9534F), fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                GenderSelector(
                  value: _gender,
                  required: true,
                  errorText: _showGenderError ? '성별을 선택해 주세요.' : null,
                  onChanged: (g) => setState(() {
                    _gender = g;
                    _showGenderError = false;
                  }),
                ),
                const SizedBox(height: 24),
                _AgreementSection(
                  allAgreed: _allAgreed,
                  agreedTerms: _agreedTerms,
                  agreedPrivacy: _agreedPrivacy,
                  agreedMarketing: _agreedMarketing,
                  onToggleAll: _toggleAll,
                  onToggleTerms: (v) => setState(() => _agreedTerms = v),
                  onTogglePrivacy: (v) => setState(() => _agreedPrivacy = v),
                  onToggleMarketing: (v) => setState(() => _agreedMarketing = v),
                ),
                const SizedBox(height: 28),
                _SubmitButton(
                  isSubmitting: _isSubmitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}년 ${date.month}월 ${date.day}일';
}

class _Header extends StatelessWidget {
  const _Header({required this.provider});

  final String provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '활동수첩 회원가입',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.title,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '$provider 로그인이 확인되었어요.\n활동수첩 이용을 위해 기본 정보를 입력해 주세요.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.subtitle,
                height: 1.5,
              ),
        ),
      ],
    );
  }
}

class _AgreementSection extends StatelessWidget {
  const _AgreementSection({
    required this.allAgreed,
    required this.agreedTerms,
    required this.agreedPrivacy,
    required this.agreedMarketing,
    required this.onToggleAll,
    required this.onToggleTerms,
    required this.onTogglePrivacy,
    required this.onToggleMarketing,
  });

  final bool allAgreed;
  final bool agreedTerms;
  final bool agreedPrivacy;
  final bool agreedMarketing;
  final ValueChanged<bool> onToggleAll;
  final ValueChanged<bool> onToggleTerms;
  final ValueChanged<bool> onTogglePrivacy;
  final ValueChanged<bool> onToggleMarketing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.shadow.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          AgreementTile(
            value: allAgreed,
            onChanged: onToggleAll,
            label: '약관 전체 동의',
            emphasize: true,
          ),
          Divider(color: AppColors.shadow.withValues(alpha: 0.08), height: 8),
          AgreementTile(
            value: agreedTerms,
            onChanged: onToggleTerms,
            label: '서비스 이용약관 동의',
            required: true,
            onView: () => showAgreementSheet(context, AgreementType.terms),
          ),
          AgreementTile(
            value: agreedPrivacy,
            onChanged: onTogglePrivacy,
            label: '개인정보 수집·이용 동의',
            required: true,
            onView: () => showAgreementSheet(context, AgreementType.privacy),
          ),
          AgreementTile(
            value: agreedMarketing,
            onChanged: onToggleMarketing,
            label: '마케팅 정보 수신 동의',
            onView: () => showAgreementSheet(context, AgreementType.marketing),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isSubmitting, required this.onPressed});

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: isSubmitting ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                '가입 완료',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
