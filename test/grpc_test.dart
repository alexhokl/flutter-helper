import 'package:flutter_helper/grpc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';

void main() {
  group('isLoopbackHost', () {
    test('treats loopback and empty hosts as local', () {
      for (final host in ['', 'localhost', '127.0.0.1', '::1']) {
        expect(isLoopbackHost(host), isTrue, reason: host);
      }
    });

    test('treats any other host as remote', () {
      for (final host in ['photos.some-name.ts.net', '192.168.1.2', 'x']) {
        expect(isLoopbackHost(host), isFalse, reason: host);
      }
    });
  });

  group('GrpcChannelHolder', () {
    test('uses TLS for remote hosts and plaintext for loopback', () {
      expect(
        GrpcChannelHolder(host: 'cbt.some-name.ts.net', port: 443).useTls,
        isTrue,
      );
      expect(GrpcChannelHolder(host: 'localhost', port: 8080).useTls, isFalse);
    });

    test('an explicit useTls wins over the host', () {
      expect(
        GrpcChannelHolder(host: 'localhost', port: 8443, useTls: true).useTls,
        isTrue,
      );
      expect(
        GrpcChannelHolder(host: 'a.ts.net', port: 80, useTls: false).useTls,
        isFalse,
      );
    });

    test('creates the channel lazily and once', () async {
      final holder = GrpcChannelHolder(host: 'localhost', port: 1);
      expect(holder.isOpen, isFalse);

      final channel = holder.channel;
      expect(holder.isOpen, isTrue);
      expect(identical(holder.channel, channel), isTrue);
      expect(channel.host, 'localhost');
      expect(channel.port, 1);
      expect(channel.options.credentials.isSecure, isFalse);

      await holder.shutdown();
      expect(holder.isOpen, isFalse);
      expect(identical(holder.channel, channel), isFalse);
      await holder.shutdown();
    });
  });

  group('ServiceException.from', () {
    test('keeps the gRPC status message', () {
      final error = GrpcError.notFound('record 3 not found');
      final exception = ServiceException.from(error);

      expect(exception.message, 'record 3 not found');
      expect(exception.grpcError, same(error));
      expect(exception.toString(), 'record 3 not found');
    });

    test('falls back to the code name when there is no message', () {
      expect(
        ServiceException.from(GrpcError.unavailable()).message,
        'UNAVAILABLE',
      );
    });

    test('wraps other errors by their string form', () {
      final exception = ServiceException.from(StateError('boom'));

      expect(exception.message, 'Bad state: boom');
      expect(exception.grpcError, isNull);
    });

    test('passes a ServiceException through unchanged', () {
      final original = ServiceException('already wrapped');

      expect(ServiceException.from(original), same(original));
    });
  });

  test('guardGrpc returns the value or throws a ServiceException', () async {
    expect(await guardGrpc(() async => 42), 42);
    await expectLater(
      guardGrpc<int>(() async => throw GrpcError.internal('nope')),
      throwsA(
        isA<ServiceException>().having((e) => e.message, 'message', 'nope'),
      ),
    );
  });

  group('describeError', () {
    test('uses the message of a ServiceException or GrpcError', () {
      expect(describeError(ServiceException('down')), 'down');
      expect(describeError(GrpcError.unavailable('host down')), 'host down');
    });

    test('extracts the message part of a gRPC string', () {
      expect(
        describeError(
          'gRPC Error (code: 14, codeName: UNAVAILABLE, message: Connection '
          'refused, details: [], rawResponse: null, trailers: {})',
        ),
        'Connection refused',
      );
    });

    test('returns other text unchanged', () {
      expect(describeError('plain failure'), 'plain failure');
    });
  });
}
