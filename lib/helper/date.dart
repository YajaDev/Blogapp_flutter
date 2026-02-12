class Date {
  static String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();

    final difference = now.difference(date);
    final seconds = difference.inSeconds;

    if (seconds < 60) return "just now";
    if (seconds < 3600) return "${difference.inMinutes}m ago";
    if (seconds < 86400) return "${difference.inHours}h ago";

    return "${difference.inDays}d ago";
  }
}
