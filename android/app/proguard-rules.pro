# Razorpay
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google Sign-In
-keep class com.google.android.gms.auth.api.signin.** { *; }
-dontwarn com.google.android.gms.auth.api.signin.**

# QR Code Scanner / ZXing (qr_flutter dependency)
-keep class com.google.zxing.** { *; }
-dontwarn com.google.zxing.**

# Flutter plugins - keep MethodChannel classes
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.plugin.**
-dontwarn io.flutter.embedding.**

# JSON serialization
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
