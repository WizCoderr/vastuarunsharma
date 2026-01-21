import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (!keystorePropertiesFile.exists()) {
    error("keystore.properties not found at: ${keystorePropertiesFile.absolutePath}")
}

keystoreProperties.load(FileInputStream(keystorePropertiesFile))

android {
    namespace = "com.vastuarunsharma.vastu_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.vastuarunsharma.vastu_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        create("release") {
            val keyAliasProp = keystoreProperties["keyAlias"]?.toString()?.trim()
            val keyPasswordProp = keystoreProperties["keyPassword"]?.toString()?.trim()
            val storeFileProp = keystoreProperties["storeFile"]?.toString()?.trim()
            val storePasswordProp = keystoreProperties["storePassword"]?.toString()?.trim()

            require(!keyAliasProp.isNullOrBlank()) { "Missing keyAlias in keystore.properties" }
            require(!keyPasswordProp.isNullOrBlank()) { "Missing keyPassword in keystore.properties" }
            require(!storeFileProp.isNullOrBlank()) { "Missing storeFile in keystore.properties" }
            require(!storePasswordProp.isNullOrBlank()) { "Missing storePassword in keystore.properties" }

            val keystoreFile = rootProject.file(storeFileProp)
            require(keystoreFile.exists()) {
                "Keystore file not found at: ${keystoreFile.absolutePath}"
            }

            keyAlias = keyAliasProp
            keyPassword = keyPasswordProp
            storeFile = keystoreFile
            storePassword = storePasswordProp
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.add("-Xlint:-options")
    options.compilerArgs.add("-Xlint:-deprecation")
    options.compilerArgs.add("-Xlint:-unchecked")
}
