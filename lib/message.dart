import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

enum Sender {
  User,
  Bot,
}

class Message {
  final Sender sender;
  final String text;
  final String? imagePath;

  Message({
    required this.sender,
    required this.text,
    this.imagePath,
  });

  String toJson() {
    return jsonEncode({
      'sender': sender.index,
      'text': text,
      'imagePath': imagePath,
    });
  }

  factory Message.fromJson(String json) {
    final Map<String, dynamic> map = jsonDecode(json);
    return Message(
      sender: Sender.values[map['sender']],
      text: map['text'],
      imagePath: map['imagePath'],
    );
  }
}

class MessageWidget extends StatelessWidget {
  final Message message;

  const MessageWidget({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildTextMessage(context);
  }

  Widget _buildTextMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: Align(
        alignment: message.sender == Sender.User
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: message.sender == Sender.User
                ? Colors.blueAccent.withOpacity(.4)
                : Colors.greenAccent.withOpacity(.4),
            borderRadius: BorderRadius.only(
              topLeft:
                  Radius.circular(message.sender == Sender.Bot ? 0.0 : 15.0),
              topRight: const Radius.circular(15.0),
              bottomLeft: const Radius.circular(15.0),
              bottomRight:
                  Radius.circular(message.sender == Sender.User ? 0.0 : 15.0),
            ),
          ),
          child: MarkdownBody(
            data: message.text,
            selectable: true,
            styleSheet: MarkdownStyleSheet(),
          ),
        ),
      ),
    );
  }
}
