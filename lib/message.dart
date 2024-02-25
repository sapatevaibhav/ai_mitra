import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hive/hive.dart';

part 'message.g.dart';

enum Sender {
  User,
  Bot,
}

@HiveType(typeId: 0)
class Message extends HiveObject {
  @HiveField(0)
  final Sender sender;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final String? imagePath;

  Message({
    required this.sender,
    required this.text,
    this.imagePath,
  });

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
      child: Column(
        crossAxisAlignment: message.sender == Sender.User
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
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
        ],
      ),
    );
  }
}
