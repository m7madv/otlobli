# ملخّص الجلسة — otlobli (2026-07-30)

## v86.21 — إصلاح سعر اللون/المقاس المحدد في SHEIN

- الصورتان أثبتتا السبب: SHEIN كان يعرض للون `أخضر عسكري` والمقاس `L` سعراً حياً `$17.19`، لكن الجذب أخذ `$11.15` من عرض JSON الافتراضي للمنتج قبل قراءة سعر التركيبة المختارة.
- صار الجذب يقرأ سعر رأس المنتج الظاهر أولاً، ويستبعد السعر المشطوب `$21.84` ونسبة `-21%`. ينتظر قراءتين متطابقتين بعد توقف اللمس حتى لا يرسل السعر القديم إذا غيّر SHEIN السعر بعد اختيار اللون بقليل. JSON يبقى احتياطياً فقط إذا لم يوجد سعر حي.
- لم أغيّر منطق الخيارات الذي استُعيد في v86.20. الاختبارات أثبتت `$17.19 · L` في الحالة المطابقة للصورة وتحديث السعر المتأخر، وأبقت `M / CP1` و`M / 1PC` وتغيير `M→L` صحيحة، ومنعت الإضافة بلا اختيار.
- نجح حارس التجمّد والأداء والبناء ومزامنة Android/iOS وGradle وGitHub/Xcode run `30519999113`. APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.21-shein-live-sku-price-fix-debug.apk`، SHA-256 `4A0A81EB64FCFE88A0BB633A8D5C5044D54E9FD60C4BF94384F3BB78581BFF1E`.
- IPA غير موقّع: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.21-iphone16-unsigned.ipa`، SHA-256 `F406AD5B7901478E725A14F988B7CBEDD1558D9832D951235CEDACE43277B966`. فحصه أكد `86.21/881` وعلامات السعر وإصلاح التجمّد. لا يوجد Android متصل، واختبار المنتج الحقيقي ودورات iPhone 16 ما زال مطلوباً.

## v86.20 — إلغاء تراجع جذب خيارات SHEIN

- أكدت المقارنة أن v86.19 عمّمت إصلاح منتج واحد على كل المنتجات: كانت تقرأ أقرب زر من `الكمية / مقاس` حتى لو كان افتراضياً أو قديماً، ولذلك أمكن أن تضيف بلا اختيار أو تبقى على `M` بعد اختيار `L`.
- أعدت جذب كل المنتجات ومسار السعر إلى كود v86.18 الذي كان يعمل. الإصلاح الجديد لا يعمل إلا للاستثناء الأصلي: عندما يكون `1PC` محدداً فعلياً ويوجد مقاس محدد فعلياً داخل حاوية الخيارات نفسها، يكمل السطر إلى `M / 1PC` أو يحفظ `M / CP1` الظاهر في نفس الاختيار.
- اختبار متصفح حقيقي أثبت: بلا اختيار لا توجد إضافة، المنتج العادي يلتقط `L`، المنتج المركب يلتقط `M / CP1`، وتغيير المقاس إلى `L` يلتقط `L / 1PC`. لم تتغير حماية `addressCookie` أو المنطقة أو إصلاح تجمّد iPhone.
- نجحت حراسة التجمّد والأداء، البناء، مزامنة Android/iOS، وبناء APK. ملف Android: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.20-shein-variant-regression-fix-debug.apk`، SHA-256 `EE74578B350CF53BB89119991235E3A748790B2EDEC442C4EADC1961DDF9E81F`.
- نجح GitHub/Xcode run `30497128620`. ملف iPhone غير الموقّع: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.20-iphone16-unsigned.ipa`، SHA-256 `9D5CCB2976A5B63C2CA0A55287D4F89CCF8318B2F2FE33EC02D4DDE749223AEB`. فحصه أكد `86.20/880` وعلامات الإصلاح والتجمّد، بلا provisioning/signature. لا يوجد جهاز Android متصل، واختبار iPhone الحقيقي ما زال مطلوباً.

## v86.19 — تسجيل الأرقام الجديدة، مقاس SHEIN المركّب، وتتبع الطلب

- سبب فشل الرقم الجديد بعد إدخال الرمز الصحيح كان في قاعدة البيانات لا في الرمز: الحساب القديم موجود فيتجاوز الإنشاء، أما الحساب الجديد فيستدعي دالة تدقيق اسم لم تُنشأ أبداً عبر migration. أضفت migration وطبقتها على Supabase، ثم نجح مسار إنشاء عميل جديد داخل اختبار transaction تم التراجع عنه بلا ترك بيانات تجريبية.
- إذا جُرّب رقم جديد سابقاً وفشل، يجب طلب رمز جديد مرة واحدة. أضفت أيضاً حماية في مصدر خادم واتساب تعيد فتح الرمز الصحيح عند فشل حفظ الجلسة، لكنها ما زالت source-only لأن وصول نشر Oracle غير متاح في هذه المهمة؛ إصلاح قاعدة البيانات المسبب للمشكلة منشور فعلياً.
- أصلحت منتج SHEIN المرفق: عندما يعرض الزر `M / CP1` لكن عنصره الداخلي يعلن `1PC`، صار الالتقاط يأخذ النص المرئي الكامل. اختبار متصفح حقيقي التقط `M / CP1` حرفياً وأبقى `addressCookie` الموقّع، لذلك لم تُضعف حماية المنطقة أو زر السلة.
- أعدت ترتيب بطاقات منتجات التتبع حتى لا تدخل فوق رأس الطلب أو فوق بعضها. نجح القياس والمراجعة البصرية على عرضي 320 و430 بكسل بلا تداخل أو تمرير أفقي، مع ظهور `متعدد الألوان · M / CP1 · ×1` كاملاً.
- نجحت حراسة تجمّد iPhone، حراسة الأداء، بناء الويب، مزامنة Android/iOS، بناء Android، وبناء iOS عبر GitHub run `30493537125`. لم تتغير أوقات `otlobliForceRecompose` أو burst resume.
- APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.19-auth-variant-tracking-fix-debug.apk` — SHA-256 `92BCF3B2533FAFA7E3DA3E063E5D8339B708B9DF6D51F1720D98109E5B741239`.
- IPA غير موقّع: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.19-iphone16-unsigned.ipa` — SHA-256 `223DBA03AE55B6A2CC7FB945E2E979A3DD498720A74CE70B2C1FC4485664941E`. فحصه أكد `com.otlobli.app` و`86.19/879` وعلامات الإصلاح والتجمّد. لا يوجد جهاز Android متصل، واختبار iPhone الحقيقي ما زال مطلوباً.

## v86.18 — تشخيص حقن قلب منطقة SHEIN

- اختبار iPhone 16 الحقيقي أثبت أن v86.17 لم يحل أول دخول للمنتج، لذلك لم نعدّل selectors عشوائياً. ظهر خلل بنيوي قبل DOM: شريط Otlobli يُحقن عند بداية المستند، لكن سكربت المنطقة الكامل يعتمد على `browserPageLoaded`، وكان أول event يُرفض إذا وصل `id` قبل تخزينه في React.
- v86.18 يعتمد معرّف أول WebView singleton بدل إسقاطه، ثم يرسل telemetry خفيفة من WebView إلى React لكل مرحلة حاسمة: الحقن، route، tick، prime، repair/cooldown، الغطاء وz-index، زر الشحن، درج المناطق، `addressCookie` وتوقيعه، النجاح أو timeout.
- آخر 80 حدثاً فقط متاحة في `window.__OTLOBLI_SHEIN_REGION_DIAGNOSTICS__` وفي console بالبادئة `[otlobli][shein-region]`. لا توجد واجهة تشخيص تغطي المستخدم، ولا polling دائم؛ مؤقت تفريغ الرسائل يتوقف خلال 5 ثوانٍ.
- حماية السلة ما زالت تعتمد على `sheinSignedSaudiAddressReady()`، وإصلاح تجمّد iPhone 16 ومسار Android resume وحارس إعادة بناء المنطقة لم تتغير. لا يجوز وصف المشكلة بأنها محلولة قبل اختبار iPhone الحقيقي ورؤية سلسلة الأحداث.
- نجح TypeScript والبناء الإنتاجي وحارسا التجمّد والأداء ومزامنة Android/iOS وبناء Android. ملف APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.18-shein-region-injection-diagnostics-debug.apk`، وبصمته `5A143E2038E61508FD4E6D15A6B3E105AB04557572CE8DCF08303C5BB9CF6070`. لم يكن هناك جهاز Android متصل للاختبار.
- نجح بناء iPhone عبر GitHub/Xcode في run `30489996516` من commit `5e68790`. ملف IPA غير الموقّع: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.18-iphone16-unsigned.ipa`، وبصمته `99BA19D125568162F8AB4601148375080FCBB8825755F724332EEC1CD7AEC41F`. فحص الحزمة أكد `86.18/878` وعلامات التشخيص والحقن و`otlobliForceRecompose`، لكنها تبقى بحاجة للتوقيع والاختبار الحقيقي على iPhone 16.

## v86.17 — إصلاح أول دخول لمنتج SHEIN وإخفاء تبديل المنطقة

- عالجت المشكلة الجديدة بعد v86.16: على iPhone 16 بعد حذف/تثبيت التطبيق، أول دخول لمنتج SHEIN كان ممكن لا يبدأ قلب المنطقة إطلاقاً. صار السكربت يتعرف على صفحة المنتج من الرابط نفسه، وليس فقط من عناصر الشحن بعد ما تظهر.
- صار أول منتج يطلق تهيئة المنطقة فوراً حتى لو SHEIN لم يرسم سطر الشحن بعد، وهذا يمنع حالة “تصفحت دقيقتين وما صار شيء”.
- إذا رابط المنتج لا يحمل الدولة/العملة/اللغة المطلوبة أو يحمل دولة قديمة، يعمل التطبيق reload واحد فقط للرابط المطبّع، بدون loop، ثم يكمل اختيار المنطقة الداخلية عبر SHEIN حتى يحصل على `addressCookie` الموقّع.
- أضفت غطاء خفيف داخل WebView يخفي درج/خطوات تبديل المنطقة عن المستخدم، مع بقاء شريط Otlobli السفلي ظاهراً فوقه. هذا ليس الغطاء Native القديم الذي كان يسبب حبس/تعليق.
- زر الإضافة للسلة بقي محمياً: لا يسمح بالتقاط/إضافة المنتج إلا إذا أصبحت المنطقة موقّعة وصحيحة حسب اختيار لوحة الإدارة.
- خففت تشخيص console قديم داخل SHEIN كان يعمل مسح صور/DOM عند الإضافة للسلة، حتى تبقى النسخة أخف على الأجهزة الضعيفة وتحت ميزانية الأداء.
- نجح `npm run build` مع حارس تجمّد iPhone وحارس الأداء، ونجحت مزامنة Android/iOS وبناء Android وGitHub iOS.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.17-shein-first-product-region-veil-debug.apk` — SHA-256 `036333156DFA7A9C37123E1CAFD1057391596304EC118066E0F0A9243583A91D`. لم يتم تثبيته لأن ADB لم يجد جهاز Android موصولاً.
- iPhone IPA غير موقّع: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.17-iphone16-unsigned.ipa` — SHA-256 `56A70B26090D484045A09654077D48D5B5B7108F67B31D792B8B82018F746A3A`. GitHub run `30487346505` من commit `ad8b93d`.
- المطلوب تجربته على iPhone 16: حذف/تثبيت، فتح أول منتج، التأكد أن غطاء Otlobli يظهر ويخفي التبديل، ثم يصل للبلد المحدد من الإدارة، ثم جرّب تغيير البلد من لوحة الإدارة وفتح منتج جديد، وبعدها خمس دورات خلفية/رجوع.

## v86.16 — إصلاح خطأ إنشاء الطلب وتسريع قلب منطقة SHEIN بالخلفية

- ركّزت على المشكلتين الأخيرتين فقط: خطأ `orders_payment_status_check` عند متابعة الدفع، وتعطّل/بطء قلب منطقة SHEIN على Android وiPhone.
- أضفت migration إنتاجي يطبّع `orders.payment_status` قبل الحفظ حتى لا ترجع قاعدة البيانات ترفض الطلبات بسبب اختلاف صيغة حالة الدفع. تم تطبيقه على Supabase بنجاح، وتحديث `supabase/schema.sql` معه.
- حسّنت رسالة الخطأ في التطبيق: قيد الدفع المعروف يعطي رسالة واضحة، وباقي قيود قاعدة البيانات لا تختفي خلف رسالة خاطئة.
- أعدت بناء نظام قلب منطقة SHEIN ليعمل بالخلفية بدل شاشة حجب/غطاء Native: المنتج يبقى ظاهر، وشريط Otlobli يبقى موجود، والسكربت يكمل اختيار الدولة/المحافظة/المدينة/المنطقة بدون تعليق المستخدم داخل درج المناطق.
- قوّيت بوابة الجاهزية: صفحة المنتج لا تعتبر المنطقة صحيحة لمجرد الرابط أو التخزين، بل تحتاج `addressCookie` الموقّع من SHEIN بنفس الدولة المطلوبة. هذا يحمي زر “أضف للسلة” عندما تكون المنطقة غلط.
- عالجت stale region: إذا كان `addressCookie` قديم لدولة ثانية مثل قطر/الكويت والإدارة تطلب السعودية، يتم تنظيفه ثم إعادة إصلاح المنطقة بدل اعتبار المتجر جاهزاً.
- جعلت مسار الإصلاح أسرع وأخف: فواصل أقصر أثناء الإصلاح، timeout أقصر، وتراجع تلقائي عن فحص DOM الثقيل أثناء لمس/تمرير المستخدم حتى لا يثقل على الهواتف الضعيفة.
- أضفت ترجمة عربية خفيفة لعناصر المنطقة داخل درج SHEIN بدون تغيير النص الأصلي داخلياً، مثل `السعودية / Saudi Arabia` و`منطقة الرياض / Riyadh Province` و`العليا / Al Olaya`، حتى يبقى مفهوماً للسوريين ولا يكسر أتمتة SHEIN.
- نجح `npm run build` مع حارس تجمّد iPhone وحارس الأداء، ونجحت مزامنة Android/iOS وبناء Android. لم أرفع حدود الأداء.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.16-region-background-payment-status-debug.apk` — SHA-256 `6A6E250025BC9A8D9D4C1D3615E8C16DB8FFE9F64D90086E4BB3F6334AC6CEFB`. لم يتم تثبيته لأن `adb devices` لم يُظهر جهازاً موصولاً وقت الفحص.
- iPhone IPA غير موقّع: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.16-iphone16-unsigned.ipa` — SHA-256 `B306938FC6AEAEB2189026AF9D4966C05658F0F8CC05C2DBE79677FAA816E5D9`. GitHub run `30455469510` من commit `225cdb2`.
- ما زال اختبار القبول الحقيقي مطلوباً بعد تثبيت النسخة: إنشاء طلب، فتح SHEIN من دولة قديمة ثم إجباره للسعودية، الدخول لمنتج، إضافة للسلة، وخمس دورات خلفية/رجوع على iPhone 16 للتأكد من عدم رجوع التجمّد.

## v86.15 — إصلاح مقاس رأس SHEIN على iPhone وإجبار السعودية فعلياً

- أصلحت مشكلة iPhone التي جعلت رأس SHEIN/البحث/الشعار يدخل تحت الساعة والنوتش: صار الـWebView يحترم top safe-area على iOS، بدون تغيير شريط Otlobli السفلي وبدون تكبير/تصغير عام.
- تحققت أن إعداد لوحة الإدارة يرجع SHEIN على السعودية فعلاً: `SA` مع `Riyadh Province → Riyadh → Al Olaya`. لذلك المشكلة كانت داخل أتمتة iPhone/SHEIN، وليس من لوحة الإدارة.
- أصلحت مسار قلب السعودية: التطبيق لم يعد يعتبر المنتج جاهزاً فقط لأن الرابط أو storage صار `SA`؛ لازم `addressCookie` الموقّع من SHEIN يكتمل. هذا يمنع حالة “جاري تغيير المنطقة” ثم يترك المنتج على قطر.
- إذا فتحت قائمة الدول وكانت Saudi Arabia خارج الجزء الظاهر، صار السكريبت يضغط حرف `S` أو يمرّر قائمة الدول داخل درج الشحن، ثم يكمل المسار. كذلك صار يطابق خيارات مثل `العليا/Al Olaya` من الطرفين.
- حافظت على الأداء: لم أرفع budget ولم أضف polling دائم. نجح build وحارس تجمّد SHEIN وحارس الأداء. سكربت SHEIN بقي تحت السقف: `549,631 / 550,000`.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.15-ios-safe-top-saudi-region-repair-debug.apk` — SHA `FA406DAFD77CD390023E2686E41EF9786B65CA208E2BA758456ED35F1B410DC2`.
- iPhone IPA غير موقّع: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.15-iphone16-unsigned.ipa` — SHA `64C3DCFAEBE2FD27225D266305819B58EA167CCD744697AFB128DA0135ED8125`. GitHub run `30445161898`، commit `36d0486`.
- ما زال مطلوب اختبار iPhone الحقيقي بعد التثبيت: حذف/تثبيت أو cold launch، فتح منتج SHEIN من حالة قطر، التأكد أنه يكمل للسعودية/الرياض/العليا وأن الرأس صار تحت شريط الحالة، ثم اختبار الرجوع من الخلفية 5 مرات.

## v86.14 — إصلاح تشويه السلة والدفع على iPhone + خطأ حالة الدفع

- أصلحت تشويه Checkout الذي ظهر في صور iPhone: تفاصيل التكلفة لم تعد تُقصّ أو تدخل تحت زر الدفع، وزر الدفع صار منفصلاً بمساحة واضحة. السبب كان من صفوف CSS Grid التي كانت تصغر أقل من محتواها، وليس من حاجة لتكبير/تصغير عام للتطبيق.
- صغّرت وضبطت بطاقات السلة: عنوان المنتج الطويل صار محدوداً بثلاثة أسطر مع التفاف صحيح، فلا يكبّر البطاقة بشكل مزعج ولا يسبب تداخل مع التفاصيل أو شريط الدفع.
- خفّفت شريط الدفع الثابت بإزالة blur ثقيل (`backdrop-filter`) حتى يبقى ألطف على الأجهزة الضعيفة بدون حذف ميزات.
- أصلحت خطأ إنشاء الطلب `orders_payment_status_check`: الكود صار يرسل حالة دفع canonical، ورفعت migration الإنتاج `20260729210000_fix_order_payment_status_constraint.sql` على Supabase بنجاح.
- نجح البناء والفحوصات: `npm run build`، حارس تجمد SHEIN، ميزانية الأداء، مزامنة Android/iOS، بناء Android، وبناء iPhone عبر GitHub run `30441863134`.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.14-checkout-cart-ios-layout-payment-status-fix-debug.apk` — SHA `7538734E1C5DF5F8D6ED7D7517A693FF3BF12CBFEC250E62E611D7B8212001BD`.
- iPhone IPA غير موقّع: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.14-iphone16-unsigned.ipa` — SHA `E64F0A488ABC5BB241E972BD67E3A95DAF15B61ACA7F3F39988446C4C9F922A9`.
- ما زال اختبار iPhone الحقيقي مطلوباً بعد التثبيت/التوقيع: السلة، متابعة الدفع، زر الدفع، التنقل، خمس دورات خلفية/رجوع، وتشغيل بارد منفصل.

## v86.13 — إصلاح السلة والمقاس العلوي وسرعة الشريط

- أصلحت تداخل بطاقات السلة من السبب الحقيقي: شبكة الصفحة كانت تصغّر ارتفاع الصفوف تحت محتواها. أصبحت كل بطاقة تأخذ ارتفاع محتواها الطبيعي مع صور ومربعات ألوان محددة المقاس، وعناوين وأزرار حذف صحيحة وقابلة للوصول. نجح الفحص البصري والهندسي على عرضي `390px` و`320px`.
- أضفت انتقالاً أصلياً مباشراً من شريط SHEIN/Temu إلى «طلباتي» و«السلة» و«حسابي». الصفحة المطلوبة تُثبّت في React فوراً، ثم تُخفى نافذة المتجر، مع مسار احتياطي للنسخ القديمة. الحل حدثي ولا يضيف polling أو عملاً دائماً على الهواتف الضعيفة.
- أصلحت الجزء العلوي على Android فقط: WebView يبدأ بعد شريط الحالة، لذلك شعار SHEIN والبحث والرأس ظاهرون بالكامل. لم أغيّر مقياس الصفحة ولم ألمس مقاس iPhone 16 لأنه مناسب حسب توضيح المستخدم.
- ثبّتُّ شريط Otlobli على جذر المستند بدل `body` الذي تستبدله SHEIN لحظياً أثناء تحديث صفحات المنتجات. هكذا لا يسقط الشريط ولا تمر النقرة إلى المنتج تحته، من دون إضافة مؤقتات جديدة.
- ثبتت `86.13/873` فوق التطبيق الموجود على النوت 8 مع حفظ البيانات. حدود WebView بدأت عند `y=63` تحت شريط النظام، وبقي الشريط على صفحات البحث/المنتج، وظهرت «طلباتي» في أول لقطة تحقق خلال `1.17s` من بدء أمر ADB، وهذا الرقم يشمل قرابة `0.58s` من كلفة أمر ADB والتقاط الشاشة. لم أمسح أو أستبدل عناصر سلة المستخدم الموجودة.
- نجح بناء الإنتاج وحارسا التجمّد والأداء ومزامنة Android/iOS وبناء Android وتثبيته. Android: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.13-responsive-cart-fast-nav-debug.apk`، SHA `D74996688545B1FA884F6883ED4741ECF948E404FC6C6B8B0B9089831AD9D9E4`.
- نجح بناء iPhone عبر GitHub/Xcode run `30437092864` من commit `011b4a1`. الملف: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.13-iPhone16-unsigned.ipa`، SHA `B9ECA22B8457625645FE8D2355AF44B2A0CE3725EDBC8FFB325424719F063019`.
- فحص الـIPA أكد `com.otlobli.app` و`86.13/873` وعلامات الانتقال الأصلي وثبات الشريط وإصلاح التجمّد. الملف بلا provisioning أو توقيع للتطبيق، وما زال يحتوي scheme `otlobli` فقط، لذلك Google على iPhone يبقى مخفياً. لا يوجد ادعاء نجاح على iPhone قبل تجربة السلة والشريط وخمس دورات خلفية/رجوع وتشغيل بارد منفصل.

## v86.12 — شاشة احترافية عند انقطاع الإنترنت

- أوقفت ظهور صفحة Chromium الخام التي كانت تعرض `ERR_INTERNET_DISCONNECTED` داخل SHEIN. صار Android وiPhone يعرضان فوراً واجهة Otlobli عربية واضحة فوق الصفحة الفاشلة، مع زر أصلي «إعادة المحاولة» وحالة «بانتظار عودة الاتصال…».
- يحفظ التطبيق رابط المنتج نفسه ولا يمسح الجلسة أو الكاش. عند رجوع شبكة صالحة يحاول مرة محكومة تلقائياً، ويتوقف مراقب الشبكة فور النجاح أو إغلاق المتجر؛ لا يوجد polling دائم أو حمل جديد على الهواتف الضعيفة.
- ثبتت v86.12 فوق النسخة الموجودة على النوت 8 دون مسح البيانات، وفتحت WebView الحقيقي بلا إنترنت. اختفت صفحة الخطأ الخام تماماً، لم تبقَ طبقة تحميل ثانية، وزر المحاولة أعاد الفشل إلى نفس الواجهة الآمنة بلا شاشة بيضاء. لم أختبر الرجوع التلقائي للشبكة على الجهاز لأن الهاتف لم يملك اتصال Wi-Fi أو بيانات صالحاً وقت الاختبار.
- نجح بناء الإنتاج وحارسا تجمّد iPhone والأداء، ومزامنة Android/iOS، وبناء Android، وبناء Xcode على GitHub. إصلاح تجمّد iPhone الدائم لم يتغير توقيته أو آليته.
- Android: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.12-offline-recovery-debug.apk`، SHA `79E8EFBA569381E3AB62B9121DE79ECF57F2C64077814F56839CD3728301EED6`.
- iPhone: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.12-iPhone16-unsigned.ipa`، SHA `EF7E0175AEAB4091B647E8FD7C05D924029848C1436105CC734301BAED0850DE`. GitHub run `30390632982`، commit `5ab5639`.
- ملف iPhone غير موقّع، لذلك يلزم تجربته على آيفون حقيقي عند توفر التوقيع: قطع/إعادة الشبكة داخل منتج، زر المحاولة، ثم خمس دورات خلفية/رجوع واختبار تشغيل بارد منفصل.

## v86.11 — إصلاح تدقير المنتج وعدم استجابة الشريط

- فحصت نسخة 86.9 المثبتة على النوت 8 من داخل WebView الحقيقي. كان الشريط ظاهراً لكن `pointer-events:none` وبلا علامة yield، وكل نقاط اللمس تصل إلى صفحة SHEIN خلفه. السبب سباق بين تعطيل الشريط للدرج وبين حفظ/استرجاع ستايله بعد انتهاء تحويل المنطقة.
- فصلت حالة الشريط نهائياً عن سجل ستايل الدرج: بعد الإغلاق يعود دائماً ظاهراً ومعتمًا وقابلاً للضغط، والحارس الشفاف داخل الشريط وحده يمنع اللمس أثناء التحويل.
- أوقفت مسوحات DOM والنص والـlayout الثقيلة أثناء لمس/تمرير المنتج وحتى 320ms بعده، مع إبقاء أحداث الشريط مباشرة. تحويل المنطقة خلف الغطاء مستثنى، ونتيجة فحص جذر الدرج أصبحت مخزنة مؤقتاً.
- ثبتت v86.11 فوق v86.9 على النوت 8 دون مسح البيانات. بعد تمرير سريع متكرر انتقلت «طلباتي» و«السلة» و«حسابي» من أول ضغطة صحيحة، بلا crash أو ANR. تحسن p99 من `38ms` إلى `28-29ms`، وتراجعت الإطارات التي فات موعدها من `22` إلى `4-7`.
- Android: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.11-scroll-safe-nav-debug.apk`، SHA `1E930ADF3C6FB5ABB2B3D1F1DD3A32DC3E2593AA684820F22B5AD56390AAF1E5`.
- iPhone: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.11-iPhone16-unsigned.ipa`، SHA `E8CF4581911EB0B2B45E1C5B87575224F26960023529C67F58EA233AC06B8814`. GitHub run `30361886400`، وآخر commit `ab5dda3`.
- ملف الآيفون غير موقّع. يلزم اختبار التمرير السريع ثم ضغط الشريط على آيفون 16، وتحويل المنطقة، وخمس دورات خلفية/رجوع قبل اعتبار مشكلة iOS مقبولة نهائياً.

## v86.10 — ثبات شريط التنقّل أثناء ضبط المنطقة على iPhone

- أصلحت الفراغ الذي كان يظهر على الآيفون أثناء تبديل متجر/منطقة SHEIN: شريط Otlobli السفلي المعتم يبقى ظاهراً بينما يغطي الغطاء الأصلي قائمة المناطق التي يعمل عليها السكربت.
- أضفت حاجز لمس شفافاً داخل الشريط يمنع الانتقال الخطأ فقط أثناء عمل مسار الدولة والمحافظة والمدينة والمنطقة. لا يمكن أن تظهر صفوف SHEIN عبر المساحة المحجوزة، ويختفي مؤقتاً فقط زرا الإضافة والرجوع.
- لم أضف polling أو مؤقتاً دائماً أو إعادة بناء للـWebView، ولم أضعف إصلاح تجمّد iPhone. نجح الفحص البصري على `390x844`، وبناء الإنتاج، وحارسا التجمّد والأداء، وبناء Android وiOS عبر GitHub/Xcode.
- Android: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.10-persistent-nav-region-cover-debug.apk`، SHA `904B81F6BC1FF6A72C2AC738B2CDF1EB780387E08ADBFFC4CD54AF6FF957B6F1`.
- iPhone: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.10-iPhone16-unsigned.ipa`، SHA `F38D74471E35A3AE6F3C8991C66A180822C1040AB3E78DCF9EE1302CB6045DE0`. GitHub run `30357835150`، commit `88a9765`.
- ملف IPA غير موقّع ويحتاج قبولاً على آيفون حقيقي. تسجيل Google على iOS يبقى مخفياً إلى أن يُجهّز OAuth callback الخاص بالآيفون.

## v86.9 — إصلاح قائمة الدولة واللمس على iPhone

- كشفت صورة iPhone أن قائمة الدول كانت مفتوحة فعلاً، لكن SHEIN أبقت اسم `Qatar` في التبويب الأول؛ لذلك كان السكربت يعيد الضغط على قطر بدل اختيار السعودية. صار وجود عدة صفوف دول هو الحالة الحاكمة، وتُختار دولة لوحة الإدارة أولاً.
- صار اكتشاف القائمة يعتمد على كونها مرسومة، لا على `pointer-events` فقط. أثناء نافذة الشحن يُقفل تمرير المنتج في الخلفية مع حفظ مكانه، ويُترك السحب داخل القائمة نفسها، وتُخفى أزرار Otlobli المتداخلة مؤقتاً ثم تعود بعد إغلاقها.
- الحل يعمل ضمن دورة الصيانة الموجودة ولا يضيف polling جديداً. نجح البناء وحارس تجمّد iPhone وميزانية الأجهزة الضعيفة ومزامنة Android/iOS.
- GitHub Actions رقم `30356842504` نجح من commit `4fe7f5b`. ملف iPhone غير الموقّع: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.9-iPhone16-unsigned.ipa`، وملف Android: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.9-ios-country-drawer-fix-debug.apk`.
- فحص iPhone الحقيقي لهذه النسخة ما زال مطلوباً بعد التوقيع؛ لا يوجد ادعاء 100% قبل تجربة التحويل من قطر إلى السعودية وإغلاق القائمة ثم تكرار اختبار الرجوع من الخلفية خمس مرات.

## v86.8 — إصلاح تبديل المنطقة السريع على Android وiPhone

- تم اكتشاف سببين فعليين: كان ممكناً فتح نافذتي SHEIN معاً عند وصول إعداد المنطقة، وكانت نافذة العنوان الجديدة تستخدم زر إغلاق من نوع `span` لا يلتقطه السكربت القديم؛ لذلك كانت المنطقة تُحفظ لكن القائمة تبقى حتى قرابة 45 ثانية.
- صار التطبيق يفتح جلسة SHEIN أصلية واحدة فقط، ينتظر إعداد المنطقة قبل الفتح الأول، يغلق أي نافذة قديمة، ويتعامل مع تبويبات «اختيار موقع» الجديدة بدون الرجوع المتكرر بسبب عنوان البلد السابق.
- الاختبار الحقيقي على النوت 8 نجح: الكويت أغلقت إلى `Abu Halifa` خلال نحو 4.9 ثوانٍ، ثم التحويل الذي أجراه المستخدم من الكويت إلى السعودية أكمل `Riyadh Province → Riyadh → Al Olaya` وأغلق القائمة خلال نحو 6.7 ثوانٍ مع بقاء زر «أضف للسلة» والشريط.
- لوحة الإدارة الإنتاجية محدثة، ونسخة Android v86.8 مثبتة على النوت 8. ملف Android موجود على سطح المكتب باسم `otlobli-v86.8-smart-fast-region-debug.apk`.
- نسخة iPhone النهائية لهذه الدفعة نجح بناؤها في GitHub Actions run `30354782068` وهي على سطح المكتب باسم `otlobli-v86.8-iPhone16-unsigned.ipa`. ما زال يلزم اختبارها على الآيفون الحقيقي؛ لا يوجد ادعاء نجاح على iPhone قبل ذلك.
- نسخة iPhone غير موقعة، وتسجيل Google فيها ما زال مخفياً لأن iOS OAuth Client غير موجود في GitHub Secrets. هذا منفصل عن إصلاح المنطقة.

## قاعدة مزامنة دائمة لكل تعديل

- من الآن، كل دفعة تعديل مكتملة تُحدّث فوراً وفي نفس المهمة: `CURRENT_STATE.md` و`AI-HANDOFF.md` و`SESSION_SUMMARY.md`، حتى لو كان التعديل صغيراً.
- تغييرات تطبيق العميل المشتركة تُبنى وتُزامَن مع Android وiOS المتأثرين، وتغييرات لوحة الإدارة وقاعدة البيانات والخلفية والإصدارات والملفات الناتجة تبقى متطابقة مع المصدر.
- حالة النشر والاختبار على الأجهزة تُكتب بوضوح: ناجح، محلي فقط، معلّق، أو فاشل. تعديل التوثيق وحده لا يفرض بناء تطبيقات بلا داعٍ.
- ثُبّتت القاعدة التفصيلية في `AGENTS.md`، وانعكست أيضاً في `CLAUDE.md` و`AI_QUICK_HANDOFF.md`.

## حارس دائم لتجمّد SHEIN على iPhone 16

- أضيف `docs/SHEIN_IOS_FREEZE_GUARD.md` كمرجع إلزامي قبل أي تعديل يمس SHEIN أو WebView أو InAppBrowser أو دورة الخلفية أو اختيار المنطقة.
- أضيف فحص آلي `npm run verify:shein-freeze-guard` وصار يعمل تلقائياً قبل كل `npm run build`. يفشل البناء إذا اختفى فصل/إعادة إرفاق WKWebView، حفظ موضع التمرير، استدعاء resume، حماية Android، أو حارس عدم إعادة البناء عند بقاء المنطقة نفسها.
- الباتش الحالي يراقب `appDidBecomeActive` و`appWillEnterForeground` ويشغّل `otlobliRecomposeAllWebViews()` بجدول محدود `0.12/0.5/1.2/2.2` ثانية مع `otlobliForceRecompose(force: true)`. حارس البناء يمنع حذف هذه العلامات.
- أضيف تفريق إلزامي بين استئناف التطبيق نفسه من الخلفية وبين سحبه من App Switcher وتشغيله من الصفر. الإصدار المتأثر لا يُقبل إلا بعد خمس دورات background/resume واختبار cold launch منفصل على iPhone 16 حقيقي.
- نجح الحارس، وبناء الويب الإنتاجي، ومزامنة Android، ومزامنة iOS. هذه الدفعة تضيف حراسة وتوثيقاً ولا تغيّر سلوك التطبيق الأصلي أو إصداره، لذلك لم تُنشأ APK/IPA جديدة ولم يُضف ادعاء اختبار جهاز حقيقي.

## خفة الأجهزة الضعيفة ومتطلبات Google/Push على iPhone

- صارت خفة الأجهزة الضعيفة شرط إصدار دائم من دون حذف ميزات. أضيف `docs/LOW_END_DEVICE_PERFORMANCE_GUARD.md` وحارس حجم يعمل بعد كل build ويمنع نمو JavaScript/CSS/الخطوط وسكربت SHEIN فوق خط الأساس.
- الحزمة الرئيسية الحالية نحو 1.15MB خام وما زالت تحتاج code splitting تدريجياً؛ لم تُخفَ هذه الملاحظة ولم تُرفع السقوف لتجميل النتيجة.
- أضيف `docs/IOS_GOOGLE_PUSH_REQUIREMENTS.md`. Google على iPhone مخفي لأن iOS OAuth client غير موجود في GitHub Secrets؛ يحتاج صلاحية Google Cloud وإنشاء client مرتبط بـ`com.otlobli.app`.
- ظهور طلب السماح بالإشعارات لا يعني أن APNs يعمل. المشروع الحالي unsigned، بلا `aps-environment`، وخادم Supabase بلا أسرار APNs، لذلك لا يستطيع تسليم Push إلى iPhone حالياً.
- عند توفر Apple Developer Program نحتاج تفعيل Push للـApp ID، entitlements/profile وتوقيعاً صحيحاً، ومفتاح APNs p8 مع Key ID وTeam ID وBundle ID. لا تُرسل كلمة مرور Apple أو 2FA؛ يكفي تسجيل الدخول محلياً/وصول الفريق ووضع الأسرار بأمان.
- نجح حارس التجمّد والبناء وميزانية الأداء ومزامنة Android وiOS. أكبر JS بقي `1,151,303` بايت ومجموعه المضغوط `348,843` بايت. لم يتغير الإصدار أو السلوك ولم تُبنَ ملفات تثبيت جديدة في هذه الدفعة.

## v86.7 — انتقال فوري من شريط المتجر + مرشح iPhone 16

- القياس الحقيقي على Note 8 أثبت أن الانتقال من SHEIN إلى «طلباتي» كان يستغرق نحو 5–6 ثوانٍ، لأن WebView المتجر يبقى فوق React إلى أن يكتمل الرسم ثم يعمل Effect الإخفاء.
- فُعّل تحكم الإخفاء الأصلي الآمن في `CapgoInAppBrowser`، وصار كل مسار في شريط SHEIN/Temu يخفي WebView فور اللمس قبل إرسال رسالة التنقل. يوجد استدعاء احتياطي idempotent من React للصفحات القديمة المحفوظة.
- القياس بعد الإصلاح: «طلباتي، السلة، حسابي» تظهر خلال نحو 0.5–0.75 ثانية، والرئيسية تعيد المتجر الجاهز دون إعادة تحميل. لم يظهر crash أو ANR أو renderer loss.
- الإصدار `86.7/867`، وAndroid مثبت فوق السابق مع حفظ البيانات. APK:
  `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.7-instant-store-nav-debug.apk`
  SHA-256: `0CD3A847436F44B0FED48426692498B87E4E6CA8B17509C67DD123315F90D026`.
- بناء الويب وحارسا التجمّد والأداء ومزامنة Android/iOS نجحوا. أكبر JS `1,151,784` بايت، مجموع JS المضغوط `348,941`، وسكربت SHEIN `524,091`.
- مصدر iOS المطابق مرفوع على `codex/ios-v86-4` عند `7b32f28`، وبناء Xcode رقم `30350677536` نجح. IPA غير موقّع:
  `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.7-iPhone16-unsigned.ipa`
  SHA-256: `FBD006DE08A2CFEBA49F161B5A8E908E918191405B136A48018646645651CF57`.
- فحص داخل IPA أكد `com.otlobli.app` و`86.7/867` وعلامة النسخة، وتفعيل visibility control، ووجود `window.mobileApp.hide()` في الحزمة، وعدم وجود relay placeholder أو توقيع. لا تُسلّم IPA 86.6 الأقدم.
- Google على iPhone ما زال مخفياً لغياب `VITE_GOOGLE_IOS_CLIENT_ID`، والـIPA غير موقّع؛ APNs واختبار iPhone 16 الحقيقي ما زالا معلّقين.

## v86.5 — استعادة الحساب والواجهة المتجاوبة

- أُصلح سباق حفظ الجلسة بعد Google/OTP: تُكتب الجلسة فوراً قبل أول طلب للحساب أو المحفظة أو الطلبات أو تسجيل جهاز الإشعارات.
- عند تشغيل التطبيق بحساب محفوظ، يجلب الحساب والطلبات القديمة ورصيدَي SYP/USD وحركات المحفظة. فشل الشبكة المؤقت لم يعد يمسح اللقطة المحلية أو يحوّل الرصيد إلى صفر.
- طُبّقت ترحيلات الإنتاج حتى `20260726234500_session_account_hydration.sql` وأُعيد نشر `google-auth`. مطابقة الطلبات القديمة تتعامل مع اختلاف صيغة `09…` و`9639…`.
- اختيار حساب Google على Android صار المسار القياسي الكامل مع تعطيل الاختيار التلقائي وإجبار إظهار المنتقي.
- صار شريط الأعلى وشريط التنقل خارج منطقة التمرير، وأزيل blur الثقيل. عبارة «طرق تسجيل الدخول» تلتف عند الحاجة ولا تظهر بثلاث نقاط. اجتاز التصميم فحص 320 و360 و412 بكسل.
- APK Android v86.5 جاهز في:
  `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.5-account-recovery-responsive-debug.apk`
  SHA-256: `A5D5BFDFE7E251C6CE114AF9FF049B6082163898BD2D633D61B45B4EFFBBEE05`.
  لم يُثبّت على النوت 8 لأن الجهاز غير ظاهر في ADB حالياً؛ يجب التثبيت بـ`-r` بعد إعادة توصيله دون مسح البيانات.
- بناء Xcode رقم `30216693369` نجح من الفرع المعزول `codex/ios-v86-4` عند `e9662da`. ملف iPhone غير الموقّع:
  `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.5-iPhone-unsigned.ipa`
  SHA-256: `0E241E31DD9316EA67AD0F2F54040D4A924ABD364F6E17A780869FCA5356C5CC`.
- Google على iPhone ما زال مخفياً لأن `VITE_GOOGLE_IOS_CLIENT_ID` غير موجود، والـIPA غير موقّع. لا يُعتبر ذلك مقبولاً على جهاز حقيقي قبل إضافة OAuth الخاص بـiOS والتوقيع وإعادة البناء.

## v86.4 — اختيار المنطقة الكامل

- أصل المشكلة كان أن السكريبت يعتبر ظهور «السعودية» نهاية الاختيار، بينما SHEIN لا تعتمد الشحن إلا بعد كتابة `addressCookie` موقّع يحوي الدولة والمحافظة والمدينة والمنطقة.
- صار الدخول الأول إلى المنتج مخفياً خلف غطاء «جاري ضبط منطقة المتجر…»، ويكمل الدرج الحي: الدولة ← المحافظة ← المدينة ← المنطقة، ثم يغلقه ويظهر المنتج.
- تم اختبار حالة أول مستخدم فعلياً على النوت 8 بحذف مفتاح العنوان وحده مؤقتاً: اختار السعودية ← منطقة الرياض ← الرياض ← العليا، كتب `xAdFlag` بطول 216، أغلق الدرج، أبقى شريط Otlobli ظاهراً، وأظهر المنتج. حُذفت نسخة الاختبار الاحتياطية بعد النجاح.
- لوحة الإدارة الإنتاجية محدثة: 7 دول SHEIN الحقيقية، وقائمة Temu العالمية الموسعة، وتحويل قابل للعكس. إعداد SHEIN الحي يحتوي مسار الرياض الكامل.
- تحسينات الأجهزة الضعيفة: تقليل مسح DOM، تهدئة المؤقتات الساخنة، إزالة blur غير الضروري، مهلة 60 ثانية للمسار الكامل، ومراقب خفيف يعيد شريط التنقل إذا أعاد المتجر بناء الصفحة.
- APK v86.4 مثبت على النوت 8 ومحفوظ في:
  `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.4-complete-region-routing-debug.apk`
  SHA-256: `BAF091D2C1C940C80B71982E3999325303C6AC77E3C9598A2FB0694CB00320DA`.
- نسخة iPhone المطابقة على الفرع المعزول `codex/ios-v86-4`؛ بناء Xcode رقم `30196655282` نجح، والـIPA غير الموقّع موجود في:
  `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.4-iPhone-unsigned.ipa`
  SHA-256: `2A004AC399C033B70F978B3BFC2385BAEBA128FB956A08E0680F46F4ECC4FA17`.

## v86.3 — iPhone unsigned candidate

- Built the current v86.3 customer app on an isolated `codex/ios-v86-3` branch so the primary dirty worktree stayed untouched.
- GitHub/Xcode run `30194500640` passed and produced `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.3-iPhone-unsigned.ipa`.
- SHA-256: `B4274F8CB1AA3BA5875A2EE10CA75B05FCE82E0723BCBF196700DC7BA3AEDE88`.
- Verified inside the IPA: `com.otlobli.app`, version `86.3`, build `863`, the v86.3 marker, linked native plugins, and no relay-key placeholder.
- Fixed the iOS CI relay-key injection and added correct iOS OAuth plumbing (`VITE_GOOGLE_IOS_CLIENT_ID` + reversed URL callback). Google stays hidden on iOS until that client exists; the likely project-owner Google account requires identity re-verification.
- The IPA is unsigned and not yet tested on an iPhone. Signed APNs and real iOS Google acceptance remain pending.

## v86.3 — الحساب الموحّد + إشعارات Android مؤكدة

- تم فصل «رقم الاستلام» عن «وسائل تسجيل الدخول». حساب Google الجديد يدخل بعد معلومات الاستلام بلا OTP، والرقم لا يصبح وسيلة دخول إلا بعد تأكيده.
- أضيفت شاشة `حسابي → طرق تسجيل الدخول`: ربط Google بحساب الرقم، أو تأكيد رقم الاستلام وربطه بنفس حساب Google، مع منع الاستيلاء على هوية مرتبطة بحساب آخر.
- طُبّقت حيّاً `20260726223000_unified_customer_auth.sql` ونُشرت `google-auth`. الحسابات القديمة الـ27 بقيت مفعلة.
- تم اختبار Google الحقيقي على النوت 8: `idToken` أصلي بنمط online ثم exchange حي أعاد جلسة الحساب نفسه. حالة الحساب الحية: Google مرتبط والرقم مؤكد.
- تم إصلاح Push كاملاً وتأكيده من المستخدم: جهاز Android مسجل، إرسال الإدارة `sent=1`، قناة `otlobli_general` عالية الأهمية، والإشعار ظهر فعلياً.
- لوحة الإدارة الإنتاجية محدثة على `https://talabieh-admin.vercel.app`.
- APK v86.3 مثبت على النوت 8 ومحفوظ في:
  `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.3-unified-google-phone-auth-debug.apk`
  SHA-256: `DAB16D357518A27AB2732EEFB2EAF0DC358A3847D4772A074FC4E4BCD8FF859B`.

## v86.2 continuation — Auth design/Admin regions/Branding

- Updated from the v85.8.92 worktree to v86 commit `e72f4db`; current branch name remains `claude/ios6-cover-fix`.
- Fixed Android `Failed to resolve module specifier "@capgo/capacitor-social-login"` by bundling the native package statically. Did the same for Push Notifications.
- Corrected the plugin call for Android: initialize in online mode, call login without custom scopes, narrow the online response, and ignore expected `USER_CANCELLED`.
- Google has a committed public Web OAuth client fallback and is enabled unless explicitly disabled. A clean build therefore does not silently lose the Google button.
- `TEST_ONLY_AUTH_BYPASS=false`; fresh installs show auth.
- Added independent live region settings for SHEIN and Temu. Customer-side URL/country enforcement is dynamic, refreshes settings every 30 seconds, and recreates the active WebView after changes. USD is still fixed to avoid changing payment/cart arithmetic.
- Applied `supabase/migrations/20260726180000_store_regions.sql`, deployed `app-settings`, and verified both live defaults as `SA/USD/ar`.
- Replaced the Figma-only project/global instruction with a flexible rule: approved Figma stays authoritative, while direct code-native design is allowed with the installed `frontend-design`, `web-design-guidelines`, and `react-best-practices` skills.
- Redesigned the customer auth shell as a compact Arabic-first route from SHEIN through Otlobli to Syria, with dynamic app name/logo, improved phone semantics, official Google button, visible focus, reduced-motion support, and an accessible live toast.
- Added and deployed the admin `المتاجر والهوية` tab: independent SHEIN/Temu ISO country codes, arbitrary two-letter custom regions, USD safety lock, branding upload/preview, and live 30-second propagation copy.
- Applied `20260726200000_branding_settings.sql`, deployed `app-settings`, and redeployed `https://talabieh-admin.vercel.app`.
- Built and installed Android v86.2 (`versionCode=862`) on the Note 8. Verified the new UI, native Google activity, clean cancellation, no raw module error, and no fatal crash.
- Region/session polling now requests only the required `app-settings` keys, avoiding repeated downloads of the uploaded logo.
- APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.2-professional-auth-admin-stores-debug.apk`; SHA-256 `F4F7BBDC04549FE428FFFEB56DE837FCBAF3F6EC8337126B5FCD92E31D2176E7`.
- Still not a 100% end-to-end claim: real Google account selection/backend exchange, first real FCM delivery, real non-SA store pages, and matching iOS build remain acceptance tests.

> انسخ هذا الملف كاملاً في بداية أي شات جديد لمتابعة العمل.

## الفرع والوصول
- **الفرع الفعّال:** `claude/otlobli-v86-push-google-telegram` (مبني على `claude/ios6-cover-fix`). آخر نسخة: **v86**.
  ⚠️ الـ harness قد يبدأ على فرع قديم جداً (رأينا v36) — تأكّد من الفرع + `APP_VERSION` في `src/config.ts` أولاً.
- **Supabase CLI مربوط** → طبّق تغييرات القاعدة والدوال بنفسك:
  `supabase db query --linked -f file.sql` / `supabase functions deploy <fn> --project-ref dcicqdprtyhwmhegabay [--no-verify-jwt]`.
  ⚠️ `schema.sql` غير مطابق للسيرفر الحيّ — افحص الحيّ عبر `supabase db query --linked`، لا الملف.
  ⚠️ عند إعادة نشر دالة قائمة، **حافظ على `verify_jwt` نفسه** (افحصه بـ `supabase functions list`). `admin-orders` = true.
- **Vercel CLI مسجّل دخول** → واجهة الإدارة: `cd admin && vercel --prod --yes` (مشروع `talabieh-admin`).
- النوت 8 على USB عبر `adb` (serial `988e16384e4f51395230`). بناء iOS: `gh workflow run ios-unsigned-build.yml --ref <branch> --repo m7madv/otlobli`.
- علم `src/config.ts`: `TEST_ONLY_AUTH_BYPASS = true` (يجب false قبل الإنتاج؛ يتخطّى شاشة OTP ويبدأ على home).

## ما أُنجز هذه الجلسة (v86) — الطلبات الثلاثة
> فلسفة التنفيذ: كل شي **إضافي وخامل وآمن**. التطبيق والخوادم تعمل طبيعياً؛ الميزات مخفية خلف أعلام/أسرار
> حتى يُدخل المستخدم مفاتيحه الشخصية. **الدليل الكامل خطوة بخطوة: `docs/CREDENTIALS_SETUP.md`.**

1. **تسجيل الدخول عبر جوجل + ربط الحساب** — مرتكز على الهاتف (ضروري للتوصيل).
   - قاعدة البيانات (مطبّقة حيّة): جدول `customer_identities` + دوال `find_identity_customer`,
     `link_customer_identity`, `touch_identity_login`, `create_customer_session_for_customer`.
   - دالة حافة `google-auth` (منشورة، `verify_jwt=false`): تتحقق من رمز جوجل عبر tokeninfo،
     تبحث/تربط الهوية، تصدر جلسة متوافقة مع نظام `customer_sessions` الحالي. **تفشل مغلقة** حتى يُضبط `GOOGLE_CLIENT_IDS`.
   - الواجهة: `src/services/googleAuthApi.ts` + زر "المتابعة عبر جوجل" في شاشة الدخول (`src/App.tsx`) +
     ربط بعد OTP في كل مسارات النجاح. خلف علمَي `VITE_GOOGLE_AUTH_ENABLED` + `VITE_GOOGLE_WEB_CLIENT_ID`.
   - **مُختبَر بصرياً**: الزر يظهر ويفشل بلطف (الإضافة غير مثبّتة) بلا أي خطأ console.
   - **يحتاج منك:** Google OAuth Client IDs (Web+Android+iOS) + تثبيت `@codetrix-studio/capacitor-google-auth`.

2. **إشعارات Push (أندرويد FCM + آيفون APNs)**.
   - قاعدة البيانات (مطبّقة حيّة): جدول `device_tokens` + دوال `upsert_device_token`, `disable_device_token`.
   - دالة حافة `send-push` (منشورة، `verify_jwt=false`): FCM HTTP v1 (JWT حساب خدمة) + APNs (p8/ES256).
     محميّة بـ `x-push-secret`/`x-admin-pin`. **خاملة** (sent=0) حتى تُضبط مفاتيح FCM/APNs.
   - الربط: `admin-orders` يستدعي `send-push` بالتوازي مع واتساب عند تغيّر حالة الطلب (fire-and-forget، خامل بلا `PUSH_TRIGGER_SECRET`).
     **سلوك واتساب لم يتغيّر.**
   - الواجهة: `src/services/pushNotifications.ts` يسجّل الجهاز عند وجود جلسة (خلف `VITE_PUSH_ENABLED`، native فقط).
   - **يحتاج منك:** مشروع Firebase (`google-services.json` + service account) و — للآيفون — Apple Developer/APNs.

3. **تنبيه تيليغرام عند حظر رقم واتساب** — **الكود جاهز بالكامل** في `server/src/whatsapp.js`
   (`alertAdmin` عند `loggedOut` وعند ارتفاع خطر الرقم). ينقصه فقط تشغيل أحدث كود على Oracle:
   `cd ~/otlobli && git pull && cd server && npm install && pm2 restart talabieh-whatsapp`.
   يستخدم `TELEGRAM_ALERT_CHAT_ID` أو يرجع لـ`TELEGRAM_CHAT_ID` الموجود — غالباً يعمل فور النشر بلا مفتاح جديد.

## الاستيراد الديناميكي المحروس (مهم للفهم)
`googleAuthApi.ts` و`pushNotifications.ts` يستوردان إضافات Capacitor عبر
`import(/* @vite-ignore */ pkg)` باسم حزمة في متغيّر — حتى يمرّ بناء الويب **دون تثبيت الإضافات**.
لا تحوّلها إلى `import` ثابت وإلا يكسر البناء قبل تثبيت الإضافات. البناء الحالي: `npm run build` ✅ ناجح.

## فخاخ مهمة (لا تقع فيها)
- **سيرفران واتساب:** `server/` هو الفعّال (Oracle، متعدّد أرقام). `server-whatsapp/` نسخة ميتة — لا تعدّلها.
- منطق الدفع/المحفظة/anti-ban حسّاس — عدّل أقل مساحة وبعد فهم النسخة الحيّة.
- `verify_jwt` لكل دالة حافة يجب أن يُحفظ عند إعادة النشر.

## المطلوب التالي / المتبقّي
- المستخدم يُدخل المفاتيح الثلاثة حسب `docs/CREDENTIALS_SETUP.md` لتفعيل الميزات.
- (أمان متوسط) تحصين دوال السلة المشتركة بجلسات.
- قبل الإنتاج: `TEST_ONLY_AUTH_BYPASS = false`.
