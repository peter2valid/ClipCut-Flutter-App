import 'dart:isolate';

/// High-performance isolate runner for executing expensive tasks off the UI thread.
///
/// This enables FFmpeg operations, file I/O, and other CPU-intensive tasks
/// to run without blocking the UI, ensuring smooth animations and responsiveness.
///
/// Example usage:
/// ```dart
/// final result = await TaskRunner.run(() async {
///   return await someExpensiveOperation();
/// });
/// ```
class TaskRunner {
  /// Run a task in a separate isolate to avoid blocking the UI thread.
  ///
  /// [task] - The asynchronous function to execute in the isolate
  /// Returns the result of type [T] when the task completes
  static Future<T> run<T>(Future<T> Function() task) async {
    final receivePort = ReceivePort();

    try {
      await Isolate.spawn(_entry, [receivePort.sendPort, task]);
      final result = await receivePort.first as T;
      return result;
    } catch (e) {
      receivePort.close();
      rethrow;
    }
  }

  /// Internal entry point for the isolate.
  /// Executes the task and sends the result back to the main isolate.
  static void _entry(List<dynamic> args) async {
    final SendPort sendPort = args[0];
    final Future Function() task = args[1];

    try {
      final result = await task();
      sendPort.send(result);
    } catch (e) {
      // Send error back to main isolate
      sendPort.send(e);
    }
  }
}
