enum TripStatusEnum{
  pending,
  confirmed,
  ongoing,
  completed,
  canceled,
  paymentFailed,
}

extension TripStatusEnumApiValue on TripStatusEnum {
  /// The value the API actually sends in `trip_status`.
  ///
  /// Dart's `.name` returns the identifier as written — `paymentFailed` — but the
  /// backend sends snake_case, `payment_failed`. Every
  /// `tripStatus == TripStatusEnum.paymentFailed.name` comparison was therefore
  /// silently false: the trip-details header rendered an empty `SizedBox` beside
  /// a meaningless tick, and `Pay Now` never appeared for a trip that had
  /// actually failed payment.
  ///
  /// The other values are single words, so `.name` already matches the wire
  /// format for them and they fall through unchanged.
  String get apiValue => this == TripStatusEnum.paymentFailed ? 'payment_failed' : name;
}
