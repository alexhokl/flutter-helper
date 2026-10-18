import 'package:flutter/services.dart';
import 'package:flutter_helper/intents.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const name = 'test.app/intents';
  const method = MethodChannel(name);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  String? parse(Map<String, String?> raw) =>
      raw['action'] == 'send' ? raw['text'] : null;

  tearDown(() => messenger.setMockMethodCallHandler(method, null));

  test('getInitialIntent parses the launch intent', () async {
    messenger.setMockMethodCallHandler(method, (call) async {
      expect(call.method, 'getInitialIntent');
      return {'action': 'send', 'text': 'hello'};
    });

    expect(await IntentChannel(name, parse).getInitialIntent(), 'hello');
  });

  test('getInitialIntent returns null without a launch intent', () async {
    messenger.setMockMethodCallHandler(method, (call) async => null);

    expect(await IntentChannel(name, parse).getInitialIntent(), isNull);
  });

  test('getInitialIntent returns null off Android', () async {
    expect(await IntentChannel(name, parse).getInitialIntent(), isNull);
  });

  test('listen delivers parsed intents and drops ignored ones', () async {
    final channel = IntentChannel(name, parse);
    final received = <String>[];
    channel.listen(received.add);

    Future<void> send(String method, Object? arguments) =>
        messenger.handlePlatformMessage(
          name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall(method, arguments),
          ),
          (_) {},
        );

    await send('onIntent', {'action': 'send', 'text': 'one'});
    await send('onIntent', {'action': 'view', 'uri': 'x://y'});
    await send('other', {'action': 'send', 'text': 'two'});
    await send('onIntent', 'not a map');

    expect(received, ['one']);

    channel.dispose();
    await send('onIntent', {'action': 'send', 'text': 'three'});
    expect(received, ['one']);
  });

  test('nonEmpty', () {
    expect(nonEmpty(null), isNull);
    expect(nonEmpty('  '), isNull);
    expect(nonEmpty(' a '), 'a');
  });

  test('squashWhitespace', () {
    expect(squashWhitespace('  a \n\t b  '), 'a b');
  });

  test('splitList trims, drops blanks and duplicates in order', () {
    expect(splitList(null), isEmpty);
    expect(splitList(' home, errand,,home ,'), ['home', 'errand']);
    expect(splitList('Work, work ,Home', normalise: (v) => v.toLowerCase()), [
      'work',
      'home',
    ]);
  });
}
