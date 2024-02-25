import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'chat_screen.dart';

void main() {
  runApp(
    const Main(),
  );
}

class Main extends StatelessWidget {
  const Main({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData.light(),
      dark: ThemeData.dark(),
      initial: AdaptiveThemeMode.light,
      builder: (lightTheme, darkTheme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        home: const Scaffold(
          body: ChatScreen(
            title: 'AI मित्र',
          ),
        ),
      ),
    );
  }
}
