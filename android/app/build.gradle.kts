import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rjinnovativemedia.mybyajbook"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.rjinnovativemedia.mybyajbook"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        getByName("debug") {
            storeFile = file("${System.getProperty("user.home")}/.android/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
        
        create("release") {
            // Copy from debug for testing purposes
            storeFile = file("${System.getProperty("user.home")}/.android/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
            
            try {
                // Try to load from local.properties if it exists
                val localPropertiesFile = project.rootProject.file("local.properties")
                if (localPropertiesFile.exists()) {
                    val properties = Properties()
                    localPropertiesFile.inputStream().use { properties.load(it) }
                    
                    val keystorePath = properties.getProperty("keystore.path", "keystore.jks")
                    val keystorePassword = properties.getProperty("keystore.password", "")
                    val keyAlias = properties.getProperty("keystore.key_alias", "")
                    val keyPasswordValue = properties.getProperty("keystore.key_password", "")
                    
                    storeFile = file(keystorePath)
                    storePassword = keystorePassword
                    this.keyAlias = keyAlias
                    keyPassword = keyPasswordValue
                } else {
                    // Fallback to env variables if no local.properties
                    val envStoreFile = System.getenv("RELEASE_STORE_FILE")
                    if (envStoreFile != null) {
                        storeFile = file(envStoreFile)
                        storePassword = System.getenv("RELEASE_STORE_PASSWORD")
                        keyAlias = System.getenv("RELEASE_KEY_ALIAS")
                        keyPassword = System.getenv("RELEASE_KEY_PASSWORD")
                    } else {
                        // Default development values for debug only
                        storeFile = file("${System.getProperty("user.home")}/.android/debug.keystore")
                        storePassword = "android"
                        keyAlias = "androiddebugkey"
                        keyPassword = "android"
                        
                        println("WARNING: Using debug keystore for release build. Create a release keystore before publishing.")
                    }
                }
            } catch (e: Exception) {
                println("Failed to load signing config. Error: ${e.message}")
                
                // Fallback to debug keystore
                storeFile = file("${System.getProperty("user.home")}/.android/debug.keystore")
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
