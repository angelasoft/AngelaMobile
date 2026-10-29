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

  /// MEMBERSHIP_REQUEST | MEMBERSHIP_REQUEST_RESULT | ELECTION_STARTED | ELECTION_RESULT
  final String type;
  final String title;
  final String message;
  final int? targetId;
  final bool isRead;
  final DateTime createdAt;

  bool get isAboutElection => type == 'ELECTION_STARTED' || type == 'ELECTION_RESULT';
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
