import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.devtools.ksp")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

android {
    namespace = "fr.jaetan.mybudget"
    compileSdk = 37
    ndkVersion = "28.2.13676358"

    buildFeatures {
        resValues = true
        buildConfig = true
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file("app/keystore/mybudget_key.jks")
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "fr.jaetan.mybudget"
        // Android 8.0. Vérifié avant de descendre de 31 : aucun plugin ne
        // demande plus que 24, et le code natif n'appelle aucune API
        // au-delà — `FLAG_IMMUTABLE` existe depuis 23, la surcharge
        // `setRemoteAdapter(Int, Intent)` des widgets depuis 11 (dépréciée
        // en 31, pas supprimée).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "MyBudget Debug")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "MyBudget")
        }
        create("beta") {
            dimension = "env"
            applicationIdSuffix = ".beta"
            resValue("string", "app_name", "MyBudget Beta")
        }
        create("store") {
            dimension = "env"
            resValue("string", "app_name", "MyBudget")
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("profile") {
            applicationIdSuffix = ".debug"
        }
        release {
            signingConfig = signingConfigs.findByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

configurations.all {
    resolutionStrategy {
        force("androidx.glance:glance:1.1.1")
        force("androidx.glance:glance-appwidget:1.1.1")
    }
}

// ObjectBox Admin, the store browser, only exists in the debug build : it
// ships a web server, which has nothing to do in a release. Its artifact
// carries the native library too, so the plain one has to step aside.
configurations {
    getByName("debugImplementation") {
        exclude(group = "io.objectbox", module = "objectbox-android")
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    debugImplementation("io.objectbox:objectbox-android-objectbrowser:5.4.2")

    implementation("com.google.mlkit:genai-prompt:1.0.0-beta4")
    implementation("com.google.mlkit:genai-schema:1.0.0-alpha1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    ksp("com.google.mlkit:genai-schema-compiler:1.0.0-alpha1")
}

flutter {
    source = "../.."
}
