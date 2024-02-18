import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:ai_mitra/utils.dart';
import 'package:url_launcher/url_launcher.dart';

void openSettingsPopup(
  BuildContext context,
  String apiKey,
  Function(String) initializeGenerativeModel,
) {
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
          height: 200,
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
                  onTap: () {
                    Navigator.of(context).pop();
                    DialogUtils.showApiKeyDialog(
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
                  color: Colors.yellow.withOpacity(
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
                  ),
                  title: Text(
                    'Source Code',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white60 : Colors.black,
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
