extension NullableStringExtension on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  bool get isUrl =>
      this != null && Uri.tryParse(this!)?.host.isNotEmpty == true;

  String toCapitalize() {
    if (this == null) return '';
    return this![0].toUpperCase() + this!.substring(1);
  }

  String orEmpty() => this ?? '';
}
