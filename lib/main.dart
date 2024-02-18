import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'chat_screen.dart';

void main() {
  runApp(
    const GenerativeAISample(),
  );
}

class GenerativeAISample extends StatelessWidget {
  const GenerativeAISample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData.light(),
      dark: ThemeData.dark(),
      initial: AdaptiveThemeMode.light,
      builder: (lightTheme, darkTheme) => MaterialApp(
        title: 'AI Mitra',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        home: const ChatScreen(
          title: 'AI Mitra',
        ),
      ),
    );
  }
}
