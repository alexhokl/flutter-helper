import 'package:flutter_helper/config.dart';
import 'package:flutter_helper/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackendConfig.fromUrl', () {
    test('defaults an unparseable value to localhost', () {
      final config = BackendConfig.fromUrl('', defaultHttpPort: 8080);

      expect(config.host, 'localhost');
      expect(config.port, 8080);
    });

    test('resolves a bare https address to port 443', () {
      final config = BackendConfig.fromUrl('https://cbt.some-name.ts.net');

      expect(config.host, 'cbt.some-name.ts.net');
      expect(config.port, 443);
      expect(config.scheme, 'https');
      expect(config.useTls, isTrue);
    });

    test('resolves a bare http address to the default HTTP port', () {
      expect(BackendConfig.fromUrl('http://localhost').port, 80);
      expect(
        BackendConfig.fromUrl('http://localhost', defaultHttpPort: 8080).port,
        8080,
      );
    });

    test('treats a schemeless address as http', () {
      final config = BackendConfig.fromUrl('localhost', defaultHttpPort: 8080);

      expect(config.host, 'localhost');
      expect(config.port, 8080);
      expect(config.scheme, 'http');
      expect(config.useTls, isFalse);
    });

    test('an explicit port always wins over the scheme default', () {
      expect(BackendConfig.fromUrl('https://a.ts.net:8443').port, 8443);
      expect(BackendConfig.fromUrl('http://localhost:9090').port, 9090);
    });

    test('ignores surrounding whitespace', () {
      expect(
        BackendConfig.fromUrl('  https://a.ts.net  '),
        const BackendConfig(host: 'a.ts.net', port: 443, scheme: 'https'),
      );
    });

    test('decides TLS by host, not scheme', () {
      expect(BackendConfig.fromUrl('http://a.ts.net').useTls, isTrue);
      expect(BackendConfig.fromUrl('https://localhost').useTls, isFalse);
    });
  });

  group('BackendConfig storage', () {
    setUp(setUpInMemoryPrefs);

    test('load falls back to the default URL', () async {
      final config = await BackendConfig.load(
        defaultUrl: 'http://localhost:8080',
      );

      expect(config.host, 'localhost');
      expect(config.port, 8080);
    });

    test('save then load round-trips the trimmed URL', () async {
      await BackendConfig.save(' https://a.ts.net ');

      expect(
        await BackendConfig.loadUrl(defaultUrl: 'unused'),
        'https://a.ts.net',
      );
      expect((await BackendConfig.load(defaultUrl: 'unused')).port, 443);
    });

    test('channel opens a holder for the configured backend', () {
      final holder = BackendConfig.fromUrl('https://a.ts.net').channel();

      expect(holder.host, 'a.ts.net');
      expect(holder.port, 443);
      expect(holder.useTls, isTrue);
    });
  });

  test('BuildInfo.gitCommit defaults to dev', () {
    expect(BuildInfo.gitCommit, 'dev');
    expect(BuildInfo.isDevBuild, isTrue);
  });
}
