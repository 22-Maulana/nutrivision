import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../models/chat_message.dart';

class ChatbotState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String currentProfile;

  ChatbotState({
    required this.messages, 
    this.isLoading = false,
    this.currentProfile = 'Saya',
  });

  ChatbotState copyWith({
    List<ChatMessage>? messages, 
    bool? isLoading,
    String? currentProfile,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      currentProfile: currentProfile ?? this.currentProfile,
    );
  }
}

final chatbotProvider = StateNotifierProvider<ChatbotNotifier, ChatbotState>((ref) {
  return ChatbotNotifier();
});

class ChatbotNotifier extends StateNotifier<ChatbotState> {
  ChatbotNotifier() : super(ChatbotState(messages: [])) {
    _loadHistory();
  }

  static const String _historyKey = 'chat_history_v1';

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        final messages = decoded.map((m) => ChatMessage.fromJson(m)).toList();
        state = state.copyWith(messages: messages);
      } else {
        // Initial greeting if no history
        state = state.copyWith(
          messages: [
            ChatMessage(
              text: 'Halo Ibu! Saya NutriBot AI. Ada yang bisa saya bantu seputar gizi dan tumbuh kembang anak hari ini?',
              isUser: false,
              timestamp: _getCurrentTimestamp(),
            ),
          ],
        );
      }
    } catch (e) {
      print("Error loading chat history: $e");
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(state.messages.map((m) => m.toJson()).toList());
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      print("Error saving chat history: $e");
    }
  }

  String _getCurrentTimestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void setProfile(String profileName) {
    state = state.copyWith(currentProfile: profileName);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    state = state.copyWith(messages: []);
    _loadHistory();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final timeString = _getCurrentTimestamp();

    final userMessage = ChatMessage(text: text, isUser: true, timestamp: timeString);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );
    _saveHistory();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse(ApiConstants.chatbot),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': text,
          'target_profile': state.currentProfile,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botMessage = ChatMessage(
          text: data['reply'],
          isUser: false,
          timestamp: _getCurrentTimestamp(),
        );

        state = state.copyWith(
          messages: [...state.messages, botMessage],
          isLoading: false,
        );
        _saveHistory();
      } else {
        throw Exception('Gagal mendapatkan balasan dari AI Server.');
      }
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Maaf, terjadi gangguan koneksi. Pastikan server aktif.',
        isUser: false,
        timestamp: timeString,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }
}

