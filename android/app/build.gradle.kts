import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load release signing credentials from android/key.properties (gitignored).
//
// ⚠️ SECURITY: a missing key.properties must NOT silently downgrade to debug
// signing. The previous build did exactly that:
//
//     signingConfig = if (hasKeystoreProperties) release else debug
//
// so `flutter build apk --release` on a machine without the keystore produced a
// perfectly valid, Play-Uploadable APK signed with the *public, well-known*
// debug key. Anyone could then publish an update that Android accepts as
// coming from this app, and the store listing would carry attacker code under
// this app's identity. The build also looked successful, so nothing surfaced.
//
// The guard below turns that into a hard failure at configuration time. To run
// a debug-signed *local* build use `--debug` (or `flutter run`), which never
// touches this block.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// True only for a build that is genuinely going to be signed for distribution.
val isReleaseBuild = gradle.startParameter.taskNames.any { task ->
    task.contains("Release", ignoreCase = true)
}

if (isReleaseBuild && !hasKeystoreProperties) {
    throw GradleException(
        """
        |Refusing to build a release variant without release signing credentials.
        |
        |android/key.properties is missing, so the release build would fall back to
        |the DEBUG signing key. A debug-signed APK is accepted by Google Play but
        |can be forged by anyone, which means an attacker could publish an update
        |that the device treats as authentic.
        |
        |Create android/key.properties with storeFile, storePassword, keyAlias and
        |keyPassword (see docs/RELEASE.md), or build a debug variant instead:
        |
        |    flutter build apk --debug
        """.trimMargin()
    )
}

android {
    namespace = "com.neetmitos.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        applicationId = "com.neetmitos.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasKeystoreProperties) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // No fallback branch: configuration above has already failed the
            // build if the credentials are absent, so an unqualified reference
            // here can only ever resolve to the real release config.
            signingConfig = signingConfigs.getByName("release")

            // Obfuscation. Without it, the release APK ships Dart code and asset
            // paths in a form that is trivial to read and reverse. ProGuard
            // rules live in proguard-rules.pro.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    dependencies {
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    }
}

flutter {
    source = "../.."
}
