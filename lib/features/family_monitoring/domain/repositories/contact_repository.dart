import '../../../../shared/common/result/app_result.dart';
import '../value_objects/contact_channel.dart';

/// Provides the contact channel and identity available to authorized follow-up.
abstract interface class ContactRepository {
  /// Fails with `NOT_FOUND` when there is no follow-up or no channel.
  Future<AppResult<ContactChannel>> contactChannel(String olderAdultId);

  Future<AppResult<String>> olderAdultFullName(String olderAdultId);
}
