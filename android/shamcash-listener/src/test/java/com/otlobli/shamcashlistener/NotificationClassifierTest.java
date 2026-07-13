package com.otlobli.shamcashlistener;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

public class NotificationClassifierTest {
    @Test
    public void acceptsArabicIncomingPaymentWithArabicDigits() {
        assertTrue(NotificationClassifier.looksLikeIncomingPayment(
            "شام كاش",
            "تم استلام ٢٥ دولار إلى حسابك",
            ""
        ));
    }

    @Test
    public void acceptsIncomingSyrianPoundDeposit() {
        assertTrue(NotificationClassifier.looksLikeIncomingPayment(
            "حوالة واردة",
            "إيداع 125000 ل.س",
            "تم استلام الدفعة بنجاح"
        ));
    }

    @Test
    public void acceptsEnglishIncomingPayment() {
        assertTrue(NotificationClassifier.looksLikeIncomingPayment(
            "Payment received",
            "You received USD 17.25",
            ""
        ));
    }

    @Test
    public void acceptsCommonIncomingDirectionPhrases() {
        assertTrue(NotificationClassifier.looksLikeIncomingPayment(
            "حوالة من أحمد",
            "القيمة 15 USD",
            ""
        ));
        assertTrue(NotificationClassifier.looksLikeIncomingPayment(
            "تمت إضافة مبلغ",
            "100000 ل.س إلى حسابك",
            ""
        ));
    }

    @Test
    public void rejectsOutgoingPayment() {
        assertFalse(NotificationClassifier.looksLikeIncomingPayment(
            "تم إرسال حوالة",
            "أرسلت 25 USD بنجاح",
            ""
        ));
        assertFalse(NotificationClassifier.looksLikeIncomingPayment(
            "حوالة صادرة",
            "تم دفع 25 USD بنجاح",
            ""
        ));
    }

    @Test
    public void rejectsBalanceOnlyNotification() {
        assertFalse(NotificationClassifier.looksLikeIncomingPayment(
            "الرصيد",
            "رصيدك الحالي 500 USD",
            ""
        ));
    }

    @Test
    public void rejectsOtpAndUnqualifiedTransferText() {
        assertFalse(NotificationClassifier.looksLikeIncomingPayment(
            "رمز التحقق",
            "رمز OTP هو 123456",
            ""
        ));
        assertFalse(NotificationClassifier.looksLikeIncomingPayment(
            "OTP received",
            "Your verification code is 123456",
            ""
        ));
        assertFalse(NotificationClassifier.looksLikeIncomingPayment(
            "تحويل",
            "تحويل بقيمة 50 دولار",
            ""
        ));
        assertFalse(NotificationClassifier.looksLikeIncomingPayment(
            "تحويل من حسابك",
            "تم تحويل 50 دولار",
            ""
        ));
    }

    @Test
    public void forwardsUnknownAmountBearingCandidateForServerSideAudit() {
        assertTrue(NotificationClassifier.shouldForwardCandidate(
            "شام كاش",
            "عملية جديدة بقيمة 17.25 USD",
            ""
        ));
        assertFalse(NotificationClassifier.shouldForwardCandidate(
            "رمز الدخول",
            "رمز التحقق 123456",
            ""
        ));
        assertFalse(NotificationClassifier.shouldForwardCandidate(
            "حوالة صادرة",
            "تم إرسال 17.25 USD",
            ""
        ));
    }
}
