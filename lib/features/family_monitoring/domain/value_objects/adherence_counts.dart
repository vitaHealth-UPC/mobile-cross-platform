/// Validated adherence counts; absence of evidence has no percentage.
final class AdherenceCounts {
  AdherenceCounts(this.confirmed, this.total) {
    if (confirmed < 0 || total < confirmed) {
      throw ArgumentError('Invalid adherence counts');
    }
  }

  final int confirmed;
  final int total;

  /// 0..100, or null when nothing was resolved yet.
  double? get percentage => total == 0 ? null : confirmed * 100.0 / total;
}
