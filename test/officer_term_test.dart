import 'package:angelamobile/features/presidium/governance/governance_models.dart';
import 'package:angelamobile/features/presidium/governance/officer_term_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('임기 마지막 날은 서버와 같이 계산한다', () {
    expect(OfficerTerm(appointedDate: DateTime(2026, 1, 7), years: 3, months: 0).endDate, DateTime(2029, 1, 6));
    expect(OfficerTerm(appointedDate: DateTime(2024, 3, 1), years: 3, months: 0).endDate, DateTime(2027, 2, 28));
    // 1/31 + 1개월 = 2/29 (말일로 맞춤), 그 전날.
    expect(OfficerTerm(appointedDate: DateTime(2024, 1, 31), years: 0, months: 1).endDate, DateTime(2024, 2, 28));
    expect(OfficerTerm(appointedDate: DateTime(2025, 6, 15), years: 1, months: 6).endDate, DateTime(2026, 12, 14));
  });

  test('간부 임기와 만료 임박을 읽는다', () {
    final officer = PresidiumMember.fromJson({
      'userId': 1,
      'displayName': '박우석(유스티노)',
      'grade': 'ACTIVE',
      'gradeLabel': '행동단원',
      'officerRole': 'PRESIDENT',
      'officerLabel': '단장',
      'officerAppointedDate': '2023-12-15',
      'officerTermMonths': 36,
      'officerTermLabel': '3년 0개월',
      'officerTermEndDate': '2026-12-14',
      'me': true,
    });

    expect(officer.officerAppointedDate, DateTime(2023, 12, 15));
    expect(officer.officerTermLabel, '3년 0개월');
    expect(officer.isTermEndingBy(DateTime(2026, 11, 13)), isFalse);
    expect(officer.isTermEndingBy(DateTime(2026, 11, 14)), isTrue);
    expect(officer.isTermEndingBy(DateTime(2027, 1, 1)), isTrue);
  });

  test('당선 뒤 임명 대기 상태를 읽는다', () {
    final election = OfficerElectionItem.fromJson({
      'id': 9,
      'positionLabel': '부단장',
      'candidateName': '둘째',
      'startedByName': '단장',
      'status': 'ELECTED',
      'eligibleVoterCount': 3,
      'requiredVotes': 2,
      'yesCount': 2,
      'noCount': 0,
      'canVote': false,
      'canAppoint': true,
      'closesAt': '2026-11-16T10:00:00Z',
      'closedAt': '2026-11-09T10:00:00Z',
    });

    expect(election.isElected, isTrue);
    expect(election.isActive, isTrue);
    expect(election.canAppoint, isTrue);
    expect(election.statusLabel, '당선 · 임명 대기');
  });
}
