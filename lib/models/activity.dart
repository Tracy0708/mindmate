import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String activityID;
  final String userID;
  final String? linkedEmotionLogID;
  final String title;
  final String description;
  final String activityType;
  final String activityStatus;
  final String activityNotes;
  final DateTime completionTime;
  final Duration duration;

  Activity({
    required this.activityID,
    required this.userID,
    this.linkedEmotionLogID,
    required this.title,
    this.description = '',
    required this.activityType,
    String? activityStatus,
    this.activityNotes = '',
    DateTime? completionTime,
    Duration? duration,
  })  : activityStatus = activityStatus ?? 'pending',
        completionTime = completionTime ?? DateTime.now(),
        duration = duration ?? const Duration();

  Activity copyWith({
    String? activityStatus,
    String? activityNotes,
    DateTime? completionTime,
    Duration? duration,
  }) {
    return Activity(
      activityID: activityID,
      userID: userID,
      linkedEmotionLogID: linkedEmotionLogID,
      title: title,
      description: description,
      activityType: activityType,
      activityStatus: activityStatus ?? this.activityStatus,
      activityNotes: activityNotes ?? this.activityNotes,
      completionTime: completionTime ?? this.completionTime,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activityID': activityID,
      'userID': userID,
      'linkedEmotionLogID': linkedEmotionLogID,
      'title': title,
      'description': description,
      'activityType': activityType,
      'activityStatus': activityStatus,
      'activityNotes': activityNotes,
      'completionTime': Timestamp.fromDate(completionTime),
      'duration': duration.inSeconds,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map, String id) {
    return Activity(
      activityID: id,
      userID: map['userID'] ?? '',
      linkedEmotionLogID: map['linkedEmotionLogID'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      activityType: map['activityType'] ?? '',
      activityStatus: map['activityStatus'],
      activityNotes: map['activityNotes'] ?? '',
      completionTime: map['completionTime'] is Timestamp
          ? (map['completionTime'] as Timestamp).toDate()
          : DateTime.now(),
      duration: Duration(seconds: map['duration'] ?? 0),
    );
  }
}
