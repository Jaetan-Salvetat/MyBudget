import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "fr.jaetan.mybudget"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "fr.jaetan.mybudget"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        

        val localProperties = project.file("../local.properties")
        var appwriteProjectId = if (localProperties.exists()) {
            val properties = Properties()
            properties.load(localProperties.inputStream())
            properties.getProperty("appwrite.projectId", "default")
        } else {
            "default"
        }
        
        manifestPlaceholders["appwriteCallbackScheme"] = "appwrite-callback-$appwriteProjectId"
    }

    buildTypes {
        release {

            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
