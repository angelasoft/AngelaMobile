import '../../core/network/api_client.dart';

/// 앱 알림함의 알림 한 건.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.targetId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      targetId: json['targetId'] as int?,
      isRead: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }

  final int id;

  /// MEMBERSHIP_REQUEST | MEMBERSHIP_REQUEST_RESULT | ELECTION_STARTED | ELECTION_RESULT | GRADE_CHANGED
  /// | OFFICER_TERM_ENDING
  final String type;
  final String title;
  final String message;
  final int? targetId;
  final bool isRead;
  final DateTime createdAt;

  /// 간부 투표·임기 만료 알림은 간부 이동 화면을 연다.
  bool get isAboutElection =>
      type == 'ELECTION_STARTED' || type == 'ELECTION_RESULT' || type == 'OFFICER_TERM_ENDING';

  /// 쁘레또리움·아듀또리움 임명/해제 알림은 내용만 알리고 따로 열 화면이 없다.
  bool get isGradeChange => type == 'GRADE_CHANGED';
}

class NotificationService {
  const NotificationService({ApiClient client = const ApiClient()}) : _client = client;

  final ApiClient _client;

  Future<List<AppNotification>> fetchRecent() async {
    final list = await _client.get('/app/notifications') as List<dynamic>;
    return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> fetchUnreadCount() async {
    final json = await _client.get('/app/notifications/unread-count') as Map<String, dynamic>;
    return json['count'] as int? ?? 0;
  }

  Future<void> markRead(int id) => _client.post('/app/notifications/$id/read');

  Future<void> markAllRead() => _client.post('/app/notifications/read-all');
}
