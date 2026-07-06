package com.otlobli.shamcashlistener;

import java.util.Locale;
import java.util.regex.Pattern;

final class NotificationClassifier {
    private static final Pattern AMOUNT_PATTERN = Pattern.compile("[0-9][0-9.,٬،\\s]{1,}");
    private static final Pattern CURRENCY_PATTERN = Pattern.compile("(?:\\$|usd|syp|syr|دولار|ل\\.?\\s*س|ليرة(?:\\s+سورية)?)", Pattern.CASE_INSENSITIVE);
    private static final Pattern INCOMING_PATTERN = Pattern.compile(
        "(?:تم\\s*استلام|استلام\\s*حوالة|حوالة\\s*واردة|تحويل\\s*وارد|حوالة|تحويل|حول\\s*إليك|استلمت|وارد|ايداع|إيداع|incoming|received|deposit|transfer)",
        Pattern.CASE_INSENSITIVE
    );
    private static final Pattern OUTGOING_PATTERN = Pattern.compile(
        "(?:أرسلت|ارسلت|تحويل\\s*إلى|تحويل\\s*الى|دفعت|خصم|سحب|شراء|sent\\s*payment|outgoing|debited)",
        Pattern.CASE_INSENSITIVE
    );
    private static final Pattern BALANCE_ONLY_PATTERN = Pattern.compile(
        "(?:رصيدك|الرصيد\\s*الحالي|available\\s*balance|current\\s*balance|كشف\\s*حساب|statement|otp|رمز)",
        Pattern.CASE_INSENSITIVE
    );

    private NotificationClassifier() {}

    static boolean looksLikeIncomingPayment(String title, String text, String bigText) {
        String normalized = normalize(join(title, text, bigText));
        if (normalized.isEmpty()) return false;

        boolean hasAmount = AMOUNT_PATTERN.matcher(normalized).find();
        boolean hasCurrency = CURRENCY_PATTERN.matcher(normalized).find();
        boolean hasIncoming = INCOMING_PATTERN.matcher(normalized).find();
        boolean hasOutgoing = OUTGOING_PATTERN.matcher(normalized).find();
        boolean balanceOnly = BALANCE_ONLY_PATTERN.matcher(normalized).find();

        if (!hasAmount) return false;
        if (!hasCurrency && !hasIncoming) return false;
        if (hasOutgoing && !hasIncoming) return false;
        if (balanceOnly && !hasIncoming) return false;
        return hasIncoming;
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
            .toLowerCase(Locale.ROOT)
            .trim();
    }
}
