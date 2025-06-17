import 'package:flutter/material.dart';

class ShowErrorMessage extends StatelessWidget {
  final String errorMessage;
  const ShowErrorMessage({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    
    if (errorMessage != '') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => {
                Navigator.pop(context),
                Navigator.pop(context),
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}