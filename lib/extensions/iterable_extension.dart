extension IterableExtension<T> on Iterable<T>? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  T? firstWhereOrNull(bool Function(T element) test) {
    if (isNullOrEmpty) return null;
    for (var element in this!.toList()) {
      if (test(element)) return element;
    }
    return null;
  }
}
