// ignore_for_file: empty_catches, use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:ai_mitra/sender_adapter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'utils.dart';
import 'message.dart';

class ChatWidget extends StatefulWidget {
  ChatWidget({Key? key}) : super(key: key);

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  GenerativeModel? model;
  late ChatSession chat;
  List<Message> messages = [];

  late ScrollController _scrollController;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  bool _loading = false;
  String? _apiKey;
  late Box<Message>? messageBox;
  final SpeechToText _speech = SpeechToText();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initHive().then((_) {
      _getApiKey();
      _initSpeech();
    });
  }

  Future<void> _initHive() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MessageAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SenderAdapter());
    }
    messageBox = await Hive.openBox<Message>('messages');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Hive.close();
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
    final storedApiKeyBox = await Hive.openBox('api_key');
    final storedApiKey = storedApiKeyBox.get('key');
    if (storedApiKey == null) {
      await DialogUtils.showApiKeyDialog(
        context,
        _apiKey,
        _setAndInitializeGenerativeModel,
      );
    } else {
      setState(() {
        _apiKey = storedApiKey.toString();
      });
      _initializeGenerativeModel();
    }
  }

  void _setAndInitializeGenerativeModel(String apiKey) {
    final storedApiKeyBox = Hive.box('api_key');
    storedApiKeyBox.put('key', apiKey);
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
    if (messageBox != null) {
      final List<Message> savedMessages = messageBox!.values.toList();
      setState(() {
        messages = savedMessages.toList();
      });
      _scrollToBottom();
    } else {
      _showError("Error loading messageBox");
    }
  }

  Future<void> _saveMessages() async {
    await messageBox?.clear();
    await messageBox?.addAll(messages);
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
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: getPdfText,
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _getImageFromSource,
          ),
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: _startListening,
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
                    onSubmitted: sendChatMessage,
                  ),
                ),
                const SizedBox.square(
                  dimension: 15,
                ),
                _loading
                    ? const CircularProgressIndicator()
                    : IconButton(
                        onPressed: () {
                          sendChatMessage(_textController.text);
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

  void _startListening() {
    if (_speech.isAvailable) {
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
            sendChatMessage(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _getImageFromSource() async {
    setState(() {
      _loading = true;
    });

    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text('Gallery'),
            ),
          ],
        );
      },
    );

    if (source != null) {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        final String imagePath = pickedFile.path;
        final String imageType =
            imagePath.substring(imagePath.lastIndexOf('.') + 1).toLowerCase();

        if (['jpg', 'png', 'jpeg', 'webp', 'heic', 'heif']
            .contains(imageType)) {
          final File imageFile = File(imagePath);
          await sendImageToBot(imageFile);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unsupported image type')),
          );
        }
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
      String? customizedMessage = await _showMessageInputDialog();

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

      final storedApiKeyBox = await Hive.openBox('api_key');
      final String? storedApiKey = storedApiKeyBox.get('key');
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
        messages.add(Message(
          sender: Sender.User,
          text: customizedMessage ?? 'You sent an image',
        ));
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

  Future<String?> _showMessageInputDialog() async {
    TextEditingController messageController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Customize Message'),
          content: TextField(
            controller: messageController,
            decoration: const InputDecoration(
              hintText: 'Enter message...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String? message = messageController.text.trim();
                Navigator.of(context).pop(message.isNotEmpty ? message : null);
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendChatMessage(String message) async {
    setState(() {
      _loading = true;
    });

    try {
      if (message.isNotEmpty) {
        var response = await chat.sendMessage(Content.text(message));
        var text = response.text;

        if (text == null) {
          _showError('No response from API.');
          return;
        }

        var sentMessage = Message(
          sender: Sender.User,
          text: message,
        );
        setState(() {
          messages.add(sentMessage);
          messages.add(Message(
            sender: Sender.Bot,
            text: text,
          ));
          _saveMessages();
        });
      }

      _textController.clear();
      _textFieldFocus.requestFocus();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        _loading = false;
      });
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToBottom();
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

  Future<void> getPdfText() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        String? pdfPath = result.files.single.path;

        if (pdfPath != null) {
          String text = await ReadPdfText.getPDFtext(pdfPath);

          await _sendTextToBotInChunks(text);
        }
      }
    } catch (e) {
      _showError('Error reading PDF: $e');
    }
  }

  Future<void> _sendTextToBotInChunks(String text) async {
    const chunkSize = 1024;
    for (var i = 0; i < text.length; i += chunkSize) {
      var chunk = text.substring(
          i, i + chunkSize < text.length ? i + chunkSize : text.length);
      await sendChatMessage(chunk);
    }
  }
}
