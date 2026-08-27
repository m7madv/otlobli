# v86.244/1110 — إغلاق «تسجيل لاحقًا» عند تغيّر غلاف SHEIN (2026-08-27)

اعمل فقط داخل
`C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` على الفرع
`codex/otlobli-v86-212-testflight-auth`. رقم النسخة الظاهر بقي `86.244`،
ورقم البناء الجديد هو `1110` لأن Apple لا تسمح باستبدال البناء `1109` بعد
رفعه.

الفحص فصل حالتين. صفحة `/ar/user/login` الكاملة لا تحتوي زر «لاحقًا»،
وتبقى معالجتها هي رجوع Native الموجود في بناء `1109`. أما نافذة SHEIN
الاختيارية فكان التقاط زرها الفوري محصورًا في الغلاف القديم
`.s_auth__block-login-tip`؛ تغيير SHEIN لاسم الغلاف كان يستطيع إبقاء النافذة
حتى fallback الأبطأ. صار مراقب السياسة الوحيد يعيد استعمال قائمة
`candidateSelector` التي يجمعها أصلًا، ويفحص الجذر وآخر `16` مرشحًا بحثًا عن
نص «تسجيل لاحقًا» المطابق تمامًا. الغلاف القديم بقي احتياطًا محدودًا. لا
يوجد selector عام جديد على الوثيقة، ولا observer أو interval أو WebView أو
reload أو lifecycle hook جديد. التحقق البشري يخرج قبل الفحص، ولا يُنقر
«تسجيل الدخول» أو نص غير دقيق أو حقل نموذج.

حُدث fallback الموجود فقط ليفهم الصيغ العربية
«تسجيل/التسجيل (الدخول) لاحقًا» و`Login Later` مع بقاء نطاقه وتوقيته السابقين.
ويتشارك المساران الآن علامتي `action/fired` قبل النقرة؛ لذلك سواء سبق مراقب
السياسة أم fallback يبقى مجموع النقرات واحدة فقط، مع إزالة العلامتين إذا
رمت `.click()` استثناءً.
بقيت حرفيًا `otlobliForceRecompose()`، مهلة `appDidBecomeActive` ذات
`0.25s`، استعادة scroll/constraints، دفاع Android
`otlobliOnHostResume()`، ومقارنة المناطق عبر `JSON.stringify`. لم تتغير
المنطقة أو cookies/session أو التحقق أو Temu أو الدفع أو الطلبات أو المحفظة.

نجح حارس SHEIN بfixture يثبت الغلاف غير المعروف، الظهور بعد mutation، التأجيل
حتى runtime، النقرة الواحدة، رفض النص غير الدقيق، وعدم النقر أثناء challenge،
مع observer واحد وصفر استعلامات generic إضافية على document root. نجح
`npm run build` وكل الحواجز والمزامنة للمنصتين من دون رفع ميزانية: startup
`673,159/720,000`، JS gzip `300,476/370,000`، CSS `69,989/70,000`،
نصوص المتاجر `318,372/470,000`، Temu Gecko `172,513/180,000`، ومصدر
المتاجر `582,181/600,000`.

بُني Android Release وثُبت كتحديث يحفظ البيانات على Note 8. الجهاز يؤكد
`86.244 (1110)` ومهلة الشاشة `120000ms`؛ فتح SHEIN Home ثم قائمة ومنتجًا
حيًا، ولم يظهر fatal/ANR/OOM مطابق. الجلسة المحفوظة لم تعرض نافذة الدخول،
لذلك هذا smoke test وليس قبولًا لمسار «تسجيل لاحقًا» أو iPhone.

- APK: `artifacts/release-86.244/Otlobli-86.244-1110-release.apk` —
  `4,112,739` بايت، SHA-256
  `DAF3A6D0BD3ADAE41873CCD4D425D9134F265BA68018CFCFCC1B32A1FA8956BC`.
- AAB: `artifacts/release-86.244/Otlobli-86.244-1110-release.aab` —
  `5,773,866` بايت، SHA-256
  `6BBF28ACFC24D96D491160719E0D392EB388BD5B20BE14C872E178EB4E322C95`.

أكد App Store Connect بالقراءة المباشرة أن الإصدار العام الوحيد
`86.230 (1095)` هو `REJECTED` وطلبه `UNRESOLVED_ISSUES`. البناء
`86.244 (1109)` سليم `VALID` و`APP_STORE_ELIGIBLE` و`IN_BETA_TESTING` لكنه
غير مربوط بأي App Store Version ولم يدخل المراجعة؛ خطوة الإرسال في GitHub
كانت skipped. نص سبب الرفض لا توفره API الرسمية ويجب قراءته من
`App Review Issues & Messages`. لا تُشغّل الإرسال العام قبل قراءته؛ السكربت
الحالي لا يعيد استعمال سجل بحالة `REJECTED` بأمان. بناء `1110` لم يُرفع إلى
TestFlight بعد، وقبول iPhone الحقيقي وخمس دورات الخلفية/العودة والتشغيل البارد
ما زالت مطلوبة.

قبل رفع `1110` كانت جلسة WhatsApp `0` في حالة `error` ذاكرية مع اعتماد محفوظ،
`riskScore=0`، ومن دون QR فعلي. أعاد تشغيل `otlobli-wa` الحالة إلى `idle`،
ثم أعاد طلب محمي واحد الاتصال من الاعتماد نفسه. الصحة النهائية تؤكد
`whatsappConnected=true` و`whatsappSenderReady=true` و
`sessionStoreReady=true` و`otpSecurityReady=true`؛ لم تُحذف جلسة ولم يُمسح
QR ولم تُرسل رسالة أو OTP اختباري.

# v86.244/1109 — مغادرة صفحة دخول SHEIN الكاملة ومنع OAuth الخارجي (2026-08-26)

تابع فقط داخل
`C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` على الفرع
`codex/otlobli-v86-212-testflight-auth`. الإصداران القياسيان Android وiOS هما
`86.244 (1109)`. لم تُرسل هذه الدفعة إلى App Review.

الصورة وتجربة الصفحة الحية أثبتتا أن الواجهة المبلغ عنها هي صفحة SHEIN
الكاملة `/ar/user/login`، وليست نافذة `.s_auth__block-login-tip` ذات زر
«تسجيل لاحقًا». كان المسار مصنفًا أصلًا `blocked-login` وتمنعه قرارات التنقل
الشبكية، لكن انتقال SHEIN الداخلي عبر History API يغيّر URL من دون المرور
بـ`WKNavigationDelegate` أو `shouldOverrideUrlLoading`. لذلك كان iOS يحفظ
المسار عبر مراقب URL، وكان Android يمرره عبر `doUpdateVisitedHistory`، ثم
أتاح popup الخاص بـFacebook الخروج إلى Safari.

الإصلاح لا يصلح Google أو Facebook ولا يمس DOM. عند وصول إشعار URL الموجود
أصلًا إلى أي مسار محجوب، ينفذ المتصفح الأصلي رجوعًا واحدًا. إذا أعاد SHEIN
صفحة الدخول بعد الرجوع، يفحص العنوان مرة واحدة بعد `200ms` ويعود إلى Home؛
وإذا لم يوجد سجل رجوع يذهب إلى Home مباشرة. وأي رابط أو نافذة منبثقة صادرة
من صفحة الدخول تُلغى قبل فتح Safari/تطبيق خارجي. المسار
نفسه مطبق في iOS المخصص وAndroid Capgo، والرقعة الدائمة تقبلها حزمة npm
نظيفة. لا يوجد observer أو interval أو DOM scan أو reload/WebView جديدة،
والفحص الاحتياطي مؤقت أحادي محدود لا يعمل إلا عند وقوع المسار المحجوب.

لم تتغير SHEIN region/cookies/session أو التحقق البشري أو الدفع أو الطلبات أو
المحفظة أو Temu. بقيت حرفيًا `otlobliForceRecompose()`، مهلة
`appDidBecomeActive` ذات `0.25s`، استعادة scroll/constraints، دفاع Android
`otlobliOnHostResume()`، ومقارنة المنطقة عبر `JSON.stringify`.

نجح `npm ci` وتطبيق الرقعة من الصفر، واختبارات route والخدمات، وحارس تجمد
SHEIN، وحارس سطح المتجر، ومسح الأسرار، والبناء والمزامنة للمنصتين. لم تُرفع
ميزانية: startup `673,159/720,000`، إجمالي JS gzip `300,219/370,000`، CSS
`69,989/70,000`، نصوص المتاجر `318,044/470,000`، Temu Gecko
`172,513/180,000`، ومصدر المتاجر `581,616/600,000`.

بُني Android Release الموقّع وثُبت كتحديث يحفظ البيانات على Note 8. الجهاز
يؤكد `86.244 (1109)` ومهلة الشاشة `120000ms`، وأقلع التطبيق من دون
fatal/ANR/OOM مطابق. هذا لا يثبت صفحة الدخول على iPhone أو دورة lifecycle.

قبل TestFlight أعادت صحة الهاتف `status=ok` لكن جلسة WhatsApp `0` كانت
`error` بعد انقطاع قديم، مع `riskScore=0` ومن دون QR أو إيقاف. لم يُرسل طلب
إعادة اتصال في تلك الحالة. أُعيد تشغيل عملية `otlobli-wa` فقط لإزالة الحالة
الذاكرية، ثم أثبت الفحص `idle/connected=false/qrAvailable=false` واعتمادات
سليمة؛ أُرسل POST محمي واحد إلى `/api/whatsapp/sessions/0/reconnect`. النتيجة
النهائية `connected=true` و`whatsappConnected=true` و
`whatsappSenderReady=true`، بلا حذف جلسة أو QR أو OTP تجريبي.

- APK: `artifacts/release-86.244/Otlobli-86.244-1109-release.apk` —
  `4,112,470` بايت، SHA-256
  `917605B307DC5A32FF10430181965EE686FEDBEBB36F0EF7B817F0EAAE1820CB`.
- AAB: `artifacts/release-86.244/Otlobli-86.244-1109-release.aab` —
  `5,773,596` بايت، SHA-256
  `15D0DE97BA2F75E319188BB2412B550178EB61756995432377C25FC270DFDE89`.

التزام الإصدار `28ea4518d6bd47575fd594d4020c460649876b31` مدفوع. نجح مسار
[GitHub 32988536909](https://github.com/m7madv/otlobli/actions/runs/32988536909)
وبنى ورفع `otlobli-v86.244-build-1109-testflight.ipa`: الحجم
`10,551,296` بايت، SHA-256
`E40902F61230CDE3D279C9A1281AF56DB5445D705513F4CB4B157C05D0382ED1`،
وDelivery UUID `25645ee5-2f2e-4e68-8f09-d6161e4fc7de`. تحقق App Store
Connect أن البناء `VALID` وحالته `IN_BETA_TESTING` ومتاح لمجموعة
`Otlobli Internal`، وحالة المختبِر المتوقع `INSTALLED`. أثر GitHub رقم
`9614099128` وحجمه `25,260,142` بايت وبصمة ZIP
`A3178BA4B5076A691DE9CBBA5084D1B915A20F15D6586693460BB92579442E19`.
خطوة App Review بقيت معطلة ولم تُنفذ.

يلزم الآن على iPhone 16 Pro Max فتح أول منتج من جلسة غير مسجلة، والتأكد أن
صفحة الدخول لا تبقى وأن Google/Facebook لا يخرجان من التطبيق، ثم خمس دورات
background/resume واختبار force-quit/cold-launch مستقل. لا يُدعى قبول الجهاز
من CI أو Note 8.

# v86.243/1108 — استئناف SHEIN بعد التحقق وروابط المجموعة المباشرة (2026-08-26)

تابع فقط داخل
`C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` على الفرع
`codex/otlobli-v86-212-testflight-auth`. الإصداران القياسيان Android وiOS هما
`86.243 (1108)`. مصدر التطبيق هو
`a962b0d2553925f0ae6a1fb38883a4e204a2a174`، وتصحيحات مسار التوقيع التي
بنت نسخة TestFlight تنتهي عند
`142eacd1ddf9cfe27c221110274cd961c3b3b80c`. جميعها مدفوعة.

أكدت تجربة المستخدم التشخيص: بعد التحقق البشري الأول بقيت SHEIN في حالة
واجهة قديمة وغير قابلة للتمرير، ثم أدى الدخول إلى Temu والرجوع إلى SHEIN إلى
عملها الكامل. لذلك لم يُضف reload أو WebView جديدة؛ بعد إثبات اختفاء التحقق
بـ`1200ms` ثم تسوية `600ms` يستأنف التطبيق مرة واحدة سياسة SHEIN ثم توافق
الخصوصية. «تسجيل لاحقًا» لا يُنقر إلا داخل
`.s_auth__block-login-tip` وبمطابقة النص الدقيق، و«قبول الكل» لا يُنقر إلا
داخل غلاف الخصوصية المؤكد وبحد أقصى `160` عنصرًا. لا يوجد
`setInterval` أو `MutationObserver` جديد للخصوصية أو مسح DOM واسع، ولا يلمس
التطبيق التحقق البشري أو يحله. بقيت المنطقة والجلسات وملفات تعريف الارتباط
والدفع والطلبات والمحفظة خارج التغيير.

أصبحت دعوة «اطلب مع صديق» رابطًا نظاميًا مباشرًا مع بقاء الانضمام صريحًا
وشخصين فقط. نُشرت ملفات Android App Links وiOS Universal Links على
`https://talabieh.vercel.app` عبر Vercel deployment
`dpl_4iZnSZqiDgMN3EtVQkzpSoYoRGND`. ملف الأصل وApple CDN يعيدان الآن
`200 application/json` للمسارين `/group` و`/group/*` وللتطبيق
`36D743K87T.com.otlobli.app`. Android على Note 8 يسجل الدومين بالحالة
`always : 200000000`، وGoogle Digital Asset Links يقر بصحة البيان. صفحة
الاحتياط لا تشغّل scheme تلقائيًا؛ زر الفتح اليدوي باقٍ. لم تُنفذ نقرة رابط
حقيقية على iPhone بعد، لذلك لا يُدعى قبول Universal Link فعلي على الجهاز.

نجح `npm run build` وTypeScript واختبار المجموعة وحارس تجمد SHEIN وحارس سطح
المتجر ومسح الأسرار ومزامنة Android وiOS. لم تُرفع أي ميزانية. القياس المحلي:
startup JS `673,159/720,000`، إجمالي JS gzip `300,217/370,000`، CSS
`69,989/70,000`، نصوص المتاجر `318,044/470,000`، Temu Gecko
`172,513/180,000`، ومصدر المتاجر `581,616/600,000`. قياس TestFlight:
startup `673,350`، gzip `300,262`، وCSS `69,989` ضمن الحدود نفسها.

بُني Android Release مع R8 وثُبت فوق البيانات الموجودة على Samsung Note 8.
الجهاز يؤكد `86.243 (1108)` ومهلة الشاشة `120000ms`. بقيت عدادات السلال
محفوظة، وظهرت SHEIN بعد نحو `25s` ثم تغيّر المحتوى بعد تمريرة، ما يثبت أن
الصفحة قابلة للتمرير في هذه الجلسة، بلا fatal/ANR/OOM مطابق. الأدلة في
`artifacts/device-captures/v86.243-note8/`. لأن الجهاز احتفظ ببياناته، فهذا
ليس اختبار تثبيت نظيف لحوار cookies/login، وليس قبولًا لجهاز A52 أو iPhone.

- APK: `artifacts/release-86.243/Otlobli-86.243-1108-release.apk` —
  `4,112,457` بايت، SHA-256
  `D8AC90063B7CD15C95A0278BA9369A160BC9ADA5DF316356C74F9450E164AFF3`،
  توقيع APK v2/v3، `minSdk 24` و`targetSdk 36`.
- AAB: `artifacts/release-86.243/Otlobli-86.243-1108-release.aab` —
  `5,772,733` بايت، SHA-256
  `CD7AB051E00C2535BBF8A4763A237ACC262C1FFEA8992D8C831D323D14AB4B13`.

توقف تشغيل `32950592504` أولًا قبل التوقيع لأن مرسل WhatsApp كان خاملًا.
كانت الجلسة `0` محفوظة، بلا QR أو إيقاف أو نقاط خطر، فأعيد وصلها مرة واحدة
عبر endpoint Oracle المحلي المحمي؛ لم تُحذف أو تُنشأ جلسة ولم تُرسل رسالة.
المحاولة الثانية أثبتت أن Bundle ID مسجل في Apple كـ`UNIVERSAL`. تشغيل
`32951612789` فعّل `ASSOCIATED_DOMAINS` وأنشأ ملف التزويد، ثم رفضه الحارس
بسبب افتراض محلي خاطئ أن تفويض ملف Apple قائمة؛ التفويض الصحيح في profile هو
`*` بينما استحقاق التطبيق نفسه قائمة دقيقة. صُححت المطابقة بلا حذف شهادة أو
Profile، وبقي فحص IPA النهائي يطلب حرفيًا
`["applinks:talabieh.vercel.app"]`.

نجح [تشغيل TestFlight `32952198744`](https://github.com/m7madv/otlobli/actions/runs/32952198744)
في `7m56s`. أعاد استخدام Profile
`053cb721-6618-48ae-8d16-1c6ba86feed5`، وتحقق من توقيع IPA واستحقاق الدومين
الدقيق. Delivery UUID هو `4ea11eda-a514-4c24-a05a-8b39d04c646c`.
البناء `86.243 (1108)` هو `VALID` و`IN_BETA_TESTING` في مجموعة all-builds
`Otlobli Internal`، وحالة المختبر المتوقعة `INSTALLED`. IPA حجمها
`10,546,318` بايت وSHA-256
`5637399386858365D318C40FFE6F4000815553556BB093CB884E67A38CDB11A5`.
Artifact GitHub رقم `9600827192`، اسمه
`otlobli-ios-v86.243-build-1108-testflight`، حجمه `25,253,256` بايت وdigest
`sha256:a509dd9fa5fef6be5ad1ae2dd1a0e6a7de0965671853799d5581e3cbe493183a`.
لم يُرسل البناء إلى App Review. لا يُدعى قبول iPhone الحقيقي؛ يلزم اختبار
حوار SHEIN الأول، رابط WhatsApp المباشر، خمس دورات background/resume، ثم
force-quit/cold-launch مستقل.

# v86.242/1107 — إزالة شريط iOS الفارغ فوق منتج Temu (2026-08-26)

تابع فقط داخل
`C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` على الفرع
`codex/otlobli-v86-212-testflight-auth`. الإصداران القياسيان Android وiOS هما
`86.242 (1107)`. التزام المصدر `e46dbf9ab01dc594942501f0ba3ac223c3a9c373`
مدفوع، ونجح مسار TestFlight الداخلي `32923259010` في `8m6s`. لا يوجد إرسال
إلى App Review في هذه الدفعة.

أثبت قياس لقطة iPhone 16 Pro Max أن الفراغ ليس من Temu DOM ولا من safe area:
ينتهي شريط الحالة عند `y=132`، ثم يظهر أبيض خالص حتى `y=295` وفاصل أصلي عند
`y=296..298`. الارتفاع المحوّل يقارب `75pt`، أي ارتفاع `UINavigationBar`
الفارغ. كان Capgo يخفي الشريط عند `ToolBarType.BLANK` ثم يعيد `setUpState()`
إظهاره وبحركة عند `viewWillAppear`. صار `setUpState()` يخفي الشريط عندما
`blankNavigationTab=true`، ويحافظ على السلوك السابق للأنماط الأخرى. لم تتغير
قيود WebView أو safe area أو DOM/CSS أو أي مؤقت/مراقب/مسح.

مسار SHEIN المنفصل لم يتغير، وبقيت حرفيًا حماية
`otlobliForceRecompose()` وتأخير `appDidBecomeActive` البالغ `0.25s` ودفاع
Android resume ومقارنة المناطق عبر `JSON.stringify`. لم تتغير المنطقة أو
الجلسات أو التحقق البشري أو الدفع أو الطلبات أو المحفظة. أضيف حارس ثابت يفشل
إذا أعادت ترقية Capgo سطر إظهار شريط `BLANK` القديم.

نجح البناء الكامل و`verify:shein-freeze-guard` و`verify:store-surface` وكل
حواجز الإصدار. بقيت الميزانيات من دون رفع سقف. القياس المحلي: JavaScript
الابتدائي `673,159/720,000` وإجمالي gzip `299,506/370,000`؛ بناء TestFlight:
`673,350/720,000` و`299,553/370,000`. بقي CSS `69,989/70,000`. تزامن iOS
القياسي وAndroid بنجاح.

بُني Android Release وثُبت كتحديث يحفظ البيانات على Note 8. الجهاز يؤكد
`86.242 (1107)` ومهلة الشاشة `120000ms`؛ دخل Temu بالمقاسات الصحيحة نفسها
وبلا فراغ أو fatal/ANR/OOM. الأدلة في
`artifacts/device-captures/v86.242-note8/`.

- APK: `artifacts/release-86.242/Otlobli-86.242-1107-release.apk` —
  `4,111,902` بايت، SHA-256
  `208FFB9B5B333C7731FB816ECDDA33BE95B06BA9721B167C79D41F3704594A78`،
  توقيع APK v2/v3، `minSdk 24` و`targetSdk 36`.
- AAB: `artifacts/release-86.242/Otlobli-86.242-1107-release.aab` —
  `5,772,210` بايت، SHA-256
  `C42AE0279ACF5FAEDCA23E9FFDC43584FB4913FC741DF386DB4F420C1B648557`.

تحقق Apple من IPA ورفعها بلا أخطاء؛ Delivery UUID هو
`e7ab793a-ba55-49c0-b03b-ca25cb7f3a04`. البناء `86.242 (1107)` صار
`VALID` ثم `IN_BETA_TESTING` ضمن مجموعة all-builds `Otlobli Internal`، وحالة
عضوية المختبر `INSTALLED`. IPA حجمها `10,544,361` بايت وSHA-256
`F814CD76FB3D9F82D9F7FCF98D7BB45BD66C48BC3178616509E6B36A357D92A3`.
Artifact GitHub رقم `9590730095`، اسمه
`otlobli-ios-v86.242-build-1107-testflight`، حجمه `25,251,919` بايت وdigest
`sha256:2a6a8ce5795e900e74de760bd22651978fa0c6ad3a7f5765d1a68653688c9a54`.
اجتاز preflight خدمة WhatsApp والمصادقة من دون إرسال رمز تجريبي.

لا يجوز ادعاء قبول iPhone من البناء أو TestFlight. يلزم فتح منتج Temu على
iPhone 16 Pro Max والتأكد من زوال الفراغ وثبات الرأس، ثم خمس دورات
background/resume واختبار force-quit/cold-launch مستقل.

# v86.241/1106 — تثبيت رأس Temu على iPhone وربط طلب الصديق (2026-08-26)

تابع فقط داخل
`C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` على الفرع
`codex/otlobli-v86-212-testflight-auth`. الإصداران القياسيان Android وiOS هما
`86.241 (1106)`. التغييرات مبنية ومزامنة، ورفعت خدمة الويب إلى
`https://talabieh.vercel.app`، وطبقت قاعدة البيانات وEdge Function في مشروع
Supabase الحي `dcicqdprtyhwmhegabay`. الالتزام
`33da0d8505f4979115b2659a04e711ec05b076fa` مدفوع، ومسار TestFlight
`32918348290` نجح في المحاولة الثانية مع التوزيع الداخلي ومن دون App Store
submission.

حل تحليل فيديو iPhone 16 Pro Max فصل بين سطح Otlobli الثابت ورأس Temu
الداخلي الذي كان يتحرك بنحو `70px`. السبب هو أن طي غلاف تنزيل Temu صار يعمل
على iOS، بينما تصفير مركبة Y لعلامة Temu الدلالية اللاصقة بقي محصورًا في
Android. صار التصحيح يعمل على iOS أيضًا، لكنه لا ينشط إلا على Temu Home وبعد
إثبات طي الغلاف. لا يغير البحث أو التصنيفات أو المنتجات، ولا يضيف مؤقتًا أو
مراقبًا أو مسح DOM أو شريطًا داخل الصفحة.

واجهة تسجيل الدخول الاختيارية التي قد تظهر عند أول منتج في SHEIN تُغلق عبر
إجراء SHEIN المحدد «تسجيل الدخول لاحقًا» داخل دورة السياسة الموجودة أصلًا.
التحقق البشري يخرج قبل هذه المطابقة، ولا يُملأ نموذج أو يُحجب تسجيل دخول
اختاره المستخدم، ولم يُضف مؤقت أو مراقب جديد. يحوي مسار الحجب الاحتياطي
المطابقة الدقيقة نفسها فقط.

أعيدت ميزة «اطلب مع صديق» إلى دعوة ثنائية صريحة: المضيف وصديق واحد فقط.
الرابط النظيف يحتوي `code/group/store` فقط، ولا ينضم الزائر تلقائيًا قبل
موافقته. واجهة الدعوة أصغر وتعرض المشاركة المباشرة عبر WhatsApp وحالة
«شخصان فقط». الخادم يطلب جلسة مستخدم موثقة، ويستخدم RPC ذرية، وفهارس جزئية
تمنع مضيفًا ثانيًا أو صديقًا ثانيًا، ويغلق المجموعة عند خروج المضيف. حُدّثت
عمليات السلة لتتجاهل الردود القديمة عبر epoch، ولا تمسح إلا المجموعة والعناصر
المطابقة، مع سقف `200` عنصر والتحقق من UUID. لم يتغير منطق الدفع أو المحفظة
أو الطلب المكتمل خارج تنظيف رابط المجموعة المطابق.

طُبقت migration
`supabase/migrations/20260826123000_group_order_single_friend.sql` حيًا من
دون تعديل المجموعات التاريخية. تحقق ما بعد الترحيل: `30` مجموعة و`44` عضوية
و`1` مجموعة نشطة، ولا إخفاق في سلامة المضيف النشط. الاختبار الحي داخل معاملة
مع `ROLLBACK` أثبت مضيفًا وصديقًا واحدًا، ورفض الصديق الثالث بفهرس
`cart_group_members_one_friend_per_group_idx`، وإلغاء المجموعة عند خروج
المضيف، ثم بقيت الأعداد كما هي. ألغيت صلاحيات RPC القديمة المجهولة، ونُشرت
Edge Function الجديدة؛ smoke عام يعيد `400 {"error":"bad_action"}` للفعل
غير المعروف بدل عقد الإصدار القديم.

نجح `npm run build` بكل حواجز الإصدار، ونجح TypeScript وDeno و
`test:group-orders` و`verify:shein-freeze-guard` و`verify:store-surface` و
`git diff --check`. بقيت الميزانيات من دون رفع سقف: JavaScript الابتدائي
`673,159/720,000`، إجمالي gzip `299,501/370,000`، وCSS
`69,989/70,000`. مزامنة `npx cap sync android` و`npx cap sync ios` نجحت.
فحص lint الكامل ما زال يتوقف فقط عند خطأين قديمين خارج النطاق في
`src/services/sheinNavigationScript.ts:44` مع التحذيرات المعروفة.

بُني Android release وbundle بنجاح وثُبت APK كتحديث يحفظ البيانات على
Samsung Note 8 `SM-N950F`. الجهاز يؤكد `86.241 (1106)` ومهلة الشاشة
`120000ms`. بقي رأس Temu والبحث في موضعهما عند الفتح وبعد تمرير عميق، وبقي
الشريط الأصلي خارجهما. ظهر تحقق Temu الأمني الأصلي عند الرجوع؛ توقف الاختبار
فورًا ولم يُحاول تجاوزه. لا توجد مطابقة fatal أو ANR أو OOM في سجل الفحص.
الأدلة في `artifacts/device-captures/v86.241-note8/`.

- APK: `artifacts/release-86.241/Otlobli-86.241-1106-release.apk` —
  `4,111,877` بايت، SHA-256
  `122BF44912874CC78F9D3D2D29C4D3A2DAE1B27DBC3957A160AE53232AB47D8F`،
  وتحقق توقيعه عبر APK v2/v3، مع `minSdk 24` و`targetSdk 36`.
- AAB: `artifacts/release-86.241/Otlobli-86.241-1106-release.aab` —
  `5,772,199` بايت، SHA-256
  `F931E6262CC113325DA770C192C18734E47F1708456E6340290F0933F49A13B3`.

المحاولة الأولى من [المسار `32918348290`](https://github.com/m7madv/otlobli/actions/runs/32918348290)
توقفت بأمان قبل التوقيع لأن مرسل WhatsApp المحفوظ كان خاملًا. كانت الجلسة
`0` موجودة، بلا QR أو إيقاف أو نقاط خطر، فأعيد وصلها مرة واحدة من بياناتها
المحفوظة عبر endpoint الإدارة المحلي المحمي؛ لم تُحذف جلسة ولم تُرسل رسالة.
أعادت الصحة بعدها، وبعد نهاية المسار، `whatsappConnected=true` و
`whatsappSenderReady=true` و`whatsappCredentialsPresent=true` مع
`customer-session-v1` وOTP hardened.

نجحت المحاولة الثانية في `8m37s`. Apple قبلت IPA ذات SHA-256
`23DEACC520F414E01919BA15AAF2AEB25160F3A20D4FB5706B993467C7472425`
وحجم `10,544,380` بايت؛ Delivery UUID هو
`62c29df1-3eb2-4578-8855-68d79716acd6`. البناء الدقيق `86.241 (1106)` صار
`VALID` ثم `IN_BETA_TESTING` ضمن مجموعة all-builds `Otlobli Internal`، وحالة
عضوية المختبر المتوقعة `INSTALLED`. Artifact GitHub رقم `9589184204`، اسمه
`otlobli-ios-v86.241-build-1106-testflight`، حجمه `25,251,950` بايت وdigest
`sha256:826a0531247e67cf8ddb72b86d9beea08b6d23ac43f09fef78f17a4cdc778678`.
خطوة App Review كانت معطلة وتخطيت صراحةً.

بقيت `otlobliForceRecompose()` وتأخير `appDidBecomeActive` البالغ `0.25s`
ودفاع Android resume ومقارنة المناطق عبر `JSON.stringify` كما هي. لم تتغير
منطقة SHEIN أو الجلسات أو التحقق البشري أو الدفع أو الطلبات أو المحفظة. لا
يجوز ادعاء قبول iPhone من البناء أو TestFlight؛ تبقى خمس دورات
background/resume على iPhone 16 واختبار force-quit/cold-launch مستقل مطلوبة.

# v86.237/1102 — فصل هوية المتجر عن تبويب السلة وقبول Note 8 (2026-08-25)

تابع فقط داخل
`C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` على الفرع
`codex/otlobli-v86-212-testflight-auth`. شجرة العمل متسخة وتحتوي تغييرات
المستخدم وذكاءات سابقة؛ المرشح محلي وغير ملتزم أو مدفوع أو منشور. الإصداران
القياسيان Android وiOS هما `86.237 (1102)`، وإصدار Android المعزول هو
`86.237-personal (1102)`، وGecko manifest هو `1.3.21`.

أُعيد إنتاج العطل الذي وصفه المستخدم على Note 8 بالإصدار السابق: Temu ←
السلة ← اختيار تبويب سلة SHEIN ← الرئيسية ← قائمة المتاجر ← SHEIN كان يستطيع
إظهار جلسة Temu المركونة، كما كان حدث إضافة متأخر يستطيع استخدام تبويب السلة
الحالي بدل المتجر المصدر. السبب المثبت هو استعمال `selectedStoreRef` لهويتين
مختلفتين: تبويب السلة المرئي ومالك WebView القياسي الفعلي.

أصبحت جلسة WebView القياسية تملك هوية صريحة `{store, sessionId, id}`. لا يُعاد
استعمال الجلسة إلا إذا طابق مالكها المتجر المطلوب؛ وتُرفض أحداث التحميل
والرابط والرسائل والإغلاق القديمة ما لم تطابق الجلسة ومعرّف النافذة. ربط
المعرّف المبكر محدود بمرحلة الفتح، والمتجر والجلسة نفسيهما، ومعرّف غير متجاهل،
ولا يعمل أثناء الإغلاق. تغيير تبويب السلة لم يعد يغلق المتجر أو يغيّر مالك
WebView. رسائل الإضافة تحفظ في سلة متجر الرسالة، ويغلب نطاق رابط المنتج
الموثوق عند التعارض، ويذهب ACK إلى معرّف WebView المصدر بدل البث. Gecko يمرر
`sourceStore:'temu'` صراحةً. عند أول تشغيل يصلح ترحيل واحد محدود العناصر التي
يثبت نطاق رابطها أنها في السلة الأخرى؛ الروابط القديمة المجهولة لا تتحرك.

زر Otlobli داخل منتج Temu بقي ثابتًا `128×48 CSS px` ومن اليمين `14px`، وارتفع
فقط من `16px` إلى `24px` عن نهاية WebView. لم يتغير زر SHEIN (`16px`) ولم
تُضف قراءة inset أو `visualViewport` أو مؤقت أو مراقب أو مسح DOM أو شريط داخل
الصفحة. على Note 8 كانت حدود الزر `[706,1666][1044,1795]` ونهاية WebView عند
`y=1858`: فراغ `63px` فعليًا = `24 CSS px` بكثافة `2.625`.

ثُبّت APK القياسي النهائي كتحديث يحفظ البيانات على `SM-N950F`. تقرأ السلة
بعد ترحيل البيانات `Temu=2` و`SHEIN=0`. نجح المسار الأصلي كاملًا في الاتجاهين:
فتح السلة من Temu اختار Temu، وتبديل تبويبها إلى SHEIN ثم Home أعاد Temu،
واختيار SHEIN من المنتقي فتح SHEIN؛ والعكس بدأ من SHEIN واختار تبويب Temu ثم
أعاد SHEIN، وبعد المنتقي فتح Temu. بقي WebView الفعلي
`[0,63][1080,1858]` والشريط الأصلي خارجه. لقطة تحميل Temu العكسية لم تكن
تعليقًا: أثبت log أنها سبقت إرفاق النافذة بـ`19ms` فقط؛ لذلك لم يتغير
`isPresentAfterPageLoad` أو `preShowScript` ولم يضف غطاء أو مؤقت. لا يوجد في
سجل القبول fatal أو ANR أو OOM أو native crash. الأدلة في
`artifacts/device-captures/v86.237-note8/`.

نجحت مصفوفة قياس Temu عند عروض `320/360/393/412/430 CSS px`، ومنها عرض A52
التقريبي `412px`. المحاكي `1080×2400 @420dpi` حُدّث إلى Debug `86.237/1102`
من دون حذف بياناته، لكنه فتح شاشة الدخول؛ لم يُتجاوز التحقق ولم يُدّع اختبار
Temu حي عليه. لا يوجد جهاز A52 حقيقي متصل في هذه الدفعة.

نجح `test:release-services` وTypeScript وESLint المحدد و
`verify:temu-size-gate` و`verify:store-surface` و`verify:release-hardening` و
`verify:shein-freeze-guard` والبناءان الكاملان. مزامنة Android وiOS تمت من
`dist` القياسي النهائي. الميزانيات نجحت من دون رفع حد: startup/largest JS
`669,726/720,000` و`/1,200,000`، JS gzip `295,014/370,000`، CSS
`69,932/70,000`، الخطوط `81,364/100,000`، نصوص المتاجر
`315,090/470,000`، Gecko `170,458/180,000`، ومصدر المتاجر
`564,829/600,000`.

الحزمتان موقعتان بشهادة Otlobli المتوقعة ذات SHA-256
`e0b0f44cc677888f9535c01c9125077e09b014bdb9096dc2813e3bd06f17f784`
وتنجحان عبر APK v2/v3:

- `artifacts/release-86.237/Otlobli-86.237-1102-release.apk` — `4,107,374`
  بايت، SHA-256
  `C05C949846881FDBB6E82B286CAEE487AE38CBF6A1DF30A65FA4B24B8A6552A8`،
  `minSdk 24` و`targetSdk 36`.
- `artifacts/release-86.237/Otlobli-86.237-1102-temu-personal-arm64.apk` —
  `195,389,315` بايت، SHA-256
  `8B4009316E168DEA720ACE20186F6629625EDA002A5D927625676DC1CFB80AD9`،
  `minSdk 26` و`targetSdk 36`.

لم تتغير منطقة SHEIN أو الجلسات أو التحقق البشري أو الدفع أو الطلبات أو
المحفظة. بقيت `otlobliForceRecompose()` وتأخير `appDidBecomeActive` البالغ
`0.25s` ودفاع Android resume ومقارنة المناطق عبر `JSON.stringify` كما هي.
iOS متزامن فقط؛ لا IPA ولا قبول iPhone. تبقى خمس دورات background/resume على
iPhone 16 واختبار force-quit/cold-launch مستقل شرطًا قبل قبول iOS.

# v86.236/1101 — Temu sticky-offset correction verified on Note 8 (2026-08-25)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. This is a local dirty candidate;
it is not committed, pushed, uploaded, submitted, or published. Standard
Android and iOS are `86.236 (1101)`; the isolated Android build is
`86.236-personal (1101)` with Gecko manifest `1.3.20`. The external states of
the previously submitted `86.230 (1095)` and internal TestFlight `86.231
(1096)` were not changed.

The remaining reported Temu “crowding” was separated into two parts. Temu's
dense category, benefit, trust, hero, promotion, and product-grid rows are
third-party content. The actual Otlobli-induced fault appeared only after a
scroll round-trip on Android Home: v86.235 collapsed Temu's `0.66rem` download
shell, while Temu retained `transform: translate(-50%, 0.66rem)` on its empty
semantic `[js-selector="bg-cui-top-sticky"]` presentation marker. Temu sets
`1rem=100 CSS px`; the observed Note 8 jump was `173` physical px at density
`2.625`, or `65.9 CSS px`, which matches that stale `66px` offset.

The correction is a static CSS rule on that one Temu marker. It runs only when
the existing bounded shell detector has actually marked and collapsed the
download shell, Android is active, and the current route is Home. It resets
only the transform Y component while preserving `translateX(-50%)`; it does
not force `top`, move Search/content, or apply on product, account, challenge,
iOS, or Gecko-web surfaces. The success attribute changes only on a real state
transition, so the existing `650ms` low-end coordinator does not create
periodic DOM mutations. No timer, observer, broad scan, scroll listener,
WebView, or navigation bar was added.

On physical `SM-N950F`, the WebView remains `[0,63][1080,1858]` and the native
bar `[0,1858][1080,2094]`. Temu's stable Home measurements are categories
`y=199..244`, benefits `273..420`, trust `435..514`, hero `548..1105`, content
tabs `1176..1228`, and grid start `1260`. The orange Temu logo was
`y=95..138` initially, became `268..311` after a scroll in v86.235, and stayed
exactly `95..138` initially and after 5 and 10 varied-speed cycles in v86.236.
The initial and cycle-10 header crops were pixel-identical.

A saved raw-Temu viewport study separates responsive density from host UI. At
`320x568`, `360x640`, `393x852`, `412x831`, and `430x932`, collapsing only the
native Temu download wrapper moves the product-grid start from
`430.0/483.8/513.1/522.6/531.5` to
`373.7/420.4/447.1/456.6/465.5 CSS px`; the latter is
`65.8%/65.7%/52.5%/54.9%/49.9%` of viewport height. Note 8's measured grid
start is `456.0 CSS px` (`66.7%` of its `683.8px` WebView height), within
`0.6px` of the `412px` study. This confirms the
remaining categories, benefits, trust, hero, content tabs, and grid are Temu's
own responsive rows. The native bottom bar stays outside the WebView and is
`236` physical px (`89.9dp`) on Note 8, with no overlap or gap.

The standard APK was installed in place with `adb install -r`; data was not
removed and the device reports `86.236 (1101)`. Acceptance covered a cold
launch, 10 deep scroll/return cycles, English suggestions and Arabic keyboard
input, two separate products followed by Back, another scroll round-trip, and
background/resume. The header remained correct and the current process log has
no matching fatal, ANR, OOM, or native-crash line. Chrome reached Temu's own
`bgn_verification` page, so browser scrolling was not compared or bypassed.
Synthetic ADB taps could not reproduce the native `320ms` chooser gesture in
this pass; its previously accepted v86.235 implementation was unchanged.

The 10-cycle stress trace rendered `5,214` frames with
`p50/p90/p95/p99 = 10/21/24/32ms`, `28.63%` jank, and 12 missed vsyncs. PSS
moved from `194,091 KB` to `203,757 KB` (`+9,666 KB`) while graphics stayed
`56,736 KB`. This is an intentionally heavy 80-swipe Temu trace, not a direct
raw-browser comparison and not evidence that third-party Temu rendering became
light. No performance budget was raised.

`npm run build:temu-personal`, `npm run build`, scoped ESLint, release-service,
production, freeze, Temu product/size, store-surface, hardening, and low-end
guards pass; Android and iOS synchronized from the final standard `dist`.
Repository-wide `npm run lint` remains red only on two pre-existing, out-of-
scope `no-useless-escape` errors at `src/services/sheinNavigationScript.ts:44`
plus 18 existing warnings; SHEIN was not changed. Both artifacts use the
expected Otlobli RSA-4096 certificate and verify with APK v2/v3:

- `artifacts/release-86.236/Otlobli-86.236-1101-release.apk` — `4,106,166`
  bytes, SHA-256
  `05AF2BBFC825235328DFA72E59EB7AD0F7E7047307ABFEDB0217EABE1E3BD32F`,
  `minSdk 24`, `targetSdk 36`.
- `artifacts/release-86.236/Otlobli-86.236-1101-temu-personal-arm64.apk` —
  `195,388,096` bytes, SHA-256
  `D675BC71234069569451717F09AC7B4885543682BF048A9B56F9DD892CCC2E5F`,
  `minSdk 26`, `targetSdk 36`.

iOS source/assets are synchronized at `86.236 (1101)`, but Windows cannot
archive/sign an IPA and no iPhone acceptance was performed. Five real iPhone
16 resume cycles and a separate force-quit/cold launch remain mandatory. The
protected `otlobliForceRecompose()`, `appDidBecomeActive` delay `0.25s`, Android
resume defense, and JSON-stringified region equality remain intact and their
guard passes.

# v86.232/1097 — native store surface, CAPTCHA isolation, and low-end runtime maintenance (2026-08-25)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. The current work is a local dirty
candidate based on `852868e`; it is not committed, pushed, uploaded to
TestFlight, submitted to App Review, or published. Marketing/version codes are
`86.232 (1097)` on iOS and standard Android; the isolated Gecko artifact uses
version name `86.232-personal` with the same code. The previously submitted
`86.230 (1095)` and internal TestFlight `86.231 (1096)` were not changed.

The SHEIN/Temu bottom surface is now permanent native UI outside the store
`WebView`, not `#otlobli-nav` inside third-party DOM. iOS, standard Android, and
the isolated Android Gecko surface reserve `74pt/dp` plus the real safe-bottom
inset; loading/offline layers end above it. The bar is opaque white with no
blur, shadow, or animation. Home double activation within `320ms` opens the
store chooser, while accessibility activation provides a direct chooser path.
Android uses real WindowInsets for navigation/gesture/IME changes. The native
Back state is republished from the current document instead of being owned by
fragile injected markup.

Human verification is treated as exclusive store-owned UI. Otlobli pauses its
DOM scans, blockers, selection helpers, region work, and bounded image timers;
owned temporary styles are restored. It never selects CAPTCHA images, clicks
the check, invents a token, or bypasses the provider. `humanCheckResolved` is
status-only: queued products and native navigation stay gated until a trusted,
stable ready signal from the same resolved document or a newer document.
Capgo accepts gate-changing messages only from a top-level HTTPS frame on the
current SHEIN/Temu host; the legacy Android bridge can forward messages but
cannot alter the native gate. Native/toolbar/system Back and iOS edge-swipe are
locked through the hand-off. Cookies are flushed after a real resolved signal
so the provider may reuse its own verification session. The exact optional
SHEIN action `تسجيل الدخول لاحقًا` is clicked only on the relevant product/auth
interstitial; generic account forms are not filled or hidden.

Temu now posts generation-scoped `temuPublicReady` and
`temuProductVisible` only after stable public/product evidence. A queued product
survives verification and is retried at most twice. Lightweight Gecko work
retires when the full capture runtime owns a product document. Expensive work
stops while hidden, challenge polling is bounded to an active challenge, normal
polling is adaptive, duplicate observers/cadences were removed, and color/SKU
timers are single-owner and cancelled on challenge, route, or visibility
changes. No feature or performance budget was removed/raised.

`npm run build`, TypeScript, release/auth/security/secret checks, production
hash protection, SHEIN freeze, Temu product/size, store-surface, release
hardening, patch reverse-check, and low-end budgets pass. ESLint exits `0` with
the 18 documented warnings and no errors. Final budgets are startup/largest JS
`663,530/720,000` and `/1,200,000`, total JS gzip `290,914/370,000`, CSS
`69,932/70,000`, fonts `81,364/100,000`, minified store scripts
`304,558/470,000`, Gecko capture `160,920/180,000`, and store source
`552,103/600,000`. `npx cap sync android` and `npx cap sync ios` both pass.

Signed local Android artifacts, both verified with APK signature schemes v2/v3
and the existing Otlobli production upload certificate:

- `artifacts/release-86.232/Otlobli-86.232-1097-release.apk` — `4,103,257`
  bytes, SHA-256
  `BF995D428803B03AE2D5F08935CE7A75B08667373195E1CE9AB3D5652E4D47B7`.
- `artifacts/release-86.232/Otlobli-86.232-1097-temu-personal-arm64.apk` —
  `195,382,950` bytes, SHA-256
  `1F99435469F55129A6342B641E678B0CCAA1D4B7AC2E4FBF5C069AD8002C69E1`.

The standard APK was installed in place over `86.231 (1096)` on the physical
Samsung Note 8 `SM-N950F`; ADB returned `Success`, the package reports
`86.232 (1097)`, and the unchanged first-install timestamp confirms that app
data was not cleared. A force-stop launch completed in `1,198ms`, the process
remained alive, and the launch-window log contained no matching fatal exception
or ANR. The personal Gecko APK was not installed, and user store/CAPTCHA
acceptance is still pending. iOS source/assets are synchronized, but Windows
cannot archive/sign an IPA and no Mac workflow was authorized or triggered.
Before release, perform the required real iPhone 16 five background/resume
cycles plus a separate force-quit/cold launch, verify genuine SHEIN/Temu CAPTCHA
completion and session reuse, and complete the now-started old-Android manual
pass. See `docs/DESIGN_AUDIT.md` for the UI audit and pending VoiceOver/TalkBack/
orientation/keyboard checks.

# v86.231/1096 — TestFlight WebView and blocking performance maintenance (2026-08-24)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Marketing version is `86.231` and
both native build numbers are `1096`. Exact source
`44a5200a127f0e3689373c5b756486fef510dd4f` is pushed. Signed workflow
[32760648713](https://github.com/m7madv/otlobli/actions/runs/32760648713)
passed: Apple accepted delivery UUID `05c2aefa-05ec-4ec1-994a-c3e24bcb6d65`,
and exact `86.231 (1096)` is `VALID` and `IN_BETA_TESTING` in the internal
all-builds group `Otlobli Internal`. The expected tester account state is
`INSTALLED`. Public App Store submission was explicitly false and the review
step was skipped. The separately submitted `86.230 (1095)` therefore remains
the last confirmed `WAITING_FOR_REVIEW` build configured for automatic release
after Apple approval; this TestFlight upload did not replace or resubmit it.

Two earlier attempts stopped safely before Apple. Run `32759501489` failed at
`npm ci` because the manually edited Capgo patch had invalid strict hunk
metadata. The patch was mechanically regenerated and clean reverse/apply checks
pass in commit `44a5200`. Run `32760002781` then passed build and sync but
stopped before signing because the persisted WhatsApp sender was disconnected.
Oracle session `0` credentials were present and were reconnected once through
the protected loopback admin endpoint; no message or QR was generated. The live
health contract then passed with connected sender, session store, OTP security,
and `customer-session-v1` readiness before the successful retry.

The injected capture runtime is now compiled per active store: SHEIN receives
only `SHEIN_CAPTURE_SCRIPT` and Temu receives only `TEMU_CAPTURE_SCRIPT`, with
an exact host guard before runtime work. Their minified payloads are `138,492`
and `150,400` bytes respectively; the former shared runtime was about 220 KB.
The Temu personal-Gecko capture fell from `416,137` to `138,945` bytes
(`139,825` bytes including its wrapper). No blocking interval was lengthened
and no feature was removed.

Stable-page work is materially smaller. SHEIN reuses one visible-region text
snapshot per coordinator pass, policy mutations are filtered/deduplicated, and
already-blocked header controls bypass repeated geometry/text reads. Temu
reuses bounded search/product vitals, ties readiness to the current route, and
stops blank/image/product watchdogs only after that exact product is confirmed;
route changes re-arm them. The full injected script, complete product URLs, and
routine bridge event payloads are no longer printed by the native Android/iOS
plugin. The persistent patch and freeze guard now enforce those deletions.

`npm run build`, TypeScript, release-service/production-release verification,
SHEIN freeze, Temu product/size, store-surface and performance gates passed.
Final budgets are startup/largest JS `659,775/720,000` and `/1,200,000`, total
JS gzip `285,982/370,000`, CSS `69,932/70,000`, fonts `81,364/100,000`,
minified store scripts `296,171/470,000`, Temu Gecko `139,825/180,000`, and
store source `523,508/600,000`. Android and iOS were synchronized. The signed
macOS workflow repeated the production build, freeze/release guards, native
sync, universal-device check, authentication preflight, archive, export,
signature/profile/callback validation, upload, Apple processing, and internal
distribution successfully. The whole Android root build still requires the
unrelated `OTLOBLI_LISTENER_*` signer values, while the requested customer task
`:app:assembleRelease` passed.

Signed iOS artifacts downloaded from GitHub artifact `9532806101` are under
`output/testflight-v86.231-build-1096-run-32760648713`:

- `otlobli-v86.231-build-1096-testflight.ipa` — `10,488,204` bytes, SHA-256
  `D9B1F22FE42FFC16AFC819ECA81E70E54D49F22688FC5DC6EF91A34F3A6D2A77`.
- `otlobli-v86.231-build-1096-dSYMs.zip` — `14,858,853` bytes, SHA-256
  `A8EADD8426A0B0B4DF6FF84449DA67748E656F445D35EDEAB9F80DF83D384F18`.

The uploaded GitHub artifact is `25,146,693` bytes with digest
`sha256:f5c526fd529b45d29328b395d8cd8a85b1b0a22d59278d63bf7561667d197702`.

Signed Android artifact:

- `output/Otlobli-v86.231-Android-Performance-Maintenance.apk` — `4,098,272`
  bytes, SHA-256
  `4EDEE16ACB3C8E1B473E0601D7CF42ECCA1ED6CFDC36EB7C60F7942185B6C4F5`.
  Package `com.otlobli.app`, `versionCode=1096`, `versionName=86.231`, v2/v3
  signing verified with the existing Otlobli production upload certificate.

The APK was installed as an in-place update on the physical Samsung Note 8
`SM-N950F`. A fresh process launch measured `812ms` (a subsequent cached launch
was `632ms`). Temu Home → product → Home rendered successfully and retained the
Otlobli Back button; SHEIN Home rendered with the controlled surface. Both had
zero app crash/ANR and zero heavy native bridge-payload logs. Four steady SHEIN
scrolls measured 401 frames, 9.73% jank, p50/p90/p95/p99 of
`11/16/18/24ms`, with `181,936 KB` PSS. Four steady Temu scrolls measured
`17/24/27/36ms`; its external page remained more render-heavy on this 2017
device. These are Android smoke/performance results, not comprehensive store or
checkout acceptance. The required five real iPhone 16 resume cycles plus a
separate cold launch remain unperformed for `86.231`.

# v86.230/1095 — submitted to Apple Review (2026-08-24)

The owner gave the exact action-time confirmation to submit this accepted
build and release it automatically after approval. Authorized workflow
[32703091122](https://github.com/m7madv/otlobli/actions/runs/32703091122)
passed from exact source `c45ea0114323cc71aff16f1e2e337616115085c2`.
It verified and reused the existing `86.230 (1095)` build, confirmed both
screenshots as COMPLETE, added the version to review submission
`e5e27b8a-b628-4116-b135-361b91266929`, and Apple returned
`WAITING_FOR_REVIEW`.

App Store Connect now has the Arabic description, keywords, support URL,
copyright, Shopping category, free price, all 175 territories, and the
calculated 13+ rating (12+ on pre-v26 systems, with regional equivalents).
Untested Apple Silicon Mac and Vision Pro distribution are disabled. The
iPhone 6.5 `1242x2688` and iPad Pro 12.9 `2048x2732` screenshots are COMPLETE
under localization `ar-SA`. Privacy and user-choice URLs point to
`https://talabieh.vercel.app/privacy.html`; all 13 accurate data types are
configured as App Functionality, linked to the user, and not used for tracking.
The owner approved publication and the privacy label is now published in App
Store Connect.

Public privacy/support pages are live from READY Vercel deployment
`dpl_2EU6QQoxjhA7xFuFsrARAUB3SS69`. The third-party content-rights declaration,
reviewer contact details, and Sign in with Apple review instructions are saved;
personal contact values are not copied into the repository. The app is not yet
public or approved: it is waiting for Apple Review and is configured to release
automatically only after approval. The `PREPARE_ONLY` marker remains removed
because the authorized submission completed.

# v86.230/1095 — TestFlight uploaded and internally distributed (2026-08-24)

Signed workflow
[32673961608](https://github.com/m7madv/otlobli/actions/runs/32673961608)
passed from exact source `b8f05e13d6f68e9a170fc5e419209ec7e6911f64`.
Apple accepted the upload with delivery UUID
`39aa64a7-dc63-4895-9fe9-81a9f3ef8838`; exact `86.230 (1095)` is `VALID`
and `IN_BETA_TESTING` in the `Otlobli Internal` all-builds group. Expected
tester membership is verified and the tester state is `INSTALLED`. Public App
Store review was explicitly disabled and skipped; this is a TestFlight-only
release for physical acceptance before any store submission.

Downloaded artifacts are under
`output/testflight-v86.230-build-1095-run-32673961608`. The `10,460,853`-byte
IPA has SHA-256
`5F886B0D053A076AD85073079CF0152AC9709388DD04D1D575890791788FE049`;
the `14,858,947`-byte dSYMs archive has SHA-256
`F9E770FA70E87016B652ED3BE34AA1DC38B76DC283D982728BCBFC0F26E58C4D`.
Workflow production build, native sync, signing/profile/auth callback checks,
upload, processing, and internal distribution all passed.

The iOS deployment target remains 15.0. An actual iPhone 6 cannot install this
build because that model is limited to the iOS 12 generation; iPhone 6s and
later can run iOS 15. Confirm the exact model before expecting TestFlight to
offer the build. Real-device acceptance of v86.230 remains unperformed; test on
a compatible iPhone before authorizing public App Store submission.

# v86.230/1095 — two-store identity, unified auth, signed Android production artifacts (2026-08-24)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Marketing version is `86.230` and both
native build numbers are `1095`. This batch was intentionally not submitted to
App Store, TestFlight, Google Play, or any public review track.

The customer-facing identity no longer presents Otlobli as a SHEIN-only app.
Authentication, onboarding, metadata, manifest copy, product fallbacks, and
order-success copy now describe SHEIN and Temu together. The login is a compact
Arabic-first native surface with a clear two-store route, integrated full-width
Google and Apple actions, an explicit WhatsApp-phone path, trust copy, visible
focus/pressed states, and reduced-motion support. The Apple mark is an inline
SVG instead of the Apple private-use glyph, so it renders correctly on Android.
Playwright visual QA passed at `320x568`, `360x640`, and `430x932`; the checked
mobile widths have no horizontal overflow. No heavy animation, blur, timer,
polling, store script, WebView lifecycle, payment, wallet, or completed-order
logic changed.

Android production signing is now reproducible. A dedicated 4096-bit Otlobli
upload key is retained outside the repository at
`C:\Users\MOHAMMAD\.android\otlobli-main-upload.jks`, with local properties at
`C:\Users\MOHAMMAD\.android\otlobli-main-upload.properties`; its passwords and
private key were never printed or committed. Matching encrypted GitHub Actions
secrets exist. Public certificate SHA-1 is
`99:6F:BA:CA:02:F2:00:76:0C:41:CB:EC:02:EC:95:0E:D1:64:E9:F4`; SHA-256 is
`E0:B0:F4:4C:C6:77:88:8F:95:35:C0:1C:91:25:07:7E:09:B0:14:BD:B9:09:6D:C2:81:3E:3B:D0:6F:17:F7:84`.
Both fingerprints were added to Firebase project `otlobli-1ccf5` for
`com.otlobli.app`, and the downloaded `android/app/google-services.json` now
contains the matching Android OAuth client. The existing Android workflow now
performs production auth preflight, restores the protected key, builds signed
optimized APK/AAB artifacts, validates package/version/signature/hardening, and
uploads a versioned production artifact. ESLint now ignores generated release
inspection content under `output/**`, matching its other build-output ignores.

The exact production environment was built and copied into both native
projects. `npm run build`, all release/auth/security guards,
`verify:shein-freeze-guard`, Temu/store guards, and
`verify:performance-budget` pass. Final budgets are startup/largest JS
`661,790/720,000` and `/1,200,000`, total JS gzip `265,531/370,000`, CSS
`69,932/70,000`, fonts `81,364/100,000`, shipped store scripts
`227,477/470,000`, and store source `519,044/600,000`. Full ESLint exits zero
with 17 established hook warnings and no errors. `:app:assembleRelease` and
`:app:bundleRelease` pass. APK inspection confirms package `com.otlobli.app`,
`versionCode=1095`, `versionName=86.230`, `debuggable=false`, one RSA-4096
signer with the certificate above, production phone/Google/Apple markers, and
no web source maps. AAB signature and the same embedded production markers also
verify.

Final local artifacts:

- `output/Otlobli-v86.230-Android-Production.apk` — `4,070,937` bytes,
  SHA-256 `544A405F7586B69EFD0882BACC3FB9641CB75658AAC3F930B082800C55294373`.
- `output/Otlobli-v86.230-Android-Play.aab` — `5,720,927` bytes,
  SHA-256 `6D1FC53520684CD1761FC7CD921A1FE78981EA6CFC647D72E2951C56A558A2BD`.

Real Android device acceptance is still unperformed: install the APK and test
one phone OTP, Google login, Apple login, SHEIN, Temu, and push delivery. A real
weak/old Android performance pass is also still required before claiming store
acceptance. iOS source/assets are synchronized, but no new iOS binary was built
or uploaded in this batch.

# iPhone APNs hosted key transport fixed; live delivery accepted (2026-08-24)

The owner created the dedicated topic-specific production APNs key
`4GGVNXQ9UT` for `com.otlobli.app` and retained the one-time file
`C:\Users\MOHAMMAD\Downloads\AuthKey_4GGVNXQ9UT.p8`. The file is a valid
257-byte PKCS#8 PEM with SHA-256
`82D90432FE29D0C74313AFDFE1D57768C0FEFCA71529DA1394A7CB110357E0BE`.
Its private contents were never printed or committed.

The user's first retries still produced no alert. Production function logs gave
the exact cause on every attempt: `APNs JWT sign failed expected valid PKCS#8
data`. The Apple file and identifiers were correct, but the initial multiline
CLI secret transport corrupted the PEM inside the hosted Edge runtime. The
server now normalizes literal PEM, escaped-newline PEM, or a single-line base64
PEM. Production `APNS_KEY` was replaced with the base64 form so shell/env
transport cannot alter its line structure; private material is never logged.

The authenticated probe now runs inside Supabase itself, signs with the hosted
secret, and receives the expected `400 BadDeviceToken` from production APNs for
a deliberately fake token. A separate real test targeted only the newest active
`86.229`, iOS `27.0`, production installation. The live response was `sent=1`,
`total=1`, `delivery.apns.sent=1`, with zero invalid/retryable/failed tokens and
`configuration.apns=true`. Apple therefore accepted the actual device message;
visual receipt/tap confirmation remains with the owner.

`send-push` is active as version `19` with `verify_jwt=false`; `admin-orders` is
active as version `46` with `verify_jwt=true`. The shared push trigger secret was
rotated and both functions use the same project secret. Full build, secret scan,
release-service/security tests, SHEIN freeze guard, store guards, and low-end
budgets pass. Preserve iOS → APNs and Android → FCM strict mapping. This
server-only correction does not require a new TestFlight build or native sync.

# Production Admin push payload repair (2026-08-24)

The user physically accepted the complete `86.229 (1094)` Temu behavior on the
iPhone, including the native Back returning after product → listing/Home. The
only reported problem after that acceptance was Admin manual notifications
returning `invalid_payload`.

The live `send-push` contract requires an explicit safe navigation payload, but
the legacy Admin sender supplied only target/title/body. Admin now sends
`{ version: '1', type: 'system', route: 'notifications' }` for both broadcast
and single-customer messages, so delivery is accepted and a notification tap
opens the in-app Notifications screen. Known server errors are presented in
Arabic instead of exposing raw protocol codes. The automatic order-status
sender was aligned with the same contract using `order_update`,
`orders/details`, and the exact order id; order, payment, and wallet behavior
were not otherwise changed.

Admin production build and `test:release-services` pass. Vercel deployment
`dpl_Ffk4BRxnC18dNNAGWUY6KjB9ZtBW` is `READY` and aliased to
`https://talabieh-admin.vercel.app`; no-cache readback of live asset
`/assets/index-DsatHAQz.js` (`274,485` bytes, SHA-256
`D04A7D66F3163532F1A74DF0BAE1EDA6F4F0558CBEF6AF64939EA362BD862749`)
confirms the typed payload and localized error. Supabase `admin-orders` is live
as version `41` with its existing `verify_jwt=true`. No customer notification
was sent during validation. This Admin/Edge-only batch does not change app
version or require native sync.

# v86.229/1094 — republish Temu iOS Back on SPA URL change (2026-08-24)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Marketing is `86.229`; iOS is `1094`
and Android is `1093`. The user physically accepted the v86.228 SHEIN Qatar
region correction. This batch is limited to the remaining Temu iOS Back issue.

Frame review of the supplied 58.54-second iPhone recording confirms the green
native Back is visible on first Temu entry, is hidden on a product as intended,
but does not return after the product navigates back to the listing/Home surface.
Native `didStartProvisionalNavigation` owns the hide. The v86.224 repair only
re-published from `didFinish` and JavaScript `pageshow`; Temu's SPA product/Home
history transition instead updates the already-observed `WKWebView.url` without
guaranteeing either callback, leaving the native control hidden.

The Capgo iOS patch now reuses that exact URL KVO event to call the existing
`republishOtlobliNativeBackState(in:)`. That event clears the document dedupe key
and asks the current route to publish its one native Back state, so inner Temu
pages remain owned by Temu while the root exit returns immediately on Home. No
timer, polling, DOM scan, reload, WebView rebuild, lifecycle timing, SHEIN region,
orders, wallet, payment, or backend behavior changed. The store guard now checks
that the re-publication call lives inside the URL observer, not merely elsewhere
in the patch.

The dependency patch applies strictly to a fresh 8.6.25 package. Full production
build, release/auth/security/SHEIN/Temu/store guards, both native syncs, Android
`assembleDebug`, and the three-root artifact scan pass. Performance remains
within the existing limits: startup/largest JS `658,718/720,000` and
`/1,200,000`, total JS gzip `264,572/370,000`, CSS `69,968/70,000`, fonts
`81,364/100,000`, shipped store scripts `227,477/470,000`, and source
`519,044/600,000`. Bundle `storeCaptureBundle-uuEtemj5.js` is `250,644` bytes,
SHA-256 `DC1AD9C5AEA6C7E909371F046E121CF31E56F80CDA64B51D3B4D562F4B74BE48`.
Android artifact `output/Otlobli-v86.229-build-1093-Android-debug.apk` is
`11,115,898` bytes, SHA-256
`CD1543209E7E5C34143E1917029857FEE98A9820A43EF6968A6E65E51A3A1391`.
Signed workflow
[32667383788](https://github.com/m7madv/otlobli/actions/runs/32667383788)
passed from `de3ae2593ffc5abec0eea6b241153fe780cf2c5f`. Apple validation/upload
succeeded with delivery UUID `02801af5-7936-43de-870f-af8c234194a6`; exact
`86.229 (1094)` is `VALID`/`IN_BETA_TESTING` in the `Otlobli Internal`
all-builds group, with expected tester state `INSTALLED`. Public review was
skipped. Downloaded artifacts are under
`output/testflight-v86.229-build-1094-run-32667383788`: the `10,460,323`-byte
IPA has SHA-256
`49DABD543789E8D9DBB21D06FC04F86E8ACC114557D1972AA2B3E5FE24A6ACAE`, and
the `14,858,947`-byte dSYMs archive has SHA-256
`EF7CB71DB6B75FDC2FA484B88FD75D71DCB732955AB22A31D771D404DDCC0C7D`.
The user physically accepted the complete Temu behavior on the iPhone: the
button returns after product → listing/Home and the full build is working.

# v86.228/1093 — TestFlight SHEIN Qatar policy/region fix (2026-08-24)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Marketing is `86.228`; iOS is `1093`
and Android is `1092`. Signed workflow
[32665947122](https://github.com/m7madv/otlobli/actions/runs/32665947122)
passed from exact source `7dacf04ae6c606f24a222adb91aad2f9ab3b046f`.
Apple validation and upload succeeded with delivery UUID
`0de5dbb3-1704-4b9c-bc17-dfa1e1bb9ff5`; exact `86.228 (1093)` is `VALID` and
`IN_BETA_TESTING` in the `Otlobli Internal` all-builds group. Expected tester
membership is verified and its state is `INSTALLED`. Public App Store review
was deliberately skipped.

The exact Desktop launcher `محاكي أندرويد Pixel 7.lnk` was used to boot
`Pixel_7_API_35_Test`. A clean current build proved the live Admin response is
`SHEIN QA/USD/ar` (about 1.3–2.5s), while app cold launch itself was only
1.3–2.8s. The real delay was inside SHEIN: interactive browsing took about
6.6–8.1s and the signed Qatar cascade took 11.8–15.3s. The old fixed 12s escape
could therefore close a still-progressing municipality/city/zone drawer.

CDP also proved the final Android SHEIN document had capture installed but no
policy engine, causing `policyState: unknown`, false preparation failure, and a
cover that waited for full signed readiness. Reinstalling policy post-load
initially exposed the deeper conflict: policy hid the live `.sui-drawer.cascade`
controls that Otlobli itself needed to choose the region. v86.228 now restores
the idempotent one-observer policy on every final document, exempts only that
exact cascade while Otlobli's bounded region-repair veil exists, and replaces
the fixed 12s abort with 16s/20s stalled-progress bounds plus a 36s/45s absolute
ceiling. Login/account/checkout/country access remains blocked for the customer;
Add/capture remains fail-closed until the signed address matches.

The clean emulator result is a fully signed Qatar address (`Al Daayen` →
`Zone 70`, nonempty `xAdFlag`), policy `verified` with `installCount: 1` and one
observer, a real current product page, and successful `addToCart` capture after
selecting `iPhone 17` at `$1.60`; no wrong-region message appeared. A real
SHEIN `si-verify-block-request-dialog` appeared during repeated rapid clean
opens and was left visible/untouched until SHEIN resolved it, as required.

Full production build and every auth/security/release/SHEIN/Temu/store guard
pass. Existing low-end budgets pass: startup/largest JS `660,449/720,000` and
`/1,200,000`, total JS gzip `264,924/370,000`, CSS `69,968/70,000`, fonts
`81,364/100,000`, shipped store scripts `227,477/470,000`, and store source
`519,044/600,000`. Android and iOS are synchronized; Android assembly and the
three-root artifact scan pass. Bundle `storeCaptureBundle-uuEtemj5.js` is
`250,644` bytes/SHA-256
`DC1AD9C5AEA6C7E909371F046E121CF31E56F80CDA64B51D3B4D562F4B74BE48`.
Android artifact `output/Otlobli-v86.228-build-1092-Android-debug.apk` is
`11,114,252` bytes/SHA-256
`13075F4E924361694293173F6A579426E2DB733B2EB5723804848EB5552E04AD`.
Downloaded iOS artifacts are under
`output/testflight-v86.228-build-1093-run-32665947122`: the
`10,460,344`-byte `otlobli-v86.228-build-1093-testflight.ipa` has SHA-256
`68F47AA61E8B859D2D7EA8EDA1B1D2394BCD9AA21B0D69F2FD541CA2A9A9F1AA`, and
the `14,858,923`-byte `otlobli-v86.228-build-1093-dSYMs.zip` has SHA-256
`53C81F41932A2F81E200582C0B722AC84CE496756CB7F2A00A4E81C8465DCC30`.
The test-only auth bypass is back to `false` and all temporary CDP probes were
deleted. iPhone acceptance, five background/resume cycles, and a separate cold
launch remain unperformed; never infer them from the Android emulator.

# v86.227/1092 — restore the physically accepted v86.216 region contract (2026-08-23)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Marketing is `86.227`; iOS is `1092`
and Android is `1091`.

The user physically confirmed the exact regression boundary: `86.216` changes
the SHEIN region correctly, while `86.217` introduced the failure that remains
in `86.226`. Commit comparison confirms v86.217 removed v86.216's bounded
browse-ready path during signed-address repair and added a Home rule that
cancelled repair when address state was `unknown` rather than an explicit
`mismatch`. The later Home cancellation was already removed, but the v86.216
short visual-ready continuation was still missing.

This batch restores that remaining v86.216 contract: after a `1.8s` normal or
`2.8s` low-end head start, a policy/currency/language/capture-safe interactive
page may be browsed while the same bounded signed-address cascade continues.
Per-path visual/signed readiness prevents stale page events. Add/capture remains
fail-closed on full coordinator READY and the signed address. The release guard
now requires the v86.216 markers and forbids the v86.217 Home-unknown cancellation.
No reload, new polling loop, DOM observer, diagnostic UI, or lifecycle recompose
was added.

All targeted and full production guards pass. Existing performance limits pass:
startup/largest JS `658,718/720,000` and `/1,200,000`, total JS gzip
`264,278/370,000`, CSS `69,968/70,000`, fonts `81,364/100,000`, shipped store
scripts `227,411/470,000`, and store source `518,366/600,000`. Android/iOS sync
and Android `assembleDebug` pass. The synchronized store bundle
`storeCaptureBundle-DqgI3sKU.js` is `250,063` bytes, SHA-256
`102B4C016C49E6D6F36EA2AD04D0521048B8DB5C5FA4886325614CFB278B8F0B`.
Android artifact `output/Otlobli-v86.227-build-1091-Android-debug.apk` is
`11,113,604` bytes, SHA-256
`0DCBC2601DEE34D01F288A4A5D48A72E65EB1AB14256CFE977F2ACEFB3B37528`.
Signed workflow [32662460797](https://github.com/m7madv/otlobli/actions/runs/32662460797)
passed from `8ce2cce`: Apple validation/upload succeeded, delivery UUID
`616777a5-f4c9-4b08-a21a-b0f226222d09`, and exact `86.227 (1092)` is
`VALID`/`IN_BETA_TESTING` with all-builds access for `Otlobli Internal`; expected
tester state is `INSTALLED`. Public App Store review was skipped. Downloaded
artifacts are under `output/testflight-v86.227-build-1092-run-32662460797`:
the `10,460,026`-byte IPA has SHA-256
`4484FD3B0313D0885DC5832D581BFE13203F9CB67BB206077B1D11BAACA12960`,
and the `14,858,923`-byte dSYMs archive has SHA-256
`885EE512576461BFDAC3E34009F8066E74FEA4C065B3ADDC1FAEEA2B347E3F42`.
Physical acceptance is pending; never infer device acceptance.

# v86.226/1091 — release the v86.71 interactive page without weakening Add (2026-08-23)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Marketing is `86.226`; iOS is `1091`
and Android is `1090`.

The user's physical iPhone rejects `86.225 (1090)`: SHEIN never becomes visible
and remains on «جاري تجهيز المتجر». Windows sees the connected iPhone 16 Pro
Max/iOS 27 USB interfaces and 3uTools initially identified the device, but its
Apple service session timed out before syslog opened. Source-level comparison
with accepted commit `56d1c56` is decisive: v86.71 unconditionally consumed
`sheinPageInteractive`, while v86.225 required fully matching country+signed
region in both React and native Swift. After the bounded 12s repair timeout the
page emitted `sheinPageInteractive` with unknown region, both gates rejected it,
and the preparation cover could never close.

The correction restores the v86.71 separation: a policy-safe, localized,
interactive page with no explicit country/region mismatch may be browsed while
the bounded automatic signed-address cascade continues. Full coordinator READY
and `sheinSignedSaudiAddressReady()` remain mandatory for Add/capture. No timer,
polling, reload, recompose, diagnostic UI, or early DOM cleaner was added. The
automatic product/Home region path, one-time server-change runtime-cache reset,
human verification, current navigation/orders/auth, and lifecycle defenses are
unchanged. Targeted release-service and SHEIN freeze guards pass. Full build,
both native syncs, and Android `assembleDebug` pass. The unchanged synchronized
store bundle is `249,770` bytes with SHA-256
`1EBA8CD8D892D558E1AD4E277B97777E1C8478180C6580D59E235FBF9F38179A`.
The Android artifact is
`output/Otlobli-v86.226-build-1090-Android-debug.apk`, `11,113,448` bytes,
SHA-256 `54BF073B97C750EEC7A3C5B28844CCE7CB54226D8EE2A01B802B7AEE86A95055`.
The full production budgets remain within their existing limits: startup/largest
JS `658,718/720,000` and `/1,200,000`, total JS gzip `264,163/370,000`, CSS
`69,968/70,000`, fonts `81,364/100,000`, shipped store scripts
`227,118/470,000`, and store source `516,561/600,000`. Physical acceptance is
pending; do not infer device acceptance from these checks.

Signed workflow [32661353655](https://github.com/m7madv/otlobli/actions/runs/32661353655)
passed from `f2c6e1a`: Apple validation/upload succeeded, delivery UUID
`4ccd7c30-b0db-4c7b-920a-e1028c868f5a`, and exact `86.226 (1091)` is
`VALID`/`IN_BETA_TESTING` with all-builds access for `Otlobli Internal`; expected
tester state is `INSTALLED`. Public App Store review was skipped. Downloaded
artifacts are under `output/testflight-v86.226-build-1091-run-32661353655`:
the `10,459,918`-byte IPA has SHA-256
`B26A1FF26F4352EC9A91DD45478EA23B5D74B430FA6877CEF86A77C7F3DBE3BB`,
and the `14,858,923`-byte dSYMs archive has SHA-256
`05DB8747EB0606A1355629E82438CB5FECF29B94F2617DC86FB873ACC163D12D`.
Physical acceptance remains pending. The user also confirmed that v86.213
changed the SHEIN region successfully. A source comparison shows the drawer
selection cascade is still materially the same; later readiness/WebView
coordination around it is the stronger regression boundary. v86.226 fixes the
proven infinite-cover gate, but device testing must still establish whether the
signed region itself completes.

# v86.225/1090 — restore the physically accepted v86.71 server-region path (2026-08-23)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Marketing is `86.225`; iOS is `1090`
and Android is `1089`.

The user's physical test rejects `86.224 (1089)`: the same SHEIN region failure
and Temu product -> Home Back loss remain. Searching the actual Codex chat found
the exact remembered acceptance sequence, not an inferred older snapshot:
`v86.69` introduced the fast signed-address path, `v86.70` connected independent
JO/AE/QA/SA Admin/server settings, and `v86.71` commit `56d1c56` refreshed only
the runtime cache on a server-region change. After testing v86.71 the user said
the build was «كتير كتير ضابطة».

This batch restores only that v86.71 operational region path while preserving
the current app, authentication, Orders links, navigation, blocking, capture,
and iPhone lifecycle defenses. A server setting change marks the active SHEIN
cache reset pending, closes the old store session, clears HTTP runtime cache
only, and reopens once without deleting cookies/localStorage/signed address.
An unsigned mismatch may again start automatic native region preparation from
a product route or the Home region entry. Later Home-only/manual-Add gating,
automatic country exhaustion, and visually-ready-before-signed behavior are
removed. Add remains fail-closed. The native iOS preparation cover now releases
only when both server country and signed region are matching; human verification
remains explicitly usable. Experimental diagnostics remain deleted.

Full production build passes every release/auth/security/SHEIN/Temu/store guard,
postbuild hardening, and the unchanged low-end budgets: startup/largest JS
`658,435/720,000` and `/1,200,000`, total JS gzip `264,132/370,000`, CSS
`69,968/70,000`, fonts `81,364/100,000`, shipped store scripts
`227,118/470,000`, and source `516,561/600,000`. Android/iOS sync and Android
`assembleDebug` pass. The synchronized store bundle
`storeCaptureBundle-BZn7Ofmk.js` is `249,770` bytes, SHA-256
`1EBA8CD8D892D558E1AD4E277B97777E1C8478180C6580D59E235FBF9F38179A`.
Android artifact `output/Otlobli-v86.225-build-1089-Android-debug.apk` is
`11,113,408` bytes, SHA-256
`7E1EE70B38B992355CFC55ADCF4F05A01727DE6916F4F0052503F94921F26AAF`.
Signed workflow run `32660285054` from commit `30f7f8b` passed clean dependency
patching, all guards/budgets, Apple Distribution archive/export, signature,
profile, authentication callback, Apple upload, processing, and internal
distribution. Delivery UUID is `e5ba3549-a01d-406f-be7a-3495643582db`.
Exact build `86.225 (1090)` is `VALID`/`IN_BETA_TESTING`; `Otlobli Internal`
has all-builds access and the expected tester state is `INSTALLED`. Public App
Store submission was skipped. GitHub artifact `9498638837` is `25,118,359`
bytes with digest
`sha256:f93938f7602a6ec67c16a8b757a45ba90240e29d5fc3b3caa7795e5e7b1fbf27`.
Downloaded IPA
`output/testflight-v86.225-build-1090-run-32660285054/otlobli-v86.225-build-1090-testflight.ipa`
is `10,459,881` bytes, SHA-256
`3882D28F948656E75D0B46069302D5C454F26193DAAB2E2767ED2158DDB0A9D1`;
the dSYM is `14,858,841` bytes, SHA-256
`41121AE7FCF373252FD7AE6D755BFF86C2772A2BB1C3E310C3252F22062F345B`.
Physical acceptance remains pending. Temu Back code is unchanged in this
region-only restoration and must not be claimed fixed. Preserve
`otlobliForceRecompose`, its 0.25s `appDidBecomeActive` call, Android resume,
and the `JSON.stringify` server-region comparison.

# v86.224/1089 — SHEIN Home preflight and native Temu Back republish (2026-08-23)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Marketing is `86.224`; the locally
validated candidate is iOS build `1089` and Android build `1088`.

The user's physical iPhone 16 Pro Max result rejects `86.223 (1088)`: Temu
blocking/speed improved somewhat, but its green Back still disappears after a
product returns to Home, and the SHEIN region failure is unchanged. The exact
older flow the user remembered was found at commit `9cea927` (`v86.68`): SHEIN
Home's semantic `.area-selector-entrance[role="button"]` opened the native
shipping cascade and produced a signed address before product browsing. That
flow was previously measured at about five seconds on a Note 8 after removing
`localStorage.addressCookie`.

The region architecture now restores that proven flow without restoring its
later product-spinner coupling. Every queued SHEIN product starts from the
configured Home URL; Home alone may use the semantic shipping entry to finish
the signed Admin-selected address, and the host navigates to the queued PDP
only after the full region coordinator is `READY`. The obsolete
`__otlobliSkipHomeRegionRepair` path is deleted. Ordinary PDP browsing still
cannot start region repair; explicit Add remains the fail-closed fallback and
cannot capture until the signed address matches. This also covers product links
opened from `طلباتي` when the store is not already prepared.

Temu's remaining Back loss was a native race: Capgo hides the control in
`didStartProvisionalNavigation`, while a restored Home document may not emit a
new JavaScript state. The patched iOS controller now asks the completed
document to republish Back state once from `didFinish`; this is event-driven and
adds no timer, retry loop, DOM scan, reload, or WebView recreation. Temu's
stable-product paths now stop repeated vital/blank-page scans after the product
identity is confirmed. More than 300 lines of unreachable diagnostic/header-
wake code and forced scroll/resize behavior were removed, entry cleanup no
longer launches forced waves, and the unavoidable loading surface is a branded
light green instead of a raw white page.

Validation passes: targeted ESLint has zero errors (16 established App hook
warnings), TypeScript, every release/auth/security/SHEIN/Temu/store guard, full
production build, postbuild hardening, low-end performance budget, Android/iOS
Capacitor sync, three-root production artifact scan, and Android
`assembleDebug`. Budgets are startup/largest JS `658,718/720,000` and
`/1,200,000`, total JS gzip `264,497/370,000`, CSS `69,968/70,000`, fonts
`81,364/100,000`, shipped store scripts `227,991/470,000`, and store source
`522,868/600,000`; no budget changed. Store bundle
`dist/assets/storeCaptureBundle-BElCPPAm.js` is `250,643` bytes, SHA-256
`2EBC6E66DB21BA6B162686D79E678F1B169821AF0CF1313DA14644483AF24F35`,
and is byte-identical in both native projects. Android debug artifact
`output/Otlobli-v86.224-build-1088-Android-debug.apk` is `11,113,872` bytes,
SHA-256 `1AC514F19E6A736DFBE86E4A966C7E061B020962BD59FDA40402AA5CC702D9A5`.

Signed workflow run `32657648658` from commit `7b87dc8` passed clean dependency
patching, every release guard/budget, Apple Distribution archive/export,
production-asset and signature/profile/auth checks, Apple `VERIFY` and `UPLOAD`
with no errors, processing, and internal distribution. Delivery UUID is
`941e996f-a127-4dc0-b7d2-77a113988006`. Exact build `86.224 (1089)` is
`VALID`/`IN_BETA_TESTING`; `Otlobli Internal` is verified as an all-builds group
and the expected tester state is `INSTALLED`. GitHub artifact ID `9497976071`
is `25,118,233` bytes with digest
`sha256:a0e6e503a93f7420da54762b029e96a37fd1f5fd0edce53559ca61ca8377cfd5`.
Downloaded IPA
`output/testflight-v86.224-build-1089-run-32657648658/otlobli-v86.224-build-1089-testflight.ipa`
is `10,460,230` bytes, SHA-256
`5C40665247BB41662FDEFBA2F40FECC01535A91417EE9338C79B8C0E695A6ADB`;
the dSYM is `14,858,923` bytes, SHA-256
`2E9CB1B2A36BA05BE35038AD5F39B1D73796D5CF3EC3B754BDCAE156CDFFDC00`.
Public App Store submission was deliberately skipped.

Real-device acceptance remains mandatory: Temu product -> Home must preserve
Back; SHEIN must start with the Admin-selected region and open several products
without a drawer/spinner; test an order product, five background/resume cycles,
and a separate cold launch. A real weak/old Android acceptance is not claimed.

# v86.223/1088 — long Temu recording and Qatar address completion (2026-08-23)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Marketing remains `86.223`; the new
unreleased local candidate is iOS build `1088` and Android build `1087`.

The latest archive `WhatsApp Unknown 2026-08-23 at 6.24.17 PM.zip` was safely
extracted under `output/video-analysis-20260823-182417`. Both 384x848/60fps
recordings were inspected: Temu is 58.538s/3272 frames and SHEIN is
39.153s/2348 frames. The Temu recording proves three runtime defects rather
than a slow iPhone: WebKit hides the green native Back during navigation and a
bfcache Home restore did not directly republish it; hashed Temu header tabs
painted before delayed cleanup; and the cleanup walked nearly every visible
DOM container repeatedly, including forced scans during scroll/navigation.
The SHEIN recording proves Qatar is already the country while the drawer is
advancing through Al Daayen and the zone level; the fixed 12-second deadline
closes that still-progressing drawer and makes the next Add repeat the flow.

The wake handler now calls `ensureBackButton()` immediately after resetting
the native-state dedupe key. Temu's observed `topTabContainer > tab-*` cells
are hidden by document-start CSS, the scroll-forced and navigation-forced
blocker scans are removed, the remaining fallback scans semantic popup/control
candidates instead of every `div/section/nav/header`, and repeated product
vital consumers share one 240ms measurement. Search, product capture, Add,
navigation, and account-route exceptions remain present.

SHEIN now recognizes a country name stored in `addressCookie.value` (including
Qatar). Region repair remains Add-only and fail-closed, but its escape is based
on 16s of no progress with a 36s absolute ceiling on normal devices (20s/45s
on low-end devices), so live municipality/area/zone progress no longer loses
the drawer at a fixed 12s. The Add copy now accurately says it is completing
the shipping address inside the configured country; it no longer implies that
Qatar itself is wrong. The signed address remains mandatory before capture.

The earlier order-product correction is included: a product in `طلباتي`
enters the Home/store surface immediately and opens there, while native Back
returns to the same order. Payment, wallet, completed-order, auth, backend,
native recompose timing, and the `JSON.stringify` region comparison are
unchanged.

Validation passes: targeted ESLint has zero errors (16 established App hook
warnings), TypeScript, release/auth/security guards, SHEIN freeze guard, Temu
size/store-surface guards, full production build, postbuild hardening, low-end
performance budget, Android/iOS Capacitor sync, three-root production scan, and
Android `assembleDebug`. Budgets are startup/largest JS `659,073/720,000` and
`/1,200,000`, total JS gzip `264,581/370,000`, CSS `69,968/70,000`, fonts
`81,364/100,000`, shipped store scripts `228,123/470,000`, and store source
`539,060/600,000`; no limit changed. Store bundle
`dist/assets/storeCaptureBundle-m9EUWutG.js` is `250,775` bytes, SHA-256
`C51AB87CD9F533ABCB447AD25DCC88B2B4C529610ADF0B4A48AB80CA53BDEACC`,
and is byte-identical in both native projects. Android debug artifact
`output/Otlobli-v86.223-build-1087-Android-debug.apk` is `11,113,956` bytes,
SHA-256 `E4B0FD79261D2D2BB9C5C3267703500573EB518060C5962DCA18C074FFCA8E45`.

Signed workflow run `32651898752` from commit `1d3aab7` passed Apple validation,
upload, processing, and internal assignment. Delivery UUID is
`7cc28dc8-0324-4831-8864-ce8eab63c896`; exact build `86.223 (1088)` is
`VALID`/`IN_BETA_TESTING` with expected tester state `INSTALLED`. GitHub
artifact ID `9496522621` is `25,119,065` bytes with digest
`sha256:057ffd767e1f9be248f3c6f65a12a2ba803e918aeb224ba1941a56b71869ed4b`.
The local artifact download was interrupted before an IPA hash could be
verified, so none is claimed. No public App Store submission was made. The
user's subsequent physical test rejected this candidate as recorded above.
Real-device acceptance remains required on iPhone 16 Pro Max: repeat the
recorded Temu product/Home/rapid-scroll sequence, confirm the green Back and
both bars remain stable, complete Qatar Add through the zone number, open both
stores' products from one order, then run five background/resume cycles and a
separate force-quit/cold launch. A real weak Android acceptance is not claimed.

# v86.223/1087 — Temu Home Back, Qatar cascade, and order products (2026-08-23)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Marketing stays `86.223`; this release
candidate is iOS build `1087` and Android build `1086`. The production web
bundle is synchronized to both native projects.

The attached 8.25-second, 384x848, 60fps recording was inspected across all
495 frames. It proves that SHEIN already had Qatar selected: the cascade showed
`قطر`, then `الضعاين`, then `الضعاين`, and finally `رقم المنطقة اختر`. At the
last level the option list was temporarily empty, but the old fallback scanned
the entire drawer, mistook the visible Qatar header tab for a country option,
clicked it, and reset the cascade to its first level. Country discovery now
excludes header/cascade tabs, and country fallback is allowed only before a
multi-level cascade has begun. The Add-only signed-address gate and all region
validation remain intact.

Temu's Back persistence is corrected at route classification. The previous
implementation compared Home to the first session path; Temu may normalize or
redirect that locale path, so a later real Home was classified as an inner
page and the green native exit disappeared. Temu now treats only its actual
root/locale roots (`/`, `/qa`, `/qa-en`, etc.) as Home. Product, search,
category, channel, and other keyword-bearing routes remain inner routes. The
existing bounded coordinator republishes the state; no reload, timer, polling,
observer, DOM scan, navigation interception, or WebView recreation was added.

Products in the currently open order are now full-card semantic buttons. A
same-store product opens in the already-warm store WebContent; a cross-store
product uses the existing serialized store switch and still refuses to violate
an open group-cart boundary. The WebView Back contract now supports `orders`
in the React coordinator, dedicated SHEIN iOS browser, and patched Capgo iOS
browser, returning to the same `tracking` screen and preserving the selected
order. Cart return behavior remains unchanged. Missing source links give an
explicit notice and cannot trigger an empty navigation. Payment, wallet,
completed-order state, auth, and backend behavior were not changed.

Local verification passes: targeted ESLint has zero errors (16 established
hook warnings), TypeScript, every release/auth/security/SHEIN/Temu/store guard,
production build, low-end performance budget, Android/iOS Capacitor sync,
three-root release-artifact scan, Android `assembleDebug`, and responsive
Playwright inspection at `393x852`. Accessibility inspection exposes the two
test products as named buttons for their respective stores. Budgets are
startup/largest JS `658,830/720,000` and `/1,200,000`, total JS gzip
`264,422/370,000`, CSS `69,968/70,000`, fonts `81,364/100,000`, shipped store
scripts `227,679/470,000`, and store source `536,917/600,000`; no limit changed.

Store bundle `dist/assets/storeCaptureBundle-fmt322U7.js` is `250,324` bytes,
SHA-256 `0386A1E947E05DE72653194B00EB5D8C28B07A16243BA63D41C19F095CF76149`.
Android debug artifact
`output/Otlobli-v86.223-build-1086-Android-debug.apk` is `11,113,744` bytes,
SHA-256 `A0A0A5E353FF306C04CD0B19E41313780C606ECEE97878F7CC2C80293F579100`.
Initial workflow run `32646164142` stopped at `npm ci` before any archive,
signing, or Apple upload because a manually edited patch hunk was unparsable.
The Capgo patch was regenerated from the installed dependency; a fresh
`npm ci` now applies all three patches cleanly, followed by another full build,
both native syncs, Android assembly, and artifact scan.
Signed workflow run `32646548641` from commit `ae9cdad` passed clean patch
installation, all release guards/budgets, Apple Distribution archive/export,
production-asset and signature/profile/auth checks, Apple `VERIFY` and `UPLOAD`
with no errors, processing, and internal distribution. Delivery UUID is
`0d57c10d-7a8f-447a-8aee-1acfa08debcb`. Exact build `86.223 (1087)` is
`VALID`/`IN_BETA_TESTING`; `Otlobli Internal` is verified as an all-builds
group, and the expected tester state is `INSTALLED`. GitHub artifact ID
`9495120142` is `25,118,712` bytes with digest
`sha256:127b87e071cc819c55dfabcc935bf515d08a4113db31e0e3fdd27bac4bd3acc7`.
Downloaded IPA
`output/testflight-v86.223-build-1087-run-32646548641/otlobli-v86.223-build-1087-testflight.ipa`
is `10,459,976` bytes, SHA-256
`CC1F0BE1A770EA166BDB65FFCBADB15561BBB571237733D3695E788FC7038574`;
the dSYM is `14,858,751` bytes, SHA-256
`8045EECF8D5B5F76D21DF80954986B6861DF2B34F91D9AE348F93AA534E2F335`.
No public App Store submission was made; draft `86.223` remains on build `1085`
until physical acceptance and owner-controlled store metadata are complete.

Real-device acceptance is still required: on iPhone 16, verify Temu
product -> Home restores the green Back button; SHEIN Qatar Add reaches and
selects the zone number without returning to the first tab; SHEIN and Temu
order-product taps open the correct PDP and native Back returns to the same
order. Also perform the mandatory five background/resume cycles and a separate
force-quit/cold launch. A real weak/old Android acceptance is not claimed.

# v86.223/1086 — iPhone Back placement and Temu persistence (2026-08-23)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Marketing version remains `86.223`;
iOS source is build `1086`, while Android deliberately remains `86.223/1085`.
The final web bundle is synchronized byte-for-byte to both native projects.

The iPhone green native Back button is now 14pt lower than its former
safe-area-relative position in both browser implementations: the dedicated
SHEIN browser and the Capgo browser used by Temu. Fourteen points is the
requested approximate quarter-centimetre adjustment on iPhone 16; the button
remains 44x44pt, right-anchored, and accessibility-labelled. No native
foreground/recompose timing or WebView lifecycle behavior changed.

Temu's disappearing Back button had a deterministic back-forward-cache cause:
native code hides the button at provisional navigation, then Temu can restore
Home with the old JavaScript state-deduplication key still present. The restored
page therefore skipped re-sending the identical visible state. On `pageshow`
and visible wake, the document-start bootstrap now clears only that dedupe key;
the existing bounded coordinator then publishes the current state once and the
native button reappears. No reload, new timer, polling loop, observer, or DOM
scan was added.

Store navigation now explains the already-supported store-switch gesture
directly beneath `الرئيسية` with `اضغط مرتين للتبديل`, and exposes the full
Arabic instruction through the button's accessible name. The established
320ms double-tap route is unchanged: one tap remains inert and two quick taps
open Otlobli's store chooser without destroying the parked store session.
The production navigation style key is `v86.223.1` so an already-mounted bar is
upgraded safely.

Signed workflow run `32642833471` from commit `692c835` passed clean patch
installation, all release guards, Apple Distribution archive/export,
production-asset verification, signature/profile/auth callback checks, Apple
`VERIFY` and `UPLOAD` with no errors, processing, and internal distribution for
exact build `86.223 (1086)`. Delivery UUID is
`eac22189-ddc5-4089-b682-176f60569c10`; Apple reports `VALID` and
`IN_BETA_TESTING`, the `Otlobli Internal` all-builds group is verified, and the
expected tester remains `INSTALLED`. GitHub artifact ID `9494161426` is
`25,115,824` bytes with digest
`sha256:25c860d4410387f92bc6a42d4b03c61dd338a4bcd0532f6c29685ee642ce992b`.
The accepted IPA is downloaded at
`output/testflight-v86.223-build-1086-run-32642833471/otlobli-v86.223-build-1086-testflight.ipa`;
it is `10,459,456` bytes, SHA-256
`A7708933F753567509EE80456754BC30797DA698EE0E4A5010227C6C6A3F9AD1`.
Its dSYM is `14,858,667` bytes, SHA-256
`CA1FF14EB740065CEF6034DE27FF8683E8D4E994C6B2A760A8C460FBF3ABF36D`.
App Store submission was intentionally skipped: draft `86.223` remains linked
to accepted build `1085` until this new UI behavior is accepted on the real
iPhone and the owner's missing store metadata is completed.

The user reports that the v86.222 physical test is working and asked to remove
all temporary experimental/diagnostic tooling and publish to the App Store.
The tested product-navigation, native iOS Back, post-load blockers, and
Add-only signed-region behavior are unchanged. Functional acceptance of the
reported issue is recorded from the user; the separately mandated evidence of
five iPhone 16 background/resume cycles plus a force-quit/cold launch was not
enumerated, and weak/old Android acceptance is not claimed.

The store flight recorder is fully retired rather than build-disabled:
`storeScriptDiagnostics.ts`, its stub, fixture renderer, App imports/state/
listeners, Vite alias/env flag, Workflow input, navigation feature flags, and
old freeze/tap/price/region probe modules are deleted. The device-rejected
document-start protection scans and 250ms protection timer are deleted from
the navigation source. The production bootstrap now does only viewport setup,
Otlobli bar mounting/touch routing, and wake restoration; the established
post-load blocking/capture/session runtime remains active. Optional region
probe calls were also removed from the injected script. The customer support
screen's consent-based issue report remains a production support feature, not
the retired SHEIN test panel.

The iOS workflow no longer accepts a diagnostic-build input. It now has an
explicit `app_store_submission` action. When authorized, the signed TestFlight/
App Store archive is uploaded, processed, linked to an automatically released
iOS App Store version, added to a review submission, and submitted through the
App Store Connect API. The operation is idempotent and fails with Apple's exact
metadata/review blockers rather than inventing privacy URLs, screenshots, or
legal metadata. Signed run `32611345045` from `7d99f13` passed archive, export,
signature/auth verification, Apple transport, processing, and internal
TestFlight assignment for exact build `86.223 (1085)`. Its artifact is
`otlobli-ios-v86.223-build-1085-testflight`, ID `9485690696`, size
`25,115,693` bytes, GitHub digest
`sha256:56008db6dfbcce1fc84b72bae45b19d3d923f8dc34e0089bd21ac0039eb3cf62`.
The first App Review attempt stopped before changing any store-version data:
Apple returned 409 because another iOS App Store version already occupies the
editable slot. The submitter now lists all iOS versions and safely renames the
single `PREPARE_FOR_SUBMISSION` draft to `86.223`, preserving its localized
metadata/review details, then replaces only its selected build. It never deletes
a draft or guesses metadata. Retry `32611795204` reused draft `1.0` as
`86.223`, linked build `1085`, and created review submission
`e5e27b8a-b628-4116-b135-361b91266929`. Apple then refused the review item
because store prerequisites are incomplete across screenshots, version
localization, age rating, app info/localization, data usage/privacy, app-level
details, and price. The raw response collapsed the field-level entries, so the
submitter now serializes every associated Apple error and a lightweight
`ios-app-review.yml` workflow can retry/inspect the already processed build
without rebuilding or uploading another IPA.

Run `32612073248` verified the final live App Store state without re-uploading:
version `86.223` is `PREPARE_FOR_SUBMISSION`, exact build `1085` is already
linked, and the same draft review submission remains. Apple's complete
prerequisite list is: description, keywords, support URL, iPhone 6.5-inch and
iPad Pro 12.9-inch screenshots, primary category, App Review contact/details,
copyright, content-rights declaration, published App Privacy/data-usage
answers, price, privacy-policy URL, and all 22 required age-rating questionnaire
answers. These are owner/legal/storefront decisions and were deliberately not
invented. The App Store review item therefore has not been submitted.

Apple upload delivery UUID is `98370121-bfc3-4e6e-943c-90ceaad9021b`;
App Store version ID is `a03a0acc-2555-44aa-accd-78429a3e6a39` and review
submission ID is `e5e27b8a-b628-4116-b135-361b91266929`. The exact accepted
IPA downloaded to
`output/app-store-v86.223-run-32611345045/otlobli-v86.223-build-1085-testflight.ipa`
is `10,458,318` bytes, SHA-256
`1EDA4263A97F496E2FDB594E1395E0D297E5D84A1E90B3E110BC220E65F1B0EC`.
Its dSYM archive is `14,858,055` bytes, SHA-256
`268DC270242E1DE5C38831158ADDC791A4D6C5C46DEC8845E3392ABBA1BE6057`.

Local validation passes: clean dependency installation with all patches,
all release/auth/security/store/Temu guards, TypeScript, executable/minified
SHEIN freeze checks, production build, performance budgets, Android/iOS sync,
post-sync release artifact scans, and Android `assembleDebug`. Generated
`dist`, Android, and iOS assets contain none of the retired recorder/probe
markers. Budgets are startup/largest JS `657,135/720,000` and `/1,200,000`,
total JS gzip `264,021/370,000`, CSS `69,990/70,000`, fonts
`81,364/100,000`, shipped store scripts `227,372/470,000`, and store source
`535,270/600,000`.

Store bundle `dist/assets/storeCaptureBundle-Clt5YaMD.js` is `250,014` bytes,
SHA-256 `0AA55B63288CA8DDC650E4989CF7FB7A0B3AA908EC647D6165EA9DCBCA7C0A42`.
Main bundle `dist/assets/index-vzZNXC5I.js` is `657,135` bytes, SHA-256
`44575BB609C3917381F956B3C74CE68958B1BD63284BE911FAC1841976670F1A`.
Local Android debug APK
`android/app/build/outputs/apk/debug/app-debug.apk` is `11,125,147` bytes,
SHA-256 `A19DB77002BA040FB5FC68090F9496881280DCC12FDEA9E10E8A52779187B74E`.
No native lifecycle/recompose timing, payment, wallet, completed-order,
authentication, database, or backend behavior changed.

# v86.222 — device-led safe navigation and Add-only region repair (2026-08-23)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Source is `86.222/1084`, locally
validated and synchronized to Android/iOS as an internal diagnostic candidate.
It is delivered to internal TestFlight but is not real-device acceptance.

The physical v86.221 flight recorder produced the first exact cause: the
persistent PDP spinner did not appear before N6, while enabling N6 immediately
and consistently restored it. N6 ran three DOM/layout protection scans from document-start every
250ms until runtime readiness, for up to 180 runs. v86.222 makes
`navigationEarlyProtection` fail-closed before reading current or stale flags.
The blocker feature is not removed: post-load `runOtlobliBlockers()` still hides
listing/native Add controls, and the normal runtime still hides SHEIN bottom
navigation and the exact signup surface.

N4 had a separate intermittent observation: initial SHEIN Home sometimes showed
SHEIN's own generic system-error page and Retry recovered. The code was creating,
styling, and repaint-reclaiming a hidden HTML Back button on iOS even though the
app-owned native UIButton is the only visible/pressed control. iOS now publishes
`otlobliBackButtonState` and returns before creating page Back DOM. The accepted
native canonical-Home exit, product history, cart priority, and 0.8s lock are
unchanged; Android/no-WebKit retains the HTML fallback.

R1 in v86.221 was cumulative and still contained N6, so it was not independent
proof against the session layer. v86.222 separates it: R1 and customer defaults
have early protection off. It also removes every region-owned PDP navigation
mutation: ordinary product browsing does not open the shipping cascade, call
document-start `location.replace`, rewrite history, or let the native URL
listener call `setUrl`. Explicit Otlobli Add remains the fail-closed boundary;
it calls `ensureSheinSaudiStore(true)` and cannot capture/add until the signed
address matches. Home can still correct an explicit administration-region
mismatch before product browsing.

The diagnostic state/storage is v4. N6 is no longer selectable; N0-N5 remain for
regression isolation and R1 is now truly free of N6. Playwright at `430x932`
verified the updated Arabic panel, interaction tree, and copy; the only console
error is the fixture's absent favicon. Evidence is
`output/playwright/v86.222-shein-safe-runtime-iphone16.png`.

Validation passes: TypeScript; targeted ESLint with zero errors and 17 existing
App hook warnings; release, security, store, Temu, and executable SHEIN freeze
guards; normal and diagnostic builds; both performance budgets; Android/iOS
sync; post-sync freeze guard; and Android `assembleDebug`. Normal budgets are
startup/largest raw JS `657,788/720,000` and `/1,200,000`, total JS gzip
`267,630/370,000`, CSS `69,990/70,000`, fonts `81,364/100,000`, shipped store
scripts `237,136/470,000`, and source `590,127/600,000`. Diagnostic startup is
`660,862/720,000` and total gzip `277,345/370,000`; the other measurements are
identical.

The store bundle is 259,916 bytes, SHA-256
`59FA5531FA693642AE32144BFE1079F06F3C8623AEEA84C094020B27BD8ABFC3`.
The v4 diagnostic chunk is 31,851 bytes, SHA-256
`2CB0CA46663DE83D67357311B405C1578536973D763C4F60068FE33C127C8A4A`.
Both and `index.html` are byte-identical in `dist`, Android, and iOS. Android
artifact `output/Otlobli-v86.222-SHEIN-safe-navigation-region-Android-debug.apk`
is 11,128,645 bytes, SHA-256
`C67D80FC2D361D497199EA0BC8438BAA67A9967C023A7FDA919BC22BDF779AAB`,
package `com.otlobli.app`, version `86.222/1084`.

Signed workflow run `32608307685` from
`35bcaeba71b79a87d51b0357a2548e7c1f182214` passed the diagnostic build,
sync, universal device/auth/generated-asset checks, Apple Distribution archive
and export, signature/profile/callback verification, Apple validation, upload,
processing, and internal distribution. `VERIFY SUCCEEDED` and
`UPLOAD SUCCEEDED` had no errors; delivery UUID is
`e0e18aeb-3fd0-4362-9602-f9ec451e8227`. App Store Connect verified exact
`86.222 (1084)` as `VALID`/`IN_BETA_TESTING`, internal all-builds group
`Otlobli Internal`, and tester `mhm1981dx@gmail.com` state `INSTALLED`. No
public submission occurred.

GitHub artifact `9484859515`,
`otlobli-ios-v86.222-build-1084-testflight`, is 25,129,358 bytes with digest
`sha256:d3090e83f0056fb95ac3487a8057a548fc65d1fee7aa99ec024cd28a9c213d47`.
Downloaded signed IPA
`output/otlobli-ios-v86.222-testflight-run-32608307685/otlobli-v86.222-build-1084-testflight.ipa`
is 10,472,249 bytes, SHA-256
`D964F2E4264D87EC1750F2E5BE2C505D159FBEBD097CE0255E6AC367EF51CB7C`.
Its dSYMs ZIP is 14,858,055 bytes, SHA-256
`9913656EC42E8C4A0FC7EA85A542BAB716774BC4BA33D2ED2F6187A1471A9666`.
Signed-IPA inspection confirms the exact store/diagnostic hashes above plus
embedded provisioning and CodeResources.

No native lifecycle/recompose, payment, wallet, completed-order, authentication,
or backend behavior changed. Physical acceptance is pending: first cold-open
Home once, open several products with N5, use native Back to Home, then test R1
and press Add once to verify region repair starts only there. Five iPhone 16
background/resume cycles and one separate force-quit/cold-launch remain required.

# v86.221 — professional SHEIN navigation flight recorder (2026-08-23)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Source is `86.221/1083`. This is an
internal diagnostic candidate, not a claim that the list-to-PDP spinner or the
region restart is fixed.

The user installed `86.220/1082` and reproduced the same product spinner. This
physically rejects v86.220 and corrects its diagnosis: the earlier A-D result
proved only that the broad Navigation group contains the trigger. v86.220
removed the product fallback and chunk bridge but retained viewport mutation,
runtime bar creation, nav touch routing, Back state, document-start mounting,
and the bounded early DOM protection scans. The exact sublayer remains
unproven.

v86.221 replaces the broad and misleading test with one ordered flight
recorder. `N0` starts from the device-proven composition: capture+blocking on,
all navigation and session/region off. `N1` adds viewport only; `N2` runtime bar
painting; `N3` bar-button touch routing; `N4` product Back; `N5` document-start
bar mounting; `N6` early bottom-nav/native-add/signup protection; `R1` finally
adds session/region. Every profile recreates one WebView while preserving the
site-owned persistent data store. The old session-interaction branch now also
respects `navigationBar`, so an intentionally disabled bar is not repainted as
an inert ghost.

The Arabic bottom sheet records, without changing navigation, whether the
physical product tap reached the page, the URL changed, the product document
loaded, and a PDP surface painted. Three bounded checkpoints run only after a
product tap. Trace storage is capped at 40 entries and error capture at six;
there is no `setInterval`, `MutationObserver`, persistent DOM scan, or React
state/render loop. Results persist in Otlobli host storage—not SHEIN storage—
and `نسخ التقرير الكامل` creates one report with all N0-R1 outcomes and the
last 12 events. The normal customer build still aliases the module to a 397-byte
marker-free stub.
The iOS workflow's existing `store_script_diagnostics` input now names this
flight recorder explicitly; it remains false by default and is enabled only
for the internal diagnostic delivery.

Validation passes: TypeScript; targeted ESLint with zero errors (17 existing
App hook warnings); WebKit/iPhone visual and interaction fixture with zero
console errors; accessibility/design review; release/security/store guards;
the expanded executable freeze guard; normal and diagnostic builds; performance
budgets; both native syncs; post-sync freeze guard; and Android
`assembleDebug`. Repository-wide ESLint alone is red because it descends into
two old extracted IPA `native-bridge.js` files under ignored `output/`; changed
source has no lint errors.

Normal-build budgets are startup/largest raw JS `657,770/720,000` and
`/1,200,000`, total JS gzip `267,526/370,000`, CSS `69,990/70,000`, fonts
`81,364/100,000`, shipped store scripts `236,890/470,000`, and source
`588,366/600,000`. Diagnostic totals are startup `660,872/720,000` and total
JS gzip `277,284/370,000`; all other measured budgets are the same. Normal
store bundle is 259,670 bytes, SHA-256
`DBA9812E2F48F5FA190EECBBE4DB7C8EDD62B47BB3F6A07A83790505C3D9E477`.
The diagnostic chunk is 32,159 bytes, SHA-256
`575FFF5AFE0E2E806E879275168B8A9F8CC294F2CD8646428E1BDA925F3E973D`.
Both files and `index.html` are byte-identical in `dist`, Android, and iOS.

Android artifact
`output/Otlobli-v86.221-SHEIN-navigation-flight-recorder-Android-debug.apk`
is 11,352,143 bytes, SHA-256
`F9AEF7A24F78B109827FA4D99111CDE24149F7AB5C8981EDD38002495C57B032`.
Signed run `32606619539` from
`dfc8d5acc2f6bdfa21a1ef554f81a702c500fd59` passed diagnostic build/sync,
universal target and auth checks, Apple Distribution archive/export, generated-
asset inspection, signature/profile/callback checks, Apple validation, upload,
processing, and internal distribution. `VERIFY SUCCEEDED` and
`UPLOAD SUCCEEDED` had no errors; delivery UUID is
`048fe33e-90b2-44d8-8db9-432234e0fe33`. App Store Connect verified exact build
`86.221 (1083)` as `VALID`/`IN_BETA_TESTING`, internal all-builds group
`Otlobli Internal`, and expected tester `mhm1981dx@gmail.com` state
`INSTALLED`. No public submission occurred.

GitHub artifact `9484352744`,
`otlobli-ios-v86.221-build-1083-testflight`, is 25,129,574 bytes with digest
`sha256:49e95661c5a069b21edf362b7bf6a29afe4ca5ae823b13b51f7399ca97727f02`.
Downloaded signed IPA
`output/otlobli-ios-v86.221-testflight-run-32606619539/otlobli-v86.221-build-1083-testflight.ipa`
is 10,472,179 bytes, SHA-256
`FA3DBA27FE713D5364190F48024CE870701C20740A22C33EE4D59852538C4509`.
dSYMs ZIP in the same folder is 14,858,053 bytes, SHA-256
`811B59574057C146C0345A05214853910A4FB4587B9E67F86D1D5845087E268E`.
Signed-IPA inspection confirms the exact diagnostic/store chunks above plus
embedded provisioning and CodeResources.

Real-iPhone acceptance remains unperformed. On the iPhone, start at N0, open
one product and mark `فتح المنتج` or `بقي يحمّل`, then proceed in order only
until the first failure and copy the report. Test R1 last for the separate
region restart. Five background/resume cycles and a separate force-quit/cold-
launch test remain mandatory after the responsible profile is identified.

# v86.220 — rejected SHEIN navigation hypothesis (2026-08-23)

The group-level A-D result was useful: disabling Navigation opened the same
products. v86.220 then removed the global product `touchend` fallback,
500ms `location.assign`, and chunk bridge while preserving the rest of the
Navigation group. It also made automatic region-repair exhaustion country-
session scoped. Local guards/builds passed, but these facts did not prove which
Navigation sublayer caused the spinner.

Signed run `32604307896` from `3fa4e74` passed Apple verification/upload with
delivery UUID `d5138ae7-92a0-43c7-a191-a8b3c7a1cc0f`. App Store Connect
confirmed exact build `86.220 (1082)` as `VALID`/`IN_BETA_TESTING` in internal
all-builds group `Otlobli Internal`; tester `mhm1981dx@gmail.com` was
`INSTALLED`. Artifact `9483810169`,
`otlobli-ios-v86.220-build-1082-testflight`, is 25,119,202 bytes with digest
`sha256:12c8e0c51df882698ac20aa49d49919182c5a1ddb0e85fb0f106f84ddab86fde`.
No public submission occurred.

The user installed that TestFlight build and immediately reproduced the same
PDP spinner. v86.220 is therefore physically rejected. Its removed fallback
and chunk bridge are not the exact cause; all retained Navigation sublayers
must be isolated before another fix.

# v86.219 — expose diagnostic A-C below the native cover (2026-08-23)

The user's first physical `86.218/1080` attempt never reached stage A: iOS
remained on Otlobli's native `جاري تجهيز المتجر…` cover. This rejects v86.218
as a usable isolation build but says nothing yet about SHEIN's raw PDP.

The cause is exact. The diagnostic panel posted `sheinPageInteractive` and the
React listener accepted `diagnostic: true`, but the independent native iOS
cover correctly accepts only a full production coordinator payload. A-C omit
session/region by design, so they can never produce that payload and the cover
can never release. The fix does not weaken or edit the native gate: only an
explicit diagnostic build opens A-C with `otlobliLoadingCover=false`. D and
every normal customer build keep the existing policy/region-gated cover. The
decision is the single primitive expression
`!STORE_SCRIPT_DIAGNOSTICS || (runtime && session)` evaluated once per WebView
open; it adds no timer, observer, DOM scan, state, render, or WebView.

Source is `86.219/1081`. TypeScript, diff check, the freeze guard, all
release/security/store guards, targeted ESLint (0 errors; 17 existing hook
warnings), normal marker-free build/artifact scan, and diagnostic
marker-required build/artifact scan pass. Diagnostic budgets are startup
`659,105/720,000`, total JS gzip `273,058/370,000`, CSS `69,990/70,000`, fonts
`81,364/100,000`, shipped store scripts `240,400/470,000`, and source
`569,544/600,000`. Android and iOS are synchronized to the diagnostic build;
the diagnostic chunk remains byte-identical across all three at SHA-256
`241CD059EAA8AA77216513218FB8E920247D7BB2EA20898E328E1E7786E87EED`.
Android `assembleDebug` passes. Artifact
`output/Otlobli-v86.219-SHEIN-AB-cover-fix-Android-debug.apk` is `11,123,713`
bytes, SHA-256
`B54BBE27B0E8B182F9A8028ED721F945DA05866CBB337C83D5B7D2F2361371C7`,
package `com.otlobli.app`, version `86.219/1081`.

Signed run `32600407694` from
`997baeb003e331bc717aa9afb08a533521dc6d2b` passed the diagnostic build,
sync, Xcode archive/export, signature/profile/auth checks, Apple validation,
and upload. `VERIFY SUCCEEDED` and `UPLOAD SUCCEEDED` had no errors; delivery
UUID is `9824804a-63a3-4f85-9fcd-c69371869671`. App Store Connect then
confirmed exact build `86.219 (1081)` is `VALID` and `IN_BETA_TESTING`, the
strictly internal `Otlobli Internal` group has all-build access, and the
expected tester membership is `INSTALLED`. No public App Store submission was
made. Artifact `9482813304`,
`otlobli-ios-v86.219-build-1081-testflight`, is `25,125,297` bytes with digest
`sha256:021c434924c02540c69e5c91aa45386c1c2b5242503ee2c5bc95ffa1987eb252`.
Downloaded signed IPA
`output/otlobli-ios-v86.219-testflight-run-32600407694/otlobli-v86.219-build-1081-testflight.ipa`
is `10,468,015` bytes, SHA-256
`A873B2C64EAF44F630114CCC58B222344ACE07D1875FEA9A18D2E28980E03F47`;
inspection confirms the diagnostic chunk, signed provisioning, and compiled
`runtime && session` cover condition.

All real-device acceptance for v86.219 remains pending. The next device gate
is only: update, enter SHEIN, confirm A shows the raw page and `فحص` button,
then try the same PDP. Do not progress to B/C/D or resume-cycle acceptance
until A is actually visible.

# v86.218 — one-build SHEIN A-D isolation (2026-08-22)

Continue in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Current source is `86.218/1080`.
This is an internal TestFlight diagnostic, not a customer release and not a
claim that the iPhone product spinner or repeated region drawer is fixed.

The user's physical rejection of `86.217/1079` closes the next speculative-fix
lane. v86.218 restores the already-existing script-isolation control on top of
the current v86.217 code instead of copying an older branch. One build performs
the proposed sequence: A evaluates no normal store runtime (only the mandatory
privacy compatibility and a small painted-page/exit panel); B enables product
capture only; C adds blocking; D restores navigation plus session/region. Each
change recreates one WebView while preserving SHEIN's persistent website data,
cookies, storage, and completed verification. A is the fresh default under a
new v2 preference key.

The host URL/region normalizer and policy/navigation document-start scripts are
off whenever the diagnostic session/navigation flags are off. The panel's own
painted-page signal releases the native cover in A-C, so the page under test is
never hidden while waiting for the deliberately absent coordinator. Normal
customer builds resolve the diagnostic dynamic import to a marker-free stub;
the production artifact guard proves no panel/message marker exists. The iOS
workflow exposes one explicit boolean input and only includes the panel when it
is true.

No extraction, blocking, session, coordinator, payment, wallet, completed-
order, auth, native WebView, detach/reattach, resume timing, or
`JSON.stringify` region-equality implementation was changed. The A-D executable
guard parses all four exact scripts and proves A has no `tick()`, B capture
only, C capture+blocking without session, and D full runtime.

Local validation: TypeScript, diff check, freeze guard, all release/security
guards, normal production build plus marker-free artifact scan, diagnostic
build plus marker-required scan, and unchanged performance budgets pass.
Diagnostic budgets are startup `659,081/720,000`, total JS gzip
`273,049/370,000`, CSS `69,990/70,000`, fonts `81,364/100,000`, shipped store
scripts `240,400/470,000`, and source `569,544/600,000`. Android/iOS syncs are
byte-identical for the diagnostic chunk SHA-256
`241CD059EAA8AA77216513218FB8E920247D7BB2EA20898E328E1E7786E87EED`.
Android debug build passes; artifact
`output/Otlobli-v86.218-SHEIN-AB-isolation-Android-debug.apk` is `11,123,705`
bytes, SHA-256
`18E7AE0DBE087BC9885FE66F274E2F805C1C2ED80673AECCC7E8A25295714AC7`,
and metadata is `com.otlobli.app` `86.218/1080`.

Playwright at `430x932` proves A starts with every normal group off and B/C/D
toggle the intended flags. Evidence:
`output/playwright/v86.218-shein-ab-panel-iphone16.png`. The only console error
was the fixture's absent favicon.

Signed run `32598213562` from
`0bd6b144fc13315947fb3de987c142271b741de4` passed Xcode export, signature,
profile, auth, Apple validation, and upload. `VERIFY SUCCEEDED` and
`UPLOAD SUCCEEDED` had no errors; delivery UUID is
`9527dd4a-cf31-46f7-8e98-25d29678e6f8`. Artifact `9482209312`,
`otlobli-ios-v86.218-build-1080-testflight`, is `25,125,417` bytes with digest
`sha256:f08b05a49172fb4a0fb4b2fa342567163a4953ec9097a78f7c2a7660c5121f62`.
The downloaded signed IPA at
`output/otlobli-ios-v86.218-testflight-run-32598213562/otlobli-v86.218-build-1080-testflight.ipa`
is `10,468,001` bytes, SHA-256
`1FE4A06731BB86A24AB73BC9ED183A25788D2F95CAB3B37364515EDBC7AF158D`.

App Store Connect API verification run `32599164674` from `79154c3` confirms
the exact `86.218 (1080)` build is `VALID`, the strictly internal
`Otlobli Internal` group has all-build access, the expected tester is a member
with state `INSTALLED`, and the build state is `IN_BETA_TESTING`. The workflow
now defaults future TestFlight uploads to upload-and-distribute, while its
`distribute-existing` mode performs no upload and can verify/repair only the
matching internal build/group/tester relationship. It rejects a non-internal
group or enabled public link. No App Store review submission was made.

Real iPhone acceptance remains entirely unperformed. Update from TestFlight,
test the same PDP in A first, and only if it opens progress through B, C, then
D. Record the first failing stage. The protected five background/resume cycles
and separate force-quit/cold-launch test remain required after the responsible
stage is isolated.

# v86.217 — live verification pass-through and v86.213 region gate (2026-08-22)

Continue in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Current source is `86.217/1079` and is
synchronized to Android and iOS. It is not uploaded to TestFlight; a new signed
upload still requires exact approval for `86.217/1079`.

The exact `86.213 -> 86.214` boundary is commit
`04d274fcc834125facb66f0dca703c2c44785493` over
`5a2788ccb7515cce93ee9ded102e6635dfc4ac0a`. Product extraction and
`storeBlockingScript.ts` did not change there. The region-visible regression
came from v86.214's early visual-ready release while the signed native address
cascade was still active. v86.217 removes that pre-region release: an active
product repair stays behind the existing cover until signed readiness or its
bounded 12-second timeout, matching the v86.213 gate. Home with an absent/unknown
address no longer opens or reopens the shipping drawer; Home repairs only a real
country mismatch from the administration setting. Unsigned product routes still
run the native address cascade before capture.

The old product spinner also had a separate deadlock consistent with the user's
human-verification hypothesis. The injected detector persisted
`__otlobliHumanCheckPendingAt` for 15 minutes, then required
`sheinPageLooksInteractive()` before clearing it. A spinner could therefore be
treated as a verification page forever, pausing region, blocking, navigation,
and capture. Verification is now live-only: while a visible/URL challenge exists
all Otlobli interventions pause; as soon as it disappears the same coordinator
continues immediately, even if the product is not interactive yet. No challenge
marker, guide overlay, Otlobli-node deletion, drawer unlock, body mutation,
automatic click, reload, or solution is retained.

The extraction implementation, add-to-cart messages, blocking rules, admin
`JSON.stringify` region comparison, protected iOS/Android lifecycle/recompose,
payments, wallet, completed orders, and authentication are unchanged. The
audited coordinator SHA-256 is
`42F9A1282956DDBF91D44AC0FED7F4727BFD3D240F66DBA86CBF8C3CC0AC5F6B`;
capture calls/order/cadence are unchanged.

`git diff --check`, ESLint, the expanded executable freeze guard, and full
`npm run build` pass. Budgets remain unchanged: startup/largest JS
`657,198/720,000`, total JS gzip `267,929/370,000`, CSS `69,990/70,000`, fonts
`81,364/100,000`, shipped store scripts `240,400/470,000`, and store source
`567,685/600,000`. Both Capacitor syncs and post-sync Android `assembleDebug`
pass. The synchronized store bundle is byte-identical across web/Android/iOS,
contains live resolution and Home cancellation, and contains neither the sticky
marker nor the verification guide. Android artifact
`output/Otlobli-v86.217-Android-debug.apk` is 11,117,996 bytes, SHA-256
`7A962975B923BAAF4BF5E599F1CDEF63D080C2843910CCDCD1A714F2A61BA5CC`.

Unsigned macOS/Xcode run `32567462720` passed from
`233bc4666eb3eb5d6d7259f1239335b6cd223d9d`. Production build/sync, universal
iPhone+iPad target, generated assets, `.app`, and IPA checks passed; every
development/App Store signing and TestFlight step was skipped. Artifact
`9474493487`, `otlobli-ios-v86.217-ipad-iphone-universal`, is 6,458,996 bytes
with digest
`sha256:3def52542d77c84105c9ef5d9b004a49301d429575d9a746012a6af4812fd974`.
Downloaded IPA at
`output/otlobli-ios-v86.217-unsigned-run-32567462720/otlobli-ios-v86.217-ipad-iphone-universal/otlobli-v86.217-ipad-iphone-universal-unsigned.ipa`
is 6,568,085 bytes, SHA-256
`3C272E70EFBD109304C6E917588000517AF832D0FF5051586D6D5791DDC6B17F`.
Inspection confirms `com.otlobli.app`, `86.217/1079`, iPhone+iPad, the exact
synchronized store-bundle hash, live-resolution/Home-cancellation markers, no
sticky marker/guide, and no app provisioning/signature.

All real-device acceptance remains pending. Do not claim the iPhone
product/region issue resolved until the same product is tested, followed by five
iPhone 16 background/resume cycles and a separate force-quit/cold-launch test.
Weak/old Android acceptance is also unperformed.

# v86.216 — release warm recovery from the SHEIN region loop (2026-08-22)

Continue in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Current source is `86.216/1078` and is
synchronized to Android and iOS. The user explicitly approved this exact
TestFlight upload. Signed run `32551873565` succeeded from
`3f92cc51c64629d7990a34e3f6de42c46b456be8`; Apple validation and upload both
reported no errors, delivery UUID `b38a9b39-ae06-46e1-8610-3b85bbc9c74f`.
App Store Connect finished processing and shows `86.216 (1078)` as `Testing`
inside `Otlobli Internal` (`1 Tester`, `4 Builds`). The exact tester remains
`mhm1981dx@gmail.com`; its row still says Installed `86.215 (1077)` until the
device updates. No production App Store review submission was made.

The user's 34.92-second physical iPhone video rejects `86.215/1077`: SHEIN
selects the requested area, closes the drawer, then repeatedly opens and selects
it again, while the original list→product gray spinner remains. The exact causes
were related. Warm recovery opened SHEIN Home but retained the PDP until full
signed address readiness; only visual readiness completed, so the product was
never requested. The waiting Home then ran automatic region repair; its 12s
timeout closed the drawer and its later scan started the same repair again.

v86.216 treats recovered Home only as a same-site launch pad: at policy-safe
visual readiness the host navigates the queued PDP in the same WebView. Home
region repair is skipped for that launch state, and any real automatic repair
that times out is exhausted for the same country/path until route/state changes.
The physical tap timestamp is now armed at validated `touchend`, and a chunk
failure is eligible only when it occurred after that exact tap and both are less
than 15 seconds old. A stale listing failure can no longer trigger or suppress a
later product recovery.

The protected iOS/Android lifecycle and recompose code, `JSON.stringify`
store-region equality, purchase gates, payments, wallet, and orders are
unchanged. No timer, polling loop, observer, DOM scan, WebView, or persistent
React render was added; transient routing uses a ref.

`npm run verify:shein-freeze-guard`, `npx tsc --noEmit`, targeted ESLint (zero
errors), `git diff --check`, and the full `npm run build` pass. Performance is
within unchanged budgets: startup JS `657,198/720,000`, largest JS
`657,198/1,200,000`, total JS gzip `268,868/370,000`, CSS `69,990/70,000`,
fonts `81,364/100,000`, shipped store scripts `243,384/470,000`, and source
`568,240/600,000`. Both Capacitor syncs and the post-sync Android
`assembleDebug` pass. Android artifact
`output/Otlobli-v86.216-Android-debug.apk` is 11,120,845 bytes, SHA-256
`FEFE572388DB1E830A0EA7C2B82020885576E875B6ADBAC64D82717BBAF7257D`.

Unsigned iOS run `32540635518` passed from
`7f016862fda486bbd583c085ff78b1cf8da5183d`. Production assets, version
`86.216/1078`, and universal iPhone/iPad checks passed; all signing and
TestFlight steps were skipped. Artifact `9466944399`,
`otlobli-ios-v86.216-ipad-iphone-universal`, is 6,459,819 bytes with digest
`sha256:c947c6561904c3956c7dc7e383a9429e79d1651f42400969f972aff49e386d04`.
Downloaded unsigned IPA is 6,568,990 bytes, SHA-256
`A0F5F15BF3EAC6CE1737CDF9DC79868EBB2C6AB1873124485E69D7D500393265`.

The first approved signed run `32551772188` stopped before installing signing
assets because the persisted Oracle WhatsApp sender was disconnected. The same
session `0` was reconnected through the protected localhost admin endpoint;
no message or QR was generated. Every live health field then passed and the
successful run proceeded. Signed artifact `9470342666`,
`otlobli-ios-v86.216-build-1078-testflight`, is 25,120,826 bytes with digest
`sha256:9778761428db6fc73d74a3be0142d71bfb4f6dac730ebc835c37f6ecdaa9313b`.
Downloaded signed IPA is 10,463,515 bytes, SHA-256
`65417017ECAF9886142F0DF6FD24F81C701BDACB5D9AF5DE861AED98716FAC34`.

No physical acceptance is claimed. Acceptance must update TestFlight, retest
the same product, prove no repeated region drawer, then perform five real
iPhone 16 background/resume cycles plus a separate force-quit/cold-launch test.

# v86.215 — consume the recorded SHEIN tap failure and warm Home (2026-08-22)

Continue in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Current source is `86.215/1077` and is
synchronized to Android and iOS. The user approved the current upload, and
signed run `32538654061` succeeded from
`6246ca88a1c92470b964e5eaac610ad4dc4ca8b3`. Apple validation and upload both
reported no errors; delivery UUID is `d2d4a5d0-a03b-4a17-be81-3e13de802dea`.
App Store Connect shows `86.215 (1077)` in `Otlobli Internal` and the exact
tester as Installed on iPhone 16 Pro Max / iOS 27. No production App Store
review submission was made. Real product and lifecycle acceptance still need
the user's physical test.

App Store Connect confirms the exact internal tester `mhm1981dx@gmail.com`
installed `86.214 (1076)` on iPhone 16 Pro Max / iOS 27. The user reproduced
the same list→product spinner, so v86.214 failed real-device acceptance. The
remaining edge is exact: a chunk error may occur after the product touch but
before the SPA changes `location.pathname`. v86.214 recorded it, but the
existing 500ms tap callback never consumed
`__otlobliRecoverSheinChunkOnStalledTap()` and treated the later product URL as
success. v86.215 makes one stored-error probe in that existing callback. A hit
uses the same iOS-only, 60-second, cache-only recovery; a miss continues the
normal route unchanged.

Recovery now opens the lightweight SHEIN Home first after the HTTP cache reset,
retains the queued product, then navigates to it inside the same verified
WebView. This matches the user's proven Temu→SHEIN recovery instead of
cold-loading a deep PDP after cache clear. No new timer, polling, observer, DOM
scan, WebView, lifecycle work, region rule, or purchase relaxation was added.

`npm run build` passes all release/auth/SHEIN/Temu/store guards and unchanged
performance budgets: startup JS `656,897/720,000`, total JS gzip
`268,668/370,000`, CSS `69,990/70,000`, and shipped store scripts
`243,083/470,000`. Both Capacitor syncs and Android `assembleDebug` pass.
Android artifact `output/Otlobli-v86.215-Android-debug.apk` is 11,119,208 bytes,
SHA-256
`1D51B3FCB043F63D8A4437BBF81D6A81DEB52788EDBDCF0E6D5B54AF060B5EFA`.
Unsigned iOS run `32538249134` passed from
`05b81a11ab62a836e119d04a3500768dd69cc38f`; Swift, production assets,
version `86.215/1077`, and universal iPhone/iPad checks passed. Artifact
`9466159129`, `otlobli-ios-v86.215-ipad-iphone-universal`, is 6,459,712 bytes
with digest
`sha256:55580f7a74a4b64e7069a8fd8d134388136ef0bd65ccf97c18aedb100c2b1fbb`.
Downloaded unsigned IPA is 6,568,807 bytes, SHA-256
`272C92DB84FB826140D5687A2098D03923731A3CE5F6BF7C5BCA4B800BC2FD0B`.
Every signing and TestFlight step was skipped in that unsigned run. Physical
product and lifecycle acceptance for v86.215 remains pending.

The signed artifact is `9466326356`,
`otlobli-ios-v86.215-build-1077-testflight`, 25,120,544 bytes with GitHub digest
`sha256:a8547ae98c6e3d09c7dd95cca5e10d27c017918a39409d7ee08675a68e0eb033`.
Downloaded signed IPA is 10,463,303 bytes, SHA-256
`340462372D7218E27FCAF3F5AF4DC062DD245DCA11F8D3C4EB18D8F04AB65402`.

The approved v86.214 upload had one safe preflight failure: run `32536442526`
stopped before signing because WhatsApp was disconnected. The Oracle sender was
reconnected from stored credentials through its protected local endpoint,
without a message or QR; all live health fields passed. Run `32536820362` then
succeeded from `11fdf755f7ca7d9e0e8cf35e59be068ef05f9d9b`, validation and upload
both reported no errors, and Apple delivery UUID is
`9c84ea82-e074-4a98-a2ba-20069d732600`. Artifact `9465796159`,
`otlobli-ios-v86.214-build-1076-testflight`, is 25,120,684 bytes with digest
`sha256:eea4363706e2ddc1a9a6290f6187f7eacbdfff786d51f28cb3995309eaaedb9a`.
The signed IPA is 10,463,262 bytes, SHA-256
`11730844FAC50BCF86C2D055D551827B3CBB90E3B954EEFBA74C4A6D91880DC9`.
Apple shows the upload Complete and group `Otlobli Internal` with 1 tester and
2 builds; the tester row shows Installed `86.214 (1076)`. No App Store
production review submission was made.

Apple Developer is configured under the exact Account Holder
`mhm1981dx@gmail.com`, Team `36D743K87T`. Services ID
`com.otlobli.app.signin` now uses primary App ID `com.otlobli.app`, domain
`dcicqdprtyhwmhegabay.supabase.co`, and exact return URL
`https://dcicqdprtyhwmhegabay.supabase.co/functions/v1/apple-oauth-callback`.
New Sign in with Apple key `FAMAKDMKT6` is active; the unusable prior key
`Y8K8B23VK6` was left untouched. Its one-time `.p8` is retained only in the
ACL-restricted local signing directory
`C:\Users\MOHAMMAD\Documents\Otlobli Apple Signing 2026`.

Only the unusable Apple Distribution certificate `K99MT75HDF`, whose downloaded
certificate hash was
`743D7E09F1D9CD0DB43DE72E5E422482ADEF8C3365CCBB486A6B2827E1826D92` and had
no matching retained private key, was revoked. Replacement certificate
`9G84PQ34US` expires 2027-08-22 and has SHA-256 fingerprint
`62:18:6A:2E:70:CA:EE:E2:78:ED:B9:90:48:F5:09:CA:E0:E2:EF:ED:E8:8A:34:C5:16:AE:FB:0D:D8:EA:42:6B`.
Its private key, certificate, validated P12, and DPAPI-protected local password
are in the restricted signing directory; their GitHub Actions equivalents are
encrypted secrets and were not printed or committed.

App Store provisioning profile `Otlobli v86.213 App Store` has portal ID
`J8UJBNN6S8`, UUID `ade603b0-8cd9-42e1-8883-a39aea1c9cb1`, expires
2027-08-22, and was decoded and verified for the exact team, App ID, production
APNs, Sign in with Apple, distribution certificate, and TestFlight entitlement.
The `.mobileprovision` and decoded plist are retained in the restricted signing
directory. GitHub secrets now contain the matching Distribution P12/password
and App Store profile.

Supabase has the exact new `.p8`, key ID `FAMAKDMKT6`, Team ID, iOS/Services ID
allowlist, and redirect map. Exact live configuration checks return
`configured=true` for iOS `com.otlobli.app` and Android
`com.otlobli.app.signin` with its callback. GitHub secret
`VITE_SUPABASE_URL` was corrected to
`https://dcicqdprtyhwmhegabay.supabase.co`. The hardened WhatsApp sender was
reconnected from its stored session without sending a message or showing a new
QR; the upload preflight then passed every readiness field.

App Store Connect record `Otlobli` has numeric app ID `6804052538`, SKU
`otlobli-ios-20260822`, Arabic primary language, and Bundle ID
`com.otlobli.app`. Initial workflow run `32529401241` exposed and safely stopped
on the malformed Supabase URL, disconnected sender, then Apple's iPad
orientation validation. Commit `a98b9b8` preserves portrait-only iPhone while
declaring all four iPad multitasking orientations and adds an exact CI plist
assertion. A fresh `npm run build` passed every release/auth/SHEIN/Temu/store/
performance guard, `npx cap sync ios` passed, and `git diff --check` passed.

GitHub run `32530248241` succeeded from
`a98b9b8e4e984e7928811029d98874b29cbeae18`, signed the production archive,
validated callbacks/profile/signature/symbols, and uploaded the IPA. Artifact
`9463720205`, `otlobli-ios-v86.213-build-1075-testflight`, is 25,117,598 bytes;
its GitHub artifact digest is
`sha256:fe8d5e310f80d406005b3426bf9ca883bfb6b2437fa0c2df7abc0627f859642b`
and it expires 2026-09-20.

Internal group `Otlobli Internal` now contains builds 1075 and 1076 and the
exact tester `mhm1981dx@gmail.com`. The tester installed 86.214/1076; its
list→product result failed and is the evidence for v86.215. No v86.215 iPhone
acceptance, weak-Android acceptance, five iPhone 16 resume cycles, or
force-quit/cold-launch acceptance is claimed.

# v86.212 — internal TestFlight authentication candidate (2026-08-21)

Work is isolated on `codex/otlobli-v86-212-testflight-auth` in
`C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`, based on protected
v86.211 documentation HEAD `bf654a1a84d379e1f7b2fcb8f8e0c98faa5765d3`.
Version/build is `86.212/1074`. No TestFlight build has been uploaded and no
Apple resource has been changed during this batch.

Google ownership and iOS OAuth configuration were completed externally on
2026-08-21. `mhm1981x@gmail.com` accepted ownership of Google Cloud/Firebase
project `otlobli-1ccf5`, was verified opening IAM, Credentials, and Firebase,
and is now the sole human Owner; former owner `djjd19903@gmail.com` was removed
after that verification. Google OAuth client `Otlobli iOS` now exists for
Bundle ID `com.otlobli.app`, Team ID `36D743K87T`, with client ID
`677396296147-n3337ehkgd51rt47dru8i9lle82in66q.apps.googleusercontent.com`.
GitHub Actions secret `VITE_GOOGLE_IOS_CLIENT_ID` was set in `m7madv/otlobli`
at `2026-08-21T19:20:36Z`. Supabase project `dcicqdprtyhwmhegabay` secret
`GOOGLE_CLIENT_IDS` was updated at `2026-08-21T19:20:39.112Z` to retain the
existing Web and Android audiences and add the new iOS audience. No secret
value was committed. This was an external-configuration/documentation-only
batch; no native rebuild or physical-device authentication claim was made. A
live invalid-token smoke check against the deployed `google-auth` function
returned HTTP `401` with `invalid_google_token`, confirming the provider remains
configured after the allowlist update.

The physical iPhone proved that native Apple account selection succeeds, then
the backend returns `apple_auth_not_configured`. The failure is therefore the
missing server-side Sign in with Apple configuration, not the button or the
development entitlement. v86.212 adds a strict multi-client Apple backend for
the iOS bundle ID `com.otlobli.app` and Android Services ID
`com.otlobli.app.signin`, an exact HTTPS callback, Apple token/code verification,
per-client authorization storage, and hardened service-role-only identity RPCs.
Android gets the native browser callback path. Google iOS configuration now has
the required `VITE_GOOGLE_IOS_CLIENT_ID`; the next eligible iOS build can inject
`GIDClientID` and the reversed callback, while physical Google sign-in remains
unverified. CI checks both the iOS client and the Web server-client audience.
Phone/WhatsApp now fails closed: production
accepts only the real backend, local mock requires explicit DEV-only opt-in, and
incomplete inbound mode is rejected.

The active WhatsApp server now uses a six-digit CSPRNG OTP, HMAC-only storage,
bounded attempts and resend/IP rate limits, redacted logs, Supabase session
readiness, and a fail-closed connected-sender gate. Every session/status/QR
operation now requires a separate 32-byte server secret before body parsing;
legacy archive/reset/public-QR routes return 410, and QR images are generated
locally behind authentication without serializing raw QR material. The old
tracked admin PIN must still be rotated before deployment.
The live server is still the old deployment: its health response reports the
sender disconnected and lacks the `customer-session-v1` contract, so the
TestFlight workflow correctly refuses to upload.

Final local verification includes a fresh `npm ci` with all native patches
applied, production build and every release/SHEIN/Temu/store/performance/auth
guard, Admin production build, clean iOS and Android Capacitor sync, Android Java
compile, and Deno checks for `apple-auth`, `apple-oauth-callback`, `google-auth`,
and `account-lifecycle`. All three workflow YAML files parse; 30 Bash run blocks
and 13 embedded Python programs pass syntax validation. Full lint has zero
errors (18 pre-existing hook/directive warnings), and `git diff --check` passes.
The registered iOS workflow has a separate manual `testflight` mode with
authentication preflight, distribution/profile/entitlement/signature checks,
App Store Connect validation/upload, artifact/dSYM preservation, and credential
cleanup. The stale v86.208 final-release workflow is hard-retired.

External blockers are exact: Account Holder acceptance of Apple's updated
agreement; explicit approval to register the prepared Services ID and SIWA key;
an Apple Distribution certificate/P12 and App Store profile; an Otlobli App
Store Connect record; the seven missing distribution/upload GitHub secrets;
deployment of migrations through
`20260821193000`, current auth Edge Functions, and the hardened WhatsApp server;
and a connected WhatsApp sender. Exact steps are in
`docs/final-enablement/MANUAL_PORTAL_ACTIONS.md` and `WHATSAPP_SETUP.md`.

This is an internal TestFlight candidate, not an App Store release. Before App
Store submission, separately finish/verify durable Apple revocation cleanup,
account-deletion concurrency, and policy-approved anonymization of retained
transactional personal data. Product capture, SHEIN/Temu routing, region,
orders, payment, and wallet behavior were not deliberately changed.

# v86.211 — complete order cards and Apple development signing (2026-08-21)

Work is isolated on `codex/otlobli-v86-211-orders-apple` in
`C:\Users\MOHAMMAD\Projects\otlobli-v86-211-orders-apple`, based exactly on
v86.210 HEAD `ec0d76bdbaf5bda0cd305ad6ac97f9a031085922`. Version/build
`86.211/1073` were verified unused for this physical iPhone test candidate.

The v86.210 device screenshot proved that every order card clipped the lower
part of the order-number/Reorder row. The orders screen is a CSS Grid and its
auto tracks could shrink grid items whose shared card rule has `overflow:hidden`.
`.mobile-content--orders` now uses `grid-auto-rows:max-content`, matching the
existing cart/tracking sizing pattern. No order, payment, or completed-order
logic changed. A regression guard enforces the sizing rule. Production build,
all release/store/freeze/performance guards, lint (zero errors), iOS/Android
sync, and visual QA at 430x932 and 320x568 pass. Measured cards have 14.8px below
the footer and `scrollHeight === clientHeight`; no footer is clipped.

After explicit user approval, Apple Developer now contains a new exact
`com.otlobli.app` App ID with Push Notifications and primary Sign in with Apple
enabled. Team ID is `36D743K87T`. A new matching Apple Development certificate
expires August 21, 2027. Provisioning profile `Otlobli v86.211 Development`
contains both registered iPhones and expires August 21, 2027. Local inspection
verified its application identifier, Team ID, `aps-environment=development`,
Apple Sign-In `Default`, device count, and certificate match without recording
device identifiers. The older incorrect `com.otlobli.app.36D743K87T` identifier
was left untouched.

The encrypted P12, its generated password, the development profile, and Team ID
are stored only in GitHub Actions secrets named
`IOS_DEVELOPMENT_CERTIFICATE_BASE64`,
`IOS_DEVELOPMENT_CERTIFICATE_PASSWORD`,
`IOS_DEVELOPMENT_PROVISIONING_PROFILE_BASE64`, `APPLE_TEAM_ID`, and a one-way
`IOS_DEVELOPMENT_DEVICE_UDID_SHA256` target-device fingerprint; none is in Git
and the raw device identifier is not logged. The registered iOS workflow now has
an explicit `development-signed`
manual mode that imports those assets into an ephemeral keychain and scopes the
matching profile to the App target only in the disposable runner checkout. This
avoids applying an app profile to Swift Package targets and leaves the committed
Xcode project unchanged. It archives the Release configuration with development
APNs entitlement and exports one
development IPA, verifies its signature/profile/entitlements/identity/version/
architecture/minimum iOS/device families/intended device, and removes all
temporary runner signing assets while restoring the original keychain state.
GitHub run `32492834328` succeeded from commit
`ce62ce214c0da2c158916ced6d4a58022d5e483d`; artifact `9450517773` is the
Apple-development-signed universal IPA. CI verified the code signature and
designated requirement, embedded profile and certificate membership, Team ID
`36D743K87T`, Bundle ID `com.otlobli.app`, version/build `86.211/1073`, arm64,
iOS 15 minimum, device families 1/2, development APNs, Sign in with Apple, and
the intended registered iPhone. Its SHA-256 is
`13E3B3C5791167ED780E9710288217E63F08D544BFA360DA6DFACCB16F76C845`.
The downloaded IPA at
`C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.211-development-signed-run-32492834328\otlobli-v86.211-build-1073-development-signed.ipa`
matches that hash and independently contains the expected Info.plist,
`embedded.mobileprovision`, `_CodeSignature`, capabilities, and two-device
profile. Install it directly without Sideloadly/3uTools re-signing; Apple login
remains pending physical-device acceptance. Google iOS remains separately
blocked by the missing `VITE_GOOGLE_IOS_CLIENT_ID` OAuth client secret, so its
action remains hidden.

# v86.210 — exact loading-nav copy and visible order number (2026-08-21)

Work is isolated on `codex/otlobli-v86-210-ui-auth` in
`C:\Users\MOHAMMAD\Projects\otlobli-v86-210-ui-auth`, based exactly on the
v86.209 documentation HEAD `7024ac56d603aedd3a52e0c82b7d13d88a498e62`.
Version/build `86.210/1072` were verified unused and are reserved for this
physical iPhone test candidate; this is not an App Store release.

The v86.209 device test accepted the navigation behavior but exposed a visual
handoff: the temporary iOS SHEIN loading bar used SF Symbols while the permanent
React/injected bar uses Otlobli's own SVG paths. v86.210 draws those same four
24-point paths natively at 22 points, uses the same colors, 12-point bold text,
4-point active indicator, spacing, safe area, and stable pressed treatment.
Injected tabs also neutralize host-site pressed styling. This is a literal copy
of the existing bar, not a redesign. Product capture, store routing, region,
cookies/data, and WebView lifecycle are unchanged.

Order cards now put an explicit `رقم الطلب` block in the lower physical-left
corner beside the existing reorder action. The full sample identifier remained
visible at both 320x780 and 360x800 in browser visual QA. No order/payment data
logic changed. Apple error 1000 is mapped to an actionable Arabic message, but
authentication itself is not claimed fixed: the tested v86.209 IPA was unsigned
and contained no provisioning profile. GitHub has none of the Apple certificate,
profile, password, or Team ID inputs, so a 3uTools/free re-sign cannot prove the
`com.apple.developer.applesignin` entitlement.

Google is also externally blocked, not a runtime-code failure. GitHub run
`32483692145` had an empty `VITE_GOOGLE_IOS_CLIENT_ID`; inspected v86.209
`Info.plist` had no `GIDClientID` or reversed Google callback, and the app safely
hid the Google action. GitHub currently contains no iOS OAuth client secret.
`npm ci`, production build, release/security guards, SHEIN freeze guard, Temu
guards, store-surface guard, TypeScript, performance budget, and lint pass.
iOS/Android sync also passes. GitHub/Xcode run `32487355586` compiled code commit
`b543b1c102636c7c98e8027692566f31e7059dfc`; artifact `9448456832` is the
unsigned universal iPhone/iPad IPA. Inspection proved Bundle ID
`com.otlobli.app`, version/build `86.210/1072`, arm64, iOS 15 minimum, and device
families 1/2. It has no signature, provisioning profile, `GIDClientID`, or Google
callback. Its SHA-256 is
`D46ACEB3127F9BC866C695280D506DF0554FE7EF5F5D87C28847A107888E0149`.
Signing and physical-device acceptance remain pending.

# v86.208 — final enablement current state (2026-08-21)

Work is isolated on `codex/otlobli-v86-208-final-enablement` in
`C:\Users\MOHAMMAD\Projects\otlobli-v86-208-final-enablement`, based on protected
HEAD `c18363c9a5712239d53bdf97880058036f9b2198`, with version/build
`86.208/1070`. Product capture remains byte-identical and Temu is unchanged.

The release adds a bounded versioned SHEIN policy layer, native forbidden-route
enforcement, independent region/readiness coordination, and opening timing.
The live admin setting was verified as QA/USD/ar. Supabase migration
`20260821090000_production_auth_push.sql` and functions `google-auth`,
`send-push`, `apple-auth`, and `account-lifecycle` are deployed. Local gates,
production build/sync, artifact scans, and Android compile/unit tests pass.
GitHub/Xcode unsigned run `32476867979` also passes; artifact `9444682658`
validates the iOS target but is not signed or provisioned.

Release ready remains **no**: Apple/APNs/Google iOS and Android signing inputs
are absent, no signed IPA/AAB/APK exists, and the required physical device,
push, OAuth, deletion, policy, region, Temu, and performance matrix has not run.
The authoritative handoff is `docs/final-enablement/FINAL_RELEASE_ACCEPTANCE.md`
and exact remaining actions are in `docs/final-enablement/MANUAL_PORTAL_ACTIONS.md`.

# v86.207 — final production release candidate preparation (2026-08-21)

Release work is isolated on `codex/otlobli-final-production-release`, based on
clean v86.201 commit `0b462a93030b5c7114012d5848ce61eac49b8b17` and reserved as
`86.207/1069`. Product capture, SHEIN blocking, region/session behavior, store
navigation, and Temu behavior remain unchanged; production diagnostics and
Release Web Inspector access are removed/compiled out. The owner attributes the
old freeze to an earlier iOS 27 beta/WebKit build and reports roughly 30
successful store flows after updating the same phone. v86.207 does not claim a
new freeze fix.

iOS direct APNs, safe notification routes, Google iOS, Sign in with Apple, and
account deletion are implemented around the existing Supabase customer/session
model. All local web/guard/sync checks and Android unit/debug compilation pass.
Physical OAuth/push/deletion tests, live migration/function deployment, Apple
and Google portal configuration, signed IPA/AAB/APK, and the device matrix are
still required; therefore Release ready is **no**. Authoritative details are in
`docs/final-release/FINAL_RELEASE_REPORT.md` and
`docs/final-release/REQUIRED_PORTAL_ACTIONS.md`.

# v86.201 — double Home reveals the store chooser (2026-08-20)

The requested gesture was only implemented for the Android personal-Temu surface. It was impossible inside the injected SHEIN/Temu navigation: the document-start bridge immediately loaded store Home on the first tap and rejected every event inside 450ms, including the user's real second `touchend`.

v86.201 preserves v86.200 and changes only injected Home-tab routing. One Home tap now waits 320ms and then performs the existing active-store Home navigation. A second physical Home tap inside that window cancels navigation and emits the existing `closeStore` message; App.tsx reveals `store-select`, hides/parks the same browser session, and its React bottom bar remains mounted. The synthetic `click` following an iOS `touchend` is explicitly deduplicated and cannot falsely open the chooser. Touching Orders, Cart, or Profile cancels a pending single-Home action before routing that tab.

Version/build is `86.201/1063`; marker `2026.08.20-v86.201-double-home-store-switch`. Local gates/build/sync and GitHub/Xcode run `32395358634` pass from commit `705881c`; artifact ID `9416494357`. The inspected unsigned IPA is `com.otlobli.app`, ARM64, iOS 15+, iPhone/iPad `[1,2]`, `6,559,013` bytes, SHA-256 `5E24D42A5E3CD600B1F76FF0E7D7918B13E53A49BED930710820ACAF42F64F8B`, without app signature, provisioning profile, source maps, or relay placeholder. It contains the double-Home markers, `[OTLOBLI_BACK]`, and the inactive-scheduling selector. Physical acceptance is pending. Acceptance must cover: one Home tap from a product opens store Home after the bounded delay; two quick taps show the chooser without a store reload; the bottom bar stays visible; re-entering SHEIN/Temu preserves interaction; and all v86.200 button/background tests still pass.

# v86.200 — one visible store-exit button on SHEIN and Temu (2026-08-20)

The customer reported two navigation defects while the combined background candidate was being prepared: Temu has no exit control on its Home root, and SHEIN shows two overlapping controls (green native plus dark injected). Source confirms both. `ensureBackButton()` hid the Temu root entirely, while the dedicated iOS SHEIN plugin deliberately renders a native UIButton without suppressing the HTML fallback that continues to repaint at the same coordinates.

v86.200 retains all v86.199 root-Back and `.throttle` behavior. On any iOS WebView that exposes the native message handler, the injected HTML Back remains `display:none` but continues computing and publishing visibility/target state; exactly one native button is visible. Temu is now eligible for a Back control even at its root. Search overlay Back still has first priority; root exit emits `closeStore`, parks/hides the Temu browser, and reveals the Otlobli picker; non-root Temu keeps the existing history behavior. Android/no-native-handler retains the injected button as its single fallback.

Version/build is `86.200/1062`; marker `2026.08.20-v86.200-store-exit-buttons`. GitHub/Xcode run `32394719421` passed from commit `ed75aab`; artifact ID `9416286514`. Physical acceptance is pending. Acceptance: SHEIN must show only the green native control; Temu Home must show exactly one control; Temu search Back must exit search; Temu root Back must reveal the picker; re-entering both stores must keep them interactive; then perform the v86.199 five-cycle background test.

# v86.199 — preserve accepted root Back and test inactive scheduling (2026-08-20)

Physical v86.198 results split the incident cleanly. Its native root guard is accepted: SHEIN opens normally, product/back works, Back at canonical Home now leaves the store without entering WebKit history, and the customer can choose/open another store. That fix must remain. A separate trigger remains: send the whole app to the background and return, and the retained SHEIN page still freezes. Therefore the Back race was real and fixed, but it was not the only freeze path.

v86.199 is cut directly from the accepted v86.198 code. Its only new behavioral delta is `configuration.preferences.inactiveSchedulingPolicy = .throttle` for iOS 17+ before the app-owned SHEIN WKWebView is created. The root URL guard, cart priority, 0.8-second Back lock, `[OTLOBLI_BACK]` logging, one WKWebView, website data, cookies, cache, Service Workers, region/VPN, scripts, and navigation remain unchanged. `.none`, reload, recompose, detach/reattach, recreation, and website-data clearing remain forbidden.

Version/build is `86.199/1061`; marker `2026.08.20-v86.199-root-back-scheduling`. Build/archive and physical acceptance are pending. The decisive test is app switching without force-quit: enter SHEIN, open a PDP, return to Home, background Otlobli for 5–10 seconds, return, then scroll/open a category and PDP. Repeat five times. A separate swipe-away force-quit/cold launch must be reported separately because process death is not a scheduling-resume cycle.

# v86.198 — canonical SHEIN Home exits before WebKit history (2026-08-20)

The customer found a 100% local trigger that supersedes backgrounding as the immediate reproduction: SHEIN Home → product → Back to Home → press Back once more. The second Back visibly reloads Home and leaves it inert. Source inspection identifies the pressed control as the native `UIButton` in `OtlobliSheinBrowserPlugin`, which sits above the injected page button. The injected script already classifies Home as an exit, but it publishes `nativeBackTarget` asynchronously during navigation maintenance. The native handler trusted that possibly stale target and then called `WKWebView.goBack()` whenever `canGoBack` was true. SHEIN redirects/verification entries make that history structurally nonempty without making it safe application navigation.

v86.198 starts from exact clean v86.193 commit `a6e0ca943c4d9a2722b5962a4193d3e34d2da248`; it deliberately excludes v86.197's inactive-scheduling change so the device result tests one cause. At native Back tap time, the live WKWebView URL is now authoritative. Canonical `m.shein.com/ar/` (or `/`) sends existing `closeStore`, which parks the same verified session and reveals Otlobli's store picker without `goBack`, `history.back`, reload, or Home load. Cart retains first priority; non-root pages retain the existing `goBack`/Home fallback. A 0.8-second native lock rejects overlapping taps.

Native `[OTLOBLI_BACK]` logging records page type, current URL/path, `canGoBack`, total and last five back-list items, received target, chosen action, and the resulting top-level `WKNavigationType`. The freeze guard enforces cart-before-root-before-history ordering. Version/build is `86.198/1060`; marker `2026.08.20-v86.198-shein-root-back-guard`. Local build/gates pass, as does GitHub/Xcode run `32392833687` from code commit `a3675ff`; artifact ID `9415593869`. The inspected IPA is ARM64, iOS 15+, iPhone/iPad `[1,2]`, `6,558,346` bytes, SHA-256 `01BF09120BC919A614252279FD0A6890F7392C20EABC3FC8EFECAD74DE903E66`, app-level unsigned/unprovisioned, without source maps or relay placeholder. Its binary contains `[OTLOBLI_BACK]` and deliberately does not contain `setInactiveSchedulingPolicy:`. Physical acceptance is pending. It must cover ten product → Back cycles, then one Back at Home returning directly to the picker, SHEIN re-entry with list/PDP still interactive, plus the standing resume/cold-launch checks. Do not call the inert-page mechanism itself explained: this candidate prevents the proven trigger without claiming why SHEIN fails hydration after the unsafe history item.

# v86.189 — one disposable iOS render-surface path (2026-08-14)

Physical v86.188 results rejected same-instance recovery: on the modern iPhone the first entry worked, but the second entry showed a category/list surface whose controls no longer accepted taps. On iPhone 6 the home document loaded completely, but the next SHEIN list route began and did not finish into an interactive product list. The matching Android build remains fully interactive. This isolates both active faults to iOS WebKit rendering/navigation ownership, not the injected script groups or SHEIN's Android path.

v86.189 removes the rebind design instead of stacking another recovery on it. There is one rule on every supported iPhone: a WKWebView is a disposable render surface and never survives hide or background. Exit/background destroys the surface; entry/foreground creates a new one from the saved SHEIN URL. Cookies, signed region state, human-verification proof, and storage remain in `WKWebsiteDataStore.default()`. A settled SHEIN SPA path change also gets one fresh surface and a full document request, so the old and modern iPhones share the same navigation contract. There is no device-version branch, process pool, hidden surface, reload, recompose, display link, snapshot, or delayed retry burst.

Version/build is `86.189/1051`, marker `2026.08.14-v86.189-disposable-render-surface`. TypeScript, release hardening, freeze/architecture, Temu, surface, and performance gates, iOS sync, macOS/Xcode run `31834669885`, and archive inspection pass from commit `6830a04`. The inspected unsigned artifact is `com.otlobli.app`, ARM64, iOS 15+, iPhone/iPad `[1,2]`, `6,557,711` bytes, SHA-256 `8F5D73D105483733BF9D03817300429D2D79CFC2D2A50A77C8A6572BC0B874AF`, with no provisioning profile, code-signature directory, or source maps. Physical acceptance is deliberately short: modern iPhone second entry plus one resume; iPhone 6 Home → list and one product tap. Do not call fixed before both results.

# v86.188 — dedicated app-owned iOS SHEIN browser (2026-08-14)

The physical v86.187 isolation test is decisive: after a clean install, every normal Otlobli store-script group was switched off, the first SHEIN visit worked, the flags remained off, and the same storefront froze after background/return. This rules the normal Runtime, Navigation, Blocking, Capture, and Session/Region injections out as the cause. It also supersedes the earlier same-store re-entry diagnosis for this background-resume symptom. The fault belongs to the generic iOS WKWebView owner/lifecycle path.

v86.188 removes iOS SHEIN from the generic Capgo modal-browser path. `OtlobliSheinBrowserPlugin.swift` now owns one full-size WKWebView directly under the permanent Capacitor host view, one document-start bridge, `WKWebsiteDataStore.default()`, and one shared process pool. `storeBrowser.ts` is the platform boundary: only iOS + a SHEIN URL uses the dedicated browser; Android and non-SHEIN traffic retain Capgo. SHEIN still owns its real website, cookies, local/session storage, human verification, and network behavior. This is not a recreated or scraped storefront.

The new lifecycle keeps the same WKWebView/DOM/session through ordinary hide/show and backgrounding. After an actual `didBecomeActive`, it performs at most one render-surface rebind separated by a real `CADisplayLink` frame, restores the scroll offset, and never reloads the page. The browser does not use `willEnterForeground`, retry bursts, cookie deletion, local-storage deletion, or background reloads. Only HTTP memory/disk cache can be cleared by the existing bounded damaged-session recovery. WebContent-process termination remains a separate fatal event handled by the host's clean recovery path.

Version is `86.188/1050`; marker is `2026.08.14-v86.188-native-shein-browser`. TypeScript, the expanded native-architecture guard, diagnostic web build, hardening, store/Temu/performance gates, Capacitor iOS sync, and honest-pipefail macOS/Xcode run `31832999429` pass on commit `a9ae9e1`. The inspected unsigned IPA is ARM64, iOS 15+, iPhone/iPad `[1,2]`, `com.otlobli.app`, with no source maps, code-signature directory, or embedded provisioning profile; size `6,554,404` bytes and SHA-256 `7F92FAE968BBB51CAFA8F2C533119D9EB7654A5D2F1DBBDEC91DADC1A34619A4`. Physical-device acceptance is still pending. Required acceptance: keep the diagnostic flags raw/off, enter SHEIN, then run ten background/return cycles (including 10 s, 30 s, and a VPN-app hop) and verify scrolling, categories, list, and PDP after every return. Then enable all scripts and repeat Home → list → PDP plus five resumes. A force-quit/cold launch is a separate session-persistence check, not a resume cycle.

# v86.187 — store-script isolation panel and same-store re-entry diagnosis (2026-08-14)

This is an explicitly diagnostic build, not a customer production release. The reported sequence is: the first SHEIN entry works, leaving the store and entering SHEIN again can leave the whole storefront non-interactive, and switching to Temu then back to SHEIN recovers it. v86.186 corrected the concrete host race behind that sequence: `closeStore` exposed the chooser before the asynchronous native close completed, and a fast same-store open was discarded by `webviewClosingRef`. Store opens are now queued during close, the exact old WebView ID is retired without animation, stale close events are ignored, and one pending same-store request is replayed after close.

v86.187 adds an environment-gated isolation panel so the remaining device symptom can be classified in one short test instead of by speculative patches. A fixed 50×48 `فحص` control inside the native store surface opens an accessible RTL drawer with `المتجر خام`, `تشغيل الكل`, and independent Runtime, Navigation, Blocking, Capture, and Session/Region switches. A flag change rebuilds only the current native WebView and deliberately does not clear the website data store, cookies, or human-verification proof. Raw mode still injects the small diagnostic control/readiness bridge, but does not evaluate the normal store coordinator, recurring work, or region diagnostic. The panel is excluded completely unless `VITE_STORE_SCRIPT_DIAGNOSTICS=true`; normal production builds therefore do not ship an active debug surface.

The decisive test is full mode followed by raw mode using the exact failing sequence: enter SHEIN, leave to the store chooser, enter SHEIN again, and tap categories/products. If raw mode still freezes, stop changing injected scripts and investigate native WebView/plugin close-open ownership. If raw mode works, restore all switches and turn off one group at a time, starting with Blocking, then Session/Region, Navigation, and Capture. The selected flags persist in Otlobli host storage, while the remote SHEIN session remains site-owned.

TypeScript, the executable SHEIN freeze/isolation guard, Temu product-loading guard, Standard and Personal diagnostic builds, release hardening, store-surface/size/performance gates, Capacitor sync, Android ARM64 Debug, and isolated Xcode all pass. Playwright visual checks passed at `390×844` and `320×568`, including focus handling, safe-area padding, 44px+ controls, reduced-motion behavior, no horizontal overflow, and a scrollable small-screen drawer. Final Personal budgets are startup JS `641,231/720,000`, total JS gzip `264,287/370,000`, CSS `69,819/70,000`, fonts `81,364/100,000`, shipped store scripts `244,573/470,000`, and combined source `562,339/600,000` bytes.

Version is `86.187/1049`. Android diagnostic APK: `C:\Users\MOHAMMAD\Documents\Codex\2026-08-14\files-pasted-by-the-user-otlobli\outputs\Otlobli-v86.187-Android-Script-Isolation-DIAGNOSTIC.apk`, `205,012,092` bytes, SHA-256 `DC1EB324B9C01B434D2BF64836958D9359CE2F0F3563278403AD10B5E253E394`; package `com.otlobli.app`, ARM64, minSdk 26/target 36, APK Signature v2 debug-signed. iOS isolated branch `codex/ios-v86-187-script-isolation`, commit `7259faf`, GitHub run `31830165263`, produced `C:\Users\MOHAMMAD\Documents\Codex\2026-08-14\files-pasted-by-the-user-otlobli\outputs\Otlobli-v86.187-iPhone-iPad-Script-Isolation-DIAGNOSTIC-UNSIGNED.ipa`, `6,532,034` bytes, SHA-256 `87560FCF9C09DA39E922BD489EDF07670876722C86148471A504E5F5C86625D5`. Archive inspection confirms `com.otlobli.app`, `86.187/1049`, ARM64, iOS 15+, iPhone/iPad families `[1,2]`, the panel and host-handler markers, no source maps, no app-level signature, and no provisioning profile.

No physical iPhone was connected, so this is not called device acceptance or a proven final fix. Sign/provision the IPA normally, run the two-profile test on both affected iPhones, and report whether raw mode freezes. That single result determines the next engineering lane without more blind changes.

# v86.185 — store runtime cleanup and persistent SHEIN session ownership (2026-08-14)

The store injection is no longer a 10,000-line mixed-responsibility file. `sheinBrowserScript.ts` is composition-only and assembles named navigation, session, capture, blocking, Temu, and coordinator modules documented in `src/services/STORE_RUNTIME.md`. The release guard follows the module graph and locks the composition order, so splitting the source cannot bypass syntax or behavior fixtures. The full runtime has one recurring due-time coordinator instead of four permanent intervals, and the former full-document MutationObserver is gone. The 120 ms normal / 650 ms low-end blocker cadence is preserved; the document-start timers remain bounded and stop as soon as the full runtime reports ready. The only remaining store MutationObserver is the existing local, short-lived selected-SKU price observer.

The high-risk session interference was removed. Otlobli no longer monkey-patches `Storage.prototype.setItem`, writes guessed SHEIN country/currency/language cookies or storage keys, deletes `addressCookie`, or reloads a product merely because aliases are absent. Live browser inspection showed SHEIN now owns structured values such as `currency={value,end}` and a signed `addressCookie`; the old scalar coercion could corrupt that schema and force reinitialization even in an older app build. SHEIN now owns cookies/localStorage/sessionStorage and its solved human-check proof. Otlobli reads the signed address and uses SHEIN's native shipping UI when the configured country needs repair. Human verification remains entirely user-controlled. Entry URLs were reduced from thirteen guessed region aliases to `currency`, `localcountry`, and `lang`.

Live browser verification loaded the current SHEIN Arabic home normally. A direct automated category navigation was then challenged by SHEIN itself at `/ar/risk/challenge` with HTTP 429; no attempt was made to solve or bypass it. This confirms that challenge frequency is controlled by the third-party risk service and supports the fail-visible, session-preserving design. It does not replace device acceptance.

Version is `86.185/1047`; markers are `2026.08.14-v86.185-store-runtime-cleanup` and `2026.08.14-v86.185-personal-store-runtime-cleanup`. Standard and Personal builds, release hardening, SHEIN/Temu/store fixtures, product-loading guard, performance budgets, iOS/Android sync, Personal ARM64 Android Debug, and isolated macOS/Xcode all pass. Final Personal budgets: startup JS `639,347/720,000`, total JS gzip `259,740/370,000`, CSS `69,819/70,000`, fonts `81,364/100,000`, shipped store scripts `243,698/470,000`, and combined store source `545,738/600,000` bytes. Full repository lint still reports the pre-existing project baseline (`40` errors, `19` warnings), including unrelated Admin/App rules and extracted historical output; it is not a release gate and no new helper error was reported.

Personal ARM64 debug APK: `C:\Users\MOHAMMAD\Documents\Codex\2026-08-14\files-pasted-by-the-user-otlobli\outputs\Otlobli-v86.185-personal-store-runtime-cleanup-debug.apk`, `205,006,508` bytes, SHA-256 `693CA50D0168E4A092A907866319B802B643814A9195CDCE7CC051D0FB2274C0`. A production Android release was not produced because the separate ShamCash listener lacks its `OTLOBLI_LISTENER_*` release-signing values; the delivered APK is debug-signed for device testing.

Isolated iOS branch `codex/ios-v86-185-store-runtime-cleanup`, commit `26bdd5bd69f6586203d02c7fa89d2f6b3be11b97`, and GitHub run `31827354199` produced `Otlobli-v86.185-iPhone-iPad-Store-Runtime-Cleanup-UNSIGNED.ipa`, `6,527,689` bytes, SHA-256 `AA75998F5CAF2C7B82CAEDDF61D84C11D1D3573DC54B07613403A61A4F45DBEE`. Archive inspection confirms `com.otlobli.app`, `86.185/1047`, ARM64, iOS 15+, `UIDeviceFamily [1,2]`, no source maps, no app signature/provisioning profile, presence of the new runtime/session markers, and absence of the storage override/product-bootstrap reload markers.

No physical iPhone was connected, so the customer symptom is not called device-accepted. Required acceptance on both affected iPhones: Home → collection/list → selected PDP; complete `أنا إنسان` manually once if shown, open the PDP, leave and return to the store, and confirm the same verification is not requested again while SHEIN's own proof remains valid. On iPhone 16 also run five background/resume cycles and one force-quit/cold launch. A third-party site cannot be guaranteed never to change; the durable boundary is minimal intervention, site-owned session state, semantic challenge protection, separated responsibilities, and regression guards.

# v86.184 — SHEIN live verification compatibility guard (2026-08-14)

The current mobile-browser flow was reproduced directly at `m.shein.com`: Home and the intermediate Super Deals collection both loaded, the selected card navigated to its canonical `-p-520531743.html` PDP, and both static and realtime product APIs returned HTTP 200. SHEIN then opened a legitimate human-verification surface with `.sui-dialog__wrapper` and `.risk-one-pass-*`, Arabic copy ending in `أنا إنسان`, and successful risk-token/resource requests. Otlobli recognized only older `.one-pass-dialog`/captcha shapes; its former generic fallback required a `challenge` class before reading text. The new live wrapper has neither, so Otlobli failed to enter its existing protected challenge mode and continued page cleanup. This is the server-side change that explains why a clean install of formerly working `86.134/994` now fails too. v86.183's card-route diagnosis was real but incomplete and is superseded.

`src/services/sheinHumanCheck.ts` now detects the exact live `risk-one-pass` family and also performs a bounded semantic check over at most the last 12 visible dialog/security surfaces. It reads only the candidate surface, not the whole page; ordinary login/promotion dialogs and hidden stale templates remain negative. Detection enters the existing user-controlled challenge mode before any popup/product cleanup, exposes SHEIN's own verification UI, and notifies the host. It never clicks, solves, reloads, changes a verification response, or writes region state while the token is outstanding. The iOS product-tap fallback is also less class-dependent: across at most 12 ancestors and 16 descendant PDP links it accepts the nearest container only when all qualifying links share one product ID, and refuses ambiguous multi-product containers. Numeric metadata-only cards retain their constrained fallback.

The freeze guard now executes fixtures for the live `risk-one-pass` dialog, a renamed semantic verification dialog, a normal promotion dialog, a hidden stale verification template, a renamed single-product card, and an ambiguous multi-product list. Standard and Personal builds, release hardening, SHEIN/Temu/store guards, performance budgets, iOS/Android sync, standard Android debug compile, Personal ARM64 Android debug compile, and the isolated macOS/Xcode build pass. Final Personal budgets are startup JS `640,035/720,000`, total JS gzip `261,170/370,000`, CSS `69,819/70,000`, fonts `81,364/100,000`, shipped store scripts `249,905/470,000`, and SHEIN source `555,083/600,000` bytes. Synced iOS and Android assets both contain the live risk marker.

Version is `86.184/1046` (`86.184-personal-shein-live-risk-guard` on Personal Android). The Personal ARM64 debug APK is `C:\Users\MOHAMMAD\Documents\Codex\2026-08-14\files-pasted-by-the-user-otlobli\outputs\Otlobli-v86.184-Personal-ARM64-Debug.apk`, `205,009,860` bytes, SHA-256 `6B0C7CA57000CEDC5CAAAC33C2481776FD4392E39A05AEE797D126F033392ECB`; it is a debug-certificate device-test artifact, not a Play upload. Isolated branch `codex/ios-v86-184-shein-live-risk-guard`, commit `e74a6fab45fcc1bbe32ebaffcbb843d58dc98973`, and GitHub run `31824376802` produced `otlobli-v86.184-ipad-iphone-universal-unsigned.ipa`, `6,529,146` bytes, SHA-256 `F4CD547901E1D5675BD3E3C9BBC9E263F2765F86B049D678672F015CCC7B002D`. Archive inspection confirms `com.otlobli.app`, `86.184/1046`, ARM64, iOS 15+, `UIDeviceFamily [1,2]`, the risk and native freeze markers, no source maps, and no app signature/provisioning profile.

No physical phone was connected, so device acceptance is explicitly pending. Sign/provision the IPA, then on both affected iPhones test Home → collection/list → selected PDP; if SHEIN shows `أنا إنسان`, complete it manually once and verify that the same PDP becomes interactive. On iPhone 16 also run five background/resume cycles plus one force-quit/cold launch. No code can guarantee compatibility with arbitrary future third-party changes; this release replaces the exact-class blind spot with bounded semantics and guarded fixtures so the current failure is handled without weakening SHEIN security or low-end performance.

# v86.183 — corrected SHEIN live product-card targeting on iPhone (2026-08-14)

Version `86.182/1044` was confirmed installed on both connected phones (`iPhone17,2` and `iPhone8,1`), and the customer reported the exact same collection/list-to-product failure on both. The customer then deleted it completely and clean-installed the much older `86.134/994` on the iPhone 16 Pro Max; device inspection confirmed that exact installed version and the same failure remained. This rules out a regression or stale data introduced after v86.134. Source comparison explains the continuity: v86.134 and v86.182 both miss the current live card shapes. The v86.182 diagnosis was incomplete and that artifact is superseded. Inspection of the current live SHEIN mobile DOM matching the customer's Batman search/list screen found that the tapped image is inside `.bs-product-card.multi-product-card`, while the canonical `-p-<id>` anchor is a sibling rather than an ancestor. Other real grid items use `.flash-sale__product-item` with `data-id` and no direct anchor. Both old resolvers therefore fail to arm for these real cards; v86.182 could also suppress itself after any SPA URL change even when SHEIN had moved to another non-product list/brand route.

`OTLOBLI_IOS_PRODUCT_TAP_FALLBACK_JS` now climbs past leaf image wrappers to a bounded set of actual product-card shapes and arms only when it resolves either a direct sibling/descendant `-p-<id>` link or numeric product metadata. Metadata-only cards use the bounded SHEIN route `/<locale>/product-p-<id>.html`. After the existing single 500 ms window, the fallback skips only when the current route already contains the same product ID; a wrong non-product SPA route is overridden once with the captured PDP. Generic `sd-ccc-products__item` collection/carousel items with neither product href nor product ID remain entirely natural. No synthetic click, polling, observer, continuous DOM scan, extra timer, or product-specific exception was added. Protected `otlobliForceRecompose`, the 0.25-second `appDidBecomeActive` path, and the `JSON.stringify` region guard remain unchanged.

The guard now covers the live `.bs-product-card` image/sibling-link shape, `data-id`-only flash-sale cards, generic collection non-intervention, same-product natural navigation, and wrong-list SPA redirects. Standard and Personal builds, release hardening, SHEIN/Temu/store guards, iOS/Android sync, and Android `assembleDebug` pass. The isolated iOS build also passed with startup JS `638,738/720,000`, total JS gzip `260,513/370,000`, CSS `69,819/70,000`, fonts `81,364/100,000`, shipped store scripts `248,920/470,000`, and SHEIN source `554,884/600,000` bytes.

Version is `86.183/1045` (`86.183-personal-shein-product-card-target` on Personal Android). Isolated branch `codex/ios-v86-183-shein-product-card-target`, commit `05f123e`, and GitHub run `31818768808` produced `Otlobli-v86.183-iPhone-iPad-SHEIN-Product-Card-Target-UNSIGNED.ipa`, `6,528,874` bytes (`6.23 MiB`), SHA-256 `D1931BDDCB4AC3BCF1458F8FDE781BE81346F4A27173B071DC47719CFF1FCF8C`. Archive inspection confirms bundle `com.otlobli.app`, `86.183/1045`, iOS 15+, iPhone/iPad, ARM64, the new route markers, no source maps, no app-level signature, and no provisioning profile. It must be signed/provisioned before installation. Static/build validation is complete, but the issue is not declared fixed until both affected phones pass Home → collection/list → the exact PDP; iPhone 16 also needs five background/resume cycles and one force-quit/cold launch.

# v86.182 — SHEIN iPhone collection-to-product routing (2026-08-14)

Real-device reproduction on iPhone8,1 / iOS 15.8.8 confirmed the customer's three-stage flow: SHEIN Home loads normally, the first card tap opens a product collection/list, and the second tap on the actual item fails to reach the PDP and leaves a blank/error-like SHEIN listing surface. The same symptom is customer-reported on iPhone 16. The app process emitted no useful Release syslog entries during the reproduction; no raw device log was retained.

Root cause was the iOS product-tap fallback in `src/services/sheinBrowserScript.ts`. It treated generic `sd-ccc-products__item` collection containers as if they were direct products and replayed a synthetic `.click()` whenever `location.href` had not changed. SHEIN can complete the legitimate Home-to-collection transition inside its SPA without changing that value, so the replay could select a brand/category route instead of the requested PDP.

The fallback now preserves the natural Home-to-collection transition and arms only when the tapped element exposes a direct SHEIN product href containing `-p-<id>`. After the existing bounded 500 ms window it assigns that captured href once only if no natural route change occurred. Generic cards without a direct PDP href are explicitly ignored. No polling, observer, DOM scan, permanent listener, extra timer, or product-specific exception was added. The protected iOS `otlobliForceRecompose`, 0.25-second `appDidBecomeActive` path, and `JSON.stringify` region guard remain unchanged.

Version is `86.182/1044` (`86.182-personal-shein-pdp-route` on Personal Android). Standard and Personal builds pass TypeScript, release hardening, SHEIN freeze, Temu size/capture, store-surface, and low-end performance guards. Standard was synced to iOS and Personal to Android; Android `assembleDebug` passed. Final Personal budgets: startup JS `640,023/720,000`, total JS gzip `260,632/370,000`, CSS `69,819/70,000`, fonts `81,364/100,000`, shipped store scripts `248,151/470,000`, and SHEIN source `554,096/600,000` bytes.

Isolated iOS build commit `54a9991` on branch `codex/ios-v86-182-shein-pdp-route` passed GitHub run `31816661268`. The unsigned iPhone/iPad artifact is `Otlobli-v86.182-iPhone-iPad-SHEIN-Product-Route-UNSIGNED.ipa`, `6,528,595` bytes (`6.23 MiB`), SHA-256 `4FF5C1B346E29B6AFF9FADBB22427EF06CFEA354B68866DEFA021C0F6F5A17FD`. Archive inspection confirms bundle `com.otlobli.app`, `86.182/1044`, iOS 15+, iPhone/iPad, ARM64, no source maps, and no embedded signature/provision. It must be signed/provisioned normally before installation. Final acceptance remains pending on both affected iPhones: test Home → collection → exact PDP; on iPhone 16 also perform five background/resume cycles plus a force-quit/cold launch.

# v86.181 — consented online diagnostics for iPhone and Android (2026-08-14)

The app now has a customer-controlled online diagnostic flow under **Account → Support → Send diagnostic report**. The customer describes the failure, explicitly consents, and the app sends a bounded in-memory trace of at most 60 recent technical events. It records screen/store transitions, store load/failure states, verification states, product-capture receipt, cart acceptance, and acknowledgement success/failure. It does not patch `console`, scan store DOM, add polling, persist the trace, or send automatically. Client and server both drop sensitive keys and redact bearer/JWT values, URLs, long identifiers, email-like text, and phone-like text; screenshots, cookies, passwords, page HTML/content, product titles, and selected values are not part of the diagnostic trace. Existing Android shake/screenshot reports remain compatible and now attach the same sanitized trace.

The live backend is upgraded on Supabase project `dcicqdprtyhwmhegabay`: migration `20260814164500_app_report_diagnostics.sql` is applied and the updated `app-reports` Edge Function is deployed. Diagnostic reports may omit screenshots; visual reports still require one. Payloads are server-sanitized, limited to 32 KB / 60 events, and retain the existing 20-second per-device rate limit. A real opt-in submission from the customer support UI reached production successfully; it is intentionally labeled `اختبار آلي: التحقق من إرسال تشخيص آمن عبر الإنترنت` in the report inbox.

Admin now distinguishes `تشخيص` from `لقطة`, renders a stable no-screenshot diagnostic surface, and exposes the trace through an accessible expandable timeline rather than raw JSON. It was deployed to the official alias `https://talabieh-admin.vercel.app`; the no-cache production asset `/assets/index-Cg9mc4cb.js` contains `reportKind`, `diagnostics`, and `تشخيص مباشر`. The compact customer UI reused the existing support/form components, added explicit inline validation and `aria-live`, and added zero bytes to the already-tight customer CSS budget.

Version is `86.181/1043` (`86.181-personal-online-diagnostics` on Personal Android). This candidate also carries the v86.180 request-scoped Temu capture IDs that allow repeated products/options to be added, the Home-tab store-switch gesture/hint, and the stable bottom surface. Standard and Personal web builds passed TypeScript, release hardening, SHEIN freeze guard, Temu size/capture guard, store-surface guard, and low-end performance budgets. Final Personal budget: startup JS `640,029/720,000`, total JS gzip `260,668/370,000`, CSS `69,819/70,000`, fonts `81,364/100,000`, shipped store scripts `248,358/470,000`, and SHEIN source `554,331/600,000` bytes. Standard web is synchronized to iOS and Personal web to Android. The protected iPhone `0.25s` recompose path and `JSON.stringify` region equality guard were not changed.

Android Personal ARM64 Release test artifact: `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.181-Android-Online-Diagnostics-Test.apk` (workspace copy `output/otlobli-v86.181-personal-arm64-online-diagnostics-release.apk`), `195,372,614` bytes (`186.32 MiB`), SHA-256 `A984FE415827B31621276F33BE08AA023E260837CF00380DAB5107B23CC6A549`. It is package `com.otlobli.app`, ARM64 only, minSdk 26/target 36, R8/resource-shrunk, non-debuggable, cleartext-disabled, contains no source maps, and is APK Signature v2/v3 signed with the local Android debug certificate for device testing only; do not upload it to Play. Android x86_64 debug `86.181/1043` was installed in place on the Android 15 emulator, launched, opened Account → Support, and rendered the final diagnostic form with no matching FATAL/ANR/MOZ_CRASH. Evidence: `output/v86.181-emulator-online-diagnostics.png`. The real Note 8 was not connected, so weak physical-device acceptance remains pending.

iOS Universal unsigned test artifact: `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.181-iPhone-iPad-Online-Diagnostics-UNSIGNED.ipa`, `6,528,632` bytes (`6.23 MiB`), SHA-256 `80487AB4E95BFFF74731CBFCE1A4B9C937F933AA235FE74FE099D2510A1CA09C`. GitHub Actions run `31807331199` succeeded from isolated branch `codex/ios-v86-181-online-diagnostics`, commit `8b813be226719c53654d21f72e70d1aa13862834`. Archive inspection confirms `com.otlobli.app`, version/build `86.181/1043`, ARM64 iPhoneOS, iOS 15+, `UIDeviceFamily=[1,2]`, the local Syrian flag, the online-diagnostics marker, no source maps, no app `_CodeSignature`, and no embedded provisioning profile. Native binary strings retain `otlobliForceRecompose` and `appDidBecomeActive`.

Acceptance boundary: the IPA is unsigned and must be signed/provisioned before installation. No real iPhone/iPad test was performed. After install, reproduce the store failure, go to Account → Support, send the diagnostic report, and then read it in Admin → App reports. Five real iPhone 16 background/resume cycles plus a separate force-quit/cold-launch test remain mandatory. Because consent is required and the trace is memory-only, a hard process crash before the user opens Support does not upload automatically.

# v86.179 — Temu one-tap store return and bounded capture acknowledgement (2026-08-14)

Personal Android now labels the active Temu Home tab as `المتاجر`; one press hides the persistent Gecko surface and returns directly to the SHEIN/Temu chooser without reloading or destroying the Temu session. A compact `بدّل هنا ↑` cue appears only until that first successful press, persisted under `talabieh.storeSwitchHintSeen.v1`. It is event-driven and adds no observer, interval, animation, or network work. Android 15 x86_64 emulator evidence is `output/v86.179-emulator-temu-store-tab.png` and `output/v86.179-emulator-one-tap-store-return.png`; the first press returned to the hub, and the next entry retained the session with the cue gone.

Temu capture is now fail-closed and bounded across the whole flow. The five-second safety guard starts when the blocking overlay appears, so an exception while parsing a product can no longer leave the spinner or scroll lock forever. Every asynchronous attempt is caught, a rejected native hand-off surfaces `addToCartNack`, and the extension shows success only after React has synchronously persisted the cart update and calls native `acknowledgeAdd()`. Gecko holds the original `sendNativeMessage()` result for at most 3.5 seconds; timeout/destruction rejects it. This preserves the existing in-place PDP behavior—capture does not navigate away to Cart—and adds no persistent timer.

Exact Temu code `CA5773086` was opened on the emulator before the fix; its red-gradient option and size `M` were selected and the Otlobli capture control was present. After installing the v86.179 debug build, Temu required a visual security CAPTCHA because the installed signing/build fingerprint changed. It was not solved or bypassed, so post-fix live acceptance on that exact product remains pending and must not be claimed. The native acknowledgement path compiled in both Debug and R8 Release, and source guards cover the start-to-finish timeout, NACK, explicit cart acknowledgement, one-tap exit, and hidden-session invariants.

Version is `86.179-personal-temu-capture-ack/1041` on Android and `86.179/1041` on iOS. Standard and Personal builds passed TypeScript, release hardening, SHEIN freeze guard, Temu size/price gate, store-surface guard, and low-end budgets; final Personal CSS is `69,978/70,000`, startup JS `630,865/720,000`, total JS gzip `257,334/370,000`, and shipped store scripts `248,358/470,000` bytes. Standard web was synchronized to iOS and Personal web to Android. iPhone native recompose code/timing was untouched.

Android test artifact: `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.179-Android-Temu-Capture-Fixed-Release-Test.apk` (workspace copy `output/otlobli-v86.179-personal-arm64-temu-capture-ack-release.apk`), `195,369,394` bytes (`186.32 MiB`), SHA-256 `28997FE21FD4CF7D573FC9D6D2FC1118EA4A5891198D7266A59982610F1F1CD8`, package `com.otlobli.app`, ARM64 only, minSdk 26/target 36, R8/resource-shrunk and non-debuggable. It is v2/v3 signed with the local Android debug certificate for device testing only; do not upload it to Play. Real Note 8/weak-phone capture and extended background acceptance remain pending.

iOS Universal test artifact: `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.179-iPhone-iPad-Universal-Final-Test-UNSIGNED.ipa`, `6,525,440` bytes (`6.22 MiB`), SHA-256 `E86403F3079CCB7C6A1CBB75260B0A01B7FC726BA7970EB658E751C4605F4615`. GitHub Actions run `31799688321` succeeded in `3m15s` from isolated branch `codex/ios-v86-179-universal`, commit `77598df9bf59090f322f388db4b6efbcdb0ef811`. Direct archive inspection proves `UIDeviceFamily=[1,2]`, bundle `com.otlobli.app`, ARM64, iOS 15+, version/build `86.179/1041`, the local Syrian flag, no source maps, no app-level `_CodeSignature`, and no embedded provisioning profile. It must be signed/provisioned before installation. No real iPhone/iPad acceptance was performed; five iPhone 16 background/resume cycles plus a force-quit/cold-launch test remain required.

# v86.178 — low-end Android runtime and deferred store payload (2026-08-14)

This batch keeps every customer feature while reducing startup/main-thread cost for 4 GB and older Android phones. The SHEIN/Temu capture constants are no longer statically imported by `App.tsx`; `src/services/storeCaptureBundle.ts` is fetched only on the first store entry. The production startup entry fell from `883,614` to `629,961` raw bytes (`253,653` bytes, or `28.7%`), while the deferred store chunk is about `256 KB` raw / `68 KB` gzip. A new `720,000`-byte startup-entry budget locks this split without raising any existing budget. Final Personal metrics passed: largest JS `629,961/1,200,000`, total JS gzip `256,792/370,000`, CSS `69,838/70,000`, fonts `81,364/100,000`, shipped store scripts `247,442/470,000`, and SHEIN source `553,085/600,000` bytes.

Native Android now marks Gecko inactive and unfocused while the whole app is in the background, restores it only when the store surface is visible, and suspends media while inactive. Ordinary in-app Store → Cart/Profile hiding deliberately still keeps the Gecko session active: deactivating there can interrupt Temu's security hand-off, and `verify:temu-size-gate` continues to enforce that invariant. Likely low-end Android devices (`deviceMemory <= 4`, four or fewer logical cores, or Android 10 and older) receive a pre-paint profile that removes expensive blur/animation/shadows and applies bounded off-screen containment to long customer lists. Cart/order/tracking images now have fixed dimensions and lazy/async decoding where applicable. No payment, wallet, completed-order, capture, price, or iPhone recompose logic changed.

Standard and Personal web builds, TypeScript, release hardening, SHEIN freeze guard, Temu size/price gate, store-surface lifecycle guard, and performance budgets passed. Standard web was synchronized to iOS and Personal web to Android. Playwright passed at `320×568` and `360×640` with no horizontal overflow and proved that the deferred store bundle is absent at the store hub and requested only after a store tap. On an Android 15 x86_64 emulator constrained to 4 cores and `4,013,932 kB` RAM, a clean Personal Release cold launch completed in `998 ms`; the store hub used `73,364 KB` total PSS. Live Temu reached its security challenge/feed, Cart opened on the first press, Store returned to the preserved Temu session, a background/resume cycle returned hot in `164 ms`, and no matching FATAL/ANR/MOZ_CRASH appeared. Gecko's allocated memory remained resident (settled package PSS about `274 MB`) while inactive, so the emulator result proves lifecycle stability and suspended execution, not physical-device memory reclamation or weak-CPU acceptance.

Final Android test artifact: `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.178-Android-4GB-Smooth-Release-Test.apk`, Personal ARM64 Release `86.178-personal-low-end-runtime/1040`, `195,368,613` bytes (`195.37 MB`, `186.32 MiB`), SHA-256 `B4B6809398F170F510C85E28917172B89B1BF4E84A3E3F9122BCE10B906E03ED`, package `com.otlobli.app`, minSdk 26/target 36. It is R8/resource-shrunk, non-debuggable, contains no source maps, and is signed with the local Android debug certificate for device testing only; do not upload it to Play. The ARM64 copy under `output/otlobli-v86.178-personal-arm64-low-end-release.apk` is authoritative because the Gradle output path was later reused for the x86_64 emulator build. A real old/weak ARM64 Android phone was not connected for this batch, so final physical-device scrolling, store-switch, product-capture, and extended background acceptance remain pending.

iOS `86.178/1040` now has one Universal ARM64 device-test archive for both iPad and iPhone: `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.178-iPad-iPhone-Universal-Final-Test-UNSIGNED.ipa`, `6,524,846` bytes (`6.52 MB`, `6.22 MiB`), SHA-256 `ED10F4C41A358CD144854B2138B7709C2CAFF7F4B792D2B3620AF767F5135938`. GitHub Actions run `31796588474` succeeded in `3m12s` from isolated branch `codex/ios-v86-178-ipad-universal`, commit `d803a2046ef65494a55645ff75d895516cc84e78`. The built `Info.plist` was parsed after Xcode and contains `UIDeviceFamily=[1,2]`, `com.otlobli.app`, iOS `15.0+`, and portrait orientation for iPad/iPhone; the executable is 64-bit ARM64 iPhoneOS. Archive inspection found the local Syrian flag and deferred store chunk, no source maps, no app-level `_CodeSignature`, and no embedded provisioning profile. Native binary strings retain `otlobliForceRecompose` and `appDidBecomeActive`.

The workflow now checks both the Xcode target and the built app's `UIDeviceFamily` before uploading a Universal artifact. Browser visual acceptance passed at iPad `768×1024` and `1024×1366` with zero horizontal overflow; evidence is `output/playwright/v86.178-ipad-768x1024-login.png`, `output/playwright/v86.178-ipad-768x1024-store-hub.png`, and `output/playwright/v86.178-ipad-1024x1366-store-hub.png`. The IPA remains unsigned and needs the owner's normal signing/provisioning method before installation; the Apple Developer account was deliberately not connected yet. No real iPad/iPhone acceptance was performed. Because shared store bootstrap loading changed, five real iPhone 16 background/resume cycles plus a separate force-quit/cold-launch test remain mandatory; native recompose timing and the verified `0.25s` delay were untouched.

# v86.177 — Temu captures the selected variant's live price (2026-08-14)

The reported issue was reproduced on physical Note 8 product `607534043768396`. The blue option's active SKU drawer showed `531.03 SAR`, while the gray option showed `528.93 SAR`; Temu deliberately left the mounted PDP `.curPrice-*` at `531.03 SAR` after gray was selected. The old `temuPriceUsd()` read only the first `.curPrice-*`, so both variants captured the blue price. The corrected reader first inspects a visible, structurally proven Temu SKU dialog (last eight dialogs only), preferring its `salePriceRich`/current price, and falls back to the PDP `curPrice` only when no active variant price exists. There is no observer, permanent timer, cache, or broad price scan.

Live DOM validation on that exact product returned gray `528.93 SAR → $141.22` and blue `531.03 SAR → $141.79`, even while the stale PDP value remained `531.03 SAR`. `verify:temu-size-gate` now locks both different-price cases plus hidden-drawer and unrelated-promo fallbacks. Standard and Personal builds passed release hardening, SHEIN freeze guard, Temu gate, store-surface guard, TypeScript, and the low-end budget: largest JS `883,614/1,200,000`, total JS gzip `256,338/370,000`, CSS `69,838/70,000`, fonts `81,364/100,000`, shipped store scripts `247,442/470,000` bytes. Android and iOS were synchronized successfully; iPhone recompose timing and SHEIN entry behavior were not changed.

Personal ARM64 debug `86.177-personal-temu-variant-price/1039` was installed in place on the physical `SM-N950F` Note 8 with `adb install -r`, preserving app data and the existing cart. It launched, entered Temu, and returned to the normal Temu feed with no matching FATAL/ANR/MOZ_CRASH. The installed APK contains the generated Gecko capture script and the new `salePriceRich` reader. Desktop artifact: `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.177-Android-Temu-Variant-Price-Final-Test.apk`, `205,003,387` bytes, SHA-256 `B441E2FA4B10C8D7A99F3EB41EE091B02CCB185F733E0B34332FC92429E05904`, package `com.otlobli.app`, ARM64, minSdk 26. After installation, reopening the exact product triggered Temu's visual security verification; it was not bypassed or automated, so a second end-to-end post-install add on that route remains unclaimed. No cart row was added or deleted during validation.

The updated iPhone test archive is `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.177-iPhone-Latest-Final-Test-UNSIGNED.ipa`, `6,524,330` bytes (`6.52 MB`, `6.22 MiB`), SHA-256 `DB60DB27F7E2936E5F60F476D9C6991805CA93B6BD5630CD82E72436F36B293E`. GitHub Actions run `31755017217` succeeded from isolated branch `codex/ios-v86-177-temu-variant-price`, commit `0421f5b3b0535720a015e956d47ec300f2102465`. Archive metadata is `com.otlobli.app`, `86.177/1039`, ARM64 iPhoneOS with iOS `15.0+`; inspection confirmed the v86.177 Temu selected-variant-price marker and `salePriceRich` reader, the local current Syrian flag, no source maps, no app-level `_CodeSignature`, and no embedded provisioning profile. The native binary retains `otlobliForceRecompose` and `appDidBecomeActive`. The IPA needs the owner's normal signing/provisioning before installation. No real-iPhone acceptance was performed; five real iPhone 16 background/resume cycles plus a separate force-quit/cold-launch remain mandatory. Payment, wallet, completed orders, repeat-capture behavior, Temu option selection/session logic, SHEIN capture, and native recompose timing were untouched.

# v86.176 — SHEIN fast entry only; iPhone test archive (2026-08-14)

This batch is deliberately limited to SHEIN store-entry speed. The measured causes were (1) `switchSelectedStore()` clearing the healthy HTTP/WebKit cache on every ordinary Temu → SHEIN switch, making every return a cold load, and (2) Android passing `isPresentAfterPageLoad: true`, so the native Otlobli loading cover itself was withheld until SHEIN finished `onPageFinished`. Ordinary switches now preserve cache; the existing bounded damaged-session/cart-product recovery still owns cache resets. Android presents the branded cover immediately, while iOS still evaluates `isPresentAfterPageLoad` to `true` and remains hidden until readiness, preserving the protected iPhone reveal/lifecycle path.

Physical Note 8 validation on the final corrected `86.176-personal-shein-fast-entry/1038` debug build showed the branded cover in the screenshot taken about `0.9s` after the hub tap; native logs recorded `openWebView` at `01:36:13.959`, first `browserPageLoaded` at `01:36:18.351` (~`4.39s`), and signed `sheinSaudiReady` at `01:36:19.168` (~`5.21s`). There was no matching FATAL/ANR/MOZ_CRASH. Earlier reproduction had delayed visible native focus by roughly `7.5s`. The VPN/geo probes were not the bottleneck (measured roughly `61–396ms`). Evidence: `output/v86176-final-cover.png` and the final device log.

After the user clarified scope, the attempted repeat-Temu-capture change was completely removed. The v86.175 `temuAddInFlightRef` behavior remains; there is no fingerprint/two-second capture logic in the final diff or iOS build branch. No Temu product was added during the mistaken navigation, no app data was cleared, and the corrected build was installed in-place on the Note 8 to replace the temporary test build while preserving its data. Payment, wallet, completed orders, Temu capture/SKU/session code, SHEIN injected capture code, and native iPhone recompose timing were not changed.

The final iPhone file is `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.176-iPhone-SHEIN-Fast-Final-Test-UNSIGNED.ipa`, `6,524,164` bytes, SHA-256 `4FDADE9249EF115DD55C9EC66DE8FE1FB2BCBBF37C134935354F556CE927F292`. GitHub Actions run `31750234595` succeeded from isolated branch `codex/ios-v86-176-shein-fast-entry`, commit `efed15b58757531cce6552bf95a510494da07475`. Archive metadata is `com.otlobli.app`, `86.176/1038`, iPhoneOS with iOS `15.0+`; it contains the local current Syrian flag, no source maps, no app-level `_CodeSignature`, and no embedded provisioning profile. `otlobliForceRecompose` and `appDidBecomeActive` remain in the native binary.

Validation passed: TypeScript, standard and personal web builds, release hardening before/after build, SHEIN freeze guard, unchanged Temu gate guard, store-surface guard, low-end performance budget, Android/iOS Capacitor sync, isolated macOS/Xcode unsigned build, IPA metadata/archive inspection, and Note 8 in-place install/launch. Final standard budget: largest JS `883,072/1,200,000`, total JS gzip `256,185/370,000`, CSS `69,838/70,000`, fonts `81,364/100,000`, shipped store scripts `246,903/470,000` bytes. The IPA still needs the owner's normal signing/provisioning before installation. No real-iPhone acceptance was performed; five real iPhone 16 background/resume cycles plus force-quit/cold-launch remain mandatory before release acceptance. Active dirty-worktree changes were not staged or committed; only the isolated iOS build branch was committed and pushed.

# v86.175 — hardened release pipeline + repaired login with the current Syrian flag (2026-08-13)

`C:\Users\MOHAMMAD\Desktop\Otlobli-v86.175-Android-Final-Test.apk` is **rejected for the owner's Note 8**. It is the 4 MB standard customer variant, while the recent Note 8 Temu work lives behind `TEMU_PERSONAL_SITE=true` and requires the packaged Gecko engine. Installing that standard artifact after the old `86.172-personal` build therefore removed the embedded Temu path and correctly looked as though the recent work was absent. Do not use that misleadingly named standard artifact for Personal/Note 8 acceptance.

The corrected Note 8 artifact is `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.175-Personal-Note8-Final-Test.apk`, `195,367,479` bytes, SHA-256 `5BFF729F8920C96A71CCB7BF600ECA5E19ECFAA288427F97466418115A4C7E86`. It is the ARM64 R8/resource-shrunk Release `86.175-personal-release-hardening/1037` (minSdk 26), signed with the local Android debug certificate only for installation, verified with APK Signature v2/v3, and non-debuggable (`run-as` refused it). Archive inspection confirmed Gecko `libxul.so`, the Temu WebExtension capture script, the current local Syrian flag, and no source maps. It was clean-installed on the physical `SM-N950F` Note 8 running Android 9 after explicitly uninstalling `86.172-personal`.

Final iPhone device-test artifact is `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.175-iPhone-Final-Test-UNSIGNED.ipa`, `6,524,183` bytes, SHA-256 `BB70D4CE394A61CCEA18E895340C1CE1B77C8503DF3BCBEFFABD219A91BFE182`. The same ARM64 IPA is used on both weak and strong iPhones running iOS 15 or later. GitHub Actions macOS/Xcode run `31742547246` succeeded from the isolated branch `codex/ios-v86-175-final-test` at commit `d5f96ef81657b98c5332f45cde930c820dd67055`; the app metadata is `com.otlobli.app`, version/build `86.175/1037`. Archive inspection confirmed that it is unsigned and has no embedded provisioning profile, has no source maps or old Syrian flag emoji, includes the current local Syrian flag, lacks selected readable injected-script signatures, and retains `otlobliForceRecompose` plus `appDidBecomeActive`. It must be signed/provisioned through the owner's normal iPhone installation method before device testing and is not an App Store upload artifact.

Version is `86.175/1037` (`86.175-personal-release-hardening` for the personal Android variant). Release hardening is now enforced instead of documented only: Android Release enables R8 minification, resource shrinking, optimized ProGuard rules, non-debuggable/JNI-non-debuggable output, zip alignment, backup/data-transfer exclusion, and cleartext blocking. Capacitor's broad plugin keep rule is narrowed while preserving bridge annotations and constructors. iOS Release has dead-code stripping, post-processing, installed-product/Swift stripping, and testability disabled. Vite emits no source maps, and build-time Terser compilation minifies the large SHEIN/Temu injected-script strings that ordinary Vite minification previously left readable. Exact patched dependencies are pinned and `verify:release-hardening` is mandatory before and after every build.

The committed in-app-browser patch previously contained a live relay credential. It is sanitized to two `OTLOBLI_RELAY_KEY_PLACEHOLDER` values and the verifier rejects any committed replacement. This does **not** make a static credential inside a published client secret: postinstall still injects the local relay value into native sources, so a determined attacker can recover it from a running or published binary. The required final architecture is documented in `docs/APP_BINARY_PROTECTION.md`: Play Integrity / App Attest → backend verification → short-lived, request-bound, replay-protected relay tokens → removal and then rotation of the static key. No worker/backend deployment or key rotation happened in this batch because doing either before a compatible attested client rollout would break existing apps. No client-only technique can honestly promise that downloaded code is impossible to inspect.

The login page is also repaired. Syria no longer uses the platform `🇸🇾` emoji anywhere in the country option; it uses the bundled `public/flags/syria-independence-flag.svg` (green, white, black, three red stars), including the order route. The country control shows the image plus `+963`, while the accessible select retains full country names. Copy/hierarchy, phone labeling, live submit status, keyboard focus, safe areas, zoom support, favicon and green theme colour were reviewed. Playwright passed at `320×568`, `360×740`, and desktop with no horizontal overflow; the local flag loaded at `900×600`, the old Syrian emoji was absent from options, and the only development console message was React DevTools. Native Android visual proof is `output/playwright/native-v86.175-standard-launch.png`.

Validation passed: standard and personal web builds, TypeScript, release-hardening pre/post checks, exact minified injected-script syntax checks, SHEIN iPhone freeze guard, Temu size gate, store-surface guard, Android R8 personal build, Android standard debug + shrunk Release packaging, Android/iOS synchronization, and Android 15 emulator install/launch (`MainActivity` resumed; zero matching FATAL/ANR). Final low-end measurements: largest JS `883,137/1,200,000`, total JS gzip `256,190/370,000`, CSS `69,838/70,000`, fonts `81,364/100,000`, and shipped injected scripts `246,903/470,000` bytes. The CSS limit was not raised.

Artifacts: personal ARM64 debug `output/otlobli-v86.175-personal-arm64-debug.apk` — `205,002,911` bytes — SHA-256 `400FC43463398DE67ADC5BB76277BC64847B975FBC12811E16A3EB2EACDDA3A5`; standard universal debug `output/otlobli-v86.175-standard-universal-debug.apk` — `11,104,319` bytes — SHA-256 `7B920C13A704E048A01BA23DCBDD4E050A6B4C6B06B65A5B54B071CF1C91ADD8`. These are test builds, not publication artifacts. The hardened standard Release audit APK is unsigned and stays under `android/app/build/outputs/apk/release/app-release-unsigned.apk` — `3,978,864` bytes — SHA-256 `9A3161B5EC637E02FAA52C843A8EB00B89BBA4714DD0F617A98B419238F2D7EF`; production signing properties are absent. Its archive contains the local flag and no source maps, old Syrian emoji, or selected readable SHEIN implementation signatures.

**Acceptance limits:** the corrected Personal Release passed a real Note 8 clean install and launch, registered Gecko plus the bundled WebExtension, opened the live Temu Saudi site, continued to the live product feed after closing Temu's own security challenge, switched to Otlobli Cart on the first press, and survived three background/resume cycles without matching FATAL/ANR/MOZ_CRASH. Proofs are `output/note8-v86.175-personal-launch.png`, `output/note8-v86.175-personal-temu.png`, `output/note8-v86.175-personal-temu-after-captcha-close.png`, `output/note8-v86.175-personal-cart.png`, and `output/note8-v86.175-personal-resume3.png`. Store-open rendering measured 73 frames with 16 janky (`21.92%`), p50 `12ms`, p90 `26ms`, p95 `42ms`, and p99 `150ms`; active Gecko total PSS was approximately `289,692 KB`. Product selection/add-to-cart/checkout and SHEIN were not accepted in this turn because the first Temu navigation presented the security challenge. The standard login route also remains a real weak-phone UX issue: on Note 8 the keyboard clips the submit/alternate-login content and its startup-plus-keyboard sample was 16/34 janky frames (`47.06%`); the Personal build starts at store selection and does not expose that route. The unsigned iOS archive still has not been signed, installed, or accepted on a real iPhone; weak/strong iPhone acceptance, five iPhone 16 background/resume cycles, and a separate force-quit/cold-launch test remain mandatory. No payment, wallet, completed-order, SHEIN recompose timing, Temu session/SKU, or deployed backend behavior changed. No current dirty-worktree changes were staged or committed, and no PR or deployment occurred.

# v86.174 — measured Temu surface geometry restores the true Otlobli navigation colours (2026-08-13)

The reported pale Otlobli bar was reproduced on the Android 15 emulator and measured before changing code. MainActivity had no lingering dialog or `FLAG_DIM_BEHIND`; SurfaceFlinger reported the Gecko `SurfaceView` and activity at sRGB, alpha/dimming ratio `1.0`, and stable Temu whites were real `255,255,255`. The fault was geometry and elevation: the embedded Temu layer ended at `y=2164` while the React navigation began at `y=2102`, covering its first 62 pixels, and `storeLayer.setElevation(24dp)` cast a measured shadow over the remainder. At the centre of the navigation the pre-fix background fell from `204` at the store edge through `212`, `233`, and `249` instead of the host screen's constant `255`.

The personal Temu layer now has no elevation shadow and reserves the system navigation-bar inset in addition to React's 90dp navigation. On the installed v86.174 emulator build its SurfaceFlinger bound ends at `y=2101`; the React navigation starts at `y=2102`, and all sampled blank navigation rows are `255,255,255`. No CSS colour was changed. `scripts/verify-store-surface.mjs` now guards the inset calculation, absence of store-layer elevation/dim, alpha restoration, session-preserving hide, and the existing `SurfaceView`-first screenshot path.

Regression checks passed on Android 15: profile → Temu retained the same Gecko surface/session, background → resume retained the visible page, a real Temu product opened with `otlobli-add-btn` and returned normally while every navigation sample remained white, the shake dialog preview contained the live Temu surface rather than black, dismissal left one app window and a white navigation with no dim, and no FATAL/ANR appeared. One cold-start sample was `2582ms` versus the pre-change `3005ms`, but this single emulator sample is not claimed as a performance improvement. Temu surface appearance after the hub tap measured `2073ms` on this run.

Validation passed: standard and personal web builds, `verify:shein-freeze-guard`, `verify:temu-size-gate`, new `verify:store-surface`, `verify:performance-budget`, Android/iOS synchronization, standard Android build, and personal x86_64/ARM64 Android builds. The installed emulator artifact is `output/otlobli-v86.174-temu-personal-x86_64-debug.apk` (`224,468,290` bytes, SHA-256 `597DC0F2B741EB7ED5F640BE5877C7CE53669A50736F7292C231419A3C05981F`). The ARM64 artifact is `output/otlobli-v86.174-temu-personal-arm64-debug.apk` (`205,045,396` bytes, SHA-256 `408B41F463CB558BD3E75D2CF224D276AB9EFEF2EE3486D5AC1833783B3917EB`). The standard APK is `output/otlobli-v86.174-standard-universal-debug.apk` (`11,146,812` bytes, SHA-256 `901F1AA01639596DF02454FB4812254496B61FABC162B3A64BFDA8813A8840D3`).

**Acceptance limits:** v86.174 is installed and measured on the Android 15 emulator only. The real Note 8 is not connected and has not accepted this build. iOS web/version is synchronized at `86.174/1036`, but there was no Xcode build or real-iPhone acceptance and none of the mandatory iPhone 16 lifecycle cycles were performed. Payment, wallet, completed orders, SHEIN lifecycle/recompose, Temu session identity, SKU logic, and report transport were not changed.

# v86.173 — exact Temu size drawer + shake-to-report with the live product screenshot (2026-08-13)

The exact Temu product `601101949689075` was diagnosed through Gecko remote debugging. Its size drawer did open, but the first-paint promo blocker classified the real SKU dialog as a discount popup because the dialog contains repeated `خصم 75%`, then hid it. Real product dialogs are now structurally allowlisted by their `role=dialog`, radio/SKU/spec descendants, and the drawer remained visible after five seconds on the same product.

The size gate had two additional concrete faults: Arabic `الحجم` and Temu's current `.specTypes-*` markup were not recognized, and the generated regex lost its backslashes inside the template literal. The parser now recognizes the current markup, preserves `/([0-9]+)\s*(?:الحجم|حجم)/` in the generated script, and ignores the duplicate collapsed dimension when an authoritative expanded radio group exists. On the exact product, pressing Otlobli add before choosing a size produced `حدد المقاس أولاً` and kept the drawer open; choosing `الملكة: 160*200*20 سم` then produced the normal captured-product success overlay.

Android now supports an Instagram-style issue report: while the app is resumed, two strong accelerometer peaks open a native Arabic dialog. The screen is captured **before** the dialog appears, so shaking from inside a Temu product includes the product image and the exact page state. GeckoView renders through a separate `SurfaceView`; window PixelCopy returned a black image, so the reporter deliberately captures the largest visible `SurfaceView` first and falls back to the window for normal screens. The verified emulator capture contains the live Temu page, not a black placeholder. The customer adds a 3–800 character note and sends the screenshot, store/screen, app version, device identity, and available customer identity.

The backend is live on Supabase project `dcicqdprtyhwmhegabay`: migration `20260813170000_app_issue_reports.sql`, private `app-issue-reports` bucket, and deployed JWT-verified `app-reports` function. Anonymous app submissions are validated, limited to a 1.5 MB image and a 20-second per-device interval; listing, signed screenshot URLs, status changes, and admin notes require `x-admin-pin`. The Admin dashboard has a responsive `بلاغات التطبيق` panel with filters, 20-second refresh, lazy screenshots, report metadata, status, and follow-up note. It was deployed to the official production alias `https://talabieh-admin.vercel.app` as Vercel deployment `dpl_7JAQTMXiFEipNpX1VzgEwjxhFXqM`; a no-cache asset readback proved that the live bundle contains both `بلاغات التطبيق` and `app-reports`. Emulator report `3efc830f-9eff-4af8-9c2d-d3f0b1438e48` was received end to end with a signed screenshot URL and was marked `resolved` as an acceptance test. A second acceptance run shook the emulator while a real Temu tool-set product page was visible: report `1e108393-d2ea-4676-a7a5-3cdba6713dbb` reached production, its signed 135,354-byte JPEG was downloaded and visually confirmed to contain the product image, title, price, quantity controls, and page state, then the report was marked `resolved`.

Validation passed: exact live-product Gecko checks, shake dialog and real Surface screenshot on Android 15 emulator, an additional shake/send/readback while inside an actual Temu product, live POST/GET/PATCH, `npm run build`, `npm run build:temu-personal`, Admin build, SHEIN freeze guard, Temu size-gate guard, performance budget, Android/iOS synchronization, personal x86_64 emulator build/install, and personal ARM64 build. Admin reports were visually checked at 1440×1000 and 390×844. The ARM64 artifact is `output/otlobli-v86.173-temu-personal-arm64-debug.apk`, `205,045,388` bytes, SHA-256 `385A2D27EE3066D0FBD5917BB4513574D7CCD2DFAF164624FFA97109BA9DFB26`, package `com.otlobli.app`, version `86.173-personal-size-reports/1035`, native ABI `arm64-v8a`.

**Acceptance limits:** the feature was proven on the Android emulator, not yet on the real Note 8. Shared web assets and version `86.173/1035` are synchronized into iOS, but the native shake/capture plugin in this batch is Android-only; no iOS build, no iPhone shake acceptance, and none of the required iPhone 16 background/resume cycles were performed. The existing iPhone freeze invariant was not changed.

**Next-chat handoff:** `HANDOFF_TO_CODEX.md` now begins with the factual v86.173 state, exact artifact/backend/admin deployment, acceptance boundaries, and the one new open issue. Local Playwright state and `output/` are ignored by Git as tool/build evidence (not deleted). The open issue is visual only and not yet diagnosed: entering Temu reportedly makes the Otlobli bar pale and the Temu surface darker. Reproduce and measure native dim/scrim, SurfaceView alpha, overlays, and focus restoration before changing colors.

# v86.172 — the invisible store gate that froze Temu product pages (2026-08-12)

The user reported a Temu product that "adds itself without opening the options", where trying to reach the size options made the page "lock up". Both are one fault, found by reading the live page instead of guessing.

**How it was found.** Screenshots showed a Temu product page that did not move a single pixel over four idle seconds — its own countdown timer frozen — while the injected WebExtension kept posting messages every ~1.5s and the content process burned 66% CPU. Three hypotheses were tried and each was disproven on the device: an orphaned `overflow:hidden` scroll lock (fixed anyway in v86.171, changed nothing here), a detached Gecko compositor (reattach made no difference; **that change was reverted**, not shipped), and CPU saturation (Temu's own home page runs hotter at 93% and scrolls fine).

Enabling Gecko remote debugging in debug builds settled it. Over the protocol the page was completely healthy: `readyState` complete, 1097 nodes, `body.scrollTop = 600` applied instantly and **87,671 pixels changed on screen**. Yet a window-level capture listener recorded **zero** touch events from a real swipe. Rendering fine, scripting fine, no touch at all — so the blocker was above the page. `uiautomator dump` named it: a React store gate, «اتصالك من منطقة مدعومة، لكن منتجات تيمو لم تكتمل على هذا الجهاز» with an «إعادة تجهيز المتجر» button, laid over the Temu layer. Tapping that invisible button at its dumped coordinates worked instantly and the page moved.

**The fault.** The gate renders whenever `sheinBlockedError`/`no-vpn`/`bad-region`/`offline` is set, but nothing retired the personal Temu surface underneath. Gecko paints over React, so the gate is invisible while still taking every touch — the customer sees a live Temu page that answers nothing, cannot scroll to the size options, and the add button therefore captures no size. The gate now hides the store surface when it appears: if a gate is worth showing, it is worth seeing.

**Not yet verified end to end:** the gate could not be provoked on demand during this session, so the fix is verified by mechanism and by the proven cause, not by watching the gate appear and become visible. Provoke it (airplane mode mid-session) on the next pass.

Artifact `86.172-personal-invisible-gate-fix` / `1034`: `output/otlobli-v86.172-temu-personal-arm64-debug.apk`, `205,027,384` bytes, SHA-256 `91695CAA88B1DF2C4EBDB16FD9DAFBAB462F8BC4EA4950DF2D8E4B1E81080747`. Installed on Note 8. Gecko remote debugging is enabled for `BuildConfig.DEBUG` only.

# v86.171 — release an orphaned scroll lock (2026-08-12)

`showAddingOverlay()` sets `overflow:hidden` and `removeOverlay()` was the only path back, so any skipped path left a page unscrollable forever. Restored on both `body` and `documentElement`, plus a self-heal in `tick()`: a scroll lock with no overlay on screen is never correct. This did **not** cause the frozen Temu product page above — it is a real defect fixed on its own merits.

# v86.170 — a cart product no longer throws the customer onto a full-screen gate (2026-08-12)

**A regression introduced by v86.168, reported by the user and fixed here.** Removing the stale-verdict refusal was right, but the replacement sent the customer to Home with `setScreen('home')` before the connection check had answered. When that check was slow or failed once, they landed on the full VPN gate — «تم التحقق أن الـ VPN شغّال (قطر)، لكن متجر شي إن لم يفتح من هذا السيرفر» — with no way back to what they tapped. The cart felt like it had stopped opening products entirely. The old toast was less disruptive than this, so the fix was a net loss in exactly the case it was meant to improve.

Tapping a cart product now **stays in Cart** while the check runs, showing «جاري التحقق من الاتصال...». A new effect watches the settled result: `ok` enters the store and opens the queued product; `no-vpn`/`bad-region`/`offline` clears the queue and reports the reason in Cart, where the customer still has their list. Nothing reaches a full-screen gate that the customer did not navigate to themselves.

Verified on Note 8 from a cold start, going straight to Cart without opening a store first — the path that previously produced the gate. The check settled and the product opened to its real SHEIN page (`$21.57`, gallery `1/7`, rating `4.92`). No FATAL or ANR.

Artifacts, version `86.170-personal-cart-stays-put` / `1030`:

- Personal (installed on Note 8): `output/otlobli-v86.170-temu-personal-arm64-debug.apk`, `205,026,976` bytes, SHA-256 `6ABC2982595996E40882903E269D54BBBCC95BF186D1787065C4EC3A2E8523C2`
- Standard: `output/otlobli-v86.170-standard-universal-debug.apk`, `11,129,192` bytes, SHA-256 `16A8FD69C387866274D20E17DE61B254E6B1395F1F1F3A0C6C6D51B1ECE0FB2A`
- iOS synced at `86.170`, **not** built in Xcode, **no iPhone device acceptance**.

# v86.169 — a solved SHEIN verification no longer reports "Access timed out" (2026-08-12)

The user reported completing SHEIN's human check and being told it failed. The same failure was observed independently during v86.168 device testing: SHEIN's own toast, `Access timed out, please refresh the page and try again`, appeared over a correctly solved check.

**The cause is in our code and the codebase already documented the rule it broke.** `ensureSheinSaudiStore()` carries the comment «أثناء تحقق «أنا إنسان»: ممنوع أي إعادة تحميل/كتابة — تصفّر حل المستخدم» and returns early during a challenge. But both paths that *enter* challenge mode called `writeSheinSaudiState()` first — `otlobliEnterChallengeMode()` in `sheinHumanCheck.ts`, and the early challenge-URL branch in `sheinBrowserScript.ts`. That function writes **26 cookies on `.shein.com`** plus a block of `localStorage` keys. Seeding them the instant a challenge appears changes the session fingerprint between the moment SHEIN issues its token and the moment it validates the answer, so a correct answer comes back as a timeout.

Both writes are removed. The Saudi state is now seeded at the first safe moment instead: in the resolution branch, after `otlobliChallengeActive` clears and the page is interactive again, so a session that began on a challenge still gets its region.

Verified on Note 8 after a cold start: SHEIN opened fully in Arabic/Saudi with USD pricing, and the region cookies read back `country=SA`, `currency=USD`, `site_uid=pwar`, `language=ar`, `ship_to=SA`, `store_country=SA` with `__otlobliSheinSaudiStateSeeded` true — the deferral costs nothing on ordinary pages. **A live challenge did not appear during this run, so the fix is verified by mechanism and by absence of regression, not yet by watching a real challenge succeed end to end.** That confirmation is the first thing to do on the next challenge SHEIN issues.

No CAPTCHA is solved, clicked, or bypassed anywhere in this change — the fix is strictly about not disturbing the session while the customer answers.

Validation: `npx tsc -b`, `verify:shein-freeze-guard`, `npm run build`, `npm run build:temu-personal`, `verify:temu-size-gate`, `verify:performance-budget`, `npx cap sync android`, `npx cap sync ios`, personal arm64 and standard Android builds. Budgets: largest JS `1,083,079 / 1,200,000`, JS gzip `286,936 / 370,000`, CSS `69,766 / 70,000`, fonts `81,364 / 100,000`, shipped store scripts `452,006 / 470,000`, SHEIN script source `548,515 / 600,000`.

Artifacts, version `86.169-personal-challenge-cookie-fix` / `1029`:

- Personal (installed on Note 8): `output/otlobli-v86.169-temu-personal-arm64-debug.apk`, `205,026,832` bytes, SHA-256 `8216AAB54AEB2B1249BAB490B94A5841E9A3214908BDE8DB4322E9AB47DB05A9`
- Standard: `output/otlobli-v86.169-standard-universal-debug.apk`, `11,129,036` bytes, SHA-256 `DDEF909607700B8D7D63B08E4FF43774751013DB3A27D9922F3F510061228988`
- iOS synced at `86.169`, **not** built in Xcode, **no iPhone device acceptance**.

# v86.168 — the false VPN gate on SHEIN cart products, proven and removed (2026-08-12)

Three reported faults, all diagnosed on the real Galaxy Note 8 (`SM-N950F`, `988e16384e4f51395230`) before any code changed.

**The false VPN gate was measured, not guessed.** The device network was independently confirmed to have no VPN interface at all (`no tun/ppp`), yet all four geo probes — run from inside the app's own WebView over CDP — returned `QA` (Vodafone Qatar, a fully supported exit), the fastest answering in **77ms**, later **52ms**. Instrumenting `window.fetch` proved the decisive fact: across the entire failing path (open Temu cart product → exit → cart → SHEIN tab → tap product) **not one geo probe fired**. `openStoreProductFromCart()` was refusing from a `vpnStateRef` recorded minutes earlier, showing «شغّل VPN ثم جرّب فتح المنتج مرة أخرى» without ever checking the connection. Tapping the same product *before* the Temu round trip worked; after it the tap looked completely dead, because the toast expired before it could be seen. A stored verdict is now never grounds to refuse: any non-`ok` state re-checks, and Home either opens the queued product or shows the genuine gate with its own diagnosis.

**`switchSelectedStore()` was the other half.** It reset `vpnStateRef` to `idle` and discarded a confirmed supported exit on every store switch. Reachability is per-store and is still re-measured; the internet exit country belongs to the device's connection and now survives the switch. `switchCartStore()` had already learned this lesson in an earlier release — the store switch had not.

**Cart products no longer open over Cart.** The personal Temu branch set `pendingBackTargetRef` to `cart` and left Cart mounted under Gecko, so the bottom bar read «السلة» while a Temu product filled the screen, and backing out landed on an inner Temu page. The product now opens over the store screen, matching where the user actually is.

**A fourth fault surfaced during reproduction and is fixed too.** `openCart`/`openOrders`/`openProfile` hid the Chromium `InAppBrowser` but never the personal Gecko surface, so pressing a bottom tab while Temu was open changed the React screen underneath while Gecko stayed painted over it — the press looked completely dead. `hidePersonalTemuSurface()` now retires whichever store surface is actually on screen.

Verified on the device across two full cycles, the second from a cold start: the cart tab press returns instantly, the Temu cart product opens with the bottom bar on «الرئيسية», and the SHEIN cart product opens to its real page (`$21.57`, gallery `1/7`). SHEIN then issued its genuine human-verification, which the app left usable behind its own guidance strip — **no CAPTCHA is bypassed**. No FATAL or ANR was recorded.

Validation: `npx tsc -b`, `npm run build`, `npm run build:temu-personal`, `verify:shein-freeze-guard`, `verify:temu-size-gate`, `verify:performance-budget`, `npx cap sync android`, `npx cap sync ios`, plus personal arm64 and standard Android builds. Budgets: largest JS `1,082,533 / 1,200,000`, JS gzip `286,637 / 370,000`, CSS `69,766 / 70,000`, fonts `81,364 / 100,000`, shipped store scripts `452,004 / 470,000`, SHEIN script source `547,993 / 600,000`.

Artifacts, version `86.168-personal-no-false-vpn-gate` / `1028`:

- Personal (installed and verified on Note 8): `output/otlobli-v86.168-temu-personal-arm64-debug.apk`, `205,026,472` bytes, SHA-256 `2EE0924741A5B3C02855DF378E6420B58E1A17EC59052EAF5290E1C591C11BCF`
- Standard: `output/otlobli-v86.168-standard-universal-debug.apk`, `11,128,660` bytes, SHA-256 `28C889A9F4DD0BC6E4EAED6DB3FC5F9964E396894F758DFACB337D1CC0EDA2CE`
- iOS is synchronized with the standard web bundle at `86.168`, but was **not** built in Xcode and the required five iPhone 16 resume cycles plus cold-launch test were not performed. **There is no iPhone device acceptance for this batch.**

# v86.167 — exact SHEIN PDP performance + Temu cart links without false VPN gate (2026-08-12)

Diagnosed both reports on the real Galaxy Note 8 (`SM-N950F`, serial `988e16384e4f51395230`) before changing behavior. The Temu-cart failure was not a Temu restriction or a missing VPN: `switchSelectedStore()` reset the host VPN state to `idle`, then `openStoreProductFromCart()` ran the legacy VPN gate before calling the personal Gecko browser. The device network was independently confirmed `NOT_VPN`. Personal Android Temu cart links now enter the already-established Saudi Gecko session directly; the old VPN gate remains untouched for ordinary store launches. A real cart item opened to its Temu Saudi product twice (cart → product → cart → same product) with the session and page preserved and no VPN notice.

The exact reported SHEIN product was identified as product `130872819` (`100pcs/50pcs/1set ... Morandi Hair Scrunchies`). A 12-second DevTools CPU profile on that exact route found `isAddToCartText` consuming `81.14%` of sampled JavaScript time. `hideSheinNativeProductAdd()` selected broad `[class*=add]` wrappers and flattened their large descendant `textContent` before rejecting them by geometry every 650 ms. The fix rejects impossible geometry first and only reads descendant text from bounded small controls. The perpetual cookie discovery scan is now capped, and remaining whole-page checks use layout-neutral `textContent`; the short carrier-error detector skips real 900+ element PDPs. On the installed fixed build, the exact product route was re-opened and SHEIN issued its genuine `/risk/challenge` flow; in a second 12-second profile `isAddToCartText` accounted for `0%` and the page was idle for `96.67%`. This does not bypass SHEIN CAPTCHA, and the challenge must still be completed normally when SHEIN requests it.

The hidden personal Temu view now releases only its rendering attachment and marks the Gecko session inactive/unfocused, then reattaches/reactivates the same session on show. This reduces unnecessary hidden rendering without discarding product history, cookies, or scroll state. Regression guards now lock the direct personal-cart route, hidden-session lifecycle, geometry-before-text ordering, bounded text reads, cookie-scan cap, and carrier-error recognition. The existing SHEIN iPhone detach/reattach and unchanged-region invariants remain intact.

Validation passed: `npx tsc -b`, `npm run build:temu-personal`, `npm run build`, `verify:shein-freeze-guard`, `verify:temu-size-gate`, `verify:performance-budget`, `npx cap sync android`, `npx cap sync ios`, personal arm64 Android build, and standard Android build. Final standard budgets: largest JS `1,082,252/1,200,000`, total JS gzip `286,555/370,000`, CSS `69,766/70,000`, fonts `81,364/100,000`, shipped store scripts `452,004/470,000`, SHEIN script source `547,993/600,000`. No recent app FATAL or ANR was found on Note 8. Personal cold launch measured `ThisTime=2484ms`.

Installed Note 8 artifact: `output/otlobli-v86.167-temu-personal-arm64-debug.apk`, version `86.167-personal-cart-links-pdp-perf/1027`, `205,026,308` bytes, SHA-256 `F41F11614F58797DF787E45A0A5138624E47973FE07349590DC40A8C3F328F0E`. Standard artifact: `output/otlobli-v86.167-standard-universal-debug.apk`, version `86.167/1027`, `11,128,500` bytes, SHA-256 `BF913B434C5E1B1272A6F7E6CF8A03010EE57F5B8F4DF2EB2ADE41363F645B2E`. iOS is synchronized with the standard web bundle and version `86.167/1027`, but was not built with Xcode and the required five real iPhone 16 resume cycles plus cold-launch test were not performed; there is no iPhone device acceptance for this batch.

# v86.166 — بوابة مقاس Temu فورية وصيانة الأداء (2026-08-12)

شُخّص خلل المقاس من مسار الالتقاط نفسه: عند وجود عدة مقاسات بلا `aria-checked`/`aria-selected` صريح كان `temuSelectedSize()` و`otlobliTemuSku()` يستعملان حدّ/خلفية CSS كاحتياط، فيُحسب مقاس غير مختار اختيارًا حقيقيًا. أصبح الاحتياط البصري للّون الافتراضي فقط؛ المقاس المتعدد لا يمر إلا بإعلان Temu الصريح أو نقرة العميل المسجلة لنفس المنتج، بينما يبقى المقاس الوحيد تلقائيًا والمنتج بلا مقاسات صالحًا.

أزيل سبب الانتظار: بوابة Temu كانت تعيد الفحص `10 × 500ms` ثم تراقب الاختيار `20 × 500ms`، مع إعادة التقاط تصل إلى `10 × 500ms` وانتظار صورة حتى `2500ms`. قرار «حدد المقاس أولاً» صار فوريًا، وأعيد التقاط Temu إلى ثلاث قراءات فقط بفاصل `150ms` (حد أقصى `300ms` بعد القراءة الأولى)، وأُرسل المنتج مباشرة لأن صورته مأخوذة من عنصر مرسوم أصلًا. أضيف `scripts/verify-temu-size-gate.mjs` إلى `prebuild` ويغطي: لون افتراضي + مقاس متعدد غير محدد، مقاس صريح، مقاس وحيد، بلا خيارات، وخيار غير متاح.

ضمن صيانة الأجهزة الضعيفة، صارت مؤقتات ساعة الدفع واستطلاع OTP عبر WhatsApp/Telegram ومزامنة مجموعة السلة وتفاصيل الطلب تتوقف حين يكون التطبيق في الخلفية وتنعش مرة عند العودة؛ لم يتغير منطق الدفع أو المحفظة أو الطلبات. نجح `npm run build` و`npm run build:temu-personal` وTypeScript وحارسا SHEIN/Temu وميزانية الأداء وبناء Android القياسي والشخصي ومزامنة Android وiOS. الحدود: أكبر JS `1,081,662/1,200,000` (الشخصي `1,081,661`)، JS gzip `286,415/370,000` (الشخصي `286,411`)، CSS `69,766/70,000`، الخطوط `81,364/100,000`، سكربتات المتجر `451,727/470,000`، ومصدر السكربت `547,471/600,000`.

ثُبتت النسخة الشخصية `86.166-personal-fast-size/1026` وWebExtension `1.3.14` على Galaxy Note 8 الحقيقي `SM-N950F`/`988e16384e4f51395230`. التشغيل البارد بعد فتح الجهاز `ThisTime=2299ms`. على منتج حقيقي متعدد المقاسات ظهرت `حدد المقاس أولاً` فور النقر وبقيت السلة بلا إضافة؛ منتج بمقاس وحيد دخل مسار الإضافة فورًا. بقي منتج متعدد المقاسات مع `M` محدد بعد الخلفية/العودة بلا إعادة تحميل، ولم يسجل الجهاز FATAL أو ANR. نافذة «حجز مسبق» الخاصة بـTemu غطت بعض نقرات الإضافة في منتج الاختبار، لذلك لا تُنسب سرعتها إلى التطبيق ولا ندّعي قياس قبول إضافة محددة عبرها.

النسخة الشخصية: `output/otlobli-v86.166-temu-personal-arm64-debug.apk`، الحجم `205,026,080` بايت، SHA-256 `EF826AAA833D72EFCB4286082AE804D84F28DB2718E43DB0B6F47F9782D25A4C`. النسخة القياسية: `output/otlobli-v86.166-standard-universal-debug.apk`، الحجم `11,128,384` بايت، SHA-256 `6F82549098166B7B93B81B1DE0A800BEFEFF236438DFC388FEA2745D0C52DDE1`. iOS متزامن مع بناء الويب القياسي `86.166/1026` لكنه لم يُبن على Xcode ولم تُنفذ دورات iPhone 16 الخمس أو اختبار التشغيل البارد؛ لا توجد موافقة جهاز iPhone لهذه الدفعة. فحص ESLint الموجّه ما زال يفشل بسبب ديون موجودة مسبقًا في الملفات الكبيرة، بينما TypeScript والبناء ينجحان.

# v86.164 — جذب Temu يبقى داخل صفحة المنتج (2026-08-12)

زر Otlobli داخل منتج Temu يضيف المنتج إلى سلة Temu في الخلفية، ثم يعرض داخل الصفحة `✓ تم جذب المنتج بنجاح` ويبقي المستخدم في صفحة المنتج نفسها؛ أزيل الانتقال التلقائي إلى السلة بالكامل. تأكيد النجاح لا يصدر قبل وصول رسالة `addToCart` إلى الجسر الأصلي، ثم تؤكد WebExtension الاستلام داخل صفحة Temu. لم يتغير فصل سلة SHEIN عن سلة Temu، ويمكن فتح السلة يدويًا من شريط التطبيق.

أُثبت المسار على Galaxy Note 8 الحقيقي `SM-N950F`/`988e16384e4f51395230`: اختير المقاس `S`، ظهرت رسالة النجاح في `output/temu-no-auto-success.png`، وبقي المنتج نفسه ظاهرًا بعد خمس ثوانٍ في `output/temu-no-auto-stays-product.png`. بعد الضغط اليدوي على السلة ظهر المنتج الجديد كالعنصر الثاني في سلة Temu في `output/temu-no-auto-cart-manual2.png`. وسجل الجهاز رسالة `addToCart` كاملة بعنوان المنتج والصورة والسعر `8.56 USD` والمقاس `S` قبل التأكيد. جلسة Temu المضمّنة بقيت محفوظة، وWebExtension الحالية `1.3.12`.

النسخة الشخصية المثبتة على Note 8 هي `86.164-personal-integrated/1024`: `output/otlobli-v86.164-temu-personal-arm64-debug.apk`، الحجم `205,028,280` بايت، SHA-256 `4B4DEDBE3089E7D860BDC041C578D51C9320E7955ACC3C970BDB02FFE5A022D0`. النسخة القياسية: `output/otlobli-v86.164-standard-universal-debug.apk`، الإصدار `86.164/1024`، الحجم `11,466,337` بايت، SHA-256 `575B502B7DBC7F57D48EE812DF6E3F9C3C86B3105863F8019CCDFCAFF546E54B`.

نجح `npm run build` و`npm run build:temu-personal` وحارس تجمد SHEIN وميزانية الأداء وبناء Android القياسي والشخصي ومزامنة Android وiOS. الحدود النهائية: أكبر JS `1,085,076/1,200,000` بايت (الشخصي `1,085,075`)، JS gzip `287,255/370,000` (الشخصي `287,250`)، CSS `69,766/70,000`، الخطوط `81,364/100,000`، سكربتات المتجر `456,288/470,000`، ومصدر SHEIN `552,710/600,000`. نُفذ تشغيل بارد للنسخة الشخصية وبقيت `MainActivity` هي الواجهة الوحيدة النشطة. iOS متزامن مع بناء الويب القياسي، لكنه لم يُبنَ على Xcode ولم تُنفذ دورات iPhone 16 الخمس أو اختبار التشغيل البارد؛ لا توجد موافقة جهاز iPhone لهذه الدفعة.

# v86.163 — شاشة المتاجر، سلتان مستقلتان، وتنقّل Temu الصحيح (2026-08-12)

يبدأ التطبيق الآن مباشرةً بشاشة اختيار عربية سريعة بين **SHEIN السعودية** و**Temu السعودية**، ولا يبدأ فحص الاتصال أو فتح WebView الثقيل قبل اختيار المتجر. لكل متجر جلسة وسلة مستقلة، وتعرض شاشة السلة مبدّل SHEIN/TEMU مع عدد القطع والمجموع الخاص بكل متجر؛ لا تختلط المنتجات أو الشحن أو الدفع بين المتجرين. إذا كانت مجموعة شراء مشتركة مفتوحة، يُمنع تبديل متجر السلة حتى لا يتغير مصدر الطلب الجاري.

تغيّر معنى زر «الرئيسية» داخل التطبيق: من السلة/الطلبات/الحساب يرجع إلى المتجر النشط، وداخل المتجر يرجع إلى رئيسية المتجر نفسه ولا يخرج إلى شاشة الاختيار. الخروج من المتجر صار إجراءً صريحاً عبر زر الرجوع: على رئيسية Temu يبقى زر الرجوع ظاهراً، ويعرض `هل تريد الخروج من متجر تيمو؟`؛ «خروج» يغلق جلسة العرض ويرجع إلى شاشة المتجرين مع إبقاء سلة Temu محفوظة. بقيت هوية Otlobli، الشريط السفلي، حجب عناصر Temu، المنطقة السعودية، جلسة الضيف الدائمة، وحارس إصلاح صفحة المنتج كما كانت. WebExtension هي `1.3.8`.

النسخة الشخصية النهائية `86.163-personal-inapp/1023` بُنيت وثُبتت على Galaxy Note 8 `SM-N950F`/`988e16384e4f51395230`. اختُبر تشغيل بارد (`ThisTime=2649ms`)، فتح Temu من شاشة الاختيار، فتح السلة ثم «الرئيسية» والعودة إلى Temu، ظهور زر الرجوع على رئيسية Temu، نافذة تأكيد الخروج، ثم رجوع «خروج» إلى شاشة الاختيار مع بقاء عداد سلة SHEIN. الأدلة: `output/note8-v86.163-store-hub-fixed.png`، `output/note8-v86.163-cart-tabs.png`، `output/note8-v86.163-temu-home.png`، `output/note8-v86.163-temu-exit-confirm.png`، و`output/note8-v86.163-after-confirm-exit.png`.

APK Note 8: `output/otlobli-v86.163-store-hub-cart-temu-arm64-debug.apk`، الحجم `205,027,368` بايت، SHA-256 `BA9DD25C7A0A81F5722CCE7F4F9235D1109BB602AA305AFA5915DC916B79C186`. APK Android العادي المتزامن: `output/otlobli-v86.163-store-hub-cart-universal-debug.apk`، الحجم `11,128,628` بايت، SHA-256 `6FE083FE8A75FFA8EF2CAD544BCF6432F74DCDAFA6D6ED4EB69142E3F8AF15CF`.

نجح `npm run build` و`npm run build:temu-personal` و`verify:shein-freeze-guard` وTypeScript وبناء Android العادي والشخصي ومزامنة Android وiOS. ميزانية الأداء النهائية: أكبر JS `1,082,529/1,200,000` (الشخصي `1,082,528`)، إجمالي JS gzip `286,628/370,000` (الشخصي `286,625`)، CSS `69,766/70,000`، الخطوط `81,364/100,000`، سكربتات المتجر `455,791/470,000`، ومصدر SHEIN `552,213/600,000`. iOS متزامن مع بناء الويب العادي وإصداره `86.163/1023`، لكنه لم يُبنَ على Xcode ولم تُنفذ دورات iPhone 16 الخمس أو اختبار التشغيل البارد؛ لا توجد موافقة جهاز iPhone لهذه الدفعة.

# v86.161 — منع غطاء «جاري فتح المنتج» الكاذب بعد نجاح فتح Temu (2026-08-12)

شُخّصت الشاشة من نصها ومصدرها وسجل Note 8: هي العنصر `#otlobli-temu-product-loading` الذي ينشئه حارس Otlobli `otlobliTemuBlankProductNotice()`، وليست صفحة Temu ولا طبقة Android ولا عودة إلى تسجيل الدخول. بقي سجل Gecko على رابط المنتج نفسه ولم يسجل `/login` وقت العطل. كان الحارس يعتبر المنتج فارغاً عندما لا توجد صورة كبيرة أو قيمة سعر **داخل مساحة الشاشة الحالية**؛ بعد أن يفتح المنتج ويغيّر Temu صورة المعرض/DOM أو تخرج الصورة والسعر من مجال الرؤية، تصير النتيجة المرئية سالبة رغم بقاء DOM المنتج سليماً، فيرسم الحارس غطاءً أبيض كاملاً فوق المنتج الصحيح.

الإصلاح في النسخة الشخصية `86.161-personal-inapp/1021` وWebExtension `1.3.7`: بعد ثبات ظهور المنتج الحقيقي يسجل السكربت هويته في `__otlobliTemuConfirmedProductIdentity`. غطاء التحميل لا يظهر الآن إلا لمنتج جديد لا يملك أي DOM منتج فعلياً ولم يسبق تأكيده، وإعادة التحميل المحدودة تتوقف أيضاً فور كون المنتج مؤكداً. لم يُحذف حارس الفراغ الحقيقي ولم تُضف مؤقتات أو observers أو مسوحات DOM جديدة. أضيف الفحص `node scripts/verify-temu-product-loading-guard.mjs` لأربع حالات: DOM جديد فارغ، منتج محمّل خرجت عناصره من viewport، منتج مؤكد أثناء تبديل DOM لحظي، ومنتج جديد مختلف.

ثُبتت `86.161/1021` فوق النسخة السابقة على Galaxy Note 8 `SM-N950F`/`988e16384e4f51395230` عبر `pm install -r` مع حفظ سياق Temu الدائم. فُتح المنتج الحقيقي `606482062007357` من عروض التصفيات، ظهر زر `أضف للسلة` وشريط Otlobli، وبقي مفتوحاً من 11:13 إلى 11:18 مع تغيير صور المعرض وعدة فترات انتظار تتجاوز دورات الصيانة. فحص UI النهائي أعاد `LOADING_TEXT_COUNT=0` و`LOGIN_TEXT_COUNT=0`، ولم يسجل logcat FATAL/ANR أو انتقالاً إلى صفحة الدخول. نتيجة الإصلاح موثقة في `output/temu-v86161-note8-long-swipe.png`.

APK المثبت على Note 8: `output/otlobli-v86.161-temu-inapp-arm64-debug.apk` (والـalias `otlobli-v86.161-temu-inapp-debug.apk`)، الحجم `205,023,908` بايت، ABI `arm64-v8a`، وSHA-256 `FB8FF58987EACF1FAA1288C2A96CDD262AEDE99F33626E69C0DBA1C087C91900`. APK المحاكي: `output/otlobli-v86.161-temu-inapp-x86_64-emulator-debug.apk`، الحجم `224,446,802` بايت، وSHA-256 `5739C1332A84805C09E61C039C20D9C56EA78EE9153A792A3C4EDB794EAF7232`. APK العادي المتزامن: `output/otlobli-v86.156-standard-debug.apk`، الحجم `11,125,420` بايت، وSHA-256 `AE2D03603742DC5BDCD9300E0ACE7BF33E839B7B9F1AFA86EFD4755282425617`، وفحصه أعاد صفر Gecko/Temu-extension entries.

نجح البناء العادي والشخصي، حارس تجمد SHEIN، ميزانية الأجهزة الضعيفة، مزامنة Android وiOS للويب العادي، وبناء Android العادي وARM64 وx86_64. أكبر JS `1,077,429/1,200,000`، إجمالي JS gzip `285,318/370,000`، والسكربتات المشحونة `454,698/470,000`. لم يُبن أو يُختبر iOS؛ التغيير يخص حارس Temu المشترك لكنه مُسلّم ومقبول جهازياً في مسار Android الشخصي فقط.

# v86.160 — إصلاح جذري لرجوع Temu إلى تسجيل الدخول على Android (2026-08-12)

شُخّصت المشكلة باختبار A/B على المنتج نفسه `607511226757592` ومن الشبكة نفسها: بناء Android السابق كان يفرض ترويسة iPhone Safari على محرّك GeckoView يعمل فعلياً على Android، فكانت هوية المتصفح متناقضة ويحوّل Temu فتح المنتج إلى `/login.html?login_scene=2`. فتح المنتج في Chrome Android لم يطلب حساباً بل انتقل إلى تحقق الضيف، وبعد إزالة الترويسة المزيفة من GeckoView انتقل التطبيق أيضاً إلى تحقق الضيف بدلاً من تسجيل الدخول. لذلك حُذف حل إعادة المحاولة التجريبي نهائياً؛ لا يوجد `otlobli_guest_retry` أو دوران تنقّل مخفي.

النسخة الشخصية الحالية `86.160-personal-inapp/1020` تستخدم هوية Gecko/Android الأصلية وسياق ضيف دائم جديد `otlobli-temu-android-guest-v86160-final` مع `usePrivateMode(false)`. بقي Temu داخل التطبيق، وبقي شريط Otlobli السفلي وزر الإضافة الأخضر وحجب أزرار Temu وفرض السعودية كما كان. WebExtension الحالية `1.3.6`. لم تتغير CM أو السلة أو الدفع أو المحفظة، والبناء العادي بقي منفصلاً `86.156/1016` بلا GeckoView.

نجح التحقق على محاكي Android 15: أُكمل تحقق الضيف مرة، ثم بعد `force-stop` وتشغيل بارد فتح المنتج مباشرة بلا صفحة دخول وبلا تحقق جديد، مع `LOGIN_COUNT=0` و`CHALLENGE_COUNT=0` وبدون FATAL/ANR. وعلى Galaxy Note 8 الحقيقي `SM-N950F`/`988e16384e4f51395230` ثُبتت النسخة النهائية مع حفظ بيانات التطبيق؛ ظهرت في السياق الجديد شاشة تحقق ضيف أولية لا صفحة دخول، وبعد الإغلاق والتشغيل البارد فتح منتج حقيقي داخل التطبيق وظهر زر `أضف للسلة` وشريط Otlobli، مع `LOGIN_COUNT=0` وبدون FATAL/ANR. لم يُحل CAPTCHA آلياً على Note 8 ولا يوجد تجاوز له؛ يحتفظ التطبيق بجلسة التحقق، لكن يظل لخادم Temu حق طلب تحقق جديد عند تغيّر تقييم المخاطر.

APK المثبت على Note 8: `output/otlobli-v86.160-temu-inapp-arm64-debug.apk` (والـalias `otlobli-v86.160-temu-inapp-debug.apk`)، الحجم `205,023,728` بايت، ABI `arm64-v8a`، وSHA-256 `CD3AC4D50847BEA44F0A129DCE317BAC8FD272D7AF546E5C43BC72F79C8E1E5A`. APK المحاكي المثبت: `output/otlobli-v86.160-temu-inapp-x86_64-emulator-debug.apk`، الحجم `224,446,622` بايت، وSHA-256 `0305D5FB55ED752D380C705844E3184A6E5683B38858F83DB77FE6262F87DE22`. APK العادي: `output/otlobli-v86.156-standard-debug.apk`، الحجم `11,125,340` بايت، وSHA-256 `47C92DE395B513758AC1A86E6E0800AC1AE98670FC9F2C663CB720E2E114FAE9`، وفحصه أعاد صفر Gecko entries.

نجح `npm run build` وحارس تجمد SHEIN وميزانية أداء الأجهزة الضعيفة، ثم مزامنة Android وiOS وبناء Android العادي. ونجح `npm run build:temu-personal` ومزامنة Android وبناء نسختي ARM64 وx86_64. iOS متزامن مع الويب العادي فقط ولم يُبن أو يُختبر؛ الإصلاح الحالي خاص بمسار Temu الشخصي على Android.

# v86.159 — إصلاح منتج Temu وحفظ جلسة التحقق (2026-08-12)

النسخة الشخصية الحالية `86.159-personal-inapp/1019` تُبقي Temu داخل `TemuGeckoActivity` بمحرك GeckoView مضمّن وبلا شريط عنوان أو اسم موقع أو قائمة متصفح. أصل غياب زر Otlobli الأخضر كان أن Temu غيّر رابط المنتج إلى صيغة iPhone مثل `-g-601103…html` بينما مشغّل الالتقاط كان يقبل فقط `/goods.html` و`goods_id=`. صار مولّد الإضافة يعرّف الصيغ الثلاث، وارتفعت نسخة WebExtension إلى `1.3.4` لضمان تحديثها على الأجهزة.

على صفحة المنتج يظهر الآن زر Otlobli الأخضر `أضف للسلة`، ويُحجب زر Temu البرتقالي `حدد خياراً`/`اختر خياراً` وشريط الشراء الأصلي والتحكم العائم الزائد، من دون حجب زرنا. نُقل زرنا إلى أسفل المحتوى فوق شريط التطبيق، وصار زر الرجوع الأصلي يحترم حافة شريط الحالة مع مسافة `24dp` ويختفي تماماً على رئيسية `/sa/`. بقي شريط Otlobli السفلي وحجب حساب/سلة/قائمة Temu والعجلة والنوافذ وأشرطة فتح التطبيق كما كان. لم تتغير سلة Otlobli أو الدفع أو المحفظة أو CM.

جلسة Temu غير خاصة وتستخدم السياق الدائم نفسه `otlobli-temu-ios-guest-v86158-final2`؛ لا يُغيّر هذا المعرف ولا تُمسح بياناته، لأن GeckoView يخزّن ملفات الموقع حسب `contextId`. أول منتج بعد تحديث APK ثم `force-stop` فتح بلا CAPTCHA وبلا دخول، ما يثبت بقاء تحقق الجلسة عبر الإغلاق والتحديث. بعد نقرات ADB سريعة ومتكررة أعاد خادم Temu بعض المنتجات فعلياً إلى `/login.html`؛ هذا قيد خادم وليس فقداناً محلياً للجلسة، ولا يوجد تجاوز CAPTCHA أو ادعاء بأن Temu لن يعيد التحقق عندما يحتاج.

اختُبرت نسخة `x86_64` على `Pixel_7_API_35_Test`/Android 15: تشغيل بارد بلا مسح بيانات فتح الرئيسية السعودية بالعربية والريال، بلا زر رجوع زائد وبشريط Otlobli الكامل. المنتج الأول أثبت ظهور زرنا واختفاء `حدد خياراً`، ولا توجد `FATAL EXCEPTION` أو ANR. تُرك المحاكي على الرئيسية. Note 8 غير متصل بـ ADB، لذلك لم تُثبت النسخة عليه.

APK الخاص بـ Note 8: `output/otlobli-v86.159-temu-inapp-arm64-debug.apk` (والـalias `otlobli-v86.159-temu-inapp-debug.apk`)، الحجم `205,023,728` بايت، ABI `arm64-v8a`، وSHA-256 `F3C403436BA4FA8E9E467FE06D1D9B0FFB7E6E2CD2233595D10214E0F7CFE5F9`. APK المحاكي المثبت: `output/otlobli-v86.159-temu-inapp-x86_64-emulator-debug.apk`، الحجم `224,446,622` بايت، وSHA-256 `DB0880D1C30A6242EBF3B13720D1EF4D1350C1374A6E455A21D874365246F72B`. اختصار `محاكي أندرويد Pixel 7.lnk` باقٍ على سطح المكتب.

البناء العادي بقي منفصلاً `86.156/1016` ولا يضم GeckoView؛ فحص APK أعاد صفر Gecko entries. نجح بناؤه ومزامنة Android وiOS و`assembleDebug`. مساره `output/otlobli-v86.156-standard-debug.apk`، الحجم `11,125,340` بايت، وSHA-256 `B3789760FC756E459C43951844CD1CBF87781FFD6DBADDB1BEEA97FB93F08EDC`.

نجح حارس تجمد SHEIN وميزانية الأجهزة الضعيفة: أكبر JS `1,077,128/1,200,000` (الشخصي `1,077,127`)، إجمالي JS gzip `285,219/370,000` (الشخصي `285,212`)، CSS `63,846/70,000`، الخطوط `81,364/100,000`، سكربتات المتجر `454,397/470,000`، ومصدر SHEIN `551,255/600,000`. iOS متزامن مع البناء العادي فقط ولم يُبن محلياً؛ اختبارات iPhone 16 الخمسة واختبار force-quit/cold-launch غير منفذة.

# v86.156 — استعادة Temu داخل التطبيق بعد تشخيص Android (2026-08-12)

المرشح الحالي `86.156/1016` ومثبت فعلياً على Galaxy Note 8 (`988e16384e4f51395230`). بناءً على طلب
المستخدم أُبقي Temu داخل WebView التطبيق بنفس الشريط والشكل والحجب السابق، وثُبتت السعودية محلياً
(`SA` و`/sa/` والأسعار بالريال). البناء الافتراضي لا ينفذ Custom Tab أو فتح Chrome أو تبديل شكل التطبيق؛ المسار الخارجي موجود فقط خلف وضع `temu-personal` المنفصل الموثق أعلاه.

التشخيص أثبت أن Chrome الحقيقي على Note 8 يستطيع فتح منتجات السعودية كضيف بعد تحقق أمني يدوي؛ فُتح
منتجان فعليان (`605943177830110` و`601103362618514`). لكن المسار الداخلي نفسه أعاد من خادم Temu
`424/40001` عند `/api/passport/token/touch` ثم `403 NEED_LOGIN` عند `/api/oak/integration/render`.
بقي ذلك صحيحاً بعد تجربة third-party cookies، وإزالة علامتي WebView من UA، وإكمال التحقق الرسمي يدوياً
(`login_verify_result=1` ورمز تحقق صالح)، ثم إعادة طلب واجهات المنتج بهوية Chrome وعبر VPN الجهاز.
كما فشلت تجربة أخيرة مررت كل واجهات Temu بهوية واحدة؛ لذلك ليس الفرق CAPTCHA أو كوكيز الطرف الثالث أو UA
وحدها، بل قبول جلسة الضيف من خادم Temu عند تصنيف Android WebView.

لم تُعتمد أي تجربة ثقيلة أو خارجية. أزيلت طبقة `addProxyHandler` كاملة، ومحاكاة Chrome، والمسار الأصلي
المباشر في كود Android، وكل سجلات الأجسام/الترويسات التشخيصية. أُعيد توليد رقعة
`@capgo/capacitor-inappbrowser` من المصدر النظيف. النتيجة النهائية تحفظ حجب عجلة الجوائز وشكل Otlobli؛
وعندما يفرض Temu الدخول على Android تظهر صفحة الدخول الأصلية داخل التطبيق بدل شاشة بيضاء أو طرد للرئيسية.
لم يتغير CM أو الدفع أو المحفظة أو الطلبات المكتملة.

نجح `npm run build` مع حارس تجمد SHEIN وميزانية الضعيف: أكبر JS
`1,075,812/1,200,000`، إجمالي JS gzip `284,862/370,000`، CSS `63,846/70,000`، الخطوط
`81,364/100,000`، وسكربتات المتجر `454,397/470,000`. نجحت مزامنة Android وiOS و`assembleDebug`،
وثُبت APK كتحديث وحافظ على البيانات. أكد الجهاز `versionName=86.156` و`versionCode=1016` ولم تظهر
`FATAL EXCEPTION` أو ANR أو سجلات التجربة المحذوفة. مسار APK:
`android/app/build/outputs/apk/debug/app-debug.apk`، الحجم `11,126,604` بايت، وSHA-256:
`3A14535400020A21E4AF85D8DB4DD307514612320647796B648EBF66ADE03CC4`.

iOS متزامن فقط ولم يُبنَ محلياً. لم تُنفذ دورات iPhone 16 الخمس أو force-quit/cold-launch؛ لا تدّعِ قبول iOS
لهذه الدفعة. حل المنتجات بلا دخول المثبت على Android هو Chrome، لكنه غير معتمد لأن المستخدم طلب الشكل الداخلي.

# v86.153 — تيمو: إظهار الدخول الحقيقي وإيقاف عجلة الجوائز (2026-08-12)

المرشح الحالي هو `86.153/1013` ومثبّت على Galaxy Note 8
(`988e16384e4f51395230`). صيانة هذه الدفعة محصورة بتيمو ولم تغيّر منطق الدفع أو
المحفظة أو الطلبات المكتملة.

أظهر فحص DOM الحي أن صفحة `/login.html` الحقيقية كانت موجودة، لكن منظف إعلانات
تيمو صنّف الحاوية العامة `.container` خطأً كعرض حساب وأعطاها
`display:none!important` مع `data-otlobli-temu-clean-hidden=1`. صار المنظف الآن
يتوقف على مسارات الحساب/الدخول ويعيد فقط العناصر التي أخفاها هو. صفحة الدخول
الأصلية (البريد وGoogle وFacebook) أصبحت مرئية وتفاعلية بدلاً من الشاشة البيضاء.
كما صار مسار منتج السلة المعلّق يعرض تحقق تيمو الحقيقي ولا يبقى خلف timeout مخفي،
وتنتهي حالة التحقق لكل متجر عند وصول `humanCheckResolved`.

كذلك كانت عجلة جوائز Temu كاملة الشاشة تظهر فوق المنتجات لأن دالة الحجب الموجودة
لم تكن تُستدعى. أضيف مرساة selectors رخيصة في tick تيمو؛ لا يبدأ الفحص الأوسع إلا
عند وجود عنصر wheel/spin/turnable، وبعد حجب الجذر مرة واحدة تتجاوزه الدورات التالية.
اختير هذا الأسلوب لتثبيت الواجهة من دون إضافة مسح DOM دائم على الأجهزة الضعيفة.

التحقق على Note 8:

- الرئيسية عرضت منتجات Temu الفعلية بعد التشغيل البارد بلا عجلة جوائز.
- النقر على منتج وصل إلى مسار المنتج ثم فرض خادم Temu الدخول
  (`424/40001` ثم `403 NEED_LOGIN`)؛ بقي نموذج الدخول الحقيقي ظاهراً ولم تظهر
  `temuLoginBlocked` ولم يطرد التطبيق المستخدم إلى رابط USD أو شاشة «نفد المنتج».
- زر الرجوع العائم أعاد إلى الرئيسية، وزر السلة فتح سلة Otlobli الأصلية. كانت
  السلة فارغة ولم تُغيّر أي بيانات.
- ثلاث دورات خلفية/استئناف أبقت العملية نفسها `PID 29796`. نجح force-stop ثم
  cold launch بعملية `PID 31641`، وعادت المنتجات بلا العجلة. لم يسجل الفحص
  `FATAL EXCEPTION` أو ANR أو موت العملية، ولم تتكرر هجرة `clearCookies`.

نجح `npm run build` مع حارس تجمّد SHEIN وميزانية الأجهزة الضعيفة: أكبر JS
`1,076,241/1,200,000`، إجمالي JS gzip `284,993/370,000`، CSS
`63,846/70,000`، الخطوط `81,364/100,000`، والسكربتات المشحونة
`454,397/470,000`. نجحت مزامنة Android وiOS، ونجح `assembleDebug`، وثُبّت APK
بتحديث يحافظ على بيانات التطبيق. الملف
`android/app/build/outputs/apk/debug/app-debug.apk` حجمه `11,124,980` بايت
وبصمة SHA-256 هي
`05E0885CE5D406D74F551AEE0E9A320E46305FFC5EFE1E90A468AB45EA3E4952`.

فحص ESLint المستهدف ما زال يعرض الدين السابق (`31` خطأ و`15` تحذيراً)، بينما
بناء TypeScript/Vite نجح. iOS متزامن فقط ولم يُبنَ أو يُختبر على iPhone؛ لا تزال
خمس دورات iPhone 16 واختبار force-quit/cold-launch مطلوبة قبل قبول iOS.

# v86.150 — تيمو: إظهار التحقق الحقيقي ومنع «نفد المنتج»/الطرد الوهمي (2026-08-11)

المرشح المحلي الحالي هو `86.150/1010`. لا تعتبر قبول `86.147` المكتوب أدناه
قبولاً للمنتجات: المستخدم أثبت أن كل منتج ظاهر كان يعطي «نفدت هذه السلعة» ثم
يرجعه للرئيسية، والفحص السابق أخطأ عندما عدّ هذا الرجوع نجاحاً.

إعادة الإنتاج على Galaxy Note 8 (`988e16384e4f51395230`) حسمت السبب بالشبكة:
النقر على منتج ظاهر أرسل `/api/passport/token/touch` فأعاد `424/40001`، ثم
`/api/oak/integration/render` فأعاد `403 NEED_LOGIN`. بعدها كان كود Otlobli
نفسه يحوّل مسار الدخول إلى رئيسية السعودية، بينما واجهة تيمو تعرض fallback
مضللاً كأن المنتج نافد. المنتج لم يكن مثبتاً أنه نافد.

الإصلاح الحالي:

- أزيل فرض عملة/دولة Otlobli داخل `localStorage` و`sessionStorage` وكوكيز تيمو؛
  هذه الكتابات كانت تولّد `localStorageNotRegister` و`sessionStorageNotRegister`
  وتترك SAR وUSD معاً. السعودية ما زالت ثابتة من مسار `/sa/` وإعداد المتجر،
  والعملة المرئية يختارها تيمو (ظهرت SAR على الجهاز).
- رئيسية تيمو صارت `/sa/` بلا `currency=USD`. روابط تيمو الأصلية
  `/goods.html?...` تبقى كما يصدرها تيمو ولا تتحول إلى `/sa/goods.html`.
- أزيل اعتراض `/login.html` ورسالة `temuLoginBlocked` وكل رجوع إجباري إلى
  الرئيسية. تسجيل الدخول أو التحقق الأمني وجهة حقيقية يجب أن تبقى ظاهرة
  وتفاعلية، لا أن تتحول إلى «نفد المنتج» أو تطرد المستخدم.
- توجد هجرة مرة واحدة لجلسة تيمو القديمة فقط. Android يحذف كوكيز `temu.com`
  فعلياً ككوكيز host/domain من دون اشتراط WebView مفتوحة؛ iOS يستخدم حذف
  `WKWebsiteDataStore` المحصور بالمضيف بعد فتح WebView. فشل التنظيف لا يمنع فتح
  المتجر. لا تُمس كوكيز SHEIN أو جلسة تطبيق Otlobli.

الدليل الحي قبل بناء المرشح: حذف كوكيز تيمو المحصورة أزال 19 كوكي متضاربة وترك
صفر كوكي تيمو، ثم أنشأ الموقع جلسة سعودية نظيفة (`region=174`, `ar`, `SAR`).
بدلاً من «نفد المنتج» ظهر iframe التحقق الأمني الحقيقي. جرى تحليل عناصره وصوره
وسحبها على الجهاز، لكن لم يتم تجاوز حماية تيمو آلياً؛ لذلك لا يوجد ادعاء بأن
صفحة منتج نهائية اجتازت التحقق. المطلوب في قبول الجهاز هو إكمال التحقق يدوياً
ثم فتح عدة منتجات والتأكد أنها تبقى مفتوحة.

نجح `npm run build` مع حارس تجمّد SHEIN وميزانية الأجهزة الضعيفة
(`453,499/470,000` بايت للشيفرة المحقونة)، وتمت مزامنة Android وiOS بعد البناء.
`npm run lint` ما زال يفشل بسبب الدين القديم للمشروع: 33 خطأ و16 تحذيراً في
التطبيق ولوحة الإدارة وخدمة الدفع، ولا يظهر خطأ TypeScript من هذا التعديل.
لم يُنتج APK `86.150`: Gradle المحلي يفتقد
`com.android.tools.build:gradle:8.13.0` و`google-services:4.4.4`، والوصول
الخارجي المطلوب للبناء رُفض من البيئة بسبب حد الاستخدام. لذلك لا يوجد مسار أو
hash أو تثبيت نهائي لهذه النسخة. iOS متزامن فقط ولم يُبنَ أو يُختبر على iPhone؛
تبقى خمس دورات iPhone 16 واختبار التشغيل البارد مطلوبة.

# v86.147 — إرجاع تيمو إلى الأساس المستقر مع إبقاء الجذب (2026-08-11)

المرشح المحلي الحالي هو `86.147/1007` ومثبّت على Galaxy Note 8
(`988e16384e4f51395230`). أُعيد سلوك تيمو إلى خط GitHub المستقر `v85.8.77`؛
المرجع الحاسم هو `b22f5d1` الذي كان قد أعاد ذلك الأساس النظيف مع إبقاء إصلاح
التجمّد. اختير لأنه آخر خط تيمو مستقر قبل أن تصبح التغييرات اللاحقة في معظمها
عمل SHEIN، ولأنه يطابق الفترة التي ثُبّت فيها متجر السعودية.

أُزيلت طبقات تيمو المتداخلة اللاحقة، مع إبقاء ما ثبت أنه صحيح فقط: حماية موت
WebView الحديثة، قفل السعودية، وإصلاح الجذب `temuStripQuantity()` الذي يمنع شريط
الكمية من تلويث اللون أو المقاس. التطبيق يتجاهل أي منطقة تيمو مخزنة أو قادمة من
الإعدادات البعيدة ويستخدم السعودية حصراً (`SA`، `/sa/`، `region=174`، لغة `ar`).
واجهة تيمو تعرض `ر.س`، بينما عملة السلة الداخلية تبقى USD كما طلب المستخدم.

استرداد التصفح محدود وواضح: عند صفحة منتج فارغة يظهر «جاري فتح المنتج…»، وتوجد
إعادة تحميل واحدة فقط لكل منتج. إذا فرض خادم تيمو `/login.html` يعترضه الغلاف
الأصلي ويعود باتجاه واحد إلى رئيسية السعودية، أو إلى سلة التطبيق عند وجود إضافة
معلّقة؛ لا يعيد فتح المنتج المرفوض ولا يدخل في حلقة. بعض المنتجات والبحث ما زالت
تُحجب من خادم تيمو نفسه على هذا الاتصال، ولا يحاول التطبيق تجاوز الحماية.

فحص القبول الكامل لنفس كود التصفح في `86.146` استمر `149.964s`: فُكّت وحُلّلت
كل الإطارات وعددها `1427`، وكانت أطول فترة بياض صارمة `0.289s` فقط (إطار منفرد)،
وسجل CDP أعطى صفر حالة بياض، وصفر منطقة أو لغة خاطئة في `93` حالة تيمو. بقيت
العملية نفسها بعد ثلاث دورات خروج/عودة. بعد ذلك لم يتغير التصفح في `86.147`؛
أُعيد فقط حارس تنقية بيانات الجذب، ثم نجح فحص نهائي على الجهاز للرئيسية السعودية
ومنتج نافد ومنتج آخر أعاده الخادم للرئيسية بلا تعليق أو بياض دائم.

نجح `npm run build` وحارس تجمّد SHEIN وميزانية الأجهزة الضعيفة (الشيفرة المحقونة
`456,841/470,000` بايت)، وتمت مزامنة Android وiOS ونجح Android debug build.
الـAPK النهائي `android/app/build/outputs/apk/debug/app-debug.apk` حجمه
`11,125,532` بايت وبصمة SHA-256 هي
`29B2250CBA057459440048C758A6566F99243256E579A99A07FDC11533B3666E`.
iOS متزامن فقط؛ لم يُبنَ أو يُختبر على iPhone، ولذلك تبقى خمس دورات iPhone 16
واختبار force-quit/cold-launch مطلوبة قبل إصدار iOS.

# v86.142 — تدقيق تيمو الزمني وقفل السعودية والاسترداد المحدود (2026-08-11)

المرشح المحلي الحالي هو `86.142/1002` على Android وiOS. تيمو مقفول على السعودية
حصراً: مسار `/sa/`، كوكي المنطقة الحقيقية `region=174`، واللغة العربية السعودية.
العملة الداخلية للسلة تبقى USD كما طلب المستخدم، بينما واجهة تيمو تعرض الأسعار
بالريال السعودي. فُحص هذا فعلياً على Galaxy Note 8 (`988e16384e4f51395230`).

أهم إصلاح أخير: بعض روابط منتجات السلة كانت ترتد `product → login` بلا نهاية في
WebView المخفية، مع أن واجهة React عادت للسلة. تيمو كانت تمسح كوكي حارس المحاولة،
لذلك استُبدل بعلامة `otlobli_guest_retry=1` داخل رابط الهدف نفسه. صار المسار
محدوداً إلى محاولة ضيف واحدة ثم رجوع وحيد إلى رئيسية السعودية. فشل رندر المنتج
الفارغ يستخدم المبدأ نفسه عبر `otlobli_blank_retry=1` بدل إعادة تحميل غير محدودة.

التحقق النهائي على الجهاز:

- سجل CDP لمدة 90.18 ثانية: خمسة انتقالات فقط؛ آخرها رئيسية السعودية عند
  `9.266s`، ولا انتقالات أخرى حتى نهاية التسجيل.
- تسجيل شاشة 89.747 ثانية حُلّل بمعدل 4 إطارات/ثانية (359 عينة): صفر فترة
  بياض كامل/قريب من الكامل، وبقيت السلة ظاهرة أثناء فشل رابط المنتج.
- خمس دورات خروج/عودة على Android أبقت العملية نفسها `pid 9325`.
- الرئيسية والبحث وحالة «لا نتائج» والرجوع والسلة بقيت تفاعلية؛ كل حالات CDP ذات
  منطقة كانت `174` وكل اللغات `ar`. لا أخطاء `StorageNotRegister`.
- خوادم تيمو أعادت 403/429 لبعض API على هذا الاتصال، ولذلك تفرض تسجيل دخول أو
  تحقق أمني على بعض المنتجات. التطبيق لا يتجاوز حماية تيمو: يعرض التحقق الحقيقي
  أو يرجع بأمان للسلة/الرئيسية بدل شاشة بيضاء أو حلقة.

التحقق الآلي: `npm run build` نجح، حارس تجمّد SHEIN نجح، ميزانية الأجهزة الضعيفة
نجحت (الشيفرة المحقونة 455,975/470,000 بايت)، وتمت مزامنة Android وiOS. نجح
`assembleDebug` وثُبت APK على الجهاز. الملف
`android/app/build/outputs/apk/debug/app-debug.apk` حجمه `11,125,180` بايت وبصمة
SHA-256 هي `BD7E012E459B9CFA0AB30E36310E715C7CDAE0A2D6B24088588E79D2E4BF606A`.
iOS متزامن فقط؛ لم يُبنَ أو يُختبر على iPhone في هذه الجلسة، لذلك دورات قبول
iPhone 16 الخمس واختبار التشغيل البارد ما زالت مطلوبة قبل إصدار iOS.

# v86.134 — تيمو: قصّ ذيل «الكمية» من اللون/المقاس (2026-08-11)

فُحص تيمو على النوت 8 (`988e16384e4f51395230`) عبر CDP + `screencap` مع نقرات
`adb input` حقيقية. المُثبت وقت الفحص كان **v86.67**، لا 86.125.

ما ثبت على الجهاز:

1. **تلوث اللون بالكمية.** صف «الكمية» في تيمو شقيق لصفّ اللون/المقاس داخل نفس
   الحاضن، فأي قراءة نصية تصعد مستوى واحداً تلتصق به. العنصر الحقيقي في DOM
   نصّه `اللونالكمية1`، والسلة كانت تحمل `color = "【أبيض】الكمية1"`، و
   `__otlobliDiag.color()` أعاد `الكمية1` كـ«لون مختار» على منتج بلا أي اختيار.
   الإصلاح: `temuStripQuantity()` تقصّ `الكمية/كمية/quantity/qty` وما بعدها، وتُطبَّق
   في `temuColor()` و`temuColorFromHeading()` وعند تخزين نقرة كرت اللون، ثم حارس
   أخير على `color`/`size` داخل `captureProductPayload`. القيمة التي ليست إلا
   كمية تصير فارغة، فيطالب التطبيق الزبون باختيار اللون بدل إرسال قيمة ملفّقة.
   **مُتحقَّق على الجهاز:** إضافة «قميص بولو» بعد اختيار L أعطت
   `size = "L"`, `color = ""`, `priceUsd = 7.74` (28.15 ر.ق × 0.275) — بلا أي ذيل كمية.

2. **موت العملية وإعادة الفتح (شكوى «يضوي ويطفي ويعيد تحميل»).** على v86.67 مات
   `com.otlobli.app` مرتين أثناء تصفّح تيمو بلا تدخّل (pid 8876→10822 و
   12970→14479)، وفي لقطة واحدة كانت **نافذتا WebView لتيمو حيّتين معاً** على نفس
   الرابط. هذا هو بالضبط ما عالجه **v86.126** (`onRenderProcessGone` في رقعة
   InAppBrowser وفي `MainActivity`) وهو غير موجود في 86.67. بعد تثبيت v86.134 لم
   تمت العملية خلال جولة الفحص الكاملة (pid 15246 ثابت).

3. **المنطقة/العملة.** الأسعار تظهر بالريال القطري (`ر.ق`) وعنوان الصفحة
   `Temu Qatar` رغم `/sa/` و`currency=USD` — تيمو تتبع IP الـVPN لا المعاملات.
   التحويل QAR→USD في `temuPriceUsd()` سليم (0.275 مثبّت)، فالسعر المحفوظ صحيح.
   لم يُغيَّر شيء هنا؛ مسجَّل للمتابعة.

4. **بوابة الدخول من المتصفّح لا من الجهاز.** من متصفّح المطوّر ترتدّ كل صفحات
   المنتجات إلى `/login.html`؛ على النوت 8 (VPN قطر) تفتح المنتجات طبيعياً. لا
   تغيير في منطق `otlobliTemuRecoverFromLoginRedirect`.

البناء ودليل التجميد وميزانية الأداء ومزامنة أندرويد و`assembleDebug` تمرّ كلها.
النسخة `86.134/994`، مثبَّتة على النوت 8. لم يُبنَ iOS في هذه الجلسة.

# Active candidate — v86.126 stops Android killing the app when SHEIN's renderer dies (2026-08-10)

Device-proven root cause, found by running v86.125 on the Galaxy Note 8
(Android 9) and reading its crash log while browsing SHEIN:

```
Abort message: [FATAL] Render process (6444)'s crash wasn't handled by all
associated webviews, triggering application crash.
F/libc: Fatal signal 5 (SIGTRAP) ... pid 6331 (com.otlobli.app)
Process com.otlobli.app has died
```

SHEIN product pages are heavy enough for Chromium to OOM-kill the renderer on an
older phone. From Android 8 the framework then kills the WHOLE APP unless every
WebView attached to that renderer claims the death via `onRenderProcessGone`.
iOS already survived this through `webViewWebContentProcessDidTerminate`;
Android had **no handler at all** — zero occurrences in the plugin or the patch.
This is what the customer saw as the app closing by itself and as blank pages.

Two WebViews share the renderer, and both had to be fixed:

1. The store browser, in the InAppBrowser patch. On renderer death it now
   claims the crash, then closes exactly like `onCloseWindow` does, handing
   control to the host whose existing `closeEvent` recovery reopens a clean
   session or shows its retry card.
2. The Capacitor bridge WebView, in `MainActivity`. Capacitor's
   `BridgeWebViewClient` already forwards `onRenderProcessGone` to registered
   listeners but returns **false** when nobody claims it — so the app still died
   after only the store side was fixed. A `WebViewListener` now claims it and
   rebuilds the activity.

Verified on the device by deliberately killing the renderer over CDP
(`Page.crash`):

| | before | after |
| --- | --- | --- |
| same deliberate kill | SIGTRAP, process died | **survived, same pid** |
| guard log | none | `bridge render process gone, didCrash=true` |
| "wasn't handled" crash lines | present | **zero** |

Version `86.126/986`. Build, freeze guard, performance budget, Android sync and
Android debug assemble pass. The patch was regenerated with patch-package and
re-checked: the iOS lifecycle fix, native back button, host-resume, freeze
diagnostics and relay key are all still present.

iOS was rebuilt from the same commit but **the iOS half of this change is a
no-op there** — iOS already handled its equivalent. Nothing else changed for
iPhone since v86.125.

# Active candidate — v86.125 stops shipping 93KB of comments to the phone (2026-08-10)

Base is still v86.117 (`bf40b1c`). Nothing about behaviour, timings, checks or
concealment changed here; this is purely about what the device has to read.

The store scripts in `src/services/sheinBrowserScript.ts` are template literals
injected into the SHEIN/Temu page **as source text** at `documentStart`. Every
byte, comments included, is shipped and tokenised by JavaScriptCore before the
product page can paint. Measured on v86.124: 92,969 of 546,397 shipped bytes
were comments — 17% pure cost on a two-core iPhone 6, on every page load.

A Vite plugin (`scripts/strip-injected-comments.mjs`) now removes whole-line
comments from that module at build time. The source stays fully documented; only
the device gets the stripped copy.

| Measurement | v86.124 | v86.125 |
| --- | --- | --- |
| shipped into the store page | 546,397 | **453,428** |
| largest JavaScript raw | 1,167,084 | **1,073,774** |
| total JavaScript gzip | 322,756 | **283,701** |

The app bundle shrank too, because the script was embedded in it as a string —
39KB less to download and decompress.

Safety, all machine-verified:

- Only whole-line comments are removed (trimmed line starts with `//`). Trailing
  comments, block comments and blank lines are untouched.
- Both emitted scripts were proven **byte-identical** to the originals with
  comment lines removed. No code or string literal changed.
- The freeze guard now parses the **stripped** output rather than raw source,
  because that is what reaches the device. A stripping mistake fails the build.
- No line in the file begins with a `//` token that is not a comment (no
  protocol-relative URLs at line start) — checked before implementing.

Budget change, stated plainly: a new `shipped store scripts raw` metric caps the
injected text at 470,000 bytes, and this is now the real device budget.
`SHEIN script source raw` was raised from 550,000 to 600,000. That is not a
relaxation — the old ceiling was serving as both the device budget and a source
size cap, and had tightened to 67 free bytes, to the point where documenting an
optimisation cost more budget than the optimisation saved. Comments no longer
reach the device, so source size has no runtime cost, and device cost is now
bounded directly and more tightly by the new metric.

Version is `86.125/985`; diagnostics off. Build, freeze guard, performance
budget, Android sync and Android debug assemble pass. ESLint reports 49 problems
before and after. Local bundle `index-BsAtQi_A.js` is 1073774 bytes, SHA-256
`47EAB0D3BD3806314AACF4CEE73C7CEBD36993496570D12664CF8488EEB4A39D`. Android debug APK is 11123140 bytes, SHA-256 `7D3C01D5977861B87497E9824F3C8061DB780FFA114804A30A44E7675DE45526`.

**Nothing was measured on a physical device.** Expected effect: product pages
start faster because 93KB less script is parsed before SHEIN paints. Acceptance
is unchanged and must still include concealment being exactly as immediate as
v86.117 and the back button never dead-ending.

# Active candidate — v86.124 speeds up the iPhone 6 by removing work, not checks (2026-08-10)

Base is still v86.117 (`bf40b1c`). The functional diff against it is now five
changes and nothing else — two for the back button (v86.123) and three pure
speedups added here. No feature, check, hider, timing or message was weakened.

The governing rule, learned from two device rejections (v86.118, v86.121): on a
2-core phone, buy speed by **cutting work inside a pass**, never by lengthening
the interval between passes. A ~950ms concealment pass leaves SHEIN's own price
and add controls visible for most of a second on the very device that needs them
hidden fastest. The freeze guard now forbids `OTLOBLI_VERY_LOW_END` outright.

Three measured sources of cost, two removed here:

1. **MutationObserver ran for nothing on low-end.** It watches `childList` +
   `subtree` on the document root, so it wakes on every DOM change SHEIN makes
   — lazy images, carousels, infinite scroll — continuously. But
   `scheduleTick()` returns immediately on low-end, so its whole effect there
   was clearing `sheinBlockReported`: one mutation record plus one microtask
   per DOM change, on two cores, to set a boolean. Low-end no longer observes.
   The `pushState`/`replaceState`/`popstate` hooks still clear that flag,
   which is the realistic path that re-arms it after a navigation.
2. **Layout thrashing in the concealment loops.** Each iteration read
   `getBoundingClientRect()` and then wrote inline styles; the write invalidates
   layout and the next read forces a synchronous recalculation, so the pass paid
   one forced layout per element. Worse, elements hidden on an earlier pass were
   re-measured and re-written every 650ms forever. Both hot hiders now skip an
   already-hidden node before any geometry read, using an inline-style read that
   costs no layout. Steady-state cost collapses; behaviour is identical.
3. **`document.body.innerText` every 1.6s** forces a full-page layout. Not
   addressed — the safe gate is an element count, and a previous attempt using
   `body.children.length > 8` silently disabled the detector because the block
   page itself exceeded it. Any new threshold must be generous (600+ total
   elements) and tested against a real block page first.

Version is `86.124/984`; diagnostics off. Production build, freeze guard,
performance budget, Android sync and Android debug assemble pass. ESLint reports
49 problems before and after — none added. Local bundle `index-BHQM3P73.js` is
1167084 bytes, SHA-256 `EC28D87E75D9937E08342FFD969096650A3DC4F8194DF7C1ECAC290B1E5EFB24`. Android debug APK is 11,169,512
bytes, SHA-256
`AE987756CFC0EB90352F41D1D71589B8C5D75F682E042C183B0E04B9A82CAE30`.

**Budget wall.** SHEIN source is `549,933/550,000` — 67 bytes free. Every change
above was funded by condensing comments on the code it touched; no ceiling was
raised. Measurement worth acting on: **17% of this file is comments (93,739
bytes)**, and the file ships into the store page as an injected string, so those
bytes are parsed by JavaScriptCore on the iPhone 6 at every page load for no
runtime benefit. Stripping comments at build time would ship ~456,195 bytes
instead of ~549,934 and would free the budget for the remaining work. That needs
a build transform plus a guard that measures the emitted script rather than raw
source — not decided yet.

**Nothing was measured on a physical device.** The wins here are structural and
provable by inspection, but "feels faster" is the customer's call. Acceptance:
scrolling a SHEIN listing and a product page on the iPhone 6 should be smoother,
with concealment exactly as immediate as v86.117.

# Active candidate — v86.123 returns to v86.117 and fixes only the back button (2026-08-10)

Device verdict from the customer, covering four builds:

- v86.116 — back button vanished entirely. Rejected outright.
- v86.117 — correct in every respect, including concealment. One defect: after a
  few product hops on the iPhone 6 the back button keeps accepting taps and
  stops moving. The app also felt slow.
- v86.118 — traded concealment quality for speed. Rejected: "خرب".
- v86.119/120/121 — chased entry and cache problems that v86.117 never had.

The instruction is explicit: return to v86.117 and fix the back button only.
`src/`, `patches/` and `scripts/verify-shein-freeze-guard.mjs` are therefore
restored to `bf40b1c` verbatim, with exactly one change applied on top. The
v86.122 candidate (false-VPN-gate work) is abandoned: those defects live in the
v86.121 lineage, which no longer exists here.

Root cause of the back defect: the native button forwards its tap to the in-page
button, whose handler ends in a bare `history.back()`. Once the store's back
stack is spent that call is a SILENT no-op — no error, no navigation, nothing
observable. Every back consumes an entry while re-entering a product does not
always add one, so the stack runs dry and the button dead-ends while still
looking and feeling live. That is precisely the reported symptom: visible
button, registered tap, no movement.

`otlobliBackOrLeave()` records the URL, calls `history.back()`, and 900ms later
navigates to the recorded `__otlobliHomePath` if nothing moved. A real
navigation destroys the JS context before the timer fires, so the fallback is
reachable only by a back that genuinely did nothing — a slow but working back is
never overridden. The freeze guard pins the wrapper and forbids the bare call.

Deliberately unchanged: concealment timings and both add-hiders every pass, the
VPN/preparation logic, the back button's look and placement, the iPhone 16
recompose lifecycle, Android resume defense, order/payment logic. The v86.117
slowness is left alone — chasing it is what broke v86.118. No new timer,
observer, polling loop or React effect; the one `setTimeout` is per tap and
self-cancelling.

Version is `86.123/983`; diagnostics remain off. Production build, freeze guard,
performance budget, Android sync and Android debug assemble pass. The fix costs
188 bytes over v86.117, funded by condensing the comment on the code it
replaces; SHEIN source is `549,909/550,000` and the ceiling was not raised.
Local bundle `index-C3882LG0.js` is 1,167,065 bytes, SHA-256
`F387266DD31FA09D61E9306EBA989A9491236B1E90396CCE94ED3CB4867E7F0D`.
Other budgets: JS gzip `322,787/370,000`, CSS `63,670/70,000`, fonts
`81,364/100,000`. Android debug APK is 11,169,524 bytes, SHA-256
`2543C69A28B75437816B4CD066E2D4B7898FEEB14363BEA0E89576D606DB765F`.

**Nothing was validated on a physical device.** Required acceptance: on the
iPhone 6, hop through five or more products and confirm the back button never
stops responding; when the back stack is genuinely spent it must land on the
SHEIN home rather than freeze. Confirm concealment still matches v86.117.

# Active candidate — v86.121 restores the device-proven v86.118 runtime (2026-08-10)

The v86.120 real-iPhone screenshot proved the corrected Qatar/preparation copy
was present, but SHEIN still never entered. The user then identified v86.118 as
the last version that actually opened the store. A direct `c2cc383..HEAD`
comparison isolated the post-v86.118 runtime changes: v86.119 increased hot
concealment work on two-core iPhones and v86.120 armed a native HTTP cache reset
whenever supported geo/reachability was confirmed, turning healthy starts into
cold sessions.

v86.121 restores `src/services/sheinBrowserScript.ts` exactly to the v86.118
runtime and removes cache-reset arming from successful geo/store probes,
supported unexpected closes and the primary retry. Cache reset remains only in
the pre-existing bounded stuck/chunk recovery and the proven Temu → SHEIN fresh
session. The supported-Qatar preparation wording, intentional-close retry
coordination, approved back action/layer, iPhone 16 recompose/lifecycle fix,
Android resume defense, JSON region comparison and order/payment logic remain.
No new timer, polling loop, observer, WebView burst or React effect was added.

Version is `86.121/981`; diagnostics remain off. Production build,
freeze/performance guards, Android/iOS sync, diff check, Android debug assemble
and GitHub/Xcode run `31340886636` pass. Local bundle `index-BWvDqCCZ.js` is
1,166,623 bytes, SHA-256
`683F1D6EB6F004F1F85D4BCB5C1E29129DE4DF9A59CAE81F02DD3FB36BA89CD4`.
Budgets are JS gzip `322,578/370,000`, CSS `63,670/70,000`, fonts
`81,364/100,000`, and SHEIN source `549,668/550,000`. Android debug APK is
11,169,320 bytes, SHA-256
`DB955A35C9F48AFF4775EBCDC1BFA634FEF25E02E5F036DD34D35A4F10A9F492`.

Desktop IPA is
`C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.121-iphone\otlobli-v86.121-iphone16-unsigned.ipa`,
7,050,682 bytes, SHA-256
`43C31B9BEBECA834DD74DACA038CCD7EAB774CA73D2AB7462316A7A4D81303BF`.
Archive inspection confirms `com.otlobli.app`, `86.121/981`, iOS 15+, the
v86.121 runtime marker and supported-region copy, and absence of the rejected
confirmed-Qatar VPN copy. CI JS is `index-CIfG9Dfv.js`, 1,167,811 bytes,
SHA-256 `4D774702530EA647D7CF7AE84529AF128FD9B449E989242F608D6EA6F0994525`.
The IPA is unsigned/unprovisioned; the workflow has no configured Google iOS
callback and it lacks production APNs entitlement. Real iPhone entry and the
required five iPhone 16 resume cycles plus cold launch remain pending.

# Active candidate — v86.116 iPhone 6 store recovery and sticky-price back layer (2026-08-10)

The user's v86.115 iPhone 6 screenshots proved both reported issues remained.
The host could still show `تعذّر تجهيز المتجر` with a VPN diagnostic action,
and SHEIN's sticky price strip covered the back button after a small scroll.

The preparation failure had two concrete application causes. SHEIN's newer
home cards can be visually loaded without exposing three semantic links or
buttons, but `sheinPageLooksInteractive()` required three; an old phone could
therefore reject a genuinely painted page until the bounded recovery ended.
Home readiness now still requires two decoded images, plus either a visible
semantic control or at least 500 characters of real page content. Confirmed
iOS WebKit termination and an unexpected close of an already-ready SHEIN view
now enter the existing single runtime-cache recovery (60-second incident
guard), preserving cookies, storage, signed address and the current product
URL. They no longer jump straight to the host error. If preparation genuinely
fails after bounded recovery, its screen no longer offers the irrelevant VPN
diagnostic; real network/VPN failures retain it.

The back-button root move in v86.115 was wrong for old WebKit paint ordering:
a composited sticky descendant of `body` can cover a direct `html` child even
at maximum z-index. v86.116 keeps the existing iPhone 6 `58px` top, moves the
button to a top-level `body` child and reclaims last paint order only when the
existing point-hit test proves it is actually covered. Reparenting disables
the entrance animation, so no flicker is retriggered. It reuses the current
maintenance tick and adds no timer, observer, scroll scan or native recompose.

Version is `86.116/976`; diagnostics remain off. Production build,
freeze/executable guard, low-end budget, Android/iOS sync, diff check and
Android debug assemble pass. Budgets: JS raw `1,166,461/1,200,000`, total JS
gzip `322,636/370,000`, CSS `63,670/70,000`, fonts `81,364/100,000`, SHEIN
source `549,582/550,000`. Bundle `index-D5vXFFT1.js` is identical in
dist/Android/iOS, SHA-256
`4C588085CFE27B56B27DDF4A98FEB83376F0D40929C13683DF67D4D2BEFAA9A9`.
Android debug APK is 11,169,400 bytes, SHA-256
`D3686E905715E41F392459B3A5A750CF3A350F9E2475C69F118D3469540CD734`.
GitHub/Xcode run `31336148034` succeeded from commit `bbb3143`. Downloaded IPA:
`C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.116-iphone\otlobli-v86.116-iphone16-unsigned.ipa`,
7,045,748 bytes, SHA-256
`A3E8741247DD9F80FAEF98ED2EA6D1F81E1E0B9E72045D8E73342308D0FD920C`.
Archive inspection confirms `com.otlobli.app`, `86.116/976`, arm64/iOS 15+,
the body/last-child back helper, non-reanimation, broadened visual readiness,
push code, `FAKE_VISIBLE`, and native `otlobliForceRecompose`. CI asset
`index-D6AvzqBz.js` is 1,167,649 bytes, SHA-256
`F02FD430BC9643D8E442AEC98E7819FCA028A8E49F2E1DF8EC1C4203AC05F416`.
The IPA remains unsigned/unprovisioned, lacks APNs entitlement, and contains
only the `otlobli` URL scheme because the Google iOS secret remains absent; it
is a device-test artifact, not App-Store-ready. Physical iPhone 6/iPhone 16
acceptance remains pending. All protected native resume/recompose, region JSON,
cart and verification paths remain unchanged.

# Previous candidate — v86.115 Qatar VPN continuity and iPhone 6 back layer (2026-08-09)

The remaining issues were independent. First, a transient timeout from the
geo/store probes could overwrite a Qatar or already-working store session and
show VPN advice. v86.115 now keeps a confirmed supported country or successful
store session authoritative across a transient probe failure. An explicit
blocked-country result still opens the real VPN gate, offline remains offline,
and changing stores resets the store-reachability evidence. A store loading
failure after supported access is reported as preparation/recovery, not as a
false VPN problem.

Second, the injected back button already used the maximum z-index, but it was
inside `body`. SHEIN can append a later body portal with the same stacking
priority, which covered the button on the small iPhone 6 layout. The button is
now an idempotent direct child of `document.documentElement`, with fixed
position, maximum important z-index, GPU compositing and pointer events. The
existing iPhone 6 top offset (`58px` at widths up to 390px) and modern-iPhone
position are unchanged. No timer, observer, scan or native recompose was added.

Version is `86.115/975`; diagnostics remain off. Production build,
freeze/executable guard, low-end budget, Android/iOS sync, diff check and
Android debug assemble pass. Budgets: JS raw `1,166,206/1,200,000`, total JS
gzip `322,557/370,000`, CSS `63,670/70,000`, fonts `81,364/100,000`, SHEIN
source `549,495/550,000`. Bundle `index-DJYgI4go.js` is identical in
dist/Android/iOS, SHA-256
`7E2302F00879ED6C4C46AE08AF1AFF0EAAB2D8D641860BFE13D14F087F91162F`.
Android debug APK is 11,170,941 bytes, SHA-256
`31E342B6B8156E5A54453E6E0D1AB43C3E18D0E310ABDF4402503F48E18947F8`.
GitHub/Xcode run `31334667716` succeeded from commit `d6236e5`. Downloaded IPA:
`C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.115-iphone\otlobli-v86.115-iphone16-unsigned.ipa`,
7,045,678 bytes, SHA-256
`487557AD139DDE8DEF37BCC8E90B6CD0ED13D001334E676878D97953407BB6A5`.
Archive inspection confirms `com.otlobli.app`, `86.115/975`, arm64/iOS 15+,
the root back-layer helper, supported-connection recovery copy, push code,
`FAKE_VISIBLE`, and native `otlobliForceRecompose`. CI asset
`index-BSb3bB3x.js` is 1,167,394 bytes, SHA-256
`E2827A8BDD1F7FD0375DDF739D3C716901BBE4F58E882EDE5E30BF13CC63D287`.
The IPA is unsigned/unprovisioned, has no APNs entitlement, and contains only
the `otlobli` URL scheme because the Google iOS secret remains absent; it is a
real-device test artifact, not an App-Store-ready archive. Physical iPhone 6
and iPhone 16 acceptance remain pending. Preserve the exact iPhone 0.25-second
recompose, Android resume defense, store-region JSON guard and v86.113
host-first reveal.

# Previous candidate — v86.114 instant SHEIN native add-button concealment (2026-08-09)

The user clarified that the remaining product-entry defect was concealment,
not Otlobli button sizing: SHEIN's own black add-to-cart control stayed visible
until the shopper scrolled down and back up. Live inspection of the current
Arabic SHEIN product page found the exact control class
`j-add-to-bag add-cart__normal-btn productAddBtn`. The document-start CSS only
covered `add-bag`/`addbag`, so it did not match SHEIN's real `add-to-bag` name;
the later geometry/text scan could eventually catch it after scroll/layout.

v86.114 mounts the lightweight SHEIN-only concealment stylesheet while the
session is still on the home route, before the product-path guard. It covers
the current `add-to-bag`/`add-cart` variants plus bounded equivalent class and
ARIA names. A product action created later by the SPA is therefore hidden by
the browser's CSS engine on insertion, with no scroll, new timer, mutation
geometry scan, recompose burst, or permanent watcher. The freeze verifier now
enforces the document-start selectors and their ordering ahead of a later SPA
product route.

Version is `86.114/974`; diagnostics remain off. Production build,
freeze/executable guard, low-end budget, diff check, Android/iOS sync and
Android debug assemble pass. Budgets: JS raw `1,166,026/1,200,000`, total JS
gzip `322,526/370,000`, CSS `63,670/70,000`, fonts `81,364/100,000`, SHEIN
source `549,739/550,000`. Bundle `index-DsS0ZeUp.js` is identical in
dist/Android/iOS, SHA-256
`0C2F9B163923FB1467313983DA2A0B0FBED7DEDBA29D796EEBE72B703E367520`.
Android debug APK is 11,547,910 bytes, SHA-256
`9678319D4A7762D65F3004079C68421CC0BFF64849B0FF40A642215AD2851AEA`.
GitHub/Xcode run `31333940354` succeeded from commit `dd45e4f`. Downloaded IPA:
`C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.114-iphone\otlobli-v86.114-iphone16-unsigned.ipa`,
7,045,624 bytes, SHA-256
`4B2A982E5563552C95F0AB4818D7659EEDF7ABF58F171EC099C281D83858856B`.
Archive inspection confirms `com.otlobli.app`, `86.114/974`, arm64/iOS 15+,
the real `add-to-bag` and Arabic cart selectors, push code, hidden
`FAKE_VISIBLE` reveal, and the native `otlobliForceRecompose` symbol. CI web
asset `index-DMbii6YN.js` is 1,167,214 bytes, SHA-256
`58F70542C0A2C45DCF1890DB147A38C47E1983442F288206810D8E7C4C7D067D`.
The IPA remains unsigned/unprovisioned, has no APNs entitlement, and contains
only the `otlobli` URL scheme because the Google iOS client secret remains
absent. It is a real-device test artifact, not an App-Store-ready archive.
Real iPhone acceptance is pending. Preserve the exact iPhone 0.25-second
recompose, Android resume defense, store-region JSON guard and v86.113
host-first reveal.

# Active candidate — v86.113 fixed host-first SHEIN reveal on iPhone (2026-08-09)

The remaining iPhone 6 first-open defect was not another nav-height problem.
The native loading cover deliberately stopped above the injected bottom nav,
so SHEIN's document-start nav could become visible while its hidden controller
was still moving from the pre-presentation viewport to the real device frame.
That exposed a horizontally clipped two-tab frame for about two seconds before
WebKit's later layout corrected it.

v86.113 uses the plugin's existing hidden `FAKE_VISIBLE` mode for iOS SHEIN.
The WebView now loads offscreen at the real window size while React's already
mounted Otlobli loading screen and bottom nav remain the only visible surface.
The existing `sheinSaudiReady` / `sheinPageInteractive` / `humanCheck` path
marks the session ready; only then may the home visibility effect call
`InAppBrowser.show()`. A new freeze-guard assertion enforces both the full-size
hidden option and readiness-before-show ordering, including fresh cart-product
sessions and bounded recovery reopens.

No new timer, DOM scan, native recompose call, region transition, verification
bypass, cart/payment/wallet/order change, or plugin patch was added. The exact
iPhone `appDidBecomeActive` + 0.25-second recompose, Android resume defense,
scroll/constraints and `JSON.stringify` region guard remain unchanged.

Version is `86.113/973`; diagnostics are disabled. Production build,
freeze/executable guard, low-end performance budget, diff check, Android/iOS
sync, and Android debug build pass. Budgets: JS raw
`1,166,014/1,200,000`, total JS gzip `322,581/370,000`, CSS
`63,670/70,000`, fonts `81,364/100,000`, SHEIN source
`549,734/550,000`. Bundle `index-DL3biifD.js` is identical in dist/Android/iOS,
SHA-256 `67BFFFB018100AE645D37661B6D1C00AA002105AE951119F942ECE6B9C154028`.
Android debug APK is 11,169,316 bytes, SHA-256
`8258C347DB214BFABF11141E17C44259C7D6394D5DF7491FDDC533036E44E916`.
Repository-wide lint still fails on the documented pre-existing 33 errors and
16 warnings; no reported lint item points at the v86.113 changes.

GitHub/Xcode run `31332963586` succeeded from commit `247908a`. Downloaded IPA:
`C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.113-iphone\otlobli-ios-v86.113-iphone16\otlobli-v86.113-iphone16-unsigned.ipa`,
7,045,681 bytes, SHA-256
`A767F73D56AB17F3A2FB54A7FCC41CC29E311D31D66A43C3A0FF16BFF140AB43`.
Archive inspection confirms `com.otlobli.app`, `86.113/973`, iPhoneOS arm64,
iOS 15+, production Supabase input, push code, the version/`FAKE_VISIBLE`
markers, and the preserved native recompose symbol. CI asset
`index-DguZdE19.js` is 1,167,202 bytes, SHA-256
`19A81FF6CB7541FC3533EEC6EA2818274699469F8A7B0E287491A1DF6BD57E51`.
The IPA remains unsigned/unprovisioned, has no APNs entitlement, and contains
only the `otlobli` URL scheme because the GitHub Google iOS client secret is
still absent; it is a real-device test artifact, not App-Store-ready. Required
acceptance remains iPhone 6 cold open plus cart-product open, and five iPhone
16 background/resume cycles plus a separate force-quit/cold-launch test.

# Previous candidate — v86.112 iPhone 6 product-entry black-toast guard (2026-08-09)

The user clarified that the remaining iPhone 6 defect is the compact black
SHEIN “added to shopping cart successfully” bar above Otlobli's bottom nav. It
is already visible on product entry and disappears only after Otlobli's add
button is pressed or the customer quickly opens Otlobli cart.

The cause is exact in the existing code: `hideSheinCartSuccessToast()` already
recognizes and hides this specific black bar, but its seven-second guard window
was armed only inside `addToCartFlow()`. Therefore product entry returned before
the scan; pressing Otlobli add armed the guard, and opening cart merely hid the
entire SHEIN WebView. v86.112 arms the same bounded guard for 15 seconds when a
new `-p-<id>` route is entered and runs it before Otlobli's add button is
exposed. It resets its product key off product routes and retains the existing
add-flow window for later actions.

No timer, MutationObserver work, full-page scan, native WebView/lifecycle,
region, verification, cart write, payment, wallet or order logic changed. The
existing low-end tick performs the same bounded point/alert inspection only
during the entry window. The freeze verifier now executes the actual injected
helper against a 375×667 black-toast fixture, proves it hides on product entry
without any add click, proves non-product entry does not arm it, and enforces
that the guard runs before the Otlobli add button.

Version is `86.112/972`; diagnostics disabled. Production build,
freeze/executable regressions, low-end budget, patch reverse-check, diff check,
and Android/iOS sync pass. Budgets: JS raw `1,165,969/1,200,000`, total JS gzip
`322,546/370,000`, CSS `63,670/70,000`, fonts `81,364/100,000`, SHEIN source
`549,734/550,000`. Synchronized bundle `index-CtL87wKm.js` is 1,165,969 bytes,
SHA-256 `5C4B6FDBFB705FCA400E5EFC924AE92010C52EAC28FC2754C6CB0BC574AC3DBB`,
identical in dist/Android/iOS.

GitHub/Xcode run `31331834857` succeeded from commit `9759e2b`. Downloaded IPA:
`C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.112-iphone\otlobli-ios-v86.112-iphone16\otlobli-v86.112-iphone16-unsigned.ipa`,
7,045,614 bytes, SHA-256
`8FCFD6E90D70AC32F8726B6FD0CB3A30716E2EDA4A71AB750861263488D2CE71`.
Archive inspection confirms `com.otlobli.app`, `86.112/972`, iPhoneOS arm64,
iOS 15+, production Supabase input, push code, version/product-entry/deadline/
hidden-toast markers and preserved native recompose/navigation symbols. CI
asset `index-BLmbZ9qY.js` is 1,167,157 bytes, SHA-256
`AD3A15C15A653970C9C7862CB4182B7AB5B052CEDCED26EACB1B9483C4507614`.
The IPA remains unsigned/unprovisioned with no APNs entitlement or Google iOS
callback. Real iPhone 6 acceptance is pending; do not claim the symptom closed
until the product-entry bar is absent on that device.

# Previous candidate — v86.111 iOS SHEIN cart-product session isolation (2026-08-09)

The user's real iPhone 16 Pro Max and iPhone 6 results reject v86.110 as a fix
for the cart-triggered dead-product-navigation sequence. The exact reproduction
is: keep SHEIN open, enter Otlobli cart, open a saved SHEIN product, then later
SHEIN's shell/categories can still paint while product navigation stops. A
manual Temu → SHEIN switch restores it immediately.

The decisive local difference is now removed. The cart path previously called
`InAppBrowser.setUrl()` on the already-used hidden SHEIN WebView; the proven
Temu → SHEIN recovery closes that WebView, clears only WebKit disk/memory HTTP
cache, and creates a new one. Every iOS SHEIN cart-product open now performs
that same bounded close/cache-reset/fresh-open sequence *before* the product is
shown. It keeps the React cart visible until the new product document and the
existing blockers report ready, preserves persistent cookies/localStorage and
the signed region, and marks the product session disposable so returning to an
Otlobli destination cannot preserve the suspect product runtime.

An expanded freeze guard enforces that the iOS fresh-session branch occurs
before warm-product reuse or `setUrl`, includes the cache reset and singleton
reopen, and contains no `setUrl` itself. No native recompose timing, background
lifecycle, injected polling, region, verification, payment, wallet or order
logic changed. The exact iPhone `appDidBecomeActive` + 0.25-second recompose,
Android resume defense and region `JSON.stringify` guard remain intact.

Version is `86.111/971`; diagnostics and diagnostic copy UI are disabled.
Production build, freeze guard, low-end performance budget, patch reverse-check,
`git diff --check`, and Android/iOS sync pass. Budgets: JS raw
`1,165,420/1,200,000`, total JS gzip `322,344/370,000`, CSS
`63,670/70,000`, fonts `81,364/100,000`, SHEIN source
`549,182/550,000`. The synchronized local bundle is `index-CcGBMKpA.js`,
1,165,420 bytes, SHA-256
`65324888D9C71274148A93B9319B17260262900401F45B4096901CEAE85CD9C3`,
identical in `dist`, Android assets and iOS assets.

GitHub/Xcode run `31330410350` succeeded from commit `c2eb127`. Downloaded IPA:
`C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.111-iphone\otlobli-ios-v86.111-iphone16\otlobli-v86.111-iphone16-unsigned.ipa`,
7,045,461 bytes, SHA-256
`A9F04E68C55E7DE5EC9C35701D413B941986165AFA4CE148F5D178E2E1505390`.
Archive inspection confirms `com.otlobli.app`, `86.111/971`, iPhoneOS arm64,
minimum iOS 15, production Supabase input, push plugin code, the v86.111 marker
and fresh-session notice, plus all preserved native lifecycle symbols. The CI
asset is `index-BJBAX-bI.js`, 1,166,608 bytes, SHA-256
`0FEDE1104A15B0C8C66DCB4A61EA86C135D1ACB47BE98DDAAB344C5722418AA4`.

This IPA is unsigned/unprovisioned: it has no app `_CodeSignature`, embedded
profile or APNs entitlement. GitHub still has no Google iOS OAuth client, so
only the `otlobli` URL scheme is present. It is a real Release/Xcode device-test
artifact, not an App Store submission archive. Required device test: from a
warmed SHEIN session open an existing saved product from Otlobli cart, return
through Otlobli navigation, open several listing products, repeat on iPhone 6
and iPhone 16 Pro Max, then perform five iPhone 16 background/resume cycles plus
a separate force-quit/cold launch. Do not claim the symptom closed until those
real-device checks pass.

# Previous candidate — v86.110 SHEIN review guard + delayed iPhone tap recovery (2026-08-09)

Two separate iPhone reports are addressed. First, the full-screen photo-viewer
heuristic accepted any `number/number` text. A rating such as `4.9/5` could
therefore make a fixed SHEIN product root look like a photo viewer after the
customer scrolled to ratings/comments; Otlobli then correctly followed the
wrong state and hid its add button. Viewer detection now requires a visible,
standalone integer image counter such as `1/7`, rejects review/rating/comment
surfaces, and still recognizes the real photo viewer.

Second, the prior confirmed `ChunkLoadError` recovery listened only inside a
product URL to avoid v86.81's eager home-page close/reopen flash. That left a
gap when SHEIN's listing runtime failed after a long session: the visible grid
could scroll, but tapping a product could not load its route. v86.110 records a
confirmed listing chunk failure without reopening anything. Recovery is
requested only when a real short iPhone product tap then remains on the same
URL, or when a chunk fails within 15 seconds of that stalled tap. A direct
`-p-<id>` anchor is also recognized regardless of changing card class names.
The existing one-recovery-per-60-seconds host path, native HTTP-cache-only
reset, cookies/storage preservation, and product URL restoration remain.

No polling, MutationObserver, WebView lifecycle/recompose timing, region,
verification, payment, wallet or order logic changed. The exact iPhone
`appDidBecomeActive` + 0.25-second guarded recompose and Android resume defense
are preserved. The guard now executes regression harnesses proving: listing
chunk errors do not recover eagerly; a stalled tap after one does recover; a
post-tap chunk preserves the product URL; direct product anchors still route;
`4.9/5` and comment surfaces are not viewers; and a real `1/7` viewer remains.

Version is `86.110/970`. Production build, expanded SHEIN freeze guard,
low-end budget, `git diff --check`, and Android/iOS synchronization pass.
Budgets: JS raw `1,164,614/1,200,000`, total JS gzip `322,199/370,000`, CSS
`63,670/70,000`, fonts `81,364/100,000`, SHEIN source `549,182/550,000`.
The synchronized bundle is `index-D_2Iz6xX.js`, SHA-256
`4E4D026114738DD33E66A0B1BB56F2144F51ED927630A5CA38CEFC6BDA5CFF7E`,
identical in `dist`, Android assets and iOS assets.

GitHub/Xcode run `31329654038` succeeded from commit `ecc7224`. Downloaded IPA:
`C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.110-iphone\otlobli-ios-v86.110-iphone16\otlobli-v86.110-iphone16-unsigned.ipa`,
7,045,328 bytes, SHA-256
`2E78266CA7BCB7CFAF2F9D56CAE17E148C256707229AB0C15967E67D41C8A634`.
Archive inspection confirms `com.otlobli.app`, `86.110/970`, iPhoneOS arm64,
minimum iOS 15, production Supabase build input, push plugin code, both new fix
markers, and the preserved native lifecycle markers. The CI asset is
`index-v4sDXob3.js`, 1,165,802 bytes, SHA-256
`424838ED1B5E2C95AA37FB4CB254818873124F3F02DBFA835A770D4CEF0A2B86`.
The app itself has no signature or provisioning profile. GitHub still lacks
`VITE_GOOGLE_IOS_CLIENT_ID`, so Google is hidden, and there is no
`aps-environment` entitlement. This is an unsigned device-test artifact, not a
publish-ready App Store archive. Real iPhone acceptance is still pending:
scroll a product to ratings/comments and confirm Otlobli add stays present;
leave SHEIN active long enough to reproduce the old tap stall and confirm
either direct navigation or one bounded recovery; then perform five iPhone 16
background/resume cycles and a separate force-quit/cold-launch test.

# Previous candidate — v86.109 iPhone 6 first-frame SHEIN add-button concealment (2026-08-09)

The old iPhone 6 SHEIN product layout exposed its own wide “add to cart”
action until Otlobli's add flow began. The existing listing-card cleaner was
intentionally capped at 96px, so it could not remove this product-width action.
The document-start bootstrap now installs a product-route-only CSS guard before
SHEIN paints known add-button classes, then uses the existing bounded early
protection loop to identify older obfuscated markup by exact Arabic/English add
semantics plus bottom-action geometry. The long-lived capture loop applies the
same bounded defense. Both `أضف إلى السلة` and `أضف للسلة` wording are covered;
all Otlobli-owned nodes are explicitly excluded.

No MutationObserver scan, timer, network request, WebView lifecycle change or
native recompose retiming was added. Each fallback scan is capped at 140
candidate controls plus a 3×3 bottom point probe, throttled to 350/450ms and
reusing existing timers. A real-browser 375×667/iPhone-6 fixture confirmed that
both a known-class SHEIN action and an obfuscated role-button are hidden during
the early bootstrap and remain hidden after the full capture script, while the
Otlobli nav stays visible and interactive.

Version is `86.109/969`. The production build, SHEIN freeze guard, low-end
budget, patch reverse-apply check, `git diff --check`, and Android/iOS sync pass.
Budgets: JS raw `1,166,162/1,200,000`, total JS gzip `323,337/370,000`, CSS
`63,670/70,000`, fonts `81,364/100,000`, SHEIN source `549,717/550,000`.
The identical local synchronized customer bundle is `index--wBuHHo_.js`,
SHA-256 `1F659B17400E4909520486A87BCA6D8A1CBBC37C539C5A7B116951775B9ADECF`, in
`dist`, Android assets and iOS assets.

GitHub/Xcode run `31328598144` succeeded from commit `7504cda`. Downloaded IPA:
`C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.109-iphone\otlobli-v86.109-iphone16-unsigned.ipa`,
7,045,851 bytes, SHA-256
`876CA8BB521B24FDC9D0FE2D9E450D259A07C6BF35841FDE5A7309F73EC1FD39`.
Archive inspection confirms `com.otlobli.app`, `86.109/969`, iPhoneOS arm64,
minimum iOS 15, production Supabase, push code, the version marker and native
add concealment marker. It has no app signature or provisioning profile.
GitHub still lacks `VITE_GOOGLE_IOS_CLIENT_ID`, so the iOS Google action and
callback are intentionally absent. There is also no `aps-environment`
entitlement or Apple/APNs signing configuration. This is an unsigned device
test artifact, not a publish-ready App Store build; completing the user's
production requirement needs the Apple signing/profile/APNs values and the
Google Cloud iOS OAuth client. Real iPhone product-load acceptance and the
separate five background/resume cycles plus cold launch remain mandatory.

# Previous candidate — v86.108 persistent SHEIN verification session (2026-08-09)

The app now preserves SHEIN's genuine completed human-check session as far as
the store permits. Android already uses the shared persistent WebView cookie
jar; the SHEIN WebView now accepts the verifier's required third-party cookies,
and receipt of the existing `humanCheckResolved` status immediately flushes
that real cookie jar to disk. iOS continues to use `WKWebsiteDataStore.default()`
and its persistent cookie store. No token/certificate is fabricated, copied,
extended or replayed, and the app never clicks or solves the challenge.

Closing the app, switching SHEIN → Temu → SHEIN, cache-only recovery and native
WebView recreation do not clear cookies or local storage. A completed check can
therefore be reused across those flows instead of being lost with the process.
SHEIN still owns expiry and risk decisions, so a network/device change or an
expired/revoked trust cookie can legitimately require another check; the app
cannot promise “once forever.” The v86.107 guide, action gate and safe return
from the misleading removed-product page remain unchanged.

Version is `86.108/968`. Production build, SHEIN freeze guard, low-end budget,
Android/iOS sync, persistent-patch clean-apply check and Android Release compile
pass. Budgets: JS raw `1,161,971/1,200,000`, total JS gzip `322,555/370,000`,
CSS `63,670/70,000`, fonts `81,364/100,000`, SHEIN source
`545,533/550,000`. Release APK:
`android/app/build/outputs/apk/release/app-release.apk`, 9,179,632 bytes,
SHA-256 `E15B9BF4BC677A4A1F9256AD8A7F79BA133D74FAADD87DAB866C0675D8459AD1`.
It is v2/v3 signed with the Note 8's existing update certificate, is
non-debuggable, and contains the native verification-session marker.

Installation over v86.107 on real `SM-N950F` succeeded without clearing data.
The package reports `86.108/968`, starts with a live process and has no fatal
startup/ANR marker. End-to-end reuse still requires the customer to complete
one real SHEIN check, close/reopen, then switch Temu → SHEIN; do not claim that
server-controlled acceptance from build inspection. Real iPhone five-cycle
resume and separate cold-launch acceptance also remain unperformed.

# Active candidate — v86.107 SHEIN human-check guard (2026-08-09)

SHEIN's current product challenge renders as a visible `.one-pass-dialog`
beside a zero-sized `#one-pass-custom` host. The old detector tested only the
host and therefore missed the challenge; closing it then made SHEIN show the
misleading Arabic “product removed” page. A second detector call in the same
tick could also consume the existing 1.5-second scan throttle. v86.107 detects
the visible dialog and caches the scan result for the whole tick.

The app does not solve or bypass SHEIN's verification. While it is visible, a
compact Arabic guide explains that the customer must press “أنا إنسان”, and
Otlobli's product action is withheld. The pending state survives SHEIN document
transitions for up to 15 minutes. If the customer closes/skips verification and
SHEIN falls through to “تمت إزالة المنتج”, the app explains what happened and
returns to the product list (or the Otlobli cart when that was the source).
Successful verification resumes the normal product flow. No payment, wallet,
cart/order, store-region, WebView lifecycle or native recompose behavior changed.

Version is `86.107/967`. The production web build embeds the live public
Supabase configuration and enables Google and push. SHEIN freeze guard and
low-end budgets pass: JS raw `1,161,968/1,200,000`, total JS gzip
`322,563/370,000`, CSS `63,670/70,000`, fonts `81,364/100,000`, and SHEIN
source `545,533/550,000`. Android and iOS are synchronized, and both native
asset trees contain the `.one-pass-dialog` detector and cached scan result.

Real Note 8 inspection confirmed the live challenge text/button and the
zero-sized-host/visible-dialog structure. A controlled live diagnostic showed
the guide mounted, the product action removed and the bottom navigation kept.
Final source was built and synchronized after the detector-cache correction.
Final Android Release packaging remains pending an execution approval; the
temporary debuggable test app was removed and the device was restored to the
previous non-debuggable v86.107 Release artifact. Do not treat that installed
artifact as containing this final correction. Real iPhone acceptance (five
background/resume cycles plus a separate cold launch) is still unperformed.

# Active candidate — v86.106 Android native-nav parity + production release gate (2026-08-09)

The user's screenshots rejected v86.105: the four tab rectangles were equal,
but that check measured the preserved hidden store WebView instead of the
foreground React screen. Real Note 8 DevTools then showed the actual cause:
SHEIN renders the nav label at `12px` with text adjustment fixed at `100%`,
while Android's `font_scale=1.1` made the React label `13.2px`. A one-time
Android startup probe now compensates only the four fixed nav labels back to
the accepted `12px`; accessibility font scaling remains intact everywhere
else. The existing Flex/icon/spacing parity and Arabic accessibility semantics
from v86.105 remain.

The white/black Android system-navigation mismatch was separate. Window state
showed the foreground InAppBrowser dialog lacked `LIGHT_NAVIGATION_BAR`, while
the obscured Capacitor activity had it. The persistent InAppBrowser patch now
uses Otlobli's light navigation surface and explicitly requests dark system
icons; the main app theme declares the same policy. No iPhone recompose burst,
`appDidBecomeActive` 0.25-second timing, scroll/constraint restoration,
Android host-resume defense or unchanged-region comparison changed.

Version is `86.106/966`. The production web build embeds the live Supabase
public configuration and explicitly enables Google and push. Google services,
the FCM sender/app resources, notification permission/service, Social Login
component and all four Capacitor plugins are present in the Release variant.
SHEIN freeze guard, Android/iOS sync and Release Java/resource compilation pass.
Budgets: JS raw `1,159,657/1,200,000`, JS gzip `322,314/370,000`, CSS
`63,670/70,000`, fonts `81,364/100,000`, SHEIN source `549,985/550,000`.

Release signing is now fail-closed: `assembleRelease`/`bundleRelease` cannot
silently fall back to the debug identity. The customer app and ShamCash listener
guards are task-scoped, so each Release requests only its own independent key.
The user then narrowed the delivery to updating the existing Note 8. Android
requires the same certificate to update without deleting app data, so a
non-debuggable Release APK was signed with that device's already-installed,
Firebase-registered debug certificate only for this in-place device update.
Signature matching, package `com.otlobli.app` `86.106/966`, production Supabase,
Google, push and release marker inspection all pass. APK:
`android/app/build/outputs/apk/release/app-release.apk`, 9,179,401 bytes,
SHA-256 `BFB289191B867CD6B2E84E63AE4D433726D8F9015EFC2046C9A51F63E49CEC17`.

Installation over v86.105 succeeded with data preserved. On the real Note 8,
Home and Orders now use dark Android system-navigation controls, and the
inactive `حسابي` label is pixel-identical in both screenshots: bounds
`x=96…174`, `y=1989…2023`, `79×35`, 489 dark pixels. A subsequent cold launch
kept the process alive with zero app fatal/ANR and zero push-registration error
markers. The user visually accepted the result as fully fixed. Nothing was
published. This APK is not the future Play upload artifact: a permanent upload
key plus Firebase/Play certificate registration still require explicit owner
approval if store publication is requested later.

# Active candidate — v86.104 stable first-frame SHEIN navigation (2026-08-09)

The reported product-open frame showed Otlobli's injected bottom navigation at
its `90px` fallback, then moving upward after SHEIN finished applying
`viewport-fit=cover` and WebKit exposed the real bottom safe area. The host app
already knows that inset before opening the store. v86.104 reads the mounted
host navigation's computed bottom padding once, passes the bounded value into
SHEIN's document-start script, and makes the injected navigation use the larger
of the host value, WebKit `env(safe-area-inset-bottom)`, and the existing 16px
minimum. The first and hydrated frames therefore use the same geometry.

The temporary iOS tap diagnostic is closed for this customer build:
`otlobliTapDiagnostics` is explicitly false, its document-start script and
capture-context interpolation are excluded, and the native `نسخ` button is not
installed. The v86.103 cart-session recovery remains. No WebView rebuild,
polling, region decision, payment/cart behavior, native recompose timing,
scroll restoration, or Android resume defense changed.

Version is `86.104/964`. Production build, the SHEIN freeze guard, low-end
performance budget, and Android/iOS sync pass. Budgets: JS raw
`1,157,905/1,200,000`, JS gzip `321,473/370,000`, CSS `63,291/70,000`, fonts
`81,364/100,000`, SHEIN source `549,920/550,000`. A Playwright `440×932`
first-frame fixture with a 34px iPhone inset measured `108px` navigation height,
`34px` bottom padding, top `824`, bottom `932`, and `stable=true`. Android debug
APK: `android/app/build/outputs/apk/debug/app-debug.apk`, 11,167,800 bytes,
SHA-256 `5CE18F7657FE34322E303D1F25A85AA2944C7FE2384C77C1CA83F7C2B0D3B18C`.
Commit `b7f6d27` is pushed and GitHub/Xcode
[run `31313269405`](https://github.com/m7madv/otlobli/actions/runs/31313269405)
passed. Inspected IPA:
`release-artifacts/ios-v86.104-run-31313269405/otlobli-v86.104-iphone16-unsigned.ipa`,
7,044,634 bytes, SHA-256
`70D1EC898C8C4244A3D787642DC5C815D293FF553F55BEA1C1C95E0AE3D23AE4`.
An identical verified copy is on the desktop at
`C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.104\otlobli-v86.104-iphone16-unsigned.ipa`.
Archive metadata is `com.otlobli.app` `86.104/964`; the customer bundle contains
the first-frame inset marker, has `otlobliTapDiagnostics:false`, and excludes
the tap diagnostic script. The app root has no signature or embedded
provisioning profile; four vendor frameworks retain signatures. All real
iPhone acceptance remains pending; do not claim it from browser/build checks.

# Active recovery candidate — v86.103 SHEIN cart-session reset (2026-08-09)

The customer's v86.102 report narrows the failure to a preserved iPhone SHEIN
session after an Otlobli-cart product path. The WKWebView was attached, visible,
interactive and `440×894`; SHEIN country state was consistently `QA`, with no
region transition or veil. Scroll moved from `0` to `734`, so WebKit input and
painting were alive. The user confirmed that the shell/categories keep working
while product navigation stops, and that Temu → SHEIN restores it by closing
the old store session and clearing runtime cache.

v86.103 tracks only iOS SHEIN sessions that opened a product from the Otlobli
cart. On app resume or exit from that product to Otlobli cart/orders/profile,
the preserved WebView is retired once and the existing bounded cache-reset path
opens a fresh SHEIN session. Cookies, localStorage, signed country/address,
cart/order/payment data and native `appDidBecomeActive` 0.25-second recompose
timing are unchanged. Normal browsing sessions and Android keep the old
preserve/hide behavior.

The diagnostic is still enabled for this acceptance build. It now records a
bounded raw touch/click attempt even when product-card recognition fails,
includes href/label/scroll state, records `touchcancel`, schedules after-URL
from capture, and runs only in the top frame so Pinterest/Criteo/about:blank
iframes cannot consume the native 180-event ring. A zero-delay task now reads
final cancellation after page listeners complete. Playwright verified an
unknown element (`productDetected=false`), a known product link with href,
capture+bubble/final cancellation, synthetic touchstart/touchend under one
attempt, the 720ms after record, and no iframe installation.

Production build, freeze guard, low-end budget, Android/iOS sync and Android
debug build pass. Budgets: JS raw `1,163,553/1,200,000`, JS gzip
`323,209/370,000`, CSS `63,291/70,000`, fonts `81,364/100,000`, SHEIN source
`549,929/550,000`. Android APK:
`android/app/build/outputs/apk/debug/app-debug.apk`, 11,171,342 bytes, SHA-256
`1EDC0BFED9DF367F6046F30DE9432F9695F13033AD22E1A464B049B2DBB8897B`;
metadata confirms `com.otlobli.app` `86.103/963`. Code commit `49b734e` is pushed on
`codex/shein-ios-tap-diagnostic`; GitHub/Xcode
[run `31310138809`](https://github.com/m7madv/otlobli/actions/runs/31310138809)
passed from `49b734e36c0c5ffbafe7b1d03502a5e6288c3548`. Inspected IPA:
`release-artifacts/ios-v86.103-run-31310138809/otlobli-v86.103-iphone16-unsigned.ipa`,
7,046,214 bytes, SHA-256
`E83EF7ECDD885E8CBB6FD49C9BDB1888411C444EA2708BFE5487503DFC2C712F`.
Verified desktop copy:
`C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.103\otlobli-v86.103-iphone16-unsigned.ipa`
with the same size and SHA-256.
Archive inspection confirms `com.otlobli.app` `86.103/963`, the cart-session
recovery marker/message, raw touch markers, and native recompose symbols. The
app root has no signature or embedded provisioning profile; four prebuilt
Facebook frameworks retain vendor signatures. All real iPhone acceptance is
still pending. If product entry still fails, copy the raw v86.103 report before
switching stores.

# Active diagnostic candidate — v86.102 SHEIN iOS tap-path trace (2026-08-09)

The unresolved iPhone defect is now instrumented without guessing at a fix.
This dedicated build records product `touchstart`, `touchend`, and `click` in
capture and bubble, plus a post-dispatch record that still reveals final
`defaultPrevented` and missing bubble propagation. Each capture snapshot
contains the target, `elementFromPoint`, eight ancestors, bounded fixed/sticky
layers at the point, computed interaction/visibility styles, rectangles, URL
before/after, configured/actual SHEIN country, signed-address readiness, and
region-transition state. The existing iOS product fallback reports when it is
armed, schedules or runs `.click()`, skips after natural navigation, or calls
`location.assign()`; its `280ms/220ms` timing and behavior are unchanged.

Native iOS adds the matching WKWebView state (attached/window/hidden/alpha,
interaction, bounds, loading/progress, scroll and app state) to an in-memory
180-event ring. The diagnostic-only `نسخ` button copies a report headed
`OTLOBLI_SHEIN_TAP_DIAGNOSTIC`. No timer/polling, reload, cache reset, WebView
rebuild, touch cancellation or diagnostic overlay was added. The old freeze
diagnostic remains disabled. The proven `appDidBecomeActive` 0.25-second
recompose, scroll/constraints restoration, Android resume defense and
unchanged-region `JSON.stringify` guard are preserved.

Playwright reproduced a fixed transparent layer over a product: the trace
identified the layer as the event target and painted element, found the product
under it, captured opacity/z-index/pointer-events/rect and region state, and
left `defaultPrevented=false`. Synthetic touchstart/touchend produced stable
capture+bubble records under one attempt plus the after-URL record. Production
build, freeze guard, low-end budget, Android/iOS sync and Android debug build
pass. Budgets: JS raw `1,162,215/1,200,000`, JS gzip `322,933/370,000`, CSS
`63,291/70,000`, fonts `81,364/100,000`, SHEIN source `549,929/550,000`.

Android APK: `android/app/build/outputs/apk/debug/app-debug.apk`, 11,548,135
bytes, SHA-256 `30DBE8CF87AAF04098CDE6F3101DEC6DD40DE23858E53703F7A806AF44E3E643`;
metadata confirms `com.otlobli.app` `86.102/962`. The connected Note 8 is ADB
`unauthorized`, so it was not installed or device-tested. Code commit
`b5a6e7a` is pushed on `codex/shein-ios-tap-diagnostic`. GitHub/Xcode
[run `31308844558`](https://github.com/m7madv/otlobli/actions/runs/31308844558)
passed from the full commit `b5a6e7a194410b1d774cad3a1a07c52fdb8a4170`.
The inspected unsigned IPA is
`release-artifacts/ios-v86.102-run-31308844558/otlobli-v86.102-iphone16-unsigned.ipa`,
7,045,998 bytes, SHA-256
`3E9C88CFF994D64C4688F904737E8CDE34FAA0DB319A46716B158121E4FA96E4`.
Its archive confirms `com.otlobli.app`, `86.102/962`, the web/native diagnostic
markers and the existing native recompose markers. The main app has no
top-level `_CodeSignature` or embedded provisioning profile; vendor-signed
Facebook frameworks retain their own signatures. Real iPhone acceptance is
entirely pending; at the first failed tap copy the report before switching
stores, then run the five-path matrix and five resume cycles plus cold launch.

# Previous candidate — v86.101 hidden SHEIN colour-template guard (2026-08-09)

The false "choose a colour first" block on no-option SHEIN products is fixed.
Live Note 8 evidence proved the cause: `findOptionContainer()` accepted a
hidden DOM template whose class happened to include `color`, turning it into
an unselected mandatory colour. A no-option nail page reported
`color.exists:false`; adding one hidden two-button colour fixture made the old
code report `exists:true`; v86.101 keeps it `false`. Only rendered option
containers can now become the fallback, so real visible colour choices keep
their existing protection.

The user video was inspected at 60 fps. The bottom navigation is already
complete and unchanged from 0.25 s until the store paints. The dark rounded
card before that is the iOS home-to-app launch animation, which happens before
app code, React, or the WebView exists. No navigation, launch timing, WebView,
region, cache, or iPhone recompose code was changed for that system transition.

Android 86.101/961 passed production build, iPhone-freeze guard, low-end
budget, Android/iOS sync, Android debug build, and was installed over the
connected Note 8 without clearing data. The device diagnostic passed; no cart
write was performed. APK: `android/app/build/outputs/apk/debug/app-debug.apk`,
11,167,224 bytes, SHA-256 `957D4D540D81A8162DF501CD9251760AD9F9CC5274349CA52C852E6F9C23FCF1`.
The unsigned iPhone build completed successfully: [run 31305701128](https://github.com/m7madv/otlobli/actions/runs/31305701128).
IPA: `release-artifacts/ios-v86.101/otlobli-v86.101-iphone16-unsigned.ipa`,
7,039,768 bytes, SHA-256 `D9AC194F1EBA2594F82B68103701A58830289259C95930474EE4F30785B00F4D`.
Archive inspection confirms Otlobli 86.101/961 (`com.otlobli.app`) with no embedded
provisioning profile or signature. Real iPhone 16 acceptance remains pending: test the
no-option product and complete five background/resume cycles plus a cold launch.

# Previous candidate — v86.100 Otlobli-first store opening (2026-08-09)

The user requires Otlobli itself to open first, with its name, status line,
and persistent navigation already visible, then SHEIN/Temu to load above that
ready app. A Note 8 frame capture confirmed that the previous native surface
fade painted the same wordmark/tabs twice. v86.100 uses one local pre-activity
render of that exact Otlobli loading surface, keeps the matching native app
surface while Capacitor starts, and removes it atomically only after React has
rendered two frames. The store WebView is unchanged and opens only after the
existing region/VPN readiness path.

The startup resource is local and static (no WebView, JavaScript, network,
timer, store-region polling, cache reset, or remote font). Android 12+ also
uses the platform SplashScreen handoff before BridgeActivity starts; the Note
8 keeps the exact static app preview. No iPhone recomposition, foreground
timing, Android resume defense, or `JSON.stringify` region guard changed.

Android 86.100/960 was built and installed on the connected Note 8. A
10-fps cold-start recording confirms a stable Otlobli surface with no opacity
cross-fade/double wordmark before store preparation. Production build,
iPhone-freeze guard, low-end performance budget, Android/iOS sync, and Android
debug build pass. APK: `android/app/build/outputs/apk/debug/app-debug.apk`,
12,581,116 bytes, SHA-256
`5D8C52CE73A26DC6C94C3E2E3A0493967814BD84AE6EEB18FB33B062DFC0104F`.

The user reported that their iPhone still runs old v86.82 and can stall on
the SHEIN skeleton until a manual store switch. The current unsigned iPhone
build completed successfully from commit `0b387d9`:
[run 31304414080](https://github.com/m7madv/otlobli/actions/runs/31304414080).
Its IPA is `otlobli-v86.100-iphone16-unsigned.ipa`, 7,039,678 bytes, SHA-256
`5DAD64EFB8620B8C5677A97A80A809EB3C61EE3D65199F80C3874EA776A59BFC`.
Real iPhone 16 cold-launch and five background/resume acceptance remain
mandatory and are not yet claimed.

# Otlobli Current State

## Active candidate — v86.98 stable store opening (2026-08-09)

Frame-by-frame cold-start capture on the connected SM-N950F / Note 8 found the concrete cause of the visibly changing SHEIN opening screen. Android was adding the native loading cover inside `presentWebView()` while the Dialog was still measured as a short wrap-content window. It painted a compressed, top-aligned wordmark and navigation before the dialog later expanded and painted the full centred cover.

v86.98 creates that guard only from `WebViewDialog.show()` and waits for at least 70% of the real display height before its first paint. The old compact first frame is therefore not drawn. All normal loading layers now use the same text (`جاري تجهيز المتجر…`), 24/14 system typography and green Otlobli wordmark. The React bottom navigation also uses the same platform system font as the injected SHEIN navigation, removing the visible Arabic font-weight change when moving between Home and Orders on Android. No remote font, additional timer, WebView recreation, store-region logic, cache recovery, iPhone recompose timing, or Android resume behavior was changed.

Android 86.98/958 was built and installed on the connected Note 8. A second 0.2-second cold-start capture series confirms the early compressed Otlobli frame is gone; the only branded loading view that appears is the stable, full-height surface with the four complete SVG tabs. Validation passed: production build, low-end performance budget, patch reverse-check, iPhone freeze guard, Android and iOS sync, Android debug build and device install. The real iPhone 16 cold launch and five background/resume cycles remain required; iOS source was synchronized but has not received device acceptance.

APK: android/app/build/outputs/apk/debug/app-debug.apk, 11,234,493 bytes, SHA-256 028C9D1A71B78463546EEBA311B1D5C9B0F35DAF6A9A0366AB0F612CC5E79416.

## Active candidate — v86.97 unified SHEIN loading surface (2026-08-09)

The Android native SHEIN loading guard used a full-screen circular spinner,
while the web boot shell and React host used different loading layouts. This
made a normal open look like several unrelated screens; on Note 8 the native
cover could also clip the top half of the injected Otlobli navigation, leaving
labels without icons.

v86.97 keeps the native guard that prevents raw SHEIN from flashing, but makes
all normal loading states use the same quiet Otlobli wordmark and one concise
status line. The spinner is removed. Android reserves 120dp below the cover
for the real document-start SVG bottom bar (including its WebView safe-area
rounding), and iOS reserves the same established nav footprint with its safe
area. React's connection/preparation states use the same surface instead of a
second header/spinner page. No WebView lifecycle, region-rebuild comparison,
cache recovery, iPhone recompose, or Android resume behavior changed.

Android 86.97/957 was built and installed on the connected SM-N950F / Note 8.
Cold-start capture at the native-cover stage visibly showed otlobli, the
single preparation line, and all four full SVG navigation icons; a later
capture reached the normal SHEIN home. Validation passed: patch reverse-check,
iPhone freeze guard, production build, low-end budget, Android/iOS sync,
Android debug build and Note 8 install. The real iPhone 16 cold launch and
five background/resume cycles remain required; iOS is synchronized but has not
received real-device acceptance from this change.

APK: android/app/build/outputs/apk/debug/app-debug.apk, 11,464,241 bytes,
SHA-256 6925ED05C4AF125FEF1DA623F250C211C5B36EB2F3F9606C8E4E0CCFC6B24BA5.

## Active candidate — v86.96 fast startup + persistent SVG navigation (2026-08-09)

The cold path was waiting for two avoidable delays: it held a usable cached
store region behind the remote settings response, and it waited for the
slower VPN-geo service even when the selected store had already proved
reachable. v86.96 opens immediately from a valid cached region; the existing
`JSON.stringify` guard still recreates the store only if the eventual admin
response truly changes that region. The VPN gate now opens as soon as a real
asset from the selected store decodes, while the geo lookup continues only for
later diagnostic text. A failure still follows the existing VPN/offline path.

An inline, zero-network boot shell now paints the Otlobli brand and four SVG
navigation tabs before the main JavaScript bundle parses. React replaces that
shell on its first render, so there is no empty/icon-less interval. SHEIN's
injected nav also no longer embeds or waits on a complete Cairo font file; it
uses the device system font with the same inline SVG icons. This removes the
short 25 ms font bootstrap loop and a large base64 font payload. No native
WebView lifecycle, cache-recovery rules, recompose timing, or region-change
behavior changed.

Android `86.96/956` was built and installed on the connected SM-N950F / Note
8. A cold activity launch measured `TotalTime: 1741 ms`; passive live
inspection then confirmed a loaded Qatar SHEIN home page with visible
`#otlobli-nav` and four SVGs, while the underlying React shell also contained
four bottom-nav SVGs. No cart/account data was changed. APK:
`android/app/build/outputs/apk/debug/app-debug.apk`, 11,087,570 bytes,
SHA-256 `23ACB683FB90ECF118A8AF15948A1A74B1F5E2402660C8E811391124B83D0E50`.

Validation passed: emitted-script parser, iPhone freeze guard, production
build, low-end budget, Android/iOS sync, Android debug build and Note 8
install. Largest JS is now `1,155,517 / 1,200,000` bytes and total gzip JS
`320,778 / 370,000`, down from v86.95 by 41,096 raw and 33,008 gzip bytes;
CSS/fonts remain within budget. First installs still wait for a real region
and reachability decision, but show the static shell immediately. Real iPhone
16 cold-launch plus five background/resume acceptance remains required.

Unsigned iPhone build [31288703952](https://github.com/m7madv/otlobli/actions/runs/31288703952)
was triggered from source commit `a9a1701` and is currently in progress. It
checks synchronized source/native build health only, not real iPhone behavior.

## Active candidate — v86.95 SHEIN product quantity-option capture (2026-08-09)

The connected Note 8 live DOM for the pink three-makeup-bag product
(`p-216351093`) confirms two independently selected options: `M` under the
SHEIN `مقاس` heading and `1PC` under its `الكمية` heading. Earlier work
correctly prevented `1PC` from being mistaken for a size, but consequently
did not retain it at all. v86.95 captures that product/SKU option separately
as `quantityOption` and appends it to the descriptive cart label only. A new
line will read `متعدد الألوان · M · 1PC`.

Otlobli cart `quantity` deliberately remains `1`, so this does not multiply a
package, its price, or the cart count. The helper reads only selected option
nodes inside an existing SHEIN form and identifies the `الكمية` group; it adds
no polling, page-wide scan, navigation, WebView restart, or iPhone lifecycle
work. Existing cart rows cannot recover an option that was not stored when
they were added; add the current product once after updating to validate the
new label.

Android `86.95/955` was built and installed on the connected SM-N950F / Note
8. APK: `android/app/build/outputs/apk/debug/app-debug.apk`, 11,119,526 bytes,
SHA-256 `A0BE6F3C2DBB696FC3BD7CB8084096034D88F2003DFFE976FBACD9FED761A7A0`.
The emitted-script parser, iPhone freeze guard, production build, low-end
performance budget, Android/iOS synchronization, and Android debug build
pass. Build measurements: largest JS `1,196,613 / 1,200,000`, gzip
`353,786 / 370,000`, CSS `63,029 / 70,000`, fonts `81,364 / 100,000`, SHEIN
source `549,827 / 550,000`. Manual acceptance remains: add that selected
product once and confirm `M · 1PC` in its cart row while the cart stepper stays
at one. The required real iPhone 16 cold-launch and five background/resume
cycles remain unperformed.

Unsigned iPhone build [31288237127](https://github.com/m7madv/otlobli/actions/runs/31288237127)
was triggered from source commit `8d3120b` and is currently in progress. It
verifies the synchronized source/native build only, not real iPhone behavior.

## Active candidate — v86.94 challenge-navigation icons (2026-08-09)

The connected Note 8 showed a real SHEIN `/ar/risk/challenge` page. This was
not a missing-font or delayed-paint issue: the dedicated
`otlobliEnsureChallengeNav()` fallback intentionally created text-only tabs,
whereas normal Otlobli navigation uses inline SVG icons. v86.94 makes that
fallback reuse the exact four inline SVG icons and the normal flex layout, so
the navigation stays visually identical from the first challenge frame through
the storefront. It does not add a timer, font request, WebView restart, or any
iPhone lifecycle change.

The v86.94 Android debug APK (`86.94/954`) was built, installed on the
connected SM-N950F / Note 8, and cold-launched. Live storefront inspection
found all four tabs visible with 22×22 inline SVGs; the built bundle contains
the challenge-nav icon branch. The actual challenge page had already cleared
after the fresh launch, so physical challenge-page rendering must be confirmed
the next time SHEIN legitimately presents it. APK:
`android/app/build/outputs/apk/debug/app-debug.apk`, 11,119,702 bytes,
SHA-256 `291286C4959EA946842A3FCA2FC51440DA78D96201FF721D03048DA661197B8D`.

Research decision: a SHEIN human-verification page is site-controlled and
must not be bypassed, auto-solved, or hidden. The app already keeps SHEIN
cookies/localStorage through normal opens and HTTP-cache-only recovery, enables
Android third-party cookies for SHEIN, and pauses its own heavy page work while
the challenge is on screen. This is the legitimate path to reduce needless
re-prompts; it cannot promise a lifetime/no-challenge result. A future,
separate experiment may flush Android cookies once *after the user completes*
a challenge, provided it is measured for UI blocking and does not alter the
challenge itself. See `docs/KNOWN_ISSUES_AND_DECISIONS.md`.

An unsigned iPhone build was triggered from commit `9562276`: [run
31287796920](https://github.com/m7madv/otlobli/actions/runs/31287796920) was
queued at the time of this update. It checks source/native build sync only; the
required real iPhone 16 cold-launch and five background/resume cycles remain
unperformed and must not be inferred from CI.

## Active candidate — v86.93 SHEIN injected-script parse repair (2026-08-09)

v86.91 introduced a package-member counter using `/\+/g` inside the
`SHEIN_CAPTURE_SCRIPT` TypeScript template literal. Template-literal escaping
emitted the invalid JavaScript regex `/+/g`; Chromium consequently rejected the
**entire** injected script before it could create Otlobli's blocker, add button,
or bottom navigation. The host then timed out waiting for the script's ready
message and incorrectly displayed the preparation/VPN-style error. The VPN was
not the cause.

v86.93 emits `/\\+/g` correctly, removes the redundant heavy SHEIN
`preShowScript` route, and adds a build guard that transpiles and parses the
actual emitted `SHEIN_CAPTURE_SCRIPT`. This makes this class of escaped-template
syntax failure fail the build instead of releasing raw SHEIN. No iPhone
recompose timing, store-region comparison, or WebView reconstruction changed.

Real Note 8 evidence after installation: on the live SHEIN home, `#otlobli-nav`
is `display:flex` with pointer events enabled; on `p-216351093`, both the
Otlobli add button and nav are visible/enabled and no raw SHEIN bottom-nav
candidate is visible. The Android APK is `86.93/953`, `11,120,406` bytes,
SHA-256 `F4B4A97402DA28DC38F09F0814EA3EF08870A6A0C8958224716C4342AE194339`.
It is installed on the connected Note 8. Customer add-to-cart and real iPhone
acceptance remain required.

Unsigned iPhone run `31287002745` was triggered from commit `0c6bb29` and was
still in progress at handoff. It verifies build synchronization only; it is not
a replacement for iPhone device acceptance.

## Active candidate — v86.91 SHEIN three-piece bundle capture (2026-08-09)

The pink bow makeup-bag product (`p-216351093`) has two separate controls in
SHEIN's quick form: `الكمية = 1PC` and `المقاس = مجموعة (صغير + متوسط + كبير)`.
The old generic selector could capture the first control and save `1PC` as the
size. v86.91 scopes the read to the group whose heading is size/measurement,
so the selected bundle is captured as the bundle name and its three members are
shown in the Otlobli cart as `… · 3 قطع`.

`quantity` deliberately remains `1`: it represents one purchased package.
Changing it to `3` would order and charge three complete three-piece packages.
Live Note 8 DOM evidence confirmed the two groups and the selected target; the
release build, freeze guard, performance budget, Android/iOS sync, and Android
debug build pass. The v86.91 APK is installed on the connected Note 8. Manual
customer acceptance remains: choose that bundle, add once, and confirm its cart
line says `3 قطع` while the price is for one bundle. Real iPhone 16 background
cycles and cold launch are still required before iPhone acceptance.

The native SHEIN loading cover now has a quiet 12-second fail-safe on Android
and iOS. It is a cover-only fallback for a missed readiness event, not a WebView
rebuild or a change to the protected iPhone recompose timing. Note 8 restart
inspection confirmed the cover had cleared while the live storefront remained
visible; a full product-flow acceptance is still pending.

Android artifact: `android/app/build/outputs/apk/debug/app-debug.apk`;
`86.91/951`; `11,120,402` bytes; SHA-256
`5F1C8BE741CB25F1535E4831737EA4091320D8C74DBDE2D84B3E75A1F5AB0B3B`.
It was installed successfully on the connected SM-N950F / Note 8.

Unsigned iPhone build run `31286513512` was started from commit `488374d` and
was still in progress at handoff. It is build verification only, not device
acceptance; download/inspection and the required real iPhone tests remain next.

## Active candidate — v86.85 Curvy button reaches its form-aware gate (2026-08-09)

The first v86.84 change correctly made `addToCartFlow()` form-aware, but live Note 8 inspection found a second, earlier gate inside the floating button’s own `click` handler. That duplicate gate called `sheinOpenSkuDrawer()` and checked the background PDP before `addToCartFlow()` ran, so it could still reject a valid Curvy selection. v86.85 removes only that duplicate pre-gate: both normal PDP products and `bsc-quick-add-cart` now use the single form-aware gate in `addToCartFlow()`. This is the chosen fix because it eliminates conflicting decisions rather than adding another Curvy exception.

Device evidence from the live product: the Otlobli button was enabled, painted above the Curvy sheet, and selected `4XL` was visible in the sheet. The SHEIN success toast was also present, but it is unrelated to Otlobli’s cart event. Build/device acceptance for v86.85 remains next.

## Active candidate — v86.84 Curvy quick-add + diagnostics off (2026-08-09)

SHEIN can open a `bsc-quick-add-cart` form for the Curvy/plus-size choice over the regular product page. The previous flow read the regular PDP's still-unselected sizes first, so a real selected Curvy value such as `5XL` was rejected before capture and the Otlobli add button looked unresponsive. v86.84 detects the visible quick-add form before the normal PDP gate; it reads the form's own selected color/size, scopes the required-size check to that form, and captures the same form. It never opens or reads the background PDP while that form is active. This keeps ordinary product selection unchanged and prevents a selected Curvy SKU from being mistaken for an unselected background one.

The Note 8 has the v86.84 debug build installed for validation: `android/app/build/outputs/apk/debug/app-debug.apk` (11,118,174 bytes; SHA-256 `09089059115600186193B537E0540D0FCED293E85E192E48DCA4D87C57EB3D54`). Direct automated access to the exact product is currently served a SHEIN human-verification page, so the final physical Curvy add-to-cart test must be repeated from a normal, already-accepted SHEIN session; no CAPTCHA bypass is implemented or claimed. Local TypeScript/build, performance budget and iPhone-freeze guard pass: raw JS `1,192,836 / 1,200,000`, gzip `352,616 / 370,000`, SHEIN source `546,375 / 550,000`.

Marker: `2026.08.09-v86.84-curvy-quick-add`; native version `86.84 / 944`. This candidate includes the v86.83 diagnostics-off change below.

## Active candidate — v86.83 diagnostics off (2026-08-09)

The customer requested normal releases without the two active diagnostic tools. v86.83 removes the SHEIN price/option diagnostic from the normal customer bundle entirely: no red diagnostic button, no diagnostic overlay, and no 500 ms / 1.5 s diagnostic timers. Its source remains retained for a separately requested diagnostic build, but `App.tsx` no longer imports it. The production bundle is therefore smaller than v86.82: raw JS `1,189,850` bytes (down `8,827`), gzip `351,813` bytes (down `2,583`).

The iPhone freeze probe and native `LOG` trace are also disabled through `SHEIN_IOS_FREEZE_DIAGNOSTICS=false`. This removes observability only; it does **not** remove the iPhone 0.25-second guarded recompose, lifecycle race checks, bounded product-only chunk recovery, region guard, or Android resume defense. The guard verifies both that iPhone diagnostics are off and that the price diagnostic cannot be imported into a normal release.

Marker: `2026.08.09-v86.83-diagnostics-off`; native version `86.83 / 943`. Local build, low-end budget, freeze guard, patch reversibility and Android/iOS synchronization pass. A new iPhone artifact and physical iPhone/Note 8 acceptance are pending. If a new incident occurs, restore diagnostics only in a dedicated build after recording exact steps/device in `docs/KNOWN_ISSUES_AND_DECISIONS.md`.

## Active candidate — v86.82 no-flash SHEIN recovery + weak-device maintenance (2026-08-09)

The v86.81 emergency path correctly proved that a fresh HTTP-cache-only SHEIN session can heal a real PWA chunk incident, but it reacted too broadly: a harmless home-page `ChunkLoadError` could close/reopen a still-healthy store and visibly flash «جاري إصلاح…». v86.82 narrows the bridge to a real product route (`-p-<id>`) and makes host recovery iPhone-only. It retains one 60-second-bounded HTTP cache reset for a confirmed broken iPhone product, but a normal home, normal resume, and all Android chunk notices now remain visually untouched. This is a scope correction; the guarded native iPhone 0.25-second recompose is unchanged.

For weak phones, the document-start nav bootstrap no longer runs an unbounded 1.5–2.5-second `mount()` watchdog. It remounts only on actual `pageshow`/visible return, and the existing SHEIN/Temu periodic work exits while the document is hidden. That removes background DOM work that could compete with resume rendering without removing customer features. The performance guard now verifies this invariant.

Project maintenance is now explicit: `docs/KNOWN_ISSUES_AND_DECISIONS.md` is a permanent Git-tracked incident/decision log and `docs/PROJECT_MAP.md` maps ownership. `AGENTS.md` and `AI_QUICK_HANDOFF.md` require future work to read them, so recurring problems retain their evidence, accepted fix, rejected fix, and test requirement rather than being reconstructed from chat history. Temporary local screenshots are ignored but never deleted by cleanup.

Marker: `2026.08.09-v86.82-shein-no-flicker`; native version `86.82 / 942`. Local validation passes: freeze guard, production web build, low-end budget (raw JS `1,198,677 / 1,200,000`, gzip `354,396 / 370,000`, SHEIN source `543,389 / 550,000`), patch reversibility, Android/iOS sync and Android `assembleDebug`. Local Android artifact: `android/app/build/outputs/apk/debug/app-debug.apk` (11,120,162 bytes; SHA-256 `981D11A3C55499793ECDE8A259E3BAB109026F0E0E2AD3BCE11220576456DD93`). iPhone workflow [31283073598](https://github.com/m7madv/otlobli/actions/runs/31283073598) passed from `8d1b20c`; unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.82-no-flicker\otlobli-ios-v86.82-iphone16\otlobli-v86.82-iphone16-unsigned.ipa` (7,070,839 bytes; SHA-256 `D5571278DB577A2119CD68CB0F2CBB88FAC01B2BF380FD5832B155403EB242E3`; archive confirms `86.82 / 942`). Real iPhone/Note 8 acceptance remains pending. Required device acceptance: iPhone cold launch + five background/resume cycles + home/list/cart product short-taps; verify no recovery message on healthy return. Note 8: cold launch, home/product/cart, background return, and no flash before/after a normal SHEIN open. If an affected iPhone product fails, tap `LOG` before changing store or restarting.

## Active candidate — v86.81 automatic SHEIN chunk-failure recovery (2026-08-09)

The v86.80 device report proves that preserving SHEIN’s own PWA storage alone is not enough. The report starts from a live `/ar/` page after 41 seconds, then records repeated `ChunkLoadError` failures for the same versioned SHEIN assets. A cart product starts navigation but stays on its image/skeleton; a later home navigation produces many more missing chunks followed by `blank`, `/ct.html`, and `/syncframe`. The visible shell can still receive a press, but the product/router code and sometimes the injected navigation cannot finish. This is a confirmed SHEIN PWA asset incident, not a single malformed cart link or a reason to alter iPhone recompose timing.

The customer also proved the safe recovery: Temu → SHEIN immediately produces a healthy product page. That path closes the current browser, clears only WebKit disk/memory HTTP cache, and opens a fresh SHEIN session while retaining cookies, localStorage, the selected country/address, and the site’s service-worker registration. v86.81 now invokes that exact bounded path automatically only when SHEIN itself emits a `ChunkLoadError`: the document-start bridge observes errors, sends one `sheinChunkLoadFailure` message per document, and changes neither network, storage, nor routing. The host debounces the incident for 60 seconds, closes the failed instance, sets the existing bounded cache-reset flag, and opens once. If the failing page is a valid product URL, it is queued again after the fresh session is ready, including cart-origin product preparation.

No native foreground/background/recompose timing changed. The prior v86.80 removal of document-start cache/service-worker deletion remains mandatory; the new recovery is native HTTP-cache-only and happens after an observed failure, never on ordinary resume. The freeze guard requires both the event bridge and the host debounce/recovery path.

Marker: `2026.08.09-v86.81-shein-chunk-recovery`; native version `86.81 / 941`. Local validation passes: expanded freeze guard, `npm run build`, low-end performance budget (largest JS `1,198,435 / 1,200,000`, gzip `354,383 / 370,000`, SHEIN source `543,169 / 550,000`), patch reversibility, and Android/iOS synchronization. GitHub/Xcode [run `31282204234`](https://github.com/m7madv/otlobli/actions/runs/31282204234) passed from `98302bc`; IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.81-chunk-recovery\otlobli-v86.81-iphone16-unsigned.ipa` (7,070,838 bytes, SHA-256 `7977DDDB196D531425BD9B272069AC9F2B2597173276F55FF0F120DA5684C5DA`; archive confirms `86.81 / 941`). Device acceptance remains pending. Acceptance: three exit/return cycles, open a home/list product and a cart product after each, and confirm any chunk incident shows one brief «جاري إصلاح تحميل متجر SHEIN…» recovery rather than a permanent skeleton. If it remains broken after the automatic recovery, tap `LOG` before switching stores or restarting.

## Active candidate — v86.80 SHEIN runtime-cache ownership after iPhone resume (2026-08-09)

The latest user diagnostic resolves the first reproducible part of the “frozen product grid” report. It contains repeated SHEIN `ChunkLoadError` events for assets on `sheinm.ltwebstatic.com` immediately after a new WebView session. The page can therefore render and scroll while its own product-route code is missing; a long press still shows iOS/SHEIN’s native menu, but a normal product tap cannot complete. This is an asset-graph failure, not evidence that the iPhone layer-recompose guard should be removed or retimed.

The actual Otlobli conflict was document-start code that unregistered SHEIN’s service worker and deleted every SHEIN CacheStorage entry on each cold browser session. It could interrupt SHEIN while its PWA runtime was resolving its versioned chunks, producing exactly the reported mixed/failed load. v86.80 removes that runtime-cache interference completely: SHEIN owns its service worker and runtime cache. The existing bounded native `clearCache()` remains intentionally limited to a real store-region transition or a deliberate Temu → SHEIN fresh session, before a new WebView starts; cookies and localStorage are untouched. No native lifecycle/recompose timing changed.

The iOS product-tap safety net remains deliberately narrow: after a real short tap only, it first lets SHEIN handle the card, then tries that same card once and finally routes only to that card’s captured direct product URL if the address did not change. It ignores swipes and presses longer than 650 ms. When diagnostic logging is enabled, the stages `product-tap-start`, `product-tap-fallback`, and `product-tap-route-fallback` are recorded, so any residual failure is attributable rather than guessed. The freeze guard now forbids reintroducing the document-start runtime-cache purge and checks this fallback.

Marker: `2026.08.09-v86.80-shein-resume-product-tap`; native version `86.80 / 940`. Local validation passes: freeze guard, `npm run build`, low-end performance budget (largest JS `1,196,768 / 1,200,000`, gzip `353,859 / 370,000`, SHEIN source `542,018 / 550,000`), patch reversibility, and Android/iOS synchronization. GitHub/Xcode [run `31281456875`](https://github.com/m7madv/otlobli/actions/runs/31281456875) passed from `c87ced2`; IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.80-runtime-cache\otlobli-v86.80-iphone16-unsigned.ipa` (7,070,345 bytes, SHA-256 `C2EAE54EE018F0BF6A25451765FA430CB11EBE51E3EB729813B4A5CC778CF17E`; archive confirms `86.80 / 940`). Real-device acceptance is pending. Required iPhone acceptance: cold launch, open a product once, background/return and tap a product once, five background/resume cycles, then a force-quit/cold launch. If a tap ever fails, tap `LOG` before changing stores or restarting and paste the report.

## Active candidate — v86.79 SHEIN cart product-link repair (2026-08-09)

The diagnostic report isolated the repeatable trigger behind the latest apparent iPhone freeze: a quick-add cart row persisted the malformed route `/ar/-p-57281932.html`. SHEIN renders that path as its **Oops** page. Tapping its return-to-home button then creates the `blank`/frame navigation churn visible in the log, which made the later blocked home look like a WebView rendering failure. The recorded product had a valid long canonical path with the same ID, so this is a cart-link defect, not a reason to retime or remove iPhone recovery.

v86.79 prevents a new bad row by resolving the quick-add product link from the drawer's exact product anchor first. If that exact anchor is unavailable, the authoritative `goods_id` uses the valid non-empty `product-p-<id>.html` form—never the old bare `-p-<id>` form. This removes brittle URL-field guessing while keeping a unique, valid product route. `normalizeSheinBrowserUrl()` also repairs saved legacy cart links at open time, so the user's existing affected cart row is handled without deleting their cart. The freeze guard now rejects a return of the old generator and requires both protections. No native WebView lifecycle/recompose timing, region transition, polling, or challenge handling changed.

SHEIN's “I am not a robot” page is site-controlled and is not bypassed. The app already preserves cookies and localStorage, does not clear them during the bounded cache reset, and leaves recognized challenge URLs untouched; therefore a successfully accepted SHEIN verification is retained for as long as SHEIN itself honors the session. A lifetime/never-again guarantee is impossible because that decision belongs to SHEIN, not the app.

Marker: `2026.08.09-v86.79-shein-cart-product-link`; native version `86.79 / 939`. Local validation passes: freeze guard, `npm run build`, performance budget (largest JS `1,198,378 / 1,200,000`, gzip `354,659 / 370,000`, SHEIN source `543,629 / 550,000`), patch reversibility and Android/iOS synchronization. GitHub/Xcode [run `31280651233`](https://github.com/m7madv/otlobli/actions/runs/31280651233) passed from `0b3ddba`; IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.79-cart-product-link\otlobli-ios-v86.79-iphone16\otlobli-v86.79-iphone16-unsigned.ipa` (7,071,127 bytes, SHA-256 `30A7ECB4BB1FC470B28FCF6F4C4A2BEE185CBB66DC79ED1B053E63F0FF6E64E4`; archive confirms `86.79 / 939`). No real-device acceptance is claimed; acceptance must cover opening the existing cart item, a newly quick-added item, five background/resume cycles, and a force-quit/cold launch.

Last updated: 2026-08-09

## Active candidate — v86.78 iPhone resume-race guard (2026-08-09)

The first v86.77 trace identified a concrete lifecycle race, not a generic WebKit claim. `didBecomeActive` schedules its single 0.25-second recompose, but the trace shows a new `willResignActive` just 39 ms later; without invalidation, production could detach/reattach the WKWebView while the app was already backgrounded. That can corrupt the same remote-layer recovery it is meant to protect.

v86.78 gives each active lifecycle its own generation. The delayed action now runs only if that generation is still current and `UIApplication.shared.applicationState == .active`; `otlobliForceRecompose()` repeats the active-state check at the actual detach point. This preserves the device-proven one-shot, 0.25-second recomposition and scroll/constraint restoration, but cancels a stale callback before it can touch a backgrounded WebView. Android, region rules, cart, navigation and the `JSON.stringify` store-region guard remain unchanged.

The trace remains enabled in this candidate (`SHEIN_IOS_FREEZE_DIAGNOSTICS=true`) but is now observational: normal loading/privacy cover and guarded recovery run, while `SHEIN_IOS_FREEZE_DIAGNOSTICS_BYPASS_RECOVERY=false`; `LOG` stays available to capture any further failure. Marker: `2026.08.09-v86.78-shein-ios-freeze-race-guard`; native version `86.78 / 938`. `npm run build`, expanded freeze guard, patch reversibility and low-end budget pass: largest JS `1,198,034 / 1,200,000`, gzip `354,528 / 370,000`, SHEIN source `543,347 / 550,000`; Android/iOS are synchronized. GitHub/Xcode [run `31279659087`](https://github.com/m7madv/otlobli/actions/runs/31279659087) passed from `9eeb630`. IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.78-race-guard\otlobli-ios-v86.78-iphone16\otlobli-v86.78-iphone16-unsigned.ipa` (7,070,988 bytes, SHA-256 `A1160CBF0D6EFDEA3D8D316FD662748721ED8A542FDBBC730624B766A08E00FD`); archive inspection confirms `86.78 / 938`. No device acceptance is claimed. If any failure remains, tap `LOG` before switching stores, restarting or applying recovery, then paste the report.

## Active candidate — v86.74 SHEIN quick-add product identity (2026-08-08)

v86.74 fixes the device-proven mix-up where a SHEIN recommendation quick-add drawer sat over a different PDP: Rafferiza’s selected swatch/size were captured from the drawer while the Franclia background supplied the title, image and price. The new cold-path-only capture treats `.bsc-quick-add-cart` as a self-contained product: it reads its Vue `productInfo` (`goods_id`, title, source image), active gallery hero, selected colour icon, active size, displayed quick-add price, and a normalized direct product link. It never reads the background PDP cache or structured product store while that drawer is open. `sheinSelectedSkuPricePending()` also skips the background mutation wait for this distinct drawer. This deliberately avoids restoring v86.64’s hot-path global goods-ID logic, which regressed iPhone interaction.

Validation: `npm run build`, the iPhone freeze guard, and the low-end budget pass (largest JS `1,199,417 / 1,200,000`, gzip `355,224 / 370,000`, SHEIN source `545,737 / 550,000`); Android and iOS are synchronized. Android `86.74 / 934` `assembleDebug` passes and is installed on physical Note 8 `988e16384e4f51395230`. The installed runtime passed a bounded CDP payload test built from the inspected real drawer structure and values: **Rafferiza**, `$13.13`, active product image, its selected swatch, `XL`, and a direct `p-143690938` link; that generated link was then opened on the Note 8 and resolved to the Rafferiza PDP. No native lifecycle, region-transition, polling, or iPhone recompose logic changed.

Artifact: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-android-v86.74\otlobli-v86.74-note8-debug.apk` (11,121,750 bytes, SHA-256 `D883F984AF8F96266F988A6B4B1F4F713847029AA0A593E22F28B33BE5B43937`). Existing wrong cart rows are intentionally not migrated; remove/re-add them and complete one live interactive add from a quick-add drawer. iOS source is synchronized at `86.74 / 934`, but no new IPA was requested or built. Real iPhone acceptance remains required: add from a quick-add drawer, five background/resume cycles, then force-quit/cold launch.

## Previous candidate — v86.73 SHEIN product-image / swatch separation (2026-08-08)

v86.73 corrects the image-field mix-up in v86.72: the cart's large `image` is now the SHEIN product image; `colorImage` alone carries the selected small swatch. The swatch is used for the large image only if SHEIN has no product image at all. The real «المزيد من الخيارات» DOM on the Note 8 has five descriptive `<div>` properties (back tie, embroidery, twist, ruffle lace, square neck), with no SKU value, selected state, or purchase control, so it remains product information rather than an invented cart variant. Existing cart rows retain their previously saved wrong image and must be removed/re-added; the app does not erase the user's cart automatically.

Validation: `npm run build`, freeze guard, and low-end budget pass (largest JS `1,199,339 / 1,200,000`, gzip `355,626 / 370,000`, SHEIN source `545,661 / 550,000`); Android and iOS synchronized; Android `86.73 / 933` `assembleDebug` passes and is installed on real Note 8 `988e16384e4f51395230`. No native lifecycle, region-transition, polling, or iPhone recompose logic changed.

Artifact: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-android-v86.73\otlobli-v86.73-note8-debug.apk` (11,121,502 bytes, SHA-256 `43E7726E87CDF4D855E132CD1DAF9A6CC06D4D2ED8A261910DE678FDE5D3E1DE`). iOS source is synchronized at `86.73 / 933`, but no new IPA was requested or built. User should remove one old wrong-image row, add that real icon-based product again with a size, and verify the large card image vs. small colour swatch; iPhone still requires its separate five background/resume cycles and cold launch acceptance.

## Previous candidate — v86.71 automatic SHEIN region-transition recovery (2026-08-08)

Admin remains restricted to Jordan (JO), United Arab Emirates (AE), Qatar (QA), and Saudi Arabia (SA) for each independent store; the Edge Function rejects all other or malformed regions. User diagnosis confirmed that changing to Temu then returning to SHEIN immediately fixes a failed country switch. The proven difference was a fresh SHEIN session with WebKit runtime cache cleared. v86.71 automatically performs that exact bounded recovery whenever the active SHEIN region changes: it preserves cookies/localStorage and the signed address, clears only WebKit disk/memory cache, then opens the requested country once. This removes the repeating «جاري ضبط المنطقة» path without changing address selection, the product-tap fallback, or iPhone recompose timing.
Validation: freeze guard, customer build and low-end budget pass (largest JS `1,198,171 / 1,200,000`, gzip `355,221 / 370,000`, SHEIN source `544,497 / 550,000`); Android/iOS synchronized; Android `86.71 / 931` assemble passes; iPhone workflow [run `31264563690`](https://github.com/m7madv/otlobli/actions/runs/31264563690) passed from `56d1c56`.
Artifact/deploy: the already-deployed app-settings function and official Admin https://talabieh-admin.vercel.app remain current. Unsigned iPhone IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.71\otlobli-ios-v86.71-iphone16\otlobli-v86.71-iphone16-unsigned.ipa` (7,066,154 bytes, SHA-256 `D74FD77854A94774119FF1E541B01F4D9CE9630051F8AA363370CBEC3573B948`). Real iPhone acceptance is still required: clean delete/reinstall, then switch Qatar → SHEIN and Saudi → SHEIN; each must reopen once with no repeating region pill, followed by product open, five background/resume cycles, and force-quit/cold launch.
- **iPhone diagnosis:** SHEIN home is interactive and a long press opens SHEIN’s native “Not interested” menu, but a short tap on a product card in the second listing opened from home does not route. This is a short-tap route failure, not a complete page freeze; Android does not reproduce it.
- **Chosen fix:** the iOS-only, document-start fallback still gives SHEIN 280 ms to handle the original tap, then calls the exact same card’s native `.click()` once only if the URL did not change. It now recognizes the proven second-listing card `LI.sd-ccc-products__item[role="link"]`, in addition to `.product-card` and narrowly named product/goods cards. A real Note 8 CDP click on that exact `LI` navigated SHEIN to its flash-sale route. Swipes and presses longer than 650 ms are excluded, so the native long-press menu remains intact. No polling, overlay, reload, touch prevention, or native recompose timing changed.
- **Saudi bootstrap:** the existing home semantic entry remains `.area-selector-entrance[role="button"]`; the address cascade’s real mobile tabs (`.cascade__tabs [role="tab"]` / `.sui-tab-item-mobile`) are now included in the bounded region path. On the Note 8, signed Saudi state remains `Riyadh Province → Riyadh → Al Olaya`; a fresh first-ever-SHEIN session still needs iPhone acceptance.
- **Portrait only:** iOS was already declared portrait-only in `ios/App/App/Info.plist`; Android now explicitly locks `MainActivity` to `portrait`. This avoids adding orientation code near the WebView.
- **Validation/sync:** `npm run build`, `verify:shein-freeze-guard`, and low-end budget pass: largest JS `1,197,893 / 1,200,000`, gzip `355,148 / 370,000`, SHEIN source `544,255 / 550,000`. Android/iOS were synchronized; Android `86.69 / 929` debug build installed on real Note 8 and reports the signed Saudi cookie. iPhone workflow [run `31262261007`](https://github.com/m7madv/otlobli/actions/runs/31262261007) passed from `53d8191`; unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.69\otlobli-v86.69-iphone16-unsigned.ipa` (7,066,086 bytes, SHA-256 `93A5C452200CBC5ACD736DA1A2592FAAE8B970E8D111E7B8C35DCA0A1607D6DC`). Physical iPhone acceptance is pending.
- **Required iPhone acceptance:** clean delete/reinstall the v86.69 IPA, short-tap a home card then a card inside the resulting listing, confirm long press only opens SHEIN’s menu, then perform five background/resume cycles and a force-quit cold launch. Do not mark the iPhone issue resolved until this is done.

## WhatsApp "waiting for this message" (iOS) — LID root cause + fresh-session fix (2026-08-08)

- **Symptom (device-confirmed by user, post-deploy):** iOS recipient — first OTP eventually decrypts after opening the chat (~2-3s), but a SECOND OTP is stuck on «في انتظار هذه الرسالة» forever. Server error log showed `Closing stale open session for new outgoing prekey bundle` on every send.
- **Root cause = LID addressing** (confirmed via Baileys issues #1739/#1744/#1701, not my earlier getMessage/IDLE guess): modern WhatsApp (esp. iPhone) registers identity under `xxxx@lid`, Signal keys are saved for the @lid identity, but we send to `phone@s.whatsapp.net` → key/identity mismatch → recipient can't decrypt. First msg works (fresh session from scratch); second reuses the mismatched session → stuck. The `Closing stale open session` log itself is benign (per a Baileys contributor); LID is the real fault. My prior getMessage/IDLE hardening does NOT fix it (resend reuses the broken session).
- **Constraint:** we're outbound-only (OTP/notify) — we never receive from these numbers, so we can't learn their LID to send to it; and Baileys is `6.6.0` (LID send-support is in the 7.0.0-rc line / `add-lid-to-message-key` PR).
- **Fix chosen (user-approved, low-risk, no QR/upgrade):** force a fresh Signal session on EVERY send so each message behaves like the always-working "first message". New `forceFreshRecipientSession(session, jid)` in `server/src/whatsapp.js` deletes the recipient's `session-<pn>.*.json` records via `sock.authState.keys.set({session:{...:null}})` before `sendMessage`; Baileys then re-fetches prekeys and builds a clean session. Wired into `sendHumanLike(session, jid, …)` (both OTP + notification paths). Toggle off without redeploy via env `WHATSAPP_FRESH_SESSION_PER_SEND=0`. Safe: sends are serialized (`paceSend`) so no concurrent-session race; creds untouched (no re-link). Cost: an extra prekey fetch per send (fine at OTP volume).
- **DEPLOYED + DEVICE-VERIFIED 2026-08-08** on Oracle VM. **User confirmed WhatsApp works** («زبط الواتساب»). Server logs prove it: `🧹 جلسة نظيفة للمستلم 97470067040` fired before each send, TWO back-to-back OTPs (6875 then 8463 — the previously-permanently-stuck "two in a row" case) both `✅ OTP … sent`, and the error log is now EMPTY (the `Closing stale open session` churn is gone). Backup `~/otlobli-server/src/whatsapp.js.bak-prelid-20260808-005915`. Rollback if ever needed: `WHATSAPP_FRESH_SESSION_PER_SEND=0` in `.env` + `pm2 restart otlobli-wa`, or restore the `.bak-prelid-…` file. Escalation path if it ever regresses: Baileys 7.0.0-rc + send-to-@lid (needs phone ready for possible QR).

## `main` promoted to v86.67 — admin swatch deployed (2026-08-07)

- **Merged** `claude/shein-sku-image-freeze-bugs-52b525` → `main` as a clean **fast-forward** (`3d0566c` → `679f476`). `origin/main` now carries v86.66/v86.67 SHEIN store-based capture + admin colour swatch + WhatsApp iOS hardening. No merge commit, no history loss.
- **Admin (Vercel `talabieh-admin.vercel.app`):** auto-deploy triggered by the push to `main`; site verified live (login screen responds). Visual confirmation of the swatch needs an admin PIN login on an order that has a colour — pending user check.
- **WhatsApp server (Oracle VM `84.8.100.128`, user `ubuntu`, key `~/Downloads/ssh-key-2026-07-22.key`) — DEPLOYED 2026-08-08 via SSH.** The live server was running `whatsapp.js` frozen at commit `39ab8b4` (Jul 22, VM setup day) — 3 commits behind repo, NOT the 1-file patch the handoff assumed. Verified no unique on-server edits, no new npm deps (no new imports), safe env defaults (`WHATSAPP_IDLE_TIMEOUT_MS`→1800000, `WHATSAPP_PER_NUMBER_PER_DAY`→300, `TELEGRAM_ALERT_CHAT_ID`→falls back to `TELEGRAM_CHAT_ID`), identical `wa-sessions` session logic. Backed up live file → `~/otlobli-server/src/whatsapp.js.bak-20260808-002942`, uploaded repo HEAD (636 lines), `pm2 restart otlobli-wa`. Post-deploy: process **online & stable** (no crash loop, empty error log), **session preserved** (`wa-sessions/0` creds intact — no QR re-link; slot `1` was always empty/unlinked), `/health` ok. Deploy brought 2 extra undeployed features too (onWhatsApp pre-send verify — fail-open, only blocks explicit non-WA numbers; number-health caps). **NOT end-to-end verified** — confirming a real OTP delivers needs sending a real WhatsApp message (outward); user tests by requesting a login code in the app. **Rollback (one cmd):** `ssh -i <key> ubuntu@84.8.100.128 "cp ~/otlobli-server/src/whatsapp.js.bak-20260808-002942 ~/otlobli-server/src/whatsapp.js && pm2 restart otlobli-wa"`.
- **Optional root fix STILL PENDING:** upgrade Baileys `6.6.0`→`6.7.24` on the VM (`npm install @whiskeysockets/baileys@6.7.24 && pm2 restart otlobli-wa`). Carries QR re-link risk — do it with the service phone ready; rollback to `6.6.0` if it demands a re-scan. Not done autonomously (would risk knocking OTP offline).
- **iPhone — STILL PENDING (user-run):** delete + clean-install `otlobli-v86.67-iphone16-unsigned.ipa` (SHA-256 `db0c608694bf1ac6cc5384c6fdae3b46451b4d2ebe53598fdfac255a62de5ff7`). Installing over the old app keeps stale/frozen WebView state — always delete first.

## Admin colour swatch + WhatsApp iOS "waiting" hardening (2026-08-07)

- **Admin colour swatch (`admin/src/AdminApp.tsx`):** ambiguous colour names («متعدد الألوان») can't be told apart in order text. The app already captures `colorImage` (each variant's distinct image), but admin showed the name only. Added `ColorCell` — renders the swatch (image, or gold gradient for ذهبي like the customer app) before the colour name in both order views (list card + modal); added `colorImage` to admin `CartItem`. **Deploy:** admin is Vercel (`talabieh-admin.vercel.app`) — needs a redeploy (merge to main / Vercel deploy). App side already ships `colorImage` (v86.67).
- **WhatsApp OTP "waiting for this message" on iOS recipients (`server/src/whatsapp.js`):** known Baileys+iOS issue; iOS asks for a resend (retry receipt) minutes later but the session was cut after 5 min idle so it never resent → stuck. Fixes: `IDLE_TIMEOUT_MS` 5m→30m (env `WHATSAPP_IDLE_TIMEOUT_MS`) to catch late retries + cut reconnect churn; persist the resend message store to disk (`_wa-msg-store.json`) so restarts don't lose it; diagnostic log in `getMessage`. **Deploy:** scp `server/src/whatsapp.js` to Oracle VM + `pm2 restart`. **Recommended root fix:** upgrade Baileys 6.6.0→6.7.24 on the VM (`npm install @whiskeysockets/baileys@6.7.24`), test, rollback to 6.6.0 if it needs a re-link.

## v86.66 SHEIN store-based capture — authoritative, not DOM guessing (2026-08-07)

- Marker `2026.08.07-v86.66-shein-store-based-capture`; iOS `86.66/926`; branch `claude/shein-sku-image-freeze-bugs-52b525`. Built on the WORKING v86.65 baseline (v86.63 code), so it does NOT reintroduce the v86.64 iOS breakage.
- **Rewrote capture to read SHEIN's own structured Vue store as the authoritative source** (DOM heuristics were the root of the wrong colour/size/price bugs). New `sheinStoreVariant()` replaces `sheinStoreSelectedSku()`:
  - colour + image from `mainSaleAttribute.info[goods_id === current]` → the current variant's true colour + image.
  - size + real price + sku_code from the `multiLevelSaleAttribute.sku_list` entry whose `sku_sale_attr` matches the shopper's selected DOM values (`priceInfo.salePrice.usdAmount`). «نوع الموديلات» is kept in size, not leaked as colour; range products ("من $X") ship the real per-variant price instead of 0.
  - `captureProductPayload` overrides colour/image/size/price with it; falls back to the existing DOM path when the store shape is unavailable. `__otlobliDiag.storeVariant` added for CDP diagnosis.
- **CONTAINMENT (iOS safety):** all new code runs ONLY in the cold capture path (`captureProductPayload`, on add-tap), NOT in tick/observer/shipping/interaction — unlike v86.64's hot-path store reads that broke iOS.
- **Device-validated on Note 8 (CDP, real store data)** for the jewelry set `p-327715649`: colour `فضي`/`«35 عنصرًا»` → **ذهبي أصفر**; image wrong-swatch → correct 405×552; size mixed → **مقاس واحد / 35 عنصرًا**; price `0/range-blocked` → **$3.43** (sku `I9dop5b11wy9`). Normal product `p-413586970` (socks): no regression, image quality improved (405×552 vs 96×).
- Budget: local (real env) largest JS raw `1,199,380/1,200,000`; freeze guard OK. Re-trimmed three Temu comment blocks to fit.
- **iOS still needs clean delete+reinstall to test** (installing over the old app keeps stale WebView state — see below).

## v86.65 REVERT capture to v86.63 — v86.64 froze SHEIN on iPhone (2026-08-07)

- Marker `2026.08.07-v86.65-revert-capture-to-v86.63`; iOS `86.65/925`; branch `claude/shein-sku-image-freeze-bugs-52b525`.
- **Device report (iPhone):** v86.64 froze the SHEIN listing from the FIRST open (no backgrounding) — products render on scroll, but tapping a product never opens it. v86.63 worked. The only diff v86.63→v86.64 is the two capture fixes below.
- **Could NOT reproduce on Android (Note 8) via CDP:** real `adb input tap` on category cards, product cards, and ranking cards ALL navigated; our click handler never blocked any (`defaultPrevented=false`), and no body-lock/overlay ever appeared. The v86.64 functional changes are provably inert on the listing (goods_id keying is passive; the `inspect()` SKU rejection only matters when a shipping drawer is open, which never happens on a category listing). So the regression is iOS-WKWebView-specific and I have no iOS repro/debug path here.
- **Action:** reverted `src/services/sheinBrowserScript.ts` entirely to the v86.63 blob (`git checkout 3967f8e -- ...`) to restore usability immediately; bumped to v86.65. iOS build run `31162247380` **passed** (CI budget largest JS raw `1,199,433/1,200,000`). Unsigned IPA `otlobli-v86.65-iphone16-unsigned.ipa` at `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.65\`; SHA-256 `6ef72ab93ad8e02aed13ebe5d8a9a20106309497d03fbec2fc2cef9c7bf1b68b`.
- **CONFIRMED WORKING on iPhone (2026-08-07):** after a CLEAN delete+reinstall, v86.65 restores product taps. This also confirmed v86.64 was the iOS breakage. **Critical iOS test lesson:** installing an IPA OVER the old app keeps the old/frozen WebView state, so the fix looked broken until the app was fully deleted and reinstalled clean. Always delete+reinstall for iOS acceptance.
- **Still open (deferred):** the two v86.64 capture fixes (quick-add image/colour leak + size-select freeze) are NOT in v86.65. They remain in git history at commit `58d2ce7` (v86.64). Redo them only with a real iPhone verification loop (clean reinstall each test), since the freeze they caused is iOS-only and invisible on Android. See [[project_shein_pathname_state_leak]].

## v86.64 SHEIN SKU image/color leak + size-select freeze (2026-08-07)

- Marker `2026.08.07-v86.64-shein-sku-image-freeze-fix`; branch `claude/shein-sku-image-freeze-bugs-52b525` (fast-forwarded onto v86.63 base). Fixes the two open bugs from the v86.63 SKU-capture handoff.
- **Bug 1 (image/color/icon leaked from product A to B):** the colour/image/price stash and `__otlobliSkuMemo` were keyed only on `location.pathname`, which is shared across quick-add products on one listing route, so product A's stale colour + colour image + memo bled into product B. Fix: new `sheinGoodsId()` (reads Vue `store.state.productDetail.coldModules.productInfo.goods_id`, falls back to pathname). Stash now stamps `__otlobliSelectedSkuGoodsId` at swatch-tap and at price `commit()`, and every consumer (`getPrice`, `sheinSelectedSkuPricePending`, the drawer colour/image/size payload block) requires the stamped goods_id to equal the current one. `sheinSkuMemo` and its three drawer resets are now keyed by `sheinGoodsId()` instead of pathname.
- **Bug 2 (size-select freeze + false "close the shipping list first"):** the SKU size/colour drawer is also a `.sui-drawer__body` with `role="option"` items, so `sheinResolvedShippingUiRoot()` misread it as the shipping/address drawer, which locked the page (froze) and blocked add-to-cart. Fix: `inspect()` now rejects any candidate that contains SKU markers `[data-attr_value_id],.SIZE_ITEM_HOOK,.j-select-to-buy,.goods-size__sizes` — those never appear in the real shipping drawer.
- No timer/region/price/payment/wallet/order or native WebView lifecycle behavior changed. Condensed three Arabic Temu comment blocks (logic untouched) to hold the CI budget.
- Validation: `npm run build` OK; `verify:shein-freeze-guard` OK; `verify:performance-budget` OK — local largest JS raw `1,198,401 / 1,200,000` (base v86.63 was `1,198,358`), SHEIN script source `544,668 / 550,000`.
- iOS build: workflow `ios-unsigned-build.yml` run `31158730740` on branch `claude/shein-sku-image-freeze-bugs-52b525` **passed** (CI budget largest JS raw `1,199,589 / 1,200,000`). Unsigned IPA `otlobli-v86.64-iphone16-unsigned.ipa` (iOS `86.64/924`) copied to `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.64\`; SHA-256 `1c0751598196b2713bcd28285b5d08c007eacd9fc24a2630a1cb07d3e286234f` (CI-reported hash matches the downloaded file). Android not rebuilt this task.
- **Not yet device-verified on Note 8 / iPhone** (browser preview can't exercise SHEIN's real DOM/Vue store). On-device acceptance of the two products still pending: add product A (correct), then a quick-add product B must show its OWN colour + image, and selecting a size must not freeze or trigger the false shipping block.

## v86.54 SHEIN selected color capture from cart screenshots (2026-08-02)

- Current marker is `2026.08.02-v86.54-shein-selected-color-capture-fix`; Android/iOS are `914/86.54`. Branch is `claude/shein-drawer-open-fix`.
- User reported three SHEIN cart color defects visible on both iPhone and Android: text-button color product selected `لون القرنفل` but cart showed `أبيض حريري`; another row stored all color labels and put the chosen color at the end; an `انقر للشراء` product kept the previous red-purple image after the customer changed to green in the opened selector.
- Fix: `getSelectedWithin()` now extracts labels only from a single selected option, rejects selected wrapper/container text that contains multiple option children, and falls back to the visually selected black/white option button when SHEIN does not expose `aria`/class selection. `getColorState()` now trusts the direct selected option before stale page heading text. `getSelectedColorSwatchImage()` skips selected multi-option wrappers, and SHEIN payloads prefer `colorState.image` over the hero image so cart thumbnails do not keep a previous color while the hero is lagging.
- To keep budgets safe, one old explanatory comment block inside `SHEIN_CAPTURE_SCRIPT` was removed; no timer, polling, region, price, payment, wallet, order, or native WebView lifecycle behavior changed.
- Validation so far: `npm run build` passed; `verify:shein-freeze-guard` OK; `verify:performance-budget` OK with largest JS raw `1,197,091 / 1,200,000`, JS gzip `355,995 / 370,000`, CSS `63,029`, fonts `81,364`, SHEIN script source `543,352 / 550,000`; extracted `SHEIN_CAPTURE_SCRIPT` parses with `new Function`; `npx cap sync android`; `npx cap sync ios`; Android Gradle `assembleDebug` passed. APK copied to `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-android-v86.54\otlobli-v86.54-debug.apk`; SHA-256 `366BBDFF77FD5A6535AFDCF1C7B62E40198EA964E4D8CA4AF1CDA3B9326F62D2`; size `11,121,882` bytes.
- iOS workflow run `30745439884` at commit `c590373` passed. CI budget reported largest JS raw `1,198,279 / 1,200,000`. Unsigned IPA copied to `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.54\otlobli-v86.54-iphone16-unsigned.ipa`; SHA-256 `B04E34DB4A612A7589482B0C7DC7744E77BE707254A0FB85684F9BF0E7562152`; size `7,067,006` bytes. Inspection confirms `com.otlobli.app`, `86.54/914`, no app-level `_CodeSignature`, no `embedded.mobileprovision`, marker `2026.08.02-v86.54-shein-selected-color-capture-fix`, `sheinSelectionLabel`, `sheinLooksVisuallySelected`, and native freeze symbols `otlobliForceRecompose`, `appDidBecomeActive`, `navigateHostFromJavaScript`, `otlobli:nativeNavigate`.
- Real iPhone/Android acceptance on the three photographed products is still pending. ADB currently lists no connected Android device.

## v86.53 Note8 cart gold swatch + v86.52 freeze chain (2026-08-02)

- Current marker is `2026.08.02-v86.53-cart-solid-color-swatch-fix`; Android/iOS are `913/86.53`. Branch is `claude/shein-drawer-open-fix`. Base fix commit `861031f` is pushed; a follow-up in this task removes shipped comments only to restore iOS CI bundle headroom.
- User-reported cart issue: items whose text says `ذهبي أصفر` could show a circular `colorImage` copied from a previous SHEIN product. Device storage confirmed the same old 96px SHEIN URL persisted across different cart items. v86.53 renders `ذهبي/Gold` variants as a local gold CSS swatch and strips `colorImage` for new adds with that color.
- Included underneath from the same session: v86.49-v86.52 Note 8 fixes for slow first product/cart reopen, login-bar hiding, low-end throttling, selected SKU price capture in `.SIZE_ITEM_HOOK` drawer groups, stale fixed-body unlock, security challenge body-lock release, and the v86.52 freeze root cause: product `[role=tab]` review tabs were misclassified as shipping address tabs. Shipping-tab detection is now scoped to `.address-header-tab`.
- Note 8 validation: installed `86.53/913`; existing cart still had stale `colorImage` data, but DOM for the three checked `ذهبي أصفر` rows now reports `.cart-item-color-swatch` as `SPAN` with gold `linear-gradient(...)`, not `IMG` and not the stale product URL. v86.52 product tab/body-lock tests passed before the cart swatch patch.
- Initial iOS workflow run `30744352856` at `861031f` failed before Xcode because CI's real `VITE_*` values pushed largest JS raw to `1,201,132 / 1,200,000`. The follow-up keeps behavior unchanged and removes 48 explanatory comment lines that ship inside `SHEIN_CAPTURE_SCRIPT`.
- Build/sync validation after the trim: `npm run build` passed; `verify:shein-freeze-guard` OK; `verify:performance-budget` OK with largest JS raw `1,196,344 / 1,200,000`, JS gzip `355,943 / 370,000`, CSS `63,029`, fonts `81,364`, SHEIN script source `542,610 / 550,000`.
- Android/iOS sync passed again and Android Gradle `assembleDebug` passed. APK: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA\.claude\worktrees\brave-gould-c49b60\android\app\build\outputs\apk\debug\app-debug.apk`; SHA-256 `F25829AC663691663F0FBE518C93C0A662FC95021C7186272512A70911BE7A95`; size `11,123,806` bytes.
- iOS workflow run `30744565468` at commit `96f0beb` passed. CI budget reported largest JS raw `1,197,532 / 1,200,000`. Unsigned IPA copied to `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.53\otlobli-v86.53-iphone16-unsigned.ipa`; SHA-256 `A756B746DF0E606530FC8B401ABF4B2CFA2CD7718015793BD08A213AA28B91EE`; size `7,067,379` bytes. Inspection confirms `com.otlobli.app`, `86.53/913`, no app-level `_CodeSignature`, no `embedded.mobileprovision`, marker `2026.08.02-v86.53-cart-solid-color-swatch-fix`, gold swatch marker, `.address-header-tab` scoped guard, and native symbols `otlobliForceRecompose`, `appDidBecomeActive`, `navigateHostFromJavaScript`, `otlobli:nativeNavigate`.
- Evidence screenshots: `output\note8-v8653-cart-swatch.png` plus earlier freeze diagnostics under `output\`. Real iPhone 16 acceptance, five background/resume cycles, and force-quit/cold-launch were not performed.

## v86.47 SHEIN drawer: أربعة أعطال حقيقية (2026-08-01)

- Current marker is `2026.08.01-v86.47-shein-options-clear-of-button`; Android/iOS are `907/86.47`. Branch `claude/shein-drawer-open-fix`, commit `154338c`.
- PR [#1](https://github.com/m7madv/otlobli/pull/1) open for merge to `main`.
- **Android verified on device**: add-to-cart with correct price $21.08, "L / أخضر" on 3-Tier-Lockable product. Options visible and clear of floating button.
- **iOS IPA**: build run `30711387365` passed. IPA on Desktop: `otlobli-ios-v86.47/otlobli-v86.47-iphone16-unsigned.ipa`.
- Four bugs fixed (all measured on Note 8 via CDP):
  1. Heading `مقاس/لون` (reversed) not accepted → accept both orders
  2. `li` missing from selector queries → added
  3. Toggle: pressing while open closes → skip if options already visible
  4. Floating button covers options → `scroll-margin-bottom` clears them
- JS budget: `1,198,804/1,200,000` (headroom ~1,196 bytes locally).

## v86.46 SHEIN reveals the options it opened (2026-08-01)

- Current marker is `2026.08.01-v86.46-shein-reveal-sku-options`; Android/iOS are `906/86.46`. Branch `claude/shein-drawer-open-fix`, commit `47b216b`.
- **First fix in this series diagnosed on real hardware instead of inferred.** The user's Note 8 (SM-N950F) is reachable over ADB and the app's WebView exposes `@webview_devtools_remote_<pid>`, so the live SHEIN DOM was inspected over CDP (hand-rolled WebSocket client, no deps) while the app ran.
- What the device proved, against every earlier assumption: **v86.45 already worked.** Pressing `أضف للسلة` recorded `__otlobliTapTrace = SPAN.capsule-box touch=1 cancel=0`, `.SIZE_ITEM_HOOK` went `0 -> 2` and four `.sui-drawer` nodes appeared - SHEIN *did* open the selection. But it renders the revealed `نوع الموديلات` / `مقاس` groups roughly 500 CSS px below the fold, so not one pixel of the screen changed and the user correctly reported `لا يحدث شيء أبدا`. The press was never the missing piece; showing its result was.
- Also measured, and worth keeping: the real control is `li.j-select-to-buy.goods-size__click-to-buy` (SHEIN's `j-` prefix marks a JS hook) wrapping `span.capsule-box`; a plain `.click()` on it works once it is on screen; the entry row sits below the viewport at rest, which is why `sheinTapElement` clamps its coordinates - harmless, because the event target and its bubble path are what matter.
- `sheinRevealSkuOptions()` (in `sheinSkuTap.ts`) scrolls the last `.SIZE_ITEM_HOOK` to centre 280ms after the press, retrying up to five times while SHEIN renders. Nothing else changed.
- Device acceptance for the fix itself, on `Jewelry-Tray-Organizer...` (a real `انقر للشراء` product): before the press `SIZE_ITEM_HOOK: 0`; after it `2`, both groups inside the viewport (`394-557` and `593-632` of `773`), and the screenshot shows the colour swatches, all sixteen `نوع الموديلات` options and `مقاس`. Verified on the Android build of the same source; iPhone acceptance is still owed.
- GitHub/Xcode run `30704341295` passed (CI reported JS raw `1,199,011/1,200,000`, freeze guard OK). Unsigned IPA on the Desktop: `otlobli-v86.46-iphone16-unsigned.ipa`; SHA-256 `4DF6FA6DE9809787204E4862DA98160F5D97A6022D28C6B508D4D4D2BCD80FF9` (matches CI); size `7,068,834` bytes; inspection confirms `86.46/906`, `sheinRevealSkuOptions` present, `sheinConfirmSkuDrawer`/`entry.click()` absent, native recompose symbols intact.
- Reproducible diagnosis recipe for the next session, since it collapsed days of blind guessing into one hour: `adb forward tcp:9222 localabstract:webview_devtools_remote_$(adb shell pidof com.otlobli.app)`, then `curl http://127.0.0.1:9222/json` for the `m.shein.com` page and drive `Runtime.evaluate` / `Page.captureScreenshot` over the WebSocket. `adb exec-out screencap -p` shows what the shopper actually sees; keep the screen awake (`settings put system screen_off_timeout`) or captures come back black/stale.

## v86.45 SHEIN SKU drawer, single press (2026-08-01)

- Current marker is `2026.08.01-v86.45-shein-sku-drawer-single-press`; Android/iOS are `905/86.45`. **v86.44 is device-rejected**: "خربت الدنيا ولا شي زابط".
- Regression cause, and the lesson: `sheinConfirmSkuDrawer()` assumed a drawer covers the row it was opened from. That is false — SHEIN's options drawer is a bottom sheet and the entry row above it stays visible and uncovered. The 450ms probe therefore concluded "did not open" on a drawer that HAD opened, its retry tap closed it again, and the refusal message then appeared on every product. Never verify a UI state with a probe that has not been observed on device; a wrong probe is worse than no probe.
- Recovery: `src/` was restored to `2dccab9` (v86.43) in full, then only the requested behaviour was re-applied. The complete functional delta against v86.43 is now: `sheinSkuTap.ts` interpolated into the capture script, the `انقر للشراء` pattern moved to the shared `OTLOBLI_SKU_PROMPT` constant (identical semantics), `entry.click()` replaced by one real tap on the chip, and the dead `debugSnapshot` removed. No timer, no retry, no new refusal message.
- The user's requirement, restated from their own words: on a product whose colour/size lives behind a separate screen (`انقر للشراء`), pressing `أضف للسلة` must immediately press `انقر للشراء` so SHEIN opens its own selection panel.
- GitHub/Xcode run `30701409445` at commit `5a26700` passed; CI reported JS raw `1,198,673/1,200,000` and freeze guard OK. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.45-iphone16-unsigned.ipa`; SHA-256 `D741EDC4623D7C2A24E637DA992171CAF6689B0CF0C29DDA56F4E9DA7F9C379D` (matches CI); size `7,068,730` bytes. Inspection confirms `com.otlobli.app`, `86.45/905`, unsigned and unprovisioned, `sheinTapElement`/`sheinSkuPromptNode`/`__otlobliTapTrace` present, `sheinConfirmSkuDrawer`/`entry.click()`/`debugSnapshot` all absent, and the native `otlobliForceRecompose`/`appDidBecomeActive`/`navigateHostFromJavaScript` symbols intact.
- Device acceptance is still owed for v86.45: one press on `أضف للسلة` must open SHEIN's own colour/size panel and leave it open. If it does not, capture the diagnostics `لمسة:` line before changing anything.
- Budgets as CI sees them (LF endings, realistic secret lengths): JS raw `1,198,715/1,200,000` — headroom `1,285` bytes, against `154` for v86.43 — gzip `357,786/370,000`, SHEIN source `545,598/550,000`; freeze guard OK. Syntax check and the four-scenario tap harness pass.

## v86.44 SHEIN SKU drawer opened by a real tap (2026-08-01, device-rejected)

- Current marker is `2026.08.01-v86.44-shein-sku-drawer-tap`; Android/iOS are `904/86.44`. Branch is `claude/shein-drawer-open-fix`, branched from `claude/ios6-cover-fix` at `2dccab9`. Price capture, region logic, payment/wallet paths and the native recompose patch are untouched.
- Defect: on device the options drawer never opened for `انقر للشراء` products, and the add button gave no feedback at all. v86.43 activated the entry with `entry.click()`, which reaches only listeners bound to `click` on that exact node or an ancestor; SHEIN's mobile PDP binds the options entry with a touch directive on an inner chip, so no listener ran, while `sheinOpenSkuDrawer()` still returned `true` and `addToCartFlow` returned silently. The v86.42 note that "direct `entry.click()` is required" is therefore superseded.
- `src/services/sheinSkuTap.ts` (new, interpolated into `SHEIN_CAPTURE_SCRIPT` beside `sheinSkuSelectionEntry`, same pattern as `OTLOBLI_NAV_TOUCH_BRIDGE_JS`) adds three functions. `sheinTapElement()` replays a real tap — `pointerdown → touchstart → pointerup → touchend → mousedown → mouseup → click` — on the deepest node under the target's centre, so every binding up the ancestor chain fires; if the page cancels the touch, the mouse/click tail is dropped exactly as a browser drops it, so a dual-bound row cannot be activated twice and toggled shut. `sheinSkuPromptNode()` aims at the `انقر للشراء` chip rather than its label row. `sheinConfirmSkuDrawer()` re-taps once after `450ms` and then shows `اضغط "لون/مقاس" واختر ثم أضف`; its probe is row coverage, not SHEIN class names.
- The diagnostics overlay gained a `=== الدرج ===` section: entry row class/text, `window.__otlobliTapTrace` (tapped tag/class, whether real touch events were constructible, whether the page cancelled them, tap coordinates) and the live `.SIZE_ITEM_HOOK` count. A failed tap is now visible instead of silent.
- Verification performed: injected-script syntax check on the composed `SHEIN_CAPTURE_SCRIPT`; a four-scenario harness over a synthetic DOM proving a touch-bound chip fires with no compat click, an ancestor `click` handler fires exactly once, an engine without `TouchEvent` still reaches the chip, and a blocked `elementFromPoint` falls back to the element itself; `verify:shein-freeze-guard` OK; production build OK.
- Budgets measured the way CI sees them (LF endings plus secrets of realistic length): JS raw `1,199,237/1,200,000`, JS gzip `357,972/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `545,637/550,000`. Correction to the previous handoff: CI is `1,230` bytes larger than a secretless local build, not `~120`, because Vite inlines the real `VITE_*` values; v86.43 passed CI with only `154` bytes to spare. Headroom was rebuilt to `763` bytes by moving the new module's explanation out of the injected template (comments inside it ship verbatim), compressing the longest shipped comment blocks without dropping any recorded fact, deleting the dead `debugSnapshot`, and removing a paragraph duplicated verbatim in the Temu white-screen guard.
- Nothing was built natively in this worktree (no toolchain, no real `VITE_*` secrets), so the iOS artifact came from the workflow. GitHub/Xcode run `30700779023` at commit `9f6e6c0` passed; CI's own budget report was JS raw `1,199,195/1,200,000`, gzip `358,023/370,000`, SHEIN source `545,637/550,000`, freeze guard OK. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.44-iphone16-unsigned.ipa`; SHA-256 `35F619FCFA922948D8C4F1A19926060F9A3F0BEB3053C87E04A18B81E0696A82` (matches the hash printed by CI); size `7,068,496` bytes. Inspection confirms `com.otlobli.app`, `86.44/904`, only the `otlobli` URL scheme, no app `_CodeSignature` and no provisioning profile; the bundle contains `sheinTapElement`/`sheinSkuPromptNode`/`sheinConfirmSkuDrawer`/`__otlobliTapTrace`, the `اضغط "لون/مقاس" واختر ثم أضف` message and the `=== الدرج ===` diagnostics section, with `entry.click()` and the dead `debugSnapshot` gone, and the native binary still exports `otlobliForceRecompose`, `appDidBecomeActive`, `navigateHostFromJavaScript` and `otlobli:nativeNavigate`.
- `ios-unsigned-build.yml` no longer hardcodes a version: it reads `MARKETING_VERSION` from `project.pbxproj` and prints the IPA's SHA-256. The literal had been stuck at `v86.42`, so every later run produced a file named after a version it did not contain. No Android APK was produced in this batch.
- Real-device acceptance is not performed. Required: on an `انقر للشراء` product, one tap on add must open the options drawer; then colour/size selection and add must land the right price. If it still does not open, the diagnostics `=== الدرج ===` section (`لمسة:` line) identifies the node that was tapped and whether touch events were constructible at all — capture it before the next change. Five background/resume cycles plus a cold launch remain mandatory. The signed `addressCookie` region defect is untouched and still open.

## v86.42 SHEIN image-swatch colors and inline size focus (2026-08-01)

- Current marker is `2026.08.01-v86.42-shein-image-swatch-color-inline-size-focus`; Android/iOS are `902/86.42`. Real-device diagnostics for product `p-453254089` reject v86.41: the active image swatch existed but color was empty, and add did not take the user to the unselected inline `0XL–4XL` size group. Price `$19.18/spa-dom` was correct and remains unchanged.
- Root cause for color: `findOptionContainer()` could choose the active `.bs-color__item ... active` itself, but `getSelectedWithin()` and swatch-image capture inspected descendants only, excluding the selected container. The swatch also has no readable label; SHEIN's authoritative changing name is the exact `.main-sales-attr-container` text `لون: الأسود`. Selected candidate hosts now win equal container scores, the container itself participates in selection/image reads, and the bounded exact heading supplies the color name when no product-options drawer is active.
- Inline-size behavior is intentionally fail-closed: if no `انقر للشراء` drawer entry exists and the visible/fallback size group is unselected, `sheinRevealSizeOptions()` scrolls that exact group to the viewport center and focuses its first enabled control without clicking or selecting it. Add remains blocked until the customer selects a size. Product drawer entries are clicked directly so event delegation cannot be redirected to an unrelated ancestor.
- Device-shaped full-script Playwright reproduces the old empty color/image and passes after: initial `الأسود + black.jpg`; changed swatch `الأحمر + red.jpg`; first add scrolls to `y=773`, focuses the size group, and posts no add; selecting `2XL` sends `الأحمر | 2XL | red.jpg | $19.18`. v86.41/v86.40/v86.39/v86.38 regressions still pass, including shipping blocking, options reopening, `بيج / كبير`, incomplete blocking, `أزرق/L`, `رمادي / كبير`, and `M / 1PC`.
- Freeze guard, production/performance build, Android/iOS sync, Gradle debug, APK metadata, GitHub/Xcode build, and IPA inspection pass. Budgets: JS raw `1,199,228/1,200,000`, JS gzip `358,111/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `549,385/550,000`.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.42-shein-image-swatch-color-inline-size-focus-debug.apk`; SHA-256 `8E60BF4C8C637FC9A723D13D892CCB6BC2FB81A3E28B1B68D720A439DF5157D7`; size `11,124,794` bytes; metadata confirms `com.otlobli.app`, `86.42/902`, release/color-heading/size-focus markers.
- Code commit is `cbeada7` on `claude/ios6-cover-fix`; GitHub/Xcode run `30698764256` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.42-iphone16-unsigned.ipa`; SHA-256 `38B8E53920EF8ACCA99C985E3AC81A510F5DF55F935A6A04384732C489D77E5F`; size `7,068,614` bytes. Inspection confirms `com.otlobli.app`, `86.42/902`, iOS 15 minimum, only `otlobli`, color/size/shipping/drawer and all native-recompose markers, with no app-root signature or provisioning profile.
- Real-iPhone acceptance is not yet performed for v86.42. On the exact dress, switch through several colors and confirm diagnostic/cart name plus color image; tap add with no size and confirm navigation without an add; choose each of two sizes and verify the cart. Retest `انقر للشراء`, the shipping guard, five background/resume cycles, and a cold launch. Automatic store-region switching remains a separate open defect.

## v86.38 SHEIN externally-rendered combined size (2026-08-01)

- Current marker is `2026.08.01-v86.38-shein-confirmed-external-size`; Android/iOS are `898/86.38`. The user rejected v86.37 on the real iPhone with the same missing `كبير` symptom; price remains confirmed correct and unchanged.
- Root cause boundary corrected: the exact `لون / مقاس — رمادي / كبير` summary can be outside the `goods-size` drawer container. v86.37 queried titles only inside that container, so its ancestor walk never started. The real diagnostic showed both nodes globally but did not establish containment.
- v86.38 queries only SHEIN's exact size-title selector across the document, examines at most four headings and three ancestors, and accepts `كبير` only when an actually selected element inside the detected options container has an exact/prefix match. A stale external summary therefore cannot authorize an add.
- Full-script Playwright with the summary outside the container reproduces v86.37 (`size/key/payload=رمادي`, price `14.43`) and passes after the fix with `رمادي / كبير`. A negative fixture with an external summary but no selected `كبير` now returns an empty size and posts no add. Normal `L` and legacy `M / 1PC` still pass; price remains `14.43/selected-mutation`.
- Freeze guard, production/performance build, Android/iOS sync, Gradle debug, and APK metadata pass. Budgets: JS raw `1,199,542/1,200,000`, JS gzip `359,214/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `549,712/550,000`.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.38-shein-confirmed-external-size-debug.apk`; SHA-256 `86B530AAAD1C98A680DA5CE644A8BFEAE5E80DDCA28E2C4A294EAE972CE615B1`; size `11,125,830` bytes; metadata confirms `com.otlobli.app`, `86.38/898`. No ADB device was connected.
- Primary commit is `e3b82b1` on `claude/ios6-cover-fix`; GitHub/Xcode run `30695599782` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.38-iphone16-unsigned.ipa`; SHA-256 `E6423E8070530710A4876E5080D2ECC2CB0A2060A112A57DF346E85A648C7C67`; size `7,069,811` bytes. Inspection confirms `com.otlobli.app`, `86.38/898`, iOS 15 minimum, only the `otlobli` URL scheme, external-summary confirmation/fail-closed/price/navigation/range/native-recompose markers, and no app `_CodeSignature` or provisioning profile.
- Real iPhone acceptance is not yet performed for v86.38. Require `مختار: [رمادي / كبير]`, the full selection key, last-add size, and cart line before calling the issue resolved.

## v86.37 SHEIN nested combined-size summary (2026-08-01)

- Current marker is `2026.08.01-v86.37-shein-nested-combined-size`; Android/iOS are `897/86.37`. The user rejected v86.36 on the real iPhone: the diagnostic and last add still reported `صينية من الخشب الصلب|رمادي`, while the same DOM visibly reported `لون / مقاس` then `رمادي / كبير`.
- Root cause: v86.36 handled a direct sibling or direct parent only. The real `goods-detail__top-other` markup wraps the heading and value separately, so the heading's direct parent contains only `لون / مقاس`; the combined row exists higher in the already-detected size container.
- The completion now walks at most three ancestors from the exact `.goods-size__title`, never beyond the detected size container. It accepts only a row shorter than 60 characters that begins with the exact combined heading and whose first summary segment exactly equals the selected descendant. It adds no page scan, timer, observer, reload, or price change.
- Full-script Playwright with the nested wrappers reproduced v86.36 exactly (`size/key/payload=رمادي`, price `14.43`) and passes after the fix with all three equal to `رمادي / كبير`; normal `L` and legacy `M / 1PC` still pass. Price remains `14.43/selected-mutation`.
- Freeze guard, production/performance build, Android/iOS sync, Gradle debug, and APK metadata pass. Budgets: JS raw `1,199,257/1,200,000`, JS gzip `359,246/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `549,430/550,000`.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.37-shein-nested-combined-size-debug.apk`; SHA-256 `C0A98346368A80111F69C0C61FE0532530190F9D286C3E7D3CE27E366DD174A1`; size `11,125,854` bytes; metadata confirms `com.otlobli.app`, `86.37/897`. No ADB device was connected for physical acceptance.
- Primary commit is `355f89f` on `claude/ios6-cover-fix`; GitHub/Xcode run `30695161552` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.37-iphone16-unsigned.ipa`; SHA-256 `1E7666B2533859FE8F544BFD2EF65AC62A7A59B640DFFEB658CE786FA3104DF8`; size `7,069,856` bytes. Inspection confirms `com.otlobli.app`, `86.37/897`, iOS 15 minimum, only the `otlobli` URL scheme, nested-size/selected-price/navigation/range/native-recompose markers, and no app `_CodeSignature` or provisioning profile.
- Real iPhone acceptance is not yet performed for v86.37. The exact diagnostic must show `مفتاح: [صينية من الخشب الصلب|رمادي / كبير]`, `مختار: [رمادي / كبير]`, and the last add/cart line must include `كبير`.

## v86.36 SHEIN combined color/size capture (2026-08-01)

- Current marker is `2026.08.01-v86.36-shein-combined-color-size`; Android/iOS are `896/86.36`. Price capture is intentionally unchanged because the user confirmed it is fixed.
- The photographed product exposes one size container whose first selected descendant is `رمادي`, while its authoritative adjacent `لون / مقاس` summary is `رمادي / كبير`. The old generic getter stopped at that first descendant, so the cart received the color correctly but lost `كبير`.
- `completeSelectedCompoundSize()` now accepts a combined summary only inside the already-detected size container, only for the exact headings `لون / مقاس`, `color / size`, or `colour / size`, and only when the summary's first segment exactly equals the selected descendant. It then returns the full value (`رمادي / كبير`). The existing `M / 1PC`/`CP1` exception and normal single sizes remain unchanged.
- Full-script Playwright reproduced the defect before the change (`size=رمادي`) and passes after it with diagnostic/payload/key all equal to `رمادي / كبير`; normal `L` and legacy `M / 1PC` also pass. The captured price stays `14.43` with source `selected-mutation`.
- Freeze guard, production build, performance budget, Android/iOS sync, Android Gradle debug, and APK metadata pass. Budgets: JS raw `1,199,595/1,200,000`, JS gzip `359,371/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `549,769/550,000`.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.36-shein-combined-color-size-debug.apk`; SHA-256 `6DC49B83FD3E46281528A5C4499588CC2F9857318A47C4E4C534F8AF6E2F8143`; size `11,125,978` bytes; metadata confirms `com.otlobli.app`, `86.36/896`. No ADB device was connected for physical acceptance.
- Primary commit is `6cc1384` on `claude/ios6-cover-fix`; GitHub/Xcode run `30694579185` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.36-iphone16-unsigned.ipa`; SHA-256 `07D48915EAD3B6DA2B7243F9E16FB3058AD2195732C841393998B2270632B251`; size `7,069,997` bytes. Inspection confirms `com.otlobli.app`, `86.36/896`, iOS 15 minimum, only the `otlobli` URL scheme, combined-size/selected-price/navigation/native-recompose markers, and no app `_CodeSignature` or provisioning profile.
- Real iPhone acceptance is still required on the exact product: select the photographed model, then `رمادي / كبير`, add it, and confirm the cart line contains both segments. Also retain the mandatory five background/resume cycles and cold launch; browser/build evidence alone is not device acceptance.

## v86.35 SHEIN product-options drawer navigation (2026-08-01)

- Current marker is `2026.08.01-v86.35-shein-options-drawer-nav`; Android/iOS are `895/86.35`. The selected-price and SKU capture paths from v86.33/v86.34 are intentionally unchanged.
- Root cause: `otlobliNavShouldYield()` disabled `pointer-events` for the entire visible Otlobli bar whenever a full-screen SHEIN product-options backdrop geometrically overlapped it. It now yields only when `otlobliNavIsActuallyCovered()` proves SHEIN is actually painted over the bar.
- A document-start `touchend`/click bridge routes tabs to native before SHEIN's modal capture listener can cancel the synthetic click. A bounded `450ms` timestamp deduplicates touch + click; no timer, polling, reload, WebView rebuild, price, region, or SKU logic was added.
- Playwright at `430×932` reproduced the old geometry result, kept nav `pointer-events:auto`, routed `cart → orders → profile` exactly once each, and kept the drawer's `M` option interactive. Screenshot: `output/playwright/v86.35-options-nav.png` (untracked test evidence).
- `verify:shein-freeze-guard`, production build, performance budget, Android/iOS sync, Android Gradle debug, APK metadata, and `git diff --check` pass. Budgets: JS raw `1,198,537/1,200,000`, JS gzip `359,122/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `548,712/550,000`.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.35-shein-options-drawer-nav-debug.apk`; SHA-256 `336074AE7BD25DC59079D51ADD177371EBB63EBBF0A850BFB38FF191E2F31D6C`; size `11,541,524` bytes; metadata confirms `com.otlobli.app`, `86.35/895`. No ADB device or present Windows iPhone device was available for physical acceptance.
- Primary code commit is `4768893` on `claude/ios6-cover-fix`. GitHub/Xcode run `30693899285` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.35-iphone16-unsigned.ipa`; SHA-256 `22B61C8F6204433A5E4F30E8FFABDC43F11D6CC61F83A5C48DAD771387AAF00B`; size `7,070,161` bytes. Inspection confirms `com.otlobli.app`, `86.35/895`, iOS 15 minimum, only the `otlobli` URL scheme, the nav-touch/price/SKU markers, and all native recompose/foreground markers. The app has no `_CodeSignature` or provisioning profile.
- Real iPhone acceptance is not yet performed; it must cover first-tap navigation with the options drawer open, option selection/add, five resume cycles, and cold launch. The IPA is unsigned and must be signed before normal installation.

## v86.29 SHEIN selected-price race guard (2026-07-30)

- Current marker is `2026.07.30-v86.29-shein-price-race-guard`; Android/iOS are `889/86.29`; auth bypass remains off. The user's report that the defect appears and disappears led to a deterministic timing reproduction rather than another selector change.
- The confirmed race was in `addToCartFlow()`: SHEIN was considered complete as soon as title/image/color existed, so an immediate add could finalize from static JSON before the option-price observer received SHEIN's delayed DOM update. In a full-script browser fixture, choosing `L`, scheduling `$1.00 -> $9.99` after `700ms`, and immediately adding posted `$1.00` from `json` in `42ms`.
- The option tracker now records the exact pre-click price. While its bounded observer is active, add completion waits only if no current-key/path capture exists or the captured amount still equals the pre-click amount. A genuinely changed price completes immediately when its mutation arrives; a same-price option is released when the existing `1.75s` observer window ends. The fixed fixture posted `$9.99` from `selected-mutation` in `747ms`; the unchanged `$1.00` case completed in `1,835ms` without a loop or hang.
- Exact painted PDP price roots are now preferred on the first product as well as later SPA routes, before document-static JSON/meta. SHEIN completion also requires a positive price, and the final fail-safe refuses title/image/price-incomplete payloads. Existing diagnostics now include `before` and bounded `priceWaits`.
- Playwright passes the timing-race pair, immediate selected mutations (`S=$1`, `M=$2`, `L=$9.99`), same-session SPA `$4.50 -> $8.25`, no-selection block, `L`, `M / CP1`, `M / 1PC`, `L / 1PC`, virtualized Saudi-country scrolling, and the already-signed region fast path.
- No persistent polling, WebView reload/rebuild, React state, region logic, or native lifecycle timing was added. `otlobliForceRecompose`, `appDidBecomeActive`, `appWillEnterForeground`, burst recompose, Android resume defense, signed-address add guard, bottom bar, and unchanged-store comparison remain intact.
- `verify:shein-freeze-guard`, production build, performance budget, Android/iOS sync, Android Gradle debug, APK metadata, and `git diff --check` pass. Budgets: JS raw `1,183,698/1,200,000`, JS gzip `354,429/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `549,333/550,000`.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.29-shein-price-race-guard-debug.apk`; SHA-256 `922BA65E3ADFDDC535205E1EA0C207C173BCEEA5BCB26A0F7557079BAD840301`; size `11,120,026` bytes; metadata confirms `com.otlobli.app`, `86.29/889`.
- Primary code commit is `216ea26`; matching iOS code commit is `29e8e08` on `codex/ios-v86-4`. GitHub/Xcode run `30547309099` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.29-iphone16-unsigned.ipa`; SHA-256 `308B66D6A2F8D9B7D4DE7CD1D2741FB867444A9100AD07CB8C6EED20450CB617`; size `7,064,834` bytes. Inspection confirms `com.otlobli.app`, `86.29/889`, only the `otlobli` URL scheme, the release/price-pending/country-scroll markers, `otlobliForceRecompose` and `appDidBecomeActive`, no old live-scanner/stable-read markers, no app `_CodeSignature`, and no provisioning profile. Real iPhone acceptance remains mandatory for immediate add after changing a higher-priced option, same-price options, several products without restarting, clean region setup, five resume cycles, and cold launch.

## v86.28 SHEIN SPA price + country-list scrolling (2026-07-30)

- Current marker is `2026.07.30-v86.28-shein-spa-price-country-scroll`; Android/iOS are `888/86.28`; auth bypass remains off. The decisive real-device clue was that several products reused one price during the same SHEIN session, but prices became correct after closing and reopening the app. This proved a document-lifetime SPA cache problem rather than a general price parser failure.
- A full-script browser reproduction kept product A JSON-LD/meta at `$4.50`, navigated with `history.pushState` to product B, and painted `$8.25`. Before the fix capture was `$4.50`, title `First SPA product`, source `json`; after the fix it is `$8.25`, title `Second SPA product`, source `spa-dom`. On a route different from the script's initial pathname, capture now prefers the exact live PDP title/image and a bounded scan of at most eight exact PDP price roots. The existing selected-option mutation value remains first priority and is still validated by selection key and pathname.
- The region failure was separately reproduced with a verified shipping drawer whose countries were generic `div.country-row` elements and Saudi Arabia existed only after scrolling the inner virtualized list. Before the fix the normal selector saw `visibleOptions:0` and neither list nor Saudi moved. The fallback now recognizes exact known country labels only inside the verified drawer, selects the smallest real scroll container across all rows, scrolls toward the configured country, and retries. The fixture moved the inner list from `0` to `180`, rendered/clicked Saudi Arabia, and received the signed Saudi `addressCookie`.
- New bounded diagnostics are `country-row-fallback`, `country-list-scroll`, and `selected-sku-price-capture.spaRoute`. No global click guessing, reload/setUrl loop, persistent observer, React/WebView rebuild, or native recompose retiming was added. The signed-address add guard, bottom Otlobli bar, unchanged-store `JSON.stringify` comparison, `otlobliForceRecompose`, foreground burst, and Android resume defense remain intact.
- Playwright passes the SPA stale-price reproduction, virtualized generic-country reproduction, signed-region fast path, selected mutation sequence (`S=$1`, `M=$2`, `L=$9.99`), no-selection block, `L`, `M / CP1`, `M / 1PC`, and `L / 1PC`. The obsolete v86.24 live-scanner fixture still expects behavior deliberately removed in v86.26 and is not counted as a current passing test.
- `verify:shein-freeze-guard`, production build, performance budget, Android/iOS sync, Android Gradle debug, APK metadata, and `git diff --check` pass. Budgets: JS raw `1,183,108/1,200,000`, JS gzip `354,358/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `548,739/550,000`.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.28-shein-spa-price-country-scroll-debug.apk`; SHA-256 `0677A67EB737BFCD59FE95ACD378D59C5E446598F78CB3C557A45F319EB35D6B`; size `11,119,906` bytes; metadata confirms `com.otlobli.app`, `86.28/888`.
- Primary code commit is `25e2b4d`; matching iOS code commit is `39ba8ef` on `codex/ios-v86-4`. GitHub/Xcode run `30540335090` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.28-iphone16-unsigned.ipa`; SHA-256 `CEF266C7E517882EC8072FFAD59B061134B624EEAC56D40DA9A11D014A9027AC`; size `7,065,174` bytes. Inspection confirms `com.otlobli.app`, `86.28/888`, only the `otlobli` URL scheme, the release/SPA-price/country-scroll markers, `otlobliForceRecompose` and `appDidBecomeActive` in the native executable, no old live-scanner/stable-read markers, no app `_CodeSignature`, and no provisioning profile. Real iPhone acceptance remains mandatory for same-session multi-product prices, immediate color/size changes, clean-install region setup, Admin-country changes, five background/resume cycles, and cold launch.

## v86.27 SHEIN selected-SKU mutation price (2026-07-30)

- Current marker is `2026.07.30-v86.27-shein-selected-sku-mutation-price`; Android/iOS are `887/86.27`; auth bypass remains off. The user rejected v86.26 on the real iPhone: restoring the v85.8.55 getter still captured the entry SKU price after choosing a more expensive color/size.
- The confirmed root cause is that current SHEIN keeps JSON-LD and `product:price:amount` at the entry price while changing the selected SKU price inside the live PDP after the option click. The old baseline therefore cannot identify the new amount by itself.
- v86.27 listens only to real clicks inside the detected color/size containers, then observes only changed/mounted PDP price roots for a bounded `1.75s`. It immediately stores the visible non-crossed USD price with the exact current `color|size` key and product pathname. `getPrice()` accepts this value only when that key/path still match; otherwise it retains the v85.8.55 JSON -> meta -> legacy DOM fallback. The observer disconnects and adds no polling, WebView reload, React state, or region rebuild.
- The add diagnostic stage `selected-sku-price-capture` reports the captured source/value and tracked/current selection keys through the existing bounded WebView diagnostic bridge. The narrow `M / CP1` completion, no-selection block, signed `addressCookie` guard, bottom navigation, region repair, unchanged-store comparison, and all native recompose timing remain unchanged.
- Full-script Playwright held JSON-LD/meta at `$1` while the PDP changed on click: initial `S=$1` used `json`, immediate `M=$2` and `L=$9.99` used `selected-mutation`. A separate suite passed no-selection blocking, `L`, `M / CP1`, `M / 1PC`, and `L / 1PC`.
- `verify:shein-freeze-guard`, production build, performance budget, Android/iOS sync, Android Gradle debug, APK metadata, and `git diff --check` pass. Budgets: JS raw `1,184,302/1,200,000`, JS gzip `355,462/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `549,995/550,000`.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.27-shein-selected-sku-mutation-price-debug.apk`; SHA-256 `2905A5D599DC888D1B0AC3D4952653B3E406040EBEB17B808E307B60F9B1F3DF`; size `11,133,402` bytes; metadata confirms `com.otlobli.app`, `86.27/887`.
- Primary code commit is `4b0b99d`; matching iOS code commit is `237db18` on `codex/ios-v86-4`. GitHub/Xcode run `30538230343` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.27-iphone16-unsigned.ipa`; SHA-256 `97E8F84E5ACE19766B6E4A54AA2CB3C7C1514879271E82E9C9B32AFC060EEF30`; size `7,065,900` bytes. Inspection confirms `com.otlobli.app`, `86.27/887`, only the `otlobli` URL scheme, the selected-mutation/diagnostic/native-recompose markers, no old live-scanner/stable-read markers, no app `_CodeSignature`, and no provisioning profile. Windows detects the connected Apple iPhone, but the host cannot install an unsigned IPA. Real iPhone acceptance remains mandatory for the photographed premium SKU, rapid size/color changes, clean region setup, five resume cycles, and cold launch.

## v86.26 SHEIN v85.8.55 capture baseline (2026-07-30)

- Current marker is `2026.07.30-v86.26-shein-v855-capture-baseline`; Android/iOS are `886/86.26`; auth bypass remains off. The user rejected v86.25 on the real iPhone because selected color/size prices still captured the entry price and the loading state remained slower than the known-good build.
- The exact requested v85.8.55 GitHub artifact was resolved and downloaded rather than inferred: run `29657616560`, commit `eb7b0ca04b012519f0e4191ebf13c392f9b56367`, IPA SHA-256 `52ED888B77AF294970B6CC7E19557131CDC848B3A29D79E4C40B3D3E93FF1F16`. Its production bundle uses JSON-LD offer first, then `product:price:amount`, then the legacy PDP DOM selector. It has no live price-root scanner, stable-read gate, or add-time price diagnostic.
- v86.26 restores that built v85.8.55 title/price/add-completion path exactly. It removes `sheinLiveSkuPrice()`, `sheinPdpTitleElement()`, two-stable-price waits, and the SHEIN-specific incomplete-payload delay. The narrow v86.20 `completeSelectedCompoundSize()` is deliberately retained so the original `M / CP1` requirement is not regressed. Region signing/add guard, bottom navigation, SPA repair, unchanged-region comparison, and native foreground/recompose code were not changed.
- Full injected-script Playwright passed after changing the fixture from `$11.15` to `$17.19`: the posted product was `$17.19` in `314ms`. The option suite also passed: no-selection blocked, `L`, `M / CP1`, `M / 1PC`, and `L / 1PC` were exact.
- `verify:shein-freeze-guard`, production build, performance budget, Android/iOS sync, Android Gradle debug, APK metadata, and `git diff --check` pass. Budgets: JS raw `1,179,559/1,200,000`, JS gzip `354,536/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `545,277/550,000`.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.26-shein-v855-capture-baseline-debug.apk`; SHA-256 `F3F20A13A6457315B797E60CBD6CC0F4D793EE3A0BDC83D92F930ADEE53820D8`; size `11,119,826` bytes; metadata confirms `com.otlobli.app`, `86.26/886`.
- Primary code commit is `08bc726`; matching iOS commit is `7196f98` on `codex/ios-v86-4`. GitHub/Xcode run `30536477640` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.26-iphone16-unsigned.ipa`; SHA-256 `7BB535820B4F2768F0874B4C7CF2FE0C46A002A4B6FD66F1E139A2505D289A64`; size `7,064,897` bytes. Inspection confirms `com.otlobli.app`, `86.26/886`, only the `otlobli` URL scheme, the baseline/compound/native-recompose markers, no app `_CodeSignature`, and no provisioning profile.
- Windows detects the connected Apple iPhone (`00008140001E6D581E11801C`), but the machine has no Xcode/`ios-deploy`/libimobiledevice toolchain and the IPA is unsigned, so it was not installed from this host. Real iPhone acceptance is still mandatory for the photographed premium SKU, repeated size/color changes, clean region setup, five background/resume cycles, and cold launch.

## v86.25 SHEIN priority PDP-title price boundary (2026-07-30)

- Current marker is `2026.07.30-v86.25-shein-priority-pdp-title-price`; Android/iOS are `885/86.25`; auth bypass remains off.
- The new screenshot of product `418157946` showed a readable `$14.26` PDP, selected compound option, and the Otlobli `تعذّر قراءة بيانات المنتج` fail-safe. The concrete cause was selector priority: `document.querySelector('h1, ... [class*="product-name"] ...')` returns the first matching node in document order, not the first selector. When SHEIN mounted a similar-products drawer name before the PDP price/title, that recommendation name became the boundary and all real PDP price roots were rejected.
- `sheinPdpTitleElement()` now deliberately prioritizes the exact `.product-intro__head-name`, then `h1`, then the broad legacy fallbacks. Both title capture and `sheinLiveSkuPrice()` use the same authoritative element. The bounded price-root scan, later equal-score active-SKU rule, two stable reads, signed-address guard, option extraction, and fail-safe remain unchanged.
- `price-capture` now runs before the incomplete-payload return and includes `title`/`image` booleans. An unreadable add still posts no product, but device evidence can now distinguish missing price, title, or image instead of producing only the toast.
- The full injected script passed a real Playwright regression with a recommendation name before the PDP, stale `$11.15`, active `$14.26`, and later recommendation `$2.23`: one product was posted at `$14.26`, source `live`, roots `11.15@40,14.26@40`, `title:true`, `image:true`. A second run removed both PDP prices: zero add messages, the Arabic fail-safe toast, and `captured:0/source:missing/title:true/image:true`.
- `verify:shein-freeze-guard`, production build/performance budget, Android/iOS sync, Android Gradle debug build, and `git diff --check` pass. Budgets: JS raw `1,184,099/1,200,000`, JS gzip `355,715/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `549,828/550,000`.
- v86.25/885 was installed over v86.24 on the connected Galaxy Note8 without clearing data. The app launched and stayed focused with no fatal/ANR signal. Live SHEIN product acceptance was not possible because the phone had no SHEIN/VPN route; its proxy remained `null` with no ADB reverse/forward left behind.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.25-shein-priority-pdp-title-price-debug.apk`; SHA-256 `9ADC6749748B59B8E94D7949D58847B5704EB2FFFABD88D14CD754A3849BCDD4`; size `11,121,254` bytes.
- Primary code commit is `46e4dae`; matching iOS commit is `7adff45` on `codex/ios-v86-4`. GitHub/Xcode run `30533726236` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.25-iphone16-unsigned.ipa`; SHA-256 `162124F26DA00229276FA0CBC80A7F9E51EBCB1351A05F05A4C2336B1E63BFF3`; size `7,066,587` bytes. Inspection confirms `com.otlobli.app`, `86.25/885`, only the `otlobli` URL scheme, the release/PDP-title/native-recompose markers, no app `_CodeSignature`, and no provisioning profile. Real iPhone 16 acceptance remains mandatory for the exact product, rapid SKU changes, five resume cycles, and cold launch.

## v86.24 SHEIN PDP-only price + signed-region fast path (2026-07-30)

- Current marker is `2026.07.30-v86.24-shein-pdp-price-signed-fast-path`; Android/iOS are `884/86.24`; auth bypass remains off.
- Real Galaxy Note8 diagnostics reproduced both causes. A fully signed Saudi `addressCookie` still entered `repair-started` and `product-bootstrap-reload` on the next SPA product because the reload decision looked only at missing URL parameters. The pictured product `418157946` also opened a `منتجات مشابهة` drawer with `$2.66/$2.40`; the generic/later price roots could outrank the actual selected PDP price.
- Product bootstrap reload is now allowed only while `sheinSignedSaudiAddressReady()` is false. A signed route immediately reports `prime-already-ready`, mounts no region veil, and does not reload. Native readiness messages are deduplicated by `type + pathname`, so the same ready state is posted once per route instead of every maintenance tick.
- `sheinLiveSkuPrice()` now scans only bounded PDP price roots before the actual product title, removes generic `[data-testid*="price"]` roots, still rejects hidden/old/crossed values, and preserves the later equal-score root for a newly selected SPA SKU. Meta/JSON remain fallbacks and variant extraction was not broadened.
- Playwright passes the exact stale PDP `$11.15` + active PDP `$14.26` + later recommendation `$2.23` fixture: capture is `$14.26`, root trace is `11.15@40,14.26@40`, the recommendation is absent, signed product navigation stays alive with no veil/reload, and readiness count is one. Repeated `S=$1`, `M=$2`, `L=$9.99`, delayed `$17.19`, JSON fallback, no-selection, `M / CP1`, `M / 1PC`, and changed `L / 1PC` suites also pass.
- Final physical Android test installed `86.24/884`. On a real product, diagnostics showed `signedReady:true`, `prime-already-ready`, one `sheinSaudiReady`, and zero `product-bootstrap-reload` over 18 seconds. The exact pictured product exposed the misleading similar-products drawer; its currently selected SKU was sold out, and the add guard correctly sent no incomplete cart payload. During the attached DevTools stress session, Android 9's Chrome renderer crashed once (`crashpad`, render process crash); this is recorded as a device limitation, not counted as price/add acceptance. The temporary proxy/reverse/DevTools forwarding was removed and the phone proxy restored to `null`.
- `verify:shein-freeze-guard`, production build/performance budget, Android/iOS sync, Android Gradle debug build, and `git diff --check` pass. Budgets: JS raw `1,184,007/1,200,000`, JS gzip `355,675/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `549,737/550,000`.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.24-shein-pdp-price-signed-fast-path-debug.apk`; SHA-256 `C4A988477C879882CCEA43103D7BA276E070507E0D2CA79F028587ECE1CA95CC`; size `11,532,430` bytes.
- Primary commits are `608842d` + `f4ce902`; matching iOS commits are `9597fc9` + `0cbf6dc` on `codex/ios-v86-4`. GitHub/Xcode run `30530246600` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.24-iphone16-unsigned.ipa`; SHA-256 `103CB26E8EEB6BC9876B4182E90C0A5CB4D04DA84D9DCAA9D0F4F05118BF7950`; size `7,066,113` bytes. Inspection confirms `com.otlobli.app`, `86.24/884`, only `otlobli`, the release/PDP-boundary/signed-fast-path/readiness-dedupe/native-recompose markers, and no provisioning profile or code-signature directory. Real iPhone 16 acceptance remains pending for the premium color/size price, clean-install region signing, Admin-country change, five background/resume cycles, and cold launch.

## v86.23 SHEIN active SKU price-root selection (2026-07-30)

- Current marker is `2026.07.30-v86.23-shein-active-sku-price-root`; Android/iOS are `883/86.23`; auth bypass remains off.
- The user corrected the known-good reference to GitHub Actions run `#427`. It was resolved exactly to run `30085191333`, commit `b22f5d1`, and the downloaded `v85.8.91` IPA (SHA-256 `07E6AFBC0B508DDB34306BACA3CF1615FD8B91CBF62FE42058F37FDEDF0FA165`). Its built script was inspected, not guessed: it used JSON-LD first, then meta, then a generic DOM fallback and had no later live-price scanner.
- The concrete regression in the new scanner was an early return from the first painted `.product-intro__head-price`/`.product-price` root. SHEIN can retain the entry SKU root while mounting the newly selected SKU root, so `$11.15` won before `$17.19` was inspected. The intermediate v86.22 candidate also preferred static meta before the live root and was superseded before device handoff.
- `sheinLiveSkuPrice()` now compares every bounded candidate root, rejects hidden ancestor branches and crossed/old/discount values, and lets the later equal-score root win as the active SPA SKU. The live painted price is authoritative; meta and JSON-LD are fallbacks only. The existing two-stable-read add retry remains unchanged.
- The add-time diagnostic now reports `captured/source/meta/live/json/roots/color/size`. `roots` is a bounded trace such as `11.15@40,17.19@40`; it runs only during existing add retries and adds no observer, permanent cache, timer, React render, reload, or WebView rebuild.
- Playwright reproduces two simultaneously mounted price roots across repeated adds: `S=$1`, `M=$2`, `L=$9.99`, with traces `1@40,1@40`, `1@40,2@40`, and `1@40,9.99@40`. The screenshot `$11.15 -> $17.19`, delayed update, JSON-only fallback, no-selection block, normal `L`, `M / CP1`, `M / 1PC`, and changed `L / 1PC` suites also pass.
- `verify:shein-freeze-guard`, production build/performance budget, Android/iOS sync, Android Gradle debug build, and `git diff --check` pass. Budgets: JS raw `1,183,951/1,200,000`, JS gzip `355,665/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `549,691/550,000`.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.23-shein-active-sku-price-root-debug.apk`; SHA-256 `B0C16C35FEB7F5849ECB7A7C46EE3E4AEAA5E124C4A6730B18EE90F654FE2A58`; size `11,121,746` bytes. ADB listed no connected device.
- Primary commits are `80d9d1a` + `a390f5e`; matching iOS commits are `1c960e1` + `328a563` on `codex/ios-v86-4`. Final GitHub/Xcode run `30522960782` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.23-iphone16-unsigned.ipa`; SHA-256 `B6BC93BC933DD5F9CB53F05E336EEA0D56C3BDDA8F490CA0C5445F6AF23A6447`; size `7,066,532` bytes. Inspection confirms `com.otlobli.app`, `86.23/883`, only `otlobli`, the active-root/price-trace/native-recompose markers, and no provisioning/signature. Real iPhone acceptance remains pending for the pictured premium SKU, rapid SKU changes, signed region, five resume cycles, and cold launch.

## v86.21 SHEIN live selected-SKU price capture (2026-07-30)

- Current marker is `2026.07.30-v86.21-shein-live-sku-price-fix`; Android/iOS are `881/86.21`; auth bypass remains off.
- The screenshot pair proves the price root cause: the selected `أخضر عسكري · L` variant visibly cost `$17.19`, while Otlobli captured `$11.15`. `getPrice()` returned the product's server-rendered JSON-LD/default offer before reading the live SPA price for the selected color.
- SHEIN capture now reads only bounded visible nodes inside the primary PDP price roots (`.product-intro__head-price`/`.product-price`), rejects discount percentages and crossed/old/original/retail prices, and prefers the current rendered SKU amount. JSON-LD/meta remain fallbacks for templates with no rendered price. The generic whole-page `[class*="price"]` fallback was removed.
- Add capture waits for two equal price reads after active touch/scroll ends. This lets SHEIN finish an asynchronous color-price update before posting to React. Zero/unreadable SHEIN prices fail safely; option extraction, v86.20's narrow compound completion, signed-region guard, region automation, and native recompose timing are unchanged.
- Playwright reproduces JSON-LD `$11.15` plus old `$21.84`, `-21%`, and live `$17.19`; capture posts `$17.19 · L`. A delayed `$11.15 → $17.19` update also posts `$17.19`. JSON-only `$3.49`, `M / CP1`, no-selection blocking, ordinary `L`, separate `M / 1PC`, and changed `L / 1PC` regressions pass.
- `verify:shein-freeze-guard`, production build/performance budget, Android/iOS sync, Android Gradle debug build, GitHub/Xcode, IPA inspection, and `git diff --check` pass. Budgets: JS raw `1,182,728/1,200,000`, JS gzip `355,467/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `548,490/550,000`.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.21-shein-live-sku-price-fix-debug.apk`; SHA-256 `4A0A81EB64FCFE88A0BB633A8D5C5044D54E9FD60C4BF94384F3BB78581BFF1E`; size `11,120,882` bytes. ADB listed no connected device.
- Primary code commit is `9efab6b`; matching iOS commit is `cf7a442` on `codex/ios-v86-4`; GitHub run `30519999113` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.21-iphone16-unsigned.ipa`; SHA-256 `F406AD5B7901478E725A14F988B7CBEDD1558D9832D951235CEDACE43277B966`; size `7,066,319` bytes. Inspection confirms `com.otlobli.app`, `86.21/881`, only `otlobli`, the release/live-price/stability/recompose markers, and no provisioning/signature. Real iPhone acceptance remains pending for the pictured product, immediate variant changes, region signing, five resume cycles, and cold launch.

## v86.20 SHEIN variant regression rollback + narrow compound completion (2026-07-30)

- Current marker is `2026.07.30-v86.20-shein-variant-regression-fix`; Android/iOS are `880/86.20`; auth bypass remains off.
- Real-device feedback rejected v86.19's broad `sheinQuantitySizeSummary()` path. It treated any control near `الكمية / مقاس` as a confirmed selection, which could add without a real size choice, keep stale `M` after choosing `L`, and make the captured price appear tied to the wrong variant.
- v86.20 restores the complete v86.18 extraction and price flow for ordinary products. The only new path runs when the existing selected value is an exact piece-count token (`1PC`/`CP1`) and an actual selected size exists in the same option container; it then preserves the same control's `M / CP1` text or joins the two confirmed selected values. It never infers from a heading or nearby unselected control and stores no variant cache.
- Playwright real-browser regression cases pass: no selection posts nothing; an ordinary selected `L` stays `L`; nested compound selection captures `M / CP1`; separate selected piece/size captures `M / 1PC`; changing the selected size to `L` captures `L / 1PC`. Each successful fixture retained the unchanged baseline price `$3.49` and signed `addressCookie`.
- `verify:shein-freeze-guard`, production build/performance budget, Android/iOS sync, Android Gradle debug build, and `git diff --check` pass. Budgets: JS raw `1,180,447/1,200,000`, JS gzip `354,917/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `546,214/550,000`.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.20-shein-variant-regression-fix-debug.apk`; SHA-256 `EE74578B350CF53BB89119991235E3A748790B2EDEC442C4EADC1961DDF9E81F`; size `11,120,174` bytes. ADB listed no connected device.
- Matching iOS source is pushed on `codex/ios-v86-4` at `eaf47bc`; GitHub/Xcode run `30497128620` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.20-iphone16-unsigned.ipa`; SHA-256 `9D5CCB2976A5B63C2CA0A55287D4F89CCF8318B2F2FE33EC02D4DDE749223AEB`; size `7,065,712` bytes.
- IPA inspection confirms `com.otlobli.app`, `86.20/880`, only the `otlobli` URL scheme, the v86.20/narrow-completion/recompose markers, and no provisioning profile or code-signature directory. Real iPhone 16 acceptance remains pending: no-selection block, ordinary M→L, the three-group product, variant price, five resume cycles, and a cold launch. Do not claim the regression fixed on device from fixtures/builds alone.

## v86.19 new-phone auth + exact SHEIN variant + tracking layout (2026-07-30)

- Current marker is `2026.07.30-v86.19-auth-variant-tracking-fix`; Android/iOS are `879/86.19`; auth bypass remains off.
- The new-number OTP failure was not a wrong-code bug. Production had `ensure_customer(text,...)` but `validate_customer_full_name(text)` was absent because it existed only in `supabase/schema.sql`, never in a migration. Existing numbers bypassed that insert branch. Migration `20260730120000_fix_new_phone_customer_session.sql` is applied live; the validator accepts `عميل طلبية`, and a full new-customer `ensure_customer` call passed inside a transaction that was rolled back.
- `server/src/otpStore.js` now releases a correctly reserved OTP if the later session write fails, so a transient backend error does not turn the same correct code into `already_verified`. This defense is committed but not yet redeployed to the Oracle WhatsApp host; the production database root fix is live.
- SHEIN combined selectors now prefer the complete visible `الكمية / مقاس` value over a nested partial aria label. A real-browser fixture with nested `aria-label="1PC"` and visible `M / CP1` sent `M / CP1` to cart while retaining a signed `addressCookie`. The lookup is bounded, cached for 1.2s between capture retries, and invalidated by the next real SHEIN tap; region readiness/add protection and all freeze paths are unchanged.
- Tracking uses a max-content grid and two-column product cards with bounded two-line titles, wrapped variants, explicit image dimensions, and the price below the copy. Playwright at `320×800` and `430×932` reported no header/product overlap, no card overlap, and no horizontal overflow; screenshots are in `output/playwright/v86.19/`.
- Validation passed: server syntax and OTP retry test, live Supabase migration/query/rollback test, `verify:shein-freeze-guard`, production build/performance budget, Android/iOS sync, Android Gradle debug build, compound-variant Playwright fixture, tracking layout metrics, and visual review. Budgets: JS raw `1,183,523/1,200,000`, JS gzip `355,635/370,000`, CSS `63,029/70,000`, fonts `81,364/100,000`, SHEIN source `549,317/550,000`. Targeted ESLint remains red on 22 pre-existing errors and 15 warnings in `App.tsx`; TypeScript/build pass.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.19-auth-variant-tracking-fix-debug.apk`; SHA-256 `92BCF3B2533FAFA7E3DA3E063E5D8339B708B9DF6D51F1720D98109E5B741239`; size `11,121,054` bytes. No ADB device was connected.
- Primary source commits are `08851ea` and `a747791`; matching iOS commits are `1827322` and `0400ffb`. GitHub/Xcode run `30493537125` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.19-iphone16-unsigned.ipa`; SHA-256 `223DBA03AE55B6A2CC7FB945E2E979A3DD498720A74CE70B2C1FC4485664941E`; size `7,066,065` bytes.
- IPA inspection confirms `com.otlobli.app`, `86.19/879`, the release/compound-selector/tracking markers, and `otlobliForceRecompose`; there is no provisioning profile or code-signature directory, and the only URL scheme is `otlobli`. Real-device acceptance remains required: request a fresh OTP for a genuinely new number, capture the live `M / CP1` product, inspect tracking, then run five iPhone 16 resume cycles plus a cold launch.

## v86.18 SHEIN region injection diagnostics + first-load id adoption (2026-07-29)

- Current diagnostic marker is `2026.07.29-v86.18-shein-region-injection-diagnostics`; Android and iOS are `878/86.18`, and the auth test bypass remains off.
- Real iPhone 16 testing rejected v86.17: first-product region setup still did not visibly start. The new static diagnosis found a concrete injection reliability gap before changing SHEIN DOM selectors: document start installs only the Otlobli nav, while the complete region/capture script depends on `browserPageLoaded`; that handler previously discarded an event id whenever `webviewIdRef.current` was still empty.
- During an active singleton open, the first page-loaded id is now adopted and used for the full script injection instead of being rejected. This is a host injection fix only; it does not change `addressCookie` readiness, drawer automation, reload limits, or the iPhone detach/reattach lifecycle.
- Bounded `sheinRegionDiagnostic` telemetry now reports `capture-evaluation-start`, `capture-script-injected`, product-route/tick/prime, repair active/cooldown/start, veil mount/z-index, shipping scan/entry/click, cookie/signature state, success, and timeout from WebView to React. The host stores only the latest 80 records in `window.__OTLOBLI_SHEIN_REGION_DIAGNOSTICS__` and console; the WebView flush timer stops within 5 seconds.
- Dead Temu diagnostic panels that had no callers were removed to preserve the frozen SHEIN source budget; no user feature was removed. `npx tsc --noEmit`, `npm run build`, `verify:shein-freeze-guard`, Android/iOS sync, and Android Gradle debug build pass. Budgets: largest JS `1,178,213/1,200,000`, total JS gzip `354,348/370,000`, CSS `62,602/70,000`, fonts `81,364/100,000`, SHEIN source `544,125/550,000`.
- Android artifact: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.18-shein-region-injection-diagnostics-debug.apk`; SHA-256 `5A143E2038E61508FD4E6D15A6B3E105AB04557572CE8DCF08303C5BB9CF6070`; size `11,528,789` bytes. `adb devices -l` listed no device, so no Android installation/device acceptance was performed.
- Matching source was pushed to `claude/ios6-cover-fix` and `codex/ios-v86-4` at `5e68790`. GitHub/Xcode run `30489996516` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.18-iphone16-unsigned.ipa`; SHA-256 `99BA19D125568162F8AB4601148375080FCBB8825755F724332EEC1CD7AEC41F`; size `7,064,608` bytes.
- IPA inspection confirms `com.otlobli.app`, `86.18/878`, the v86.18 marker, page-loaded id adoption, region diagnostics, capture injection, and `otlobliForceRecompose`. It has no provisioning profile or top-level app signature; its only URL scheme is still `otlobli`.
- `sheinPageInteractive` can mark the host WebView usable only after the bounded repair times out; it does not cancel the in-page tick/repair path. A real iPhone 16 must still capture the diagnostic sequence, verify the signed selected country, then pass five resume cycles and a cold launch. Do not claim the region issue solved from static analysis or builds.

## v86.17 first-product SHEIN region bootstrap + hidden switch veil (2026-07-29)

- Current marker is `2026.07.29-v86.17-shein-first-product-region-veil`; Android and iOS are `877/86.17`, and the auth test bypass remains off.
- This release targets the real iPhone 16 report after v86.16: after delete/reinstall, opening a SHEIN product could remain on the old/no signed region for minutes because the repair trigger waited too much on shipping DOM/readiness. Product-route detection now starts from the URL itself (`-p-...`, product/goods/item routes, and product query IDs), so the first product primes region repair immediately even before SHEIN renders the shipping row.
- SHEIN product URLs that are missing or carrying stale region query parameters now get one bounded bootstrap `location.replace()` to the normalized country/currency/language URL (`__otlobliRegionBootstrapReload:<country>:<path>`). This is not a loop and is skipped on challenge routes; after that, the signed `addressCookie` cascade remains the authority.
- A lightweight in-page region veil (`#otlobli-region-switching`) hides the SHEIN address drawer/switching steps while keeping Otlobli's bottom nav above it. It is HTML/CSS inside the WebView, not the old native `sheinSaudiRepairStart` cover, and auto-removes on signed readiness, failed repair timeout, or repair end. Add/back controls are hidden during the veil; add-to-cart still requires `sheinSignedSaudiAddressReady()`.
- The general tick now cheaply primes product-route repair before the touch/scroll early-return, then heavy scans still back off during interaction. Old `OTLOBLI_DBG` console scanning was replaced with a no-op to keep weak-phone overhead and the SHEIN source budget under control.
- Validation passed: `npm run build`, `verify:shein-freeze-guard`, `verify:performance-budget`, Android sync, iOS sync, Android Gradle debug build, GitHub/Xcode iOS build, and IPA inspection. Budgets: largest JS `1,180,135/1,200,000`, total JS gzip `355,127/370,000`, CSS `62,602/70,000`, fonts `81,364/100,000`, SHEIN source `549,688/550,000`.
- Android artifact: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.17-shein-first-product-region-veil-debug.apk`; SHA-256 `036333156DFA7A9C37123E1CAFD1057391596304EC118066E0F0A9243583A91D`. `adb devices` listed no connected Android device, so it was not installed/device-accepted.
- Matching iOS source was pushed on `codex/ios-v86-4` at `ad8b93d`; GitHub Actions run `30487346505` passed. IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.17-iphone16-unsigned.ipa`; SHA-256 `56A70B26090D484045A09654077D48D5B5B7108F67B31D792B8B82018F746A3A`.
- IPA inspection confirms `com.otlobli.app`, `86.17/877`, the v86.17 marker, first-product route/bootstrap markers, region veil marker, and `otlobliForceRecompose`. It remains unsigned/unprovisioned, and URL schemes still include only `otlobli`. Real iPhone 16 acceptance remains required: delete/install, first product must immediately show Otlobli preparation/finish selected Admin country, country change from Admin must rebuild/reprime, no visible stuck drawer, add-to-cart blocked until signed, and five background/resume cycles plus cold launch must pass.

## v86.16 background region repair + payment-status normalizer (2026-07-29)

- Current marker is `2026.07.29-v86.16-region-background-payment-status-normalizer`; Android and iOS are `876/86.16`, and the auth test bypass remains off.
- The checkout error from the screenshot was the production `orders_payment_status_check`. Supabase now has migration `20260729223000_normalize_order_payment_status_before_check.sql` applied, adding `normalize_order_payment_status_before_write()` and the `orders_aa_normalize_payment_status` trigger before insert/update so old/mojibake/mobile payment statuses become canonical Arabic before the check and before the exact-payment trigger. `supabase/schema.sql` is aligned, and the client error mapping now only treats the exact payment-status constraint as the payment DB-update case.
- SHEIN region repair no longer starts the native Saudi/region cover. It now runs as a fast bounded background cascade, applies to every Admin-selected supported country instead of the old Saudi-only smart path, clears stale foreign `addressCookie`, shortens action/scan/retry gaps, removes the 25s + 30s dead window, and releases the page as soon as it is interactive. Add-to-cart remains the hard gate: product pages require a signed `addressCookie` for the selected country before any Otlobli capture/add can proceed.
- Region list rows get lightweight Arabic-first labels through `data-otlobli-ar-label`/CSS without rewriting SHEIN's original option text, so automation and SHEIN internals still read the original labels. During user scroll/touch, the heavy SHEIN maintenance tick backs off; only the small region progress timer continues, and a live shipping drawer remains touch-isolated by `stabilizeSheinShippingDrawerInteraction()`.
- Validation passed: `npm run build`, `verify:shein-freeze-guard`, `verify:performance-budget`, Android sync, iOS sync, Android Gradle debug build, Supabase migration push/list, GitHub/Xcode iOS build, IPA marker inspection. Primary build budgets: largest JS `1,178,885/1,200,000`, total JS gzip `355,134/370,000`, CSS `62,602/70,000`, fonts `81,364/100,000`, SHEIN source `548,516/550,000`.
- Android artifact: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.16-region-background-payment-status-debug.apk`; SHA-256 `6A6E250025BC9A8D9D4C1D3615E8C16DB8FFE9F64D90086E4BB3F6334AC6CEFB`. No Android device was connected, so it was not installed/device-accepted.
- Matching iOS source was pushed on `codex/ios-v86-4` at `225cdb2`; GitHub Actions run `30455469510` passed. IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.16-iphone16-unsigned.ipa`; SHA-256 `B306938FC6AEAEB2189026AF9D4966C05658F0F8CC05C2DBE79677FAA816E5D9`.
- IPA inspection confirms `com.otlobli.app`, `86.16/876`, the v86.16 marker, background-region markers, and payment error mapping. It remains unsigned/unprovisioned, and URL schemes still include only `otlobli`, so real iPhone acceptance and Google iOS credentials remain required.

## v86.15 iOS safe top + Saudi region repair (2026-07-29)

- Current marker is `2026.07.29-v86.15-ios-safe-top-saudi-region-repair`; Android and iOS are `875/86.15`, and the auth test bypass remains off.
- The live Admin setting was verified from Supabase as SHEIN `SA` with `Riyadh Province -> Riyadh -> Al Olaya`; the user-visible failure was in the iPhone WebView automation, not the Admin setting.
- iOS now keeps the WKWebView below the real top safe-area/notch by setting `enabledSafeTopMargin:true`. Android still uses `useTopInset`; iOS still does not use the bottom safe margin because the injected Otlobli nav owns the home-indicator area. This fixes the SHEIN header/search/logo being drawn under the iPhone status bar without global zoom or CSS scaling.
- Saudi readiness on a product now requires SHEIN's signed `addressCookie`, not only SA URL/storage keys. If the country list opens while Saudi is off-screen, the automation clicks the country index letter (`S`) or scrolls the native country list within the existing bounded repair cadence. Address path matching now handles bilingual rows such as `العليا/Al Olaya` by matching either side of `/`.
- No feature was removed and no performance budget was raised. Production build, SHEIN freeze guard, performance budget, Android sync, iOS sync, Android Gradle, isolated iOS build, and GitHub/Xcode passed. Primary build budgets: largest JS `1,179,804/1,200,000`, total JS gzip `355,415/370,000`, CSS `62,602/70,000`, fonts `81,364/100,000`, SHEIN source `549,631/550,000`.
- Android artifact: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.15-ios-safe-top-saudi-region-repair-debug.apk`; SHA-256 `FA406DAFD77CD390023E2686E41EF9786B65CA208E2BA758456ED35F1B410DC2`.
- Matching iOS source is pushed on `codex/ios-v86-4` at `36d0486`; GitHub Actions run `30445161898` passed. IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.15-iphone16-unsigned.ipa`; SHA-256 `64C3DCFAEBE2FD27225D266305819B58EA167CCD744697AFB128DA0135ED8125`.
- IPA inspection confirms `com.otlobli.app`, `86.15/875`, the v86.15 marker, and the country-list movement marker. It remains unsigned/unprovisioned. Real iPhone acceptance is still required: delete/install or cold-launch, open a SHEIN product from a stale Qatar state, confirm it completes to Saudi/Riyadh/Al Olaya and the header is below the status bar, then run the permanent five background/resume cycles.

## v86.14 checkout/cart iOS layout + payment-status fix (2026-07-29)

- Current marker is `2026.07.29-v86.14-checkout-cart-ios-layout-payment-status-fix`; Android and iOS are `874/86.14`, and the auth test bypass remains off.
- The iPhone checkout regression came from the same implicit CSS Grid row-shrink class of bug as the earlier cart issue: the checkout price/details region could be clipped while the fixed payment action overlapped it. Checkout now has its own `.mobile-content--checkout { grid-auto-rows:max-content; }`, compact spacing, and a separated primary action. Do not replace this with global zoom, page-scale changes, or iOS top inset changes.
- Long cart product names are compact and bounded to three lines with wrapping, so a SHEIN title can no longer make the cart card huge or collide with the totals/sticky pay area. The sticky pay bar no longer uses `backdrop-filter`, keeping the weak-phone path lighter without removing features.
- New orders now normalize `payment_status` before sending to Supabase. The production database migration `20260729210000_fix_order_payment_status_constraint.sql` was applied with `supabase db push --linked`; it normalizes legacy/invalid values and keeps the canonical check constraint: `بانتظار الدفع`, `مدفوع`, `فشل المطابقة`.
- Visual Playwright acceptance passed at iPhone/narrow sizes. Evidence files: `output/playwright/v8614-cart-iphone16.png`, `output/playwright/v8614-cart-narrow.png`, `output/playwright/v8614-checkout-iphone16.png`, `output/playwright/v8614-checkout-narrow.png`, and `output/playwright/v8614-layout-report.json`.
- Production build, SHEIN freeze guard, performance budget, Android sync, iOS sync, Android Gradle, isolated iOS build, and GitHub/Xcode passed. Primary build budgets: largest JS `1,177,045/1,200,000`, total JS gzip `355,151/370,000`, CSS `62,602/70,000`, fonts `81,364/100,000`, SHEIN source `546,869/550,000`.
- Android artifact: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.14-checkout-cart-ios-layout-payment-status-fix-debug.apk`; SHA-256 `7538734E1C5DF5F8D6ED7D7517A693FF3BF12CBFEC250E62E611D7B8212001BD`.
- Matching iOS source is pushed on `codex/ios-v86-4` at `db6e73c`; GitHub Actions run `30441863134` passed. IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.14-iphone16-unsigned.ipa`; SHA-256 `E64F0A488ABC5BB241E972BD67E3A95DAF15B61ACA7F3F39988446C4C9F922A9`.
- The IPA remains unsigned/unprovisioned, so real iPhone acceptance is still required after install/signing: checkout spacing, cart long-title card, payment submit, store nav taps, five background/resume cycles, and a separate cold launch. Do not claim device acceptance from CI or screenshots alone.

## v86.13 responsive cart + direct store navigation + Android top inset (2026-07-29)

- Current marker is `2026.07.29-v86.13-responsive-cart-instant-native-nav`; Android and iOS are `873/86.13`, and the auth test bypass remains off.
- The cart overlap came from its scrollable CSS Grid shrinking implicit rows below their contents. Cart rows now use `grid-auto-rows:max-content` and compact flex cards with bounded image/swatch dimensions, semantic title/delete buttons, narrow-screen sizing, and visible overflow. Playwright visual/geometry acceptance passed at `390px` and `320px`: every card's rendered height is greater than its content scroll height, so adjacent cards no longer collide.
- Store-bar Orders/Cart/Profile taps now use a one-shot native `mobileApp.navigate(target)` bridge on Android and iOS. The host commits the React destination with `flushSync`; Android has a bounded 120ms reveal fallback. Cached/older scripts retain the idempotent post-message/hide path. This adds no polling, timer loop, or recurring scan.
- Android alone now enables the plugin's real top inset and safe top margin. The Note 8 WebView bounds are `[0,63][1080,2094]`, below the status bar `[0,0][1080,63]`; SHEIN's logo/search/header is fully visible. iOS keeps its existing sizing unchanged because the user's iPhone 16 layout is already correct.
- SHEIN can replace its body during live product/ranking updates. `#otlobli-nav` is therefore mounted on the stable document root rather than the replaceable body; the existing maintenance cycle remains, with no new persistent timer. The guard now protects this invariant.
- Real Note 8 acceptance used the installed `86.13/873` over existing app data: the Android top header is visible, product/search pages retain the bar, and Orders appeared in the first capture `1.17s` after the ADB command began, including about `0.58s` of ADB input overhead and screenshot time. Existing user cart data was inspected but not overwritten. No crash or ANR was observed.
- Production build, freeze/navigation guard, performance budget, Android/iOS sync, Android Gradle, APK install, and narrow visual fixtures pass. Current budgets: largest JS `1,176,414/1,200,000`, total JS gzip `354,837/370,000`, CSS `62,241/70,000`, and SHEIN source `546,869/550,000`.
- Android artifact: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.13-responsive-cart-fast-nav-debug.apk`; SHA-256 `D74996688545B1FA884F6883ED4741ECF948E404FC6C6B8B0B9089831AD9D9E4`.
- Matching iOS source is pushed on `codex/ios-v86-4` at `011b4a1`; GitHub/Xcode run `30437092864` passed. IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.13-iPhone16-unsigned.ipa`; SHA-256 `B9ECA22B8457625645FE8D2355AF44B2A0CE3725EDBC8FFB325424719F063019`.
- IPA inspection confirms `com.otlobli.app`, `86.13/873`, the v86.13/native-navigation/stable-root/recompose markers, no embedded provisioning profile, and no top-level app signature. Only the `otlobli` URL scheme exists, so Google iOS remains hidden. Real iPhone acceptance remains mandatory: cart layout, fast bar taps, five background/resume cycles, and a separate cold launch.

## v86.12 native store offline recovery (2026-07-29)

- Current marker is `2026.07.28-v86.12-native-offline-recovery`; Android and iOS are `872/86.12`, and the test auth bypass remains off.
- Main-frame network loss in the native SHEIN WebView no longer exposes Chromium/WebKit's raw error page. Android and iOS immediately place a compact Arabic Otlobli screen above the failed document, retain the exact product URL, offer an accessible native `إعادة المحاولة` button, and keep the cover in place until a real page succeeds.
- Recovery does not rebuild or clear the store session. A native network observer exists only while the offline cover is visible, performs one guarded retry when a validated path returns, and is cancelled on success or dismissal. There is no polling, DOM scan, fixed blur, or added React render work. iOS `NSURLErrorNotConnectedToInternet (-1009)` is now treated as recoverable instead of tearing down WKWebView.
- The loading cover is removed before the offline cover is exposed, so assistive technology sees one modal state and the raw error cannot flash behind a second accessibility layer. The existing iPhone detach/reattach burst and Android resume defense were not retimed or weakened.
- Real Note 8 acceptance passed with app data preserved. v86.12 was installed over v86.11; an offline SHEIN main-frame load was triggered through the real Capacitor plugin, the raw `ERR_INTERNET_DISCONNECTED` page was absent, the Arabic cover and native retry button were present, and a retry while still offline returned to the same cover without a blank/raw frame. Automatic recovery after a live network return was not exercised because the device had no reachable Wi-Fi/mobile route.
- Production build, freeze/interaction guard, performance budget, Android/iOS sync, Android Gradle, Note 8 visual/accessibility checks, and GitHub/Xcode passed. Main measurements remain within budget: largest JS `1,174,452/1,200,000`, total JS gzip `354,383/370,000`, and SHEIN source `545,474/550,000`.
- Android artifact: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.12-offline-recovery-debug.apk`; SHA-256 `79E8EFBA569381E3AB62B9121DE79ECF57F2C64077814F56839CD3728301EED6`.
- iOS source is pushed on `codex/ios-v86-4` at `5ab5639`; GitHub Actions run `30390632982` passed. IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.12-iPhone16-unsigned.ipa`; SHA-256 `EF7E0175AEAB4091B647E8FD7C05D924029848C1436105CC734301BAED0850DE`.
- IPA inspection confirms `com.otlobli.app`, `86.12/872`, the v86.12 marker, native offline-retry strings, and the permanent recompose marker. It remains unsigned/unprovisioned and only has the `otlobli` URL scheme. Real iPhone acceptance is still required: disconnect/reconnect during a product, manual retry, then the permanent five background/resume cycles and separate cold launch.

## v86.11 scroll-safe SHEIN nav input (2026-07-28)

- Current marker is `2026.07.28-v86.11-scroll-safe-nav-input`; Android is `871/86.11`, iOS is `871/86.11`, and the test auth bypass remains off.
- Real Note 8 DevTools evidence on installed v86.9 proved the stuck-bar cause: after region setup, `#otlobli-nav` was visible but computed `pointer-events:none`, had no `data-otlobli-nav-yield`, and all four hit-test points landed on SHEIN content behind it. A race let drawer-style restoration save and later restore the temporary `none` written by nav-yield logic.
- The shipping drawer no longer snapshots or restores nav interaction styles. `sheinRestoreNavAfterShipping()` owns the invariant visible/opaque/`pointer-events:auto` state, the transparent region guard alone blocks taps during conversion, and normal modal-yield logic runs again after the drawer closes.
- During active pointer/touch/scroll input, full SHEIN DOM, `innerText`, and layout scans are deferred until 320 ms after the last interaction. Region automation remains exempt behind its native cover, and shipping-root discovery is cached to avoid duplicate scans. No feature, blocker, region step, or permanent iPhone freeze repair was removed.
- `verify:shein-freeze-guard` now protects the nav-interaction and scroll-yield markers in addition to the WKWebView recompose patch.
- v86.11 was installed over v86.9 on the connected Note 8 with app data preserved. Repeated fast-scroll stress then opened Orders, Cart, and Profile from the first correct nav tap; no crash, ANR, or render-process loss occurred. The v86.9 baseline was p90/p95/p99 `21/24/38ms` with `22` missed frame deadlines. v86.11 runs measured `18/20/28-29ms` with `4-7` missed deadlines; jank percentage varied by run, so real iPhone acceptance remains required.
- Production build, freeze/interaction guard, performance budget, Android sync/Gradle/install, iOS sync, and GitHub/Xcode passed. Main measurements: largest JS `1,174,439/1,200,000`, total JS gzip `354,383/370,000`, and SHEIN source `545,474/550,000`.
- Android artifact: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.11-scroll-safe-nav-debug.apk`; SHA-256 `1E930ADF3C6FB5ABB2B3D1F1DD3A32DC3E2593AA684820F22B5AD56390AAF1E5`.
- iOS source is pushed on `codex/ios-v86-4` at `ab5dda3`; GitHub Actions run `30361886400` passed. IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.11-iPhone16-unsigned.ipa`; SHA-256 `E8CF4581911EB0B2B45E1C5B87575224F26960023529C67F58EA233AC06B8814`.
- IPA inspection confirms `com.otlobli.app`, `86.11/871`, and the scroll/nav/region guard markers. It remains unsigned/unprovisioned and only has the `otlobli` URL scheme, so Google iOS remains hidden. Required iPhone acceptance: fast product scrolling followed immediately by Orders/Cart/Profile taps, region conversion, and the permanent five background/resume cycles.

## v86.10 persistent iOS nav during region setup (2026-07-28)

- Current marker is `2026.07.28-v86.10-ios-persistent-nav-region-cover`; Android is `870/86.10`, iOS is `870/86.10`, and the test auth bypass remains off.
- Root cause: v86.9 intentionally hid `otlobli-nav` while the SHEIN shipping drawer was open, but the native iOS cover stops above the reserved bottom-nav band. That exposed SHEIN region rows in the band and made the app bar disappear during store/region changes.
- The verified drawer now keeps `otlobli-nav` visible, opaque, and mounted. A transparent in-nav interaction guard prevents accidental navigation while the automatic country/province/city/district cascade is running; only the overlapping Add and Back buttons are hidden. The guard is removed as soon as the drawer closes.
- This reuses the existing SHEIN maintenance tick and adds no polling, timer, blur, or WebView rebuild. The permanent iPhone freeze recompose patch was not weakened.
- Visual fixture acceptance passed at `390x844`: nav display `flex`, visibility `visible`, opacity `1`, guard present, and the bottom hit target was the guard rather than the hidden region list. Screenshot: `output/playwright/v86.10-nav-region-visible.png`.
- Production build, freeze guard, performance budget, Android sync/Gradle, iOS sync, and GitHub/Xcode passed. Main measurements: largest JS `1,171,247/1,200,000`, total JS gzip `353,644/370,000`, and SHEIN source `542,297/550,000`.
- Android artifact: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.10-persistent-nav-region-cover-debug.apk`; SHA-256 `904B81F6BC1FF6A72C2AC738B2CDF1EB780387E08ADBFFC4CD54AF6FF957B6F1`. The Note 8 was disconnected, so it was not installed/device-accepted.
- iOS source is pushed on `codex/ios-v86-4` at `88a9765`; GitHub Actions run `30357835150` passed. IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.10-iPhone16-unsigned.ipa`; SHA-256 `F38D74471E35A3AE6F3C8991C66A180822C1040AB3E78DCF9EE1302CB6045DE0`.
- IPA inspection confirms `com.otlobli.app`, `86.10/870`, the v86.10 marker, and the persistent-nav guard. It remains unsigned/unprovisioned; Google iOS remains hidden because only the `otlobli` URL scheme is present. Real iPhone acceptance is still required: switch store/region, confirm the bar never disappears, then run the permanent five background/resume cycles.

## v86.9 iOS country-first cascade + shipping drawer touch lock (2026-07-28)

- Current marker is `2026.07.28-v86.9-ios-country-first-drawer-touch-lock`; Android is `869/86.9`, iOS is `869/86.9`, and the test auth bypass remains off.
- The iPhone screenshot exposed an iOS-only state: SHEIN had already opened the country list but kept the stale `Qatar` label in its first tab. The old order checked that tab first and re-tapped Qatar on every pass instead of choosing Saudi Arabia.
- The cascade now detects two or more country-coded rows as authoritative country-list mode and selects the Admin-configured country before consulting stale tabs. Painted iOS transition nodes are detected even while they inherit `pointer-events:none`.
- A verified shipping drawer now owns touch interaction while open: the product page is position-locked at its saved scroll offset, touch scrolling is restored inside the real drawer/list, and Otlobli nav/Add/Back chrome is temporarily hidden and restored after close. This uses the existing maintenance tick and adds no permanent polling.
- Freeze guard, production build, low-end budget, iOS sync, GitHub/Xcode, Android sync, and Gradle passed. Current low-end measurements: largest JS `1,169,318/1,200,000` raw, total JS gzip `353,185/370,000`, and SHEIN source `540,365/550,000`.
- Android artifact: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.9-ios-country-drawer-fix-debug.apk`; SHA-256 `3202CC4930233F336851492134D69A9486D21ED3CC6D72A4A432B4351C052276`. The Note 8 was disconnected, so this exact APK is built but not installed/device-accepted.
- iOS source is pushed on `codex/ios-v86-4` at `4fe7f5b`; GitHub Actions run `30356842504` passed. IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.9-iPhone16-unsigned.ipa`; SHA-256 `5A8A39E38CC59D88EA598F3F87427F2A837C85A7E7B9C2C789E28E4C4D86A20B`.
- IPA inspection confirms `com.otlobli.app`, `86.9/869`, the country-first and touch-lock markers, plus both permanent freeze markers. It remains unsigned/unprovisioned and Google iOS remains hidden because no iOS OAuth URL scheme was injected. Real iPhone acceptance is still required; build inspection is not a substitute.

## v86.8 smart store-region session + fast drawer completion (2026-07-28)

- Current marker is `2026.07.28-v86.8-smart-fast-region-close-single-webview`; Android is `868/86.8`, iOS is `868/86.8`, and the test auth bypass remains off.
- Real Note 8/DevTools evidence found two independent failures: a settings/home race could create two native SHEIN WebViews (only one received Otlobli scripts), and SHEIN's current address close target is a focusable `span.header-close`, not a button. The latter left the already-signed location drawer visible until the old 45-second escape hatch.
- `App.tsx` now resolves the two region keys before first native open, caches the last verified region, owns one open/close lifecycle, closes stale returned WebView IDs, and filters URL/message/close events by the tracked ID. Region changes no longer leave an untracked Saudi/default WebView over the configured one.
- The injected SHEIN cascade now recognizes `.address-header-tab .j-tab-item`, selects the configured country from a placeholder country list, does not jump backwards because `addressCookie` still describes the previous country, advances through the configured path, recognizes the current close span, keeps the native cover until the drawer is gone, and force-closes an incomplete drawer after a 25-second bounded fallback.
- Real Note 8 tests passed with data preserved: Kuwait completed to `Abu Halifa` and closed the drawer in `4.926s`; the user's Kuwait-to-Saudi switch completed `Saudi Arabia -> Riyadh Province -> Riyadh -> Al Olaya`, wrote a signed Saudi `addressCookie`, closed the drawer in `6.666s`, and retained the Otlobli nav and Add button. Current live SHEIN Admin setting remains Saudi with that full path.
- Customer production build, freeze guard, low-end budget, Android sync/Gradle/install, iOS sync, and Admin build passed. Admin production `https://talabieh-admin.vercel.app` now accurately says region changes reach a visible app within 20 seconds.
- Android artifact: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.8-smart-fast-region-debug.apk`; SHA-256 `5EDB396603F94337E151AA9C8117D63C16C7784C729966D3DD55D3F72A712F78`.
- Final iOS CI run `30354782068` at commit `3b371a4` passed. IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.8-iPhone16-unsigned.ipa`; SHA-256 `F36A6F6A90542808E7353038CD2E72326069C482F34540EB547AF7C990EC1C73`. Inspection confirms bundle `com.otlobli.app`, `86.8/868`, the singleton/placeholder/close fixes, visibility control, and both freeze markers.
- The IPA is intentionally unsigned and has no provisioning profile. GitHub still has no `VITE_GOOGLE_IOS_CLIENT_ID`, so Google remains hidden in this build. Real iPhone acceptance is still required: Saudi region/product/Add button plus five background/resume cycles and one force-quit/cold launch; build inspection is not a substitute.

## Permanent project-sync rule (2026-07-28)

- Every completed change batch must update `CURRENT_STATE.md`, `AI-HANDOFF.md`, and `SESSION_SUMMARY.md` immediately in the same task, even when the change is small.
- Shared customer changes must be built and synchronized to every affected Android/iOS project; Admin, database, backend, workflows, versions, and artifacts must remain consistent with their source changes.
- Deployment and real-device status must always be recorded as succeeded, local-only, pending, or failed. Documentation-only edits do not trigger unnecessary native rebuilds.
- The authoritative detailed rule is `AGENTS.md → Mandatory Immediate Project Sync`; Claude and the quick handoff now contain the same requirement.

## Permanent SHEIN iPhone freeze guard (2026-07-28)

- `docs/SHEIN_IOS_FREEZE_GUARD.md` is now the mandatory source for the iPhone 16/iOS 27 frozen-frame regression. It distinguishes background/resume from force-quit/cold-launch and requires separate real-device acceptance.
- `scripts/verify-shein-freeze-guard.mjs` verifies the persistent patch, the applied iOS/Android native sources, and the unchanged-region rebuild guard in `App.tsx`.
- `npm run build` now runs the verifier through `prebuild`, so missing detach/reattach, scroll restoration, resume invocation, Android wake, or region comparison fails the build.
- The current persistent patch uses both `appDidBecomeActive` and `appWillEnterForeground`, then runs the bounded `otlobliRecomposeAllWebViews()` burst at `0.12/0.5/1.2/2.2s`; each forced pass calls `otlobliForceRecompose(force: true)`. The automated guard now requires those exact markers.
- The burst is resume-only and adds no polling or continuous work. Production web build, low-end budget, Android/iOS sync, and Android real-device checks pass. Five iPhone 16 background/resume cycles plus separate cold-launch acceptance remain mandatory.

## Permanent weak-device performance + iOS credential requirements (2026-07-28)

- `docs/LOW_END_DEVICE_PERFORMANCE_GUARD.md` makes weak-phone performance a release invariant without removing features. `npm run build` now post-runs `scripts/verify-performance-budget.mjs`.
- Baseline ceilings prevent bundle regressions: largest JS 1.2MB raw, total JS 370KB gzip, CSS 70KB, fonts 100KB, and SHEIN script source 550KB. The current 1.15MB main JS still triggers Vite's >500KB warning and remains explicit code-splitting debt.
- `docs/IOS_GOOGLE_PUSH_REQUIREMENTS.md` records the exact Apple/Google/APNs handoff. Current iOS Google is hidden because GitHub lacks `VITE_GOOGLE_IOS_CLIENT_ID`.
- The current iOS project has no `aps-environment` entitlements file, the IPA is unsigned, and Supabase has no `APNS_KEY/APNS_KEY_ID/APNS_TEAM_ID/APNS_BUNDLE_ID`; the permission prompt alone therefore cannot deliver remote notifications.
- Google iOS OAuth requires Google Cloud access and an iOS client for `com.otlobli.app`. Real APNs requires Apple Developer Program signing/capability/profile plus a p8 key. Passwords and 2FA codes must not be shared in chat.
- Validation passed: freeze guard, production build, performance budget (`1,151,303` largest JS raw / `348,843` total JS gzip), Android sync, and iOS sync. This guard/documentation batch did not alter runtime/version or create new artifacts; weak-device and signed-iPhone acceptance remain pending.

## v86.7 instant store-bar navigation + iPhone 16 candidate (2026-07-28)

- `APP_VERSION=2026.07.28-v86.7-instant-store-nav-iphone16-candidate`; Android `867/86.7`; iOS `867/86.7`; auth bypass remains off.
- Real Note 8 baseline recording proved that SHEIN → Orders took about `5–6s`: the injected store bar posted to the background React WebView, React rendered, then an effect requested native hide while the store dialog still covered the app.
- `CapgoInAppBrowser.allowWebViewJsVisibilityControl=true` now lets the injected SHEIN/Temu bar call native `window.mobileApp.hide()` at the tap itself for Orders, Cart, and Profile. The host message handler starts the same idempotent hide before `setScreen` as a fallback for cached/older scripts. The store WebView remains alive and is shown again on Home without reload.
- Repeated screen-record measurements on the connected Note 8 show Orders, Cart, and Profile appearing in roughly `0.5–0.75s`; no crash, ANR, render-process loss, or blocked hide appeared. SHEIN remains ready after returning Home.
- Production build and performance guard pass (`1,151,784` largest JS raw, `348,941` total JS gzip, `524,091` SHEIN source). Android 86.7 is installed over 86.6 with data preserved.
- APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.7-instant-store-nav-debug.apk`; SHA-256 `0CD3A847436F44B0FED48426692498B87E4E6CA8B17509C67DD123315F90D026`.
- Matching iOS source is pushed on isolated branch `codex/ios-v86-4` at `7b32f28`; GitHub/Xcode run `30350677536` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.7-iPhone16-unsigned.ipa`; SHA-256 `FBD006DE08A2CFEBA49F161B5A8E908E918191405B136A48018646645651CF57`.
- Embedded IPA checks passed: bundle `com.otlobli.app`, version/build `86.7/867`, v86.7 marker, native visibility control `true`, injected `window.mobileApp.hide()` marker, expected Capacitor plugin classes, no relay placeholder, and no code signature. Do not hand off the older successful 86.6 IPA as the current candidate.
- iOS remains unsigned and `VITE_GOOGLE_IOS_CLIENT_ID` is still absent, so Google is hidden and APNs is not end-to-end. Real iPhone 16 freeze/navigation acceptance remains the user's next device test.

## v86.5 account recovery + responsive mobile shell (2026-07-26)

- `APP_VERSION=2026.07.26-v86.5-account-recovery-responsive-shell`; Android `versionCode=865`, `versionName=86.5`; iOS marketing/build `86.5/865`; auth bypass remains off.
- Fixed the post-login session race: stored session values now reach localStorage synchronously before the first account, wallet, order, or push RPC. Android Google uses the standard explicit chooser with auto-select disabled and a forced prompt instead of reusing one old account silently.
- An authenticated startup now hydrates profile, historical orders, SYP/USD wallet balances, and wallet transactions. Temporary backend/network errors preserve the last good local snapshot instead of replacing orders with an empty list or wallet with zero.
- Production migrations `20260721120000_block_customers.sql`, `20260726223000_unified_customer_auth.sql`, and `20260726234500_session_account_hydration.sql` are applied. Account/order hydration resolves the phone from the authenticated session and matches legacy phone formats by their final 9 digits. `google-auth` is redeployed.
- The app shell now keeps the header and bottom navigation outside the only scroll container, removes expensive persistent blur, and keeps compact opaque chrome on weak WebViews. `طرق تسجيل الدخول` wraps naturally instead of truncating with an ellipsis.
- Visual acceptance passed at 320, 360, and 412 px: the full login-method label is visible, the header remains fixed while content scrolls, the body does not acquire a second scroll, and focus/reduced-motion behavior is present. Screenshots are under `output/playwright/`.
- Android build passed and the APK is at `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.5-account-recovery-responsive-debug.apk`; SHA-256 `A5D5BFDFE7E251C6CE114AF9FF049B6082163898BD2D633D61B45B4EFFBBEE05`. The Note 8 was disconnected at final acceptance, so v86.5 is not yet installed or device-verified.
- Matching iOS source is committed/pushed on isolated branch `codex/ios-v86-4` at `e9662da`. GitHub/Xcode run `30216693369` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.5-iPhone-unsigned.ipa`; SHA-256 `0E241E31DD9316EA67AD0F2F54040D4A924ABD364F6E17A780869FCA5356C5CC`. Embedded verification passed for bundle `com.otlobli.app`, version/build `86.5/865`, and the v86.5 marker.
- Honest remaining acceptance: reconnect the Note 8 and install without clearing data, then verify Google chooser, restart/store-switch hydration, old orders, wallet, and device-token registration. The iOS IPA is unsigned and Google remains hidden because `VITE_GOOGLE_IOS_CLIENT_ID` is not configured; APNs still needs Apple signing/credentials.

## v86.4 complete store-region routing (2026-07-26)

- `APP_VERSION=2026.07.26-v86.4-complete-store-region-routing`; Android `versionCode=864`, `versionName=86.4`; auth bypass remains off.
- Root cause fixed: SHEIN country text was treated as completion even when its authoritative `addressCookie` lacked province/city/district. Product reveal now waits for SHEIN's signed complete address, the live shipping drawer runs country → province → city → district behind the native cover, the drawer closes, then the product appears.
- Real Note 8 first-run acceptance passed after temporarily removing only `localStorage.addressCookie`: cover appeared, the script selected `Saudi Arabia → Riyadh Province → Riyadh → Al Olaya`, generated a 216-character `xAdFlag`, closed the drawer, preserved the Otlobli nav, and revealed the product. The temporary backup was removed after success.
- SHEIN admin destinations are limited to the 7 countries exposed by the live Arabic PWA: SA, AE, BH, KW, LB, OM, QA. Temu uses a curated 80+ country list based on its official global coverage. Region changes are reversible and Temu handles `/jo/`, `/jo-en/`, `/sa/`, and `/sa-en/` route forms.
- Weak-device work: bounded expensive fallback scans, relaxed hot polling on ≤4-core/≤3 GB/Android 7–10 devices, removed opaque-nav blur, extended the full-cascade watchdog to 60 seconds, and added a lightweight permanent nav remount watchdog.
- Production `app-settings` and `https://talabieh-admin.vercel.app` are deployed. Live SHEIN setting contains the complete Riyadh path; Temu is currently SA with an empty variable path.
- Android APK is installed on Note 8 and copied to `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.4-complete-region-routing-debug.apk`; SHA-256 `BAF091D2C1C940C80B71982E3999325303C6AC77E3C9598A2FB0694CB00320DA`.
- iOS source is isolated on `codex/ios-v86-4` (`3529bfb`, `7a5b69d`) so the primary dirty worktree remains untouched. GitHub/Xcode run `30196655282` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.4-iPhone-unsigned.ipa`; SHA-256 `2A004AC399C033B70F978B3BFC2385BAEBA128FB956A08E0680F46F4ECC4FA17`.
- Embedded IPA verification passed: bundle ID `com.otlobli.app`, marketing/build `86.4/864`, v86.4 marker, complete Riyadh path, InAppBrowser/SocialLogin/Push plugins, and no relay placeholder.
- Remaining honest acceptance: test every non-SA live destination individually and install the unsigned IPA on an iPhone. iOS Google still requires the iOS OAuth client; signed APNs still requires Apple signing/credentials.

## v86.3 iPhone candidate (2026-07-26)

- An isolated iOS build branch, `codex/ios-v86-3`, contains the current v86.3 customer source without committing the primary dirty worktree. Commits: `facff16`, `e808fd0`.
- GitHub Actions/Xcode run `30194500640` passed every step and produced an unsigned IPA.
- IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.3-iPhone-unsigned.ipa`; SHA-256 `B4274F8CB1AA3BA5875A2EE10CA75B05FCE82E0723BCBF196700DC7BA3AEDE88`.
- Embedded verification passed: bundle ID `com.otlobli.app`, marketing version `86.3`, build `863`, v86.3 app marker present, Google/Push/InAppBrowser native plugins linked, and the relay placeholder is absent.
- The iOS workflow now injects `OTLOBLI_RELAY_KEY` before Capacitor sync, enables Push in the web bundle, and supports the required `VITE_GOOGLE_IOS_CLIENT_ID` plus reversed callback URL.
- Google is deliberately hidden on iOS when that iOS OAuth client is absent instead of exposing a broken button. The current Google Cloud account that appears to own the Firebase project requires identity re-verification before the iOS client can be created.
- This artifact is unsigned and has not been accepted on a real iPhone. Google needs the iOS OAuth secret/rebuild; APNs needs Apple signing/capability/credentials before iPhone push can be claimed.

## v86.3 unified auth + verified Android push (2026-07-26)

- `APP_VERSION = 2026.07.26-v86.3-unified-google-phone-auth`; Android `versionCode=863`, `versionName=86.3`; `TEST_ONLY_AUTH_BYPASS=false`.
- Authentication is now account-centric: Google is a complete login method, while the receiving/WhatsApp number starts as delivery contact data and becomes a phone login only after a successful OTP.
- A new Google customer chooses Google, enters name/delivery details, and enters immediately without OTP. Existing Google identities still receive an immediate session.
- `حسابي → طرق تسجيل الدخول` shows Google and phone status, links Google to a phone account, and verifies the saved delivery number for phone login. The server rejects identities already linked to another customer instead of merging by typed email/phone.
- Live migration `20260726223000_unified_customer_auth.sql` and the updated `google-auth` function are deployed. All 27 pre-existing customers were preserved with phone login enabled.
- Real Note 8 acceptance passed: the installed Google account produced an online `idToken`; the live edge exchange returned `mode=existing`, a session, and the same account phone. The live account-status response showed both Google and phone linked.
- Push notifications are also now accepted end-to-end: one enabled Android token exists, admin sends return `sent=1`, Android channel `otlobli_general` is importance 5, the notification appeared, and the user confirmed it works. Admin production has the improved empty-device guidance.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.3-unified-google-phone-auth-debug.apk`; SHA-256 `DAB16D357518A27AB2732EEFB2EAF0DC358A3847D4772A074FC4E4BCD8FF859B`.
- Validation passed: live SQL rollback assertions for Google-first → optional phone verification, edge-function contract tests, production build, Playwright 412×915 UI review, Capacitor sync, Gradle build, APK install, device version check, live account-method UI, native Google ID-token return, backend exchange, and push delivery.
- Remaining acceptance is outside this Android/auth/push scope: test non-Saudi store regions on real store pages, install/test the unsigned iOS candidate, finish the iOS OAuth client, and configure signed APNs delivery.

## v86.2 professional auth + live store/branding controls (2026-07-26)

- Active worktree branch: `claude/ios6-cover-fix`, fast-forwarded to v86 commit `e72f4db`.
- `APP_VERSION = 2026.07.26-v86.2-professional-auth-admin-stores-branding`; Android `versionCode=862`, `versionName=86.2`.
- Google and Push Capacitor packages now use static bundled imports. The Android Google flow was verified on the connected Note 8 through the native Google activity; cancelling returns cleanly with no raw module-specifier error or stuck phone-login state.
- Google is enabled by default with the public Web OAuth client ID. Set `VITE_GOOGLE_AUTH_ENABLED=false` only for an intentional opt-out.
- `TEST_ONLY_AUTH_BYPASS = false`: a fresh customer must authenticate by phone or Google.
- Public settings `store_region_shein` and `store_region_temu` are live. Each accepts JSON `{ country, currency, language }`; both currently default to `SA/USD/ar`. The app polls every 30 seconds and recreates the active store WebView once when its region changes.
- SHEIN and Temu country URLs are now dynamic. Currency remains deliberately locked to USD until cart/invoice currency conversion is designed and audited.
- The production admin now has a visible `المتاجر والهوية` tab: independent two-letter region controls for SHEIN/Temu (including custom ISO codes), live arrival notice, USD safety explanation, and app name/logo upload with preview.
- `brand_name` and `brand_logo_data_url` are live app settings. The customer auth shell consumes them and now uses a compact, Arabic-first Otlobli route design instead of the oversized generic login card.
- The live database migration, `app-settings` edge function, and admin at `https://talabieh-admin.vercel.app` are deployed.
- Final Android debug APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.2-professional-auth-admin-stores-debug.apk`; SHA-256 `F4F7BBDC04549FE428FFFEB56DE837FCBAF3F6EC8337126B5FCD92E31D2176E7`.
- Validation passed: customer/admin production builds, desktop/mobile Playwright screenshots, custom `JP` region form save against a mocked backend, live settings verification, Capacitor sync, Gradle build, real-device install/launch, Android version inspection, native Google launch/cancel, and `git diff --check`.
- Region/session polling uses the filtered `app-settings?keys=...` endpoint, so a configured logo is not downloaded every 15–30 seconds.
- Honest remaining acceptance: complete a real Google account selection and backend token exchange; register at least one logged-in device and send a real FCM notification; test non-Saudi SHEIN/Temu regions on real store pages; build/test the matching iOS candidate.

## v86 — دخول جوجل + إشعارات Push + تنبيه حظر تيليغرام (2026-07-26)

الفرع الفعّال: `claude/otlobli-v86-push-google-telegram` (على `claude/ios6-cover-fix`).
كل ميزات v86 **إضافية وخاملة وآمنة** (خلف أعلام/أسرار). التطبيق يعمل طبيعياً دونها.
- قاعدة البيانات (مطبّقة حيّة): جدولا `customer_identities` + `device_tokens` و٦ دوال.
- دوال حافة منشورة: `google-auth`, `send-push` (كلاهما خامل/يفشل مغلقاً)، و`admin-orders` مربوطة بإشعار الحالة.
- الواجهة: `googleAuthApi.ts`, `pushNotifications.ts` + زر جوجل، عبر استيراد ديناميكي محروس (البناء ناجح).
- تنبيه تيليغرام لحظر واتساب: جاهز في `server/src/whatsapp.js`، يحتاج نشر Oracle فقط.
- **التفعيل خطوة بخطوة: `docs/CREDENTIALS_SETUP.md`. الملخّص الكامل: `SESSION_SUMMARY.md`.**

## v85.8.92 — Freeze fixed + payment/coupon/security + WhatsApp anti-ban (2026-07-25)

- Branch `claude/ios6-cover-fix`. `APP_VERSION = 2026.07.25-v85.8.92-freeze-fix-plus-payment-claim-5min-no-otp-test`. Base re-set to the clean v85.8.77 source (user-confirmed) with only the fixes below layered on.
- **SHEIN iPhone-16/iOS-27 freeze: FIXED (user-confirmed 100%).** Root cause = WKWebView's remote layer tree not reattaching on app resume from background. Fix (patch-package): `otlobliForceRecompose` detaches+reattaches the WebView (same constraints, preserves scroll) driven by `appDidBecomeActive`; Android defensive `handleOnResume` wake. iOS build `30144837725` + Android APK both built; the Android build launches clean on the Note 8.
- **Payment auto-match (ShamCash): FIXED & verified.** The Note 8 ran the OLD v1 listener (no HMAC) → webhook 401. Installed v2.0.0 via adb + rotated `PAYMENT_WEBHOOK_SECRET` via Supabase CLI so both sides match. Signed test → 200.
- **Security (live):** revoked `anon` EXECUTE on legacy `get_customer_account(text)` and `get_wallet(text)` (leaked any customer's account/wallet by phone). schema.sql is DRIFTED from prod — audit live via `supabase db query --linked`.
- **Coupons:** configurable `per_user_max_uses` (default 1) + `coupon_redemptions.uses` counter, atomic enforcement, admin form field. Live + tested.
- **Order payment window:** now 5 min, configurable via `app_settings.order_payment_window_minutes`, in `create_pending_order`.
- **"لقد دفعت" claim:** `orders.paid_claim_at` + `claim_order_payment` RPC; client records the press + disables the button after the window; admin shows "الزبون أكّد الدفع" badge (admin-orders + AdminApp deployed).
- **WhatsApp anti-ban on the ACTIVE `server/`** (NOT `server-whatsapp/`, a dead duplicate): onWhatsApp validation, warmup ramp, per-number daily cap, risk-score auto-pause, 429/463/403 handling, Telegram ban alerts. Deploy on Oracle: `git pull && cd server && npm install && pm2 restart`.
- Deploy access this environment has: Supabase CLI (linked, project `dcicqdprtyhwmhegabay`), Vercel CLI (`talabieh-admin`), adb to the Note 8. iOS via GitHub Actions.
- Pending (user-requested next): push notifications (FCM/APNs), Google sign-in + account linking, cart-group session hardening.

## v85.8.89 SHEIN iOS Modal Lifecycle

- Branch: `claude/ios6-cover-fix`. `APP_VERSION = 2026.07.23-v85.8.89-shein-ios-modal-lifecycle-no-otp-test`.
- Real-device diagnosis on iPhone 16 Pro Max (`iPhone17,2`, iOS 27.0 beta `24A5380h`) separated two failures. Older crash reports show `WKWebViewController.webView(_:didFinish:) -> presentView -> UIViewController.present` ending in `SIGABRT`. A separate failed cold run started fresh app/WebContent processes but received only one 705-byte HTTP 200 response and no normal resource fan-out, challenge, 429, WebContent termination, or jetsam.
- The project uses Capgo InAppBrowser 8.6.25, before the official safe-presentation, touch-blocking `UITransitionView`, and `openWebView` double-resolve fixes. Old IPAs were installed as updates under the same bundle ID, so they retained the same WebKit website-data container and were not clean A/B tests.
- Fix: SHEIN alone now dismisses its UIKit modal instead of alpha-hiding the transition container, while preserving the same live `WKWebView` and viewport. A transient lifecycle guard prevents `viewDidDisappear` from destroying that WebView during visibility hide, `hide/show` calls are serialized, repeated presentation is guarded, and the SHEIN `openWebView` call resolves once with its ID.
- Temu keeps its previous presentation, popup, preserve-attached, and hide/show paths. No payment, wallet, completed-order, cart-financial, product-capture, or Saudi-handling logic changed.
- Code commit: `35913c1` (`fix: v85.8.89 stabilize SHEIN iOS modal lifecycle`), pushed to `origin/claude/ios6-cover-fix`.
- GitHub iOS build `30012069056` succeeded, including Xcode compilation.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.89-shein-ios-modal-lifecycle.ipa`.
- v85.8.89 IPA SHA-256: `38568CD56DDAB5E042443A60E8EBA7F5BE9C68A139FE8D4BE12BF70A8330664C`.
- Validation: clean `patch-package` apply against Capgo 8.6.25, `npm run build`, targeted SHEIN/config ESLint, independent Swift/diff review, `git diff --check`, GitHub Xcode build, and embedded IPA checks for the v85.8.89 marker, `otlobliDismissModalWhenHidden`, and `otlobliVisibilityHideInProgress`. `src/App.tsx` still has the documented pre-existing unrelated lint errors.
- Not yet device-verified. Acceptance is repeated Home ↔ Cart, rapid hide/show during first load, background/resume, and cold reopen on both iPhones. This build fixes the confirmed native modal/touch/crash defects; it does not yet claim to explain the separate 705-byte cold-load failure. If that remains on iPhone 16, pull the persistent WebKit container read-only or run one true Delete App + reboot + reinstall test before calling it server fingerprint reputation.

## v85.8.88 SHEIN Passive Saudi Handling

- Branch: `claude/ios6-cover-fix`. `APP_VERSION = 2026.07.23-v85.8.88-shein-passive-saudi-no-otp-test`.
- User rejected v85.8.87 on iPhone 16 Pro Max: SHEIN remained blocked/frozen, so host-targeted cookie reset is not the root fix for that device.
- New excluded paths: document-start injection removal, challenge-page avoidance, and SHEIN-only cookie/cache reset all failed on the real device.
- New root-cause direction: after page load, the full SHEIN script was still automation-heavy. It mass-wrote common SHEIN cookies/localStorage/sessionStorage keys, monkey-patched `Storage.prototype.setItem`, scanned `document.body.innerText` for region signals too often, auto-clicked the native shipping drawer from the normal browse tick, and had a post-ready heartbeat watchdog that rebuilt the WebView after a missed heartbeat.
- Fix: SHEIN browsing is now passive. Saudi/USD/Arabic enforcement stays in the URL/native redirect path. The injected script no longer writes the broad Saudi cookie/storage set, no longer sweeps arbitrary storage keys, no longer monkey-patches storage, no longer auto-opens/clicks the shipping drawer during browsing, caches visible shipping-region text scans, and no longer sends/uses post-ready heartbeat rebuilds. Add-to-cart still blocks if the page visibly shows a foreign shipping region or an explicit foreign `addressCookie`.
- Scope protected: no product capture, color/size parsing, add-to-cart payload, product URL normalization, cart math, payment, wallet, completed-order, or Temu logic changed.
- Code commit: `832e2cb` (`fix: v85.8.88 make SHEIN Saudi handling passive`), pushed to `origin/claude/ios6-cover-fix`.
- GitHub iOS build `29972064005` succeeded.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.88-shein-passive-saudi.ipa`.
- v85.8.88 IPA SHA-256: `5BF571331F8CCE96B6D11F4AA13D18DA1EEE8CABA99E9E844205CAC4632317C6`.
- Validation: `npm run build` passed; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` passed; injected `OTLOBLI_NAV_BOOTSTRAP_SCRIPT` and `SHEIN_CAPTURE_SCRIPT` parsed with `new Function`; `git diff --check` only reports Windows LF/CRLF warnings; GitHub iOS build passed; embedded IPA marker check found `v85.8.88` and `Passive Saudi mode`. Targeted `src/App.tsx` lint still reports pre-existing unrelated project lint errors.
- Not yet device-verified. If the same iPhone remains blocked even with this passive build while other phones work, the remaining cause is likely SHEIN server-side device/IP/fingerprint reputation; the code path that looked like automation has now been removed.

## v85.8.87 SHEIN Cookie Reset

- Branch: `claude/ios6-cover-fix`. `APP_VERSION = 2026.07.23-v85.8.87-shein-cookie-reset-no-otp-test`.
- User rejected v85.8.86 on iPhone 16 Pro Max: SHEIN remained blocked even after removing SHEIN document-start injection and avoiding challenge-page writes.
- Confirmed local plugin source: `InAppBrowser.clearCache()` only removes `WKWebsiteDataTypeDiskCache` and `WKWebsiteDataTypeMemoryCache` on iOS; it does not remove SHEIN cookies. The plugin already exposes host-targeted `clearCookies({ url })`, which deletes matching `WKHTTPCookieStore` cookies.
- Fix: before opening SHEIN for this build once, clear host-targeted SHEIN cookies for `m.shein.com`, `www.shein.com`, and `shein.com`, plus WebKit cache. Also queue the same SHEIN-only cookie/cache reset after `sheinBlocked`, preparation failure, stuck-WebView recovery, unexpected SHEIN close on home, and user retry buttons.
- The reset is bounded, not a 24/7 watchdog: it runs once per `APP_VERSION` or after a confirmed stuck/blocked session. Failures in native cleanup are logged and do not prevent the WebView from opening.
- Scope protected: no product capture, add-to-cart, color/size parsing, product URL normalization, cart math, payment, wallet, completed-order, or Temu logic changed.
- Code commit: `d9903c2` (`fix: v85.8.87 reset SHEIN blocked cookies`), pushed to `origin/claude/ios6-cover-fix`.
- GitHub iOS build `29971119985` succeeded.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.87-shein-cookie-reset.ipa`.
- v85.8.87 IPA SHA-256: `A8F70B21D2A7DCD5F6D73A2F865D7793BF5B7A5669D5EFDE787113603CFD294E`.
- Validation: `npm run build` passed; `npx eslint src/config.ts` passed; `git diff --check` passed aside from Windows LF/CRLF warnings; GitHub iOS build passed; embedded IPA marker check found `v85.8.87`, `shein-website-data-reset`, and `SHEIN cookie reset`. Targeted `src/App.tsx` lint still reports pre-existing unrelated project lint errors; full build passes.
- Not yet device-verified. If this build remains blocked on the same iPhone 16 but works on another phone, the remaining likely cause is SHEIN server-side device/IP/fingerprint reputation rather than Otlobli DOM injection or WebKit cache.

## v85.8.86 SHEIN No DocumentStart Challenge Touch

- Branch: `claude/ios6-cover-fix`. `APP_VERSION = 2026.07.23-v85.8.86-shein-no-docstart-challenge-no-otp-test`.
- User rejected v85.8.85 on iPhone 16 Pro Max: SHEIN was still blocked.
- Concrete follow-up: removed SHEIN's `otlobliDocumentStartScript` bootstrap entirely. SHEIN no longer gets any Otlobli DOM/nav injection at document start; the full SHEIN script runs only after page load.
- Added an early loaded-document challenge detector before any Saudi cookie/storage write. This catches same-URL Cloudflare/security pages, not only `/challenge` URLs, then removes every Otlobli node and returns without touching the challenge.
- Scope protected: no product capture, add-to-cart, color, size, product URL normalization, cart math, payment, wallet, completed-order, or Temu logic changed.
- GitHub iOS build `29970160713` succeeded from code commit `d92b777`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.86-shein-no-docstart-challenge.ipa`.
- v85.8.86 IPA SHA-256: `4BE352FDDCC5FFBAB5EE4707D210E204FC75CB4AFA48B3A3A7DB85B7702FC9FA`.
- Validation: `npm run build` passed; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` passed; injected `OTLOBLI_NAV_BOOTSTRAP_SCRIPT` and `SHEIN_CAPTURE_SCRIPT` parsed with `new Function`; GitHub iOS build passed; embedded IPA marker check found v85.8.86 and no `otlobliDocumentStartScript` marker. Targeted `src/App.tsx` lint still reports pre-existing unrelated project lint errors; full build passes.
- Not yet device-verified.

## v85.8.85 SHEIN iOS Gentle Challenge

- Branch: `claude/ios6-cover-fix`. `APP_VERSION = 2026.07.23-v85.8.85-shein-ios-gentle-challenge-no-otp-test`.
- New real-device evidence: the same SHEIN build can work normally on iPhone 6, while iPhone 16 Pro Max gets challenged/blocked after the first entry even after reinstall. Treat this as SHEIN anti-bot/session sensitivity on the modern device, not a universal code failure.
- Concrete fix: when SHEIN shows a human/security challenge, the injected script no longer writes Saudi cookies/storage and no longer mounts/re-mounts the Otlobli nav inside the challenge document. It removes Otlobli nodes, releases scroll lock, posts `humanCheck`, and leaves the challenge page alone.
- Load reduction: all iOS SHEIN WebViews now use the gentler polling cadence previously reserved for weak devices, so iPhone 16 no longer runs the 80ms/120ms hot path that can look automation-heavy and compete with the challenge script.
- Scope protected: no product capture, add-to-cart, color, size, product URL normalization, cart math, payment, wallet, completed-order, or Temu logic changed.
- GitHub iOS build `29969344175` succeeded from code commit `e363db1`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.85-shein-ios-gentle-challenge.ipa`.
- v85.8.85 IPA SHA-256: `0DB95F793C7E74108595C0E16708303B99512B3388305B2C69C235B545FAAF0A`.
- Validation: `npm run build` passed; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` passed; injected `OTLOBLI_NAV_BOOTSTRAP_SCRIPT` and `SHEIN_CAPTURE_SCRIPT` parsed with `new Function`; GitHub iOS build passed; embedded IPA marker check found v85.8.85 and `OTLOBLI_SHEIN_GENTLE_TIMERS`.
- Not yet device-verified.

## v85.8.84 Roll Back Failed v85.8.83 Fresh Session

- Branch: `claude/ios6-cover-fix`. `APP_VERSION = 2026.07.22-v85.8.84-rollback-v83-shein-stable-saudi-no-otp-test`.
- User rejected v85.8.83 on real iPhone: Saudi locking broke again, first open worked only once, then returning to the app left SHEIN as a frozen image. Treat v85.8.83 as a failed path.
- What failed in v85.8.83: closing SHEIN on app background/resume and forcing a fresh VPN/Saudi recheck made the browser lifecycle worse. It could kill/reopen the native WebView at sensitive moments and destabilize the Saudi setup.
- Response: reverted the v85.8.83 fresh-session policy, close/open queue, and removal of the SHEIN heartbeat. Restored the v85.8.82/v85.8.79 behavior that preserved the SHEIN WebView and had the old page heartbeat/recovery path.
- Scope protected: no color, size, product capture, add-to-cart, product URL normalization, icon/nav sizing, payment, wallet, completed-order, or Temu capture logic changed.
- GitHub iOS build `29957413860` succeeded from code commit `81ac13c`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.84-rollback-v83-shein-stable-saudi.ipa`.
- v85.8.84 IPA SHA-256: `36C2A08AFB95DAA88D97916DCFB1B6E595664111E59BEEBC7F6D3341E803CB10`.
- Validation: `npm run build` passed; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` passed; injected scripts parsed with `new Function`; `git diff --check` had only Windows LF/CRLF warnings; GitHub iOS build passed; embedded IPA marker check found v85.8.84.

## v85.8.82 SHEIN Stable Saudi + Cart Back Target

- Branch: `claude/ios6-cover-fix`. `APP_VERSION = 2026.07.22-v85.8.82-shein-stable-saudi-back-no-otp-test`.
- User rejected v85.8.81 as worse: first entry showed SHEIN on Bahrain and the app failed to lock Saudi, so product capture/add was blocked; after leaving/re-entering the app, SHEIN could freeze even without opening cart or a product.
- Response: rolled back the failed v85.8.80/81 SHEIN experiment. SHEIN cart products again use the previously stable native `InAppBrowser.setUrl()` path; the in-page navigation remains Temu-only. Restored the old SHEIN hot interval timings and the SHEIN heartbeat/recovery path from v85.8.79.
- Kept the useful v85.8.81 cart back-target fix: repeated `sheinPageInteractive` no longer resets a cart-opened product back button from `cart` to `home`; the target resets only when the customer actually leaves the WebView through Otlobli cart/orders/profile.
- Added one narrow Saudi recovery: if SHEIN has a saved `addressCookie` with an explicit non-Saudi country such as Bahrain, remove only that `addressCookie` before seeding the Saudi/USD state. This is not broad storage clearing and it preserves signed Saudi addresses.
- Scope protected: no color, size, product capture, add-to-cart flow, product link normalization, icon/nav sizing, payment, wallet, or order logic changes.
- GitHub iOS build `29952878400` succeeded from code commit `394bcae`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.82-shein-stable-saudi-back.ipa`.
- v85.8.82 IPA SHA-256: `20763A568A3E399CA59C98A4AF622C2059A62469F8D14893E77A51F1736297E3`.
- Validation: `npm run build` passed; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` passed; injected `OTLOBLI_NAV_BOOTSTRAP_SCRIPT` and `SHEIN_CAPTURE_SCRIPT` parsed with `new Function`; `git diff --check` had only Windows LF/CRLF warnings; GitHub iOS build passed; embedded IPA marker check found v85.8.82.
- Next real-device check: install v85.8.82, open SHEIN fresh and confirm Saudi/USD before any product capture. Then open a SHEIN cart product and press Otlobli back once; expected: return to Otlobli cart, not SHEIN categories/home.

## v85.8.81 SHEIN Cart Back Target Fix

- Branch: `claude/ios6-cover-fix`. `APP_VERSION = 2026.07.22-v85.8.81-shein-cart-back-target-no-otp-test`.
- User tested v85.8.80 and the same issue remained: SHEIN cart product opens correctly, but pressing Otlobli's back button returns inside SHEIN to a home/categories page where the category row is visible but the products below do not render and the page is effectively stuck.
- Corrected root cause: product opening was no longer the failing part. `sheinPageInteractive` is posted repeatedly by the injected SHEIN script. After a cart product revealed, React initially sent `__backTarget = cart`, but the next repeated readiness message called `markStoreWebviewReady()` again, posted `__backTarget = home`, and reset the button into normal in-page `history.back()` mode. The user's next tap therefore drove SHEIN's own history back to a half-rendered categories state instead of returning to Otlobli cart.
- Fix: `markStoreWebviewReady()` and the home-show effect now keep posting the current back target without resetting it to `home`. The target resets only when the customer actually leaves the WebView through Otlobli cart/orders/profile messages. A cart-opened SHEIN product therefore keeps its back button bound to Otlobli cart and never falls into SHEIN's broken in-page back state.
- Scope protected: no product URL/opening rewrite beyond v85.8.80, and no color, size, capture, add-to-cart, deep-link, nav/icon sizing, payment, wallet, or order changes.
- GitHub iOS build `29946868465` succeeded from code commit `505db9d`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.81-shein-cart-back-target.ipa`.
- v85.8.81 IPA SHA-256: `3A418030C59499B76611B59E0102C72909686954879185E7A9258CCF5E3B7A84`.
- Validation: `npm run build` passed; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` passed; injected `OTLOBLI_NAV_BOOTSTRAP_SCRIPT` and `SHEIN_CAPTURE_SCRIPT` parsed with `new Function`; GitHub iOS build passed; embedded IPA marker check found v85.8.81.
- Next real-device check: install v85.8.81, open a SHEIN product from Otlobli cart, press Otlobli's back button once. Expected: app returns to Otlobli cart, not to SHEIN categories/home. Then reopen SHEIN normally and verify browsing/products remain tappable.

## v85.8.80 SHEIN Cart Light In-Page Navigation

- Branch: `claude/ios6-cover-fix`. `APP_VERSION = 2026.07.22-v85.8.80-shein-cart-light-nav-no-otp-test`.
- User rejected v85.8.79 because it was a recovery-after-freeze approach and the same SHEIN cart-product freeze remained. New goal: fix the entry path, keep code lighter, and avoid a 24/7 watchdog workaround.
- Root-cause direction: SHEIN cart products were still opened with native `InAppBrowser.setUrl()` deep loads from the cart, while switching Temu -> SHEIN recovered because it rebuilt the WebView. This points to the preserved SHEIN iOS WebView getting driven into a bad state by the cart-origin native deep product load, not to a missing product URL.
- Fix: SHEIN cart products now follow the same safer shape used for the confirmed Temu fix: load the store home first if needed, then open the product from inside the live store document with `window.location.assign()` through `executeScript`. Warm SHEIN cart opens show the WebView before the in-page navigation instead of preparing the deep product in a hidden preserved WebView.
- Removed the v85.8.79 SHEIN heartbeat watchdog/page heartbeat recovery path. The only remaining stuck-WebView restart is the old conservative pre-ready readiness guard. This keeps the fix at the source instead of adding an always-running freeze detector.
- Low-end phones: widened the low-end detector to include small iPhone-6-sized viewports, low CPU, and low memory; relaxed hot SHEIN scan intervals on those devices to reduce load while keeping modern phones on the faster timings.
- Scope protected: no changes to `getColorState`, `getSizeState`, `captureProductPayload`, `addToCartFlow`, deep-link building, add-to-cart validation, or injected nav/icon sizing.
- Browser harness: added `scripts/shein-cart-browser-harness.mjs` for visible desktop testing. It injects the same SHEIN script, compares native full load vs in-page navigation, writes screenshots/report, and supports `--keep-open=1` for manual CAPTCHA checks. Playwright Chromium is bot-flagged by SHEIN, so CAPTCHA results there are not trusted.
- Browser evidence with the user's product URL: SHEIN home became interactive and the long product URL was preserved; product navigation in desktop automation was redirected by SHEIN to `/risk/challenge` with `humanCheck`. This confirms the URL shape is valid but desktop automation cannot complete SHEIN's human check reliably.
- GitHub iOS build `29944509509` succeeded from code commit `71a3f13`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.80-shein-cart-light-nav.ipa`.
- v85.8.80 IPA SHA-256: `67D53FD87BCFECF606DAFD641CB2AAB657C2EB1084C8401C248432BF150C8AAD`.
- Validation: `npm run build` passed; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` passed; injected `OTLOBLI_NAV_BOOTSTRAP_SCRIPT` and `SHEIN_CAPTURE_SCRIPT` parsed with `new Function`; `git diff --check` had only Windows LF/CRLF warnings; GitHub iOS build passed; embedded IPA marker check found v85.8.80 and no old SHEIN heartbeat markers. Targeted `src/App.tsx` lint still reports pre-existing unrelated App lint errors.
- Next real-device check: install v85.8.80 on iPhone 6 and iPhone 16 Pro Max. Reproduce: SHEIN cart item -> product -> back to SHEIN home -> tap categories/products. Expected: product opens through the live SHEIN page path, back/home remains tappable, no delayed rebuild workaround, and capture/add/color/size behavior stays unchanged.

## v85.8.79 SHEIN Ready-Freeze Recovery Fix

- Branch: `claude/ios6-cover-fix`. `APP_VERSION = 2026.07.22-v85.8.79-shein-ready-freeze-recovery-no-otp-test`.
- User report: SHEIN can freeze after opening a product from the Otlobli cart and backing out to SHEIN home; tapping SHEIN categories no longer works. Switching to Temu and back fixes it because that rebuilds the store WebView; killing the app does not reliably fix it.
- Root cause in the local v85.8.78 fix: the new heartbeat watchdog detected "SHEIN is ready but heartbeat stopped", then called `restartStuckSheinWebview()`, but that function immediately returned when `sheinReadyRef.current` was true. So the post-ready freeze recovery path was logically disabled.
- Fix: `restartStuckSheinWebview(sessionId, allowReadyRecovery)` now allows the heartbeat watchdog to rebuild an already-ready frozen SHEIN WebView, while the old pre-ready readiness watchdog still keeps its conservative guard.
- Also strengthened first-product SHEIN login blocking: if an unsolicited product-page auth dialog has no reliable close control, the injected script hides that floating auth surface and releases body/html scroll lock. Real login routes remain untouched.
- Scope: SHEIN WebView recovery and SHEIN product login prompt only. No Temu, payment, wallet, completed orders, SKU capture, or cart math changes.
- GitHub iOS build `29928244012` succeeded from code commit `377f6d5`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.79-shein-ready-freeze-recovery.ipa`.
- v85.8.79 IPA SHA-256: `89677EFA17882DFB02C893FF16447323829A074141DC0C5E937A68771F2A120A`.
- Validation: `npm run build` passed; injected `OTLOBLI_NAV_BOOTSTRAP_SCRIPT` and `SHEIN_CAPTURE_SCRIPT` both parsed with `new Function`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` passed; `git diff --check` had only Windows LF/CRLF warnings; GitHub iOS build passed; embedded IPA marker checks found v85.8.79 and `data-otlobli-hidden-shein-login-prompt`. Targeted lint including `src/App.tsx` still reports pre-existing unrelated App lint errors.
- Next real-device check: on iPhone 6 and iPhone 16 Pro Max, open SHEIN from a cart item, back out to SHEIN home, wait if needed, then tap top categories/search/products. Expected: if SHEIN's JS freezes, the app rebuilds the WebView automatically after about 15-19 seconds instead of staying frozen; first-product login prompts should not remain visible.

## v85.8.75 Temu Cart In-Page Nav — diagnostics removed (fix CONFIRMED working)

- Branch: `claude/ios6-cover-fix`. `APP_VERSION = 2026.07.21-v85.8.75-temu-cart-inpage-nav-clean-no-otp-test`.
- User confirmed on device (v85.8.74): opening a Temu product from the cart now reaches the real Temu product page — the two diagnostic overlays were visible ON the product, meaning the in-page-navigation fix works and the /login.html white screen is resolved.
- Change: disabled both test-only diagnostic overlays now that the fix is confirmed — the black `otlobliTemuDiag` panel (state + "الحجب"/"انسخ DOM" buttons) and the yellow `otlobliTemuUrlProbe` bar. Their `otlobliTemuDiag()` / `otlobliTemuUrlProbe()` calls in the Temu tick were removed and any leftover `#otlobli-temu-diag` / `#otlobli-temu-urlprobe` nodes are now removed each tick. The functions remain in the file; re-add the two calls to bring the diagnostics back.
- The v85.8.74 in-page navigation (`navigateStoreWebviewInPage` → `window.location.assign` with a temu.com referrer), the cold-open home-first path, and the v85.8.73 login recovery + `temuLoginBlocked` graceful fallback all remain.
- Validation: `npm run build` (tsc + vite) clean.
- Next real-device check: confirm the product page is clean (no diagnostic bars) and still opens correctly from the cart.

## v85.8.74 Temu Cart In-Page Navigation (real fix for the login gate)

- Branch: `claude/ios6-cover-fix`. `APP_VERSION = 2026.07.21-v85.8.74-temu-cart-inpage-nav-no-otp-test`.
- Builds on the v85.8.72/73 root-cause finding (reproduced live in a browser): Temu 302s a cold top-level load of any deep page (product OR search) to `/login.html` because that programmatic load carries no `temu.com` referrer. Normal in-app browsing works because tapping a card is an in-page navigation with a Temu referrer.
- Fix: open a Temu cart product with an IN-PAGE navigation inside the already-warm Temu document instead of a refererless `InAppBrowser.setUrl`. New helper `navigateStoreWebviewInPage(url)` runs `window.location.assign(url)` via `executeScript`, so the navigation carries the current Temu page as Referer — the same request shape as a real product-card tap. Applied in both the warm path (`openStoreProductFromCart`) and the queued path (`markStoreWebviewReady`). SHEIN is unchanged (still `setUrl`).
- Cold-open path: when the store WebView is not open yet, `browseShein` now loads the Temu HOME first (guest browsing works) instead of cold-loading the deep product URL; once home is warm, `markStoreWebviewReady` reaches the queued product via the in-page navigation. The pending product URL stays queued for that step.
- Safety net kept: v85.8.73 `otlobliTemuRecoverFromLoginRedirect` (one guest retry) + `temuLoginBlocked` → App returns to cart with a notice, so a still-gated product never shows a white login page. v85.8.71 900ms stable gate + v85.8.72 top URL probe remain for evidence.
- Hypothesis (referrer-based gating) is well-reasoned but NOT yet device-verified — the test browser is bot-flagged and cannot reproduce a warm Temu session. User will test on device.
- Validation: `npm run build` (tsc + vite) clean.
- Next real-device check: open a Temu product from cart. Expected: the real Temu product page opens (like normal browsing). If it still shows the login/white, read the top yellow probe: `[PDP...]` + URL — if still `/login.html`, referrer gating is not the (whole) cause and we move to driving Temu's SPA router.

## v85.8.73 Temu Login-Redirect Recovery (ROOT CAUSE FOUND)

- Branch: `claude/ios6-cover-fix`. `APP_VERSION = 2026.07.21-v85.8.73-temu-login-redirect-recover-no-otp-test`.
- ROOT CAUSE, confirmed on real device via the v85.8.72 URL probe: opening a Temu product from the Otlobli cart lands on Temu's OWN login page. Probe read `[no-PDP] img=0/0 price=0` and URL `/login.html?from=https%3A%2F%2Fwww.temu.com%2Fsa%2F<url-encoded product slug>`. Temu rejects a COLD full-navigation to a deep product URL for logged-out users and 302s to `/login.html`; normal in-app browsing works because it is soft SPA navigation, not a cold load. This is Temu-side auth behaviour, not our blocking — no product content is ever hidden (img=0/0).
- Fix: `otlobliTemuRecoverFromLoginRedirect()` (runs early in the Temu tick). On `/login.html?from=<temu product url>` it navigates once to the `from` target via `location.replace` — Temu usually sets a guest cookie on the login page, so the retry loads the PDP as a guest. Guarded by `sessionStorage['otlobli_lr_'+target]` so it retries only ONCE per target across same-origin navigations (no login→product→login loop). Account/settings/login `from` targets are skipped so intentional logins are untouched.
- Graceful failure: if the single retry still lands on login, the script posts `temuLoginBlocked`; App.tsx aborts the pending cart-product preparation, returns to the cart, and shows "تيمو تطلب تسجيل الدخول لفتح هذا المنتج مباشرةً. افتحه من داخل تيمو بدل السلة." — never a white login reveal.
- Still includes the v85.8.71 stable-visibility gate (900ms) and the `otlobliTemuUrlProbe` diagnostic bar (now top-of-screen, v85.8.72).
- Validation: `npm run build` clean. NOT yet real-device tested.
- Next real-device check: open a Temu product from cart. Best case the guest retry opens the product; otherwise expect the cart + the login notice (no white). If it still ends white, read the top probe again — it will show whether it looped on `/login.html` or reached a `goods` PDP.

## v85.8.71 Temu Cart Stable-Visibility Gate + URL Probe (diagnostic build)

- Branch: `claude/ios6-cover-fix`. `APP_VERSION = 2026.07.21-v85.8.71-temu-cart-stable-gate-urlprobe-no-otp-test`.
- Ground truth established from the capgo InAppBrowser source: `preShowScript` with `preShowScriptInjectionTime: 'documentStart'` is registered as a persistent `WKUserScript` (WKWebViewController.swift ~L1565), so the injected script DOES run on every full `setUrl` navigation, including the cart-opened product document. The v85.8.68–70 "script/gate" theories were wrong about injection.
- User evidence (v85.8.70): the top diagnostic bar shows on normal Temu product browsing but NOT on the white screen from cart. Since the script always runs, the bar is absent only because `looksLikeProductPage()` is false on the final white state — i.e. Temu redirected the cart-origin direct PDP load to a login/blank URL (no `goods` path, no `curPrice`).
- Model: cart tap → full navigation → PDP paints briefly → reveal gate posts `temuProductVisible` on that first paint → WebView revealed → Temu bounces to login (the brief login flash) → collapses to a non-PDP blank URL → permanent white. The reveal fired on a transient paint Temu then abandoned.
- Fix (v85.8.71): `otlobliPostTemuProductVisibleIfReady` now requires product content to stay continuously visible for `OTLOBLI_TEMU_STABLE_MS = 900`ms before posting `temuProductVisible`. Any non-PDP / search / account / login-sheet / no-visible-content tick resets the stability timer, so a transient paint that bounces to login never triggers reveal. If the PDP never stabilises (genuine login wall), the cart stays with its spinner and eventually shows "تعذر تجهيز صفحة المنتج" instead of a white reveal.
- Diagnostic (test build): added `otlobliTemuUrlProbe()` — a permanent bottom bar on Temu (pointer-events:none) showing `[PDP/no-PDP ACCT LOGIN] img=dom/vis price=0|1 | <path+query>`. It stays visible even on the white screen (unlike the product-only top panel), so the final URL + state can be read to confirm whether white = Temu login/verify URL (Temu-side) or hidden product content (our blockers).
- Scope: Temu cart-product reveal timing + a read-only diagnostic bar. No blocker/hiding heuristics, payment, wallet, orders, or account-route logic changed.
- Validation: `npm run build` clean. NOT yet real-device tested.
- Next real-device check: open a Temu product from cart; if still white, READ the bottom bar and report it (especially the `[...]` flags and the URL path). That determines the next fix.

## v85.8.70 Temu Cart Login-Sheet Reveal Gate

- Branch: `claude/ios6-cover-fix`.
- Current local code candidate: v85.8.70 / `APP_VERSION = 2026.07.21-v85.8.70-temu-cart-login-sheet-gate-no-otp-test`.
- User report after v85.8.69: opening a Temu product from the Otlobli cart still briefly shows the Temu login screen and then a blank white product page.
- Root cause: the v85.8.69 reveal gate (`otlobliPostTemuProductVisibleIfReady`) blocked reveal only when `otlobliTemuVisibleAccountSurfaceOpen()` matched, and that detector needs an account-panel score of ≥2. Temu's minimal cart-origin sign-in sheet often carries a single sign-in signal, so it slipped past the gate: the product image behind the sheet counted as "visible content", the WebView was revealed while the login sheet was still up, and when Temu tore the sheet down the page collapsed to white.
- Fix: added `otlobliTemuLoginSheetVisible()` — a content-based detector that flags a large, visible, centered surface containing a sign-in/continue phrase confirmed by a phone/email/password input or a social "continue with" button. `otlobliPostTemuProductVisibleIfReady` now also returns early when it fires, so the cart stays visible until the login sheet is gone and real product content shows. It is a reveal gate only (delays showing the WebView); it hides nothing, so it cannot itself cause a white screen.
- Scope: Temu cart-product reveal timing only. No blocker/hiding heuristics, SKU capture, add-to-cart, header, bottom nav, payment, wallet, orders, or account-route logic changed.
- Validation: `npm run build` passed with no syntax errors in the injected script template.
- Not yet real-device tested. Next check: install v85.8.70, add a Temu item to the Otlobli cart, tap it, and confirm the cart stays visible (spinner "جاري تجهيز صفحة المنتج...") until the real Temu product page appears — no login flash then white. If a product is genuinely login-walled, expect the gate to hold and eventually show "تعذر تجهيز صفحة المنتج" rather than a white screen.

## v85.8.69 Temu Cart Product Visible Gate

- Branch: `claude/ios6-cover-fix`.
- Current iOS candidate: v85.8.69 / `APP_VERSION = 2026.07.20-v85.8.69-temu-cart-product-visible-gate-no-otp-test`.
- Code commit: `b9d6d14` (`fix: v85.8.69 gate Temu cart product reveal`).
- User confirmed ordinary Temu product opens work again after v85.8.68, but opening a product from Otlobli cart can briefly show Temu login/account UI and then reveal a white product screen.
- Root cause: the cart-product reveal gate for Temu still trusted the native `browserPageLoaded` event. On iOS WKWebView, Temu can fire that event before the SPA paints visible product content or before the transient login/account surface is cleaned.
- Fix: Temu cart-product reveal now waits for a page-script `temuProductVisible` message. The injected script only sends it when the current Temu product page has visible product content (large image or visible price) and no visible account/login surface; React also verifies the visible URL matches the pending cart product before switching from cart to home.
- Scope: Temu cart-product reveal timing only. No SKU capture, add-to-cart logic, header, bottom nav placement, payment, wallet, orders, or real account-route logic changed.
- GitHub iOS build `29735372870` succeeded from code commit `b9d6d14`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.69-temu-cart-product-visible-gate.ipa`.
- v85.8.69 IPA SHA-256: `C66EF04310F50891BA1D1A127E587DBC9A1FF94153CAA5C6E85307F890FCBF4F`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, `npm run build`, `git diff --check`, injected-script parse, GitHub iOS build, and embedded IPA marker checks passed (`v85.8.69`, `temuProductVisible`, and `otlobliPostTemuProductVisibleIfReady` present).
- Next real-device check: install v85.8.69, add a Temu item to Otlobli cart, go to the cart, tap the product, and confirm the cart stays visible until the Temu product page content appears with no login flash -> white screen.

## v85.8.68 Temu Product White-Screen Guard

- Branch: `claude/ios6-cover-fix`.
- Current iOS candidate: v85.8.68 / `APP_VERSION = 2026.07.20-v85.8.68-temu-product-white-screen-guard-no-otp-test`.
- Code commit: `091a35f` (`fix: v85.8.68 prevent Temu product white screen`).
- User clarified after v85.8.67: v85.8.67 was the installed build; a few Temu products opened correctly, then later product entry showed the login surface briefly and became a white screen with only Otlobli back visible. v85.8.68 has not been real-device tested yet.
- Fix: Temu product entry no longer paints a full-page white Otlobli cover. It still runs the immediate cleanup waves, but without an opaque overlay that can look like a permanent blank page if Temu's SPA delays rendering.
- Fix: while on a Temu product URL, large non-floating product-flow containers are protected from account/promo hiding even if early text contains login/account wording before product images and price finish rendering.
- Scope: Temu product white-screen guard only, plus keeping the v85.8.67 iPhone 6/iPhone 16 bottom-nav offset logic. No SKU capture, cart flow, header, payment, wallet, orders, or real account-route logic changed.
- GitHub iOS build `29733534914` succeeded from code commit `091a35f`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.68-temu-product-white-screen-guard.ipa`.
- v85.8.68 IPA SHA-256: `C26CC0F9EB31B01D105F1F004305E2F16B7F8F47DABF6C89DF5F0B499613337B`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, `npm run build`, `git diff --check`, GitHub iOS build, and embedded IPA marker checks passed (`NoCoverElement=true`, product-flow guard present, v85.8.67 modern/legacy nav markers still present).
- Next real-device check: install v85.8.68 and repeat the exact v85.8.67 failure path: open several Temu products in a row from listing/back. Confirm no login flash turns into a white product page. Also recheck bottom nav on iPhone 6 and iPhone 16 Pro Max.

## v85.8.67 Temu Modern iPhone Nav Offset

- Branch: `claude/ios6-cover-fix`.
- Previous iOS candidate: v85.8.67 / `APP_VERSION = 2026.07.20-v85.8.67-temu-modern-iphone-nav-offset-no-otp-test`.
- Code commit: `3a4e2dc` (`fix: v85.8.67 keep modern iPhone Temu nav offset`).
- User report after v85.8.66: the v85.8.65 iPhone 6 bottom-nav fix worked on iPhone 6, but broke the Temu bottom nav on iPhone 16 Pro Max.
- Root cause: relying only on `env(safe-area-inset-bottom)` is not stable inside Temu's WKWebView; on iPhone 16 Pro Max it can report `0`, which incorrectly selected the legacy iPhone 6 `bottom:0px` path.
- Fix: if real safe-area is present, keep `bottom:-18px`; if safe-area is zero, classify legacy no-home-indicator iPhones by CSS viewport (`<=414x736`) and use `bottom:0px`; modern tall iPhones such as iPhone 16 Pro Max fall back to `bottom:-18px`.
- Scope: Temu injected bottom-nav vertical placement only. No cart flow, notices, header, blocker, product/SKU capture, payment, wallet, orders logic, or account route changes.
- GitHub iOS build `29704696750` succeeded from code commit `3a4e2dc`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.67-temu-modern-iphone-nav-offset.ipa`.
- v85.8.67 IPA SHA-256: `1A9CF7A06D25ADF48A91EF71C0F037A09187AA49511348F41ACBCCD1C7E16451`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, viewport logic check (`iPhone6 => 0px`, `iPhone16PM env0 => -18px`), `npm run build`, `git diff --check`, GitHub iOS build, and embedded IPA marker checks passed.
- Includes v85.8.66 underneath: cart product open flow and notice polish.

## v85.8.66 Cart Product Open + Notice Polish

- Branch: `claude/ios6-cover-fix`.
- Previous iOS candidate: v85.8.66 / `APP_VERSION = 2026.07.19-v85.8.66-cart-product-open-notice-polish-no-otp-test`.
- Code commit: `3648898` (`fix: v85.8.66 open cart products and polish notices`).
- User report after v85.8.65: tapping a product from Otlobli cart did not open it, and the browser/product notices looked too framed/heavy.
- Root cause for cart open: when Temu was opened directly from a cart item while the WebView was not already visible, the target URL loaded as the initial hidden page but was not marked as a requested product navigation, so the reveal gate never completed. A fast Temu load could also reveal and then be hidden again by the open promise handler.
- Fix: initial pending product URLs now mark navigation requested for all stores, not only SHEIN, and the WebView hide step skips the case where that pending product already revealed.
- Notice polish: React toast and injected browser messages now use a lighter snackbar-style dark translucent text surface with Cairo/system font, no yellow border, safe-area bottom positioning, and a text-only product verification overlay instead of the white framed card.
- Scope: cart-product open flow and visual notice surfaces only. No payment, wallet, orders logic, account route, Temu header, bottom nav placement, or SKU gate changes.
- GitHub iOS build `29700181145` succeeded from code commit `3648898`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.66-cart-product-open-notice-polish.ipa`.
- v85.8.66 IPA SHA-256: `943C7862779CA9284855C3DD717CC93BA9B1229C87D8D799CC768CF3F435953D`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, `npm run build`, `git diff --check`, GitHub iOS build, and embedded IPA marker checks passed. `src/App.tsx` targeted lint still reports pre-existing unrelated project lint issues; the full TypeScript/Vite build passes.
- Includes v85.8.65 underneath: Temu bottom nav uses real iOS safe-area bottom, so legacy iPhones use `bottom:0px` while home-indicator iPhones keep `bottom:-18px`.

## v85.8.65 Temu Legacy Safe-Area Nav

- Branch: `claude/ios6-cover-fix`.
- Previous iOS candidate: v85.8.65 / `APP_VERSION = 2026.07.19-v85.8.65-temu-legacy-safe-area-nav-no-otp-test`.
- Code commit: `d3b2be2` (`fix: v85.8.65 align Temu nav on legacy iPhones`).
- User tested v85.8.64 on iPhone 16 Pro Max and iPhone 6: general behavior was good, but the Temu bottom nav was vertically different on iPhone 6 while iPhone 16 looked aligned.
- Real screenshot measurement on iPhone 6 showed the Temu nav top/indicator about 36 physical pixels (18 CSS px) lower than the React Orders nav. This matched the old universal `bottom:-18px` Temu nav offset.
- Fix: Temu nav now reads the real `env(safe-area-inset-bottom)` at runtime. iOS devices with a home-indicator safe area keep `bottom:-18px`; legacy iPhones with `safe-area-inset-bottom = 0` use `bottom:0px`; Android keeps the previous `-18px` path.
- Scope: Temu injected bottom-nav vertical placement only. No header, blocker, product/SKU capture, payment, wallet, orders logic, or account route changes.
- GitHub iOS build `29697979381` succeeded from code commit `d3b2be2`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.65-temu-legacy-safe-area-nav.ipa`.
- v85.8.65 IPA SHA-256: `FDBA2940D03E7962193C416CCB11F93B7838D5F157DBC3BDBE78BAEE3F21CECF`.
- Validation: screenshot pixel comparison, targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, injected-script parse, safe-area logic check (`iphone6 safe=0 => 0px`, `iphone16 safe=34 => -18px`, Android unchanged), `npm run build`, `git diff --check`, GitHub iOS build, and embedded IPA marker checks passed. Real-device acceptance is still required.
- Includes v85.8.64 underneath: Temu counted-variant item labels are detected in summary/collapsed/structural selector paths, and Temu products opened from Otlobli cart reveal after WebView page load.

## v85.8.64 Temu Items Selector Row + Cart Product Open

- Branch: `claude/ios6-cover-fix`.
- Previous iOS candidate: v85.8.64 / `APP_VERSION = 2026.07.19-v85.8.64-temu-items-row-cart-open-no-otp-test`.
- Code commit: `d7cd70f` (`fix: v85.8.64 detect Temu items selector row`).
- Includes v85.8.63 underneath: Temu products opened from Otlobli cart now mark the WebView ready after the browser page load and reveal the prepared product instead of staying on a white screen.
- User-provided Temu DOM for a smart-watch product showed the real selector row as `skuSelector-* role="button" aria-label="7 أغراض:حدد"`. The previous structural parser detected the selector shell but did not count `أغراض`, so the product could be treated like it had no required options.
- Fix: centralize Temu counted-variant label detection and reuse it in `temuVariantCounts()`, `temuVariantSummaryEl()`, `otlobliTemuCollapsedVariantRow()`, and the structural `skuSelector-*` parser. The second option family now includes size/model/style/type/RAM/storage plus Arabic/English item/piece labels: `أغراض/اغراض/غرض/عناصر/عنصر/قطع/قطعة/items/pieces/pcs`.
- Scope: Temu SKU/variant detection and cart product reveal only. No header, bottom nav, blocker, payment, wallet, orders, or account route changes.
- GitHub iOS build `29672118803` succeeded from code commit `d7cd70f`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.64-temu-items-row-cart-open.ipa`.
- v85.8.64 IPA SHA-256: `81C48D748AB0A5C219BA585FF84A46E1219AAAB6C349EA3BF53BBF340C0882C7`.
- Validation: pasted-DOM check extracts `7 أغراض` as `secondCount=7`, targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, injected-script parse, `git diff --check`, `npm run build`, GitHub iOS build, and embedded IPA marker checks passed. Real-device acceptance is still required.

## v85.8.62 Temu Single Model Selector Row

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.62 / `APP_VERSION = 2026.07.19-v85.8.62-temu-single-model-row-no-otp-test`.
- User screenshot showed a Temu product whose diagnostic overlay said `sku: لا خيارات` while the page visibly had a collapsed option row: `4 الموديل: ...` with a `حدد` button. The existing detector only trusted `skuSelector-*` collapsed rows or color+size summaries, so a single model-only row was missed.
- Scope: Temu SKU/variant detection only. No bottom nav, header, blockers, payment, wallet, orders, or account route changes.
- Fix: add `otlobliTemuCollapsedVariantRow()` to detect visible collapsed rows that contain `حدد/select/choose` plus a counted variant label such as `4 الموديل`, `3 اللون`, `24 موديل متوافق`, size/style/type/RAM/storage. This row becomes the `collapsedEl`, so Otlobli opens the options sheet and waits for the user selection instead of adding with missing model data.
- GitHub iOS build `29670967272` succeeded from code commit `0e7882c`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.62-temu-single-model-row.ipa`.
- v85.8.62 IPA SHA-256: `5A23674D464277D424C6D961A3190179638FF86D4B22A45804B8A6939B3D4B5B`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, `npm run build`, regex check for the screenshot pattern (`4 الموديل` -> 4), injected-script parse, `git diff --check`, GitHub build, and embedded bundle marker check passed. Real-device acceptance is still required.

## v85.8.61 Temu Disabled Child SKU Options

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.61 / `APP_VERSION = 2026.07.19-v85.8.61-temu-disabled-child-sku-no-otp-test`.
- User pasted DOM after tapping an unavailable Temu option on a luggage product. The unavailable options are `role="radio"` shells whose inner SKU card has a class like `disabled-8sgMU`; the radio shell itself can still look selectable to the previous detector.
- Scope: Temu SKU/variant availability only. No bottom nav placement, header forcing, blockers, payment, wallet, orders logic, or account route changes.
- Fix: `temuOptionUnavailable()` now treats a radio/ARIA choice shell as unavailable if it contains disabled/sold-out/out-of-stock child markers, so unavailable colors/options are excluded from selected-option detection and cannot satisfy the add-to-cart gate.
- Also keeps the v85.8.60 behavior: unavailable Temu options are filtered from SKU availability checks, unavailable taps are remembered briefly, and add shows `هذا الخيار غير متوفر حالياً` instead of treating the unavailable choice as selected.
- GitHub iOS build `29668801470` succeeded from code commit `480b2b1`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.61-temu-disabled-child-sku.ipa`.
- v85.8.61 IPA SHA-256: `7EAECBC0F233250E4379859CA581EB13099660FD4836E059FD93905ACECCC5D5`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, `npm run build`, injected-script parse, pasted-DOM radio/disabled-child extraction, `git diff --check`, GitHub build, and embedded bundle marker check passed. Real-device acceptance is still required.

## v85.8.60 Temu Ignore Unavailable SKU Options

- Superseded by v85.8.61 before delivery. v85.8.60 added generic Temu unavailable-option filtering and built successfully (`29668648639`, commit `cb7563d`), but the user's pasted DOM showed the disabled marker can live inside the radio shell, so v85.8.61 extended the detector before producing the final IPA.

## v85.8.58 Temu Bottom Nav Raised Slightly

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.58 / `APP_VERSION = 2026.07.18-v85.8.58-temu-nav-bottom-offset-18-no-otp-test`.
- User report after v85.8.57: Temu bottom nav needs to be raised a tiny bit.
- Scope: Temu injected bottom-nav vertical placement only. No WebView show/hide changes, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- Fix: raise the Temu nav container from `bottom:-22px` to `bottom:-18px`, a 4px upward correction, and bump the injected nav style version.
- GitHub iOS build `29658975318` succeeded from code commit `6cd9aa6`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.58-temu-nav-bottom-offset-18.ipa`.
- v85.8.58 IPA SHA-256: `6D1D060D03404F9546AC513B2AD85993A347D2A5938A6B378EA1050028AC0401`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, injected-script parse plus `bottom:-18px` marker check, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.58 marker/offset checks passed. Real-device acceptance is still required.

## v85.8.57 Temu Bottom Nav Position Matched From Screenshots

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.57 / `APP_VERSION = 2026.07.18-v85.8.57-temu-nav-bottom-offset-22-no-otp-test`.
- User provided side-by-side real-device screenshots for Temu product page and React Orders nav. Image measurement showed Temu's nav top/indicator band around 9-10px higher than Orders.
- Scope: Temu injected bottom-nav vertical placement only. No WebView show/hide changes, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- Fix: lower the Temu nav container from `bottom:-12px` to `bottom:-22px`, preserving the accepted fixed WebView/no-gap behavior and normal `translate3d(-50%,0,0)` transform.
- GitHub iOS build `29658557163` succeeded from code commit `a0d4b0d`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.57-temu-nav-bottom-offset-22.ipa`.
- v85.8.57 IPA SHA-256: `00C83CA2EB2BCB2F506525C5B7AF63BC3D1F697E88358BD690B4E301124AF209`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, injected-script parse plus `bottom:-22px` marker check, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.57 marker/offset checks passed. Real-device acceptance is still required.

## v85.8.56 Temu Bottom Nav Lowered Slightly More

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.56 / `APP_VERSION = 2026.07.18-v85.8.56-temu-nav-bottom-offset-12-no-otp-test`.
- User report after v85.8.55: Temu bottom nav is closer but still needs to move down a little more.
- Scope: Temu injected bottom-nav vertical placement only. No WebView show/hide changes, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- Fix: lower the Temu nav container from `bottom:-8px` to `bottom:-12px` and bump the injected nav style version so the WebView refreshes the inline style.
- GitHub iOS build `29657864109` succeeded from code commit `9674808`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.56-temu-nav-bottom-offset-12.ipa`.
- v85.8.56 IPA SHA-256: `D916588CFE9C45E2C0B5764F18179AE65216EF4DF6D8854770F47E2CD0ED378A`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, injected-script parse plus `bottom:-12px` marker check, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.56 marker/offset checks passed. Real-device acceptance is still required.

## v85.8.55 Temu Bottom Nav Bottom Offset

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.55 / `APP_VERSION = 2026.07.18-v85.8.55-temu-nav-bottom-offset-no-otp-test`.
- User rejected v85.8.54 on real iPhone: Temu bottom nav still looked slightly higher than the React nav in Orders/Cart.
- Scope: Temu injected bottom-nav vertical placement only. No WebView show/hide changes, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- Fix: remove the v85.8.54 Y-transform offset and instead lower the Temu nav container itself with `bottom:-8px`, while keeping `transform:translate3d(-50%,0,0)` so the existing stability CSS no longer fights the alignment.
- GitHub iOS build `29657616560` succeeded from code commit `eb7b0ca`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.55-temu-nav-bottom-offset.ipa`.
- v85.8.55 IPA SHA-256: `52ED888B77AF294970B6CC7E19557131CDC848B3A29D79E4C40B3D3E93FF1F16`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, injected-script parse plus `bottom:-8px` marker check, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.55 marker/offset checks passed. Real-device acceptance is still required.

## v85.8.54 Temu Bottom Nav Bar Alignment

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.54 / `APP_VERSION = 2026.07.18-v85.8.54-temu-nav-bar-lower-no-otp-test`.
- User report after v85.8.53: the whole Temu injected bottom nav still sits slightly higher than the React nav in Cart/Orders, not just the icon/label content.
- Scope: Temu injected bottom-nav vertical placement only. No WebView show/hide changes, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- Fix: remove the v85.8.53 per-icon/per-label downward offset and instead apply one Temu-only `translate3d(-50%,4px,0)` to `#otlobli-nav`, moving the bar, active indicator, icons, labels, and hit area together.
- GitHub iOS build `29657282400` succeeded from code commit `d0c13f4`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.54-temu-nav-bar-lower.ipa`.
- v85.8.54 IPA SHA-256: `00127450AE6E228DE3A07DFDADF71B2788E48071149C44357DF220D21FA0003D`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, injected-script parse, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.54 marker check passed. Real-device acceptance is still required.

## v85.8.53 Temu Bottom Nav Content Alignment

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.53 / `APP_VERSION = 2026.07.18-v85.8.53-temu-nav-content-lower-no-otp-test`.
- User confirmed v85.8.52 fixed the disappearing/blank strip under Temu's bottom nav. Remaining issue: Temu's injected nav content sits slightly higher than the React nav in Orders/Cart.
- Scope: visual alignment of Temu injected bottom-nav content only. No WebView show/hide changes, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- Fix: apply a Temu-only 3px visual downward offset to the injected nav SVG icons and labels, leaving the nav container height, safe-area math, active indicator, and hit targets unchanged.
- GitHub iOS build `29656814832` succeeded from code commit `0009f24`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.53-temu-nav-content-lower.ipa`.
- v85.8.53 IPA SHA-256: `089DE99FED0E44E278CB443323A3C486E5212E0F5A276594B84413D2FD44A8E9`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, injected-script parse, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.53 marker check passed. Real-device acceptance is still required.

## v85.8.52 Temu Bottom Nav Preserve Candidate

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.52 / `APP_VERSION = 2026.07.18-v85.8.52-temu-preserve-webview-nav-no-otp-test`.
- User report after v85.8.51: Temu's bottom navigation still gained a blank/grey strip underneath after navigating to React Orders and back to Home, while the React Orders nav itself looked correct.
- Scope: Temu iOS WebView show/hide + bottom navigation stability only. No Temu header forcing, product/SKU capture, blockers, payment, wallet, orders logic, or account route changes.
- Fix: Temu on iOS now uses the existing native `otlobliPreserveAttachedWhenHidden` path, like SHEIN, so the WKWebView is not detached to a 1x1 hidden container when the user opens Orders/Cart/Profile. This preserves the WebView viewport and `env(safe-area-inset-bottom)` value across Orders -> Home.
- Fix: removed the v85.8.51 Temu-only delayed `__resize` posts after returning home, reducing layout movement/flicker.
- GitHub iOS build `29656122048` succeeded from code commit `92461f2`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.52-temu-preserve-webview-nav.ipa`.
- v85.8.52 IPA SHA-256: `26FC0A8B5C288EE11D7A877A4EB1DABC6DCFB945089EC09398E8F844340E429A`.
- Validation: `npm run build`, `git diff --check`, GitHub build, and embedded v85.8.52 marker check passed. Targeted ESLint against `App.tsx` still reports pre-existing unrelated App lint errors; no new build error was introduced. Real-device acceptance is still required.

## v85.8.51 Temu Native Header Rollback Candidate

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.51 / `APP_VERSION = 2026.07.18-v85.8.51-temu-native-header-resume-gap-no-otp-test`.
- User rejected v85.8.50 on real iPhone: Temu top bar became laggy/stuttery and loading slowed.
- Scope: Temu header rollback + app resume gap only. No payment, wallet, orders logic, account route, SKU/product capture, or blocker redesign changes.
- Change: removed execution and code for the v85.8.49/v85.8.50 Temu header interventions: no header pinning, no category-row forcing/wake, no download-shell collapse, and no empty-gap DOM scan inside Temu.
- Change: on returning from React tabs to Temu home, native posts two delayed `__resize` messages so WKWebView can recalculate layout without touching Temu's header DOM.
- GitHub iOS build `29655425599` succeeded from code commit `aa2f287`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.51-temu-native-header-resume-gap.ipa`.
- v85.8.51 IPA SHA-256: `EEE8BA63452CDACB03AC8FB6502C3DEB97258FDBB9C99BECC9297EB87503FFA6`.
- Validation: targeted ESLint for injected script/config, injected-script parse, `npm run build`, GitHub build, and embedded v85.8.51 marker check passed. Real-device acceptance is still required.

## v85.8.50 Temu Category Header Candidate

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.50 / `APP_VERSION = 2026.07.18-v85.8.50-temu-category-header-stable-no-otp-test`.
- Scope: Temu home header/category only. No payment, wallet, orders, account route, SKU/product capture, or blocker redesign changes.
- Fix: normalize only the verified top Temu home category row and wake its horizontal scroller without vertical pull/scroll nudges, so categories can appear from first entry.
- Fix: collapse only empty top header gaps on Temu home and self-restore them if content later appears, avoiding stuck 0px wrappers.
- Performance: category/gap scans are throttled for low-end iPhones.
- GitHub iOS build `29654853138` succeeded from code commit `471809a`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.50-temu-category-header-stable.ipa`.
- v85.8.50 IPA SHA-256: `F66B240EDCB94EFA278C2C6E611428343BAFABC76A23A678E5E5E4031A6FE8EC`.
- Validation: targeted ESLint, injected-script parse, `git diff --check`, `npm run build`, WebKit fixture for hidden categories + empty header gap, GitHub build, and embedded v85.8.50 marker check passed. Real-device acceptance is still required.

## v85.8.49 Temu SHEIN-Like Header Candidate

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.49 / `APP_VERSION = 2026.07.18-v85.8.49-temu-shein-like-header-no-otp-test`.
- Scope: Temu header only. No payment, wallet, orders, account route, SKU/product capture, or blocker redesign changes.
- Fix: collapse Temu's app-download banner shell and its banner-only ancestors when they do not contain search chrome, so the hidden banner cannot leave the empty white top strip.
- Fix: re-enable only the narrow existing Temu search/header stabilizer to zero the fixed header's Y transform outside active search, matching SHEIN's stable top-bar behavior without broad CSS.
- Validation so far: targeted ESLint, injected-script parse, `git diff --check`, `npm run build`, and WebKit mobile DOM checks for collapsed download shell and unclipped top search. Final acceptance still requires the real iPhone install.

## v85.8.48 Temu Emergency Rollback

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.48 / `APP_VERSION = 2026.07.18-v85.8.48-temu-rollback-47-no-otp-test`.
- User rejected v85.8.47 on real iPhone: Temu product pages became blank white again and the header issue was still not fixed.
- Action: reverted the v85.8.47 SKU-capture changes only, restoring the Temu runtime behavior from v85.8.46, then bumped the app version so the rollback IPA is identifiable.
- Scope: no payment, wallet, orders, account route, header, or blocker redesign changes in this emergency rollback.
- Next real-device check: install v85.8.48 first and confirm product pages no longer become blank white. Do not continue with SKU/header work until this rollback is confirmed.

## Active Baseline

- Branch: `claude/ios6-cover-fix`.
- Stable tested reference: v85.8.5 / `a914d81`.
- Reference IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.5-nav-cairo-font-match-no-otp-test.ipa`.
- Last real-device Temu IPA tested: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.30-temu-no-false-size-gate.ipa`.
- Last tested commit: `dcc2bb5` (`fix: v85.8.30 avoid false Temu size gate`) - no false size gate improved, but some product pages could turn white and text-only color could still be blocked.
- Current local candidate: v85.8.31 / `APP_VERSION = 2026.07.17-v85.8.31-temu-product-panel-color-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.31-temu-product-panel-color.ipa`.
- v85.8.31 build run: `29589915204` (success), built from code commit `81426c7`.
- v85.8.31 IPA SHA-256: `C6E8DA038BC4CB9E7363222E17452F24678B169B6FB729675C5CACFBD937CBCC`.
- Previous iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.30-temu-no-false-size-gate.ipa`.
- v85.8.30 build run: `29587915183` (success), built from code commit `dcc2bb5`.
- v85.8.30 IPA SHA-256: `4804EB86912DAD859BC389819C351ABD74A58795E957286BE36E6FAD4C6DF747`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.29-temu-ram-variant-gate.ipa`.
- v85.8.29 build run: `29586606771` (success), built from code commit `74e2c0f`.
- v85.8.29 IPA SHA-256: `6EB037D772BD6FBF6BB0E2264A61AA323A13E6177FA431EE238CD73A548847C5`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.28-temu-search-preserve-query.ipa`.
- v85.8.28 build run: `29584752961` (success), built from code commit `c7c49d5`.
- v85.8.28 IPA SHA-256: `2AFC1C27164E1023493632323B0F1F7992ACC16B3C6294BB9E7CFE54B97C8BCB`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.27-temu-search-light-blockers.ipa`.
- v85.8.27 build run: `29583256531` (success), built from code commit `d9368b4`.
- v85.8.27 IPA SHA-256: `9B706F650718BA25A7D3E9B61CACB54AAAC873DA492FD5F11CA81866EE2A3826`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.26-temu-clean-blockers.ipa`.
- v85.8.26 build run: `29581021125` (success), built from code commit `e3984fd`.
- v85.8.26 IPA SHA-256: `DD22DFD3CE658E056F652F140B6AEA5FEAC8A5CA1193DDAEEEDE557BA0864C2B`.
- v85.8.19 did not fix Temu: header still has empty white space, search typing is slow/unstable, and the account/login panel can appear over search.
- SHEIN is mostly considered previously stabilized; current work is Temu only unless the user explicitly asks otherwise.

## v85.8.31 Local Temu Changes

- Fixes the real-device report after v85.8.30: some Temu product detail pages could render as a blank white page while Otlobli back/add buttons remained visible.
- Removes the early static hide rule for live Temu `panel/adaptPad`/sign-in/guide classes; those account surfaces are now hidden by the dynamic account-panel cleaner only after geometry/text checks.
- Adds a product-content guard so product panels with price, product text, or large Temu images are never hidden by the account-surface cleaner.
- Allows a clearly selected text-only Temu color such as `اللون: اسود و ابيض` to add without requiring a swatch image; product image fallback still supplies the cart image.
- Validated with targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone-sized fixtures for product-panel visibility, account-panel hiding, and text-only color add, GitHub iOS build `29589915204`, and embedded v85.8.31 marker check.
- Final judgment still requires the real iPhone install; no simulator was used.

## v85.8.30 Local Temu Changes

- Fixes the real-device report after v85.8.29: some Temu products have color/quantity only and no size/RAM/model options, but Otlobli could still show "select size".
- The Temu add gate now blocks on a second option only when real option pills exist or the Temu variant summary explicitly reports more than one second-option choice.
- Text-only single-color products such as `اللون: لون فضي` now pass and capture the color text without requiring a color swatch image.
- Verified v80 (`db7dfb8`) for comparison; it did not include the RAM/memory gate and still used the older broad size-section block, so no v80 code was restored.
- Validated with targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone-sized fixtures for no-size product, text-only color product, and RAM summary gate, GitHub iOS build `29587915183`, and embedded v85.8.30 marker check.
- Final judgment still requires the real iPhone install; no simulator was used.

## v85.8.29 Local Temu Changes

- Keeps the accepted v85.8.28 Temu search behavior unchanged.
- Fixes the product capture gate for Temu products whose option summary includes RAM/memory/storage wording, such as `3 اللون, 1 ذاكرة الوصول العشوائي`.
- The Otlobli add button now treats these summaries as multi-option products and opens/clicks the `حدد` variant row instead of adding directly to the Otlobli cart.
- Extends Temu variant section detection to Arabic/English memory, storage, capacity, RAM, and ROM labels without broad product-page blocking.
- Validated with targeted ESLint, injected-script parse, `npm run build`, a WebKit iPhone-sized product fixture proving add does not post before variant selection, GitHub iOS build `29586606771`, and embedded v85.8.29 marker check.
- Final judgment still requires the real iPhone install; no simulator was used.

## v85.8.28 Local Temu Changes

- Addresses the v85.8.27 real-device report: account/cart/menu and Temu's bottom nav were visible on the search/results screen, and tapping Otlobli back while a query existed could clear the text.
- Adds a narrow search-only visual cleanup that hides compact top account/cart/menu controls and the fixed Temu bottom nav while Temu search mode or a search URL is active.
- Keeps Temu's native search back button and search suggestion text visible; the broad JS text/geometry blocker still skips active search.
- Changes Otlobli search exit so a focused or populated search input is blurred without clearing the query.
- Validated with targeted ESLint, injected-script parse, `npm run build`, a WebKit iPhone-sized search/results fixture for visible native back/suggestions plus hidden account/cart/nav and preserved query, GitHub iOS build `29584752961`, and embedded v85.8.28 marker check.
- Final judgment still requires the real iPhone install; no simulator was used.

## v85.8.27 Local Temu Changes

- Lightens the v85.8.26 Temu blocker while search is active.
- Stops calling the old native-search-back hiding function, so Temu's search back button remains visible.
- Skips the JS text/geometry blocker sweep during active Temu search, so search suggestions/letters containing words like offer/deal/cart/bag are not hidden.
- Keeps the static CSS blocker active, so blockers hidden before search stay hidden.
- Validated with targeted ESLint, injected-script parse, `npm run build`, a WebKit search-mode fixture for visible back/suggestions, GitHub iOS build `29583256531`, and embedded v85.8.27 marker check.
- Final judgment still requires the real iPhone install; no simulator was used.

## v85.8.26 Local Temu Changes

- Rebuilds the active Temu blocker path around one lightweight cleaner: account/login, cart/basket, app-download/open-app, and promo/offer/coupon sheets only.
- Stops calling the old Temu header/search/category forcing stack in the active Temu tick path: no active pinning, restoring, category forcing, logo forcing, broad customer chrome hiding, or login-popup clicking.
- Keeps search inputs, search triggers, category/filter rows, product grids, prices, and image-heavy product content protected from the blocker.
- Fixes a blocker-guard bug where the old "near search input" check climbed to `<body>` and protected unrelated floating offer sheets.
- Removes the old generic distraction list from promo detection so category/nav/menu hints do not hide the category strip.
- Slows the Temu-only cleanup interval to `1200ms` / `1800ms` on low-end devices to reduce heat and layout churn.
- Validated with targeted ESLint, injected-script parse, `npm run build`, an iPhone-6-sized WebKit blocker harness, GitHub iOS build `29581021125`, and embedded v85.8.26 marker check.
- Live Temu in headless browsers redirected to a download, so final judgment still requires the real iPhone install.

## v85.8.25 Local Temu Changes

- Treats v85.8.24 as rejected on real device: search needed multiple taps, the search bar moved while typing, the category strip was half-hidden during search, and the header size broke after exiting.
- Removes the v85.8.24 active search shell/frame marking path and all search-mode CSS that changed `min-height`, `padding-bottom`, `transform`, or `margin-top`.
- Stops restoring/forcing the Temu category strip while Temu search mode is active; category-strip CSS now applies only outside search mode.
- Makes Otlobli search-back robust when tapping the back button steals focus from the input, using a short search-back grace window that is cleared immediately on exit.
- Validated with targeted ESLint, injected-script parse, `npm run build`, a WebKit browser harness for single tap -> type without motion -> Otlobli back -> home, GitHub iOS build `29578629966`, and embedded v85.8.25 marker check.

## v85.8.24 Local Temu Changes

- Rejected on real device. It moved/expanded the search layout and caused multiple-tap search entry, moving search bar while typing, hidden category strip, and broken home size after exit.
- Fixes the latest real-device report after v85.8.23: entering Temu search cut the lower part of the search bar, and returning home could leave the header/category strip compressed or shifted.
- Replaces the previous search-mode `margin-top:18px` with a scoped active search shell/frame: only the nearest search frame gets temporary `overflow:visible`/minimum height, while the search shell is visually lowered with `transform`.
- Adds active-element and last-search-input fallbacks so the active search shell is marked reliably without broad guessing or page-wide CSS.
- On search exit, clears both active shell and active frame markers, restarts a bounded home-header wake window even when the URL did not change, and adds one delayed low-end reset for slower iPhones.
- Validated with targeted ESLint, injected-script parse, `npm run build`, a WebKit iPhone 6-sized clipped-search -> Otlobli-back -> home fixture, GitHub iOS build `29577463207`, and embedded v85.8.24 marker check.

## v85.8.23 Local Temu Changes

- Fixes the real-device report that Temu home looks correct on first entry but the home header/layout breaks after entering search and backing out.
- On Otlobli search-back, the search input is found even after focus moves to the back button, then cleared with `input/search/change` events and blurred.
- Adds a short explicit search-exit suppress window so leftover suggestion overlays cannot keep the page in search mode after returning home.
- Hides only search suggestion/recent/trending overlays created by the search session, and marks them so search/category restoration cannot revive them as category strips.
- Tightens category-strip detection so search/suggest/trending text is never treated as a category strip even if it contains words like women/kids.
- Validated with targeted ESLint, injected-script parse, `npm run build`, a WebKit iPhone-sized home -> search -> back fixture, and GitHub iOS build `29554026083`.

## v85.8.22 Local Temu Changes

- Restores the Temu category strip from first entry by marking verified category containers and applying targeted `display:flex`, instead of relying only on a tiny scroll wake.
- Treats a focused top searchbox as active Temu search even if Temu only opened the keyboard and did not switch route/overlay yet.
- Marks the active search shell and lowers it by 18px during search so it is not pressed against the status/header area.
- Hides Temu's native search back control while search is active; Otlobli back now blurs/cleans search instead of tapping Temu's arrow that opened "Available offers".
- Hides account/login and service-offer distraction sheets on non-account routes, while preserving real Temu account routes when opened intentionally.
- Replaced the iOS splash PNGs with a blank white splash to avoid the blue logo showing in the app switcher/background preview.
- Validated with targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone-sized fixtures for home/search/back/account-route behavior, and GitHub iOS build `29553022990`.

## v85.8.21 Local Temu Changes

- Fixed a WebKit document-start crash where Cairo font injection assumed `document.head` or `documentElement` already existed.
- Deferred the full-script `MutationObserver` until a real document root exists, so Temu protections cannot abort before intervals start.
- Added a first-entry Temu home wake nudge: if the category strip is not visible, dispatch the same tiny scroll/resize path that makes Temu reveal it, then return to top.
- Hid Temu account/login surfaces by observed live classes (`panel/adaptPad`, sign-in rows, account bottom strip) on non-account routes, including redraws during search.
- Kept login hiding targeted and lightweight; no broad 90ms page-wide text scan remains, so search typing should stay responsive.
- Validated with WebKit iPhone-sized Playwright, including a routed Temu fixture that reproduces hidden categories and recreated account panels without using the simulator.
- No payment, wallet, completed-order, or real account-route logic was intentionally changed.

## v85.8.20 Local Temu Changes

- Broadened Temu search input detection to include the live top text field when Temu omits `type="search"`/placeholder metadata.
- Cached expensive Temu search-mode DOM probing for a very short window so typing does not repeatedly scan the whole page.
- Search chrome restoration now avoids walking into account/login panel containers.
- Login/account panel hiding is reapplied while search is active if Temu redraws the same visible panel.
- Home-header forcing no longer scrolls the page back to top and no longer raises the category strip with forced transform/background/z-index.
- No payment, wallet, completed-order, or account-route logic was intentionally changed.

## v85.8.6 Scope

- Keeps v85.8.5 store/VPN/Saudi-address behavior as the base.
- Defers first iOS WebView presentation until its first live page while React's nav remains mounted.
- Uses bundled Cairo in both React and the injected SHEIN nav; no Google Fonts timing shift.
- Shows the native loading cover for every iOS main-frame navigation while leaving Otlobli's nav uncovered.
- Gives slow devices 35 seconds for SHEIN readiness instead of falsely blaming the VPN at 13 seconds.
- Passive security checks remain covered briefly; genuinely interactive verification is revealed after a bounded wait and is never bypassed.
- Hides only a verified SHEIN bottom tab bar. The old generic fixed-bottom hiding path is no longer called.
- Raises only an exact cookie-consent action that would overlap Otlobli's nav.
- Retries only SHEIN's exact feed-error retry action, at most four times, without reload or `setUrl` loops.
- Improves round/HOT swatch capture by ranking nested images and CSS backgrounds while rejecting small badge layers.
- Runtime Service Worker/cache cleanup runs once per SHEIN WebView session, not on every product/back navigation.

## v85.8.7 Changes

- v85.8.6 device result: iPhone 6 still showed SHEIN's five-tab bar under Otlobli's nav during preparation and remained slow; iPhone 16 showed a differently colored safe-area strip below the home nav.
- The document-start bootstrap now finds obfuscated plain-div SHEIN tabs through the visual element stack plus exact tab semantics; no broad DOM/CSS scan was added.
- Only SHEIN's exact compact "added to cart successfully" toast is hidden when it overlaps the app nav.
- Healthy WebKit cache is preserved for the fast path. Cache clearing remains limited to bounded stuck-session recovery and explicit Temu -> SHEIN switching.
- iOS WKWebView now fills the controller bottom; the injected safe-area-aware nav paints the whole inset. Android keeps its native safe-bottom margin.

## v85.8.8 Changes

- Real-device v85.8.7 result: iPhone 16 navigation appearance improved, but the injected home icons sat lower than the React cart/orders/profile icons; iPhone 6 could expose icon-only SHEIN tabs on first entry.
- The injected nav now mirrors React's grid row, direct SVG/label structure, normal line height, and natural content-box height instead of a separate flex/fixed-height layout.
- Document-start hiding adds one narrow fallback: exactly five evenly spaced children inside a fixed/sticky bottom row. It does not hide arbitrary bottom elements.
- A cart product is loaded inside the preserved hidden SHEIN WebView while the React cart stays visible. It is revealed only after the target page load and a blocker-ready message.
- SHEIN readiness is posted only after header/cart/listing/bottom-nav/cookie/toast/install blockers have run for that tick.

## v85.8.9 Changes

- v85.8.8 device result: the injected nav collapsed to content width on an older iPhone WKWebView, stacking all four tabs at the right; the first fresh launch also exited once and the second launch was smooth.
- The injected nav uses legacy-safe Flex again, with four explicit 25% cells and direct icon/label content stretched through the same 73px content row as React.
- The v85.8.8 first-session geometry scan was removed; the proven v85.8.7 semantic tab detector remains. Hidden cart-product readiness remains unchanged.
- Browser layout checks at 375px and 430px confirmed four equal cells across the full width.

## v85.8.10 Changes

- v85.8.9 device result: the fixed nav briefly flashed/brightened once while SHEIN opened.
- Bootstrap, challenge, and hydrated SHEIN navigation now share one canonical CSS string, including safe-area padding, font, background, and blur from the first frame.
- The hydrated script no longer rewrites `cssText` every tick. Reclaiming the nav to the end of `<body>` happens only when four hit-tests prove another layer actually covers it.
- `viewport-fit=cover` is established during document-start so safe-area geometry settles before the native WebView is presented.

## v85.8.11 Changes

- v85.8.10 device result: the user accepted the normal iPhone 16 navigation behavior. On iPhone 6, SHEIN could inject either a compact `15% + Register` strip or a larger email-newsletter registration panel above the app nav after cookie consent.
- Both registration surfaces are now matched by compound semantics plus exact structure. Product discounts and SHEIN's real sign-in/Google form are explicitly excluded; no generic promo CSS was added.
- The exact registration check runs at document start and before the next SPA paint. The newsletter form is found from its email input while still off-screen.
- In SHEIN's full-screen product-photo viewer, Otlobli's add button is hidden and a transparent lower-letterbox guard prevents taps from falling through to an add action.
- The viewer is recognized only as a fixed near-full-screen layer with a large image and `current/total` counter. On opening it, the existing nav and back button reclaim paint order once so old WKWebView cannot paint the viewer over them while leaving their hit targets active.
- v85.8.10 nav CSS, sizing, font, and ordinary-page behavior are unchanged.

## v85.8.12 Changes

- v85.8.11 device result: cookie Accept could sit below Otlobli's nav, the Saudi address surface could remain open after success, gallery/image taps could still capture the product, and the new pre-paint signup scan made iPhone 6 noticeably heavier.
- Cookie consent remains the customer's decision. The exact Accept/Reject action row is raised together above the nav; Otlobli does not silently accept tracking consent.
- A resolved Saudi shipping surface is closed only after SHEIN writes a fully signed Saudi address. Existing URL/storage/address guards continue to detect and repair a later foreign-region change.
- Only an unsolicited login dialog over a product is dismissed. Real login/account routes remain untouched.
- Gallery detection now walks from a few painted points to a nested fixed viewer root. Gallery taps cannot reach native or Otlobli add/cart/wishlist actions; nav/back reclaim paint order on the viewer transition.
- Removed v85.8.11's MutationObserver-to-requestAnimationFrame whole-page signup inspection. Cookie/signup scans are throttled and use six targeted points instead of fifteen, reducing layout work on old WKWebView.
- Fixed srcset whitespace parsing inside the injected script. Temu, payment, wallet, orders, and cart design are unchanged.

## Failed Paths / Guardrails

- v86-v88 are failed paths. v87 fixed none of the reported issues; v88 closed/crashed SHEIN on entry.
- v85.9-v85.11 rejected the user's working VPN. Do not reuse their full document-start capture path.
- Do not reintroduce hidden/offscreen `FAKE_VISIBLE`, broad CSS, viewport-width hacks, wide storage resets, or reload loops.
- Do not change payment, wallet, completed orders, Temu, coupons, or group checkout during this SHEIN pass.
- Use approved Figma designs when supplied; otherwise direct professional code-native design is allowed and must be visually validated.
- `TEST_ONLY_AUTH_BYPASS = true` only for rapid device testing; restore OTP before production.

## Acceptance Test

Test on iPhone 6 and iPhone 16 Pro Max:

1. Otlobli nav is visible from launch and never changes font/size.
2. No raw SHEIN tab bar appears during initial load, product open, back, or app-tab return.
3. Turkey/Germany VPN is not rejected merely because iPhone 6 prepares slowly.
4. SHEIN feed becomes usable without repeated manual retry taps.
5. Cookie consent is tappable above the nav and does not open Orders.
6. Product from cart leaves the React cart visible until ready; no raw product reload/chrome appears; back is smooth.
7. Round/HOT selected color produces the actual color thumbnail in cart.
8. Saudi shipping remains authoritative.
9. After accepting cookies, neither the 15% registration strip nor the email-newsletter panel appears above the nav; real SHEIN sign-in remains usable.
10. In a product photo viewer, add-to-cart is absent, the black lower band cannot add an item, and nav/back remain visibly painted on both phones.
11. Cookie Accept and Reject are both reachable above the nav; rejecting does not leave a forced product-login popup.
12. After Saudi setup completes, the address surface closes; a later foreign-region state is detected and repaired without broad storage clearing or reload loops.
13. On iPhone 6, product images and scrolling remain responsive after cookie consent and repeated product/gallery opens.

## Validation

- Clean `patch-package` reinstall passed; tracked relay keys remain placeholders.
- `npm run build` passed.
- Runtime syntax parse of both injected scripts passed.
- `git diff --check` passed.
- Targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts` passed.
- Full-project lint still has pre-existing unrelated errors in `App.tsx`, Admin, and the payment webhook; this SHEIN change introduced no build error.
- Xcode unsigned build and packaging passed in run `29414121203`.
- Embedded v85.8.11 marker and desktop IPA SHA-256 were verified.
- Xcode unsigned build and packaging passed in run `29416945278`; the embedded v85.8.12 marker and desktop IPA SHA-256 were verified.
# Active candidate — v86.99 persistent startup navigation (2026-08-09)

Frame-by-frame cold-launch recording on the connected SM-N950F / Note 8 found a gap that precedes Java, React, the WebView, and the existing SHEIN loading guard: Android's activity preview was a bare white splash window. That is why the Otlobli tabs could disappear for 1–2 seconds even though later loading layers were correct.

v86.99 makes navigation ownership continuous: the Android 9-and-earlier activity window paints a compact static Otlobli tab strip immediately; `MainActivity` replaces it with a complete native, RTL, labelled strip before Capacitor creates the WebView; the established SHEIN cover keeps its navigation footprint; React dismisses the native surface only after two rendered frames. The static preview intentionally has icons only because it is a system drawable; it exists only for the pre-Java moment and hands off to the labelled native bar without a blank interval. The Android-only bridge is never called on iOS.

No iPhone recompose timing, Android resume defense, region rebuild guard, SHEIN script size, cart behavior, or human-check behavior changed. Production build, iPhone-freeze guard, performance budget, Android/iOS sync, Android debug build, install, and a final 5-fps Note 8 cold-start recording passed. Android 86.99/959 APK: `android/app/build/outputs/apk/debug/app-debug.apk`, 12,574,241 bytes, SHA-256 `89680514B56FE6FD14992079A2B66D85BFA84CABD9E6BC8B99D7EA050E9D0BA9`. The real iPhone 16 cold launch plus five background/resume cycles remain required before iOS acceptance.
# v86.135 — تيمو مقفول على متجر السعودية (2026-08-11)

- تيمو لا يعتمد `country=SA` أو المسار `/sa/` وحدهما؛ منطقة المتجر الحقيقية تأتي من كوكي `region`. على النوت 8 كان `region=165` (قطر) رغم كل إعدادات السعودية.
- إعداد تيمو المنشور في الصفحة (`window.__REGION_CONFIG__`) يثبت أن السعودية رقمها الداخلي `174`. السكربت يكتب الآن `region=174` عند `documentStart` ويعيد التحميل مرة واحدة فقط إذا كانت الاستجابة قد وصلت بمنطقة أخرى، مع حارس يمنع حلقة إعادة التحميل.
- قفل تيمو أصبح `SA` ثابتاً ولا يتبع VPN أو إعداداً بعيداً قديماً. العملة بقيت مستقلة `USD` كما كانت.
- تحقق فعلي على Galaxy Note 8 بعد تثبيت `86.135/995`: العنوان `Temu Saudi Arabia`، الكوكي `region=174`، التخزين `country=SA`، واللغة `ar-SA` رغم أن منطقة زمن الجهاز/خروج الاتصال ما زالت قطر.
- نجح: حارس تجمد iPhone، بناء الويب وميزانية الأداء، مزامنة Android وiOS، و`assembleDebug`. لم يُبنَ IPA ولم تُنفّذ دورات قبول iPhone 16.
- APK: `android/app/build/outputs/apk/debug/app-debug.apk`، SHA-256: `A59EB096A2D235CA32920EA8BB05FF7694FFAE6C6FFFA930AD9BE6419C042A4B`.
# v86.165 — سعر الصرف الحي بالليرة السورية الجديدة (2026-08-12)

شُخّص العطل بالأرقام: مصدر `sp-today.com/en` يعرض الآن Buy `131.20` / Sell `131.70` بالليرة الجديدة، وخادم أوراكل `GET https://84-8-100-128.sslip.io/api/exchange-rate` يعيد `131.7` من `sp-today.com`، وSupabase `app-settings` يعيد `usd_to_syp_rate=131.7` و`syp_denomination=new`. كان العطل في عميل v86.164: كاتبا السعر في `App.tsx` يقبلان فقط ما فوق 1000، فيرفضان السعر الحي الصحيح ويبقيان الوحدة القديمة.

أصبح العميل يقبل سعر الدولار الموجب دون 1000 فقط، وهذا **فحص لسعر الدولار الواحد وليس سقفاً للطلب**. فحص `npm run verify:live-syp-rate` أثبت أن طلب `$1,000` يتحول إلى `131,700` ل.س ولا يُرفض. الحد الأدنى للطلب صار `5,000` ل.س جديدة؛ لا يوجد حد أقصى 1000. القيمة `131.7` في env احتياط عند انقطاع المصدر فقط، والتطبيق يطلب السعر الحي من أوراكل كل 30 دقيقة أثناء ظهوره، وSupabase احتياط عند فشل أوراكل. السلال القديمة ذات `priceSyp` بوحدة ×100 تُصلح مرة واحدة من `priceUsd`.

وُحّدت القيم الاحتياطية في التطبيق/الإدارة/Edge/Oracle/GitHub وأضيفت هجرتا `20260810160000_payment_intent_nudge_window.sql` و`20260810170000_syp_redenomination.sql` لمطابقة الحالة الحية. الإنتاج محوّل أصلاً؛ الهجرة idempotent ولم تُعد تقسيم البيانات. لم يُنشأ طلب إنتاج أو حوالة شام كاش في هذه الدفعة.

ثُبتت `86.165-personal-live-syp/1025` على Note 8 فوق النسخة القديمة دون مسح البيانات. CDP أثت طلب أوراكل `[200]`، طلب `app-settings` `[200]`، و`talabieh.exchangeRate=131.7`؛ سلتا SHEIN/Temu بقيتا محفوظتين. APK: `output/otlobli-v86.165-temu-personal-arm64-debug.apk`، `205,028,564` بايت، SHA-256 `8CB8ADB246E5E2161D43E18CA1372D716DE9FF32D96B8AA4F76751D18DD22C09`. القياسي: `output/otlobli-v86.165-standard-universal-debug.apk`، `11,129,572` بايت، SHA-256 `C729CA8528A06A6F085EE880AA96D8D01C391E0833287C52258BF8D2FB5BE7A7`.

نجح البناء القياسي/الشخصي/الإدارة، Android القياسي/الشخصي، مزامنة Android/iOS، حارس SHEIN، وميزانية الأداء: JS `1,085,592/1,200,000`، gzip `287,451/370,000`، CSS `69,766/70,000`، سكربتات المتجر `456,288/470,000`. iOS متزامن `86.165/1025` لكن لم يُبن على Xcode ولم تُنفذ دورات iPhone 16 الخمس/التشغيل البارد. مهمة GitHub Actions الاحتياطية ما زالت تفشل لغياب `SUPABASE_URL` و`SUPABASE_SERVICE_ROLE_KEY`؛ أوراكل هو الكاتب الحي العامل ولا توجد نسخة محلية آمنة لمفتاح service-role لإصلاح الاحتياط دون معلومات اعتماد.
# v86.238/1103 — Temu Android 15/16، إرشاد المنتقي، ومرشح TestFlight (2026-08-25)

اعمل فقط داخل
`C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` على الفرع
`codex/otlobli-v86-212-testflight-auth`. الإصدار القياسي Android/iOS هو
`86.238 (1103)` وGecko manifest هو `1.3.22`. شجرة العمل الحالية تجمع إصلاحات
Temu وهوية جلسة المتجر من الدفعات السابقة؛ لا تُستبدل من فرع قديم.

التشخيص الحي فصل كثافة Temu الأصلية عن عطل المضيف. صفوف البحث والتصنيفات
والمزايا والثقة والبانرات والشبكة محتوى Temu أصلي. على A53/Android 16 ظهر
خطأ Otlobli محدد: AppBar الفارغ الخاص بـTemu أخذ inset شريط الحالة مرة ثانية،
فبدأ WebView عند `y=175` بدل `y=87`، بينما بدأ الشريط السفلي عند `y=2012`؛
أي حجز علوي زائد `88px`. الإصلاح يجعل `topMargin=0` فقط عندما تكون جلسة
Temu ذات الشريط الأصلي و`toolbarType="blank"`. Note 8/Android 9 بقي على
WebView `[0,63][1080,1858]` والشريط يبدأ عند `1858`.

حجب إجراءات Temu وتهيئة الموافقة أصبحا document-start في Android القياسي،
بقائمة محددات ثابتة وعمل محدود، بلا `MutationObserver` أو `setInterval` أو
مسح DOM واسع. التحقق البشري الحقيقي لا يُحجب ولا يُنقر أو يُحل تلقائيًا.
الحارس الخفيف للتنقل يستخدم علم challenge موجودًا ومسارات تحقق محددة؛ لا
يربط شجرة SHEIN/Temu المصغرة ولا يحجب بحثًا أو منتجًا لمجرد احتواء الرابط
على كلمة `challenge`.

عند دخول Temu أو SHEIN يظهر تلميح أصلي أحادي بعد `700ms`:
`انقر «الرئيسية» مرتين لفتح قائمة المتاجر`. النقرة الأولى تعرض
`انقر مرة ثانية لفتح قائمة المتاجر`، والنقرتان خلال `320ms` تفتحان
`store-select` فقط؛ لا يحدث تبديل تلقائي. TalkBack/VoiceOver يفتح المنتقي
بتفعيل مقصود واحد. التلميح خارج WebView، مؤقت، يُلغى عند الإخفاء أو التحقق،
ويُعاد تسليحه عند إظهار جلسة iOS المركونة إذا لم يكن قد ظهر. لم يُضف شريط
داخل Temu أو مؤقت دائم أو مسح DOM.

أدلة Note 8 السابقة ضمن هذه النسخة تثبت زر Temu
`[706,1666][1044,1795]` وفراغ `63px` حتى نهاية WebView، وفتح Temu خلال
`0.8–1.5s` بلا وميض زر Temu الأصلي، وفصل تبويبي السلة `TEMU=3` و`SHEIN=2`.
لكن الهاتف انفصل قبل تثبيت APK النهائي بعد إضافة تلميح الدخول؛ أوامر ADB
المنفصلة لم تحقق نافذة `320ms`. لذلك لا يُدّعى قبول نهائي للنقرتين أو اختيار
SHEIN بعد المسار أو ملفات الارتباط النظيفة على هذا الأثر. الدليل في
`artifacts/device-captures/v86.238-note8/ACCEPTANCE.md`.

APK القياسي النهائي:

- `artifacts/release-86.238/Otlobli-86.238-1103-release.apk`
- الحجم `4,110,560` بايت.
- SHA-256 `A123FFA957EFFAB8FEC44CDABC0C37B5CD9EB09166C00326A6F8581ECC0E61B9`.
- `minSdk 24` و`targetSdk 36`، والتوقيع v3 بشهادة Otlobli ذات SHA-256
  `e0b0f44cc677888f9535c01c9125077e09b014bdb9096dc2813e3bd06f17f784`.

ثُبّت الأثر النهائي على محاكي Android 15/API 35 كتحديث، وأقلع إلى شاشة
الدخول بلا fatal أو ANR. لم تُمسح بيانات Note 8. النسخة الشخصية الكبيرة
استُخدمت للتحقق من الميزانية فقط ولم تُسلّم أو تُنسخ إلى مجلد الإصدار.
نجح البناء الشخصي والقياسي، TypeScript، Java، كل حواجز الإصدار، ومزامنة
Android/iOS. الميزانيات من دون رفع سقف: startup/largest JS
`669,808/720,000` و`/1,200,000`، JS gzip `298,229/370,000`، CSS
`69,932/70,000`، الخطوط `81,364/100,000`، نصوص المتاجر
`316,976/470,000`، Gecko `172,005/180,000`، ومصدر المتجر
`580,141/600,000`. النص المصغر منفصل: SHEIN `146,069` وTemu `170,907`
بايت.

لم تتغير المنطقة أو الجلسة التجارية أو الدفع أو الطلبات أو المحفظة. بقيت
`otlobliForceRecompose()` وتأخير `appDidBecomeActive` البالغ `0.25s` ودفاع
Android resume ومقارنة المناطق عبر `JSON.stringify`. iOS متزامن. شُغّل مسار
TestFlight على commit `a53fbf9` ثلاث مرات: `32886967159` و`32887220144` و
`32887640272`. توقفت كلها قبل تثبيت الشهادات أو بناء IPA أو الرفع لأن فحص
الصحة أعاد `whatsappConnected=false`. لم يُتجاوز الحارس، ولم يُرسل App Review.
يلزم إعادة ربط مرسل WhatsApp ثم إعادة `upload-and-distribute`. لم تُنفذ خمس
دورات iPhone 16 أو cold launch.

# v86.239/1104 — استقبال رمز واتساب بأفضل دعم نظامي متاح (2026-08-25)

أُنجز المسار من دون الانتقال إلى WhatsApp Business Platform ومن دون صلاحية
قراءة الإشعارات أو الحافظة في الخلفية. في شاشة OTP بقيت الخانات الست كما هي،
لكن الخانة الأولى تقبل الآن الرمز الكامل الذي يمرره iOS أو لوحة المفاتيح
(`type="text"`, `inputMode="numeric"`, `autocomplete="one-time-code"`، واسم
ومعرّف ثابتان). يوزع التطبيق القيمة على الخانات الست ويتحقق تلقائيًا. كان
`maxLength=1` على الخانة الأولى يقص الاقتراح إلى رقم واحد. كذلك أصبح اللصق
الصريح يمنع الإدخال الافتراضي ويُعالج مباشرة؛ أزيل `setTimeout(0)` الذي كان
يمكن أن يعالج الرمز مرتين. لا يوجد `navigator.clipboard.readText` أو قارئ
إشعارات أو polling أو listener عام أو WebOTP.

رسالة الخادم أصبحت تُبنى بدالة نقية تتحقق من ستة أرقام، وتضع الرمز مرة واحدة
بوصفه التسلسل الرقمي الوحيد في السطر الأول:
`رمز التحقق لتطبيق Otlobli هو: 123456`. هذا يحسن الاكتشاف الاستدلالي من
إشعار واتساب، لكنه ليس ضمانًا رسميًا على Android أو iOS؛ الضمان الموثق لرسائل
WhatsApp يتطلب مسار قوالب المصادقة الرسمي من Meta، بينما Baileys ورسالة
واتساب العادية يعتمدان على تعرّف النظام/لوحة المفاتيح.

نُشر ملفا الخادم فقط على Oracle في `/home/ubuntu/otlobli-server` بعد مقارنة
أثبتت أن الملف الحي يختلف عن المصدر بهذين التعديلين فقط. النسخة الاحتياطية:
`/home/ubuntu/otlobli-server/backups/pre-v86239-20260825T195204Z`.
تطابقت SHA-256 الحية والمحلية: `whatsapp.js`
`8854E6A7CFBBEFE02CFC1DC728643750D3352AD725866E25FE4D4B730FC5D65F`،
و`otpMessage.js`
`F37411D9049B62EB584E54C9D6C8480EB1580C64418172DE394456FDA0295F28`.
أعيد تشغيل `otlobli-wa` وبقي online، والصحة تعيد `status=ok` و
`sessionStoreReady=true` و`otpSecurityReady=true`. قبل TestFlight كانت الجلسة
`0` محفوظة وخاملة بلا QR وبلا حظر أو نقاط خطر؛ أُعيد وصلها عبر مسار الإدارة
المحمي من دون حذف الملفات أو إنشاء جلسة. الصحة النهائية بعد الرفع تعيد
`whatsappConnected=true` و`whatsappSenderReady=true` و
`whatsappCredentialsPresent=true`. لم يُرسل رمز اختبار إلى رقم عميل، لذلك
الاتصال والجاهزية مثبتان لكن وصول الرسالة/اقتراح لوحة المفاتيح على هاتف حقيقي
يبقيان اختبار قبول منفصلًا.

Android وiOS متزامنان ومُرقمان `86.239 (1104)`. نجح `npm run build` بكل
حواجز الإنتاج/الأسرار/SHEIN/Temu/الأداء، واختبارات OTP والخدمات، وفحص صياغة
الخادم، وGradle release APK+AAB. نجح ESLint المحدد بلا أخطاء؛ `npm run lint`
الكامل ما زال يفشل بثلاثة أخطاء قديمة غير مرتبطة في
`src/services/sheinNavigationScript.ts` ولم تُمس حفاظًا على نطاق المهمة.
ميزانيات الأداء من دون رفع سقف: JS `669,924/720,000`، gzip
`298,255/370,000`، CSS `69,932/70,000`، الخطوط `81,364/100,000`، نصوص
المتاجر `316,976/470,000`، Gecko `172,005/180,000`، ومصدر المتجر
`580,141/600,000`.

آثار الإصدار:

- `artifacts/release-86.239/Otlobli-86.239-1104-release.apk`، الحجم
  `4,110,593` بايت، SHA-256
  `55F045753739087B03BE6B7D394D07D6E135D7A16626EA0C01864EED1F86DACB`.
- `artifacts/release-86.239/Otlobli-86.239-1104-release.aab`، الحجم
  `5,770,899` بايت، SHA-256
  `FE987CAB470FDE3271A31AEE21EE06999A7DE000D82A524E6784945D0CE23C3F`.
- APK موقّع v2/v3 بشهادة Otlobli ذات SHA-256
  `e0b0f44cc677888f9535c01c9125077e09b014bdb9096dc2813e3bd06f17f784`،
  وثُبّت وأُطلق على `emulator-5554` Android 15/API 35 بلا fatal/ANR؛ لقطة
  الإقلاع في `artifacts/device-captures/v86.239-emulator/launch.png`.

دُفعت الدفعة إلى GitHub في commit
`8624f59d712df7e07a743f1853e53ee014891a03`. نجح تشغيل GitHub Actions
`32892860453` خلال `7m33s`: تجاوز حارس مصادقة TestFlight مع واتساب متصل،
وبنى أرشيف App Store الموقّع و`otlobli-v86.239-build-1104-testflight.ipa`،
وتحقق منه ورفعه بلا أخطاء. رقم تسليم Apple
`52f69212-271d-4564-8b60-48368e161b59`. أصبح البناء `VALID` ثم
`IN_BETA_TESTING` داخل مجموعة `Otlobli Internal` ذات وصول all-builds، وتأكدت
عضوية المختبر بحالة `INSTALLED`. لم يُرسل App Review؛ الخيار كان `false`.
أثر GitHub الموقّع رقم `9580341324`، حجمه المضغوط `25,250,769` بايت، و
SHA-256 للأرشيف
`60BED115072CCDBC15F000E91296D87E2F6835C4B846C3109548FAF805FE7F2F`.

لا يوجد Note 8 أو A52 أو iPhone حقيقي متصل، لذا نجاح TestFlight لا يساوي
قبول الجهاز أو خمس دورات iPhone 16. لم تتغير SHEIN أو المنطقة أو جلسات
المتاجر أو التحقق البشري أو الدفع أو الطلبات أو المحفظة. بقيت
`otlobliForceRecompose()` وتأخير `appDidBecomeActive` البالغ `0.25s` ودفاع
Android resume ومقارنة المناطق عبر `JSON.stringify` بلا تغيير.

# v86.240/1105 — تثبيت وجهة الرئيسية وتصميم السلة وفراغ Temu على iOS (2026-08-26)

ثُبت سبب فتح Temu بعد الخروج منه: جلسة WebView كانت تُركن بصورة صحيحة عند
العودة إلى قائمة المتاجر، لكن الضغط على «الرئيسية» من السلة أو الطلبات كان
يحوّل شاشة React إلى `home`، فيعيد تأثير العرض إظهار الجلسة المركونة. أصبحت
وجهة Home المضيفة مرجعًا خفيفًا منفصلًا عن `selectedStore` ومالك WebView.
الخروج إلى المنتقي يثبت الوجهة `store-select`، بينما دخول متجر صريح أو تنقل
صادر من متجر يثبتها `home`. لا تُغلق الجلسة عند المنتقي؛ اختيار المتجر نفسه
يعيد الجلسة، واختيار متجر آخر يبقي مسار الإغلاق المتسلسل القائم بلا تغيير.
أضيفت اختبارات نقية لـ`resolveHostNavigationTarget` وحُدث حارس السطح.

أُعيد تصميم السلة بألوان Otlobli الخضراء: مبدّل موحد، بطاقات أخف بلا الظلال
الكبيرة، عنوان من سطرين، عداد كمية ثابت الشبكة ومحاذى في الوسط، وشريط دفع
مضغوط بصف واحد وزر `44px`. نجحت معاينة Playwright على `320×844` و
`390×844`، وأدلتها في `output/playwright/cart-320x844.png` و
`output/playwright/cart-390x844.png`.

فراغ Temu الأبيض على iOS كان ناتجًا عن استثناء مقصود قديم: بعد إخفاء
`downloadUI` بقي غلاف تنزيل فارغ بنحو `60dp` كي يحجز صفًا لزر الرجوع، مع أن
الزر Native overlay والـsafe area محجوز أصلًا. صار كاشف الغلاف المحدود نفسه
يعمل على Android وiOS في Home فقط، ولا يطوي الغلاف إلا بعد إثبات أنه لا يحتوي
بحثًا، وضمن حدود العمق والحجم والموضع القائمة. تصحيح transform للرأس اللاصق
بقي Android فقط. لم يضف مؤقت أو observer أو `querySelectorAll` أو مسح DOM.

نجح `npm run build` بكامل اختبارات الإصدار والأمان والحواجز، وTypeScript،
وESLint المحدد بلا أخطاء. الميزانيات بلا رفع سقف: startup/largest JS
`670,139/720,000` و`/1,200,000`، JS gzip `298,417/370,000`، CSS
`69,985/70,000`، الخطوط `81,364/100,000`، نصوص المتاجر
`317,333/470,000`، Gecko `172,005/180,000`، ومصدر المتاجر
`580,582/600,000`. تزامن Android وiOS، وتطابقت SHA-256 لحزمة JavaScript
الرئيسية في `dist` والمشروعين الأصليين.

بُني APK وAAB موقّعان، وتحقق APK بـv2/v3 وشهادة Otlobli المتوقعة:

- `artifacts/release-86.240/Otlobli-86.240-1105-release.apk`، الحجم
  `4,110,723` بايت، SHA-256
  `F8E4C7429AF2AE47383102631CE87E3556D308395152DFA84049C923C7FB75BF`.
- `artifacts/release-86.240/Otlobli-86.240-1105-release.aab`، الحجم
  `5,771,013` بايت، SHA-256
  `04313B8ED0435AE106CD70361F1028321B72E9BA4019DD56787F65A65F82FA30`.

ثُبت `86.240 (1105)` كتحديث يحفظ البيانات على Note 8 الحقيقي
`SM-N950F`، وضُبط إطفاء الشاشة على `120000ms` كما طلب المستخدم. نجح فعليًا
`المنتقي ← طلباتي ← الرئيسية` و`المنتقي ← السلة ← الرئيسية` وبقيا على
المنتقي، وفُتح Temu الحي، وظهر تصميم السلة الجديد ببيانات الجهاز بلا fatal أو
ANR أو OOM. أُعيد تثبيت الناتج النهائي نفسه بعد آخر تغطية لمسار المصادقة،
وأُعيد المساران عليه؛ تؤكد اللقطتان `102-final-home-after-orders.png` و
`104-final-home-after-cart.png` بقاء المنتقي، وتوثق `103-final-cart.png`
السلة النهائية. الأدلة في
`artifacts/device-captures/v86.240-note8/`. لا يُدعى
قبول النقرتين آليًا لأن كل `adb input tap` استغرق نحو `534ms`، متجاوزًا نافذة
`320ms` اليدوية. لا يوجد قبول iPhone فعلي بعد.

دُفع commit `b7623e538942187db6ce0b33c9d6e1302d350b01`. محاولة TestFlight الأولى
`32905062307` توقفت بأمان قبل التوقيع لأن مرسل واتساب المخزن كان منفصلًا.
أُعيد توصيل الجلسة `0` من بياناتها المخزنة عبر نقطة الإدارة المحلية المحمية؛
لم تُمسح الجلسة ولم يولد QR أو تُرسل رسالة. أعطت الصحة بعدها
`whatsappConnected=true` و`whatsappSenderReady=true` مع الجلسة وتخزين OTP
جاهزين. نجح التشغيل الثاني `32905392346` خلال `8m43s`: تحقق IPA الموقّع
`com.otlobli.app 86.240/1105` ورفعته Apple برقم تسليم
`0470dc1f-5a1e-4b1f-918c-4e09c6b3de9e`. صارت النسخة `VALID` ثم
`IN_BETA_TESTING` في مجموعة كل النسخ `Otlobli Internal`، وتحققت عضوية المختبر
بحالة `INSTALLED`. بقي App Review معطلًا وتُركت خطوة الإرسال للمراجعة.

أثر GitHub `9584831793` اسمه
`otlobli-ios-v86.240-build-1105-testflight`، حجمه `25,250,403` بايت وبصمة
أرشيفه SHA-256
`70AF49A8D40B20D68130B1555620E61947B9DE2F57B7B11AABAB74D9698DF409`.
الـIPA المنزّل في
`output/testflight-v86.240-build-1105-run-32905392346/otlobli-v86.240-build-1105-testflight.ipa`
حجمه `10,543,182` بايت وSHA-256
`0F1382E07C4E7ABC4C011DE90F9A2CE8048433CB4CF4B6B1F6D90696A898E382`.

لم تتغير SHEIN أو المناطق أو التحقق البشري أو الدفع أو الطلبات أو المحفظة.
بقيت `otlobliForceRecompose()` وتأخير `appDidBecomeActive` البالغ `0.25s`
ودفاع Android resume ومقارنة المناطق عبر `JSON.stringify` بلا تغيير.
