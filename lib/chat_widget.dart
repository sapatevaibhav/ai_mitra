// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({Key? key}) : super(key: key);

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  GenerativeModel? model;
  late ChatSession chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  bool _loading = false;
  String? _apiKey;
  List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    _getApiKey();
  }

  Future<void> _getApiKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final storedApiKey = prefs.getString('api_key');
    if (storedApiKey == null) {
      await DialogUtils.showApiKeyDialog(
        context,
        _apiKey,
        _setAndInitializeGenerativeModel,
      );
    } else {
      setState(() {
        _apiKey = storedApiKey;
      });
      _initializeGenerativeModel();
    }
  }

  void _setAndInitializeGenerativeModel(String apiKey) {
    setState(() {
      _apiKey = apiKey;
    });
    _initializeGenerativeModel();
  }

  void _initializeGenerativeModel() {
    setState(() {
      model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: _apiKey!,
      );
      chat = model!.startChat();
      _loadMessages();
    });
  }

  Future<void> _loadMessages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? messagesJson = prefs.getStringList('messages');

    if (messagesJson != null) {
      setState(() {
        messages = messagesJson
            .map((messageJson) => Message.fromJson(messageJson))
            .toList();
      });
    }
  }

  Future<void> _saveMessages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> messagesJson =
        messages.map((message) => message.toJson()).toList();

    await prefs.setStringList('messages', messagesJson);
  }

  @override
  Widget build(BuildContext context) {
    var textFieldDecoration = InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: 'Enter a prompt...',
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _apiKey != null && _apiKey!.isNotEmpty
                ? ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, idx) {
                      return MessageWidget(
                        message: messages[idx],
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      'No API key found. Please provide an API Key.',
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    focusNode: _textFieldFocus,
                    decoration: textFieldDecoration,
                    controller: _textController,
                    onSubmitted: (String value) {
                      _sendChatMessage(value);
                    },
                  ),
                ),
                const SizedBox.square(
                  dimension: 15,
                ),
                _loading
                    ? const CircularProgressIndicator()
                    : IconButton(
                        onPressed: () {
                          _sendChatMessage(_textController.text);
                        },
                        icon: Icon(
                          Icons.send,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendChatMessage(String message) async {
    setState(() {
      _loading = true;
    });

    try {
      var response = await chat.sendMessage(Content.text(message));
      var text = response.text;

      if (text == null) {
        _showError('No response from API.');
        return;
      } else {
        setState(() {
          _loading = false;
          messages.add(Message(sender: Sender.User, text: message));
          messages.add(Message(sender: Sender.Bot, text: text));
          _saveMessages();
        });
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      _textController.clear();
      _textFieldFocus.requestFocus();
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                DialogUtils.showApiKeyDialog(
                    context, _apiKey, _setAndInitializeGenerativeModel);
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }
}

class MessageWidget extends StatelessWidget {
  final Message message;

  const MessageWidget({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUserMessage = message.sender == Sender.User;
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isUserMessage
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isUserMessage ? 18 : 0),
            topRight: Radius.circular(isUserMessage ? 0 : 18),
            bottomLeft: const Radius.circular(18),
            bottomRight: const Radius.circular(18),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: MarkdownBody(
              selectable: true,
              data: message.text,
              styleSheet: isUserMessage
                  ? MarkdownStyleSheet(p: const TextStyle())
                  : MarkdownStyleSheet(
                      p: const TextStyle(),
                    )),
        ),
      ),
    );
  }
}

enum Sender {
  User,
  Bot,
}

class Message {
  final Sender sender;
  final String text;

  Message({
    required this.sender,
    required this.text,
  });

  String toJson() {
    return jsonEncode({
      'sender': sender.index,
      'text': text,
    });
  }

  factory Message.fromJson(String json) {
    final Map<String, dynamic> map = jsonDecode(json);
    return Message(
      sender: Sender.values[map['sender']],
      text: map['text'],
    );
  }
}
