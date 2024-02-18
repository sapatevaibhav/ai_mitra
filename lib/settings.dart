import 'package:flutter/material.dart';
import 'package:ai_mitra/utils.dart';
void openSettingsPopup(BuildContext context, String apiKey,
    Function(String) initializeGenerativeModel) {
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
                title: const Text('Change API Key'),
                onTap: () {
                  Navigator.of(context).pop();
                  DialogUtils.showApiKeyDialog(
                      context, apiKey, initializeGenerativeModel);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
