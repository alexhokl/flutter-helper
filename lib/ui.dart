/// Widgets and helpers that keep the apps looking and behaving alike.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config.dart';
import 'grpc.dart';

/// Light and dark Material 3 themes generated from one seed colour.
///
/// Each theme gets its own [ColorScheme.fromSeed] call, so the dark theme
/// uses a properly derived dark palette rather than a light palette with the
/// brightness flag flipped.
({ThemeData light, ThemeData dark}) themesFromSeed(Color seed) => (
  light: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed)),
  dark: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ),
  ),
);

/// A centred progress indicator, for a page that is loading its first data.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// A consistent empty state, so every list looks the same when there is
/// nothing to show.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// A consistent error state that keeps the underlying message visible.
///
/// The raw error is shown, trimmed by [describeError], rather than a generic
/// apology because the most common failure is a connection problem, and the
/// actual message tells the user whether the server is down or the address
/// is wrong.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.error,
    this.onRetry,
    this.title = 'Could not reach the server',
    this.retryLabel = 'Retry',
    this.icon = Icons.cloud_off,
  });

  final Object error;
  final VoidCallback? onRetry;
  final String title;
  final String retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              describeError(error),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// How a [showMessage] snack bar is coloured.
enum MessageKind { info, success, warning, error }

/// Shows [message] in a snack bar, replacing any snack bar already showing.
///
/// Does nothing when [context] has been unmounted while an await was in
/// flight, so callers can use it straight after an async call.
void showMessage(
  BuildContext context,
  String message, {
  MessageKind kind = MessageKind.info,
  Duration duration = const Duration(seconds: 4),
}) {
  if (!context.mounted) return;

  final (background, foreground) = switch (kind) {
    MessageKind.info => (null, null),
    // Fixed light colours with dark text read well over both themes.
    MessageKind.success => (Colors.green.shade200, Colors.black),
    MessageKind.warning => (Colors.orange.shade200, Colors.black),
    MessageKind.error => (
      Theme.of(context).colorScheme.errorContainer,
      Theme.of(context).colorScheme.onErrorContainer,
    ),
  };

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: foreground)),
        backgroundColor: background,
        duration: duration,
      ),
    );
}

/// Asks the user to confirm an action, returning true only when they press
/// [confirmLabel]. Dismissing the dialog counts as cancelling.
///
/// When [destructive] is true the confirm button uses the error colour.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
  bool destructive = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// The commit the app was built from, in small muted text, for the foot of a
/// home page.
class GitCommitFooter extends StatelessWidget {
  const GitCommitFooter({super.key, this.gitCommit = BuildInfo.gitCommit});

  final String gitCommit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        gitCommit,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

/// A read-only field showing the commit the app was built from, with a
/// button that copies it, for the About section of a settings page.
///
/// The labels are parameters so that localised apps can pass their own.
class GitCommitField extends StatefulWidget {
  const GitCommitField({
    super.key,
    this.gitCommit = BuildInfo.gitCommit,
    this.label = 'Git commit',
    this.copiedMessage = 'Git commit copied to clipboard',
    this.copyTooltip = 'Copy to clipboard',
  });

  final String gitCommit;
  final String label;
  final String copiedMessage;
  final String copyTooltip;

  @override
  State<GitCommitField> createState() => _GitCommitFieldState();
}

class _GitCommitFieldState extends State<GitCommitField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.gitCommit,
  );

  @override
  void didUpdateWidget(GitCommitField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gitCommit != widget.gitCommit) {
      _controller.text = widget.gitCommit;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.gitCommit));
    if (!mounted) return;
    showMessage(
      context,
      widget.copiedMessage,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.commit),
        suffixIcon: IconButton(
          icon: const Icon(Icons.copy),
          tooltip: widget.copyTooltip,
          onPressed: _copy,
        ),
      ),
    );
  }
}
