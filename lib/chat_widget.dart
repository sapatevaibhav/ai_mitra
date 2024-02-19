// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'utils.dart';
import 'message.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({Key? key}) : super(key: key);

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  late ScrollController _scrollController;
  GenerativeModel? model;
  late ChatSession chat;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  bool _loading = false;
  String? _apiKey;
  List<Message> messages = [];
  final SpeechToText _speech = SpeechToText();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _getApiKey();
    _initSpeech();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () {
              if (_speech.isAvailable) {
                _speech.listen(
                  onResult: (result) {
                    if (result.finalResult) {
                      setState(() {
                        _textController.text = result.recognizedWords;
                      });
                      _sendChatMessage(result.recognizedWords);
                    }
                  },
                  listenFor: const Duration(seconds: 5),
                );
              }
            },
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.image,
            ),
          )
        ],
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
                ? SingleChildScrollView(
                    controller: _scrollController,
                    reverse: true,
                    child: Column(
                      children: messages.map((message) {
                        return MessageWidget(
                          message: message,
                        );
                      }).toList(),
                    ),
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

  void _scrollToBottom() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter == 0) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 300,
        ),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(onStatus: (status) {}, onError: (error) {});
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
        _scrollToBottom();
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
