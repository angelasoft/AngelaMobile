/// 4간부 직책. 서버 값(code)과 화면 표시(label).
enum OfficerPosition {
  president('PRESIDENT', '단장'),
  vicePresident('VICE_PRESIDENT', '부단장'),
  secretary('SECRETARY', '서기'),
  treasurer('TREASURER', '회계');

  const OfficerPosition(this.code, this.label);

  final String code;
  final String label;

  static OfficerPosition? fromCode(String? code) {
    for (final p in values) {
      if (p.code == code) return p;
    }
    return null;
  }
}

DateTime? _parseTime(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toLocal();

/// 쁘레시디움 단원.
class PresidiumMember {
  const PresidiumMember({
    required this.userId,
    required this.displayName,
    required this.grade,
    required this.gradeLabel,
    required this.officerRole,
    required this.officerLabel,
    required this.isMe,
  });

  factory PresidiumMember.fromJson(Map<String, dynamic> json) {
    return PresidiumMember(
      userId: json['userId'] as int,
      displayName: json['displayName'] as String,
      grade: json['grade'] as String,
      gradeLabel: json['gradeLabel'] as String,
      officerRole: json['officerRole'] as String?,
      officerLabel: json['officerLabel'] as String?,
      isMe: json['me'] as bool? ?? false,
    );
  }

  final int userId;
  final String displayName;
  final String grade;
  final String gradeLabel;
  final String? officerRole;
  final String? officerLabel;
  final bool isMe;

  bool get isActive => grade == 'ACTIVE';
}

/// 간부 이동 투표.
class OfficerElectionItem {
  const OfficerElectionItem({
    required this.id,
    required this.positionLabel,
    required this.candidateName,
    required this.startedByName,
    required this.status,
    required this.eligibleVoterCount,
    required this.requiredVotes,
    required this.yesCount,
    required this.noCount,
    required this.myVote,
    required this.canVote,
    required this.closesAt,
    required this.closedAt,
  });

  factory OfficerElectionItem.fromJson(Map<String, dynamic> json) {
    return OfficerElectionItem(
      id: json['id'] as int,
      positionLabel: json['positionLabel'] as String,
      candidateName: json['candidateName'] as String,
      startedByName: json['startedByName'] as String,
      status: json['status'] as String,
      eligibleVoterCount: json['eligibleVoterCount'] as int,
      requiredVotes: json['requiredVotes'] as int,
      yesCount: json['yesCount'] as int,
      noCount: json['noCount'] as int,
      myVote: json['myVote'] as bool?,
      canVote: json['canVote'] as bool? ?? false,
      closesAt: _parseTime(json['closesAt'])!,
      closedAt: _parseTime(json['closedAt']),
    );
  }

  final int id;
  final String positionLabel;
  final String candidateName;
  final String startedByName;

  /// OPEN | APPOINTED | REJECTED | EXPIRED | CANCELED
  final String status;
  final int eligibleVoterCount;
  final int requiredVotes;
  final int yesCount;
  final int noCount;
  final bool? myVote;
  final bool canVote;
  final DateTime closesAt;
  final DateTime? closedAt;

  bool get isOpen => status == 'OPEN';

  String get statusLabel => switch (status) {
        'OPEN' => '투표 중',
        'APPOINTED' => '임명',
        'REJECTED' => '부결',
        'EXPIRED' => '기한 만료',
        'CANCELED' => '취소',
        _ => status,
      };
}

/// 협조단원·퇴단 신청.
class MembershipRequestItem {
  const MembershipRequestItem({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.requesterName,
    required this.status,
    required this.officerCount,
    required this.requiredApprovals,
    required this.approveCount,
    required this.rejectCount,
    required this.myDecision,
    required this.canDecide,
    required this.createdAt,
  });

  factory MembershipRequestItem.fromJson(Map<String, dynamic> json) {
    return MembershipRequestItem(
      id: json['id'] as int,
      type: json['type'] as String,
      typeLabel: json['typeLabel'] as String,
      requesterName: json['requesterName'] as String,
      status: json['status'] as String,
      officerCount: json['officerCount'] as int,
      requiredApprovals: json['requiredApprovals'] as int,
      approveCount: json['approveCount'] as int,
      rejectCount: json['rejectCount'] as int,
      myDecision: json['myDecision'] as bool?,
      canDecide: json['canDecide'] as bool? ?? false,
      createdAt: _parseTime(json['createdAt'])!,
    );
  }

  final int id;

  /// AUXILIARY | WITHDRAWAL
  final String type;
  final String typeLabel;
  final String requesterName;

  /// PENDING | APPROVED | REJECTED | CANCELED
  final String status;
  final int officerCount;
  final int requiredApprovals;
  final int approveCount;
  final int rejectCount;
  final bool? myDecision;
  final bool canDecide;
  final DateTime createdAt;

  bool get isPending => status == 'PENDING';

  String get statusLabel => switch (status) {
        'PENDING' => '승인 대기',
        'APPROVED' => '승인',
        'REJECTED' => '반려',
        'CANCELED' => '취소',
        _ => status,
      };
}

/// 승인 요청 화면 데이터. 간부에게는 승인 대기 목록, 모두에게는 내 신청 내역.
class MembershipRequestsOverview {
  const MembershipRequestsOverview({
    required this.isOfficer,
    required this.pendingApprovals,
    required this.myRequests,
  });

  factory MembershipRequestsOverview.fromJson(Map<String, dynamic> json) {
    List<MembershipRequestItem> parse(String key) => (json[key] as List<dynamic>)
        .map((e) => MembershipRequestItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return MembershipRequestsOverview(
      isOfficer: json['officer'] as bool? ?? false,
      pendingApprovals: parse('pendingApprovals'),
      myRequests: parse('myRequests'),
    );
  }

  final bool isOfficer;
  final List<MembershipRequestItem> pendingApprovals;
  final List<MembershipRequestItem> myRequests;

  MembershipRequestItem? get myPendingRequest {
    for (final r in myRequests) {
      if (r.isPending) return r;
    }
    return null;
  }
}
