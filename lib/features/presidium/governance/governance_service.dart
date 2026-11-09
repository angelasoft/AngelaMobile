import '../../../core/network/api_client.dart';
import '../../../core/widgets/korean_date.dart';
import 'governance_models.dart';

/// 내 쁘레시디움의 단원·간부 이동 투표·협조단원/퇴단 신청 API.
class GovernanceService {
  const GovernanceService({ApiClient client = const ApiClient()}) : _client = client;

  final ApiClient _client;

  static const _base = '/app/presidiums/me';

  Future<List<PresidiumMember>> fetchMembers() async {
    final list = await _client.get('$_base/members') as List<dynamic>;
    return list.map((e) => PresidiumMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<OfficerElectionItem>> fetchElections() async {
    final list = await _client.get('$_base/elections') as List<dynamic>;
    return list.map((e) => OfficerElectionItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<OfficerElectionItem> startElection({
    required OfficerPosition position,
    required int candidateUserId,
  }) async {
    final json = await _client.post('$_base/elections', {
      'position': position.code,
      'candidateUserId': candidateUserId,
    });
    return OfficerElectionItem.fromJson(json as Map<String, dynamic>);
  }

  Future<OfficerElectionItem> vote(int electionId, {required bool approve}) async {
    final json = await _client.post('$_base/elections/$electionId/votes', {'approve': approve});
    return OfficerElectionItem.fromJson(json as Map<String, dynamic>);
  }

  /// 당선자를 임명한다. 임명일은 오늘이나 지난 날짜, 임기는 년·개월 (3년이면 3년 0개월).
  Future<OfficerElectionItem> appoint(
    int electionId, {
    required DateTime appointedDate,
    required int termYears,
    required int termMonths,
  }) async {
    final json = await _client.post('$_base/elections/$electionId/appoint', {
      'appointedDate': isoDate(appointedDate),
      'termYears': termYears,
      'termMonths': termMonths,
    });
    return OfficerElectionItem.fromJson(json as Map<String, dynamic>);
  }

  /// 당선 뒤 임명하지 않기로 할 때 (4간부만).
  Future<OfficerElectionItem> cancelElected(int electionId) async {
    final json = await _client.post('$_base/elections/$electionId/cancel');
    return OfficerElectionItem.fromJson(json as Map<String, dynamic>);
  }

  /// 지금 간부의 임명일·임기 입력 (4간부만). 앱 도입 전 간부를 위해 지난 날짜도 된다.
  Future<PresidiumMember> updateOfficerTerm(
    int officerUserId, {
    required DateTime appointedDate,
    required int termYears,
    required int termMonths,
  }) async {
    final json = await _client.put('$_base/officers/$officerUserId/term', {
      'appointedDate': isoDate(appointedDate),
      'termYears': termYears,
      'termMonths': termMonths,
    });
    return PresidiumMember.fromJson(json as Map<String, dynamic>);
  }

  Future<MembershipRequestsOverview> fetchRequests() async {
    final json = await _client.get('$_base/requests');
    return MembershipRequestsOverview.fromJson(json as Map<String, dynamic>);
  }

  /// [type]: AUXILIARY(협조단원 신청) | ACTIVE(행동단원 신청) | WITHDRAWAL(퇴단 신청)
  Future<MembershipRequestItem> submitRequest(String type) async {
    final json = await _client.post('$_base/requests', {'type': type});
    return MembershipRequestItem.fromJson(json as Map<String, dynamic>);
  }

  /// 단장이 단원을 쁘레또리움(행동단원)·아듀또리움(협조단원) 단원으로 임명하거나([appoint] false 면) 해제한다.
  Future<PresidiumMember> changeHigherDegree(int memberUserId, {required bool appoint}) async {
    final json = await _client.post('$_base/members/$memberUserId/higher-degree', {'appoint': appoint});
    return PresidiumMember.fromJson(json as Map<String, dynamic>);
  }

  /// 활동보고 목록에 없는 활동 등록 요청. 4간부 과반이 승인하면 모든 쁘레시디움 목록에 추가된다.
  Future<MembershipRequestItem> requestActivity(String name) async {
    final json = await _client.post('$_base/requests', {'type': 'ACTIVITY', 'activityName': name});
    return MembershipRequestItem.fromJson(json as Map<String, dynamic>);
  }

  Future<MembershipRequestItem> decide(int requestId, {required bool approve}) async {
    final json = await _client.post('$_base/requests/$requestId/decision', {'approve': approve});
    return MembershipRequestItem.fromJson(json as Map<String, dynamic>);
  }

  Future<MembershipRequestItem> cancelRequest(int requestId) async {
    final json = await _client.post('$_base/requests/$requestId/cancel');
    return MembershipRequestItem.fromJson(json as Map<String, dynamic>);
  }
}
