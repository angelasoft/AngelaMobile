/// 본당 소속 큐리아.
class CuriaItem {
  const CuriaItem({required this.id, required this.name});

  factory CuriaItem.fromJson(Map<String, dynamic> json) {
    return CuriaItem(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  final int id;
  final String name;
}
