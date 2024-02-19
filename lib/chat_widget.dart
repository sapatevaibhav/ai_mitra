// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
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
  GenerativeModel? model;
  late ChatSession chat;
  late ScrollController _scrollController;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  bool _loading = false;
  String? _apiKey;
  List<Message> messages = [];
  final SpeechToText _speech = SpeechToText();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getApiKey();
    _initSpeech();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {},
      onError: (error) {},
    );
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
    _scrollToBottom();
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
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () {
              _getImageFromSource();
            },
          ),
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
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _getImageFromSource() async {
    setState(() {
      _loading = true;
    });

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );

    if (pickedFile != null) {
      final String imagePath = pickedFile.path;
      final String imageType =
          imagePath.substring(imagePath.lastIndexOf('.') + 1).toLowerCase();

      if (['jpg', 'png', 'jpeg', 'webp', 'heic', 'heif'].contains(imageType)) {
        final File imageFile = File(imagePath);
        await sendImageToBot(imageFile);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unsupported image type')),
        );
      }
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> sendImageToBot(File imageFile) async {
    setState(() {
      _loading = true;
    });

    try {
      final imageBytes = await imageFile.readAsBytes();

      const chunkSize = 1024 * 1024;

      final chunks = <Uint8List>[];
      for (var i = 0; i < imageBytes.length; i += chunkSize) {
        final chunk = Uint8List.fromList(imageBytes.sublist(
            i,
            i + chunkSize < imageBytes.length
                ? i + chunkSize
                : imageBytes.length));
        chunks.add(chunk);
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? storedApiKey = prefs.getString('api_key');
      if (storedApiKey == null) {
        throw Exception('API key not found');
      }

      final model = GenerativeModel(
        model: 'gemini-pro-vision',
        apiKey: storedApiKey,
      );

      final prompt = TextPart("What's in this picture?");

      final responses = <String>[];
      for (final chunk in chunks) {
        final imagePart = DataPart('image/jpeg', chunk);

        final response = await model.generateContent([
          Content.multi([prompt, imagePart])
        ]);

        responses.add(response.text ?? '');
      }

      final combinedResponse = responses.join(' ');

      setState(() {
        _loading = false;
        messages.add(Message(sender: Sender.Bot, text: combinedResponse));
        _saveMessages();
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      _showError(e.toString());
    }
    _scrollToBottom();
  }
}
