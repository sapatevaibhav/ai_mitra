import 'package:flutter/material.dart';
import 'package:ai_mitra/utils.dart';

void openSettingsPopup(
    BuildContext context, String apiKey, Function() initializeGenerativeModel) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Settings'),
        content: Container(
          height: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Change API Key'),
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
