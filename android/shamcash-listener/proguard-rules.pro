# WorkManager creates Worker instances by class name. Keep the constructor explicit
# even if future R8/WorkManager consumer rules change.
-keep class com.otlobli.shamcashlistener.PaymentDeliveryWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
