// ignore_for_file: use_build_context_synchronously

import 'package:ai_mitra/message.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'utils.dart';

void openSettingsPopup(
  BuildContext context,
  String apiKey,
  Function(String) initializeGenerativeModel,
) async {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (
      BuildContext context,
    ) {
      return AlertDialog(
        title: const Text(
          'Settings',
        ),
        content: SizedBox(
          height: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                  color: Colors.blue.withOpacity(
                    0.2,
                  ),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                  leading: const Icon(
                    Icons.vpn_key_outlined,
                    color: Colors.blue,
                  ),
                  title: const Text(
                    'Change API Key',
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await DialogUtils.showApiKeyDialog(
                      context,
                      apiKey,
                      initializeGenerativeModel,
                    );
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                  color: isDarkMode
                      ? Colors.white.withOpacity(
                          0.2,
                        )
                      : Colors.black.withOpacity(
                          0.2,
                        ),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                  leading: Icon(
                    isDarkMode
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: isDarkMode ? Colors.white60 : Colors.black,
                  ),
                  title: Text(
                    'Switch theme',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white60 : Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _switchTheme(context);
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                  color: Colors.orange.withOpacity(
                    0.3,
                  ),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                  leading: const Icon(
                    Icons.code_outlined,
                    color: Colors.orange,
                  ),
                  title: const Text(
                    'Source Code',
                    style: TextStyle(
                      color: Colors.orange,
                    ),
                  ),
                  onTap: () {
                    launchUrl(
                      Uri.parse(
                        "https://github.com/sapatevaibhav/ai_mitra",
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                  color: Colors.redAccent.withOpacity(
                    0.3,
                  ),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                  leading: const Icon(
                    Icons.clear_rounded,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Clear History',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    clearStoredMessages(context);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _switchTheme(BuildContext context) {
  final themeMode = AdaptiveTheme.of(
    context,
  ).mode;
  final newThemeMode = themeMode == AdaptiveThemeMode.light
      ? AdaptiveThemeMode.dark
      : AdaptiveThemeMode.light;
  AdaptiveTheme.of(context).setThemeMode(
    newThemeMode,
  );
}

Future<void> clearStoredMessages(BuildContext context) async {
  final HiveInterface hive = Hive;
  final Box<Message> messageBox = await hive.openBox<Message>('messages');

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Are you sure you want to clear stored messages?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await messageBox.clear();
              Navigator.pop(context);
              Navigator.popAndPushNamed(
                context,
                '/',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Success! History has been deleted!',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      );
    },
  );
}
