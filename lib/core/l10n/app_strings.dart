import 'package:flutter/widgets.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:quran/quran.dart' as q;

import '../../features/prayer/domain/prayer_method.dart';

/// Pushes the user's chosen language below [MaterialApp], so every
/// [AppStrings.of] call follows Settings — not the device locale.
class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    super.key,
    required this.localeCode,
    required super.child,
  });

  final String localeCode;

  static String codeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStringsScope>();
    return scope?.localeCode ?? Localizations.localeOf(context).languageCode;
  }

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) =>
      localeCode != oldWidget.localeCode;
}

/// Lightweight app copy keyed by [localeCode] (en / ar / ur / fr).
class AppStrings {
  AppStrings._(this._code);

  factory AppStrings.of(BuildContext context) {
    return AppStrings._(_normalize(AppStringsScope.codeOf(context)));
  }

  factory AppStrings.fromCode(String code) => AppStrings._(_normalize(code));

  static String _normalize(String code) {
    final c = code.toLowerCase().split(RegExp('[-_]')).first;
    return switch (c) {
      'ar' || 'ur' || 'fr' => c,
      _ => 'en',
    };
  }

  final String _code;

  String get languageCode => _c;

  String get _c => _code;

  String get _dateLocale => switch (_c) {
    'ar' || 'ur' || 'fr' => _c,
    _ => 'en',
  };

  String formatFullDate(DateTime d) {
    try {
      return DateFormat.yMMMMd(_dateLocale).format(d);
    } catch (_) {
      return DateFormat.yMMMMd().format(d);
    }
  }

  String formatWeekdayDate(DateTime d) {
    try {
      return DateFormat('EEEE · MMM d', _dateLocale).format(d);
    } catch (_) {
      return DateFormat('EEEE · MMM d').format(d);
    }
  }

  String formatHijriDate(DateTime d) {
    final h = HijriCalendar.fromDate(d);
    return '${h.hDay} ${hijriMonth(h.hMonth)} ${h.hYear}';
  }

  String hijriMonth(int month) => switch (month) {
    1 => _t('Muharram', ar: 'محرم', ur: 'محرم', fr: 'Mouharram'),
    2 => _t('Safar', ar: 'صفر', ur: 'صفر', fr: 'Safar'),
    3 => _t(
      'Rabi’ al-Awwal',
      ar: 'ربيع الأول',
      ur: 'ربیع الاول',
      fr: 'Rabi’ al-Awwal',
    ),
    4 => _t(
      'Rabi’ al-Thani',
      ar: 'ربيع الآخر',
      ur: 'ربیع الثانی',
      fr: 'Rabi’ al-Thani',
    ),
    5 => _t(
      'Jumada al-Ula',
      ar: 'جمادى الأولى',
      ur: 'جمادی الاولی',
      fr: 'Joumada al-Oula',
    ),
    6 => _t(
      'Jumada al-Thani',
      ar: 'جمادى الآخرة',
      ur: 'جمادی الثانی',
      fr: 'Joumada al-Thani',
    ),
    7 => _t('Rajab', ar: 'رجب', ur: 'رجب', fr: 'Rajab'),
    8 => _t('Sha’ban', ar: 'شعبان', ur: 'شعبان', fr: 'Chaabane'),
    9 => _t('Ramadan', ar: 'رمضان', ur: 'رمضان', fr: 'Ramadan'),
    10 => _t('Shawwal', ar: 'شوال', ur: 'شوال', fr: 'Chawwal'),
    11 => _t(
      'Dhul-Qa’dah',
      ar: 'ذو القعدة',
      ur: 'ذوالقعدہ',
      fr: 'Dhou al-Qi’da',
    ),
    12 => _t('Dhul-Hijjah', ar: 'ذو الحجة', ur: 'ذوالحجہ', fr: 'Dhou al-Hijja'),
    _ => '$month',
  };

  String formatTime(DateTime d) {
    try {
      return DateFormat.jm(_dateLocale).format(d);
    } catch (_) {
      return DateFormat.jm().format(d);
    }
  }

  String countdown(Duration diff) {
    final d = diff.isNegative ? Duration.zero : diff;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return switch (_c) {
      'ar' => '$h س $m د $s ث',
      'ur' => '$h گھ $m م $s س',
      'fr' => '$h h $m min $s s',
      _ => '${h}h ${m}m ${s}s',
    };
  }

  String surahName(int number) {
    if (number < 1 || number > 114) {
      return '$surahWord $number';
    }
    return switch (_c) {
      'ar' => q.getSurahNameArabic(number),
      'fr' => q.getSurahNameFrench(number),
      _ => q.getSurahNameEnglish(number),
    };
  }

  String surahWordNumber(int number) => '$surahWord $number';

  String surahAyahRef(int surah, int ayah) =>
      '${surahName(surah)} $surah:$ayah';

  String continueSurahAyah(int surah, int ayah) =>
      '$surahWord $surah · $ayahWord $ayah';

  String ayahsCount(int n) => switch (_c) {
    'ar' => '$n آيات',
    'ur' => '$n آیتیں',
    'fr' => '$n versets',
    _ => '$n ayahs',
  };

  String savedCount(int n) => switch (_c) {
    'ar' => '$n محفوظ',
    'ur' => '$n محفوظ',
    'fr' => '$n enregistrés',
    _ => '$n saved',
  };

  String pageLabel(int n) => switch (_c) {
    'ar' => 'صفحة $n',
    'ur' => 'صفحہ $n',
    'fr' => 'Page $n',
    _ => 'Page $n',
  };

  String juzLabel(int n) => switch (_c) {
    'ar' => 'جزء $n',
    'ur' => 'پارہ $n',
    'fr' => 'Jouz $n',
    _ => 'Juz $n',
  };

  String juzPageTitle(int juz, int page, int total) => switch (_c) {
    'ar' => 'جزء $juz · صفحة $page / $total',
    'ur' => 'پارہ $juz · صفحہ $page / $total',
    'fr' => 'Jouz $juz · Page $page / $total',
    _ => 'Juz $juz · Page $page / $total',
  };

  String startsOnPage(int page) => switch (_c) {
    'ar' => 'تبدأ في الصفحة $page',
    'ur' => 'صفحہ $page سے شروع',
    'fr' => 'Commence à la page $page',
    _ => 'Starts on page $page',
  };

  String enterPage(int total) => switch (_c) {
    'ar' => 'أدخل صفحة بين 1 و $total',
    'ur' => '1 سے $total کے درمیان صفحہ درج کریں',
    'fr' => 'Entrez une page entre 1 et $total',
    _ => 'Enter a page between 1 and $total',
  };

  String pageFailedToLoad(int page) => switch (_c) {
    'ar' => 'تعذّر تحميل الصفحة $page',
    'ur' => 'صفحہ $page لوڈ نہیں ہو سکا',
    'fr' => 'Impossible de charger la page $page',
    _ => 'Page $page failed to load',
  };

  String surahPageSubtitle(String arabicName, int page) =>
      '$arabicName · ${pageLabel(page)}';

  String targetLabel(int n) => switch (_c) {
    'ar' => 'الهدف · $n',
    'ur' => 'ہدف · $n',
    'fr' => 'Objectif · $n',
    _ => 'Target · $n',
  };

  String ofTargetCompleted(int target, int loops) => switch (_c) {
    'ar' => 'من $target · اكتمل ×$loops',
    'ur' => '$target میں سے · مکمل ×$loops',
    'fr' => 'sur $target · terminé ×$loops',
    _ => 'of $target · completed ×$loops',
  };

  String degreesFromNorth(String degrees) => switch (_c) {
    'ar' => '$degrees° من الشمال الحقيقي',
    'ur' => 'حقیقی شمال سے $degrees°',
    'fr' => '$degrees° du nord vrai',
    _ => '$degrees° from true north',
  };

  String degreesToGo(String degrees) => switch (_c) {
    'ar' => 'تبقّى $degrees°',
    'ur' => '$degrees° باقی',
    'fr' => '$degrees° restants',
    _ => '$degrees° to go',
  };

  String prayerName(String key) => switch (key) {
    'Fajr' => _t('Fajr', ar: 'الفجر', ur: 'فجر', fr: 'Fajr'),
    'Sunrise' => _t(
      'Sunrise',
      ar: 'الشروق',
      ur: 'طلوع آفتاب',
      fr: 'Lever du soleil',
    ),
    'Dhuhr' => _t('Dhuhr', ar: 'الظهر', ur: 'ظہر', fr: 'Dhuhr'),
    'Asr' => _t('Asr', ar: 'العصر', ur: 'عصر', fr: 'Asr'),
    'Maghrib' => _t('Maghrib', ar: 'المغرب', ur: 'مغرب', fr: 'Maghrib'),
    'Isha' => _t('Isha', ar: 'العشاء', ur: 'عشاء', fr: 'Isha'),
    'LastThird' => _t(
      'Last third of the night',
      ar: 'الثلث الأخير من الليل',
      ur: 'رات کا آخری تہائی',
      fr: 'Dernier tiers de la nuit',
    ),
    _ => key,
  };

  String translationEdition(String id) => switch (id) {
    'en.sahih' => _t(
      'English — Saheeh International',
      ar: 'الإنجليزية — صحيح إنترناشيونال',
      ur: 'انگریزی — صحیح انٹرنیشنل',
      fr: 'Anglais — Saheeh International',
    ),
    'ur.jalandhry' => _t('Urdu', ar: 'الأردية', ur: 'اردو', fr: 'Ourdou'),
    'fr.hamidullah' => _t(
      'French — Hamidullah',
      ar: 'الفرنسية — حميد الله',
      ur: 'فرانسیسی — حمیداللہ',
      fr: 'Français — Hamidullah',
    ),
    _ => id,
  };

  String voiceStyle(String style) => switch (style) {
    'Soft' => _t('Soft', ar: 'ناعمة', ur: 'نرم', fr: 'Douce'),
    'Friendly' => _t('Friendly', ar: 'ودودة', ur: 'دوستانہ', fr: 'Amicale'),
    'Gravelly' => _t('Gravelly', ar: 'خشنة', ur: 'کھردری', fr: 'Rauque'),
    'Smooth' => _t('Smooth', ar: 'سلسة', ur: 'سلیس', fr: 'Fluide'),
    'Firm' => _t('Firm', ar: 'واثقة', ur: 'مضبوط', fr: 'Assurée'),
    'Deep' => _t('Deep', ar: 'عميقة', ur: 'گہری', fr: 'Grave'),
    'Breezy' => _t('Breezy', ar: 'خفيفة', ur: 'ہلکی', fr: 'Légère'),
    'Bright' => _t('Bright', ar: 'مشرقة', ur: 'چمکدار', fr: 'Claire'),
    'Easy-going' => _t(
      'Easy-going',
      ar: 'هادئة',
      ur: 'آسان',
      fr: 'Décontractée',
    ),
    'Informative' => _t(
      'Informative',
      ar: 'واضحة',
      ur: 'معلوماتی',
      fr: 'Informative',
    ),
    'Breathy' => _t('Breathy', ar: 'همسية', ur: 'سرگوشی', fr: 'Voilée'),
    'Clear' => _t('Clear', ar: 'جليّة', ur: 'صاف', fr: 'Nette'),
    'Excitable' => _t('Excitable', ar: 'حماسية', ur: 'جذباتی', fr: 'Enjouée'),
    'Mature' => _t('Mature', ar: 'ناضجة', ur: 'پختہ', fr: 'Mature'),
    'Upbeat' => _t('Upbeat', ar: 'مبهجة', ur: 'خوشگوار', fr: 'Dynamique'),
    'Youthful' => _t('Youthful', ar: 'شابة', ur: 'جوان', fr: 'Jeune'),
    'Forward' => _t('Forward', ar: 'مباشرة', ur: 'آگے بڑھتی', fr: 'Directe'),
    'Lively' => _t('Lively', ar: 'حيوية', ur: 'زندہ دل', fr: 'Vivante'),
    'Knowledgeable' => _t(
      'Knowledgeable',
      ar: 'عليمة',
      ur: 'دانا',
      fr: 'Érudite',
    ),
    'Even' => _t('Even', ar: 'متزنة', ur: 'ہموار', fr: 'Posée'),
    'Warm' => _t('Warm', ar: 'دافئة', ur: 'گرم جوش', fr: 'Chaleureuse'),
    'Gentle' => _t('Gentle', ar: 'رقيقة', ur: 'نرم', fr: 'Douce'),
    'Casual' => _t('Casual', ar: 'عفوية', ur: 'غیر رسمی', fr: 'Décontractée'),
    _ => style,
  };

  String voiceLanguage(String code) => switch (code) {
    'fr' => localeFrench,
    'ur' => localeUrdu,
    _ => localeEnglish,
  };

  String duaCategoryTitle(String id) => switch (id) {
    'morning' => _t('Morning', ar: 'الصباح', ur: 'صبح', fr: 'Matin'),
    'evening' => _t('Evening', ar: 'المساء', ur: 'شام', fr: 'Soir'),
    'after_salah' => _t(
      'After Salah',
      ar: 'بعد الصلاة',
      ur: 'نماز کے بعد',
      fr: 'Après la prière',
    ),
    'sleep' => _t('Sleep', ar: 'النوم', ur: 'نیند', fr: 'Sommeil'),
    'home' => _t(
      'Home & Mosque',
      ar: 'البيت والمسجد',
      ur: 'گھر اور مسجد',
      fr: 'Maison et mosquée',
    ),
    'food' => _t(
      'Food & Drink',
      ar: 'الطعام والشراب',
      ur: 'کھانا پینا',
      fr: 'Nourriture et boisson',
    ),
    'travel' => _t('Travel', ar: 'السفر', ur: 'سفر', fr: 'Voyage'),
    'protection' => _t(
      'Protection',
      ar: 'الحماية',
      ur: 'حفاظت',
      fr: 'Protection',
    ),
    'forgiveness' => _t(
      'Forgiveness',
      ar: 'المغفرة',
      ur: 'مغفرت',
      fr: 'Pardon',
    ),
    'family' => _t('Family', ar: 'الأسرة', ur: 'خاندان', fr: 'Famille'),
    'quranic' => _t(
      'Quranic Duas',
      ar: 'أدعية قرآنية',
      ur: 'قرآنی دعائیں',
      fr: 'Invocations coraniques',
    ),
    'illness' => _t('Illness', ar: 'المرض', ur: 'بیماری', fr: 'Maladie'),
    'daily' => _t(
      'Daily Life',
      ar: 'الحياة اليومية',
      ur: 'روزمرہ',
      fr: 'Vie quotidienne',
    ),
    'hajj' => _t(
      'Hajj & Umrah',
      ar: 'الحج والعمرة',
      ur: 'حج و عمرہ',
      fr: 'Hajj et Omra',
    ),
    _ => id,
  };

  String duaCategorySubtitle(String id) => switch (id) {
    'morning' => _t(
      'Adhkar after Fajr',
      ar: 'أذكار بعد الفجر',
      ur: 'فجر کے بعد اذکار',
      fr: 'Invocations après Fajr',
    ),
    'evening' => _t(
      'Adhkar after Asr',
      ar: 'أذكار بعد العصر',
      ur: 'عصر کے بعد اذکار',
      fr: 'Invocations après Asr',
    ),
    'after_salah' => _t(
      'Remembrance after prayer',
      ar: 'الذكر بعد الصلاة',
      ur: 'نماز کے بعد ذکر',
      fr: 'Évocations après la prière',
    ),
    'sleep' => _t(
      'Before bed & waking',
      ar: 'قبل النوم والاستيقاظ',
      ur: 'سونے اور جاگنے پر',
      fr: 'Avant de dormir et au réveil',
    ),
    'home' => _t(
      'Entering and leaving',
      ar: 'الدخول والخروج',
      ur: 'داخل ہونے اور نکلنے پر',
      fr: 'Entrer et sortir',
    ),
    'food' => _t(
      'Before and after meals',
      ar: 'قبل الطعام وبعده',
      ur: 'کھانے سے پہلے اور بعد',
      fr: 'Avant et après les repas',
    ),
    'travel' => _t(
      'On the journey',
      ar: 'أثناء السفر',
      ur: 'سفر کے دوران',
      fr: 'Pendant le voyage',
    ),
    'protection' => _t(
      'Fear, anxiety, ruqyah',
      ar: 'الخوف والقلق والرقية',
      ur: 'خوف، پریشانی، رقیہ',
      fr: 'Peur, anxiété, ruqya',
    ),
    'forgiveness' => _t(
      'Istighfar & repentance',
      ar: 'الاستغفار والتوبة',
      ur: 'استغفار اور توبہ',
      fr: 'Istighfar et repentir',
    ),
    'family' => _t(
      'Parents & children',
      ar: 'الوالدان والأبناء',
      ur: 'والدین اور بچے',
      fr: 'Parents et enfants',
    ),
    'quranic' => _t(
      'From the Qur’an',
      ar: 'من القرآن الكريم',
      ur: 'قرآن سے',
      fr: 'Tirées du Coran',
    ),
    'illness' => _t(
      'Healing & visiting sick',
      ar: 'الشفاء وعيادة المريض',
      ur: 'شفا اور عیادت',
      fr: 'Guérison et visite du malade',
    ),
    'daily' => _t(
      'Clothes, toilet, sneezing',
      ar: 'اللباس والدخول والعطاس',
      ur: 'کپڑے، بیت الخلاء، چھینک',
      fr: 'Vêtements, toilettes, éternuement',
    ),
    'hajj' => _t(
      'Pilgrimage remembrances',
      ar: 'أذكار الحج والعمرة',
      ur: 'حج و عمرہ کے اذکار',
      fr: 'Évocations du pèlerinage',
    ),
    _ => '',
  };

  String friendlyError(Object error) {
    final s = error.toString();
    if (s.contains('Location permission')) return locationPermissionDenied;
    if (s.contains('429') || s.toLowerCase().contains('rate limit')) {
      return voiceRateLimited;
    }
    if (s.toLowerCase().contains('piper') ||
        s.toLowerCase().contains('kokoro') ||
        s.toLowerCase().contains('tts') ||
        s.toLowerCase().contains('download the')) {
      return voicePreviewFailed;
    }
    if (s.toLowerCase().contains('gemini')) return voicePreviewFailed;
    return s;
  }

  String get settings =>
      _t('Settings', ar: 'الإعدادات', ur: 'ترتیبات', fr: 'Réglages');
  String get appearance =>
      _t('Appearance', ar: 'المظهر', ur: 'ظاہری شکل', fr: 'Apparence');
  String get themeAndLanguage => _t(
    'Theme and language',
    ar: 'السمة واللغة',
    ur: 'تھیم اور زبان',
    fr: 'Thème et langue',
  );
  String get darkMode =>
      _t('Dark mode', ar: 'الوضع الداكن', ur: 'ڈارک موڈ', fr: 'Mode sombre');
  String get darkModeSubtitle => _t(
    'Use a darker color scheme',
    ar: 'استخدم مظهراً داكناً',
    ur: 'گہرا رنگ استعمال کریں',
    fr: 'Utiliser un thème sombre',
  );
  String get appLanguage =>
      _t('App language', ar: 'لغة التطبيق', ur: 'ایپ کی زبان', fr: 'Langue');
  String get localeEnglish =>
      _t('English', ar: 'الإنجليزية', ur: 'انگریزی', fr: 'Anglais');
  String get localeArabic =>
      _t('Arabic', ar: 'العربية', ur: 'عربی', fr: 'Arabe');
  String get localeUrdu => _t('Urdu', ar: 'الأردية', ur: 'اردو', fr: 'Ourdou');
  String get localeFrench =>
      _t('French', ar: 'الفرنسية', ur: 'فرانسیسی', fr: 'Français');
  String get quran => _t('Quran', ar: 'القرآن', ur: 'قرآن', fr: 'Coran');
  String get learnQuran => _t(
    'Learn Quran',
    ar: 'تعلّم القرآن',
    ur: 'قرآن سیکھیں',
    fr: 'Apprendre le Coran',
  );
  String get duas => _t('Duas', ar: 'الأدعية', ur: 'دعائیں', fr: 'Invocations');
  String get tasbeeh => _t('Tasbeeh', ar: 'التسبيح', ur: 'تسبیح', fr: 'Tasbih');
  String get namesOfAllah => _t(
    'Names of Allah',
    ar: 'أسماء الله',
    ur: 'اسماء اللہ',
    fr: "Noms d'Allah",
  );
  String get prayer => _t('Prayer', ar: 'الصلاة', ur: 'نماز', fr: 'Prière');
  String get qibla => _t('Qibla', ar: 'القبلة', ur: 'قبلہ', fr: 'Qibla');
  String get bookmarks =>
      _t('Bookmarks', ar: 'الإشارات', ur: 'بک مارکس', fr: 'Signets');
  String get noBookmarksYet => _t(
    'No bookmarked ayahs yet',
    ar: 'لا توجد آيات محفوظة بعد',
    ur: 'ابھی کوئی محفوظ آیت نہیں',
    fr: 'Aucun verset enregistré pour le moment',
  );
  String get openInSurahReader => _t(
    'Open in surah reader',
    ar: 'فتح في قارئ السورة',
    ur: 'سورہ ریڈر میں کھولیں',
    fr: 'Ouvrir dans le lecteur de sourate',
  );
  String get explore =>
      _t('Explore', ar: 'استكشف', ur: 'دریافت کریں', fr: 'Explorer');
  String get exploreSubtitle => _t(
    'Quran, prayer, and more',
    ar: 'القرآن والصلاة والمزيد',
    ur: 'قرآن، نماز اور مزید',
    fr: 'Coran, prière et plus',
  );
  String get continueReading => _t(
    'Continue reading',
    ar: 'متابعة القراءة',
    ur: 'پڑھنا جاری رکھیں',
    fr: 'Continuer la lecture',
  );
  String get ayahOfTheDay => _t(
    'Ayah of the day',
    ar: 'آية اليوم',
    ur: 'آج کی آیت',
    fr: 'Verset du jour',
  );
  String get duaOfTheDay => _t(
    'Dua of the day',
    ar: 'دعاء اليوم',
    ur: 'آج کی دعا',
    fr: 'Invocation du jour',
  );
  String get tasbeehOfTheDay => _t(
    'Tasbeeh of the day',
    ar: 'تسبيح اليوم',
    ur: 'آج کا تسبیح',
    fr: 'Tasbih du jour',
  );
  String get upNext => _t('Up next', ar: 'التالي', ur: 'اگلی', fr: 'À venir');
  String get prayerTimes => _t(
    'Prayer times',
    ar: 'أوقات الصلاة',
    ur: 'نماز کے اوقات',
    fr: 'Horaires de prière',
  );
  String get viewAll =>
      _t('View all', ar: 'عرض الكل', ur: 'سب دیکھیں', fr: 'Tout voir');
  String get play => _t('Play', ar: 'تشغيل', ur: 'چلائیں', fr: 'Lecture');
  String get pause => _t('Pause', ar: 'إيقاف', ur: 'روکیں', fr: 'Pause');
  String get stop => _t('Stop', ar: 'توقف', ur: 'روکیں', fr: 'Arrêter');
  String get reset =>
      _t('Reset', ar: 'إعادة', ur: 'ری سیٹ', fr: 'Réinitialiser');
  String get refresh =>
      _t('Refresh', ar: 'تحديث', ur: 'تازہ کریں', fr: 'Actualiser');
  String get retry =>
      _t('Retry', ar: 'إعادة المحاولة', ur: 'دوبارہ', fr: 'Réessayer');
  String get go => _t('Go', ar: 'انتقل', ur: 'جائیں', fr: 'Aller');
  String get goTo =>
      _t('Go to', ar: 'الانتقال إلى', ur: 'جائیں', fr: 'Aller à');
  String get searchSurah => _t(
    'Search Surah',
    ar: 'بحث عن سورة',
    ur: 'سورہ تلاش',
    fr: 'Chercher sourate',
  );
  String get translation =>
      _t('Translation', ar: 'الترجمة', ur: 'ترجمہ', fr: 'Traduction');
  String get showTranslation => _t(
    'Show translation',
    ar: 'إظهار الترجمة',
    ur: 'ترجمہ دکھائیں',
    fr: 'Afficher la traduction',
  );
  String get showTranslationSubtitle => _t(
    'Display translation under each ayah',
    ar: 'إظهار الترجمة تحت كل آية',
    ur: 'ہر آیت کے نیچے ترجمہ دکھائیں',
    fr: 'Afficher la traduction sous chaque verset',
  );
  String get defaultTranslation => _t(
    'Default translation',
    ar: 'الترجمة الافتراضية',
    ur: 'طے شدہ ترجمہ',
    fr: 'Traduction par défaut',
  );
  String get nextPrayer => _t(
    'NEXT PRAYER',
    ar: 'الصلاة التالية',
    ur: 'اگلی نماز',
    fr: 'PROCHAINE PRIÈRE',
  );
  String get legal =>
      _t('Legal', ar: 'قانوني', ur: 'قانونی', fr: 'Mentions légales');
  String get privacyPolicy => _t(
    'Privacy Policy',
    ar: 'سياسة الخصوصية',
    ur: 'رازداری کی پالیسی',
    fr: 'Politique de confidentialité',
  );
  String lastUpdatedOn(String date) => switch (_c) {
    'ar' => 'آخر تحديث $date',
    'ur' => 'آخری تازہ کاری $date',
    'fr' => 'Dernière mise à jour $date',
    _ => 'Last updated $date',
  };
  String get privacyPolicySubtitle => _t(
    'How Deen Islam uses your data',
    ar: 'كيف يستخدم التطبيق بياناتك',
    ur: 'ایپ آپ کا ڈیٹا کیسے استعمال کرتی ہے',
    fr: 'Comment Deen Islam utilise vos données',
  );
  String get quranPrefsSubtitle => _t(
    'Reading and listen preferences',
    ar: 'تفضيلات القراءة والاستماع',
    ur: 'پڑھنے اور سننے کی ترجیحات',
    fr: 'Préférences de lecture et d’écoute',
  );
  String get arabicFontSize => _t(
    'Arabic font size',
    ar: 'حجم الخط العربي',
    ur: 'عربی فونٹ سائز',
    fr: 'Taille du texte arabe',
  );
  String get arabicReciter => _t(
    'Arabic reciter',
    ar: 'قارئ العربية',
    ur: 'عربی قاری',
    fr: 'Récitateur arabe',
  );
  String get arabicReciterHint => _t(
    'Voice used for Quran audio',
    ar: 'الصوت المستخدم لتلاوة القرآن',
    ur: 'قرآن کی تلاوت کی آواز',
    fr: 'Voix utilisée pour le Coran',
  );
  String get arabicReciterSubtitle => _t(
    'Used when listening to ayahs',
    ar: 'يُستخدم عند الاستماع للآيات',
    ur: 'آیات سنتے وقت استعمال ہوتی ہے',
    fr: 'Utilisée à l’écoute des versets',
  );
  String get translationVoice => _t(
    'Translation voice',
    ar: 'صوت الترجمة',
    ur: 'ترجمے کی آواز',
    fr: 'Voix de traduction',
  );
  String get translationVoiceHint => _t(
    'On-device voice for translation audio',
    ar: 'صوت على الجهاز لتلاوة الترجمة',
    ur: 'ترجمے کی آواز اس فون پر',
    fr: 'Voix hors ligne pour la traduction',
  );
  String get translationVoiceSubtitle => _t(
    'Tap to hear a sample. English uses Kokoro (~100 MB once, shared). French and Urdu use Piper (~20 MB each). After that, speech stays on this phone.',
    ar: 'اضغط لسماع عيّنة. الإنجليزية تستخدم كوكورو (نحو 100 ميغابايت مرة واحدة). الفرنسية والأردية تستخدمان بايبر (نحو 20 ميغابايت لكل صوت). ثم يعمل دون إنترنت.',
    ur: 'نمونہ سننے کے لیے ٹیپ کریں۔ انگریزی کوکورو استعمال کرتی ہے (~۱۰۰ ایم بی ایک بار)۔ فرانسیسی اور اردو پائپر استعمال کرتی ہیں (~۲۰ ایم بی فی آواز)۔ پھر آف لائن چلتی ہے۔',
    fr: 'Touchez pour entendre un échantillon. L’anglais utilise Kokoro (~100 Mo une fois, partagé). Le français et l’ourdou utilisent Piper (~20 Mo chacun). Ensuite, la lecture reste sur cet appareil.',
  );
  String get voiceGroupEnglishKokoro => _t(
    'English · Kokoro',
    ar: 'الإنجليزية · كوكورو',
    ur: 'انگریزی · کوکورو',
    fr: 'Anglais · Kokoro',
  );
  String get voiceGroupFrenchPiper => _t(
    'French · Piper',
    ar: 'الفرنسية · بايبر',
    ur: 'فرانسیسی · پائپر',
    fr: 'Français · Piper',
  );
  String get voiceGroupUrduPiper => _t(
    'Urdu · Piper',
    ar: 'الأردية · بايبر',
    ur: 'اردو · پائپر',
    fr: 'Ourdou · Piper',
  );
  String get voiceRateLimited => _t(
    'Could not download this voice. Check the connection and try again.',
    ar: 'تعذر تنزيل هذا الصوت. تحقق من الاتصال وأعد المحاولة.',
    ur: 'یہ آواز ڈاؤن لوڈ نہیں ہو سکی۔ کنکشن چیک کر کے دوبارہ کوشش کریں۔',
    fr: 'Impossible de télécharger cette voix. Vérifiez la connexion et réessayez.',
  );
  String get voicePreviewFailed => _t(
    'Could not load this voice. Check the connection and try again.',
    ar: 'تعذر تحميل هذا الصوت. تحقق من الاتصال وأعد المحاولة.',
    ur: 'یہ آواز نہیں چل سکی۔ کنکشن چیک کر کے دوبارہ کوشش کریں۔',
    fr: 'Impossible de charger cette voix. Vérifiez la connexion et réessayez.',
  );
  String get arabicChip => _t('Arabic', ar: 'العربية', ur: 'عربی', fr: 'Arabe');
  String get voiceChip => _t('Voice', ar: 'الصوت', ur: 'آواز', fr: 'Voix');
  String get arabicSpeed => _t(
    'Arabic speed',
    ar: 'سرعة التلاوة',
    ur: 'عربی رفتار',
    fr: 'Vitesse arabe',
  );
  String get arabicSpeedHint => _t(
    'Recitation speed only — translation voice stays normal',
    ar: 'سرعة التلاوة فقط — صوت الترجمة يبقى عادياً',
    ur: 'صرف تلاوت کی رفتار — ترجمہ کی آواز ویسی ہی رہے گی',
    fr: 'Vitesse de récitation uniquement — la voix de traduction reste normale',
  );
  String arabicSpeedName(double speed) {
    if ((speed - 0.5).abs() < 0.001) {
      return _t('Very slow', ar: 'بطيء جداً', ur: 'بہت آہستہ', fr: 'Très lent');
    }
    if ((speed - 0.75).abs() < 0.001) {
      return _t('Slow', ar: 'بطيء', ur: 'آہستہ', fr: 'Lent');
    }
    if ((speed - 1.25).abs() < 0.001) {
      return _t('Fast', ar: 'سريع', ur: 'تیز', fr: 'Rapide');
    }
    if ((speed - 1.5).abs() < 0.001) {
      return _t('Very fast', ar: 'سريع جداً', ur: 'بہت تیز', fr: 'Très rapide');
    }
    return _t('Normal', ar: 'عادي', ur: 'عام', fr: 'Normale');
  }

  String get prayerNotifications => _t(
    'Prayer notifications',
    ar: 'تنبيهات الصلاة',
    ur: 'نماز کی اطلاعیں',
    fr: 'Notifications de prière',
  );
  String get prayerNotificationsSubtitle => _t(
    'Local reminders at salah times for the next 7 days',
    ar: 'تذكيرات محلية عند دخول الوقت للأيام السبعة القادمة',
    ur: 'اگلے ۷ دن نماز کے وقت مقامی یاد دہانی',
    fr: 'Rappels locaux aux heures de prière pour les 7 prochains jours',
  );
  String get prayerSettingsSubtitle => _t(
    'Calculation method, Asr school, and reminders',
    ar: 'طريقة الحساب ومذهب العصر والتذكيرات',
    ur: 'حساب کا طریقہ، عصر کا مذہب، اور یاد دہانیاں',
    fr: 'Méthode de calcul, école pour Asr, et rappels',
  );
  String get prayerCalculationMethod => _t(
    'Calculation method',
    ar: 'طريقة الحساب',
    ur: 'حساب کا طریقہ',
    fr: 'Méthode de calcul',
  );
  String get prayerCalculationMethodHint => _t(
    'Automatic follows the city. You can still pick a method.',
    ar: 'التلقائي يتبع المدينة. يمكنك اختيار طريقة يدوياً.',
    ur: 'خودکار شہر کے مطابق ہے۔ آپ خود بھی طریقہ چن سکتے ہیں۔',
    fr: 'L’automatique suit la ville. Vous pouvez aussi choisir.',
  );
  String prayerMethodName(PrayerCalculationMethod method) => switch (method) {
    PrayerCalculationMethod.auto => _t(
      'Automatic (by city)',
      ar: 'تلقائي (حسب المدينة)',
      ur: 'خودکار (شہر کے مطابق)',
      fr: 'Automatique (selon la ville)',
    ),
    PrayerCalculationMethod.muslimWorldLeague => _t(
      'Muslim World League',
      ar: 'رابطة العالم الإسلامي',
      ur: 'مسلم ورلڈ لیگ',
      fr: 'Ligue islamique mondiale',
    ),
    PrayerCalculationMethod.northAmerica => _t(
      'ISNA (North America)',
      ar: 'إسنى (أمريكا الشمالية)',
      ur: 'ISNA (شمالی امریکا)',
      fr: 'ISNA (Amérique du Nord)',
    ),
    PrayerCalculationMethod.egyptian => _t(
      'Egyptian General Authority',
      ar: 'الهيئة المصرية العامة للمساحة',
      ur: 'مصری جنرل اتھارٹی',
      fr: 'Autorité égyptienne',
    ),
    PrayerCalculationMethod.ummAlQura => _t(
      'Umm al-Qura (Makkah)',
      ar: 'أم القرى (مكة)',
      ur: 'ام القری (مکہ)',
      fr: 'Umm al-Qura (La Mecque)',
    ),
    PrayerCalculationMethod.karachi => _t(
      'University of Karachi',
      ar: 'جامعة كراتشي',
      ur: 'جامعہ کراچی',
      fr: 'Université de Karachi',
    ),
    PrayerCalculationMethod.turkiye => _t(
      'Türkiye Diyanet',
      ar: 'رئاسة الشؤون الدينية التركية',
      ur: 'ترکیہ دیانت',
      fr: 'Diyanet (Turquie)',
    ),
    PrayerCalculationMethod.moonsightingCommittee => _t(
      'Moonsighting Committee',
      ar: 'لجنة رؤية الهلال',
      ur: 'چاند دیکھنے کی کمیٹی',
      fr: 'Comité d’observation lunaire',
    ),
    PrayerCalculationMethod.dubai => _t(
      'Dubai',
      ar: 'دبي',
      ur: 'دبئی',
      fr: 'Dubaï',
    ),
    PrayerCalculationMethod.kuwait => _t(
      'Kuwait',
      ar: 'الكويت',
      ur: 'کویت',
      fr: 'Koweït',
    ),
    PrayerCalculationMethod.qatar => _t(
      'Qatar',
      ar: 'قطر',
      ur: 'قطر',
      fr: 'Qatar',
    ),
    PrayerCalculationMethod.singapore => _t(
      'Singapore',
      ar: 'سنغافورة',
      ur: 'سنگاپور',
      fr: 'Singapour',
    ),
    PrayerCalculationMethod.morocco => _t(
      'Morocco',
      ar: 'المغرب',
      ur: 'مراکش',
      fr: 'Maroc',
    ),
    PrayerCalculationMethod.france => _t(
      'France (UOIF)',
      ar: 'فرنسا (UOIF)',
      ur: 'فرانس (UOIF)',
      fr: 'France (UOIF)',
    ),
    PrayerCalculationMethod.indonesian => _t(
      'Indonesia (Kemenag)',
      ar: 'إندونيسيا (كيميناج)',
      ur: 'انڈونیشیا (کیمیناگ)',
      fr: 'Indonésie (Kemenag)',
    ),
    PrayerCalculationMethod.algerian => _t(
      'Algeria',
      ar: 'الجزائر',
      ur: 'الجزائر',
      fr: 'Algérie',
    ),
    PrayerCalculationMethod.jordan => _t(
      'Jordan',
      ar: 'الأردن',
      ur: 'اردن',
      fr: 'Jordanie',
    ),
    PrayerCalculationMethod.gulfRegion => _t(
      'Gulf Region',
      ar: 'دول الخليج',
      ur: 'خلیجی خطہ',
      fr: 'Région du Golfe',
    ),
    PrayerCalculationMethod.russia => _t(
      'Russia',
      ar: 'روسيا',
      ur: 'روس',
      fr: 'Russie',
    ),
    PrayerCalculationMethod.tunisia => _t(
      'Tunisia',
      ar: 'تونس',
      ur: 'تونس',
      fr: 'Tunisie',
    ),
    PrayerCalculationMethod.tehran => _t(
      'Tehran',
      ar: 'طهران',
      ur: 'تہران',
      fr: 'Téhéran',
    ),
  };
  String automaticMethodLabel(String resolved) => _t(
    'Automatic · $resolved',
    ar: 'تلقائي · $resolved',
    ur: 'خودکار · $resolved',
    fr: 'Automatique · $resolved',
  );
  String get prayerMadhab => _t(
    'Asr school (madhab)',
    ar: 'مذهب العصر',
    ur: 'عصر کا مذہب',
    fr: 'École pour Asr (madhab)',
  );
  String get prayerMadhabHint => _t(
    'Hanafi Asr is later than Shafi’i, Maliki, and Hanbali',
    ar: 'عصر الحنفي يأتي بعد الشافعي والمالكي والحنبلي',
    ur: 'حنفی عصر شافعی، مالکی اور حنبلی سے بعد میں ہے',
    fr: 'L’Asr hanafi est plus tardif que shafi’i, maliki et hanbali',
  );
  String prayerMadhabName(PrayerMadhab madhab) => switch (madhab) {
    PrayerMadhab.auto => _t(
      'Automatic (by city)',
      ar: 'تلقائي (حسب المدينة)',
      ur: 'خودکار (شہر کے مطابق)',
      fr: 'Automatique (selon la ville)',
    ),
    PrayerMadhab.shafi => _t(
      'Shafi’i / Maliki / Hanbali',
      ar: 'شافعي / مالكي / حنبلي',
      ur: 'شافعی / مالکی / حنبلی',
      fr: 'Chafiite / Malikite / Hanbalite',
    ),
    PrayerMadhab.hanafi => _t('Hanafi', ar: 'حنفي', ur: 'حنفی', fr: 'Hanafite'),
  };
  String get previousAyah => _t(
    'Previous ayah',
    ar: 'الآية السابقة',
    ur: 'پچھلی آیت',
    fr: 'Verset précédent',
  );
  String get nextAyah => _t(
    'Next ayah',
    ar: 'الآية التالية',
    ur: 'اگلی آیت',
    fr: 'Verset suivant',
  );
  String get repeatAyah => _t(
    'Repeat this ayah',
    ar: 'تكرار هذه الآية',
    ur: 'اس آیت کو دہرائیں',
    fr: 'Répéter ce verset',
  );
  String get storage =>
      _t('Storage', ar: 'التخزين', ur: 'اسٹوریج', fr: 'Stockage');
  String get recitationCache => _t(
    'Clear recitation cache',
    ar: 'مسح ذاكرة التلاوة',
    ur: 'تلاوت کی کیش صاف کریں',
    fr: 'Vider le cache de récitation',
  );
  String recitationCacheSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    final size = mb < 0.1
        ? '${(bytes / 1024).ceil()} KB'
        : '${mb.toStringAsFixed(1)} MB';
    return _t(
      '$size stored — tap to clear',
      ar: '$size مخزّنة — اضغط للمسح',
      ur: '$size محفوظ — صاف کرنے کے لیے دبائیں',
      fr: '$size enregistrés — touchez pour vider',
    );
  }

  String get recitationCacheCleared => _t(
    'Recitation cache cleared',
    ar: 'تم مسح ذاكرة التلاوة',
    ur: 'تلاوت کی کیش صاف ہو گئی',
    fr: 'Cache de récitation vidé',
  );
  String get notificationPermissionDenied => _t(
    'Notifications are off for Deen Islam. Enable them in iPhone or Android Settings, then try again.',
    ar: 'الإشعارات متوقفة لتطبيق دين إسلام. فعّلها من إعدادات الجهاز ثم أعد المحاولة.',
    ur: 'دین اسلام کے نوٹیفیکیشن بند ہیں۔ فون کی سیٹنگز میں آن کریں، پھر دوبارہ کوشش کریں۔',
    fr: 'Les notifications sont désactivées pour Deen Islam. Activez-les dans les réglages, puis réessayez.',
  );
  String get allPrayersComplete => _t(
    'All prayers complete for today',
    ar: 'اكتملت صلوات اليوم',
    ur: 'آج کی نمازیں مکمل ہو گئیں',
    fr: 'Toutes les prières du jour sont passées',
  );
  String get seeYouAtFajr => _t(
    'All prayers for today are complete. See you at Fajr.',
    ar: 'اكتملت صلوات اليوم. نراك عند الفجر.',
    ur: 'آج کی نمازیں مکمل ہیں۔ فجر پر ملتے ہیں۔',
    fr: 'Les prières d’aujourd’hui sont terminées. À Fajr.',
  );
  String get loadingPrayerTimes => _t(
    'Loading prayer times…',
    ar: 'جاري تحميل أوقات الصلاة…',
    ur: 'نماز کے اوقات لوڈ ہو رہے ہیں…',
    fr: 'Chargement des horaires…',
  );
  String get enableLocationForPrayerTimes => _t(
    'Enable location for prayer times',
    ar: 'فعّل الموقع لأوقات الصلاة',
    ur: 'نماز کے اوقات کے لیے مقام آن کریں',
    fr: 'Activez la localisation pour les horaires',
  );
  String get locationPermissionDenied => _t(
    'Location permission denied',
    ar: 'تم رفض إذن الموقع',
    ur: 'لوکیشن کی اجازت نہیں ملی',
    fr: 'Permission de localisation refusée',
  );
  String get prayerReminders => _t(
    'Prayer reminders',
    ar: 'تذكيرات الصلاة',
    ur: 'نماز کی یاددہانی',
    fr: 'Rappels de prière',
  );
  String get remindersOn => _t(
    'On — alerts at each salah',
    ar: 'مفعّل — تنبيه عند كل صلاة',
    ur: 'آن — ہر نماز پر اطلاع',
    fr: 'Activé — alerte à chaque prière',
  );
  String get remindersOff => _t(
    'Off — tap to open Settings',
    ar: 'متوقف — اضغط لفتح الإعدادات',
    ur: 'آف — سیٹنگز کھولنے کے لیے ٹیپ کریں',
    fr: 'Désactivé — touchez pour les réglages',
  );
  String get todaysTimes => _t(
    "Today's times",
    ar: 'أوقات اليوم',
    ur: 'آج کے اوقات',
    fr: 'Horaires du jour',
  );
  String get basedOnLocation => _t(
    'Based on your current location',
    ar: 'حسب موقعك الحالي',
    ur: 'موجودہ مقام کے مطابق',
    fr: 'Selon votre position actuelle',
  );
  String get currentLocation => _t(
    'Current location',
    ar: 'الموقع الحالي',
    ur: 'موجودہ مقام',
    fr: 'Position actuelle',
  );
  String get prayerLocation => _t(
    'Prayer location',
    ar: 'موقع الصلاة',
    ur: 'نماز کا مقام',
    fr: 'Lieu de prière',
  );
  String get prayerLocationHint => _t(
    'Use GPS, or search any city in the world',
    ar: 'استخدم الموقع، أو ابحث عن أي مدينة في العالم',
    ur: 'GPS استعمال کریں، یا دنیا کا کوئی بھی شہر تلاش کریں',
    fr: 'Utilisez le GPS, ou recherchez n’importe quelle ville',
  );
  String get searchCity => _t(
    'Search any city',
    ar: 'ابحث عن أي مدينة',
    ur: 'کوئی بھی شہر تلاش کریں',
    fr: 'Rechercher une ville',
  );
  String get useCurrentLocation => _t(
    'Use my current location',
    ar: 'استخدم موقعي الحالي',
    ur: 'میرا موجودہ مقام استعمال کریں',
    fr: 'Utiliser ma position actuelle',
  );
  String get chooseCity => _t(
    'Choose a city',
    ar: 'اختر مدينة',
    ur: 'شہر منتخب کریں',
    fr: 'Choisir une ville',
  );
  String get searchingCities => _t(
    'Searching the world…',
    ar: 'جاري البحث في العالم…',
    ur: 'دنیا بھر میں تلاش…',
    fr: 'Recherche dans le monde…',
  );
  String get noCitiesFound => _t(
    'No cities found. Check the spelling or your connection.',
    ar: 'لم يتم العثور على مدن. تحقق من الكتابة أو الاتصال.',
    ur: 'کوئی شہر نہیں ملا۔ ہجے یا انٹرنیٹ چیک کریں۔',
    fr: 'Aucune ville trouvée. Vérifiez l’orthographe ou la connexion.',
  );
  String prayerRemindersScheduled(int count) => _t(
    '$count salah reminders set for the next 7 days.',
    ar: 'تم ضبط $count تذكير صلاة للأيام السبعة القادمة.',
    ur: 'اگلے ۷ دن کے لیے $count نماز یاددہانی سیٹ ہو گئیں۔',
    fr: '$count rappels de prière programmés pour les 7 prochains jours.',
  );
  String get prayerRemindersFailed => _t(
    'Could not schedule salah reminders. Set a prayer location, then try again.',
    ar: 'تعذر ضبط تذكيرات الصلاة. حدد موقع الصلاة ثم أعد المحاولة.',
    ur: 'نماز کی یاددہانی سیٹ نہیں ہو سکی۔ مقام منتخب کر کے دوبارہ کوشش کریں۔',
    fr: 'Impossible de programmer les rappels. Choisissez un lieu de prière, puis réessayez.',
  );
  String get adhanSound => _t(
    'Adhan at salah time',
    ar: 'أذان عند دخول الوقت',
    ur: 'نماز کے وقت اذان',
    fr: 'Adhan à l’heure de la prière',
  );
  String get adhanSoundSubtitle => _t(
    'Play a short bundled adhan with each reminder',
    ar: 'تشغيل أذان قصير مضمّن مع كل تذكير',
    ur: 'ہر یاددہانی کے ساتھ مختصر اذان چلیں',
    fr: 'Jouer un court adhan à chaque rappel',
  );
  String get tips => _t('Tips', ar: 'نصائح', ur: 'تجاویز', fr: 'Conseils');
  String get prayerTipsBody => _t(
    'Times are calculated on this device from your last known location. Pull refresh after you travel or change time zone.',
    ar: 'تُحسب الأوقات على جهازك من آخر موقع معروف. حدّث الصفحة بعد السفر أو تغيير المنطقة الزمنية.',
    ur: 'اوقات آپ کے آخری معلوم مقام سے اسی ڈیوائس پر نکالے جاتے ہیں۔ سفر یا ٹائم زون بدلنے کے بعد تازہ کریں.',
    fr: 'Les horaires sont calculés sur l’appareil à partir de votre dernière position. Actualisez après un voyage ou un changement de fuseau.',
  );
  String get prayerTimeBody => _t(
    'Prayer time',
    ar: 'حان وقت الصلاة',
    ur: 'نماز کا وقت',
    fr: 'C’est l’heure de la prière',
  );
  String get salahReminders => _t(
    'Salah reminders',
    ar: 'تذكيرات الصلاة',
    ur: 'نماز کی یاددہانیاں',
    fr: 'Rappels de salat',
  );
  String get faceTheKaaba => _t(
    'Face the Kaaba',
    ar: 'اتجه نحو الكعبة',
    ur: 'کعبہ رخ',
    fr: 'Orientez-vous vers la Kaaba',
  );
  String get holdPhoneFlat => _t(
    'Hold your phone flat and follow the arrow',
    ar: 'أمسك الهاتف بشكل مسطح واتبع السهم',
    ur: 'فون سیدھا پکڑیں اور تیر کی پیروی کریں',
    fr: 'Tenez le téléphone à plat et suivez la flèche',
  );
  String get howToUse => _t(
    'How to use',
    ar: 'كيفية الاستخدام',
    ur: 'استعمال کیسے کریں',
    fr: 'Mode d’emploi',
  );
  String get qiblaTipLevel => _t(
    'Keep the phone level — not tilted up or down.',
    ar: 'أبقِ الهاتف مستوياً — دون إمالته لأعلى أو لأسفل.',
    ur: 'فون برابر رکھیں — اوپر یا نیچے نہ جھکائیں۔',
    fr: 'Gardez le téléphone à plat, sans l’incliner.',
  );
  String get qiblaTipRotate => _t(
    'Rotate slowly until the arrow points straight up.',
    ar: 'أدِر ببطء حتى يشير السهم إلى الأعلى.',
    ur: 'آہستہ گھمائیں یہاں تک کہ تیر سیدھا اوپر ہو.',
    fr: 'Tournez lentement jusqu’à ce que la flèche pointe vers le haut.',
  );
  String get qiblaTipLocation => _t(
    'Location is used once to compute your bearing.',
    ar: 'يُستخدم الموقع مرة واحدة لحساب الاتجاه.',
    ur: 'سمت نکالنے کے لیے مقام ایک بار استعمال ہوتا ہے۔',
    fr: 'La position sert une fois à calculer l’azimut.',
  );
  String get compassAccuracy => _t(
    'Compass accuracy varies by device. Move away from metal and magnets if the needle jumps.',
    ar: 'دقة البوصلة تختلف حسب الجهاز. ابتعد عن المعدن والمغناطيس إذا قفز المؤشر.',
    ur: 'قطب نما کی درستگی ڈیوائس پر منحصر ہے۔ اگر سوئی اچھلے تو دھات اور مقناطیس سے دور ہوں.',
    fr: 'La précision de la boussole varie. Éloignez-vous du métal et des aimants si l’aiguille saute.',
  );
  String get stayStillPray => _t(
    'Stay still and begin your prayer.',
    ar: 'اثبت وابدأ صلاتك.',
    ur: 'رکو اور نماز شروع کریں.',
    fr: 'Restez immobile et commencez la prière.',
  );
  String get compassUnavailable => _t(
    'Compass unavailable on this device',
    ar: 'البوصلة غير متوفرة على هذا الجهاز',
    ur: 'اس ڈیوائس پر قطب نما دستیاب نہیں',
    fr: 'Boussole indisponible sur cet appareil',
  );
  String get facingQibla => _t(
    'You are facing Qibla',
    ar: 'أنت متوجه إلى القبلة',
    ur: 'آپ قبلہ رخ ہیں',
    fr: 'Vous êtes face à la Qibla',
  );
  String get turnTowardArrow => _t(
    'Turn toward the arrow',
    ar: 'اتجه نحو السهم',
    ur: 'تیر کی طرف گھمیں',
    fr: 'Tournez vers la flèche',
  );
  String get compassNorth => _t('N', ar: 'ش', ur: 'ش', fr: 'N');
  String get qiblaNeedsLocation => _t(
    'Qibla needs location permission.',
    ar: 'اتجاه القبلة يحتاج إذن الموقع.',
    ur: 'قبلہ کے لیے لوکیشن کی اجازت درکار ہے۔',
    fr: 'La Qibla nécessite la localisation.',
  );
  String get surahs => _t('Surahs', ar: 'السور', ur: 'سورتیں', fr: 'Sourates');
  String get ayahs => _t('Ayahs', ar: 'الآيات', ur: 'آیات', fr: 'Versets');
  String get surahWord => _t('Surah', ar: 'سورة', ur: 'سورہ', fr: 'Sourate');
  String get ayahWord => _t('Ayah', ar: 'آية', ur: 'آیت', fr: 'Verset');
  String get pageWord => _t('Page', ar: 'صفحة', ur: 'صفحہ', fr: 'Page');
  String get juzWord => _t('Juz', ar: 'جزء', ur: 'پارہ', fr: 'Jouz');
  String get pageNumber => _t(
    'Page number',
    ar: 'رقم الصفحة',
    ur: 'صفحہ نمبر',
    fr: 'Numéro de page',
  );
  String get bismillah =>
      _t('Bismillah', ar: 'بسم الله', ur: 'بسم اللہ', fr: 'Bismillah');
  String get listening =>
      _t('Listening', ar: 'الاستماع', ur: 'سن رہے ہیں', fr: 'Écoute');
  String get studyListenSearch => _t(
    'Study, listen, and search',
    ar: 'ادرس واستمع وابحث',
    ur: 'پڑھیں، سنیں، تلاش کریں',
    fr: 'Étudier, écouter et chercher',
  );
  String get browseBySurah => _t(
    'Browse by surah',
    ar: 'تصفح حسب السورة',
    ur: 'سورہ کے مطابق دیکھیں',
    fr: 'Parcourir par sourate',
  );
  String get browseBySurahSubtitle => _t(
    'Translation, bookmarks & audio',
    ar: 'ترجمة وإشارات وصوت',
    ur: 'ترجمہ، بک مارکس اور آڈیو',
    fr: 'Traduction, signets et audio',
  );
  String get continueSurahStudy => _t(
    'Continue surah study',
    ar: 'متابعة دراسة السورة',
    ur: 'سورہ کا مطالعہ جاری رکھیں',
    fr: 'Continuer l’étude de la sourate',
  );
  String get searchQuran => _t(
    'Search Quran',
    ar: 'بحث في القرآن',
    ur: 'قرآن تلاش',
    fr: 'Rechercher dans le Coran',
  );
  String get searchQuranSubtitle => _t(
    'Find words in translation',
    ar: 'ابحث عن كلمات في الترجمة',
    ur: 'ترجمے میں الفاظ تلاش کریں',
    fr: 'Trouver des mots dans la traduction',
  );
  String get searchHint => _t(
    'Surah name or ayah text…',
    ar: 'اسم السورة أو نص الآية…',
    ur: 'سورہ کا نام یا آیت…',
    fr: 'Nom de sourate ou texte…',
  );
  String get typeAtLeast2 => _t(
    'Type at least 2 characters',
    ar: 'اكتب حرفين على الأقل',
    ur: 'کم از کم ۲ حروف لکھیں',
    fr: 'Saisissez au moins 2 caractères',
  );
  String get noResults => _t(
    'No results',
    ar: 'لا توجد نتائج',
    ur: 'کوئی نتیجہ نہیں',
    fr: 'Aucun résultat',
  );
  String get chooseCategory => _t(
    'Choose a category',
    ar: 'اختر تصنيفاً',
    ur: 'قسم منتخب کریں',
    fr: 'Choisissez une catégorie',
  );
  String get tapPlayArabic => _t(
    'Tap play to hear the dua in Arabic',
    ar: 'اضغط تشغيل لسماع الدعاء بالعربية',
    ur: 'عربی میں دعا سننے کے لیے پلے دبائیں',
    fr: 'Touchez lecture pour entendre l’invocation en arabe',
  );
  String get favorites =>
      _t('Favorites', ar: 'المفضلة', ur: 'پسندیدہ', fr: 'Favoris');
  String get noDuasInCategory => _t(
    'No duas in this category yet',
    ar: 'لا توجد أدعية في هذا التصنيف بعد',
    ur: 'اس قسم میں ابھی دعائیں نہیں',
    fr: 'Aucune invocation dans cette catégorie',
  );
  String get playArabic => _t(
    'Play Arabic',
    ar: 'تشغيل بالعربية',
    ur: 'عربی چلائیں',
    fr: 'Lire en arabe',
  );
  String get stopArabic => _t(
    'Stop Arabic',
    ar: 'إيقاف العربية',
    ur: 'عربی روکیں',
    fr: 'Arrêter l’arabe',
  );
  String get tapDhikrHint => _t(
    'Tap a dhikr to open the counter. Play hears it in Arabic.',
    ar: 'اضغط ذكراً لفتح العداد. التشغيل يسمعه بالعربية.',
    ur: 'کاؤنٹر کھولنے کے لیے ذکر دبائیں۔ پلے عربی میں سناتا ہے۔',
    fr: 'Touchez un dhikr pour le compteur. Lecture l’entend en arabe.',
  );
  String get coreDhikr => _t(
    'Core dhikr',
    ar: 'الأذكار الأساسية',
    ur: 'بنیادی ذکر',
    fr: 'Dhikr essentiels',
  );
  String get virtuousRemembrances => _t(
    'Virtuous remembrances',
    ar: 'أذكار فاضلة',
    ur: 'فضیلت والے اذکار',
    fr: 'Évocations vertueuses',
  );
  String get dailySets => _t(
    'Daily sets',
    ar: 'الأوراد اليومية',
    ur: 'روزانہ سیٹ',
    fr: 'Séries quotidiennes',
  );
  String get tap => _t('TAP', ar: 'اضغط', ur: 'دبائیں', fr: 'TAPER');
  String get namesIntro => _t(
    'The 99 beautiful names. Tap play to hear the Arabic.',
    ar: 'الأسماء الحسنى التسعة والتسعون. اضغط تشغيل لسماع العربية.',
    ur: '۹۹ خوبصورت نام۔ عربی سننے کے لیے پلے دبائیں۔',
    fr: 'Les 99 beaux noms. Touchez lecture pour l’arabe.',
  );
  String get voicePreviewSample => _t(
    'Peace be upon you. This is how I sound when reading the translation.',
    ar: 'السلام عليكم. هكذا أبدو عند قراءة الترجمة.',
    ur: 'السلام علیکم۔ ترجمہ پڑھتے وقت میری آواز ایسی ہے۔',
    fr: 'Que la paix soit sur vous. Voici comment je sonne en lisant la traduction.',
  );

  String _t(
    String en, {
    required String ar,
    required String ur,
    required String fr,
  }) {
    return switch (_c) {
      'ar' => ar,
      'ur' => ur,
      'fr' => fr,
      _ => en,
    };
  }
}
