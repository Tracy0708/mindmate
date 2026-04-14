import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chatbot_session.dart';
import '../models/ai_assistant.dart';

class ChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _sessionsCollection = 'chatbot_sessions';
  final String _assistantsCollection = 'ai_assistants';

  // Start a new chat session
  Future<ChatbotSession> startSession({
    required String userID,
    required String assistantID,
  }) async {
    final docRef = _firestore.collection(_sessionsCollection).doc();

    final session = ChatbotSession(
      sessionID: docRef.id,
      startTime: DateTime.now(),
      assistantID: assistantID,
    );

    await docRef.set(session.toJson());
    return session;
  }

  // End a chat session
  Future<void> endSession(String sessionID) async {
    await _firestore.collection(_sessionsCollection).doc(sessionID).update({
      'endTime': DateTime.now().toIso8601String(),
    });
  }

  // Send a message and get response from Dialogflow
  Future<String> sendMessage({
    required String sessionID,
    required String content,
    required String userID,
  }) async {
    // 1. Save user message to Firestore
    final userMessage = {
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
      'isUser': true,
    };

    await _firestore.collection(_sessionsCollection).doc(sessionID).update({
      'messages': FieldValue.arrayUnion([userMessage]),
    });

    // 2. Call Dialogflow API (Simulated since not set up)
    // Note: Actual implementation would use http or a dialogflow package here.
    await Future.delayed(const Duration(seconds: 1)); // Network simulation
    String botResponse = "I'm a virtual assistant. (Dialogflow integration pending)";
    if (content.toLowerCase().contains("stressed")) {
      botResponse = "It sounds like you're feeling stressed. Would you like to try a breathing exercise?";
    }

    // 3. Save bot response to Firestore
    final botMessage = {
      'content': botResponse,
      'timestamp': DateTime.now().toIso8601String(),
      'isUser': false,
    };

    await _firestore.collection(_sessionsCollection).doc(sessionID).update({
      'messages': FieldValue.arrayUnion([botMessage]),
    });

    return botResponse;
  }

  // Get all messages for a session
  Stream<ChatbotSession> getSessionMessages(String sessionID) {
    return _firestore
        .collection(_sessionsCollection)
        .doc(sessionID)
        .snapshots()
        .map((doc) => ChatbotSession.fromJson(doc.data()!));
  }

  // Get all active AI assistants
  Stream<List<AIAssistant>> getActiveAssistants() {
    return _firestore
        .collection(_assistantsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AIAssistant.fromJson(doc.data()))
          .toList();
    });
  }

  // Link an emotion log to a session
  Future<void> linkEmotionLog({
    required String sessionID,
    required String emotionLogID,
  }) async {
    await _firestore.collection(_sessionsCollection).doc(sessionID).update({
      'emotionLogRefs': FieldValue.arrayUnion([
        {
          'emotionLogID': emotionLogID,
          'timestamp': DateTime.now().toIso8601String()
        }
      ]),
    });
  }

  // Get user's recent sessions
  Stream<List<ChatbotSession>> getUserRecentSessions(String userID,
      {int limit = 10}) {
    return _firestore
        .collection(_sessionsCollection)
        .orderBy('startTime', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatbotSession.fromJson(doc.data()))
          .toList();
    });
  }

  // Get session summary
  Future<Map<String, dynamic>> getSessionSummary(String sessionID) async {
    final doc =
        await _firestore.collection(_sessionsCollection).doc(sessionID).get();

    if (!doc.exists) {
      throw Exception('Session not found');
    }

    final session = ChatbotSession.fromJson(doc.data()!);
    final duration = session.endTime != null
        ? session.endTime!.difference(session.startTime)
        : DateTime.now().difference(session.startTime);

    return {
      'sessionID': session.sessionID,
      'duration': duration.inMinutes,
      'messageCount': session.messages.length,
      'emotionLogsCount': session.emotionLogRefs.length,
      'startTime': session.startTime.toIso8601String(),
      'endTime': session.endTime?.toIso8601String(),
    };
  }
}
