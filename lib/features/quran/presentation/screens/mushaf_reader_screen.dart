import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qcf_quran/qcf_quran.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/mushaf_layout_repository.dart';
import '../../domain/models/mushaf_page_model.dart';
import '../../domain/mushaf_navigation.dart';
import '../providers/quran_player_provider.dart';
import '../providers/quran_prefs_provider.dart';
import '../widgets/madinah_mushaf_page_renderer.dart';
import '../widgets/mushaf_audio_bar.dart';
import '../widgets/mushaf_go_to_sheet.dart';
import '../widgets/quran_nav_bar.dart';
import '../../domain/mushaf_translation.dart';

/// Faithful Madinah Mushaf reader — 604 pages, pre-defined lines, QCF fonts.
class MushafReaderScreen extends ConsumerStatefulWidget {
  const MushafReaderScreen({
    super.key,
    this.initialPage,
    this.autoPlayAudio = false,
    this.continueAudioPages = false,
  });

  final int? initialPage;
  final bool autoPlayAudio;
  final bool continueAudioPages;

  @override
  ConsumerState<MushafReaderScreen> createState() => _MushafReaderScreenState();
}

class _MushafReaderScreenState extends ConsumerState<MushafReaderScreen>
    with WidgetsBindingObserver {
  final ItemScrollController _scrollController = ItemScrollController();
  final ScrollOffsetController _scrollOffsetController =
      ScrollOffsetController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  late int _currentPage;
  int? _lastSyncedPage;
  String? _lastHighlightScrollKey;
  bool _didInitialJump = false;
  Timer? _saveDebounce;
  Timer? _syncingScrollTimer;
  Timer? _followBackTimer;
  var _syncingScroll = false;
  var _userDetached = false;
  var _highlightRetries = 0;

  static const _highlightMinTop = 0.10;
  static const _highlightMaxBottom = 0.68;
  static const _followBackDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPage = (widget.initialPage ?? 1).clamp(
      MushafNavigation.startPage,
      MushafPageModel.totalPages,
    );
    _positionsListener.itemPositions.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoPlayAudio) {
        _startListening(continuePages: widget.continueAudioPages);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveDebounce?.cancel();
    _syncingScrollTimer?.cancel();
    _followBackTimer?.cancel();
    _positionsListener.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _forceFollowPlaying();
    }
  }

  void _beginSyncingScroll() {
    _syncingScroll = true;
    _syncingScrollTimer?.cancel();
    _syncingScrollTimer = Timer(const Duration(milliseconds: 450), () {
      _syncingScroll = false;
    });
  }

  void _scheduleFollowBack() {
    _userDetached = true;
    _followBackTimer?.cancel();
    _followBackTimer = Timer(_followBackDelay, () {
      if (!mounted) return;
      _forceFollowPlaying();
    });
  }

  void _forceFollowPlaying() {
    _followBackTimer?.cancel();
    _userDetached = false;
    _lastHighlightScrollKey = null;
    _highlightRetries = 0;
    final player = ref.read(quranPlayerProvider);
    if (player.isMushafPlayback) {
      _syncScrollFromPlayer(player);
    }
  }

  double _pageHeight(
    BuildContext context, {
    required bool audioVisible,
    required bool translationPlay,
  }) {
    final media = MediaQuery.of(context);
    final top = media.padding.top + kToolbarHeight;
    // Reserve room for compact MushafAudioBar (+ voice chips when translation).
    final audioBar = translationPlay ? 86.0 : 72.0;
    final bottom = audioVisible
        ? audioBar + 52.0 + media.padding.bottom
        : 52.0 + media.padding.bottom;
    return media.size.height - top - bottom;
  }

  void _onScroll() {
    if (_syncingScroll) return;

    final page = _mostVisiblePage();
    if (page == null) return;

    if (page == _currentPage) return;

    setState(() => _currentPage = page);
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(quranPrefsProvider.notifier).saveLastMushafPage(page);
    });
    ref.read(mushafLayoutRepositoryProvider).preloadPages([
      page - 1,
      page + 1,
      page + 2,
    ]);
  }

  int? _playingPageOf(QuranPlayerState player) {
    final item = player.currentMushafItem;
    if (item != null) return pageForMushafPlaybackItem(item);
    return player.mushafPage;
  }

  int? _mostVisiblePage() {
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return null;

    ItemPosition? best;
    for (final position in positions) {
      if (position.itemLeadingEdge > 0.5) continue;
      if (best == null || position.itemLeadingEdge < best.itemLeadingEdge) {
        best = position;
      }
    }
    return best != null ? best.index + 1 : null;
  }

  void _goToPage(int page, {bool animate = true, double alignment = 0}) {
    final index = page.clamp(1, MushafPageModel.totalPages) - 1;
    if (!_scrollController.isAttached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goToPage(page, animate: animate, alignment: alignment);
      });
      return;
    }
    _beginSyncingScroll();
    if (animate) {
      _scrollController.scrollTo(
        index: index,
        alignment: alignment,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(index: index, alignment: alignment);
    }
    if (_currentPage != page) {
      setState(() => _currentPage = page);
    }
    _lastSyncedPage = page;
    ref.read(quranPrefsProvider.notifier).saveLastMushafPage(page);
  }

  Future<void> _openGoTo() async {
    final page = await showMushafGoToSheet(context, currentPage: _currentPage);
    if (page != null && mounted) _goToPage(page);
  }

  void _startListening({bool continuePages = true}) {
    _followBackTimer?.cancel();
    _userDetached = false;
    _lastSyncedPage = null;
    _lastHighlightScrollKey = null;
    ref
        .read(quranPlayerProvider.notifier)
        .playMushafPage(_currentPage, continuePages: continuePages);
  }

  void _syncScrollFromPlayer(QuranPlayerState next) {
    if (!next.isMushafPlayback) return;
    if (_userDetached) return;

    final item = next.currentMushafItem;
    final targetPage = item != null
        ? pageForMushafPlaybackItem(item)
        : next.mushafPage;
    if (targetPage == null) return;

    if (targetPage != _lastSyncedPage) {
      _lastSyncedPage = targetPage;
      _lastHighlightScrollKey = null;
      _highlightRetries = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _userDetached) return;
        _goToPage(targetPage, animate: true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _userDetached) return;
          _scrollHighlightIntoView(targetPage, item);
        });
      });
      return;
    }

    _scrollHighlightIntoView(targetPage, item);
  }

  void _scrollHighlightIntoView(int pageNumber, MushafPlaybackItem? item) {
    if (item == null || _userDetached) return;

    final player = ref.read(quranPlayerProvider);
    final translationPlay =
        player.includeTranslationAudio ||
        ref.read(settingsProvider).showTranslation;
    final viewportHeight = _pageHeight(
      context,
      audioVisible: true,
      translationPlay: translationPlay,
    );
    final repo = ref.read(mushafLayoutRepositoryProvider);
    final pageModel = repo.cachedPage(pageNumber);
    if (pageModel == null) {
      if (_highlightRetries > 8) return;
      _highlightRetries++;
      ref.read(mushafPageModelProvider(pageNumber).future).then((model) {
        if (mounted && !_userDetached) {
          _scrollHighlightIntoView(pageNumber, item);
        }
      });
      return;
    }

    final lineIndex = lineIndexForPlayingItem(pageModel, item);
    if (lineIndex == null) return;

    final playingTranslation = player.isPlayingTranslation;
    final withTranslations = ref.read(settingsProvider).showTranslation;
    final scrollKey =
        '$pageNumber:$lineIndex:$playingTranslation:$withTranslations:$translationPlay';
    final lineSlotHeight = mushafListenLineSlotHeight(viewportHeight);
    final divider = (pageNumber > 1 && !pageStartsWithSurahHeader(pageModel))
        ? kMushafPageDividerExtent
        : 0.0;
    final lineTop =
        divider +
        mushafOffsetToLine(
          pageModel,
          lineIndex,
          lineSlotHeight,
          withTranslations: withTranslations,
        );
    final blockHeight = mushafPlayingBlockHeight(
      pageModel,
      item,
      lineSlotHeight,
      withTranslations: withTranslations,
    );
    final lineBottom = lineTop + blockHeight;

    final pageIndex = pageNumber - 1;
    ItemPosition? pagePos;
    for (final position in _positionsListener.itemPositions.value) {
      if (position.index == pageIndex) {
        pagePos = position;
        break;
      }
    }

    if (pagePos == null) {
      if (_highlightRetries > 8) return;
      _highlightRetries++;
      _goToPage(pageNumber, animate: true);
      Future<void>.delayed(const Duration(milliseconds: 360), () {
        if (mounted && !_userDetached) {
          _scrollHighlightIntoView(pageNumber, item);
        }
      });
      return;
    }

    _highlightRetries = 0;

    final pageTopOnScreen = pagePos.itemLeadingEdge * viewportHeight;
    final blockTop = pageTopOnScreen + lineTop;
    final blockBottom = pageTopOnScreen + lineBottom;
    final minTop = viewportHeight * _highlightMinTop;
    final maxBottom = viewportHeight * _highlightMaxBottom;

    if (blockTop >= minTop - 4 && blockBottom <= maxBottom + 4) {
      _lastHighlightScrollKey = scrollKey;
      return;
    }

    var delta = 0.0;
    if (blockBottom > maxBottom) {
      delta = blockBottom - maxBottom;
    }
    if (blockTop - delta < minTop) {
      delta = blockTop - minTop;
    }
    if (delta.abs() < 8) return;
    final alreadyTried = _lastHighlightScrollKey == scrollKey;
    _lastHighlightScrollKey = scrollKey;
    if (alreadyTried && delta.abs() < 16) return;

    _beginSyncingScroll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _userDetached) return;
      _scrollOffsetController.animateScroll(
        offset: delta,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onPlaybackItemTap(MushafPlaybackItem item) {
    _followBackTimer?.cancel();
    _userDetached = false;
    _lastHighlightScrollKey = null;
    final continuePages = ref.read(quranPlayerProvider).mushafContinuePages;
    ref
        .read(quranPlayerProvider.notifier)
        .playMushafFromItem(item, continuePages: continuePages);
  }

  QcfThemeData _qcfTheme(BuildContext context, QuranPlayerState player) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return QcfThemeData(
      pageBackgroundColor: isDark ? AppTheme.night : const Color(0xFFFDFBF7),
      verseTextColor: scheme.onSurface,
      basmalaColor: scheme.primary,
      headerTextColor: scheme.primary,
      verseNumberColor: scheme.primary,
      showHeader: false,
      showBasmala: true,
      horizontalPadding: 6,
      verseBackgroundColor: (surah, verse) {
        if (!player.isMushafPlayback) return null;
        final current = player.currentMushafItem;
        if (current == null || current.isBismillah) return null;
        if (current.surah == surah && current.ayah == verse) {
          return scheme.primary.withValues(alpha: 0.22);
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(quranPlayerProvider.select((s) => s.followKey));
    final player = ref.read(quranPlayerProvider);
    final ctrl = ref.read(quranPlayerProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;
    final audioVisible = player.isMushafPlayback;
    final translationPlay =
        player.includeTranslationAudio || settings.showTranslation;
    final pageBg = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.night
        : const Color(0xFFFDFBF7);
    final theme = _qcfTheme(context, player);
    final pageHeight = _pageHeight(
      context,
      audioVisible: audioVisible,
      translationPlay: translationPlay,
    );

    if (!_didInitialJump) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didInitialJump) return;
        _didInitialJump = true;
        final playing = ref.read(quranPlayerProvider);
        final followPage = playing.isMushafPlayback
            ? (_playingPageOf(playing) ?? _currentPage)
            : _currentPage;
        _goToPage(followPage, animate: false);
        if (playing.isMushafPlayback) {
          _syncScrollFromPlayer(playing);
        }
        ref.read(mushafLayoutRepositoryProvider).preloadPages([
          followPage,
          followPage + 1,
          followPage + 2,
        ]);
      });
    }

    ref.listen(quranPlayerProvider, (prev, next) {
      if (prev?.followKey == next.followKey) return;
      if (!next.isMushafPlayback) {
        _lastSyncedPage = null;
        _lastHighlightScrollKey = null;
        _followBackTimer?.cancel();
        _userDetached = false;
        return;
      }
      if (_userDetached) return;
      final modeSwitch =
          prev?.includeTranslationAudio != next.includeTranslationAudio;
      if (modeSwitch) {
        _lastHighlightScrollKey = null;
        _highlightRetries = 0;
        _syncScrollFromPlayer(next);
        return;
      }
      if (prev?.currentPlaylistIndex != next.currentPlaylistIndex ||
          prev?.mushafPage != next.mushafPage ||
          prev?.isPlayingTranslation != next.isPlayingTranslation) {
        _lastHighlightScrollKey = null;
        _syncScrollFromPlayer(next);
      }
    });

    final pageModelAsync = ref.watch(mushafPageModelProvider(_currentPage));
    final surahName = pageModelAsync.maybeWhen(
      data: (p) => getSurahNameArabic(p.primarySurah),
      orElse: () => MushafNavigation.surahNameArabicForPage(_currentPage),
    );
    final juz = pageModelAsync.maybeWhen(
      data: (p) => p.juz,
      orElse: () => MushafNavigation.juzForPage(_currentPage),
    );

    final t = AppStrings.of(context);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.juzPageTitle(juz, _currentPage, MushafPageModel.totalPages),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              surahName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.arabicText(
                context,
                fontSize: 16,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.text_increase_rounded),
            onPressed: () {
              ref
                  .read(settingsProvider.notifier)
                  .setFontScale(settings.quranFontScale + 0.05);
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease_rounded),
            onPressed: () {
              ref
                  .read(settingsProvider.notifier)
                  .setFontScale(settings.quranFontScale - 0.05);
            },
          ),
        ],
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (_syncingScroll) return false;
          final playing = ref.read(quranPlayerProvider);
          if (playing.isMushafPlayback && playing.hasActiveTrack) {
            _scheduleFollowBack();
          }
          return false;
        },
        child: ScrollablePositionedList.builder(
          itemCount: MushafPageModel.totalPages,
          itemScrollController: _scrollController,
          scrollOffsetController: _scrollOffsetController,
          itemPositionsListener: _positionsListener,
          itemBuilder: (context, index) {
            final pageNumber = index + 1;
            final asyncPage = ref.watch(mushafPageModelProvider(pageNumber));
            final isPlayingPage =
                player.isMushafPlayback && player.mushafPage == pageNumber;
            final currentItem = player.isMushafPlayback
                ? player.currentMushafItem
                : null;
            final showTranslation = settings.showTranslation;

            return RepaintBoundary(
              child: ColoredBox(
                color: pageBg,
                child: asyncPage.when(
                  data: (page) {
                    final showDivider =
                        pageNumber > 1 && !pageStartsWithSurahHeader(page);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showDivider)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 22,
                              horizontal: 16,
                            ),
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        MadinahMushafPageRenderer(
                          page: page,
                          height: pageHeight,
                          fontScale: settings.quranFontScale,
                          theme: theme,
                          accentColor: scheme.primary,
                          playingItem: isPlayingPage ? currentItem : null,
                          listenMode: audioVisible,
                          onPlaybackItemTap: audioVisible
                              ? _onPlaybackItemTap
                              : null,
                          showTranslation: showTranslation,
                          translation: MushafTranslation.fromEditionId(
                            settings.defaultTranslationId,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => SizedBox(
                    height: pageHeight,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, _) => SizedBox(
                    height: pageHeight,
                    child: Center(child: Text(t.pageFailedToLoad(pageNumber))),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (audioVisible) const MushafAudioBar(embedded: true),
          QuranNavBar(
            playing:
                audioVisible && (player.playing || player.isPlayingTranslation),
            translationOn: settings.showTranslation,
            onPlay: () {
              if (audioVisible) {
                ctrl.togglePlayPause();
              } else {
                _startListening();
              }
            },
            onSearch: _openGoTo,
            onToggleTranslation: () async {
              final next = !settings.showTranslation;
              final keepPlaying = ref
                  .read(quranPlayerProvider)
                  .isMushafPlayback;
              await ref
                  .read(settingsProvider.notifier)
                  .setShowTranslation(next);
              if (keepPlaying) {
                _userDetached = false;
                _lastHighlightScrollKey = null;
                _highlightRetries = 0;
                await ctrl.continueMushafWithCurrentSettings();
                if (mounted) _forceFollowPlaying();
              }
            },
          ),
        ],
      ),
    );
  }
}
