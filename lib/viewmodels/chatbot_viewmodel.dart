import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/chatbot_session.dart';
import '../services/chatbot_service.dart';

class ChatbotViewModel extends ChangeNotifier {
  final ChatbotService _chatbotService = ChatbotService();
  
  ChatbotSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;
  // True once the AI has flagged crisis language in this session. Stays on so
  // the crisis support card remains visible until a new session starts.
  bool _crisisActive = false;

  ChatbotSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get crisisActive => _crisisActive;

  Future<void> startNewSession(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    _crisisActive = false;
    notifyListeners();

    try {
      _currentSession = await _chatbotService.startSession(
        userID: userId,
        assistantID: 'default_ai_assistant',
      );
    } catch (e) {
      _errorMessage = "Failed to start chat: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String userId, String text) async {
    if (_currentSession == null || text.trim().isEmpty) return;
    
    final sessionId = _currentSession!.sessionID;
    
    try {
      _isLoading = true;
      notifyListeners();

      final reply = await _chatbotService.sendMessage(
        sessionID: sessionId,
        content: text.trim(),
        userID: userId,
      );
      if (reply.crisisDetected) _crisisActive = true;
    } catch (e) {
      // Keep the on-screen message short and friendly; log the full error for debugging.
      developer.log('sendMessage failed: $e', name: 'ChatbotVM');
      _errorMessage =
          "MindMate AI couldn't respond just now. Please check your connection and try again.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<ChatbotSession> getSessionMessages() {
    if (_currentSession == null) {
      return const Stream.empty();
    }
    return _chatbotService.getSessionMessages(_currentSession!.sessionID);
  }
}
