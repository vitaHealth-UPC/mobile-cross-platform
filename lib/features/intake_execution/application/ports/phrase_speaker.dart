/// Reads the suggested phrase aloud for adults who prefer to hear it.
abstract interface class PhraseSpeaker {
  Future<void> speak(String phrase, String languageTag);
  Future<void> stop();
}
