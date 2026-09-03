import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/prayer/presentation/providers/prayer_providers.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

class DeenConnectApp extends ConsumerWidget {
  const DeenConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(prayerTimesProvider, (_, __) {
      syncPrayerNotifications(ref);
    });
    ref.listen(prayerTimesTomorrowProvider, (_, __) {
      syncPrayerNotifications(ref);
    });
    ref.listen(settingsProvider, (prev, next) {
      if (prev?.prayerNotifications == next.prayerNotifications &&
          prev?.localeCode == next.localeCode &&
          prev?.prayerCalculationMethod == next.prayerCalculationMethod &&
          prev?.prayerMadhab == next.prayerMadhab &&
          prev?.prayerMethodAuto == next.prayerMethodAuto &&
          prev?.prayerMadhabAuto == next.prayerMadhabAuto &&
          prev?.adhanSound == next.adhanSound &&
          prev?.useGpsLocation == next.useGpsLocation &&
          prev?.locationCityId == next.locationCityId &&
          prev?.locationLabel == next.locationLabel &&
          prev?.locationCountry == next.locationCountry) {
        return;
      }
      syncPrayerNotifications(ref);
    });

    final router = ref.watch(goRouterProvider);
    final settings = ref.watch(settingsProvider);

    final themeMode = settings.themeMode;
    final light = AppTheme.light(null);
    final dark = AppTheme.dark(null);

    final locale = Locale(settings.localeCode);

    return MaterialApp.router(
      title: 'Deen Islam',
      debugShowCheckedModeBanner: false,
      theme: light,
      darkTheme: dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('ur'),
        Locale('fr'),
      ],
      localeResolutionCallback: (_, __) => locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final rtl = settings.localeCode == 'ar' || settings.localeCode == 'ur';
        return AppStringsScope(
          localeCode: settings.localeCode,
          child: Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      routerConfig: router,
    );
  }
}
