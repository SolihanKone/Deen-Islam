/// On-device translation voices via sherpa-onnx.
///
/// English uses Kokoro (male speakers only). French and Urdu use Piper:
/// Kokoro's official catalog has a single French voice (`ff_siwis`, female)
/// and no Urdu — so those languages stay on male Piper models.
enum TtsEngine { kokoro, piper }

class PiperVoice {
  const PiperVoice({
    required this.id,
    required this.name,
    required this.language,
    required this.style,
    required this.engine,
    required this.archive,
    this.speakerId = 0,
  });

  final String id;
  final String name;

  /// `en` / `fr` / `ur`
  final String language;
  final String style;
  final TtsEngine engine;

  /// Filename on the sherpa-onnx `tts-models` release.
  final String archive;

  /// Kokoro speaker id. Unused for Piper (always 0).
  final int speakerId;

  String get label => name;

  /// Shared download / engine cache key. All Kokoro English speakers share one model.
  String get modelKey =>
      engine == TtsEngine.kokoro ? 'kokoro-en' : id;

  static const String defaultId = 'am_michael';

  static const _release =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models';

  static const _kokoroEnArchive = 'kokoro-int8-en-v0_19.tar.bz2';

  /// Piper English ids from the previous picker — migrate to Kokoro.
  static const _legacyEnglishPiper = {
    'hfc_male',
    'ryan',
    'john',
    'alan',
  };

  String get archiveUrl => '$_release/$archive';

  static const List<PiperVoice> presets = [
    PiperVoice(
      id: 'am_michael',
      name: 'Michael',
      language: 'en',
      style: 'Warm',
      engine: TtsEngine.kokoro,
      archive: _kokoroEnArchive,
      speakerId: 6,
    ),
    PiperVoice(
      id: 'am_adam',
      name: 'Adam',
      language: 'en',
      style: 'Deep',
      engine: TtsEngine.kokoro,
      archive: _kokoroEnArchive,
      speakerId: 5,
    ),
    PiperVoice(
      id: 'bm_george',
      name: 'George',
      language: 'en',
      style: 'Even',
      engine: TtsEngine.kokoro,
      archive: _kokoroEnArchive,
      speakerId: 9,
    ),
    PiperVoice(
      id: 'bm_lewis',
      name: 'Lewis',
      language: 'en',
      style: 'Firm',
      engine: TtsEngine.kokoro,
      archive: _kokoroEnArchive,
      speakerId: 10,
    ),
    PiperVoice(
      id: 'tom',
      name: 'Tom',
      language: 'fr',
      style: 'Informative',
      engine: TtsEngine.piper,
      archive: 'vits-piper-fr_FR-tom-medium-int8.tar.bz2',
    ),
    PiperVoice(
      id: 'gilles',
      name: 'Gilles',
      language: 'fr',
      style: 'Deep',
      engine: TtsEngine.piper,
      archive: 'vits-piper-fr_FR-gilles-low-int8.tar.bz2',
    ),
    PiperVoice(
      id: 'fasih',
      name: 'Fasih',
      language: 'ur',
      style: 'Clear',
      engine: TtsEngine.piper,
      archive: 'vits-piper-ur_PK-fasih-medium-int8.tar.bz2',
    ),
  ];

  static PiperVoice byId(String id) {
    for (final v in presets) {
      if (v.id == id) return v;
    }
    return presets.firstWhere((v) => v.id == defaultId);
  }

  static bool isValidId(String id) => presets.any((v) => v.id == id);

  static String languageForEdition(String translationId) {
    if (translationId.startsWith('ur')) return 'ur';
    if (translationId.startsWith('fr')) return 'fr';
    return 'en';
  }

  /// Prefer [preferredId] when it matches the translation language.
  static PiperVoice resolve({
    required String preferredId,
    required String translationId,
  }) {
    final lang = languageForEdition(translationId);
    final preferred = byId(preferredId);
    if (preferred.language == lang) return preferred;
    for (final v in presets) {
      if (v.language == lang) return v;
    }
    return byId(defaultId);
  }

  static String migrateStoredId(String? raw) {
    final id = raw ?? defaultId;
    if (isValidId(id)) return id;
    if (_legacyEnglishPiper.contains(id)) return defaultId;
    return defaultId;
  }
}
