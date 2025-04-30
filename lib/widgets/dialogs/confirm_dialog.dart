import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmDialog({
    Key? key,
    required this.title,
    required this.content,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.confirmColor,
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            if (onCancel != null) {
              onCancel!();
            }
          },
          child: Text(
            cancelText,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop(true);
            if (onConfirm != null) {
              onConfirm!();
            }
          },
          child: Text(confirmText),
        ),
      ],
    );
  }
} 