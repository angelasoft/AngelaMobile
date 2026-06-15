import 'gender.dart';
import 'social_provider.dart';

/// 활동수첩 회원가입 시 제출하는 정보.
///
/// 화면 확인 후 필드를 자유롭게 가감할 수 있도록 단순 DTO로 둔다.
class SignUpRequest {
  const SignUpRequest({
    required this.provider,
    required this.providerId,
    required this.email,
    required this.name,
    required this.baptismalName,
    required this.phoneNumber,
    required this.birthDate,
    required this.gender,
    required this.agreedTerms,
    required this.agreedPrivacy,
    this.agreedMarketing = false,
  });

  final SocialProvider provider;
  final String providerId;
  final String email;

  final String name;
  final String baptismalName;
  final String phoneNumber;
  final DateTime birthDate;
  final Gender gender;

  final bool agreedTerms;
  final bool agreedPrivacy;
  final bool agreedMarketing;

  Map<String, dynamic> toJson() => {
        'provider': provider.registrationId,
        'providerId': providerId,
        'email': email,
        'name': name,
        'baptismalName': baptismalName,
        'phoneNumber': phoneNumber,
        'birthDate': _formatDate(birthDate),
        'gender': gender.name,
        'agreedTerms': agreedTerms,
        'agreedPrivacy': agreedPrivacy,
        'agreedMarketing': agreedMarketing,
      };

  /// 백엔드 LocalDate 파싱용 yyyy-MM-dd 형식.
  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
