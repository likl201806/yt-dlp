class GeoRestrictionException implements Exception {
  final String message;
  final List<String>? allowedCountries;
  final List<String>? blockedCountries;

  GeoRestrictionException(
    this.message, {
    this.allowedCountries,
    this.blockedCountries,
  });

  @override
  String toString() {
    final buffer = StringBuffer('GeoRestrictionException: $message');
    if (allowedCountries?.isNotEmpty ?? false) {
      buffer.write('\nAllowed countries: ${allowedCountries!.join(", ")}');
    }
    if (blockedCountries?.isNotEmpty ?? false) {
      buffer.write('\nBlocked countries: ${blockedCountries!.join(", ")}');
    }
    return buffer.toString();
  }
}
