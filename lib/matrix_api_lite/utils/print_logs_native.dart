import 'package:matrix/matrix_api_lite.dart';

extension PrintLogs on LogEvent {
  void printOut() {
    var logsStr = title;
    if (exception != null) {
      logsStr += ' - ${exception.toString()}';
    }
    if (stackTrace != null) {
      logsStr += '\n${stackTrace.toString()}';
    }
    if (Logs().nativeColors) {
      switch (level) {
        case Level.wtf:
          logsStr = '\x1B[31m!!!CRITICAL!!! ${DateTime.now()}: $logsStr\x1B[0m';
          break;
        case Level.error:
          logsStr = '\x1B[31m${DateTime.now()}: $logsStr\x1B[0m';
          break;
        case Level.warning:
          logsStr = '\x1B[33m${DateTime.now()}: $logsStr\x1B[0m';
          break;
        case Level.info:
          logsStr = '\x1B[32m${DateTime.now()}: $logsStr\x1B[0m';
          break;
        case Level.debug:
          logsStr = '\x1B[34m${DateTime.now()}: $logsStr\x1B[0m';
          break;
        case Level.verbose:
          break;
      }
    }
    // ignore: avoid_print
    print('[Matrix] $logsStr');
  }
}
