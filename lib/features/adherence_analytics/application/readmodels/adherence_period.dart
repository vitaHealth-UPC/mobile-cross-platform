/// Rolling period choices offered by the adherence history selector.
enum AdherencePeriod {
  /// Last seven days.
  lastWeek(7),

  /// Last thirty days, the default period of the history screen.
  lastMonth(30);

  const AdherencePeriod(this.days);

  /// Length of the period in elapsed 24-hour days.
  final int days;
}
