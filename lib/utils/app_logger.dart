class AppLogger {
  static void info(String message) {
    print('ℹ️  $message');
  }

  static void success(String message) {
    print('✅ $message');
  }

  static void warning(String message) {
    print('⚠️  $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    print('❌ $message');
    if (error != null) print('   Error: $error');
    if (stackTrace != null) print('   Stack: $stackTrace');
  }
}
