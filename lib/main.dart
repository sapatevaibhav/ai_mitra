import 'package:flutter/material.dart';

import 'chat_screen.dart';

void main() {
  runApp(
    const GenerativeAISample(),
  );
}

class GenerativeAISample extends StatelessWidget {
  const GenerativeAISample({Key? key})
      : super(
          key: key,
        );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Mitra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color.fromARGB(
            255,
            171,
            222,
            244,
          ),
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(
        title: 'AI Mitra',
      ),
    );
  }
}
