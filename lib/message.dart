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
