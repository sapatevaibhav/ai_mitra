// ignore_for_file: use_build_context_synchronously

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

  @override
  void initState() {
    super.initState();
    _getApiKey();
  }

  Future<void> _getApiKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final storedApiKey = prefs.getString('api_key',);
    if (storedApiKey == null) {
      await DialogUtils.showApiKeyDialog(
          context, _apiKey, _setAndInitializeGenerativeModel,);
    } else {
      setState(() {
        _apiKey = storedApiKey;
      });
      _initializeGenerativeModel();
    }
  }

  void _setAndInitializeGenerativeModel(
    String apiKey,
  ) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    var textFieldDecoration = InputDecoration(
      contentPadding: const EdgeInsets.all(
        15,
      ),
      hintText: 'Enter a prompt...',
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(
            14,
          ),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(
            14,
          ),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
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
                    itemBuilder: (context, idx) {
                      var content = chat.history.toList()[idx];
                      var text = content.parts
                          .whereType<TextPart>()
                          .map<String>(
                            (e) => e.text,
                          )
                          .join(
                            '',
                          );
                      return MessageWidget(
                        text: text,
                        isFromUser: content.role == 'user',
                      );
                    },
                    itemCount: chat.history.length,
                  )
                : ListView(
                    children: const [
                      Text(
                        'No API key found. Please provide an API Key.',
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 25,
              horizontal: 15,
            ),
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
                if (!_loading)
                  IconButton(
                    onPressed: () async {
                      _sendChatMessage(
                        _textController.text,
                      );
                    },
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                else
                  const CircularProgressIndicator(),
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
      var response = await chat.sendMessage(
        Content.text(message),
      );
      var text = response.text;

      if (text == null) {
        _showError(
          'No response from API.',
        );
        return;
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      setState(() {
        _loading = false;
      });
      _textFieldFocus.requestFocus();
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Something went wrong',
          ),
          content: SingleChildScrollView(
            child: SelectableText(
              message,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                DialogUtils.showApiKeyDialog(
                    context, _apiKey, _setAndInitializeGenerativeModel);
              },
              child: const Text(
                'OK',
              ),
            )
          ],
        );
      },
    );
  }
}

class MessageWidget extends StatelessWidget {
  final String text;
  final bool isFromUser;

  const MessageWidget({
    Key? key,
    required this.text,
    required this.isFromUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
            decoration: BoxDecoration(
              color: isFromUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(
                18,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
            margin: const EdgeInsets.only(
              bottom: 8,
            ),
            child: MarkdownBody(
              selectable: true,
              data: text,
            ),
          ),
        ),
      ],
    );
  }
}
