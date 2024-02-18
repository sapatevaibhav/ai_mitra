import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DialogUtils {
  static Future<void> showApiKeyDialog(BuildContext context, String? apiKey,
      void Function(String) callback) async {
    String? _apiKey = apiKey;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter API Key'),
          content: TextField(
            controller: TextEditingController(),
            onChanged: (value) {
              _apiKey = value;
            },
            decoration: const InputDecoration(
              hintText: 'Enter your API Key',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                if (_apiKey != null && _apiKey!.isNotEmpty) {
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setString('api_key', _apiKey!);
                  Navigator.of(context).pop();
                  callback(
                      _apiKey!); // Call the callback function with the entered API key
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid API Key')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
