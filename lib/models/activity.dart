class Activity {
  final String activityID;
  final String title;
  final String activityType;
  final String activityStatus;
  final String activityNotes;
  final DateTime completionTime;
  final Duration duration;

  Activity({
    required this.activityID,
    required this.title,
    required this.activityType,
    String? activityStatus,
    this.activityNotes = '',
    DateTime? completionTime,
    Duration? duration,
  })  : activityStatus = activityStatus ?? 'pending',
        completionTime = completionTime ?? DateTime.now(),
        duration = duration ?? const Duration();

  Map<String, dynamic> toJson() {
    return {
      'activityID': activityID,
      'title': title,
      'activityType': activityType,
      'activityStatus': activityStatus,
      'activityNotes': activityNotes,
      'completionTime': completionTime.toIso8601String(),
      'duration': duration.inSeconds,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      activityID: json['activityID'],
      title: json['title'],
      activityType: json['activityType'],
      activityStatus: json['activityStatus'],
      activityNotes: json['activityNotes'] ?? '',
      completionTime: DateTime.parse(json['completionTime']),
      duration: Duration(seconds: json['duration'] ?? 0),
    );
  }
}
