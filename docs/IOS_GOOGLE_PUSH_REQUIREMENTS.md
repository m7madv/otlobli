# iOS Google Sign-In and Push Requirements

## الوضع الحالي

- Bundle ID: `com.otlobli.app`.
- كود Google وPush وإضافاتهما موجودة.
- `VITE_GOOGLE_IOS_CLIENT_ID` غير موجود في GitHub Secrets، ولذلك يخفي التطبيق زر Google على iOS عمداً.
- نسخة iOS الحالية unsigned ولا تحتوي `GIDClientID`.
- لا يوجد ملف `.entitlements` في مشروع iOS يحتوي `aps-environment`.
- الخادم يحتوي إعداد FCM الخاص بـAndroid، لكنه لا يحتوي حالياً أسرار `APNS_KEY`, `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_BUNDLE_ID`.
- ظهور نافذة السماح بالإشعارات يعني أن المستخدم سمح بعرضها فقط؛ لا يثبت نجاح التسجيل مع APNs أو وجود مسار إرسال.

## Google على iPhone

إنشاء Google OAuth ليس جزءاً من اشتراك Apple المدفوع بحد ذاته. المطلوب:

1. الوصول إلى مشروع Google Cloud/Firebase المستخدم للتطبيق.
2. إنشاء OAuth Client من نوع iOS مرتبط بـ`com.otlobli.app`.
3. إضافة Client ID إلى `VITE_GOOGLE_IOS_CLIENT_ID`.
4. إضافة `GIDClientID` وURL scheme المعكوس إلى `Info.plist`؛ workflow الحالي مجهز لذلك.
5. الاحتفاظ بـWeb OAuth client المستخدم لإصدار ID token للخادم.
6. توقيع التطبيق بشهادة Apple صالحة ليعمل كتطبيق iOS طبيعي ويحفظ بيانات الاعتماد في Keychain.

إذن: حساب Apple المدفوع ليس ما ينشئ Google Client ID، لكن توقيع Apple مطلوب لنسخة جهاز/توزيع سليمة. لا يكفي حساب Apple وحده؛ نحتاج أيضاً صلاحية Google Cloud.

## إشعارات iPhone

لإشعارات remote push الحقيقية، عضوية Apple Developer Program الفعالة مطلوبة عملياً لهذا المشروع:

1. تسجيل App ID مطابق لـ`com.otlobli.app`.
2. تفعيل Push Notifications capability.
3. إضافة entitlement باسم `aps-environment`.
4. إنشاء provisioning profile جديد يحتوي capability.
5. توقيع IPA بالشهادة والـprofile الصحيحين.
6. إنشاء APNs Authentication Key بصيغة `.p8` من حساب Apple.
7. حفظ القيم التالية كأسرار خادم:
   - `APNS_KEY`: محتوى ملف p8.
   - `APNS_KEY_ID`.
   - `APNS_TEAM_ID`.
   - `APNS_BUNDLE_ID=com.otlobli.app`.
   - `APNS_PRODUCTION` حسب نوع التوقيع.
8. تثبيت النسخة الموقعة، السماح بالإشعارات، والتأكد أن callback التسجيل أعاد device token وتم حفظه في `device_tokens`.
9. إرسال اختبار من لوحة الإدارة والتحقق من استجابة APNs ومن ظهور الإشعار والجهاز مغلق والتطبيق بالخلفية.

مهم: token بيئة sandbox لا يعمل على بوابة production والعكس؛ `aps-environment` والـprovisioning و`APNS_PRODUCTION` يجب أن تتطابق.

## ما أحتاجه من المالك

لا ترسل كلمة مرور Apple أو رمز 2FA داخل المحادثة. عند توفر العضوية:

- سجّل الدخول محلياً إلى Apple Developer/Xcode، أو امنح وصولاً مناسباً عبر فريق Apple إن كان الحساب مؤسسة.
- وافق بنفسك على أي اتفاقيات Apple معلقة.
- وفّر بطريقة آمنة شهادة/ملف provisioning للتوقيع أو جهّز signing داخل Xcode/GitHub.
- أنشئ APNs key مرة واحدة واحتفظ بنسخة آمنة؛ Apple قد لا تسمح بتنزيل ملف p8 نفسه مرة ثانية.
- سجّل الدخول إلى Google Cloud لإنشاء iOS OAuth client.

بعدها يمكن إكمال الربط، وضع الأسرار في GitHub/Supabase، بناء IPA موقعة، ثم تنفيذ اختبار Google وPush على iPhone حقيقي.
