import 'package:flutter/material.dart';

class FeedbackOverlay {
  static void showLoading(
    BuildContext context, {
    String text = 'Dang xu ly...',
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(text)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void hideLoading(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  static Future<void> showPopup(
    BuildContext context, {
    required String message,
    bool isSuccess = false,
    Duration duration = const Duration(milliseconds: 1500),
  }) async {
    BuildContext? dialogContext;
    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(duration, () {
      final activeDialogContext = dialogContext;
      if (activeDialogContext != null &&
          activeDialogContext.mounted &&
          Navigator.of(activeDialogContext, rootNavigator: true).canPop()) {
        Navigator.of(activeDialogContext, rootNavigator: true).pop();
      }
    });

    await dialogFuture;
  }
}
