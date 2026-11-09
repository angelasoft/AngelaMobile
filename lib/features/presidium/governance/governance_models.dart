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

/// 날짜만 있는 "2026-01-07" (시간대 변환 없음).
DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  final parts = (value as String).split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

/// 쁘레시디움 단원.
class PresidiumMember {
  const PresidiumMember({
    required this.userId,
    required this.displayName,
    required this.grade,
    required this.gradeLabel,
    required this.officerRole,
    required this.officerLabel,
    this.officerAppointedDate,
    this.officerTermMonths,
    this.officerTermLabel,
    this.officerTermEndDate,
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
      officerAppointedDate: _parseDate(json['officerAppointedDate']),
      officerTermMonths: json['officerTermMonths'] as int?,
      officerTermLabel: json['officerTermLabel'] as String?,
      officerTermEndDate: _parseDate(json['officerTermEndDate']),
      isMe: json['me'] as bool? ?? false,
    );
  }

  final int userId;
  final String displayName;
  final String grade;
  final String gradeLabel;
  final String? officerRole;
  final String? officerLabel;

  /// 간부 임명일·임기. 4간부가 입력하기 전이면 null.
  final DateTime? officerAppointedDate;
  final int? officerTermMonths;

  /// "3년 0개월"
  final String? officerTermLabel;

  /// 임기 마지막 날.
  final DateTime? officerTermEndDate;
  final bool isMe;

  /// 임기 마지막 날까지 한 달이 안 남았거나 이미 지났다 (서버가 간부 이동 알림을 보내는 기준).
  bool isTermEndingBy(DateTime today) {
    final end = officerTermEndDate;
    if (end == null) return false;
    final noticeFrom = DateTime(end.year, end.month - 1, end.day);
    return !DateTime(today.year, today.month, today.day).isBefore(noticeFrom);
  }

  /// 행동단원 갈래(행동단원·쁘레또리움 단원): 간부 투표에 참여하고 간부 후보가 될 수 있다.
  bool get isActive => grade == 'ACTIVE' || grade == 'PRAETORIAN';

  /// 단장이 임명한 높은 등급(쁘레또리움·아듀또리움 단원).
  bool get isHigherDegree => grade == 'PRAETORIAN' || grade == 'ADJUTORIAN';

  /// 이 단원 갈래의 높은 등급 이름.
  String get higherDegreeLabel => isActive ? '쁘레또리움 단원' : '아듀또리움 단원';
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
    this.canAppoint = false,
    this.appointedDate,
    this.termLabel,
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
      canAppoint: json['canAppoint'] as bool? ?? false,
      appointedDate: _parseDate(json['appointedDate']),
      termLabel: json['termLabel'] as String?,
      closesAt: _parseTime(json['closesAt'])!,
      closedAt: _parseTime(json['closedAt']),
    );
  }

  final int id;
  final String positionLabel;
  final String candidateName;
  final String startedByName;

  /// OPEN | ELECTED(당선, 임명 대기) | APPOINTED | REJECTED | EXPIRED | CANCELED
  final String status;
  final int eligibleVoterCount;
  final int requiredVotes;
  final int yesCount;
  final int noCount;
  final bool? myVote;
  final bool canVote;

  /// 당선 뒤 4간부와 당선자 본인이 임명할 수 있다.
  final bool canAppoint;

  /// 임명할 때 정한 임명일과 임기 ("3년 0개월").
  final DateTime? appointedDate;
  final String? termLabel;
  final DateTime closesAt;
  final DateTime? closedAt;

  bool get isOpen => status == 'OPEN';

  bool get isElected => status == 'ELECTED';

  /// 투표 중이거나 임명을 기다리는 중.
  bool get isActive => isOpen || isElected;

  String get statusLabel => switch (status) {
        'OPEN' => '투표 중',
        'ELECTED' => '당선 · 임명 대기',
        'APPOINTED' => '임명',
        'REJECTED' => '부결',
        'EXPIRED' => '기한 만료',
        'CANCELED' => '취소',
        _ => status,
      };
}

/// 협조단원·행동단원·퇴단 신청과 활동 등록 요청.
class MembershipRequestItem {
  const MembershipRequestItem({
    required this.id,
    required this.type,
    required this.typeLabel,
    this.activityName,
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
      activityName: json['activityName'] as String?,
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

  /// AUXILIARY | ACTIVE | WITHDRAWAL | ACTIVITY
  final String type;
  final String typeLabel;

  /// 활동 등록 요청(ACTIVITY)일 때 등록할 활동 이름.
  final String? activityName;
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

  /// 활동 등록 요청은 등급 변경·퇴단 신청과 따로 진행된다.
  bool get isActivityProposal => type == 'ACTIVITY';

  /// 화면 표시용. 예: "협조단원 신청", "'본당 꽃꽂이' 활동 등록 요청"
  String get displayLabel => activityName == null ? typeLabel : "'$activityName' $typeLabel";

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
      if (r.isPending && !r.isActivityProposal) return r;
    }
    return null;
  }
}
