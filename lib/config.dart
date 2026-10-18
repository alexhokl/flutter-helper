/// The backend address setting and build information.
library;

import 'package:shared_preferences/shared_preferences.dart';

import 'grpc.dart';

/// Build information passed in with `--dart-define`.
abstract final class BuildInfo {
  /// The short commit hash the app was built from, or `dev` for a build
  /// without `--dart-define=GIT_COMMIT=...`.
  static const String gitCommit = String.fromEnvironment(
    'GIT_COMMIT',
    defaultValue: 'dev',
  );

  /// Whether this is a build without a commit hash.
  static bool get isDevBuild => gitCommit == 'dev' || gitCommit.isEmpty;
}

/// The parsed form of the backend address setting.
///
/// The setting is a single URL, such as `https://photos.some-name.ts.net` or
/// `http://localhost:8080`, stored with [SharedPreferencesAsync] under
/// [storageKey].
class BackendConfig {
  const BackendConfig({
    required this.host,
    required this.port,
    this.scheme = 'http',
  });

  /// The shared preferences key every app stores the address under.
  static const String storageKey = 'backend_url';

  final String host;
  final int port;
  final String scheme;

  /// Whether to dial the backend with TLS. Only loopback hosts are dialled in
  /// the clear, regardless of [scheme].
  bool get useTls => !isLoopbackHost(host);

  /// Parses a stored address.
  ///
  /// A value without a scheme is treated as `http://`. When no port is given,
  /// `https` resolves to 443, since the tsnet servers terminate TLS there,
  /// and anything else resolves to [defaultHttpPort], which apps set to their
  /// server's local development port.
  ///
  /// A value that does not parse falls back to `localhost` rather than
  /// throwing, so a half typed address cannot leave the app unable to start.
  factory BackendConfig.fromUrl(String url, {int defaultHttpPort = 80}) {
    final text = url.trim();
    final uri = Uri.tryParse(text.contains('://') ? text : 'http://$text');
    if (uri == null || uri.host.isEmpty) {
      return BackendConfig(host: 'localhost', port: defaultHttpPort);
    }
    final scheme = uri.scheme.toLowerCase();
    return BackendConfig(
      host: uri.host,
      port: uri.hasPort
          ? uri.port
          : (scheme == 'https' ? 443 : defaultHttpPort),
      scheme: scheme,
    );
  }

  /// Reads the stored address, or [defaultUrl] when none has been saved.
  static Future<String> loadUrl({required String defaultUrl}) async {
    return await SharedPreferencesAsync().getString(storageKey) ?? defaultUrl;
  }

  /// Reads and parses the stored address.
  static Future<BackendConfig> load({
    required String defaultUrl,
    int defaultHttpPort = 80,
  }) async {
    final url = await loadUrl(defaultUrl: defaultUrl);
    return BackendConfig.fromUrl(url, defaultHttpPort: defaultHttpPort);
  }

  /// Stores [url] as the backend address.
  static Future<void> save(String url) =>
      SharedPreferencesAsync().setString(storageKey, url.trim());

  /// Opens a channel holder for this backend.
  GrpcChannelHolder channel({bool? useTls}) =>
      GrpcChannelHolder(host: host, port: port, useTls: useTls ?? this.useTls);

  @override
  bool operator ==(Object other) =>
      other is BackendConfig &&
      other.host == host &&
      other.port == port &&
      other.scheme == scheme;

  @override
  int get hashCode => Object.hash(host, port, scheme);

  @override
  String toString() => '$scheme://$host:$port';
}
