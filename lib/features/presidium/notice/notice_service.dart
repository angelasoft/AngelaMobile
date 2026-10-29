import '../../../core/network/api_client.dart';

/// 공지사항 한 건.
class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      createdByName: json['createdByName'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    );
  }

  final int id;
  final String title;
  final String content;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEdited => updatedAt.difference(createdAt).inSeconds > 1;
}

class NoticePage {
  const NoticePage(this.items, this.hasNext);

  final List<Notice> items;
  final bool hasNext;
}

class NoticeService {
  const NoticeService({ApiClient client = const ApiClient()}) : _client = client;

  final ApiClient _client;

  static const _base = '/app/presidiums/me/notices';

  /// 최신순. 홈 카드는 page 0, size 3.
  Future<NoticePage> fetchPage({required int page, int size = 20}) async {
    final json = await _client.get('$_base?page=$page&size=$size') as Map<String, dynamic>;
    final items = (json['items'] as List<dynamic>)
        .map((e) => Notice.fromJson(e as Map<String, dynamic>))
        .toList();
    return NoticePage(items, json['hasNext'] as bool? ?? false);
  }

  Future<Notice> create({required String title, required String content}) async {
    final json = await _client.post(_base, {'title': title, 'content': content});
    return Notice.fromJson(json as Map<String, dynamic>);
  }

  Future<Notice> update(int id, {required String title, required String content}) async {
    final json = await _client.put('$_base/$id', {'title': title, 'content': content});
    return Notice.fromJson(json as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete('$_base/$id');
}
