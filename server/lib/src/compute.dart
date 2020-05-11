import 'dart:isolate';

import 'package:meta/meta.dart';

/// This function will run within the new isolate.
void _isolateEntrypoint<T, S>(_ComputeRequest<T, S> request) {
  final result = request.compute();
  request.sendPort.send(result);
}

/// Bundle of information to pass to the isolate.
class _ComputeRequest<T, S> {
  /// The function to call.
  T Function(S parameter) function;

  /// The parameter to pass to the function.
  S parameter;

  /// The port through which the result will be sent.
  SendPort sendPort;

  _ComputeRequest({
    @required this.function,
    @required this.parameter,
    @required this.sendPort,
  });

  /// Call [function] with [parameter] and return the result.
  /// 
  /// This function exists to avoid type errors within the isolate.
  T compute() => function(parameter);
}

/// Call a function in a new isolate and await the result.
/// 
/// The function has to be a static function. If the result is not a primitive
/// value or a list or map of such, this won't work
/// (see https://api.dart.dev/stable/2.8.1/dart-isolate/SendPort/send.html).
Future<T> compute<T, S>(T Function(S parameter) function, S parameter) async {
  final receivePort = ReceivePort();

  Isolate.spawn(
    _isolateEntrypoint,
    _ComputeRequest<T, S>(
      function: function,
      parameter: parameter,
      sendPort: receivePort.sendPort,
    ),
  );

  return await receivePort.first as T;
}
