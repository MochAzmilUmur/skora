import 'package:flutter/material.dart';

class DialogBuilder {
  const DialogBuilder(this.context);
  final BuildContext context;

  Future<void> showLoadingDialog() => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => PopScope(
          canPop:false,
          child: AlertDialog(
            content: SizedBox(
              width: 100,
              height: 100,
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> showResultDialog(String text) => showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          content: SizedBox(
            height: 100,
            width: 100,
            child: Center(child: Text(text, textAlign: TextAlign.center)),
          ),
        ),
      );

  Future<void> showErrorDialog(String error) => showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Error'),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
}