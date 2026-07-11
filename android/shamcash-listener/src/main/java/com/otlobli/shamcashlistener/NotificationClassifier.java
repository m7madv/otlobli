package com.otlobli.shamcashlistener;

import java.util.Locale;
import java.util.regex.Pattern;

final class NotificationClassifier {
    private static final Pattern AMOUNT_PATTERN = Pattern.compile("(?:^|\\D)[0-9](?:[0-9.,٬،\\s]*[0-9])?(?:\\D|$)");
    private static final Pattern INCOMING_PATTERN = Pattern.compile(
        "(?:(?:تم|تمت)\\s*(?:استلام|ايداع|إيداع|إضافة)|استلام|استلمت|أضيف|اضيف|"
            + "(?:حوالة|تحويل)\\s*(?:واردة|وارد)|(?:حوالة|تحويل)\\s+من\\s+(?!(?:حسابك|محفظتك))|"
            + "(?:وصلت|وصلتك)\\s*(?:حوالة|دفعة)?|حول\\s*(?:إليك|اليك)|إلى\\s*(?:حسابك|محفظتك)|"
            + "وارد|ايداع|إيداع|incoming|received|credit(?:ed)?|deposit)",
        Pattern.CASE_INSENSITIVE
    );
    private static final Pattern OUTGOING_PATTERN = Pattern.compile(
        "(?:تم\\s*(?:إرسال|ارسال|خصم|سحب|دفع|شراء)|حوالة\\s*صادرة|تحويل\\s*صادر|"
            + "أرسلت|ارسلت|حوّلت|حولت|دفعت|خصم|سحب|شراء|"
            + "sent(?:\\s*payment)?|outgoing|debited|withdrawal|purchase)",
        Pattern.CASE_INSENSITIVE
    );
    private static final Pattern SECURITY_CODE_PATTERN = Pattern.compile(
        "(?:\\botp\\b|\\bone[\\s-]*time(?:\\s+password)?\\b|"
            + "\\b(?:verification|security|login)\\s+code\\b|"
            + "(?:رمز|كود)\\s*(?:التحقق|التأكيد|التاكيد|الأمان|الامان|الدخول|السري))",
        Pattern.CASE_INSENSITIVE
    );
    private NotificationClassifier() {}

    static boolean looksLikeIncomingPayment(String title, String text, String bigText) {
        String normalized = normalize(join(title, text, bigText));
        if (!shouldForwardNormalized(normalized)) return false;
        boolean hasIncoming = INCOMING_PATTERN.matcher(normalized).find();
        return hasIncoming;
    }

    // The server parser is authoritative because ShamCash can change wording without
    // an APK update. Forward any amount-bearing, non-OTP, non-outgoing candidate from
    // the fixed package so an unknown incoming format is audited instead of lost.
    static boolean shouldForwardCandidate(String title, String text, String bigText) {
        return shouldForwardNormalized(normalize(join(title, text, bigText)));
    }

    private static boolean shouldForwardNormalized(String normalized) {
        if (normalized.isEmpty()) return false;
        if (!AMOUNT_PATTERN.matcher(normalized).find()) return false;
        if (SECURITY_CODE_PATTERN.matcher(normalized).find()) return false;
        return !OUTGOING_PATTERN.matcher(normalized).find();
    }

    private static String join(String title, String text, String bigText) {
        StringBuilder builder = new StringBuilder();
        if (title != null) builder.append(title).append('\n');
        if (text != null) builder.append(text).append('\n');
        if (bigText != null) builder.append(bigText);
        return builder.toString();
    }

    private static String normalize(String value) {
        return value
            .replace('٠', '0')
            .replace('١', '1')
            .replace('٢', '2')
            .replace('٣', '3')
            .replace('٤', '4')
            .replace('٥', '5')
            .replace('٦', '6')
            .replace('٧', '7')
            .replace('٨', '8')
            .replace('٩', '9')
            .replace('۰', '0')
            .replace('۱', '1')
            .replace('۲', '2')
            .replace('۳', '3')
            .replace('۴', '4')
            .replace('۵', '5')
            .replace('۶', '6')
            .replace('۷', '7')
            .replace('۸', '8')
            .replace('۹', '9')
            .replaceAll("[\\u0640\\u064B-\\u065F\\u0670]", "")
            .toLowerCase(Locale.ROOT)
            .trim();
    }
}
