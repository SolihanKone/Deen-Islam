import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ArabicTtsState {
  const ArabicTtsState({this.speakingId, this.error});

  final String? speakingId;
  final String? error;

  bool isSpeaking(String id) => speakingId == id;
}

final arabicTtsProvider =
    NotifierProvider<ArabicTtsController, ArabicTtsState>(
  ArabicTtsController.new,
);

class ArabicTtsController extends Notifier<ArabicTtsState> {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  @override
  ArabicTtsState build() {
    _setup();
    ref.onDispose(() {
      _tts.stop();
    });
    return const ArabicTtsState();
  }

  Future<void> _setup() async {
    try {
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(false);

      final languages = await _tts.getLanguages;
      if (languages is List) {
        final codes = languages.map((e) => e.toString()).toList();
        final arabic = codes.firstWhere(
          (c) => c.toLowerCase().startsWith('ar'),
          orElse: () => 'ar-SA',
        );
        await _tts.setLanguage(arabic);
      } else {
        await _tts.setLanguage('ar-SA');
      }

      _tts.setCompletionHandler(() {
        state = const ArabicTtsState();
      });
      _tts.setCancelHandler(() {
        state = const ArabicTtsState();
      });
      _tts.setErrorHandler((msg) {
        state = ArabicTtsState(error: msg.toString());
      });
      _ready = true;
    } catch (e) {
      if (kDebugMode) debugPrint('Arabic TTS setup: $e');
      state = ArabicTtsState(error: e.toString());
    }
  }

  Future<void> toggle(String id, String arabic) async {
    if (!_ready) await _setup();
    final text = arabic.trim();
    if (text.isEmpty) return;

    if (state.speakingId == id) {
      await stop();
      return;
    }

    await _tts.stop();
    state = ArabicTtsState(speakingId: id);
    try {
      await _tts.speak(text);
    } catch (e) {
      state = ArabicTtsState(error: e.toString());
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    state = const ArabicTtsState();
  }
}
