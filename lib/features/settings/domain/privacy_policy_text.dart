/// In-app copy of the Deen Islam privacy policy.
/// Keep in sync with `legal/privacy_policy.html`.
abstract final class PrivacyPolicyText {
  static const String lastUpdated = 'September 1, 2026';

  static const String title = 'Privacy Policy';

  static String bodyFor(String locale) => switch (locale) {
        'ar' => bodyAr,
        'ur' => bodyUr,
        'fr' => bodyFr,
        _ => body,
      };

  static const String bodyAr = '''
آخر تحديث: 1 سبتمبر 2026

دين إسلام تطبيق للقرآن والصلاة والعبادة. توضح هذه السياسة المعلومات التي يستخدمها التطبيق وكيف.

لا ننشئ حسابات مستخدمين. ولا نبيع معلوماتك.

1. المعلومات التي يستخدمها التطبيق

الموقع (اختياري)
يُطلب الموقع أثناء استخدام التطبيق فقط لحساب أوقات الصلاة واتجاه القبلة. يُحفظ على جهازك ولا يُرسل إلى خوادمنا.

الحركة / البوصلة (اختياري)
تستخدم القبلة بوصلة الجهاز ومستشعرات الحركة. تبقى هذه البيانات على جهازك.

الإشعارات (اختياري)
إذا فعّلت تنبيهات الصلاة، يجدول التطبيق تذكيرات محلية على جهازك. ليست إشعارات من خادم.

الإعدادات وبيانات العبادة
العلامات المرجعية وموضع القراءة والمظهر واللغة والقارئ تُحفظ على جهازك ولا تُرفع.

2. خدمات الشبكة

تحتاج بعض الميزات إلى الإنترنت:
• يُحمَّل صوت التلاوة من شبكة خارجية (cdn.islamic.app) عند تشغيل الآيات.
• صوت الترجمة يعمل على جهازك. الإنجليزية تستخدم كوكورو (نحو 100 ميغابايت مرة واحدة). الفرنسية والأردية تستخدمان بايبر (نحو 12–20 ميغابايت لكل صوت). تُحمَّل النماذج من GitHub أول مرة. بعد ذلك لا يحتاج النطق إلى الإنترنت ولا يُرسل النص إلى Google.
• قد تُجلب الخطوط من Google Fonts عند الحاجة.

لا نستخدم إعلانات ولا أدوات تحليلات.

3. ما لا نجمعه

• لا نطلب اسمك أو بريدك أو هاتفك.
• لا نستخدم بياناتك للإعلان.
• لا نتتبعك عبر تطبيقات أو مواقع أخرى.
• لا نستخدم الميكروفون لتسجيلك.

4. الأطفال

التطبيق لجمهور عام. لا نجمع عمداً بيانات شخصية من الأطفال.

5. خياراتك

• يمكنك رفض أذونات الموقع أو الحركة أو الإشعارات في إعدادات iOS.
• يمكنك إيقاف تنبيهات الصلاة داخل التطبيق.
• حذف التطبيق يزيل البيانات المحلية.

6. التغييرات

عند تغيير السياسة نحدّث التاريخ أعلاه والنص في التطبيق.

7. التواصل

أسئلة حول هذه السياسة: صفحة دين إسلام على App Store أو بريد المطوّر المذكور هناك.

دين إسلام
معرّف الحزمة: com.solihan.deenConnect
''';

  static const String bodyUr = '''
آخری تازہ کاری: 1 ستمبر 2026

دین اسلام قرآن، نماز اور عبادت کا ساتھی ایپ ہے۔ یہ پالیسی بتاتی ہے کہ ایپ کون سی معلومات استعمال کرتی ہے۔

ہم صارف اکاؤنٹ نہیں بناتے۔ ہم آپ کی معلومات نہیں بیچتے۔

1. ایپ جو معلومات استعمال کرتی ہے

مقام (اختیاری)
نماز کے اوقات اور قبلہ کے لیے مقام صرف استعمال کے دوران مانگا جاتا ہے۔ یہ آپ کے فون پر محفوظ رہتا ہے، ہمارے سرورز پر نہیں بھیجا جاتا۔

حرکت / قطب نما (اختیاری)
قبلہ ڈیوائس کے کمپاس سے کام کرتا ہے۔ یہ ڈیٹا فون پر رہتا ہے۔

اطلاعات (اختیاری)
نماز کی یاددہانیاں آپ کے فون پر مقامی طور پر شیڈول ہوتی ہیں، کسی سرور سے پش نہیں۔

ترتیبات اور عبادت کا ڈیٹا
بک مارکس، پڑھنے کی جگہ، تھیم، زبان اور قاری آپ کے فون پر محفوظ ہیں، اپ لوڈ نہیں ہوتے۔

2. انٹرنیٹ سروسز

کچھ فیچرز کے لیے انٹرنیٹ چاہیے:
• تلاوت cdn.islamic.app سے آتی ہے۔
• ترجمے کی آواز آپ کے فون پر چلتی ہے۔ انگریزی کوکورو استعمال کرتی ہے (~۱۰۰ ایم بی ایک بار)۔ فرانسیسی اور اردو پائپر استعمال کرتی ہیں (~۱۲–۲۰ ایم بی فی آواز)۔ ماڈل پہلی بار گٹ ہب سے آتے ہیں۔ اس کے بعد انٹرنیٹ کی ضرورت نہیں اور متن گوگل کو نہیں جاتا۔
• فونٹس گوگل فونٹس سے آ سکتے ہیں۔

ہم اشتہارات یا اینالیٹکس نہیں چلاتے۔

3. جو ہم جمع نہیں کرتے

• نام، ای میل یا فون نمبر نہیں مانگتے۔
• اشتہار کے لیے ڈیٹا استعمال نہیں کرتے۔
• دوسری ایپس میں آپ کو ٹریک نہیں کرتے۔
• مائیکروفون سے ریکارڈ نہیں کرتے۔

4. بچے

یہ عمومی عبادت ایپ ہے۔ ہم جان بوجھ کر بچوں کی ذاتی معلومات نہیں لیتے۔

5. آپ کے اختیارات

• iOS سیٹنگز میں مقام، حرکت یا نوٹیفکیشن روک سکتے ہیں۔
• ایپ میں نماز کی اطلاعات بند کر سکتے ہیں۔
• ایپ ڈیلیٹ کرنے سے مقامی ڈیٹا ختم ہو جاتا ہے۔

6. تبدیلیاں

پالیسی بدلنے پر تاریخ اور ایپ کا متن اپ ڈیٹ ہوگا۔

7. رابطہ

App Store پر دین اسلام کا صفحہ یا وہاں درج ڈویلپر ای میل۔

دین اسلام
بنڈل آئی ڈی: com.solihan.deenConnect
''';

  static const String bodyFr = '''
Dernière mise à jour : 1 septembre 2026

Deen Islam est une application de Coran, de prière et d’adoration. Cette politique décrit les informations utilisées et leur usage.

Nous ne créons pas de comptes. Nous ne vendons pas vos informations.

1. Informations utilisées

Localisation (facultatif)
Demandée uniquement pendant l’usage, pour les horaires de prière et la Qibla. Elle est stockée sur l’appareil, pas envoyée à nos serveurs.

Mouvement / boussole (facultatif)
La Qibla utilise la boussole. Ces données restent sur l’appareil.

Notifications (facultatif)
Les rappels de prière sont planifiés localement. Ce ne sont pas des notifications serveur.

Réglages et données d’adoration
Signets, position de lecture, thème, langue et récitateur restent sur l’appareil.

2. Services réseau

Certaines fonctions nécessitent Internet :
• L’audio de récitation vient de cdn.islamic.app.
• La voix de traduction tourne sur l’appareil. L’anglais utilise Kokoro (~100 Mo une fois, partagé). Le français et l’ourdou utilisent Piper (~12–20 Mo par voix). Les modèles sont téléchargés depuis GitHub la première fois. Ensuite, la lecture n’a plus besoin d’Internet et le texte n’est pas envoyé à Google.
• Les polices peuvent venir de Google Fonts.

Pas de publicité ni de SDK d’analyse.

3. Ce que nous ne collectons pas

• Ni nom, ni e-mail, ni téléphone.
• Pas d’usage publicitaire.
• Pas de suivi inter-applications.
• Pas d’enregistrement via le micro.

4. Enfants

Application grand public. Nous ne collectons pas sciemment de données d’enfants.

5. Vos choix

• Refuser localisation, mouvement ou notifications dans les réglages iOS.
• Désactiver les rappels dans l’app.
• Supprimer l’app efface les données locales.

6. Modifications

En cas de changement, la date et le texte dans l’app seront mis à jour.

7. Contact

Page Deen Islam sur l’App Store, ou l’e-mail du développeur qui y figure.

Deen Islam
Identifiant : com.solihan.deenConnect
''';

  static const String body = '''
Last updated: September 1, 2026

Deen Islam (“the app”) is a Quran, prayer, and worship companion. This policy describes what information the app uses and how.

We do not create user accounts. We do not sell your information.

1. Information the app uses

Location (optional)
The app requests your location only while you are using it, so it can calculate prayer times and qibla direction for your current place. Location is stored on your device (last known coordinates) to show times if GPS is slow or unavailable. Location is not sent to our servers.

Motion / compass (optional)
Qibla uses the device compass and motion sensors. That data stays on your device.

Notifications (optional)
If you turn on prayer notifications, the app schedules local reminders on your device. These are not push notifications from a server.

Settings and worship data
Bookmarks, reading position, theme, language, reciter, and similar preferences are stored on your device. They are not uploaded.

2. Network services

Some features need the internet:

• Quran recitation audio is loaded from a third-party content network (cdn.islamic.app) when you play ayahs.
• Translation voice runs on your device. English uses Kokoro (~100 MB, downloaded once and shared across English voices). French and Urdu use Piper (~12–20 MB per voice). Models are downloaded from GitHub the first time you choose a voice. After that, translation speech does not need the internet and is not sent to Google.
• Fonts may be fetched from Google Fonts when the app first needs them.

We do not run advertising or analytics SDKs. Store-release builds do not include a bundled API key or install-tracking URL.

3. What we do not collect

• We do not require your name, email, or phone number.
• We do not use your information for advertising.
• We do not track you across other companies’ apps or websites.
• We do not use the microphone. The app never records audio.

4. Children

Deen Islam is a general-audience worship app. We do not knowingly collect personal information from children. Location and notifications are requested only for the features above.

5. Your choices

• You can deny location, motion, or notification permission in iOS Settings. Quran reading, duas, tasbeeh, and Names of Allah still work without location.
• You can turn prayer notifications off in the app.
• You can delete the app to remove local data stored on the device.

6. Changes

If this policy changes, we will update the date above and the copy in the app.

7. Contact

Questions about this policy: use the Deen Islam product page on the App Store, or email the developer listed there.

Deen Islam
Bundle ID: com.solihan.deenConnect
''';
}
