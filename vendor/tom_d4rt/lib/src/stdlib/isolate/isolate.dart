import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:tom_d4rt/d4rt.dart';
import 'interpreted_isolate.dart';

/// Thrown when an isolate cannot be created.
class IsolateSpawnExceptionIsolate {
  static BridgedClass get definition => BridgedClass(
    nativeType: IsolateSpawnException,
    name: 'IsolateSpawnException',
    isAssignable: (v) => v is IsolateSpawnException,
    constructors: {
      '': (visitor, positionalArgs, namedArgs) {
        final message = positionalArgs[0] as String;
        return IsolateSpawnException(message);
      },
    },
    getters: {
      'message': (visitor, target) => (target as IsolateSpawnException).message,
      'hashCode': (visitor, target) =>
          (target as IsolateSpawnException).hashCode,
      'runtimeType': (visitor, target) =>
          (target as IsolateSpawnException).runtimeType,
    },
    methods: {
      'toString': (visitor, target, positionalArgs, namedArgs, _) {
        return (target as IsolateSpawnException).toString();
      },
    },
  );
}

/// An isolated Dart execution context.
class IsolateIsolate {
  static BridgedClass get definition => BridgedClass(
    nativeType: Isolate,
    name: 'Isolate',
    isAssignable: (v) => v is Isolate,
    constructors: {
      '': (visitor, positionalArgs, namedArgs) {
        final controlPort = positionalArgs[0] as SendPort;
        final pauseCapability = namedArgs.get<Capability?>('pauseCapability');
        final terminateCapability = namedArgs.get<Capability?>(
          'terminateCapability',
        );
        return Isolate(
          controlPort,
          pauseCapability: pauseCapability,
          terminateCapability: terminateCapability,
        );
      },
    },
    staticMethods: {
      'run': (visitor, positionalArgs, namedArgs, _) {
        D4.checkArity(positionalArgs, 'Isolate.run', atMost: 1);
        final computation = positionalArgs[0];
        if (computation is! Callable) {
          throw RuntimeD4rtException(
            'Isolate.run requires a Function for computation.',
          );
        }
        return runInterpretedIsolate(
          visitor,
          computation,
          debugName: namedArgs.get<String?>('debugName'),
        );
      },
      'spawn': (visitor, positionalArgs, namedArgs, _) {
        D4.checkArity(positionalArgs, 'Isolate.spawn', atMost: 2);
        final entryPoint = positionalArgs[0];
        final message = positionalArgs[1];
        if (entryPoint is! Callable) {
          throw RuntimeD4rtException(
            'Isolate.spawn requires a Function for entryPoint.',
          );
        }
        return spawnInterpretedIsolate(
          visitor,
          entryPoint,
          message,
          paused: namedArgs.get<bool?>('paused') ?? false,
          errorsAreFatal: namedArgs.get<bool?>('errorsAreFatal') ?? true,
          onExit: namedArgs.get<SendPort?>('onExit'),
          onError: namedArgs.get<SendPort?>('onError'),
          debugName: namedArgs.get<String?>('debugName'),
        );
      },
      'spawnUri': (visitor, positionalArgs, namedArgs, _) {
        D4.checkArity(positionalArgs, 'Isolate.spawnUri', atMost: 3);
        // Loading native user source bypasses the interpreter's permissions,
        // capture reconstruction and root-owned worker supervision.
        return Future<Isolate>.error(
          UnsupportedError(
            'Isolate.spawnUri is unsupported by the interpreted runtime. '
            'Use Isolate.spawn with a source function instead.',
          ),
        );
      },
      'exit': (visitor, positionalArgs, namedArgs, _) {
        D4.checkArity(positionalArgs, 'Isolate.exit', atMost: 2);
        final finalMessagePort = positionalArgs.get<SendPort?>(0);
        final message = positionalArgs.get<Object?>(1);
        Isolate.exit(finalMessagePort, message);
      },
      'resolvePackageUri': (visitor, positionalArgs, namedArgs, _) {
        D4.checkArity(positionalArgs, 'Isolate.resolvePackageUri', atMost: 1);
        final packageUri = positionalArgs[0] as Uri;
        return Isolate.resolvePackageUri(packageUri);
      },
      'resolvePackageUriSync': (visitor, positionalArgs, namedArgs, _) {
        D4.checkArity(
          positionalArgs,
          'Isolate.resolvePackageUriSync',
          atMost: 1,
        );
        final packageUri = positionalArgs[0] as Uri;
        return Isolate.resolvePackageUriSync(packageUri);
      },
    },
    staticGetters: {
      'current': (visitor) => Isolate.current,
      'packageConfig': (visitor) => Isolate.packageConfig,
      'packageConfigSync': (visitor) => Isolate.packageConfigSync,
      'immediate': (visitor) => Isolate.immediate,
      'beforeNextEvent': (visitor) => Isolate.beforeNextEvent,
    },
    getters: {
      'controlPort': (visitor, target) => (target as Isolate).controlPort,
      'pauseCapability': (visitor, target) =>
          (target as Isolate).pauseCapability,
      'terminateCapability': (visitor, target) =>
          (target as Isolate).terminateCapability,
      'debugName': (visitor, target) => (target as Isolate).debugName,
      'errors': (visitor, target) => (target as Isolate).errors,
      'hashCode': (visitor, target) => (target as Isolate).hashCode,
      'runtimeType': (visitor, target) => (target as Isolate).runtimeType,
    },
    methods: {
      'pause': (visitor, target, positionalArgs, namedArgs, _) {
        D4.checkArity(positionalArgs, 'Isolate.pause', atMost: 1);
        final resumeCapability = positionalArgs.get<Capability?>(0);
        return (target as Isolate).pause(resumeCapability);
      },
      'resume': (visitor, target, positionalArgs, namedArgs, _) {
        D4.checkArity(
          positionalArgs,
          'IsolateSpawnException.resume',
          atMost: 1,
        );
        final resumeCapability = positionalArgs[0] as Capability;
        (target as Isolate).resume(resumeCapability);
        return null;
      },
      'addOnExitListener': (visitor, target, positionalArgs, namedArgs, _) {
        D4.checkArity(
          positionalArgs,
          'IsolateSpawnException.addOnExitListener',
          atMost: 1,
        );
        final responsePort = positionalArgs[0] as SendPort;
        final response = namedArgs.get<Object?>('response');
        (target as Isolate).addOnExitListener(responsePort, response: response);
        return null;
      },
      'removeOnExitListener': (visitor, target, positionalArgs, namedArgs, _) {
        D4.checkArity(
          positionalArgs,
          'IsolateSpawnException.removeOnExitListener',
          atMost: 1,
        );
        final responsePort = positionalArgs[0] as SendPort;
        (target as Isolate).removeOnExitListener(responsePort);
        return null;
      },
      'setErrorsFatal': (visitor, target, positionalArgs, namedArgs, _) {
        D4.checkArity(
          positionalArgs,
          'IsolateSpawnException.setErrorsFatal',
          atMost: 1,
        );
        final errorsAreFatal = positionalArgs[0] as bool;
        (target as Isolate).setErrorsFatal(errorsAreFatal);
        return null;
      },
      'kill': (visitor, target, positionalArgs, namedArgs, _) {
        final priority =
            namedArgs.get<int?>('priority') ?? Isolate.beforeNextEvent;
        (target as Isolate).kill(priority: priority);
        return null;
      },
      'ping': (visitor, target, positionalArgs, namedArgs, _) {
        D4.checkArity(positionalArgs, 'IsolateSpawnException.ping', atMost: 1);
        final responsePort = positionalArgs[0] as SendPort;
        final response = namedArgs.get<Object?>('response');
        final priority = namedArgs.get<int?>('priority') ?? Isolate.immediate;
        (target as Isolate).ping(
          responsePort,
          response: response,
          priority: priority,
        );
        return null;
      },
      'addErrorListener': (visitor, target, positionalArgs, namedArgs, _) {
        D4.checkArity(
          positionalArgs,
          'IsolateSpawnException.addErrorListener',
          atMost: 1,
        );
        final port = positionalArgs[0] as SendPort;
        (target as Isolate).addErrorListener(port);
        return null;
      },
      'removeErrorListener': (visitor, target, positionalArgs, namedArgs, _) {
        D4.checkArity(
          positionalArgs,
          'IsolateSpawnException.removeErrorListener',
          atMost: 1,
        );
        final port = positionalArgs[0] as SendPort;
        (target as Isolate).removeErrorListener(port);
        return null;
      },
    },
  );
}

/// Sends messages to its ReceivePorts.
class SendPortIsolate {
  static BridgedClass get definition => BridgedClass(
    nativeType: SendPort,
    name: 'SendPort',
    isAssignable: (v) => v is SendPort,
    methods: {
      'send': (visitor, target, positionalArgs, namedArgs, _) {
        D4.checkArity(positionalArgs, 'IsolateSpawnException.send', atMost: 1);
        final message = positionalArgs[0];
        (target as SendPort).send(message);
        return null;
      },
    },
    getters: {
      'hashCode': (visitor, target) => (target as SendPort).hashCode,
      'runtimeType': (visitor, target) => (target as SendPort).runtimeType,
    },
  );
}

/// Together with SendPort, the only means of communication between isolates.
class ReceivePortIsolate {
  static BridgedClass get definition => BridgedClass(
    nativeType: ReceivePort,
    name: 'ReceivePort',
    isAssignable: (v) => v is ReceivePort,
    constructors: {
      '': (visitor, positionalArgs, namedArgs) {
        final debugName = positionalArgs.get<String>(0) ?? '';
        return ReceivePort(debugName);
      },
      'fromRawReceivePort': (visitor, positionalArgs, namedArgs) {
        final rawPort = positionalArgs[0] as RawReceivePort;
        return ReceivePort.fromRawReceivePort(rawPort);
      },
    },
    getters: {
      'sendPort': (visitor, target) => (target as ReceivePort).sendPort,
      'isBroadcast': (visitor, target) => (target as Stream).isBroadcast,
      'isEmpty': (visitor, target) => (target as Stream).isEmpty,
      'length': (visitor, target) => (target as Stream).length,
      'first': (visitor, target) => (target as Stream).first,
      'last': (visitor, target) => (target as Stream).last,
      'single': (visitor, target) => (target as Stream).single,
      'hashCode': (visitor, target) => (target as ReceivePort).hashCode,
      'runtimeType': (visitor, target) => (target as ReceivePort).runtimeType,
    },
    methods: {
      'listen': (visitor, target, positionalArgs, namedArgs, _) {
        D4.checkArity(positionalArgs, 'ReceivePort.listen', atMost: 1);
        final onData = positionalArgs.get<Callable?>(0);
        final onError = namedArgs.get<Callable?>('onError');
        final onDone = namedArgs.get<Callable?>('onDone');
        final cancelOnError = namedArgs.get<bool?>('cancelOnError');

        return (target as ReceivePort).listen(
          onData == null ? null : (message) => onData.call(visitor, [message]),
          onError: onError == null
              ? null
              : (error) => onError.call(visitor, [error]),
          onDone: onDone == null ? null : () => onDone.call(visitor, []),
          cancelOnError: cancelOnError,
        );
      },
      'close': (visitor, target, positionalArgs, namedArgs, _) {
        (target as ReceivePort).close();
        return null;
      },
      // Stream methods
      'map': (visitor, target, positionalArgs, namedArgs, _) {
        D4.checkArity(positionalArgs, 'IsolateSpawnException.map', atMost: 1);
        final transform = positionalArgs[0];
        if (transform is! Callable) {
          throw RuntimeD4rtException(
            'Stream.map requires a Function for transform.',
          );
        }
        return (target as Stream).map(
          (event) => transform.call(visitor, [event]),
        );
      },
      'where': (visitor, target, positionalArgs, namedArgs, _) {
        D4.checkArity(positionalArgs, 'IsolateSpawnException.where', atMost: 1);
        final test = positionalArgs[0];
        if (test is! Callable) {
          throw RuntimeD4rtException(
            'Stream.where requires a Function for test.',
          );
        }
        return (target as Stream).where(
          (event) => test.call(visitor, [event]) as bool,
        );
      },
      'take': (visitor, target, positionalArgs, namedArgs, _) {
        D4.checkArity(positionalArgs, 'IsolateSpawnException.take', atMost: 1);
        final count = positionalArgs[0] as int;
        return (target as Stream).take(count);
      },
      'skip': (visitor, target, positionalArgs, namedArgs, _) {
        D4.checkArity(positionalArgs, 'IsolateSpawnException.skip', atMost: 1);
        final count = positionalArgs[0] as int;
        return (target as Stream).skip(count);
      },
    },
  );
}

/// A low-level asynchronous message receiver.
class RawReceivePortIsolate {
  static BridgedClass get definition => BridgedClass(
    nativeType: RawReceivePort,
    name: 'RawReceivePort',
    isAssignable: (v) => v is RawReceivePort,
    constructors: {
      '': (visitor, positionalArgs, namedArgs) {
        final handler = positionalArgs.get<Callable?>(0);
        final debugName = positionalArgs.get<String>(1) ?? '';
        if (handler != null) {
          final rawPort = RawReceivePort(null, debugName);
          rawPort.handler = (message) => handler.call(visitor, [message]);
          return rawPort;
        }
        return RawReceivePort(null, debugName);
      },
    },
    getters: {
      'sendPort': (visitor, target) => (target as RawReceivePort).sendPort,
      'keepIsolateAlive': (visitor, target) =>
          (target as RawReceivePort).keepIsolateAlive,
      'hashCode': (visitor, target) => (target as RawReceivePort).hashCode,
      'runtimeType': (visitor, target) =>
          (target as RawReceivePort).runtimeType,
    },
    setters: {
      'handler': (visitor, target, value) {
        if (value is Callable) {
          (target as RawReceivePort).handler = (message) =>
              value.call(visitor!, [message]);
        } else if (value == null) {
          (target as RawReceivePort).handler = null;
        } else {
          (target as RawReceivePort).handler = value as Function?;
        }
      },
      'keepIsolateAlive': (visitor, target, value) {
        (target as RawReceivePort).keepIsolateAlive = value as bool;
      },
    },
    methods: {
      'close': (visitor, target, positionalArgs, namedArgs, _) {
        (target as RawReceivePort).close();
        return null;
      },
    },
  );
}

/// Description of an error from another isolate.
class RemoteErrorIsolate {
  static BridgedClass get definition => BridgedClass(
    nativeType: RemoteError,
    name: 'RemoteError',
    isAssignable: (v) => v is RemoteError,
    constructors: {
      '': (visitor, positionalArgs, namedArgs) {
        final description = positionalArgs[0] as String;
        final stackDescription = positionalArgs[1] as String;
        return RemoteError(description, stackDescription);
      },
    },
    getters: {
      'stackTrace': (visitor, target) => (target as RemoteError).stackTrace,
      'hashCode': (visitor, target) => (target as RemoteError).hashCode,
      'runtimeType': (visitor, target) => (target as RemoteError).runtimeType,
    },
    methods: {
      'toString': (visitor, target, positionalArgs, namedArgs, _) {
        return (target as RemoteError).toString();
      },
    },
  );
}

/// An efficiently transferable sequence of byte values.
class TransferableTypedDataIsolate {
  static BridgedClass get definition => BridgedClass(
    nativeType: TransferableTypedData,
    name: 'TransferableTypedData',
    isAssignable: (v) => v is TransferableTypedData,
    constructors: {
      'fromList': (visitor, positionalArgs, namedArgs) {
        final list = positionalArgs[0];
        if (list is! List) {
          throw RuntimeD4rtException(
            'TransferableTypedData.fromList requires a List<TypedData>.',
          );
        }

        return TransferableTypedData.fromList(
          list.toNativeList().cast<TypedData>(),
        );
      },
    },
    methods: {
      'materialize': (visitor, target, positionalArgs, namedArgs, _) {
        return (target as TransferableTypedData).materialize();
      },
    },
    getters: {
      'hashCode': (visitor, target) =>
          (target as TransferableTypedData).hashCode,
      'runtimeType': (visitor, target) =>
          (target as TransferableTypedData).runtimeType,
    },
  );
}
