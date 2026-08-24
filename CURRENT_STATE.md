# Otlobli Current State

Last updated: 2026-08-25

## مشروع VoiceBrief المستقل (2026-08-25)

- المشروع المستقل داخل `voicebrief_flutter/` باسم **VoiceBrief** ومعرّف مرشح الإنتاج `app.voicebrief.mobile` وإصدار `0.1.0+1`. لم تُعدّل مصادر Otlobli أو Damanak أو منطق الدفع والمحفظة، وتغييرات المشروع ما تزال غير ملتزمة حتى لا تختلط بتعديلات المستخدم الموجودة.
- شاشة إعداد الصوت صارت محرراً فعلياً: موجة مستخرجة من الملف، تشغيل وإيقاف، شريط قفز زمني، لمس/سحب على الموجة، وتحديد بداية ونهاية الجزء. قص Android يستخدم Media3 Transformer ويصدر AAC/M4A خاصاً؛ مصدر iOS يستخدم `AVAssetExportSession.timeRange`. المعالجة تلخص الجزء المختار فقط، ويمكن إعادة المدى إلى التسجيل الكامل.
- تسارع الاستيراد الخارجي بإقرار ملف التسليم الخاص مباشرة بدل نسخه مرة ثانية. تُكتشف الصيغة من التوقيع عندما يحذف Android امتداد الملف، وتبقى الموجة غير حاجبة للتفاعل. أُلغي تكرار شاشة الإعداد الناتج عن استماع Shell مع تنقل المنتقي؛ ضغطة Back واحدة تعود الآن إلى Home، والقص لا يعيد استخراج موجة لملف سيُعالج فوراً.
- حذف السجل والنتيجة متفائل وفوري ثم تُكتب قاعدة البيانات في الخلفية؛ يظهر «تراجع» مباشرة ويعيد العنصر عند الضغط. فشل التخزين يستعيد الحالة بدل تعليق الواجهة. «النص الحرفي للتسجيل» أصبح مرجعاً تلقائياً مطوياً ومشروحاً، وليس خيار تلخيص ثانياً.
- على `SM_N950F`/Android 9: نجح استيراد MP3 بلا امتداد مدته 2:46، واستخراج الموجة، والقفز بالشريط إلى 1:34 وبالموجة إلى 2:29، وتحديد 0:42–1:11، وإنتاج M4A حقيقي مدته 0:29 والوصول للنتيجة ضمن مهلة 15 ثانية. نجح Back مرة واحدة، والحذف الفوري في RTL، وظهور Undo، واستعادة العنصر. العربية من `ar-AE`، رصيد `10/10`، وإذن الميكروفون عند الضغط فقط ما تزال مؤكدة.
- نجح `flutter analyze`، وكل الاختبارات غير الذهبية وعددها 25، وكل الصور الذهبية الثماني. نجح أيضاً اختبار Android الموجّه `:app:connectedDebugAndroidTest` لمشاركة Opus الحقيقية على Note 8. فشل المهمة العامة غير الموجهة غير متعلق بالتطبيق؛ فهي تحاول اختبار مكتبات إضافات منفصلة بحد SDK غير متوافق.
- حزم الإنتاج الموقعة النهائية: AAB `voicebrief_flutter/output/voicebrief/VoiceBrief-0.1.0-build1-production-signed.aab`، الحجم `58,905,864` بايت، SHA-256 `08FE3948C581BCCA2D0C52AF781E4299C69EC9F09BA9D1FC7EDEF4165954EB44`. APK في المجلد نفسه، الحجم `68,643,138` بايت، SHA-256 `7A9DB99D12781D0CC3AD8AD178CEB2118A1D53531230DAF71726FFCF2D54CD03`. تحقق APK بمخطط v2 وAAB بتوقيع JAR، وشهادة الرفع ما تزال `81:AA:4D:A6:E4:25:79:4E:88:0C:8D:DE:0A:75:68:F6:8C:EE:77:4A:3C:18:89:17:02:21:AD:04:46:EE:8F:D9`.
- مشروع Supabase المستقل هو `jyehqpdbayslhzebdycj` وروابط الخصوصية والشروط والدعم منشورة على `https://voicebrief-legal.vercel.app`. يبقى OpenAI خلف Supabase فقط: الرصيد `$10.00` وإعادة الشحن متوقفة، والمسار `gpt-transcribe` ثم `gpt-5.6-luna`. لم يُستخدم Gemini المجاني بسبب شروط البيانات غير المدفوعة.
- Google Cloud مكتمل لـWeb وAndroid وiOS في المشروع `voicebrief-prod-mhm1981x`، لكن OAuth ما يزال Testing وحساب Note 8 الموجود `mhm1981d@gmail.com` لا يطابق test user `mhm1981x@gmail.com`. RevenueCat ومنتجات المتاجر وApple signing ما تزال إعدادات خارجية، ولا يوجد ادعاء جاهزية متجر كاملة.
- رُفع المشروع إلى GitHub على الفرع `codex/voicebrief-ios`. التشغيل الأخضر `32788817963` عند `67332f4` نجح في Linux/Windows/macOS: تحليل واختبارات Android وبناء debug، الصور الذهبية الثماني، و`pod install` وبناء iOS release بلا توقيع والتحقق من `app.voicebrief.mobile` و`app.voicebrief.mobile.share` ووجود Share Extension. IPA المحلية `voicebrief_flutter/output/github-run-32788817963/voicebrief-ios-unsigned-3/VoiceBrief-0.1.0-build1-unsigned.ipa`، الحجم `16,807,014`، SHA-256 `79064717F6E26FC6DAA9D3CE30BEADB302AA581C82F618C7C2239E45D1AD900C`. الملف بلا provisioning وتوقيع، لذلك يلزم Apple signing واختبار iPhone حقيقي قبل التثبيت أو المتجر. نقطة الرجوع السابقة `voicebrief-prebuild-20260824`، وApple Design Skill مثبت عند `d0bac1e765a27a696839e62962e36330ce72f0b7`.

## مشروع ضمانك المستقل 4.1.0+7 (2026-08-25)

- `damanak_flutter/` إصدار `4.1.0+7` بمعرّف `com.damanak.damanak`. بقي نظام الفروع ونقطة البيع والمخزون والضمان مستقلاً تماماً عن Otlobli وVoiceBrief.
- الدخول صار حصراً عبر `Sign in with Apple` و`Google Sign-In`؛ أزيلت واجهات البريد وكلمة المرور وإنشاء الحساب واستعادته من العقود والتنفيذ والواجهة. يظهر Apple أولاً على iPhone وGoogle أولاً على بقية المنصات، مع معالجة واضحة للإلغاء وفشل فتح نافذة الدخول.
- دعوة الموظف أصبحت استخداماً واحداً وصالحة 48 ساعة: يحدد المدير الدور ثم يشارك رابطاً أو رمز `QR`، ويبقى رمز `DMN-...` بديلاً عند تعذر فتح الرابط. يفتح الرابط التطبيق، يملأ الدعوة والدور تلقائياً، ثم يسجل الموظف عبر Apple أو Google ويؤكد الانضمام. لا يستطيع المدير دعوة مدير آخر؛ ذلك محصور بصاحب المتجر ويطابق صلاحيات الخادم.
- اشتراك صاحب المحل صار أصلياً عبر `App Store` و`Google Play`: أسعار المتجر المحلية، شهري/سنوي، استعادة، وترقية/خفض. أزيلت واجهة التفعيل اليدوي؛ مدفوعات عملاء المحل داخل نقطة البيع منفصلة ولا تمر عبر متاجر التطبيقات.
- دالة `verify-store-purchase` تتحقق خادمياً من Apple أو Google قبل منح الخطة وإكمال المعاملة. الإيصال مربوط بحساب المالك والمتجر، والدفعة المعلقة لا تمنح وصولاً، ورمز Google الخام محفوظ في مخطط `private` لإعادة فحص التجديد/الإلغاء كل 6 ساعات عند دخول المالك.
- مشروع Supabase الإنتاجي المستقل هو `exxayzlklvgeyqhvtzgi` داخل المؤسسة `vtsboyejmxzjonslkavk` وفي Mumbai `ap-south-1`. حُذف مشروع Tokyo الفارغ بعد موافقة المستخدم، ونُشرت migrations الأربع ودالة `verify-store-purchase`، وضُبط redirect على `com.damanak.damanak://login-callback`، وعُطل Email auth. أضيفت إعدادات Supabase العامة إلى GitHub Secrets؛ لم يُمس `talabieh` أو `VoiceBrief`.
- الواجهة تحافظ على أخضر واحد ومحايدات. روجعت شاشة الدخول في الوضعين الفاتح والداكن وورقة دعوة الموظف عند `393×852`، وشاشة الاشتراك عند `1280×720` و`390×844`، بلا تجاوزات. نتيجة Apple HIG والإتاحة موثقة في `docs/DESIGN_AUDIT.md`.
- Google OAuth مكتمل داخل مشروع `Damanak Production` (`damanak-production`، الرقم `521030062021`) على الحساب `mhm1981x@gmail.com`، ومزود Supabase مفعّل، ونجح redirect الحي إلى `accounts.google.com`. Apple App ID `com.damanak.damanak` وServices ID `com.damanak.damanak.signin` ومفتاح تسجيل Apple كلها جاهزة؛ مزود Supabase مفعّل ونجح redirect الحي إلى `appleid.apple.com`.
- مفتاح Apple لتسجيل الدخول `4GF7TP229W` محفوظ خارج Git، وسر OAuth الحالي يجب تدويره قبل 2027-02-20. ملف `Runner.entitlements` يعلن `Sign in with Apple`، وملف التوزيع الجديد `Damanak App Store 2026` رقم `6497QWMYJ2` يتضمن الاستحقاق نفسه وقد حُدث GitHub Secret الخاص به. workflow iOS صار يتحقق من الاستحقاق داخل التطبيق والملف المضمّن.
- نجح `flutter analyze` و21 اختباراً. بُنيت AAB إنتاجية بالإعدادات الحية والتوقيع المحلي: `damanak_flutter/build/app/outputs/bundle/release/app-release.aab`، `55,775,502` بايت، SHA-256 `88073698D408A62D5D6C548C0B2BFD0320D4B5CCB2EA281381853917CC5C1F72`. شهادة رفع Android SHA-256 `BF0B373699911FDAB8BD46DE90664D0915CED35E2ED046A6AD4E4B030F814574`. المفتاح المحلي وكلمة مروره المشفرة بـDPAPI ما زالا خارج Git، ونسخته المشفرة وكلمة المرور والاسم المستعار محفوظة الآن في GitHub Secrets بالأسماء `DAMANAK_ANDROID_UPLOAD_KEYSTORE_BASE64` و`DAMANAK_ANDROID_UPLOAD_KEY_PASSWORD` و`DAMANAK_ANDROID_UPLOAD_KEY_ALIAS`.
- Apple App Store Connect: سجل `Damanak - ضمانك` رقمه `6804792494`، ومجموعة `Damanak Plans` رقمها `22332400`، والاشتراكات الستة مترجمة ومتاحة في دول الخليج الست بأسعار `39/390` و`99/990` و`199/1989.99 SAR`. صور المراجعة واتفاقية التطبيقات المدفوعة والحساب البنكي والضرائب وDSA كلها مكتملة. مفتاح IAP رقم `49HN3HGNM2` وأسراره موجودة في Supabase، ودالة التحقق أعيد نشرها.
- البناءان `5` و`6` في TestFlight لا يحتويان إعدادات Supabase ولا يجوز استخدامهما. build `7` المبني من `e575617` نجح في GitHub run `32783227070`: التحليل والاختبارات والتوقيع واستحقاق Apple والتحقق والرفع إلى App Store Connect كلها ناجحة. IPA المحلية `C:\Users\MOHAMMAD\Downloads\damanak-ios-build7-32783227070\ضمانك.ipa`، `21,952,228` بايت، SHA-256 `89187374D5BD47665614AB3518F60F84341A0B32183A84348243445ECFC27241`. ما زال اختبار TestFlight الحقيقي على iPhone مطلوباً بعد انتهاء معالجة Apple.
- Google Play: سجل التطبيق `Damanak - ضمانك` رقمه `4975804725938350009`. فُعّلت Android Publisher API، وأضيف حساب الخدمة `damanak-play-verifier@damanak-production.iam.gserviceaccount.com` بأذونات التطبيق المحدودة، وحُفظ JSON في Supabase وGitHub. حُذف المفتاح اليتيم `d86a3e51984e7ba7b942f00595a37c268b367316` نهائياً بعد موافقة المستخدم، وبقي المفتاح العامل `426377cca3335db2db9a17611153fb1b37e92a1d` وحده نشطاً. الإصدار الداخلي `4.1.0 (7)` منشور، وأنشئت وربطت قائمة `Damanak Internal` التي تضم `mhm1981x@gmail.com` فقط. رابط الانضمام `https://play.google.com/apps/internaltest/4701722430109624070`.
- أتمتة اشتراكات Google Play تدعم الفحص وإنشاء المسودات المسعرة لدول الخليج الست وتفعيل الخطط. الفحص الحي ناجح والمنتجات الثلاثة ما تزال مفقودة؛ إنشاء الأسعار يعيد مؤقتاً `The caller does not have permission`. توثق Google أن تغييرات الأذونات قد تحتاج حتى 48 ساعة للانتشار، ولم يُمنح حساب الخدمة صلاحية مشرف للتحايل على ذلك.

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
