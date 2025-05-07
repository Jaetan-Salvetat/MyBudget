import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("app/key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "fr.jaetan.mybudget"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"
    
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = File("/keystore/mybudget_key.jks")
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

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
        debug {
            applicationIdSuffix = ".debug"
            resValue("string", "app_name", "MyBudget Debug")
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            resValue("string", "app_name", "MyBudget")
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
