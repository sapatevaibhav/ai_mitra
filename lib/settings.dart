import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:ai_mitra/utils.dart';

void openSettingsPopup(
  BuildContext context,
  String apiKey,
  Function(String) initializeGenerativeModel,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Settings'),
        content: SizedBox(
          height: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Row(
                  children: [
                    Icon(
                      Icons.vpn_key,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Change API Key',
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  DialogUtils.showApiKeyDialog(
                    context,
                    apiKey,
                    initializeGenerativeModel,
                  );
                },
              ),
              ListTile(
                title: const Row(
                  children: [
                    Icon(
                      Icons.dark_mode,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Switch theme',
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _switchTheme(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _switchTheme(BuildContext context) {
  final themeMode = AdaptiveTheme.of(context).mode;
  final newThemeMode = themeMode == AdaptiveThemeMode.light
      ? AdaptiveThemeMode.dark
      : AdaptiveThemeMode.light;
  AdaptiveTheme.of(context).setThemeMode(newThemeMode);
}
