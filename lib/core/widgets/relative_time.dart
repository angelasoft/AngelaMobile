/// "방금 전", "5분 전", "3시간 전", "2일 전", 그 이상은 "10월 26일".
String relativeTime(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inHours < 1) return '${diff.inMinutes}분 전';
  if (diff.inDays < 1) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return '${time.month}월 ${time.day}일';
}

/// 투표 마감까지 남은 시간. 예: "2일 3시간 남음".
String remainingTime(DateTime deadline, {DateTime? now}) {
  final diff = deadline.difference(now ?? DateTime.now());
  if (diff.isNegative) return '마감';
  if (diff.inDays >= 1) return '${diff.inDays}일 ${diff.inHours % 24}시간 남음';
  if (diff.inHours >= 1) return '${diff.inHours}시간 남음';
  return '${diff.inMinutes}분 남음';
}
