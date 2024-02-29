import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'settings.dart';
import 'chat_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key, required this.title})
      : super(
          key: key,
        );

  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final String _apiKey = '';
  GenerativeModel? model;
  late ChatSession chat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
          ),
          child: Text(
            widget.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 8.0,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.settings,
              ),
              onPressed: () {
                openSettingsPopup(context, _apiKey,
                    (String _) => _initializeGenerativeModel());
              },
            ),
          ),
        ],
      ),
      body:  const ChatWidget(),
    );
  }

  void _initializeGenerativeModel() {
    setState(() {
      model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: _apiKey,
      );
      chat = model!.startChat();
    });
  }
}
