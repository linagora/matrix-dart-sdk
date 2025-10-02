class DebugUtils {
  static final DebugUtils _instance = DebugUtils._internal();

  static bool enableLogs = false;
  static bool inDebugMode = false;

  DebugUtils._internal();

  factory DebugUtils() {
    return _instance;
  }

  bool get isDebugMode {
    if (enableLogs) {
      return enableLogs;
    }
    assert(inDebugMode = true);
    return inDebugMode;
  }
}
