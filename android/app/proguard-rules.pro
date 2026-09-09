-keep class com.payu.** { *; }
-dontwarn com.payu.**
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
