import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// UI copy: app.dart
  ///
  /// In ar, this message translates to:
  /// **'ضمانك للأعمال'**
  String get msg3493ba48d2a7;

  /// UI copy: core/currency.dart
  ///
  /// In ar, this message translates to:
  /// **'الريال السعودي'**
  String get msge3c015738ac5;

  /// UI copy: core/currency.dart
  ///
  /// In ar, this message translates to:
  /// **'ر.س'**
  String get msgfeafe34f5add;

  /// UI copy: core/currency.dart
  ///
  /// In ar, this message translates to:
  /// **'الدرهم الإماراتي'**
  String get msgfa13090f419f;

  /// UI copy: core/currency.dart
  ///
  /// In ar, this message translates to:
  /// **'د.إ'**
  String get msgf0250dc87517;

  /// UI copy: core/currency.dart
  ///
  /// In ar, this message translates to:
  /// **'الدينار الكويتي'**
  String get msg1a813e54e35c;

  /// UI copy: core/currency.dart
  ///
  /// In ar, this message translates to:
  /// **'د.ك'**
  String get msg0ba7425c4cd1;

  /// UI copy: core/currency.dart
  ///
  /// In ar, this message translates to:
  /// **'الريال القطري'**
  String get msg803b65775220;

  /// UI copy: core/currency.dart
  ///
  /// In ar, this message translates to:
  /// **'ر.ق'**
  String get msg0db1d6d43800;

  /// UI copy: core/currency.dart
  ///
  /// In ar, this message translates to:
  /// **'الدينار البحريني'**
  String get msg18713c7eb0c4;

  /// UI copy: core/currency.dart
  ///
  /// In ar, this message translates to:
  /// **'د.ب'**
  String get msg05b09ee451bb;

  /// UI copy: core/currency.dart
  ///
  /// In ar, this message translates to:
  /// **'الريال العُماني'**
  String get msg43e9e1f7954f;

  /// UI copy: core/currency.dart
  ///
  /// In ar, this message translates to:
  /// **'ر.ع'**
  String get msgd510cc034489;

  /// UI copy: core/currency.dart
  ///
  /// In ar, this message translates to:
  /// **'الدولار الأمريكي'**
  String get msgb3a007a34c09;

  /// UI copy: core/currency.dart
  ///
  /// In ar, this message translates to:
  /// **'الليرة السورية'**
  String get msga54c3973b1bf;

  /// UI copy: core/currency.dart
  ///
  /// In ar, this message translates to:
  /// **'ل.س'**
  String get msgf00ff40fed12;

  /// UI copy: core/date_utils.dart
  ///
  /// In ar, this message translates to:
  /// **'منتهي منذ {p0} يوم'**
  String msg529b4943dc94(Object p0);

  /// UI copy: core/date_utils.dart
  ///
  /// In ar, this message translates to:
  /// **'ينتهي اليوم'**
  String get msge708fda7a521;

  /// UI copy: core/date_utils.dart
  ///
  /// In ar, this message translates to:
  /// **'متبقٍ يوم واحد'**
  String get msgf3bf57cfc04a;

  /// UI copy: core/date_utils.dart
  ///
  /// In ar, this message translates to:
  /// **'متبقي {p0} أيام'**
  String msgf1aaf0762596(Object p0);

  /// UI copy: core/date_utils.dart
  ///
  /// In ar, this message translates to:
  /// **'متبقي {p0} يوماً'**
  String msg4a4ac1d2f9bb(Object p0);

  /// UI copy: features/subscriptions/domain/subscription_flow.dart
  ///
  /// In ar, this message translates to:
  /// **'لم يُرجع متجر التطبيقات باقات صالحة.'**
  String get msg37d315322974;

  /// UI copy: main.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تجهيز التطبيق. تحقق من الاتصال ثم حاول مرة أخرى.'**
  String get msg6b6613da51be;

  /// UI copy: models/account.dart
  ///
  /// In ar, this message translates to:
  /// **'المالك'**
  String get msgee9b5203194c;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مدير'**
  String get msg6a05608678d2;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'موظف'**
  String get msg45372718dd18;

  /// UI copy: models/account.dart
  ///
  /// In ar, this message translates to:
  /// **'بطاقة ضمان موثّقة'**
  String get msge7139553cc0c;

  /// UI copy: models/account.dart
  ///
  /// In ar, this message translates to:
  /// **'مستخدم ضمانك'**
  String get msg05c6541036fe;

  /// UI copy: models/audit_event.dart
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get msgd52453ac627d;

  /// UI copy: models/audit_event.dart
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get msg113d570d6555;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get msg59ca629220a6;

  /// UI copy: models/audit_event.dart
  ///
  /// In ar, this message translates to:
  /// **'إنشاء المتجر'**
  String get msg0072226bceb3;

  /// UI copy: models/audit_event.dart
  ///
  /// In ar, this message translates to:
  /// **'انضمام عضو'**
  String get msgb87a7054dbb1;

  /// UI copy: models/audit_event.dart
  ///
  /// In ar, this message translates to:
  /// **'تحديث عضو'**
  String get msg32f6f28b883c;

  /// UI copy: models/audit_event.dart
  ///
  /// In ar, this message translates to:
  /// **'تفعيل اشتراك'**
  String get msg6d3e7fd39371;

  /// UI copy: models/audit_event.dart
  ///
  /// In ar, this message translates to:
  /// **'ضمان'**
  String get msg7ae716267c45;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'منتج'**
  String get msgf8720c7412f1;

  /// UI copy: models/audit_event.dart
  ///
  /// In ar, this message translates to:
  /// **'عميل'**
  String get msg7f36bcf24fa0;

  /// UI copy: screens/register_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'فرع'**
  String get msg28adde4ba2a8;

  /// UI copy: models/audit_event.dart
  ///
  /// In ar, this message translates to:
  /// **'طلب صيانة'**
  String get msgb7eb8b66eb0d;

  /// UI copy: models/audit_event.dart
  ///
  /// In ar, this message translates to:
  /// **'متجر'**
  String get msg234766dca27a;

  /// UI copy: models/audit_event.dart
  ///
  /// In ar, this message translates to:
  /// **'عضو فريق'**
  String get msg44eb24b9fe86;

  /// UI copy: models/audit_event.dart
  ///
  /// In ar, this message translates to:
  /// **'اشتراك'**
  String get msg7d42afa188f2;

  /// UI copy: models/branch.dart
  ///
  /// In ar, this message translates to:
  /// **'متجر بيع'**
  String get msg05843a56127a;

  /// UI copy: models/branch.dart
  ///
  /// In ar, this message translates to:
  /// **'مستودع'**
  String get msg1bd322ed1fa0;

  /// UI copy: models/branch.dart
  ///
  /// In ar, this message translates to:
  /// **'مركز صيانة'**
  String get msg697b008c8bfc;

  /// UI copy: models/branch.dart
  ///
  /// In ar, this message translates to:
  /// **'بيع وصيانة'**
  String get msg9297ad88d679;

  /// UI copy: models/inventory.dart
  ///
  /// In ar, this message translates to:
  /// **'رصيد افتتاحي'**
  String get msg998a0190311c;

  /// UI copy: models/inventory.dart
  ///
  /// In ar, this message translates to:
  /// **'استلام مشتريات'**
  String get msgf081df1ea3f0;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بيع'**
  String get msg3f938fa02d78;

  /// UI copy: models/inventory.dart
  ///
  /// In ar, this message translates to:
  /// **'مرتجع عميل'**
  String get msg2070711a2cdb;

  /// UI copy: models/inventory.dart
  ///
  /// In ar, this message translates to:
  /// **'تحويل صادر'**
  String get msgbd783117c924;

  /// UI copy: models/inventory.dart
  ///
  /// In ar, this message translates to:
  /// **'تحويل وارد'**
  String get msgb1e632423040;

  /// UI copy: models/inventory.dart
  ///
  /// In ar, this message translates to:
  /// **'تسوية مخزون'**
  String get msg84a79451a197;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get msgd51f9d8dbcc0;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get msg8aac5fac1498;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'مقبول'**
  String get msgf5fde9cba1be;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'قيد المعالجة'**
  String get msg0cc6a7db6080;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بانتظار العميل'**
  String get msg7c4b128da66a;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'جاهز للاستلام'**
  String get msge11898841984;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get msgc2da5684d63b;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get msg5d969a71dad3;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get msg616d302cb016;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'منخفضة'**
  String get msg23f05e2b7f33;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'عادية'**
  String get msgb0c8f17185cf;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'مرتفعة'**
  String get msg6002b017f319;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'عاجلة'**
  String get msgb96597e44c34;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'عطل في التشغيل'**
  String get msge0f77b8a8a28;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'البطارية أو الطاقة'**
  String get msga440316f8a4f;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'البرمجيات'**
  String get msg34e3823a32f8;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'ضرر مادي'**
  String get msgc88f0463f4aa;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'قطعة أو ملحق مفقود'**
  String get msg31a68ce37588;

  /// UI copy: models/warranty.dart
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get msg17a9f38e22b6;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'المحل'**
  String get msg36bf7c3274ae;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'بوابة العميل'**
  String get msg98fa26e87837;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'استيراد'**
  String get msge8c12678c3b4;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'تكامل'**
  String get msg520149c1fa17;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'لم يحدد بعد'**
  String get msgcc737e08116b;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'إصلاح'**
  String get msg9c92b58e8fd9;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'استبدال'**
  String get msg374cdcc38839;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'استرداد'**
  String get msg11d5e72c1924;

  /// UI copy: models/maintenance_request.dart
  ///
  /// In ar, this message translates to:
  /// **'مركز خدمة خارجي'**
  String get msg3d2cd595b1ab;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رفض المطالبة'**
  String get msgbfd935693039;

  /// UI copy: models/product_ai_import.dart
  ///
  /// In ar, this message translates to:
  /// **'الذكاء الاصطناعي'**
  String get msg17b5d91632ee;

  /// UI copy: models/sale.dart
  ///
  /// In ar, this message translates to:
  /// **'مكتملة'**
  String get msgf1d6d15f76da;

  /// UI copy: models/sale.dart
  ///
  /// In ar, this message translates to:
  /// **'مرتجع جزئي'**
  String get msgd020893b6854;

  /// UI copy: models/sale.dart
  ///
  /// In ar, this message translates to:
  /// **'مرتجعة'**
  String get msg16dafdc77d49;

  /// UI copy: models/sale.dart
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get msgd87ae61bedd8;

  /// UI copy: models/sale.dart
  ///
  /// In ar, this message translates to:
  /// **'عميل نقدي'**
  String get msg0a3db79bc10d;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متجر التطبيقات'**
  String get msg91e7da5d592b;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'شهري'**
  String get msg9c677bb93912;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'سنوي'**
  String get msg1beeff0b0fec;

  /// UI copy: models/store_profile.dart
  ///
  /// In ar, this message translates to:
  /// **'متجر ضمانك'**
  String get msg2a01836e5452;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'للمتجر الفردي الذي يبدأ إصدار ضماناته'**
  String get msg216cd1992604;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'فرع واحد'**
  String get msg016538bc395c;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'20 ضماناً تتجدد تلقائياً كل شهر'**
  String get msgea4ca83a8b30;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'بطاقة ضمان رقمية برمز QR'**
  String get msg443c5d6c51fb;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'رابط مشاركة آمن للضمان'**
  String get msge567a6c6442f;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'مطالبات وصور ومستندات العميل'**
  String get msg6a868640b0ca;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'للمتجر الذي يبدأ تنظيم ضماناته رقمياً'**
  String get msga575ff3d0457;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'مناسب لفرع واحد'**
  String get msg1e853ae9c9d4;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'سجل ضمانات قابل للبحث'**
  String get msge2544e97c701;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'لفريق يدير الضمانات والمتابعة يومياً'**
  String get msgcd34ade6e924;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'مناسب حتى 3 فروع'**
  String get msg1c35fbf3c4d5;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'كل مزايا بداية'**
  String get msg005df5421b44;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'فريق بأدوار مستقلة'**
  String get msg66a8ed147065;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'الفروع والمخزون ونقطة البيع'**
  String get msg45389c7a942d;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'تقارير وتصدير CSV'**
  String get msg3a5897f98bdb;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'هوية المتجر والفروع'**
  String get msga99ca9824c85;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'لسلاسل الفروع والعمليات ذات الحجم الكبير'**
  String get msg98cc994f7a96;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'حتى 20 فرعاً'**
  String get msg934f32075c93;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'كل مزايا نمو'**
  String get msg26aef5ada297;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'API بصلاحيات قابلة للتحديد'**
  String get msg6a9af3451785;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'Webhooks موقعة للمطالبات'**
  String get msg6263ca388edc;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'حصص أعلى للضمانات والتحليل'**
  String get msg01b718eb26f8;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'سجل نشاط للمالك والمدير'**
  String get msg084e5909cb0d;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'خطة مخصصة لاحتياج المتجر'**
  String get msge38ddb73a959;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'الفروع بحسب الخطة'**
  String get msgf93d9d66716e;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} تحليل ملف منتجات بالذكاء الاصطناعي شهرياً'**
  String msg35e24cd09d8e(Object p0);

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} مراجعة ذكية للمطالبات شهرياً'**
  String msg79f13793d2f2(Object p0);

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'هوية وسياسة ضمان مخصصة للعميل'**
  String get msg747cabd620f2;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'مفاتيح API تُعرض مرة واحدة فقط'**
  String get msg9d56094ee70b;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'إشعارات Webhook مع توقيع وإعادة محاولة'**
  String get msg53cf225f153d;

  /// UI copy: models/supplier.dart
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get msg552aec56f591;

  /// UI copy: models/supplier.dart
  ///
  /// In ar, this message translates to:
  /// **'مرسل للمورد'**
  String get msgd35cb9f02c2d;

  /// UI copy: models/supplier.dart
  ///
  /// In ar, this message translates to:
  /// **'مستلم جزئياً'**
  String get msgba3b8f66fad5;

  /// UI copy: models/supplier.dart
  ///
  /// In ar, this message translates to:
  /// **'مستلم'**
  String get msg66febe964420;

  /// UI copy: models/warranty.dart
  ///
  /// In ar, this message translates to:
  /// **'نقداً'**
  String get msg4a05893d630f;

  /// UI copy: models/warranty.dart
  ///
  /// In ar, this message translates to:
  /// **'بطاقة'**
  String get msg1089e4018122;

  /// UI copy: models/warranty.dart
  ///
  /// In ar, this message translates to:
  /// **'تحويل بنكي'**
  String get msg5385ccd1ff51;

  /// UI copy: models/warranty.dart
  ///
  /// In ar, this message translates to:
  /// **'محفظة رقمية'**
  String get msg93e96ec7059b;

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ساري'**
  String get msge7e4a3bf3fb7;

  /// UI copy: models/warranty.dart
  ///
  /// In ar, this message translates to:
  /// **'قارب على الانتهاء'**
  String get msg391609950c28;

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'منتهي'**
  String get msg6217883aee8e;

  /// UI copy: screens/shell_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الإدارة'**
  String get msga3b53d11ac20;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'؟'**
  String get msg7d06b69aad65;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'خدمة الضمان'**
  String get msgaf4d9ff5b4d2;

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get msgc8775206b252;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} منتج في الكتالوج'**
  String msg8be6cfd47c1b(Object p0);

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'العملاء'**
  String get msg813d9a8a1065;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} عميل'**
  String msg4bd610b4702a(Object p0);

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أداء الضمان'**
  String get msg038317a4bdae;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'التأخير والقبول والإغلاق وأسباب الأعطال'**
  String get msgd742d0ba9eb1;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إدارة المتجر'**
  String get msgb332e76753b0;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الفروع'**
  String get msg717d385ed755;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} فرع'**
  String msg44c9bd4c003e(Object p0);

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الفريق والصلاحيات'**
  String get msgfae07b10b96b;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} أعضاء'**
  String msg8b885d3f2a38(Object p0);

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدوات بيع اختيارية'**
  String get msg73a2f189121f;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'نقطة البيع'**
  String get msg019fbfd1d736;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إصدار بيع وضمان في خطوة واحدة'**
  String get msgf9e6b8346033;

  /// UI copy: screens/sales_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المبيعات والمرتجعات'**
  String get msgc3fdd6caa7c1;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} عملية'**
  String msgb2a0b8ca5be1(Object p0);

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الصندوق والورديات'**
  String get msg76218d4ae22b;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'فتح وإغلاق وجرد النقد'**
  String get msg6b5d92b9084b;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الموردون والمشتريات'**
  String get msgb303479250b4;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} مورد'**
  String msg53b2c0902636(Object p0);

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get msg66dcee1f4616;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get msg8ce3e0cc0601;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تنبيهات غير مقروءة'**
  String get msg04cc60c136b6;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} تنبيهات غير مقروءة'**
  String msgbfbe54647329(Object p0);

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بيانات المتجر'**
  String get msg97432797c672;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك'**
  String get msg103acd5c93ee;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'خطة {p0}'**
  String msgb83c63d8ca1b(Object p0);

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'التكاملات'**
  String get msgc82e99cb1b8b;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'API وWebhooks'**
  String get msgc255231e3d75;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متاحة في باقة توسع'**
  String get msgd28cd531b9d1;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إغلاق العرض التشغيلي'**
  String get msge2bd051450c6;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get msg21f474427638;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب نهائياً'**
  String get msg0e37703ffce0;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ضمانك للأعمال 4.6.0'**
  String get msge9a85ff0e478;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب نهائياً؟'**
  String get msg938d8775ee84;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إذا كنت المالك الوحيد فسيُحذف المتجر وبياناته. وإذا وُجد عضو آخر فستُنقل الملكية إليه قبل حذف حسابك. لا يمكن التراجع عن هذا الإجراء.'**
  String get msg932dd1b45205;

  /// UI copy: screens/account_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تنبيه: حذف حساب ضمانك لا يلغي الاشتراك أو يوقف الفوترة لدى {p0}. ألغِ التجديد من المتجر لتجنب رسوم لاحقة. يمكنك إدارة الاشتراك أولاً أو المتابعة بالحذف الآن.'**
  String msgc40bf1a4b038(Object p0);

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get msg9a30dc2a96b8;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إدارة الاشتراك'**
  String get msg432651e0ceb3;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حذف نهائي'**
  String get msgcd6f896cc0ee;

  /// UI copy: screens/auth_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'دعوتك جاهزة'**
  String get msgb1afed756408;

  /// UI copy: screens/auth_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الدخول إلى ضمانك'**
  String get msg2837eb878bb4;

  /// UI copy: screens/auth_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اختر حساب Apple أو Google، ثم راجع صلاحيتك وانضم إلى فريق المتجر.'**
  String get msg6c4394b5c8de;

  /// UI copy: screens/auth_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اختر حساب Google، ثم راجع صلاحيتك وانضم إلى فريق المتجر.'**
  String get msg433779b5949c;

  /// UI copy: screens/auth_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استخدم حسابك الموجود على جهازك. لا كلمة مرور جديدة ولا جلسة مشتركة بين الموظفين.'**
  String get msgbc960abda0c4;

  /// UI copy: screens/auth_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سيبقى رابط الدعوة محفوظاً أثناء تسجيل الدخول.'**
  String get msgf96ed34f8982;

  /// UI copy: screens/auth_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تسجيل الدخول بأمان…'**
  String get msg78fd957e44f0;

  /// UI copy: screens/auth_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بالمتابعة، يطّلع ضمانك فقط على الاسم والبريد اللذين يرسلهما مزوّد الحساب. يمكنك حذف حسابك من داخل التطبيق.'**
  String get msgd98d709d9821;

  /// UI copy: screens/auth_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المتابعة باستخدام Google'**
  String get msgf8402c2a1011;

  /// UI copy: screens/auth_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المتابعة باستخدام Apple'**
  String get msg6bdd85157847;

  /// UI copy: screens/auth_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حسابك لك،\nوصلاحيتك واضحة.'**
  String get msgd43e32c57516;

  /// UI copy: screens/auth_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المالك يدعو الفريق، وكل موظف يدخل بحساب Apple أو Google مستقل من دون مشاركة كلمة المرور.'**
  String get msgb4b1b15b2668;

  /// UI copy: screens/auth_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حساب فردي'**
  String get msg1914dae89043;

  /// UI copy: screens/auth_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'صلاحيات مستقلة'**
  String get msg81538c5a6b52;

  /// UI copy: screens/auth_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'دعوة برابط واحد'**
  String get msgfc933a60701c;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الفروع ونقاط البيع'**
  String get msg8c556bfb0756;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إضافة فرع'**
  String get msg46dadab0f9e2;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اربط كل ضمان بالفرع الذي نفّذ البيع حتى تصبح التقارير دقيقة.'**
  String get msg6b1d45c15935;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'فرع جديد'**
  String get msgb8a7ef94ffca;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعديل الفرع'**
  String get msgee0d3a650c5f;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'هوية الفرع'**
  String get msg0ef8d53ae2b2;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اسم الفرع'**
  String get msgfa431491b7a8;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رمز الفرع'**
  String get msg260829cfeb20;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'نوع الموقع'**
  String get msge51245b5152d;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مدير الفرع أو المسؤول'**
  String get msg84e569af1e6e;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'العنوان والتواصل'**
  String get msgcab45709e6ba;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get msg23ee0d351c7b;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'العنوان التفصيلي'**
  String get msg491712d63cd1;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رقم الفرع'**
  String get msg3c0031ace174;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بريد الفرع'**
  String get msgec3a5f9412b2;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'نقطة البيع وساعات العمل'**
  String get msg1a11da492906;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بادئة الإيصال'**
  String get msg4a0906708044;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المنطقة الزمنية'**
  String get msg2d25557e7c23;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يفتح'**
  String get msgabb44169515c;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يغلق'**
  String get msg4ce6227a817d;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يقبل عمليات البيع'**
  String get msgfc7781df53df;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يظهر ضمن نقاط البيع ويمكن فتح صندوق له.'**
  String get msgafbf92c0b73f;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يستقبل الصيانة والضمان'**
  String get msg58605069537a;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يمكن ربط طلبات الخدمة بهذا الموقع.'**
  String get msge4cdcaa94b2d;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الفرع الرئيسي'**
  String get msg811cbd5eca36;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يصبح الاختيار الافتراضي للعمليات.'**
  String get msg5d8a25c67cc5;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حفظ الفرع ونقطة البيع'**
  String get msg77794a2275a1;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استخدم 2–12 حرفاً أو رقماً لاتينياً'**
  String get msg0cc91d6f1184;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استخدم 2–8 أحرف أو أرقام'**
  String get msg2c0cdc3271c1;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استخدم صيغة 09:00'**
  String get msg2b690da096a1;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get msgd5a02f880a17;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رئيسي'**
  String get msgcd07cc117801;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لم يُسجل أي فرع بعد.'**
  String get msg75647d3eeb9c;

  /// UI copy: screens/branches_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إضافة الفرع الأول'**
  String get msg4aa207644a8d;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لم تعد المطالبة موجودة.'**
  String get msg47609a0036a9;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعديل تفاصيل المطالبة'**
  String get msg289a4e72f188;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'العميل والمنتج'**
  String get msg5c4fd79b730c;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'فتح الضمان'**
  String get msg45f73d63ecda;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'المنتج'**
  String get msga79e304d96a1;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'العميل'**
  String get msga042411e90be;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get msg94b59a5125fb;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الرقم التسلسلي'**
  String get msg5789f0fed61c;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'نهاية الضمان'**
  String get msgc246f9ec82e0;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المطالبة'**
  String get msg3122792d13c3;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المشكلة'**
  String get msg9099527b2932;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'الفئة'**
  String get msgff61fb213ffc;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الأولوية'**
  String get msg4c3e5a87f1e4;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المصدر'**
  String get msg64660bb87d89;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المسؤول'**
  String get msg5087bf126a06;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'غير معيّن'**
  String get msg3eed0035cf5d;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'فرع الخدمة'**
  String get msg7a9ca70461f9;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get msg5a0374f3ff5a;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'موعد الاستجابة'**
  String get msg25dad1fc33ec;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المعالجة والقرار'**
  String get msgf4222866fc4f;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'التشخيص'**
  String get msg490dfdf55a4d;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'القرار'**
  String get msga881a87897ba;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل التنفيذ'**
  String get msg5f7bb20a6096;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سبب القرار'**
  String get msg3a1f67eb3acd;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ظاهر للعميل'**
  String get msg187e287ce6a2;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get msg9dca2d96d1fb;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل المطالبة'**
  String get msgff42cb797bed;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم قبول المطالبة'**
  String get msge8b8e1ebd4c9;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم إكمال المطالبة'**
  String get msg87dcc5eac968;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث: {p0}'**
  String msg272095a56e1a(Object p0);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مساعد فرز المطالبة'**
  String get msg6c8cfd0ad30c;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سيُرسل وصف المشكلة واسم المنتج إلى OpenAI دون اسم العميل أو هاتفه. النتيجة اقتراح للموظف ولا تقبل المطالبة أو ترفضها.'**
  String get msg38f2b4b43147;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحليل أول ملفين أيضاً'**
  String get msg37034d66e11b;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'قد تحتوي الملفات على بيانات شخصية وتزيد التكلفة. اتركه مغلقاً إن لم تكن الصور ضرورية.'**
  String get msgc27e8c37d669;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحليل الآن'**
  String get msg925fb72780c9;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحليل المطالبة الآن.'**
  String get msg9487432c9fff;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استخدام الاقتراح؟'**
  String get msg1e02dc8d7a10;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سيُحدّث التصنيف إلى «{p0}» والأولوية إلى «{p1}». لن تتغير حالة المطالبة.'**
  String msgd67a5f3bc0a6(Object p0, Object p1);

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get msgcb822418a29d;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تطبيق بعد المراجعة'**
  String get msg43db76ef30fb;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحديث المطالبة {p0}'**
  String msgf1930614c4d7(Object p0);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد رقم هاتف مسجل لهذا العميل.'**
  String get msg596ce1253414;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح تطبيق الاتصال.'**
  String get msg25a522457d01;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'نحتاج منك معلومات إضافية لإكمال المعالجة.'**
  String get msgfa1249723b2f;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'نحتاج منك: {p0}'**
  String msg124a5c699fda(Object p0);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المنتج جاهز للاستلام. تواصل مع المحل لتأكيد الموعد.'**
  String get msgeae0b27e6196;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اكتملت معالجة المطالبة.'**
  String get msg68816aa17db1;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم اتخاذ قرار بشأن المطالبة. راجع الرابط للتفاصيل.'**
  String get msgb69362a124f3;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'القرار: {p0}'**
  String msg7784bea7df92(Object p0);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سنبلغك عند انتقال المطالبة إلى الخطوة التالية.'**
  String get msg294f46432382;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مرحباً {p0}،'**
  String msg650293d55384(Object p0);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحديث المطالبة {p0} للمنتج {p1}.'**
  String msg53e7b570927c(Object p0, Object p1);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الحالة: {p0}'**
  String msge93630401caa(Object p0);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تابع المطالبة وأرسل الملفات من هنا:\n{p0}'**
  String msg8982e1b5df75(Object p0);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سبب الرفض الظاهر في السجل'**
  String get msg81821da6baa6;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الرفض'**
  String get msgb5170558cd41;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم نقل المطالبة إلى «{p0}».'**
  String msg30b901c9e93a(Object p0);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'كيف أُغلقت المطالبة؟'**
  String get msg5a3aee566b06;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إدارة المطالبة'**
  String get msg55c952196d59;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get msgddfcaf9d0144;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'التصنيف والمسؤول'**
  String get msg5e1ee5296293;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'فئة المشكلة'**
  String get msg4ca027e90eec;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الموظف المسؤول'**
  String get msg998f15a5fe62;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحديد موعد الاستجابة'**
  String get msgffc4a70a2e55;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'موعد الاستجابة: {p0}'**
  String msgcc99d577732a(Object p0);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المعالجة'**
  String get msg6423b630e42d;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الإصلاح أو الاستبدال'**
  String get msg55819d8e482e;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة تظهر للعميل'**
  String get msgb8b4ea8855db;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا تكتب هنا معلومات داخلية أو حساسة.'**
  String get msg8a2f45135daa;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة داخلية للفريق'**
  String get msgd314b2cf9e37;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لن تظهر للعميل في البوابة أو الرسائل.'**
  String get msgfcd7430fe5b8;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حفظ تفاصيل المطالبة'**
  String get msg7946854a61d8;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أولوية {p0}'**
  String msg3faa17b063fb(Object p0);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متأخرة عن الموعد'**
  String get msg7c83012b2845;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الإجراء التالي'**
  String get msg1e6f7259e388;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حدّث الحالة فور تنفيذ الإجراء ليعرف الفريق أين وصلت المطالبة.'**
  String get msg67d310d7fe93;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بدء مراجعة المطالبة'**
  String get msgc21b0e6e74dd;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'قبول المطالبة'**
  String get msg338a6e3f6418;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'طلب معلومات من العميل'**
  String get msgaa54e8581470;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بدء المعالجة'**
  String get msg4a80c8f233d4;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تجهيزها للاستلام'**
  String get msg2050aebbb97f;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إكمال المطالبة'**
  String get msga9d4e8c51205;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استئناف المعالجة'**
  String get msg5fac64e31dbc;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تأكيد التسليم والإكمال'**
  String get msg9288c5b199d6;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إعادتها للمعالجة'**
  String get msg47bddbd85cb4;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إعادة فتح المطالبة'**
  String get msg247abd28fa31;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إعادة فتح للمراجعة'**
  String get msgca1904f3e709;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع العميل'**
  String get msg2e933f0f15e9;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يرسل ضمانك حالة المطالبة ورابط المتابعة بصياغة جاهزة.'**
  String get msg645e646e9931;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إرسال عبر واتساب'**
  String get msg8378428d3fd2;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get msg606af07c67cb;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحليل'**
  String get msg698fbdcd6041;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إعادة التحليل'**
  String get msgea3f993611e0;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يلخص وصف العميل ويقترح فئة وأولوية وأسئلة ناقصة. لا يتخذ قراراً ولا يغيّر المطالبة تلقائياً.'**
  String get msg5b26587358fe;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'فئة: {p0}'**
  String msg34d6e570eb34(Object p0);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أولوية: {p0}'**
  String msg7d3942248372(Object p0);

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ثقة {p0}%'**
  String msg5e7f0a12ab07(Object p0);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'معلومات يُفضّل طلبها'**
  String get msg05217dcdcd72;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إشارات في الوصف: {p0}'**
  String msg81ba469a03ce(Object p0);

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'، '**
  String get msg11735aabd336;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'التكلفة التقريبية: \${p0}'**
  String msg38874c5d26da(Object p0);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0}/{p1} هذا الشهر'**
  String msg358b2fe4d59b(Object p0, Object p1);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'شمل أول ملفين'**
  String get msgbe2a9d82914d;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استخدام التصنيف والأولوية بعد المراجعة'**
  String get msg34f0233acfe7;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ملفات العميل'**
  String get msg5c0e56a68d71;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل ملفات المطالبة'**
  String get msg5a1e4eb1db5e;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر عرض الملفات الآن. بيانات المطالبة ما زالت محفوظة.'**
  String get msgd449fde59c1b;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get msg14d5786f2e64;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ملفات العميل ({p0})'**
  String msgd30fcea255a6(Object p0);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح الملف. تحقق من الاتصال ثم حاول مرة أخرى.'**
  String get msg63c84e95aaf4;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أرسله العميل'**
  String get msg374c0387e1ae;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أضافه الفريق'**
  String get msge06f2fcdb931;

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'فتح {p0}، {p1}، {p2}'**
  String msg4470a29e2903(Object p0, Object p1, Object p2);

  /// UI copy: screens/claim_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة داخلية\n{p0}'**
  String msg2624f3008a34(Object p0);

  /// UI copy: screens/configuration_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'نسخة المطوّر'**
  String get msgd084c77a02d5;

  /// UI copy: screens/configuration_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'النظام الكامل جاهز للربط.'**
  String get msg9bd21e3a06f6;

  /// UI copy: screens/configuration_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يلزم مشروع Supabase مستقل ومفاتيح البناء لتفعيل الحسابات والمزامنة. يمكنك فتح العرض الآن لتجربة كل مسارات المتجر.'**
  String get msga9237f88c75a;

  /// UI copy: screens/configuration_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'فتح العرض التشغيلي'**
  String get msg2aecff1d1217;

  /// UI copy: screens/configuration_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'قاعدة مستقلة'**
  String get msg618c1cacc7b3;

  /// UI copy: screens/configuration_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أنشئ مشروع Supabase جديداً خاصاً بضمانك؛ لا تستخدم قاعدة أي تطبيق آخر.'**
  String get msg2804b819a0c6;

  /// UI copy: screens/configuration_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'طبّق ملف قاعدة البيانات'**
  String get msg70634a0adefd;

  /// UI copy: screens/configuration_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'نفّذ migration الموجود داخل مجلد damanak_flutter/supabase.'**
  String get msg036aa2e653b5;

  /// UI copy: screens/configuration_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ابنِ بالمفاتيح'**
  String get msgef29ee9c1331;

  /// UI copy: screens/configuration_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مرّر DAMANAK_SUPABASE_URL وDAMANAK_SUPABASE_PUBLISHABLE_KEY عند البناء.'**
  String get msg9078669d3cad;

  /// UI copy: screens/customers_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'دليل العملاء'**
  String get msg8f965fa8332e;

  /// UI copy: screens/customers_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إضافة عميل'**
  String get msgbf5ecb5e2537;

  /// UI copy: screens/customers_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم أو الجوال أو البريد'**
  String get msg72cd9e69b93e;

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get msg2e58b72edf70;

  /// UI copy: screens/customers_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'العملاء المسجلون'**
  String get msg3b446588152c;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عميل جديد'**
  String get msg9f73e063ae8d;

  /// UI copy: screens/customers_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} ضمان مسجل'**
  String msgcda60f94083b(Object p0);

  /// UI copy: screens/customers_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعديل العميل'**
  String get msgd21f656a885f;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اسم العميل'**
  String get msg70771eb8320f;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسم العميل'**
  String get msg149beb2779d5;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رقم الجوال'**
  String get msg6dbe8474b01b;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم جوال صحيحاً'**
  String get msg1635df2532a1;

  /// UI copy: screens/customers_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني (اختياري)'**
  String get msg58d4f0f4cb39;

  /// UI copy: screens/customers_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات (اختياري)'**
  String get msg651b7866185a;

  /// UI copy: screens/customers_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حفظ العميل'**
  String get msgc68629028b85;

  /// UI copy: screens/customers_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد عميل مطابق.'**
  String get msg6df30df80b8a;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الأعداد حسب السجل المحمّل حالياً.'**
  String get msgf758065c9bc0;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مطالبات الضمان الحديثة'**
  String get msge00a71539de4;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get msgcc52200ebc71;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عرض تشغيلي — يمكنك تجربة المسار كاملاً دون إرسال بيانات إلى خادم.'**
  String get msg8a31e9534d36;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} • إصدار الضمان ومتابعة الصيانة من مكان واحد'**
  String msg287b7c7cf0a3(Object p0);

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} متأخرة'**
  String msg12864cd9cdfb(Object p0);

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} بلا مسؤول'**
  String msgc480c8045021(Object p0);

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} جاهزة للاستلام'**
  String msg2ce8eb84fed6(Object p0);

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متابعة اليوم، {p0}'**
  String msg4d308425f002(Object p0);

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متابعة اليوم'**
  String get msgf429d83108ce;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بدء إصدار ضمان جديد'**
  String get msgd53616535a1d;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بمسح المنتج'**
  String get msg8b1fdfb786c4;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'نطابق الباركود مع الكتالوج، ثم تكمل بيانات العميل وتصدر الضمان.'**
  String get msg0d99f8cc07fb;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مسح المنتج'**
  String get msg25182c76dee6;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إدخال يدوي'**
  String get msgb4b8eec4042c;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'امسح المنتج'**
  String get msg5e602d09859b;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل العميل'**
  String get msg3f6d31670d93;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أصدر الضمان'**
  String get msg318aff1c3fce;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ضمان ساري'**
  String get msgdeccfc3a2905;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'قريب الانتهاء'**
  String get msgd839601c93ae;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'صيانة مفتوحة'**
  String get msg24e9465a42ff;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} من {p1} ضماناً هذا الشهر'**
  String msg87e424bf06da(Object p0, Object p1);

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} يوم متبقٍ في التجربة'**
  String msg549a8617b41c(Object p0);

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث {p0}'**
  String msgcf18c240c095(Object p0);

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مطالبات ضمان حديثة'**
  String get msg7d1152f44758;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تظهر هنا المطالبات المسجلة من بطاقات الضمان.'**
  String get msg92199567adc2;

  /// UI copy: screens/home_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'فتح مركز المطالبات'**
  String get msg7e189495d1b1;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اربط نظامك بضمانك'**
  String get msg32e4c4bf1ab4;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مفاتيح محدودة الصلاحية وWebhooks موقّعة للمطالبات. الأسرار تظهر مرة واحدة فقط.'**
  String get msg2ef89624fb92;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إدارة التكاملات متاحة لمالك المتجر فقط.'**
  String get msg69c475f1bbb5;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'قراءة الضمانات والمطالبات وإنشاء مطالبة من نظام خارجي.'**
  String get msgd006819c83d0;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متاح في باقة توسع.'**
  String get msg9aec3e68d086;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مفتاح جديد'**
  String get msg13b60161bea7;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مفاتيح بعد.'**
  String get msg4e1d662db6f8;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إشعار نظامك عند إنشاء مطالبة أو تحديثها.'**
  String get msgd849a0413238;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رابط جديد'**
  String get msg93f3c248a561;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا توجد روابط استقبال بعد.'**
  String get msgdb126e6fa615;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عرض باقة توسع'**
  String get msg7be81ee52e15;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'انسخ مفتاح API الآن'**
  String get msg130e05c33a70;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لن نعرض هذا المفتاح كاملاً مرة أخرى.'**
  String get msgc4fed8918459;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سر توقيع Webhook'**
  String get msgbd4e16d06de0;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استخدمه للتحقق من ترويسة x-damanak-signature. لن يظهر كاملاً مرة أخرى.'**
  String get msg679e6cf2d464;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إلغاء المفتاح فوراً؟'**
  String get msg5ce7c147d834;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سيتوقف «{p0}» عن العمل ولا يمكن استعادته.'**
  String msg3c4870c1d279(Object p0);

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إلغاء المفتاح'**
  String get msgfb5485cbbc6e;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ.'**
  String get msg48b2aff2b1a3;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get msg29a0e2739a92;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حفظته'**
  String get msg28da90313e7e;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0}… • {p1} صلاحيات'**
  String msg711625369e11(Object p0, Object p1);

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مفتاح API جديد'**
  String get msg76526f5838b3;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اسم الاستخدام'**
  String get msg478eee91c22d;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'قراءة الضمانات'**
  String get msg20e1047902e4;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'قراءة المطالبات'**
  String get msgf60ce278fc14;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إنشاء مطالبة'**
  String get msg779a27aba7f5;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get msga820f3590d36;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'Webhook جديد'**
  String get msge401fff86fca;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رابط HTTPS'**
  String get msgb3895826cf8a;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مطالبة جديدة'**
  String get msg946f0256003d;

  /// UI copy: screens/integrations_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحديث مطالبة'**
  String get msga8c00baf4c19;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get msga0e7c1b2423d;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رصيد فعلي لكل فرع مع سجل كامل للحركات.'**
  String get msg77ec83154126;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الأصناف'**
  String get msgcdc1331ab21e;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحتاج انتباهاً'**
  String get msg93020592faa0;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عرض مخزون الفرع'**
  String get msg90bc2bfaccb2;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بحث في المخزون'**
  String get msg5b37a29b3f7e;

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مسح باركود'**
  String get msgef037f26c21d;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **' • متسلسل'**
  String get msg0bdd40a9e689;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متاح {p0}'**
  String msg3c5264e88fce(Object p0);

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حد الطلب {p0}'**
  String msg5ca3e9ac1e4c(Object p0);

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تكلفة {p0}'**
  String msg00c439c9e1cc(Object p0);

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إدارة المخزون'**
  String get msg8330a0c71014;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تسوية الرصيد'**
  String get msg21ee6ce92265;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحويل لفرع'**
  String get msg0c19e9d7514c;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تسوية {p0}'**
  String msgc26759e06f41(Object p0);

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرصيد الذي عُد فعلياً، وسيُحفظ الفرق كحركة تدقيق.'**
  String get msg18a5dc02e52e;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الرصيد الفعلي'**
  String get msga8e0fa2ad992;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متوسط تكلفة الوحدة'**
  String get msga82a4ab6a00d;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سبب التسوية'**
  String get msg046d9847b03a;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جرد فعلي، تلف، فرق استلام…'**
  String get msgd84e3987c305;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اذكر سبباً واضحاً للتدقيق'**
  String get msg3c94b6a4fd15;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حفظ التسوية'**
  String get msgd8a3c0282316;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقماً صفراً أو أكبر'**
  String get msg981ec91b2ce8;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحويل {p0}'**
  String msg20c617d828ac(Object p0);

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'من {p0} • المتاح {p1}'**
  String msgee2c7ed76339(Object p0, Object p1);

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إلى الفرع'**
  String get msgab8fdcefa964;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get msg935e21853946;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الكمية يجب أن تكون ضمن الرصيد المتاح'**
  String get msge342accfe3ff;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة التحويل (اختياري)'**
  String get msgdaa5eccaa4f0;

  /// UI copy: screens/inventory_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تنفيذ التحويل'**
  String get msg7e05ad8ae33d;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تفضيلات الإشعارات'**
  String get msg27c534b023e0;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات العمل فقط'**
  String get msgd70c3b9d0a2f;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'هذه التفضيلات تخص مركز الإشعارات داخل ضمانك. لن نرسل عروضاً تسويقية، ولن نطلب إذن إشعارات النظام قبل تهيئة الإرسال الآمن.'**
  String get msgc6ff0d2513b0;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عندما يرسل عميل مطالبة أو يسجلها الموظف.'**
  String get msg2319f6847e1c;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إسناد مطالبة إليّ'**
  String get msgdd5d2366cc2d;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عندما يحدد المدير أنك المسؤول عنها.'**
  String get msg13696aed920d;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تجاوز وقت الخدمة'**
  String get msg09974a56b691;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'للمطالبات المفتوحة التي تجاوزت موعد المتابعة.'**
  String get msgd4fbaa3fea6c;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جاهزة للاستلام'**
  String get msg72028eceaa98;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لتذكير الفريق بالتواصل مع العميل.'**
  String get msg2a4e74c35861;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الحفظ…'**
  String get msg47d263ad0ba4;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حفظ التفضيلات'**
  String get msgdd485ffd9e55;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تنبيهات الآن'**
  String get msgd4621798c532;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ستظهر هنا المطالبات الجديدة وما أُسند إليك وما أصبح جاهزاً للاستلام.'**
  String get msg980aceff5ec4;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get msgbaef96cba5de;

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'منذ {p0} دقيقة'**
  String msg0e5eb0eeb216(Object p0);

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'منذ {p0} ساعة'**
  String msg7c3659ded239(Object p0);

  /// UI copy: screens/notifications_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'منذ {p0} يوم'**
  String msg292c8f51e571(Object p0);

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get msg39db927c23ae;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'كيف ستعمل مع ضمانك؟'**
  String get msg1779ceec5eef;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أنشئ مساحة لمتجرك إذا كنت المالك، أو انضم إلى متجر قائم برمز يرسله لك المدير.'**
  String get msg0580a86e3e83;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إنشاء متجر'**
  String get msg1bd5869117c2;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الانضمام لمتجر'**
  String get msg92ed9866f7c3;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اسم المتجر'**
  String get msga9ac0e475f40;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسم المتجر'**
  String get msg3a8d048d5e4d;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الدولة'**
  String get msgc431df1c0011;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'قطر'**
  String get msg8305ce4b9abd;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'السعودية'**
  String get msg1f95822cfb7d;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الإمارات'**
  String get msgdd3c0e93e763;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الكويت'**
  String get msg3c35f06de352;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'البحرين'**
  String get msg5cd57d0c88af;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عُمان'**
  String get msg0686c80527f1;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل المدينة'**
  String get msg37214777bc9f;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رقم تواصل المتجر'**
  String get msgf88494098b0b;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم تواصل صحيحاً'**
  String get msgbe10c77a7a79;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تبدأ الخطة المجانية تلقائياً بـ20 ضماناً كل شهر على تثبيت محمي واحد. وإذا استُخدمت لهذا الحساب أو التثبيت سابقاً، يمكنك اختيار باقة مدفوعة.'**
  String get msgf5696ee7fa28;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ إنشاء المتجر…'**
  String get msg2e2581d7092a;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إنشاء المتجر وبدء الخطة'**
  String get msg13243d6e07c6;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رمز دعوة الفريق'**
  String get msgb0c1a6b0c3a3;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'افتح ضمانك وأدخل رمز الدعوة الذي أرسله المدير. لا تحتاج إلى كلمة مرور المالك.'**
  String get msg186d2c125047;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم تحميل الدعوة. صلاحيتك بعد الانضمام: {p0}.'**
  String msgdb794a28a328(Object p0);

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رمز الدعوة'**
  String get msg6bdc508afffd;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز الدعوة كاملاً'**
  String get msg9bb061e26503;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الانضمام…'**
  String get msg52892306c67a;

  /// UI copy: screens/onboarding_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الانضمام'**
  String get msgdea2b5ee4ce1;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الباركود غير مسجل بعد.'**
  String get msg2fd95dc1a99c;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إضافة المنتج'**
  String get msg599ed9b2189e;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أضف سعر بيع إلى {p0} أولاً.'**
  String msgebc17899cc00(Object p0);

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'نفدت الكمية المتاحة من {p0}.'**
  String msga301affe5159(Object p0);

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم البيع وحفظ الإيصال {p0}.'**
  String msg636607b996fe(Object p0);

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تغيير الفرع'**
  String get msgde4db213d3b3;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الفرع'**
  String get msg8a706d30e0ed;

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اسم المنتج أو الباركود…'**
  String get msgd1198387ad69;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مراجعة وإتمام البيع'**
  String get msgd58160481342;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اكتب الرقم أو امسحه بالكاميرا.'**
  String get msge746c7c51155;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'هذا الرقم موجود في السلة بالفعل.'**
  String get msgd0506250eddc;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رقم القطعة'**
  String get msge23bdfa31f51;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مسح الرقم التسلسلي'**
  String get msg95475323890f;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أو اكتبه يدوياً'**
  String get msg6ed31b8a223f;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يُربط بالقطعة وضمانها.'**
  String get msgfd2f175c6f1d;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إضافة الرقم للسلة'**
  String get msg9c8e19ee120d;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متاح للبيع'**
  String get msg2b22bfedb2b2;

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المتوفر {p0}'**
  String msg9d8f17d53ab6(Object p0);

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إضافة {p0}'**
  String msgd2340abd10ff(Object p0);

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تقليل الكمية'**
  String get msg2cd1436defd5;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'زيادة الكمية'**
  String get msgea8664c03f07;

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد منتج مطابق'**
  String get msgc5ca157dad01;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أضف أول منتج لتبدأ البيع'**
  String get msgd418d297cb5d;

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جرّب اسماً أو باركوداً آخر.'**
  String get msgceedff773256;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يكفي الاسم والسعر والكمية. تستطيع إضافة بقية التفاصيل لاحقاً.'**
  String get msg781887077750;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إضافة منتج'**
  String get msg515506c4eaa6;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إجمالي البيع يجب أن يكون أكبر من صفر.'**
  String get msg2bf759332486;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مجموع الدفعات يجب أن يساوي {p0}.'**
  String msgce33cdeba1f9(Object p0);

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحصيل البيع'**
  String get msgaed38a79ce77;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} منتجات • {p1}'**
  String msg61dfae680422(Object p0, Object p1);

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get msgae2d60052976;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ربط البيع بعميل'**
  String get msg808b65537bdd;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بيانات العميل مطلوبة لإنشاء الضمان تلقائياً.'**
  String get msg2d5c97c70485;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إخفاء التفاصيل الإضافية'**
  String get msg4520bf130285;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'خصم أو تقسيم الدفع'**
  String get msgd9d5e5385cb5;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الخصم'**
  String get msgb593a6457673;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل خصماً صحيحاً'**
  String get msgae03778f56c1;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تقسيم الدفع'**
  String get msg18420f50a868;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استخدم طريقتين للدفع في العملية نفسها.'**
  String get msg447b345a02f4;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختياري)'**
  String get msgc3fc8a6c2041;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تأكيد {p0}'**
  String msg00a2ea2289ab(Object p0);

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إزالة العميل'**
  String get msg5aa88db78e0d;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عميل محفوظ'**
  String get msg2b0c6a2e8a05;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الطريقة'**
  String get msg0572c0f0cf19;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get msg1cd480f91b24;

  /// UI copy: screens/point_of_sale_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مبلغ غير صحيح'**
  String get msg477aa3178253;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أوامر الشراء'**
  String get msg37d10770219f;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الموردون'**
  String get msge9907912acf6;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} موردين نشطين'**
  String msg24348f4b9021(Object p0);

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مورد'**
  String get msg9b286307f684;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أضف المورد الأول لبدء أوامر الشراء.'**
  String get msg2066172a5f71;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} أوامر شراء'**
  String msga714623dcee2(Object p0);

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أمر جديد'**
  String get msg56d621339101;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أضف مورداً أولاً من تبويب الموردين.'**
  String get msg5453ad7ce99a;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أوامر شراء بعد.'**
  String get msg1d610c795c9e;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} أصناف'**
  String msgd10984c34bd5(Object p0);

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استلام كامل وتحديث المخزون'**
  String get msgdc3e3b89eb83;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مورد جديد'**
  String get msg9e920136dad3;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعديل المورد'**
  String get msg491a2b55387d;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اسم الشركة أو المورد'**
  String get msg881c6f87377c;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اسم مسؤول التواصل'**
  String get msg2d47a8a2f231;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get msgddf0fca39a4f;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get msg2d110e56d5f5;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get msgd446d2dc6b81;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حفظ المورد'**
  String get msg32ffe863ab83;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أمر شراء جديد'**
  String get msg1c89e0bef044;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'فرع الاستلام'**
  String get msg59daeec17138;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المورد'**
  String get msg4680c31a727f;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تكلفة الوحدة'**
  String get msg86df419eaf6e;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إضافة للأمر'**
  String get msg409af7a5a6d3;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات الأمر (اختياري)'**
  String get msg0cdc868b58b7;

  /// UI copy: screens/procurement_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إنشاء وإرسال الأمر'**
  String get msgb06d19e66e3b;

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أرشفة المنتج؟'**
  String get msg9ed97dc7f3a4;

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سيختفي المنتج من الكتالوج والمسح، وستبقى الضمانات السابقة محفوظة.'**
  String get msg1fc12cdc21c7;

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أرشفة المنتج'**
  String get msg10d4b0e1336c;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'منتج جديد'**
  String get msg5f93d58f33e3;

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استيراد منتجات CSV'**
  String get msg4b948f5006d1;

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} منتج • اضغط على أي منتج لتعديله'**
  String msgf82a12967eb6(Object p0);

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بلا ضمان'**
  String get msg2086605a1a6e;

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ضمان {p0} شهر'**
  String msgb03d6bc93521(Object p0);

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إدارة المنتج'**
  String get msga8f571f81f05;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعديل المنتج'**
  String get msgf952513ba85f;

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الكتالوج فارغ'**
  String get msg83998fd1b792;

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أضف المنتجات التي تبيعها لتسريع إصدار الضمان.'**
  String get msgdf4187af8e73;

  /// UI copy: screens/products_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إضافة أول منتج'**
  String get msgeb40ed688722;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رصيد أولي عند إضافة المنتج'**
  String get msg4cb99fac5bbb;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعديل الرصيد من بطاقة المنتج'**
  String get msg901f25dbe8cb;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'غيّر ما تحتاجه فقط.'**
  String get msg8b23844de0da;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الاسم والسعر والكمية تكفي للبدء.'**
  String get msg93fc12b500de;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اسم المنتج'**
  String get msg57efd1ac6869;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سعر البيع'**
  String get msg2d37565e6fe3;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل سعراً صحيحاً'**
  String get msg3f31bdb96388;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الكمية الحالية'**
  String get msgcefa6ccfca09;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الباركود (اختياري)'**
  String get msg8e6750d61bff;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مسح الباركود'**
  String get msgb63457dea004;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الضمان'**
  String get msgb3b3c061b465;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} شهراً'**
  String msg5ec8afa2a31e(Object p0);

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إخفاء الخيارات الإضافية'**
  String get msg36969e86e76e;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'علامة تجارية وتكلفة وخيارات مخزون'**
  String get msg88ecfd057419;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'العلامة التجارية'**
  String get msgaba316f6a70b;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get msg3a7c87ed0100;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رمز المخزون (اختياري)'**
  String get msgf937a7f18116;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تكلفة الشراء'**
  String get msg62c92ea6ab8a;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تنبيه عند كمية'**
  String get msg42d90631a5ff;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تتبّع الكمية'**
  String get msgf65af7345818;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أوقفه للخدمات أو المنتجات غير المخزنة.'**
  String get msge69fc97b753f;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تغطية خاصة لهذا المنتج'**
  String get msg3d9a91420e22;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اتركها فارغة لاستخدام سياسة المتجر.'**
  String get msgac9e7e538afe;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استثناءات خاصة بهذا المنتج'**
  String get msgc9dc69820b4f;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اتركها فارغة لاستخدام استثناءات المتجر.'**
  String get msg177ad41891db;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رقم تسلسلي لكل قطعة'**
  String get msged18040b60cd;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'للهواتف والأجهزة التي تحتاج تتبعاً فردياً.'**
  String get msg975e7e328277;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديلات'**
  String get msg6c03d6737c2f;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حفظ المنتج'**
  String get msga5fec1aeeb19;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسم المنتج'**
  String get msgc833a0d05983;

  /// UI copy: screens/product_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقماً صحيحاً'**
  String get msga0400e1d27d8;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استيراد المنتجات'**
  String get msg7da25370ad4d;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أضف الكتالوج دفعة واحدة'**
  String get msgc7132683d675;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اختر ملف CSV، راجع الأخطاء، ثم احفظ الصفوف السليمة فقط. لن نحذف أو نعدّل منتجاتك الحالية.'**
  String get msg2ff93e9e5a5a;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اختيار ملف CSV'**
  String get msg22282be709e3;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اختيار ملف آخر'**
  String get msg4f00cfb1a90e;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحليل PDF أو صورة'**
  String get msgd0be8058de1b;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'قالب جاهز'**
  String get msg88935eec0c25;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استخدم التحليل للكتالوجات غير الشخصية فقط. لا ترفع فواتير تحتوي أسماء عملاء أو أرقام هواتف؛ ستراجع كل بند قبل حفظه.'**
  String get msgdab883505768;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المعاينة'**
  String get msg0a40c58ac7c3;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم عرض أول 50 صفاً. سيُفحص الملف كاملاً عند الاستيراد.'**
  String get msg6c25eb2e88bd;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الاستيراد…'**
  String get msg2116a0b32a96;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استيراد {p0} منتج'**
  String msg961c99a8347a(Object p0);

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة {p0}، وتعذر {p1}.'**
  String msg40b95a7c5c2c(Object p0, Object p1);

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة الملف. اختر ملف CSV محفوظاً بترميز UTF-8.'**
  String get msgafb4d430799e;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الثقة منخفضة؛ راجع هذا البند وأضفه يدوياً'**
  String get msgfcd45e8640a7;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'الباركود موجود في الكتالوج'**
  String get msg05ffcc50bae0;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الباركود مكرر في المستند'**
  String get msgddd221288b42;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحليل المستند الآن. حاول بصورة أوضح أو استخدم CSV.'**
  String get msgdbd7edea4ea9;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة {p0} منتج إلى الكتالوج.'**
  String msge7ff83434b7d(Object p0);

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'﻿اسم المنتج,الشركة,الفئة,الباركود,رمز المخزون,مدة الضمان,سعر البيع,سعر التكلفة,تسلسلي\r\nهاتف تجريبي,الشركة,هواتف,1234567890123,PHONE-01,12,1000,800,نعم\r\n'**
  String get msg718514128473;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'قالب استيراد منتجات ضمانك'**
  String get msgf3c60f9cbf5d;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حجم الملف أكبر من 2 MB.'**
  String get msg7236f4dda039;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الملف أكبر من 500 منتج. قسّمه إلى ملفين.'**
  String get msg2e9dd57261c9;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الملف لا يحتوي على منتجات.'**
  String get msg62bc11b3b73c;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أضف عمود «اسم المنتج» أو استخدم القالب الجاهز.'**
  String get msg1a5d40ae08ae;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر فهم الملف. استخدم القالب الجاهز ثم حاول مجدداً.'**
  String get msgc64f37dc61c0;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حجم المستند أكبر من 8 MB.'**
  String get msg99211b25b807;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'وصل المتجر إلى حد 25 تحليلاً اليوم. أكمل غداً أو استخدم CSV.'**
  String get msg42a260cf8095;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استهلك المتجر تحليلات الذكاء الاصطناعي المشمولة هذا الشهر. استخدم CSV أو انتظر بداية الشهر التالي.'**
  String get msgad749680dd69;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف التحليل مؤقتاً لحماية الحساب من الاستخدام غير المعتاد. حاول غداً أو استخدم CSV.'**
  String get msg72f71bb6d71f;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحليل الملفات غير مشمول في الخطة الحالية. ما زال استيراد CSV متاحاً.'**
  String get msgf9cecf4ef620;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'خدمة الذكاء الاصطناعي غير مهيأة على الخادم بعد.'**
  String get msg1b71cdc2146e;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لم نعثر على بنود منتجات واضحة في المستند.'**
  String get msg6bd24b889ef4;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحليل المستندات متاح للمالك أو المدير فقط.'**
  String get msg879aa43acd89;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحليل المستند. استخدم صورة أو PDF واضحاً ثم حاول مجدداً.'**
  String get msg3d7a16d199ea;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **' • {p0}/{p1} هذا الشهر'**
  String msg08d7e5b813b5(Object p0, Object p1);

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **' بعد التحويل التلقائي'**
  String get msg34a42928114a;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'دون تكلفة مزود حالياً'**
  String get msg484a070a0d97;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'التكلفة غير متاحة'**
  String get msgba3ff8cf94fb;

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تكلفة تقريبية \${p0}'**
  String msg16fa83c9c867(Object p0);

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اقتراح من {p0}{p1} — {p2}{p3}. راجع كل بند قبل الحفظ.'**
  String msg3dad50574322(Object p0, Object p1, Object p2, Object p3);

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} صف'**
  String msg1031703cb9b9(Object p0);

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} جاهز'**
  String msg6a210a2d210e(Object p0);

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} يحتاج مراجعة'**
  String msgbf6ab67c7f6a(Object p0);

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'صف {p0}'**
  String msgfc7eba5345b4(Object p0);

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} شهر'**
  String msgb2f6a21fe6bd(Object p0);

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الكمية {p0}'**
  String msg894d7bfa79b9(Object p0);

  /// UI copy: screens/product_import_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'من المستند: {p0}'**
  String msgc35f42fce649(Object p0);

  /// UI copy: screens/register_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جلسات الصندوق'**
  String get msgd127ef29f50d;

  /// UI copy: screens/register_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'كل وردية تبدأ برصيد افتتاحي وتنتهي بجرد فعلي يظهر العجز أو الزيادة.'**
  String get msg037b9f8c678c;

  /// UI copy: screens/register_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا توجد جلسات صندوق بعد. افتح أول جلسة من نقطة البيع.'**
  String get msg740bccec6c9a;

  /// UI copy: screens/register_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مفتوح'**
  String get msg46ea59915eec;

  /// UI copy: screens/register_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مغلق'**
  String get msge655261f9c96;

  /// UI copy: screens/register_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get msgca90c297b099;

  /// UI copy: screens/register_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الافتتاحي'**
  String get msg7123bef9e335;

  /// UI copy: screens/register_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مبيعات نقدية'**
  String get msg5b897d3bb02f;

  /// UI copy: screens/register_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المتوقع'**
  String get msg8d0a03c36d7f;

  /// UI copy: screens/register_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الفرق'**
  String get msg0b5254487af9;

  /// UI copy: screens/register_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إغلاق الصندوق'**
  String get msg395c4b980330;

  /// UI copy: screens/register_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'النقد المعدود فعلياً'**
  String get msgafbc17090735;

  /// UI copy: screens/register_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سيُحسب الفرق تلقائياً ويحفظ في سجل الوردية.'**
  String get msgcad9e227c5b8;

  /// UI copy: screens/register_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الإغلاق'**
  String get msg92f294545557;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تصدير المطالبات CSV'**
  String get msg4413206fb3ff;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'صحة خدمة ما بعد البيع'**
  String get msg3f718fc08a19;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أرقام تشغيلية تساعدك على تقليل التأخير وتحسين قرار الضمان.'**
  String get msgb7166f8ebf05;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مطالبات مفتوحة'**
  String get msg3e965378aea3;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مطالبات متأخرة'**
  String get msgee61d382e5a9;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'نسبة القبول'**
  String get msgf05f2eb8e683;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متوسط وقت القبول'**
  String get msg4274413816a7;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متوسط وقت الإغلاق'**
  String get msgb4908cd47786;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ضمانات سارية'**
  String get msge643c6cc697c;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أسباب المطالبات'**
  String get msga5438e52bca2;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مطالبات مصنفة بعد.'**
  String get msgbc67fe11a8c6;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'قرارات المعالجة'**
  String get msga6c21ee652c9;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تظهر القرارات بعد إغلاق أول مطالبة.'**
  String get msg2a61a562f417;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تصدير سجل المطالبات CSV'**
  String get msg458477c1157c;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يشمل الحالة والأولوية والمسؤول والقرار وأوقات المعالجة.'**
  String get msgeadba8bd2e70;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تصدير سجل الضمانات CSV'**
  String get msgd0a5192998cd;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} ضمان • العملة {p1}'**
  String msg2c600aad6d9f(Object p0, Object p1);

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'آخر النشاطات'**
  String get msg623bfa279466;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} د'**
  String msg3f2e0dfb89ae(Object p0);

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} س'**
  String msg0ad7d321ec09(Object p0);

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} يوم'**
  String msg435e31311dfe(Object p0);

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رقم المطالبة'**
  String get msg9352b360a76f;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رقم الضمان'**
  String get msga97505f65ec3;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get msgc3a4749caed4;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الإنشاء'**
  String get msgdc08056fa4f2;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث'**
  String get msg78a3ea160681;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'موعد الخدمة'**
  String get msg3807bc689d6e;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تقرير مطالبات {p0}'**
  String msg321eecc7260a(Object p0);

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رقم الإيصال'**
  String get msg239cb47cd98d;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get msgd90c384199ac;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الجوال'**
  String get msg0b6aa9453dfb;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get msg259862e8b313;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get msgbaed6e999960;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'العملة'**
  String get msg30ce3a1dae2c;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تقرير ضمانات {p0}'**
  String msg1db2d1d6ed62(Object p0);

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سيظهر هنا سجل تغييرات المنتجات والضمانات والفروع.'**
  String get msg883b8347d313;

  /// UI copy: screens/reports_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سجل النشاط متاح للمالك والمدير فقط.'**
  String get msgd5be13d93eee;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مركز المطالبات'**
  String get msg081f4ef7ed4f;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'راجع الطلب، عيّن المسؤول، واتخذ القرار حتى تسليم المنتج.'**
  String get msg25831c564495;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ابحث في المطالبات'**
  String get msg4f3a5a119750;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رقم المطالبة، المنتج، العميل أو الرقم التسلسلي'**
  String get msgec3418a47ed0;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} مطالبة'**
  String msgc88d23dcd675(Object p0);

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'كل الفريق'**
  String get msg28e2637a22f8;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عملي'**
  String get msgad4bb1745fef;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'نطاق العمل'**
  String get msg247e564e696f;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مفتوحة'**
  String get msg7c0267827a67;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحتاج إجراء'**
  String get msg1c3a81f7a25c;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متأخرة'**
  String get msg05fa56b7d10b;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مغلقة'**
  String get msgca7e1dec1654;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0}، {p1}'**
  String msg4dfbe865820e(Object p0, Object p1);

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مطالبات ضمان'**
  String get msg59d8e21cd1c0;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تُسجل المطالبة من بطاقة الضمان، وستظهر هنا للمتابعة والتعيين.'**
  String get msgc30a30f991ed;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مطالبة تطابق البحث'**
  String get msg7bd179b36d19;

  /// UI copy: screens/requests_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عرض كل المطالبات'**
  String get msg4df7f86c6928;

  /// UI copy: screens/sales_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رقم الإيصال أو العميل أو الهاتف'**
  String get msg90d9032ae2c0;

  /// UI copy: screens/sales_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مبيعات مطابقة.'**
  String get msgb82c479b5fdf;

  /// UI copy: screens/sales_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اختر كمية واحدة على الأقل للإرجاع.'**
  String get msg0a43f9baef5e;

  /// UI copy: screens/sales_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اذكر سبب المرتجع لحفظ سجل واضح.'**
  String get msg8f529bdf8ab2;

  /// UI copy: screens/sales_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مباع {p0} • مرتجع {p1}'**
  String msg0f8cc326104a(Object p0, Object p1);

  /// UI copy: screens/sales_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'كمية المرتجع'**
  String get msg635859257026;

  /// UI copy: screens/sales_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'قبل الخصم'**
  String get msgdba2339eb860;

  /// UI copy: screens/sales_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المرتجع'**
  String get msga52fb2cb00c6;

  /// UI copy: screens/sales_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الصافي'**
  String get msg14561ea1df5d;

  /// UI copy: screens/sales_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تسجيل مرتجع'**
  String get msg1aeab420bcd7;

  /// UI copy: screens/sales_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'طريقة رد المبلغ'**
  String get msg4b2b715b01b7;

  /// UI copy: screens/sales_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سبب المرتجع'**
  String get msg7f620d885e69;

  /// UI copy: screens/sales_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تأكيد المرتجع'**
  String get msge07345d716bc;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ماسح ضمانك'**
  String get msgeef242e5f60a;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'وجّه رمز الرقم التسلسلي داخل الإطار'**
  String get msg3a4e66889236;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'وجّه الباركود داخل الإطار'**
  String get msg694c78c1743d;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إذا تعذّرت القراءة، اكتب الرقم التسلسلي يدوياً.'**
  String get msge1f1a8206c6c;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إذا تعذّرت القراءة، أدخل الرقم المكتوب تحت الباركود.'**
  String get msg4722ca18bc62;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إدخال الرقم التسلسلي'**
  String get msg8cfd61170f97;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إدخال الباركود'**
  String get msg495059d04864;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رقم الباركود'**
  String get msg89120753f66e;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استخدام الرقم'**
  String get msg0f60e04c50eb;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get msgd0f6edcf6d65;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا غير متاحة حالياً'**
  String get msgd65b17f41a7f;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اسمح باستخدام الكاميرا من إعدادات الجهاز، أو استخدم الإدخال اليدوي أدناه.'**
  String get msgce22a010407c;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إطفاء الإضاءة'**
  String get msg738b82a27754;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الإضاءة'**
  String get msgd7050d12fdbb;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تبديل الكاميرا'**
  String get msg22d515581ae2;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إدخال'**
  String get msg3e8f9b9cc74e;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تمت مطابقة المنتج'**
  String get msg5961abc0e384;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'باركود جديد على المتجر'**
  String get msg9efb15a0be65;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} • ضمان {p1} شهراً'**
  String msg0c85a84d5f42(Object p0, Object p1);

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أضف بيانات هذا المنتج مرة واحدة، ثم سيُعرف تلقائياً في كل مسحة لاحقة.'**
  String get msgbefe82928c8b;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إصدار ضمان لهذا المنتج'**
  String get msg59af482d0dba;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إضافة المنتج للكتالوج'**
  String get msg8a171a40773a;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إصدار ضمان بإدخال اسم المنتج'**
  String get msgaa03d5cb4d42;

  /// UI copy: screens/scanner_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'العودة للمسح'**
  String get msgfd6dbd8625c7;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعديل إعدادات المتجر متاح للمالك والمدير فقط.'**
  String get msg5b7c86ff0822;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'هوية المتجر'**
  String get msg6070d0810577;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رقم التواصل'**
  String get msgb6dc7e167c03;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'هوية بطاقة العميل'**
  String get msg166c2ffa66b6;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الهوية المخصصة مشمولة في باقتي نمو وتوسع. ستبقى هوية ضمانك الافتراضية في الباقة الحالية.'**
  String get msg54c0a3ec665a;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عنوان بطاقة الضمان'**
  String get msgc0bf39194a34;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اكتب عنواناً واضحاً'**
  String get msgcb479a339dcd;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رابط شعار HTTPS (اختياري)'**
  String get msg2436efa6ba23;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استخدم رابط صورة ثابتاً ومشفراً. لن يظهر الرابط نفسه للعميل.'**
  String get msg8c55f5ec55e5;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استخدم رابطاً يبدأ بـ https://'**
  String get msg36c629f2a1bb;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لون واحد للهوية'**
  String get msg283f640cdd9a;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'العملة والسجل'**
  String get msg4dcfe919a879;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عملة المتجر الأساسية'**
  String get msgaf4cf170eb41;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'السجل التجاري (اختياري)'**
  String get msg810d79d7b286;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الإيصالات والضمان'**
  String get msge5f551c71c20;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بادئة رقم الإيصال'**
  String get msgad638a0ea91c;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'من 2 إلى 8 أحرف أو أرقام لاتينية.'**
  String get msg21fa5d68e184;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استخدم 2–8 أحرف أو أرقام لاتينية'**
  String get msgda983896ba06;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مدة الضمان الافتراضية'**
  String get msg8b208f6650c6;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ما الذي يغطيه الضمان؟'**
  String get msgdcfacfb8d15b;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مثال: عيوب الصناعة والأعطال الداخلية خلال مدة الضمان.'**
  String get msg70a3b2113590;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الاستثناءات'**
  String get msg4eafb03d32c3;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مثال: الكسر، السوائل، وسوء الاستخدام ما لم يُذكر غير ذلك.'**
  String get msg456150a31b87;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حفظ إعدادات المتجر'**
  String get msge3d20512e7c5;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سوريا'**
  String get msgcf3be6cf396b;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لون الهوية المحدد'**
  String get msgbbc5a156723d;

  /// UI copy: screens/settings_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اختيار لون الهوية'**
  String get msg048375d837b9;

  /// UI copy: screens/shell_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get msgbfcf48307970;

  /// UI copy: screens/shell_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الضمانات'**
  String get msgc47227163f19;

  /// UI copy: screens/shell_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المطالبات'**
  String get msg1fc57897e9e3;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إصدار ضمان'**
  String get msg92cb3a8b07d2;

  /// UI copy: screens/startup_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جاري تجهيز ضمانك'**
  String get msg40e87bea67b7;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تفعيل المتجر'**
  String get msge766399ece5b;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الباقات والترقية'**
  String get msgb376597c34c6;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اختر الباقة'**
  String get msg5cf9073413f5;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الأسعار والعملات من {p0}.'**
  String msgb1dfc2e286f5(Object p0);

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متاح لمالك المتجر فقط'**
  String get msgeaa3b00e46f5;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدر الاشتراك من متجره الحالي'**
  String get msge9fec950706e;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ فتح متجر التطبيقات…'**
  String get msge876367a763a;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بانتظار تأكيد المتجر'**
  String get msgbc9db4c6f5eb;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اختر باقة'**
  String get msgd4b182a0f958;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'السعر غير متاح'**
  String get msg678577473255;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك في {p0}'**
  String msg5c34e3c083b9(Object p0);

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الترقية إلى {p0}'**
  String msgd3601ea818cf(Object p0);

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'التغيير إلى {p0}'**
  String msga47cd0ae4df5(Object p0);

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'باقتك الحالية'**
  String get msgd66e0f6edc99;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الباقة غير متاحة'**
  String get msgcfbed5399f0d;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر التحقق من الباقة'**
  String get msgb136d0c77e68;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الترقية'**
  String get msg88755786919e;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تأكيد تغيير الفوترة'**
  String get msg3f14b8ece2cc;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الاشتراك'**
  String get msg0da307b52c2d;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يرتفع حد هذا الشهر من {p0} إلى {p1} ضماناً. استخدمت {p2}، فيصبح المتاح {p3}. لا تُجمع حصص الباقات.'**
  String msg84110a460c6a(Object p0, Object p1, Object p2, Object p3);

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تتغير دورة فوترة باقة {p0} إلى {p1}. تبقى الحصة واستخدام هذا الشهر كما هما، ويحدد المتجر موعد تطبيق التغيير النهائي.'**
  String msg7d18cef28c3a(Object p0, Object p1);

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سيعرض المتجر تفاصيل الاشتراك النهائية قبل التأكيد.'**
  String get msg215ae57cc5f8;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المتابعة للترقية'**
  String get msg92d3f5042c3b;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متابعة تغيير الفوترة'**
  String get msg3beba1a51a10;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المتابعة للاشتراك'**
  String get msg73e066ea7fb2;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} من {p1}. ستظهر الرسوم وموعد التطبيق النهائي في نافذة المتجر.'**
  String msg4474a560188a(Object p0, Object p1);

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل حالة الاشتراك…'**
  String get msga28b8d2b660e;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ابدأ باشتراك مدفوع'**
  String get msg16aef52fbd2e;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اشتراك فعّال'**
  String get msg2cf98821e8a1;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا توجد باقة مفعّلة'**
  String get msg79c263619656;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ضماناتك السابقة محفوظة، ويتوقف إصدار ضمانات جديدة فقط'**
  String get msg33ba77066dc5;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اختر باقة أدناه، أو استعد مشترياتك إذا سبق أن اشتركت.'**
  String get msgc43f90428dcc;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يمكن لمالك المتجر اختيار باقة أو استعادة المشتريات.'**
  String get msgd46a5510a201;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ضماناتك السابقة محفوظة؛ يتوقف إصدار ضمانات جديدة فقط.'**
  String get msg52d88dcf6db7;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مفعّلة'**
  String get msg11dbdea40ec3;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مفعّل مؤقتاً'**
  String get msg5f7d9e7d61b9;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'فعّال ويتجدد'**
  String get msgfc1f775371cf;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'فعّال'**
  String get msgd9987da5d3f5;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحتاج الفوترة إلى مراجعة'**
  String get msgc89bb494c86b;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'غير فعّال'**
  String get msg1e2d2dc37f60;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'التجديد'**
  String get msg828a77d08cb3;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الانتهاء'**
  String get msgb7463e893610;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} ضماناً شهرياً'**
  String msgd89c4330e58a(Object p0);

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تثبيت محمي واحد'**
  String get msg4f7f10468891;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'خطتك المجانية'**
  String get msg0745b4bb01c2;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} ضماناً متبقياً من {p1}'**
  String msg90cbf3d83b42(Object p0, Object p1);

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تبدأ الحصة من جديد تلقائياً مع بداية كل شهر، من دون اشتراك في App Store أو Google Play.'**
  String get msg96422645630a;

  /// UI copy: widgets/message_banner.dart
  ///
  /// In ar, this message translates to:
  /// **'إغلاق الرسالة'**
  String get msg5f9e78696d67;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر إكمال العملية'**
  String get msgbf4bbec69b0f;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لم تبدأ دفعة جديدة. تحقق من حساب المتجر ثم أعد المحاولة.'**
  String get msg4c0852f71512;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الاشتراك'**
  String get msg44a8a7f9d37d;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اكتملت العملية بنجاح.'**
  String get msg7dc8ed9c9150;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اشتراكك عبر {p0}'**
  String msgb76d8725f4ba(Object p0);

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'متجر آخر'**
  String get msgdcc6ecc738c5;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استخدم المتجر نفسه لإدارة الاشتراك أو استعادته، كي لا تبدأ اشتراكاً ثانياً.'**
  String get msg504dbbfef9df;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حالة الاشتراك'**
  String get msg5c21ea9a3e1c;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل أسعار المتجر…'**
  String get msg3d1fed843fb3;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أكمل العملية في نافذة المتجر'**
  String get msg8031d214cc62;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لن تتفعّل الباقة قبل وصول تأكيد موثّق.'**
  String get msge9b8eda60b87;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ استعادة مشترياتك…'**
  String get msga1c8ad141b06;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'قد يستغرق التحقق لحظات.'**
  String get msg41c0a7f4b3af;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لن تتفعّل الباقة قبل أن يؤكد المتجر الدفعة.'**
  String get msg498e71877132;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل أسعار {p0}'**
  String msg118e790a095e(Object p0);

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحقق من اتصالك وحساب المتجر ثم أعد المحاولة.'**
  String get msg36a2f2d38e17;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أسعار المتجر غير محمّلة'**
  String get msg0d7d7eeb995d;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حمّل الأسعار قبل اختيار الاشتراك.'**
  String get msg86acc2ec62e4;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مختارة'**
  String get msg6311b5052358;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ترقية'**
  String get msgdd4fb886e84d;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تغيير الدورة'**
  String get msg28a847422d0f;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الحالية'**
  String get msg58d0e21f45f8;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'من متجر آخر'**
  String get msg43cde9e0ff7d;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'غير متاحة'**
  String get msgdd79f34f0c70;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متاحة'**
  String get msgbc4f4501a2b6;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متاحة للترقية'**
  String get msg4de775db9e46;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'متاحة لتغيير دورة الفوترة'**
  String get msg14116023a937;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الباقة الحالية'**
  String get msgd4365edd3437;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'غير متاحة لأنها أقل من باقتك الحالية'**
  String get msg6e5bcbfd097d;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'غير متاحة على متجر التطبيقات الحالي'**
  String get msgf193a3d02f59;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'غير متاحة لتعذر التحقق من حالة الاشتراك'**
  String get msgf6da56ccd675;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0}. {p1}، {p2}. {p3} ضمان شهرياً، حتى {p4} للفريق. {p5}. {p6}.'**
  String msgadec648d2e99(
    Object p0,
    Object p1,
    Object p2,
    Object p3,
    Object p4,
    Object p5,
    Object p6,
  );

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} ضمان شهرياً'**
  String msg5a1ec88d684f(Object p0);

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حتى {p0} للفريق'**
  String msg9948c401d46e(Object p0);

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن اختيار باقة أقل أثناء سريان اشتراكك.'**
  String get msg44eaa5508e08;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر إتاحة هذه الباقة بأمان حالياً.'**
  String get msg7888de885f80;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الباقات. أعد المحاولة بعد قليل.'**
  String get msg46b24e9204a8;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الاستعادة…'**
  String get msg87fd032c94fc;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'استعادة المشتريات'**
  String get msg51f37abd4118;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بيانات الحساب'**
  String get msgf65a3a124b56;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لحماية بيانات المتجر، تقتصر هذه الصفحة على إدارة الحساب حتى تفعيل الاشتراك.'**
  String get msgbb3c05a18b00;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تنبيه: حذف حساب ضمانك لا يلغي أي اشتراك قائم أو يوقف الفوترة لدى App Store أو Google Play. ألغِ التجديد من المتجر لتجنب رسوم لاحقة.'**
  String get msg3eb18334c2cc;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يعرض متجر التطبيقات السعر والعملة وموعد التطبيق النهائي قبل التأكيد. يتجدد الاشتراك تلقائياً حتى الإلغاء.'**
  String get msgb2e6b535ba38;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'شروط الاستخدام'**
  String get msg7598879d58a2;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get msg23a13bc51d58;

  /// UI copy: screens/subscription_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح الصفحة. حاول مرة أخرى.'**
  String get msg29ac7d2d6fc6;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'دعوة عضو جديد'**
  String get msg397e16a0e4a3;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اختر الصلاحية مرة واحدة، ثم أرسل الرابط للموظف. سيدخل بحسابه ويؤكد الانضمام.'**
  String get msg114968fff0a7;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الصلاحية'**
  String get msg9f9b2c7c5fa3;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'موظف — البيع والضمان والصيانة'**
  String get msg47b852791fc9;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مدير — إدارة المنتجات والفريق'**
  String get msg37c0e9cb95c1;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الرابط لشخص واحد وينتهي تلقائياً بعد 48 ساعة.'**
  String get msg97ca981f65f9;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إنشاء رابط الدعوة'**
  String get msgc6c9f3a75162;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رابط الدعوة جاهز'**
  String get msgfd86392b6012;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الصلاحية: {p0} • صالح لشخص واحد حتى {p1}/{p2}'**
  String msg7b625955c3da(Object p0, Object p1, Object p2);

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رمز QR لفتح دعوة ضمانك'**
  String get msg0f200a06edcd;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'دعوة فريق ضمانك'**
  String get msgabd2c43949e3;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يفتح الرمز صفحة ضمانك الآمنة التي تعرض رمز الانضمام، ثم يدخله الموظف داخل التطبيق.'**
  String get msgd082aef30638;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الرمز الاحتياطي'**
  String get msg9d11c18a6282;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إرسال الدعوة للموظف'**
  String get msg350cf974d4f7;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'نُسخ رمز الدعوة.'**
  String get msgd3890a3cd356;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'نسخ الرمز فقط'**
  String get msg317f0d073ab6;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'دعوة للعمل في متجر {p0} عبر تطبيق ضمانك.\nالصلاحية: {p1}.\nافتح صفحة الدعوة الآمنة، ثم سجّل الدخول إلى ضمانك باستخدام Apple أو Google وأدخل الرمز الظاهر:\n{p2}\n\nأو افتح ضمانك مباشرة واختر «الانضمام لمتجر» وأدخل الرمز: {p3}\nالدعوة صالحة لشخص واحد ولمدة 48 ساعة.'**
  String msgc9fd72650eae(Object p0, Object p1, Object p2, Object p3);

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'دعوة عضو'**
  String get msgb15038674e73;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أعضاء المتجر'**
  String get msg23da27ce8a42;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} من {p1} مقاعد مستخدمة'**
  String msgc81afcb062a9(Object p0, Object p1);

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'كل شخص يدخل بحسابه؛ يمكن إيقافه دون تغيير كلمة مرور الآخرين.'**
  String get msg29752ccea5d0;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الحساب فعّال'**
  String get msg200cab4b56b2;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عند الإيقاف يفقد العضو الوصول إلى المتجر.'**
  String get msg749800948e90;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حفظ الصلاحيات'**
  String get msgae3c6021608f;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أنت'**
  String get msg85742d892694;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'موقوف'**
  String get msge858894dedb7;

  /// UI copy: screens/team_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تعديل الصلاحيات'**
  String get msg914ac743e9ca;

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بحث سريع'**
  String get msg1812652ef981;

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رقم الجوال أو التسلسلي أو رقم الضمان'**
  String get msg330614ae4275;

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الكل {p0}'**
  String msgbcda95d71da1(Object p0);

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} ضماناً في السجل المحمّل'**
  String msgc79378f26f35(Object p0);

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} نتيجة ضمن {p1} محمّلة'**
  String msg3a30dd12ec9a(Object p0, Object p1);

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'قريب'**
  String get msg027ea1355212;

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم تحميل {p0} ضماناً حتى الآن.'**
  String msg05851e111cba(Object p0);

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم عرض جميع الضمانات ({p0}).'**
  String msg403694008d29(Object p0);

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل المزيد…'**
  String get msgf769bd53e821;

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عرض المزيد'**
  String get msgdbcc30d597f2;

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اعثر على بطاقة العميل وأصدر ضماناً جديداً بسرعة.'**
  String get msg48be88443098;

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة'**
  String get msgee6d68a794bb;

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ضمانات بعد'**
  String get msgabb7c836381f;

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تحقق من الرقم أو اختر حالة أخرى.'**
  String get msg0235e42eca52;

  /// UI copy: screens/warranties_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بإصدار أول ضمان للعميل.'**
  String get msg94bea9dd8ac6;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لم تعد بطاقة الضمان موجودة.'**
  String get msg9edf4b8f634f;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم إصدار الضمان'**
  String get msgc7a6e0fdfb63;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الضمان'**
  String get msgeaf7dd727edb;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حذف الضمان'**
  String get msg0d505fe3d181;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تجهيز الرابط…'**
  String get msgbef58a3f774f;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الضمان'**
  String get msgb884b4ed524c;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إخفاء رمز التحقق'**
  String get msg6a1ac0e46c80;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عرض رمز التحقق'**
  String get msg39b324587aad;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مطالبات الضمان'**
  String get msg0678c3efbff7;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بطاقة ضمان من {p0}\n\nالمنتج: {p1}\nالعميل: {p2}\nرقم الضمان: {p3}\nرقم الإيصال: {p4}\nتاريخ الشراء: {p5}\nصالح حتى: {p6}\nالحالة: {p7}\nالإجمالي: {p8}\nطريقة الدفع: {p9}\n{p10}\n{p11}\n\nاحتفظ بهذه الرسالة للرجوع إليها عند طلب الصيانة.\n'**
  String msg7449b113696b(
    Object p0,
    Object p1,
    Object p2,
    Object p3,
    Object p4,
    Object p5,
    Object p6,
    Object p7,
    Object p8,
    Object p9,
    Object p10,
    Object p11,
  );

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get msgc190381bd30c;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'\nملاحظات: {p0}'**
  String msg36310b3301dc(Object p0);

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'\nتحقق من الضمان واحتفظ بالرابط:\n{p0}'**
  String msg16a4cd7b6137(Object p0);

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بطاقة ضمان {p0}'**
  String msg328999e4edef(Object p0);

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مطالبة ضمان جديدة'**
  String get msg961e982ce839;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ما المشكلة؟'**
  String get msgcabed10e2a69;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مثال: الجهاز لا يعمل بعد التشغيل'**
  String get msg8a9a1bb9e453;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تسجيل المطالبة'**
  String get msg4ff1d76c66f8;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل مطالبة الضمان.'**
  String get msgb10fea1f3532;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حذف بطاقة الضمان؟'**
  String get msgb2dd8fca21fc;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف البطاقة ومطالبات الضمان التابعة لها من سجل المتجر نهائياً.'**
  String get msgc7fffa55b3d8;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'وثيقة ضمان رقمية'**
  String get msga46b81c8cb9b;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'{p0} • إيصال وضمان موحدان'**
  String msg5c2168d73c92(Object p0);

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'المنتج المشمول'**
  String get msg637134e8ceab;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'الباركود'**
  String get msg501881931acd;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الشراء'**
  String get msgdc24afda1b22;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الإيصال'**
  String get msg3aa676d8a2e7;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات وشروط'**
  String get msg90c177abd603;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رمز تحقق بطاقة الضمان {p0}'**
  String msg7229d4c7ae58(Object p0);

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'معاينة محلية'**
  String get msgae8d0843c053;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'رابط تحقق آمن'**
  String get msg132503af2da2;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تظهر روابط التحقق السحابية في مساحة المتجر الحقيقية.'**
  String get msg2dcc255c88be;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يفتح بطاقة عربية موثّقة، مع إخفاء بيانات العميل الحساسة.'**
  String get msg1fd32ccb11f3;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تم إصدار البطاقة ومزامنتها مع مساحة المتجر.'**
  String get msg5a5d5c520635;

  /// UI copy: screens/warranty_detail_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مطالبات ضمان لهذه البطاقة.'**
  String get msg6f250c704cee;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اختر تاريخ الشراء'**
  String get msg02c2c680a701;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اختيار'**
  String get msgfdcd3da079f0;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الرقم التسلسلي مسجل'**
  String get msgf3d8ce2f24b9;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'هذا الرقم مرتبط بالضمان {p0} للعميل {p1}، وصلاحيته حتى {p2}. افتح السجل قبل إصدار ضمان آخر.'**
  String msgfbe60c8a1c91(Object p0, Object p1, Object p2);

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إصدار جديد بعد المراجعة'**
  String get msgd09208df3e07;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'فتح الضمان الحالي'**
  String get msg2d05eb0bfde6;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن إصدار الضمان'**
  String get msgfcc2e8cbb761;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك غير فعّال أو تم استهلاك الحد الشهري. راجع المالك لتجديد الخطة.'**
  String get msgae2412ad9cb6;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'حسناً'**
  String get msgc556786eb169;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'منتج من الكتالوج (اختياري)'**
  String get msga4b471c40b05;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إدخال منتج يدوياً'**
  String get msg7b1c6d8d3456;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'امسحه أو اكتبه يدوياً.'**
  String get msgb916f4141fbc;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الرقم التسلسلي (اختياري)'**
  String get msg0c5cb4277a4e;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'عميل مسجل (اختياري)'**
  String get msgc213f96e206f;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'مدة الضمان'**
  String get msg060541f1a255;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الشراء {p0}'**
  String msg54331bf7051a(Object p0);

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ينتهي الضمان في {p0}'**
  String msge35391812372(Object p0);

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'بيانات العميل'**
  String get msg8d098aea9a44;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات العميل'**
  String get msg110aa6f60385;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'البيع والإيصال'**
  String get msg5e164ebd3d4e;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد فرع مسجل'**
  String get msgfc4fca62af22;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'اتركه فارغاً ليولده النظام تلقائياً.'**
  String get msge7327341464b;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات الضمان'**
  String get msg946923da935e;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الشروط أو الملاحظات'**
  String get msg24d1c2bdd586;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الإصدار…'**
  String get msgcbb92ac69976;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'إصدار الضمان'**
  String get msgd80daaf56343;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'يمكن إضافة تفاصيل البيع والإيصال قبل الإصدار عند الحاجة.'**
  String get msg0df9144ddd76;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريداً صحيحاً'**
  String get msg42b7db3713db;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل مبلغاً صحيحاً'**
  String get msg59786b599b41;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'الخصم أكبر من سعر البيع'**
  String get msg75b9e4c916a2;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ضمان جديد'**
  String get msg6820664c2dce;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'ينتهي في {p0}'**
  String msg9f98738b3ad9(Object p0);

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'3 خطوات'**
  String get msg9b7b146f3ae6;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل اختيارية'**
  String get msg335f3bce69e2;

  /// UI copy: screens/warranty_form_screen.dart
  ///
  /// In ar, this message translates to:
  /// **'البيع والإيصال والبريد والملاحظات'**
  String get msgad8e12d3c133;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'اسم المنتج مطلوب'**
  String get msge88e67ff95f7;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'اسم المنتج أطول من 140 حرفاً'**
  String get msg9f9208e398ce;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'مدة الضمان يجب أن تكون بين 1 و120 شهراً'**
  String get msg01c3eee9c8fe;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'سعر البيع غير صحيح'**
  String get msg2544f3725f52;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'سعر التكلفة غير صحيح'**
  String get msgbe9c2cb8f873;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'سعر البيع سالب'**
  String get msg9f13bc06c709;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'سعر التكلفة سالب'**
  String get msgceea9cb81b41;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'الباركود مكرر داخل الملف'**
  String get msg30d74a964ec1;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'اسمالمنتج'**
  String get msg2554e5e66315;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'الشركة'**
  String get msg9ee7213d2258;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'العلامة'**
  String get msg7e4b853d2722;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'العلامةالتجارية'**
  String get msg271fc9d3d3af;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'رمزالمخزون'**
  String get msg615d221d2f65;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'مدةالضمان'**
  String get msg399591c71051;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'أشهرالضمان'**
  String get msg56c68af7eaf1;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'سعرالبيع'**
  String get msga09cf69e1667;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'سعرالتكلفة'**
  String get msg46cf5f747630;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'التكلفة'**
  String get msg4d5bcf198d93;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'تسلسلي'**
  String get msgdb0dce293888;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'لهرقمتسلسلي'**
  String get msg32b6e8aec6a5;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get msg4b2d2c65d365;

  /// UI copy: services/product_csv_import.dart
  ///
  /// In ar, this message translates to:
  /// **'صح'**
  String get msgb6331eb5c6bb;

  /// UI copy: services/store_billing_service.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر جلب اشتراكات Google Play.'**
  String get msg39e05ec475f1;

  /// UI copy: services/store_billing_service.dart
  ///
  /// In ar, this message translates to:
  /// **'متجر Apple المستخدم للمشتريات هو {p0}، بينما خطط ضمانك متاحة في دول الخليج فقط. غيّر بلد حساب App Store إلى قطر ثم أعد المحاولة. رمز التشخيص: APPLE-STOREFRONT-{p1}.'**
  String msg663f5201a2b5(Object p0, Object p1);

  /// UI copy: services/store_billing_service.dart
  ///
  /// In ar, this message translates to:
  /// **'لم يحدد App Store بلد حساب المشتريات، ولم يُرجع أي خطة. تحقق من تسجيل الدخول إلى الوسائط والمشتريات ثم أعد المحاولة. رمز التشخيص: APPLE-STOREFRONT-UNKNOWN.'**
  String get msg35e6d94ac59f;

  /// UI copy: services/store_billing_service.dart
  ///
  /// In ar, this message translates to:
  /// **'اتصل التطبيق بمتجر Apple في {p0}، لكن المتجر أعاد 0 من 6 خطط. تحقق من حساب الوسائط والمشتريات ثم أعد المحاولة. رمز التشخيص: APPLE-CATALOG-0-{p1}.'**
  String msgb59954ed6b47(Object p0, Object p1);

  /// UI copy: services/store_billing_service.dart
  ///
  /// In ar, this message translates to:
  /// **'تتوفر الاشتراكات داخل تطبيق Android أو iPhone فقط.'**
  String get msg2c9f52cf3f78;

  /// UI copy: services/store_billing_service.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال بـ{p0}.'**
  String msg59869fa52f29(Object p0);

  /// UI copy: services/store_billing_service.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر جلب الأسعار من {p0}. حاول مرة أخرى. رمز المتجر: {p1}.'**
  String msg6a4c814dc5ad(Object p0, Object p1);

  /// UI copy: services/store_billing_service.dart
  ///
  /// In ar, this message translates to:
  /// **'اتصل التطبيق بـGoogle Play، لكن المتجر لم يُرجع أي خطة. رمز التشخيص: GOOGLE-CATALOG-{p0}-{p1}.'**
  String msg237199bb91b5(Object p0, Object p1);

  /// UI copy: services/store_billing_service.dart
  ///
  /// In ar, this message translates to:
  /// **'استغرق {p0} وقتاً طويلاً. تحقق من الاتصال ثم أعد المحاولة.'**
  String msg3fbeae73a3a0(Object p0);

  /// UI copy: services/store_billing_service.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر جلب أسعار App Store.'**
  String get msga782f16b2e97;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق من إيصال متجر سابق. انتظر اكتمال التحقق قبل بدء شراء أو استعادة أخرى.'**
  String get msg4ccb9ea66c6e;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تغيّرت حالة الاشتراك أثناء الفحص. لم نفتح الدفع؛ أعد المحاولة لتأكيد الحالة الجديدة أولاً.'**
  String get msg5db24c7f3adb;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدخول باستخدام {p0}.'**
  String msgb292c8e659da(Object p0);

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'الخطة المجانية مستخدمة لهذا الحساب أو التثبيت. يمكنك الاشتراك في باقة مدفوعة للبدء.'**
  String get msg05d07a095802;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'رابط الدعوة غير مكتمل. اطلب من المدير إرسال دعوة جديدة.'**
  String get msg64c63e0a83c9;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ بيانات المتجر.'**
  String get msge730654afa6b;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ تفضيلات الإشعارات.'**
  String get msg8af71b2d3596;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء المفتاح فوراً.'**
  String get msg47919334a5ec;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث المنتج.'**
  String get msg3e13facbc99c;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تمت أرشفة المنتج.'**
  String get msg40b2aeae01b8;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تمت تسوية المخزون وتسجيل الحركة.'**
  String get msgaf28a10c5f13;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'اكتمل تحويل المخزون بين الفرعين.'**
  String get msg95adf91cf79b;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ البيع وتحديث المخزون والضمان.'**
  String get msgaf6ab5c993fd;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل المرتجع وإعادة الكمية إلى المخزون.'**
  String get msg49acf39c5af1;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم فتح جلسة الصندوق.'**
  String get msgaea2d07966b2;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم إغلاق الصندوق وتثبيت العجز أو الزيادة.'**
  String get msgf2cc84b21c82;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم استلام أمر الشراء وتحديث تكلفة المخزون.'**
  String get msg13940e12cc32;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لم يُرجع المتجر خططاً متاحة لهذا الحساب.'**
  String get msg75e8a8465597;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'استغرق متجر التطبيقات وقتاً طويلاً. تحقق من الاتصال ثم أعد المحاولة.'**
  String get msg488c9aa85534;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'بداية'**
  String get msg50b1963dda2e;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'نمو'**
  String get msg5e7dc4940fc1;

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'توسع'**
  String get msg0e1039754754;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'منتج اشتراك'**
  String get msg48d0e64e87d1;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'شهري وسنوي'**
  String get msg1cbc05c85bbb;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'دورة غير معروفة'**
  String get msgdf24a7d5dad2;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لم يُرجع {p0} المنتجات التالية: {p1}. يمكنك اختيار المنتجات الظاهرة أو إعادة المحاولة.'**
  String msgcf06455e54f0(Object p0, Object p1);

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'إدارة الاشتراك متاحة لمالك المتجر فقط.'**
  String get msgf84fb8e924b8;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'الشراء الحقيقي يحتاج نسخة مرتبطة بقاعدة ضمانك ومنشورة من المتجر.'**
  String get msg65a26bf092ae;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'حدّث أسعار متجر التطبيقات قبل متابعة الاشتراك.'**
  String get msgce385dc19ba7;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تأكيد حالة الاشتراك قبل فتح الدفع…'**
  String get msg4524f31e1fde;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إكمال العملية. تحقق من الاتصال وحاول مرة أخرى.'**
  String get msgc09adaa77529;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر تأكيد حالة الاشتراك الحالية قبل فتح الدفع. لم يبدأ أي اشتراك جديد؛ حاول الاستعادة أو أعد المحاولة لاحقاً.'**
  String get msg77b31f3e6e99;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'هذه الخطة ودورة الفوترة فعّالتان بالفعل.'**
  String get msgd1225fc4dedf;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن الانتقال إلى باقة أقل ما دام اشتراكك الحالي سارياً. يمكنك الترقية أو تغيير دورة الفوترة فقط.'**
  String get msge957d23a6cf8;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'اشتراك المتجر ما زال سارياً عبر {p0}. أدره هناك أولاً لتجنب اشتراكين مدفوعين.'**
  String msg82feabeb713a(Object p0);

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'حالة الاشتراك الحالية غير مكتملة. لم نفتح الدفع؛ استخدم استعادة المشتريات أو أعد المحاولة.'**
  String get msg22824c7dacc9;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'أكمل العملية في نافذة المتجر الآمنة.'**
  String get msg7b2bf94248e1;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'استعادة المشتريات متاحة لمالك المتجر فقط.'**
  String get msg3beb20a2aab2;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'الاستعادة تحتاج نسخة مرتبطة بقاعدة ضمانك ومنشورة من المتجر.'**
  String get msgd60a5e850be2;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك الحالي مرتبط بـ{p0}. نفّذ الاستعادة من جهاز يستخدم المتجر نفسه.'**
  String msg06029de7758e(Object p0);

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ طلب مشترياتك السابقة من المتجر…'**
  String get msg3b7aa14dfab6;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'استغرق طلب App Store وقتاً أطول. ننتظر وصول الإيصال بأمان…'**
  String get msg686b03375ce5;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وجد المتجر دفعة معلّقة. لن تتفعّل الخطة قبل أن يؤكدها المتجر.'**
  String get msga7a34ecc5e0d;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر التحقق من المشتريات السابقة على حساب المتجر الحالي.'**
  String get msg11e7947d7e44;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تمت معالجة دفعة من معاملات App Store القديمة بأمان. اضغط استعادة المشتريات مرة أخرى لإكمال الباقي قبل اختيار الباقة.'**
  String get msg49a5f01c7d29;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تمت معالجة معاملات App Store القديمة، لكن تعذرت الاستعادة الرسمية الحالية. أعد الاستعادة قبل اختيار الباقة.'**
  String get msgd3a212b2e1e4;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم التحقق من دفعة وصلت من App Store، لكن نتيجة طلب الاستعادة لم تكتمل. أعد الاستعادة قبل اختيار الباقة.'**
  String get msg7878cbe97a6c;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تمت استعادة الاشتراك الحالي، لكن تعذر فحص معاملات App Store القديمة. أعد الاستعادة لاحقاً قبل إعادة الشراء.'**
  String get msgdc759962638c;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تمت استعادة الاشتراك والتحقق منه بأمان.'**
  String get msgbdd50efeabd2;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'بقيت {p0} معاملة قديمة. أكملها باستعادة إضافية قبل الشراء.'**
  String msg55d8286c677d(Object p0);

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذرت الاستعادة الرسمية الحالية بعد معالجة المعاملات القديمة. أعد الاستعادة قبل الشراء.'**
  String get msg5909d8aeb31c;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لم تكتمل نتيجة طلب الاستعادة. أعد الاستعادة قبل الشراء.'**
  String get msgec4187fedcc8;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر فحص معاملات App Store القديمة؛ أعد الاستعادة لاحقاً قبل الشراء.'**
  String get msg7ec2fa7dc47f;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تمت معالجة دفعة قديمة غير فعالة، وبقيت {p0} معاملة. أعد استعادة المشتريات قبل اختيار باقة.'**
  String msg62f8ee3e1520(Object p0);

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وجد المتجر اشتراكاً سابقاً غير فعال، وبقيت {p0} معاملة قديمة. أعد الاستعادة قبل الشراء.'**
  String msgc893a5f5f751(Object p0);

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'عولجت المعاملات القديمة غير الفعالة، لكن تعذرت الاستعادة الرسمية الحالية. أعد الاستعادة قبل الشراء.'**
  String get msgc3fdc99d17b7;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تحققت دفعة قديمة غير فعالة، لكن نتيجة الاستعادة لم تكتمل. أعد الاستعادة قبل الشراء.'**
  String get msgec14d7981624;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وجد المتجر اشتراكاً سابقاً غير فعال، وتعذر فحص معاملات App Store القديمة. أعد الاستعادة لاحقاً قبل الشراء.'**
  String get msg5a84584a73b6;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وجد المتجر اشتراكاً سابقاً، لكنه لا يمنح فترة فعّالة الآن.'**
  String get msg25c534abcf44;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لم تكتمل معالجة كل معاملات المتجر بأمان. لا تدفع مرة أخرى؛ أعد استعادة المشتريات بعد قليل.'**
  String get msgf0a1f0e3d840;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لم تكتمل معالجة معاملات المتجر. لا تدفع مرة أخرى؛ أعد الاستعادة بعد قليل.'**
  String get msgcb7d7694ee99;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لم يصل تأكيد من المتجر، ولم تُفعّل أي خطة. استخدم استعادة المشتريات قبل إعادة المحاولة.'**
  String get msg1f1daa8ab5ef;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اشتراك متجري يمكن إدارته حالياً.'**
  String get msg260338c6a854;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح صفحة إدارة الاشتراك في {p0}.'**
  String msg405bdbb0bf5b(Object p0);

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وجد App Store اشتراكاً أو معاملة سابقة لا تطابق اختيارك الحالي. لم يبدأ ضمانك دفعة أخرى؛ استخدم استعادة المشتريات أولاً.'**
  String get msga72d4f8ba807;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'الدفعة معلّقة لدى المتجر. لن تتفعّل الخطة قبل تأكيدها.'**
  String get msgb676bccff47a;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'أُغلقت عملية الشراء من دون تأكيد اشتراك.'**
  String get msgaf27525243d9;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'أُغلقت استعادة المشتريات من المتجر من دون تأكيد اشتراك.'**
  String get msge0e0a6454162;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'أُغلقت الاستعادة من دون تأكيد اشتراك.'**
  String get msg2cb4affe6200;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'سبق التحقق من الاشتراك، لكن تعذر إغلاق معاملة المتجر. لا تدفع مرة أخرى؛ استخدم الاستعادة لإكمالها.'**
  String get msgcd07540fdae2;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'سبق التحقق من هذه العملية بأمان.'**
  String get msg459484d8d148;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق من إيصال المتجر بأمان…'**
  String get msg42a28f3b8385;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم التحقق من الاشتراك، لكن تعذر إغلاق معاملة المتجر. لا تدفع مرة أخرى؛ استخدم الاستعادة لإكمالها.'**
  String get msgf3a434589baf;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تحققنا من العملية، لكنها لا تمنح فترة اشتراك فعّالة الآن.'**
  String get msg1ab79ae4f675;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'قبل المتجر طلب التغيير. ستظهر الخطة الجديدة عند موعد تطبيقها الذي حدده المتجر.'**
  String get msg5dec52b61b7c;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم التحقق من الاشتراك وتحديث حالته من {p0}.'**
  String msg202afabc8bf8(Object p0);

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وصلت الاستعادة وتحققنا من الاشتراك بأمان.'**
  String get msg963d8df0548d;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم التحقق من الاشتراك. جارٍ تهيئة المتجر…'**
  String get msgd01fd47cf961;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم التحقق من الاشتراك، لكن تعذّر تهيئة بيانات المتجر. أغلق التطبيق وافتحه مجدداً؛ لا تدف مرة أخرى.'**
  String get msg2bd0abc799bc;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الاشتراك الحالي من الخادم، لكن تعذر فحص معاملات App Store القديمة. أعد الاستعادة لاحقاً قبل الشراء.'**
  String get msg74cdf2255a3e;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لم يرسل المتجر عملية جديدة، وتم تحديث حالة الاشتراك الحالي من الخادم.'**
  String get msg1c7cbb126c11;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لم نجد اشتراكاً حالياً، وتعذر فحص معاملات App Store القديمة. تحقق من الاتصال ثم أعد الاستعادة.'**
  String get msgaf9570554fa1;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لم نجد مشتريات قابلة للاستعادة على حساب المتجر الحالي.'**
  String get msg552fac577cdc;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وصل تنبيه من متجر التطبيقات، وما زال التحقق من الإيصال جارياً…'**
  String get msg36ea706de06a;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول هذا غير متاح على الجهاز حالياً. تحقق من إعداد الحساب ثم حاول مجدداً.'**
  String get msg51ad7026a9a0;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لم يرسل مزوّد الحساب بيانات الدخول المطلوبة. حاول مجدداً.'**
  String get msg89206bbb6154;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح تسجيل الدخول. تحقق من وجود متصفح آمن وحاول مجدداً.'**
  String get msg21ee318da5ba;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لم يكتمل تسجيل الدخول. حاول مجدداً باستخدام Apple أو Google.'**
  String get msg534beca405ec;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'أُوقفت محاولات الدعوة مؤقتاً للحماية. انتظر 15 دقيقة ثم أعد المحاولة.'**
  String get msgc0bdce351eb5;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'رمز الدعوة غير صحيح أو انتهت صلاحيته.'**
  String get msg1c20a393ae3b;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'استُخدمت الخطة المجانية سابقاً على هذا الحساب أو التثبيت. يمكنك الانضمام إلى متجر بدعوة أو اختيار اشتراك مدفوع.'**
  String get msg4176a6b5c118;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'حدّث ضمانك إلى آخر نسخة لحماية الخطة المجانية ثم حاول مجدداً.'**
  String get msgf6f2d997401d;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذّر ربط الخطة المجانية بهذا التثبيت. حدّث التطبيق ثم حاول مجدداً.'**
  String get msg8ff168a7a7f7;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'انتهت جلسة حماية الخطة المجانية. سجّل الدخول مجدداً ثم حاول.'**
  String get msg732363b4f27b;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وصل المتجر إلى الحد الأقصى لأعضاء الخطة الحالية.'**
  String get msgd70b837f0aa4;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وصل المتجر إلى حد الفروع في الباقة الحالية.'**
  String get msg82042cc010a1;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'هذه الميزة متاحة في باقة توسع فقط.'**
  String get msg2201421b5114;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'الهوية المخصصة متاحة في باقتي نمو وتوسع.'**
  String get msg5b6ea0a549ef;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وصل المتجر إلى حد 5 مفاتيح فعالة. ألغِ مفتاحاً قديماً أولاً.'**
  String get msgb1c20fcf5708;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وصل المتجر إلى حد 5 روابط فعالة.'**
  String get msgafabf1c1b3cc;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'استهلك المتجر مراجعات المطالبات الذكية لهذا الشهر.'**
  String get msg55b20e5b92bf;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'مراجعة المطالبات الذكية غير مشمولة في الباقة الحالية.'**
  String get msg56356812bafc;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'مساعد المطالبات غير مهيأ على الخادم بعد.'**
  String get msg5a7e9f81576b;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم تحليل هذه المطالبة قبل قليل. راجع النتيجة الحالية أولاً.'**
  String get msgd41b12ba7ca2;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'مساعد فرز المطالبة متاح للمالك والمدير فقط.'**
  String get msg89bd3c6d33b3;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك غير فعّال. افتح صفحة الاشتراك لتجديده.'**
  String get msg8e74b1d415c8;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'هذه الخطة غير متاحة في المتجر حالياً.'**
  String get msg133e8106acc5;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لم يفتح المتجر نافذة الشراء. تحقق من حساب المتجر وحاول مجدداً.'**
  String get msgb8196f18dc4b;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'توجد عملية شراء مفتوحة بالفعل. أكملها أو أغلق نافذة المتجر أولاً.'**
  String get msg88b5abd43d62;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر تأكيد اشتراك Google Play الحالي. لم يبدأ ضمانك اشتراكاً جديداً؛ تحقق من الاتصال ثم حاول مجدداً.'**
  String get msg3f2b09693f65;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وجد App Store اشتراك ضمانك فعالاً، بينما لا توجد حالة مرتبطة بهذا المتجر. لم نفتح الدفع؛ استخدم استعادة المشتريات لربطه بأمان.'**
  String get msg8740c31b1085;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'اشتراك هذا المتجر مرتبط بحساب App Store آخر. لم نفتح الدفع لتجنب اشتراكين؛ سجّل الدخول إلى حساب الوسائط والمشتريات الذي اشتركت منه ثم أعد المحاولة.'**
  String get msg497506966234;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تغيّرت حالة اشتراك App Store أو تعذر مطابقتها بأمان. لم نفتح الدفع؛ حدّث الحالة ثم أعد المحاولة.'**
  String get msg23134a1f6e0a;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر التأكد من اشتراكات App Store الحالية. لم نفتح الدفع لتجنب عملية مكررة؛ تحقق من الاتصال ثم استخدم الاستعادة أو أعد المحاولة.'**
  String get msg08998bec9ea2;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وجد Google Play اشتراك ضمانك لحساب آخر. استخدم حساب ضمانك الأصلي أو غيّر حساب Google Play.'**
  String get msg18e3de3a4379;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'هذا اشتراك Google Play مرتبط بمتجر ضمانك آخر، ولا يمكن نقله تلقائياً.'**
  String get msgb7c7f12d04bc;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'توجد دفعة Google Play معلّقة. انتظر قرار المتجر قبل بدء تغيير آخر.'**
  String get msg57a9ffe13772;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'ألغى Google Play العملية المعلّقة ولم تتغير خطتك. استخدم استعادة المشتريات لتحديث الاشتراك الحالي.'**
  String get msg1b35d7318262;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'ما زالت العملية معلّقة لدى المتجر. لم تتغير خطتك؛ انتظر تأكيد المتجر ثم استخدم الاستعادة.'**
  String get msga3a36c0c8905;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وجد Google Play أكثر من اشتراك ضمانك على الحساب نفسه. أوقف الاشتراك الزائد من Google Play ثم استخدم الاستعادة.'**
  String get msg5c071f19eceb;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لم يعثر Google Play على الاشتراك الحالي المطلوب تغييره. تأكد من حساب المتجر ثم استخدم الاستعادة.'**
  String get msg485453a5253d;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وجد Google Play اشتراكاً لهذا المتجر لم يكتمل ربطه بعد. لم يبدأ شراء جديد؛ استخدم استعادة المشتريات أولاً.'**
  String get msg0abd4d138642;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديد انتقال الاشتراك بأمان. حدّث حالة الاشتراك ثم حاول مجدداً.'**
  String get msg0f9159687399;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'هذه المشتريات مرتبطة بحساب ضمانك آخر. سجّل الدخول إلى الحساب الأصلي ثم استخدم الاستعادة.'**
  String get msgb22088a4f341;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'هذا الاشتراك مرتبط بمتجر ضمانك آخر، ولا يمكن نقله تلقائياً لحماية الفوترة.'**
  String get msg9621dac148dd;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'يوجد اشتراك سارٍ عبر متجر آخر. أوقف تجديده هناك أولاً لتجنب فوترة مزدوجة.'**
  String get msg4bc0d4bf4340;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر تأكيد الاشتراك الحالي قبل تغييره. لم يبدأ ضمانك اشتراكاً جديداً؛ تحقق من حساب المتجر ثم حاول مجدداً.'**
  String get msg1717fee372a8;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'وجد App Store معاملة سابقة غير منتهية لهذه الباقة. لا تدفع مرة أخرى؛ اضغط استعادة المشتريات، وانتظر نتيجتها، ثم أعد اختيار الباقة.'**
  String get msg14edf63d327d;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تكررت محاولات التحقق خلال وقت قصير. انتظر قليلاً ثم استخدم الاستعادة مرة واحدة.'**
  String get msg8de88db9ee80;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'هذه المشتريات مرتبطة مسبقاً بحساب أو متجر ضمانك آخر، ولا يمكن نقلها تلقائياً.'**
  String get msgfd5b75e28928;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك ما زال مرتبطاً بحساب أو متجر ضمانك قائم، لذلك لا يمكن نقله إلى هذا المتجر.'**
  String get msg79ac2967b27b;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر إثبات أن عملية المتجر تخص الاشتراك القديم لهذا الحساب. تحقق من حساب المتجر ثم حاول الاستعادة مجدداً.'**
  String get msgc3408e58256d;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لم يؤكد المتجر صلاحية هذه العملية. راجع حساب المتجر ثم استخدم الاستعادة.'**
  String get msg3561a3bc9f40;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'الشراء التجريبي غير مفعّل لهذا الحساب أو انتهت صلاحية اختباره. تواصل مع دعم ضمانك لتفعيل الاختبار؛ تكرار الشراء أو الاستعادة لن يحل المشكلة.'**
  String get msg8bd189e789ce;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'خدمة التحقق لدى المتجر غير متاحة مؤقتاً. الدفع محفوظ؛ لا تكرر الشراء واستخدم الاستعادة لاحقاً.'**
  String get msge29791144d8a;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال بمتجر التطبيقات. تحقق من الاتصال وحساب المتجر ثم حاول مجدداً.'**
  String get msg72f40922290e;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'متجر التطبيقات غير متاح على هذا الجهاز حالياً.'**
  String get msgc5492f0f3103;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'الدفع محفوظ لدى المتجر، لكن التحقق لم يكتمل بعد. لا تدفع مرة أخرى؛ استخدم استعادة المشتريات لإكمال التفعيل.'**
  String get msg5f9d802288f7;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن ربط الاشتراك إلا من حساب مالك المتجر.'**
  String get msg84f3c094233d;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'استهلك المتجر حد الضمانات الشهري للخطة.'**
  String get msgc83736e914ba;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تجهيز رابط التحقق من الضمان. حاول مرة أخرى بعد لحظات.'**
  String get msg95729322e879;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'حدّث موظف آخر هذه المطالبة. أعد تحميلها قبل حفظ تعديلك.'**
  String get msgbc157e056e42;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'هذا القرار يحتاج إلى حساب المالك أو المدير.'**
  String get msg3604d6a031c5;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'اكتب سبب القرار قبل رفض المطالبة.'**
  String get msge4a5d764af5c;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن نقل المطالبة مباشرةً إلى هذه الحالة.'**
  String get msgcbc7e8cc2112;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'اختر موظفاً نشطاً من فريق المتجر.'**
  String get msg18c3c1406e45;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'استهلك المتجر تحليلات ملفات المنتجات لهذا الشهر.'**
  String get msg992db24ae82c;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف تحليل الملفات مؤقتاً لحماية الحساب من الاستخدام غير المعتاد.'**
  String get msga6474afe3344;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تحليل ملفات المنتجات غير مشمول في الباقة الحالية؛ استخدم CSV.'**
  String get msg13af577f5d75;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'خدمة تحليل ملفات المنتجات غير مهيأة على الخادم بعد.'**
  String get msg77e9970c6a52;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'استيراد المستندات متاح للمالك أو المدير فقط.'**
  String get msgc7c75d16290c;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحليل المستند. جرّب ملفاً أوضح أو استخدم CSV.'**
  String get msgfe4f54cd50b0;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحليل المطالبة الآن. راجعها يدوياً أو حاول لاحقاً.'**
  String get msg2f16f149311d;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح ملف المطالبة. تحقق من الاتصال وحاول مرة أخرى.'**
  String get msg1886b45876c2;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'الكمية المطلوبة أكبر من الرصيد المتاح في هذا الفرع.'**
  String get msg53505472310f;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقماً تسلسلياً مستقلاً لكل قطعة.'**
  String get msg0690a9995083;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'مجموع الدفعات لا يساوي إجمالي الإيصال.'**
  String get msgf498d14b8f23;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'يوجد صندوق مفتوح لهذا الفرع بالفعل.'**
  String get msg74b570f53944;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'كمية المرتجع غير صحيحة أو سبق إرجاعها.'**
  String get msg2d62a9f077b2;

  /// UI copy: state/app_controller.dart
  ///
  /// In ar, this message translates to:
  /// **'هذه القيمة مسجلة مسبقاً؛ تحقق من الباركود أو الرمز.'**
  String get msg850bb718dd93;

  /// UI copy: widgets/brand_mark.dart
  ///
  /// In ar, this message translates to:
  /// **'شعار ضمانك'**
  String get msg9006a6624319;

  /// UI copy: widgets/brand_mark.dart
  ///
  /// In ar, this message translates to:
  /// **'ضمانك'**
  String get msg407efcb53149;

  /// UI copy: widgets/brand_mark.dart
  ///
  /// In ar, this message translates to:
  /// **'ثقة موثّقة، خدمة أسهل'**
  String get msg8161e244246e;

  /// UI copy: widgets/warranty_card.dart
  ///
  /// In ar, this message translates to:
  /// **'ضمان {p0} للعميل {p1}'**
  String msgcb8b766ae349(Object p0, Object p1);

  /// UI copy: widgets/warranty_card.dart
  ///
  /// In ar, this message translates to:
  /// **'حتى {p0}'**
  String msg97e6291e54eb(Object p0);

  /// UI copy: models/subscription.dart
  ///
  /// In ar, this message translates to:
  /// **'خطة مجانية'**
  String get msgce66eb05d98d;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'ja',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
