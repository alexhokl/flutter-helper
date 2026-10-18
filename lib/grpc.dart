/// gRPC plumbing shared by the apps: one lazily created channel per backend,
/// TLS decided from the host, and a user-facing exception type.
library;

import 'package:grpc/grpc.dart';

/// Whether [host] is a loopback address, meaning a local development server
/// that is dialled in the clear.
///
/// This matches the server-side logic of the Go backends: anything that is
/// not loopback is a tailnet host expected to present a certificate.
bool isLoopbackHost(String host) =>
    host.isEmpty || host == 'localhost' || host == '127.0.0.1' || host == '::1';

/// Owns a [ClientChannel] to one backend, creating it on first use.
///
/// The apps authenticate by network identity (the server resolves the
/// caller's tailnet address to a user), so there is no credential to attach;
/// the only choice to make is whether to use TLS.
class GrpcChannelHolder {
  GrpcChannelHolder({
    required this.host,
    required this.port,
    bool? useTls,
    this.idleTimeout = const Duration(minutes: 5),
  }) : useTls = useTls ?? !isLoopbackHost(host);

  final String host;
  final int port;

  /// Defaults to TLS for every host except loopback.
  final bool useTls;

  /// How long an unused connection stays open. A short timeout keeps a
  /// mobile client from holding a connection open in the background, and
  /// reconnecting is cheap on a tailnet.
  final Duration idleTimeout;

  ClientChannel? _channel;

  ChannelCredentials get credentials => useTls
      ? const ChannelCredentials.secure()
      : const ChannelCredentials.insecure();

  /// The channel, created on first access.
  ClientChannel get channel => _channel ??= ClientChannel(
    host,
    port: port,
    options: ChannelOptions(credentials: credentials, idleTimeout: idleTimeout),
  );

  /// Whether [channel] has been created and not shut down since.
  bool get isOpen => _channel != null;

  /// Closes the channel. A later access to [channel] opens a new one.
  Future<void> shutdown() async {
    final channel = _channel;
    _channel = null;
    await channel?.shutdown();
  }
}

/// Thrown when a call to a backend fails, carrying a message fit to show the
/// user rather than a raw gRPC status.
class ServiceException implements Exception {
  ServiceException(this.message, {this.grpcError});

  /// Wraps any error thrown by a call. A [GrpcError] keeps its status message
  /// (or code name when the server sent none); anything else uses its
  /// [Object.toString].
  factory ServiceException.from(Object error) {
    if (error is ServiceException) return error;
    if (error is GrpcError) {
      return ServiceException(
        error.message ?? error.codeName,
        grpcError: error,
      );
    }
    return ServiceException(error.toString());
  }

  final String message;
  final GrpcError? grpcError;

  @override
  String toString() => message;
}

/// Runs [body], turning any failure into a [ServiceException].
Future<T> guardGrpc<T>(Future<T> Function() body) async {
  try {
    return await body();
  } catch (error) {
    throw ServiceException.from(error);
  }
}

/// Trims an error down to the line the user can act on.
///
/// A [ServiceException] or [GrpcError] gives its message directly. For
/// anything else the `message:` part of its string form is extracted when
/// present, since the full gRPC string includes the status code and transport
/// details, which are noise on a phone screen.
String describeError(Object error) {
  if (error is ServiceException) return error.message;
  if (error is GrpcError) return error.message ?? error.codeName;
  final text = error.toString();
  final match = RegExp(r'message:\s*(.+?)(?:,\s*details|$)').firstMatch(text);
  return match?.group(1)?.trim() ?? text;
}
