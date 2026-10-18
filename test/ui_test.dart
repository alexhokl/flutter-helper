import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_helper/grpc.dart';
import 'package:flutter_helper/testing.dart';
import 'package:flutter_helper/ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('themesFromSeed derives a dark palette for the dark theme', () {
    final themes = themesFromSeed(Colors.teal);

    expect(themes.light.colorScheme.brightness, Brightness.light);
    expect(themes.dark.colorScheme.brightness, Brightness.dark);
    expect(
      themes.dark.colorScheme.surface,
      isNot(themes.light.colorScheme.surface),
    );
  });

  testWidgets('EmptyState shows the message and action', (tester) async {
    await tester.pumpWidget(
      wrapForTest(
        EmptyState(
          icon: Icons.inbox,
          message: 'Nothing here',
          action: TextButton(onPressed: () {}, child: const Text('Add')),
        ),
      ),
    );

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });

  testWidgets('ErrorState trims the error and retries', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      wrapForTest(
        ErrorState(
          error: ServiceException('Connection refused'),
          onRetry: () => retries++,
        ),
      ),
    );

    expect(find.text('Could not reach the server'), findsOneWidget);
    expect(find.text('Connection refused'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('ErrorState hides Retry without a callback', (tester) async {
    await tester.pumpWidget(wrapForTest(const ErrorState(error: 'x')));

    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('showMessage replaces the current snack bar', (tester) async {
    await tester.pumpWidget(wrapForTest(const SizedBox()));
    final context = tester.element(find.byType(SizedBox));

    showMessage(context, 'first');
    await tester.pump();
    showMessage(context, 'second', kind: MessageKind.error);
    await tester.pump();

    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(
      snackBar.backgroundColor,
      Theme.of(context).colorScheme.errorContainer,
    );
  });

  group('confirmDialog', () {
    Future<Future<bool>> open(WidgetTester tester) async {
      await tester.pumpWidget(wrapForTest(const SizedBox()));
      final result = confirmDialog(
        tester.element(find.byType(SizedBox)),
        title: 'Delete record?',
        message: 'This cannot be undone.',
      );
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('returns true on confirm', (tester) async {
      final result = await open(tester);
      expect(find.text('This cannot be undone.'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    });

    testWidgets('returns false on cancel', (tester) async {
      final result = await open(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });

    testWidgets('returns false when dismissed', (tester) async {
      final result = await open(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });
  });

  testWidgets('GitCommitFooter shows the commit', (tester) async {
    await tester.pumpWidget(
      wrapForTest(const GitCommitFooter(gitCommit: 'abc1234')),
    );

    expect(find.text('abc1234'), findsOneWidget);
  });

  testWidgets('GitCommitField copies the commit', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      wrapForTest(const GitCommitField(gitCommit: 'abc1234')),
    );
    expect(find.text('abc1234'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();

    expect(copied, 'abc1234');
    expect(find.text('Git commit copied to clipboard'), findsOneWidget);
  });
}
