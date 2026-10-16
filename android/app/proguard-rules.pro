# ProGuard / R8 rules for the NEET Mitosis release build.
#
# Enabled via `isMinifyEnabled = true` in android/app/build.gradle.kts.
#
# ─────────────────────────────────────────────────────────────────────────────
# Flutter / Dart
# ─────────────────────────────────────────────────────────────────────────────
# Flutter's engine reaches Dart code through JNI and reflection that R8 cannot
# see. Keep the embedding, its entry points, and the plugin registration
# surface. Trimming these produces an APK that installs fine and then crashes on
# first frame, which is exactly the failure this file exists to prevent.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.embedding.**

# ─────────────────────────────────────────────────────────────────────────────
# Play Core / deferred components (referenced by the Flutter embedding)
# ─────────────────────────────────────────────────────────────────────────────
-dontwarn com.google.android.play.core.**

# ─────────────────────────────────────────────────────────────────────────────
# Supabase (Kotlin/OkHttp/serialization)
# ─────────────────────────────────────────────────────────────────────────────
# Supabase's Kotlin extensions and the PostgREST builder rely on generic type
# information that R8 strips, which fails at runtime with a ClassCastException
# rather than at build time.
-keep class io.supabase.** { *; }
-keep class io.supabase.gotrue.** { *; }
-keep class io.supabase.postgrest.** { *; }
-dontwarn io.supabase.**

# kotlinx.serialization keeps generated serializers referenced only via
# reflection on companion `Companion` objects.
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,includedescriptorclasses class io.supabase.**$$serializer { *; }

# ─────────────────────────────────────────────────────────────────────────────
# Drift / SQLite
# ─────────────────────────────────────────────────────────────────────────────
# Drift generates typed row classes and statement classes whose members are only
# touched from generated code. Keep them, or queries fail with
# "no such method" at runtime.
-keep class net.zetetic.** { *; }
-keep class com.google.devtools.ksp.** { *; }
-dontwarn net.zetetic.**

# ─────────────────────────────────────────────────────────────────────────────
# Google Sign-In
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**

# ─────────────────────────────────────────────────────────────────────────────
# Platform channels
# ─────────────────────────────────────────────────────────────────────────────
# MethodChannel handlers are resolved by name from native code.
-keep class com.neetmitos.app.** { *; }

# ─────────────────────────────────────────────────────────────────────────────
# Misc third-party
# ─────────────────────────────────────────────────────────────────────────────
# flutter_local_notifications desugars against java.time; its scheduled-notification
# receivers are resolved by name from the manifest.
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

-dontwarn javax.annotation.**
-dontwarn sun.misc.**