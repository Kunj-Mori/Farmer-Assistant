import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import '../services/chatbot_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<types.Message> _messages = [];
  final ChatbotService _chatbotService = ChatbotService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addMessage(
      _chatbotService.getGreetingResponse(),
      types.User(id: 'bot'),
    );
  }

  void _addMessage(String text, types.User author) {
    final message = types.TextMessage(
      author: author,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().toString(),
      text: text,
    );

    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    final user = types.User(id: 'user');
    _addMessage(message.text, user);

    setState(() => _isLoading = true);

    try {
      String response = '';
      if (_chatbotService.isGreeting(message.text)) {
        response = _chatbotService.getGreetingResponse();
      } else {
        response = await _chatbotService.getChatbotResponse(message.text);
      }

      _addMessage(
        _chatbotService.formatResponse(response),
        types.User(id: 'bot'),
      );
    } catch (e) {
      _addMessage(
        'Sorry, I encountered an error. Please try again.',
        types.User(id: 'bot'),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 4),
          Expanded(
            child: Chat(
              messages: _messages,
              onSendPressed: _handleSendPressed,
              user: types.User(id: 'user'),
              theme: DefaultChatTheme(
                primaryColor: Theme.of(context).primaryColor,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                inputBackgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              customBottomWidget: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Ask me about farming...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            _handleSendPressed(
                              types.PartialText(text: text.trim()),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        // Handle send button press
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 