import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/chatbot_session.dart';
import '../models/ai_assistant.dart';

/// Result of sending a chatbot message: the AI text plus any metadata the UI
/// needs that isn't stored on the persisted message.
class ChatbotReply {
  final String response;
  final bool crisisDetected;

  const ChatbotReply({required this.response, this.crisisDetected = false});
}

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
      userID: userID,
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

  // Send a message and get an AI response. The displayed bot text is saved to
  // Firestore and surfaced via the session stream; this returns the metadata the
  // UI needs that isn't persisted on the message (e.g. crisis detection).
  Future<ChatbotReply> sendMessage({
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

    // 2. Call Gemini via Firebase Cloud Function
    final callable = FirebaseFunctions.instance.httpsCallable(
      'getChatbotResponse',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
    );
    final result = await callable.call({'sessionId': sessionID, 'message': content});
    final String botResponse = result.data['response'] as String;
    final bool crisisDetected = result.data['crisisDetected'] == true;

    // 3. Save bot response to Firestore
    final botMessage = {
      'content': botResponse,
      'timestamp': DateTime.now().toIso8601String(),
      'isUser': false,
    };

    await _firestore.collection(_sessionsCollection).doc(sessionID).update({
      'messages': FieldValue.arrayUnion([botMessage]),
    });

    return ChatbotReply(response: botResponse, crisisDetected: crisisDetected);
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
