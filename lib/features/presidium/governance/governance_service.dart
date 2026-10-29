import '../../../core/network/api_client.dart';
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

  Future<MembershipRequestsOverview> fetchRequests() async {
    final json = await _client.get('$_base/requests');
    return MembershipRequestsOverview.fromJson(json as Map<String, dynamic>);
  }

  /// [type]: AUXILIARY(협조단원 신청) | WITHDRAWAL(퇴단 신청)
  Future<MembershipRequestItem> submitRequest(String type) async {
    final json = await _client.post('$_base/requests', {'type': type});
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
