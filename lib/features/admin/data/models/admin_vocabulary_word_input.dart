class AdminVocabularyWordInput {
  const AdminVocabularyWordInput({
    required this.russianWord,
    required this.englishTranslation,
    this.transcription,
    this.exampleSentence,
  });

  final String russianWord;
  final String englishTranslation;
  final String? transcription;
  final String? exampleSentence;

  Map<String, Object?> toInsertPayload() {
    return {
      'russian_word': russianWord.trim(),
      'english_translation': englishTranslation.trim(),
      'transcription': _trimToNull(transcription),
      'example_sentence': _trimToNull(exampleSentence),
    };
  }
}

String? _trimToNull(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  return text;
}
