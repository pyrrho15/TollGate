import 'package:flutter/material.dart';

import '../../../core/constants.dart';

/// The commitment gate. The user must retype [AppConstants.commitmentPhrase] before any
/// disabling action goes through; the submit callback validates it and can return an
/// error to show inline without closing.
///
/// Returns the typed phrase on success, or null if the user backed out.
Future<String?> showCommitmentDialog(
  BuildContext context, {
  required String title,
  required String description,
  required String actionLabel,
  required Future<String?> Function(String phrase) onSubmit,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CommitmentDialog(
      title: title,
      description: description,
      actionLabel: actionLabel,
      onSubmit: onSubmit,
    ),
  );
}

class _CommitmentDialog extends StatefulWidget {
  const _CommitmentDialog({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onSubmit,
  });

  final String title;
  final String description;
  final String actionLabel;
  final Future<String?> Function(String phrase) onSubmit;

  @override
  State<_CommitmentDialog> createState() => _CommitmentDialogState();
}

class _CommitmentDialogState extends State<_CommitmentDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await widget.onSubmit(_controller.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(_controller.text);
    } else {
      setState(() {
        _submitting = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              AppConstants.commitmentPhrase,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 1,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Type the sentence…',
              errorText: _error,
            ),
            onSubmitted: (_) => _submitting ? null : _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.actionLabel),
        ),
      ],
    );
  }
}
