import 'dart:async';

/// Runs async tasks one at a time, in call order. Repositories use it so two
/// read-modify-write saves never interleave on the same JSON file.
class SerialQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
