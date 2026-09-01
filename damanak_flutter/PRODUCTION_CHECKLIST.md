# خطة إكمال «ضمانك»

آخر تحديث: 2026-09-01 — المصدر المحلي `4.5.1+30`، وiPhone Buildات `24` حتى `29` في TestFlight، وأحدثها حالياً `4.5.1 (29)` بحالة `VALID`، ومرشح Build `30` ينتظر الرفع، وGoogle Alpha على Build `23`، وإصدار Apple `4.5.0` منشور

## مكتمل داخل التطبيق والخادم

- [x] الدخول عبر `Google` أو `Apple` فقط، مع جلسة وحذف حساب ودعوة موظف برابط أو `QR` أو رمز احتياطي.
- [x] مسار ضمان عربي مبسط، ومنتجات ومخزون وبيع وفروع وصندوق وعملاء ومطالبات وفريق.
- [x] الرقم التسلسلي يدعم الكتابة ومسح الباركود مباشرة، ولا توجد حقول ضريبية في المسار التشغيلي.
- [x] باقات بداية/نمو/توسع بحصص `100/600/3000` وحدود فريق `2/5/15`، والأسعار والعملات من المتجر فقط.
- [x] تحقق Apple/Google خادمي، وربط ذري للإيصال، وتحديث استحقاقات كل 5 دقائق، وإقرار Google خادمي.
- [x] حماية سلاسل Google من sibling/replay، واختيار شراء واستعادة المتجر المفتوح فقط، ورفض توكن legacy المبهم قبل تغيير الخطة.
- [x] مصالحة Google عند الفتح والاستئناف، وحالات شراء/استعادة محدودة المدة تمنع التكرار والنتائج القديمة.
- [x] عرض الخطة والدورة والمزود ونهاية الفترة والاستعادة والإدارة والخصوصية والشروط بواجهة RTL واضحة.
- [x] تصنيف اختيار الباقة إلى اشتراك/ترقية/منع باقة أدنى/تغيير فوترة، ومنع نفس الخطة والدورة بعد فحص الخادم، مع شرح عدم تكديس الحصة قبل التأكيد.
- [x] migrations حتى `20260901012000` منشورة على `exxayzlklvgeyqhvtzgi`، واختبارات SQL الحية الخمسة نجحت داخل `BEGIN/ROLLBACK`.
- [x] إنشاء المتجر لا يعود يتوقف عند استهلاك التجربة: يُنشأ بلا فرع أو حصة أو ميزة مجانية، ويُحجب التشغيل حتى تحقق الاشتراك أو الاستعادة.
- [x] التفعيل الأول يعيد تحميل مساحة العمل ويتطلب فرع `MAIN` بعد إكمال المعاملة، ولا يفتح من نافذة الدفع وحدها.
- [x] الاستعادة الصريحة بعد حذف حساب ضمانك تتحقق من Apple JWS أو Google lineage ولا تنتقل إذا بقيت الهوية القديمة أو وُجد ربط/entitlement منافس.
- [x] Google completion يفحص رد BillingClient الفعلي ويبقي المعاملة لإعادة المحاولة عند non-OK، مع إقرار خادمي خلفي غير حاجب.
- [x] Build `23` رُفع إلى Apple وGoogle؛ أصبح إصدار Apple `4.5.0` لاحقاً `READY_FOR_SALE` ولا توجد مسودة مراجعة نشطة، وبقي Google Alpha قيد المراجعة.
- [x] بُنيت خطة مجانية مستقلة عن المتجر: 20 ضماناً لكل شهر تقويمي، وحساب واحد على تثبيت محمي واحد، مع فرع وعضو واحدين، ومن دون عرض دورة أو مزود فوترة.
- [x] أُعيدت الاستعادة وpreflight إلى refresh مشترك، وصار lineage المدفوع المخفي يجبر التحقق قبل الدفع حتى لو كانت لقطته حديثة، مع منع الحالية والأدنى والمزود الثاني.
- [ ] migration `20260901200000` ونسخة `verify-store-purchase` المعدلة غير منشورتين؛ ينشران فقط بعد أن يصبح Build `30` متاحاً في TestFlight.

## حالة توزيع Build 24

- [x] بعد قرار المستخدم، رُفع iPhone Build `24` إلى TestFlight في [33443358450](https://github.com/m7madv/otlobli/actions/runs/33443358450)، واكتملت معالجة Apple وربطه بـ`Damanak Internal` ذات المختبر الواحد.
- [x] سُجلت IPA النهائية: `23,923,863` بايت، وSHA-256 `EA55D5F1192886EE9019F0048E3476C1D5416E047B4F1F1823D234FC56BCF768`.
- [x] بقي `scripts/app_store_setup.mjs` وsubmission Apple الجاري على Build `23` من دون إلغاء أو تبديل.
- [ ] يلزم قرار إصدار منفصل قبل رفع Build `24` إلى Google Alpha أو إضافته إلى App Review.
- [x] لم تتغير معرّفات المنتجات أو قائمة `All Apps - Closed Testers` ذات 12 مختبراً.

## حالة توزيع Build 25

- [x] رُفع رقم المصدر إلى `4.5.0+25`، ونجح `flutter analyze` و`160/160` اختبار Flutter و`56/56` اختبار Deno وبناء web release وAndroid debug.
- [x] نُشر دعم الخادم المتوافق مع Build `24` ونجح اختباره الحي.
- [x] بقي submission Apple Build `23` وGoogle Alpha Build `23` وقائمة المختبرين بلا تغيير.
- [x] رفع run [33449769807](https://github.com/m7madv/otlobli/actions/runs/33449769807) iPhone Build `25` الموقّع إلى Apple؛ Delivery UUID هو `8e864062-28e0-4250-abd2-dac25f8df1b9`، والـIPA `23,930,380` بايت وبصمتها `D2DAF9EF0A97B3C8A6328C32D1B71276352DEAA29A97E144653978983F13A14F`.
- [x] ظهر Build `4.5.0 (25)` بحالة `VALID` ومعرّف `8e864062-28e0-4250-abd2-dac25f8df1b9` بعد معالجة Apple.
- [x] رُبط Build `25` تلقائياً بمجموعة `Damanak Internal` ذات المختبر الواحد، ولم يُضف إلى App Review.
- [ ] لا ترفع Android Build `25` ولا تضف Build `25` إلى App Review بلا قرار إصدار منفصل.

## حالة توزيع Build 26

- [x] رُفع رقم المصدر إلى `4.5.0+26`، ونجح `flutter analyze` و`181/181` اختبار Flutter و`77/77` اختبار Deno واختبار migration `1/1` وفحص تنسيق 27 ملفاً و`git diff --check`.
- [x] نُشرت migration `20260901012000` و`verify-store-purchase` v25، ونجحت اختبارات SQL الحية الخمسة داخل `BEGIN/ROLLBACK`.
- [x] نجح web release وAndroid debug. APK المحلي `207,970,698` بايت وSHA-256 `7450DF31BF6D3E94AAEDF87C61687DDC2BE92EC3A0ADC3FDE558B5CF462F82DA`.
- [x] بقي submission Apple Build `23` وGoogle Alpha Build `23` وقائمة المختبرين الاثني عشر بلا تغيير.
- [x] رفع run [33458183412](https://github.com/m7madv/otlobli/actions/runs/33458183412) iPhone Build `26`، ونجح التحقق والرفع؛ Delivery UUID هو `10a1e004-c6c1-4b56-9cff-618406c3881b`، والـIPA `23,942,352` بايت وبصمتها `FE66B7F77FB1892FE8F3D55F0AC85AB6B0A7DF783286C77C2EDA735A82C32A37`.
- [x] أكد فحص القراءة [33459040483](https://github.com/m7madv/otlobli/actions/runs/33459040483) أن Build `4.5.0 (26)` صار `VALID` وداخل `Damanak Internal` ذات المختبر الواحد، من دون إضافته إلى App Review.
- [x] شُخصت محاولات الاستعادة السبع الفاشلة على v27 بين `08:36:15` و`08:38:40` بتوقيت الرياض: `status1/status1` ثم رفض توافق بسبب واجهات Node X509 غير المنفذة في Deno `2.1.4`، بلا كتابة أو رد تحقق `200`.
- [x] نُشرت `verify-store-purchase` v28 بحالة `ACTIVE` وبصمة `ecee6ad20c0efd25c452d581552aafe903be8316cc43c767a0b551bd83dd7262`. أزالت اعتماد X509 غير المتوافق، ونجح الاختبار الموجه `6/6` على Deno `2.1.4` وDeno الحديث، وأعاد runtime الحي بلا جلسة `401`. لم تجد المراجعة الأمنية المستقلة مانعاً.
- [ ] لا ترفع Android Build `26` ولا تضف Build `26` إلى App Review بلا قرار إصدار منفصل.

## حالة توزيع Build 27

- [x] رُفع رقم المصدر المحلي إلى `4.5.0+27`، وأضيف عقد مركزي لانتقالات الباقات تستخدمه الشاشة و`AppController` بعد preflight.
- [x] تعرض الواجهة الترقية كإجراء أساسي فورياً، والخفض كإجراء ثانوي عند التجديد، وتغيير الدورة مستقلاً، وتوضح أن حد الخطة الجديدة يحل محل القديم مع بقاء استخدام الشهر محسوباً.
- [x] نجح `flutter analyze` و`186/186` اختبار Flutter و`77/77` اختبار Deno و`deno fmt --check` على 27 ملفاً و`git diff --check`.
- [x] نجح web release وAndroid debug. APK المحلي `build/app/outputs/flutter-apk/app-debug.apk` حجمه `207,989,448` بايت وSHA-256 `33295CBE76936B806F7FA21C2FAA663C0B1294159A3DCA03A378FD7ED924DE37`.
- [x] رفع run [33481729437](https://github.com/m7madv/otlobli/actions/runs/33481729437) iPhone Build `27` من الالتزام `e073cd5f7fad489f094337a142c46786eda2d57f`؛ نجح التوقيع والتحقق والرفع. Delivery UUID هو `5b04b5da-22e5-4cc9-affc-691e3b7e840f`، والـIPA `23,943,985` بايت وبصمتها `808712BDD6E46942C9CE837B01FC329ED1CE25A3FC47E95F577BEC03790E2547`.
- [x] أكد فحص القراءة [33482932576](https://github.com/m7madv/otlobli/actions/runs/33482932576) أن Build `4.5.0 (27)` صار `VALID` وداخل `Damanak Internal` ذات المختبر الواحد، وبقي إصدار `4.5.0` في `Waiting for Review` مع `mutationRequested=false`.
- [x] بقي submission Apple Build `23` وGoogle Alpha Build `23` وقائمة المختبرين الاثني عشر بلا تغيير؛ لم تُرفع AAB لـBuild `27` ولم يُضف Build `27` إلى App Review.
- [x] سُجلت مراجعة Apple Design في `docs/DESIGN_AUDIT.md` مع نجاح `320×568` وتكبير النص `200%` آلياً، من دون ادعاء قبول VoiceOver أو جهاز حقيقي.
- [x] لم يُقبل مسار الخفض في Build `27` على جهاز حقيقي، ثم استُبدل بسياسة Build `28` التي تمنع بدء الخفض من داخل ضمانك؛ لا يُعد اختبار خفض Build `27` شرط إصدار حالياً. بقي رفع Android أو تغيير App Review قرار إصدار منفصل.

## حالة Build 28

- [x] رُفع رقم المصدر المحلي إلى `4.5.0+28`، وأصبح عقد الانتقال `start/current/upgrade/blockedDowngrade/billingCycleChange`.
- [x] الباقات الأدنى معلوماتية بزر معطل، ويمنعها `AppController` بعد preflight ثم تعيد خدمة المتجر الحراسة؛ Google لا يستخدم `ReplacementMode.deferred` للخفض.
- [x] قبل كل شراء Apple يفحص Build `28` `Transaction.currentEntitlements`: غياب الربط الخادمي مع وجود اشتراك ضمانك يطلب Restore، والربط القائم لا يسمح بالدفع إلا مع تطابق `originalTransactionId` والمنتج مع Apple ID الحالي. الفحص يفشل مغلقاً ولا ينفذ recovery صامتاً.
- [x] نُفذ reset ذري للاشتراك `sandbox` الوحيد: `source=store` والاستحقاقات الحالية ومرشحو refresh كلها صفر، مع tombstone `revoked` لحفظ lineage، ولا توجد بيانات فوترة `production`.
- [x] نجح `flutter analyze` و`198/198` اختبار Flutter و`77/77` اختبار Deno و`deno fmt --check` على 27 ملفاً و`git diff --check`.
- [x] نجح web release وAndroid debug. APK المحلي `build/app/outputs/flutter-apk/app-debug.apk` حجمه `208,000,201` بايت وSHA-256 `A3DF9A22739B3E1E7938FA6EC3E9BE8CE21C6B3E0CABECBD22C6513832459BBD`.
- [x] سُجلت مراجعة Apple Design المحدثة في `docs/DESIGN_AUDIT.md` من دون ادعاء قبول جهاز أو قارئ شاشة.
- [x] نجح فحص macOS الموقّع run [33520286056](https://github.com/m7madv/otlobli/actions/runs/33520286056)، ثم رفع run [33520953615](https://github.com/m7madv/otlobli/actions/runs/33520953615) Build `28`. أكد inspect [33522527864](https://github.com/m7madv/otlobli/actions/runs/33522527864) أنه `VALID` بالمعرّف `a9038423-e4fc-4499-8c04-bba4c0f1d317` وداخل `Damanak Internal`، مع بقاء Build `23` في App Review وGoogle Alpha وعدم رفع Android Build `28`.
- [x] IPA Build `28` المحلية `output/github-run-33520953615/ضمانك.ipa` حجمها `23,963,467` بايت وSHA-256 `230304290CE79C5E8F47A1D511DC8C845846C88BF529F7D167CA87B07BA65561`.
- [ ] يلزم مسح Purchase History لحساب Apple `sandbox` قبل شراء جديد نظيف؛ reset Supabase لا يمحو ملكية Apple وقد تعيد الاستعادة السجل السابق.
- [ ] منع الخفض مضمون داخل ضمانك فقط؛ صفحة إدارة Apple قد تعرض الباقات الأدنى داخل المجموعة، ويجب أن يبقى التحقق الخادمي مصالحاً لحقيقة المزود.

## حالة Build 29

- [x] أُعيد تنظيم Flutter حول `SubscriptionFlowMachine` مركزية تفصل نطاق الحساب والمتجر، والاستحقاق الخادمي، والكتالوج، وعملية الدفع/الاستعادة الجارية.
- [x] تستخدم الشاشة و`AppController` سياسة `SubscriptionPolicy` نفسها بفشل مغلق؛ لا شراء للخطة الحالية أو باقة أدنى أو مزود منافس أو حالة ناقصة، وتبقى خدمة المتجر حارساً أخيراً مستقلاً.
- [x] يقرأ كل شراء الاشتراك المرجعي من الخادم قبل فتح المتجر، وتمنع حراس الترتيب أي workspace/refresh/restore قديم من الكتابة فوق إيصال أحدث أو إنهاء تحقق جارٍ.
- [x] بُسّطت واجهة الاشتراك إلى ملخص واحد وثلاث باقات مضغوطة وإجراء أساسي واحد، مع الاستعادة والإدارة كإجراءين ثانويين والأسعار من المتجر فقط.
- [x] نجح `flutter analyze` و`211/211` اختبار Flutter و`69/69` اختبار اشتراك مركز و`77/77` اختبار Deno و`deno fmt --check` على 27 ملفاً و`git diff --check`.
- [x] نجح web release وAndroid debug للمصدر `4.5.1+29`. أكد `aapt` أن APK المحلي يحمل `versionName=4.5.1` و`versionCode=29`؛ حجمه `180,868,636` بايت وSHA-256 `C00835D114330136AC2A7A2411C2283C8A564EFC3AAF0DD08388081011E115C1`.
- [x] سُجلت مراجعة Apple Design في `docs/DESIGN_AUDIT.md`، ونجح RTL و`320×568` وتكبير النص `200%` والتمرير آلياً بلا overflow.
- [x] نجح فحص iOS الموقّع بلا رفع في [33531820327](https://github.com/m7madv/otlobli/actions/runs/33531820327). رفضت Apple محاولة `4.5.0 (29)` في [33532659092](https://github.com/m7madv/otlobli/actions/runs/33532659092) فقط لأن الإصدار صار `READY_FOR_SALE` وقطاره مغلقاً؛ نُقل رقم التسويق إلى `4.5.1` مع إبقاء Build `29`.
- [x] نجح فحص iOS الموقّع بلا رفع في [33534828721](https://github.com/m7madv/otlobli/actions/runs/33534828721)، ثم نجح التحقق والرفع في [33535634162](https://github.com/m7madv/otlobli/actions/runs/33535634162). أكد inspect [33537059054](https://github.com/m7madv/otlobli/actions/runs/33537059054) أن Build `4.5.1 (29)` صار `VALID` وداخل `Damanak Internal` بالمعرّف/Delivery UUID `e029d611-6d1a-44b7-a93b-be8478d6e7d0`، مع بقاء `4.5.0` في `READY_FOR_SALE` و`mutationRequested=false`. الـIPA حجمها `23,972,034` وبصمتها `297C151419D1CC4AA09BE776C1673303CF1A00782F9B840555CEA34F2BD88EA6`.
- [ ] تثبيت Build `29` على iPhone حقيقي وتنفيذ شراء/استعادة/ترقية/تغيير دورة وقبول VoiceOver؛ لا تُعد الاختبارات الآلية بديلاً عنها.

## حالة Build 30

- [x] رُفع المصدر إلى `4.5.1+30`، وفُصل المجاني عن فوترة Apple/Google وأُضيفت مزايا الباقات كاملة.
- [x] نجح `flutter analyze --no-pub` و`225/225` اختبار Flutter و`83/83` اختبار Deno و`deno fmt --check` على 27 ملفاً و`git diff --check`.
- [x] نجح web release وAndroid debug. أكد `aapt` أن APK المحلي يحمل `versionName=4.5.1` و`versionCode=30`؛ حجمه `180,876,532` بايت وSHA-256 `C4CA7B5F6EABF80C74FE5121067E4D0AC11B85809F0FDC36BCA9FD4526D99479`.
- [x] نجح اختبار `320×568` مع تكبير النص `200%` لشاشتي الاشتراك والإعداد، وأُغلق overflow حقل الدولة ومحدد نوع الإعداد.
- [x] اجتازت migration والاختبار الحي المركب `BEGIN/ROLLBACK` على قاعدة الإنتاج من دون كتابة؛ قورنت snapshots قبل تطبيقها وبعده للإنتاج وكل Google وسلسلته وإيصالاته وعدادات الحماية، واختُبرت حصة 20 ورفض مسار Apple لـGoogle ومصالحة `scale→growth` عبر RPC المزود.
- [ ] رفع Build `30` إلى TestFlight والتحقق أنه `VALID` وداخل `Damanak Internal` من دون mutation لإصدار App Store.
- [ ] نشر migration و`verify-store-purchase` بعد إتاحة Build `30`، ثم مقارنة بصمة الإنتاج وتشغيل الاختبار الحي وتحديث `supabase/schema.sql`.
- [ ] تثبيت Build `30` على iPhone حقيقي وتنفيذ المجاني والشراء والاستعادة والترقية والإلغاء وقبول VoiceOver؛ لا تُعد الاختبارات الآلية بديلاً عنها.

## قبول الأجهزة قبل الإطلاق العام

- [x] تثبيت Build `26` من TestFlight ونجاح شراء Apple حقيقي قبل حذف حساب ضمانك؛ حذف الحساب لم يلغ الاشتراك.
- [ ] تثبيت Build `29` من TestFlight على iPhone حقيقي والتأكد أن الباقة الأدنى تبقى معلوماتية ولا تفتح الدفع.
- [ ] اختبار حساب/تثبيت غير مؤهل للتجربة: ينشئ المتجر بحصة صفر، ويبقى مقفلاً حتى شراء أو استعادة متحققة.
- [x] نجحت تاريخياً، قبل reset، حالة Apple orphan المبلغ عنها بعد v28 عند `2026-09-01 09:22:26` بتوقيت الرياض: `APPLE_RECOVERY_RUNTIME_COMPATIBILITY_SUCCEEDED` وHTTP `200`، ثم `scale/active/source=store/provider=app_store/monthly/sandbox` وentitlement حالي مع `auto_renews=true`. أعاد التحديث المجدول التحقق عند `09:25:03` بـHTTP `200`، بلا شراء ثانٍ أو منح يدوي. الحالة الحية الحالية بعد reset هي صفر اشتراك متجر وصفر entitlement حالي.
- [ ] شراء Sandbox/اختبار حقيقي واستعادة وتجديد وترقية وتبديل دورة على iPhone، والتأكد أن الباقة الأدنى لا تفتح الدفع داخل Build `29`.
- [ ] شراء اختبار حقيقي واستعادة ودفعة معلّقة وشراء خارج التطبيق على Android من Play، لا من APK جانبي.
- [ ] اختبار حساب ضمانك يملك متجرين: تغيير A لا يمس B، واستعادة A تختار A فقط، والتوكن المبهم يفشل بلا فتح الدفع.
- [ ] اختبار إلغاء التجديد ومشكلة الدفع والسماح المؤقت والانتهاء والاسترداد/السحب على المنصتين.
- [ ] خمس دورات خلفية/استئناف وفتح بارد واتصال متقطع على الجهازين.
- [ ] VoiceOver وTalkBack وتكبير خط `200%` وهاتف Android ضعيف؛ لا يُدعى قبولها اعتماداً على اختبارات Widget.

## عمل خارجي غير مغلق

- [ ] إعداد Google RTDN/Pub/Sub لاكتشاف شراء خارجي جديد حتى لو لم يفتح المستخدم التطبيق خلال مهلة الإقرار.
- [ ] إعداد App Store Server Notifications V2 إذا كان التحديث الفوري مطلوباً.
- [ ] تنفيذ App Attest/DeviceCheck وPlay Integrity واتخاذ قرار لمسار الويب قبل الادعاء بإغلاق تحايل التجربة.
- [ ] اتخاذ قرار مدة صلاحية روابط الضمان وسياسة v1 والإبطال، من دون كسر روابط العملاء الحالية افتراضياً.
- [ ] طباعة حرارية وتصدير محاسبي ووضع بيع محدود دون اتصال قبل تسويق التطبيق بديلاً كاملاً عن كمبيوتر نقطة البيع.
- [ ] وحدة امتثال مستقلة لكل دولة قبل استخدام وصف «فاتورة ضريبية إلكترونية معتمدة»؛ النسخة الحالية إيصال بيع داخلي فقط.

تفاصيل الفوترة في `docs/STORE_BILLING_SETUP.md` ونتيجة الأمن في `docs/SECURITY_AUDIT_2026-08-31.md`.
