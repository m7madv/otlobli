# Capacitor's consumer rules retain @CapacitorPlugin entry points. Keep only
# the runtime metadata and WebView bridge members that reflection needs; the
# rest of the application remains eligible for R8 shrinking and obfuscation.
-keepattributes RuntimeVisibleAnnotations,RuntimeInvisibleAnnotations,AnnotationDefault
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Do not expose original Java/Kotlin source filenames in release stack traces.
-renamesourcefileattribute SourceFile
