class IdGenerator {
  static String next(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${prefix}_$now';
  }
}
