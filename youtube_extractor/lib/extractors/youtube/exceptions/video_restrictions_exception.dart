class VideoRestrictionsException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  VideoRestrictionsException(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() {
    final buffer = StringBuffer('VideoRestrictionsException: $message');
    if (code != null) buffer.write(' (code: $code)');
    if (details != null) buffer.write('\nDetails: $details');
    return buffer.toString();
  }
}

class AgeRestrictedException extends VideoRestrictionsException {
  final int requiredAge;

  AgeRestrictedException(String message, {this.requiredAge = 18})
      : super(message, code: 'AGE_RESTRICTED');
}

class MembershipRequiredException extends VideoRestrictionsException {
  final String? membershipType;
  final String? channelId;

  MembershipRequiredException(
    String message, {
    this.membershipType,
    this.channelId,
  }) : super(message, code: 'MEMBERSHIP_REQUIRED');
}

class PremiumRequiredException extends VideoRestrictionsException {
  PremiumRequiredException(String message)
      : super(message, code: 'PREMIUM_REQUIRED');
}

class RentalRequiredException extends VideoRestrictionsException {
  final String? price;
  final String? currency;

  RentalRequiredException(
    String message, {
    this.price,
    this.currency,
  }) : super(message, code: 'RENTAL_REQUIRED');
}

class LiveStreamRestrictedException extends VideoRestrictionsException {
  final bool isUpcoming;
  final DateTime? startTime;

  LiveStreamRestrictedException(
    String message, {
    this.isUpcoming = false,
    this.startTime,
  }) : super(message, code: 'LIVE_RESTRICTED');
}
