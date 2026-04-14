class NotificationModel {
  final String notificationID;
  final String title;
  final String notificationMessage;
  final String notificationStatus;
  final String notificationType;
  final DateTime notificationTimestamp;

  NotificationModel({
    required this.notificationID,
    required this.title,
    required this.notificationMessage,
    String? notificationStatus,
    required this.notificationType,
    DateTime? notificationTimestamp,
  })  : notificationStatus = notificationStatus ?? 'unread',
        notificationTimestamp = notificationTimestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'notificationID': notificationID,
      'title': title,
      'notificationMessage': notificationMessage,
      'notificationStatus': notificationStatus,
      'notificationType': notificationType,
      'notificationTimestamp': notificationTimestamp.toIso8601String(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationID: json['notificationID'],
      title: json['title'],
      notificationMessage: json['notificationMessage'],
      notificationStatus: json['notificationStatus'],
      notificationType: json['notificationType'],
      notificationTimestamp: DateTime.parse(json['notificationTimestamp']),
    );
  }
}
