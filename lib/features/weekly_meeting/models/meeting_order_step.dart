/// 주 회합 순서 한 단계.
class MeetingOrderStep {
  const MeetingOrderStep({
    required this.order,
    required this.title,
    required this.summary,
    this.paragraphs = const [],
    this.bullets = const [],
  });

  final int order;
  final String title;
  final String summary;
  final List<String> paragraphs;
  final List<String> bullets;
}
