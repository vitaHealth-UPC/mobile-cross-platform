import '../../../domain/entities/care_link.dart';

/// Consent progress contains public relationship metadata, never session tokens.
final class ConsentState {
  const ConsentState({
    this.loading = false,
    this.link,
    this.errorCode,
    this.withdrawn = false,
  });
  final bool loading;
  final CareLink? link;
  final String? errorCode;
  final bool withdrawn;
}
