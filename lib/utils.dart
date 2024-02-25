// ignore_for_file: prefer_const_constructors, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_mitra/main.dart';
import 'package:flutter/services.dart';

class DialogUtils {
  static Future<void> showApiKeyDialog(BuildContext context, String? apiKey,
      void Function(String) callback) async {
    String? enteredApiKey = apiKey;
    final apiKeyBox = await Hive.openBox('api_key');

    String? currentApiKey = apiKeyBox.get('key') as String?;

    TextEditingController controller =
        TextEditingController(text: enteredApiKey);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Builder(
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'Enter API Key',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          currentApiKey ?? 'No API Key',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.content_copy),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: currentApiKey ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('API Key copied to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    onChanged: (value) {
                      enteredApiKey = value;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Enter your API Key',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "If you don't have an API key, get it now.",
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            launchUrl(
                              Uri.parse(
                                'https://makersuite.google.com/app/apikey',
                              ),
                            );
                          },
                          child: const Text('Get Key'),
                        ),
                        TextButton(
                          child: const Text('Save'),
                          onPressed: () async {
                            if (enteredApiKey != null &&
                                enteredApiKey!.isNotEmpty) {
                              await apiKeyBox.put('key', enteredApiKey);
                              Navigator.of(context).pop();
                              callback(enteredApiKey!);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      const Main(),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter a valid API Key',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
