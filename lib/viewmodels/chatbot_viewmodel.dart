import 'package:flutter/material.dart';
import '../models/chatbot_session.dart';
import '../services/chatbot_service.dart';

class ChatbotViewModel extends ChangeNotifier {
  final ChatbotService _chatbotService = ChatbotService();
  
  ChatbotSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;

  ChatbotSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> startNewSession(String userId) async {
    _isLoading = true;
    _errorMessage = null;
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
      
      await _chatbotService.sendMessage(
        sessionID: sessionId,
        content: text.trim(),
        userID: userId,
      );
    } catch (e) {
      _errorMessage = "Failed to send message: ${e.toString()}";
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
