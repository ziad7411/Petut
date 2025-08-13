plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.petut"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "25.1.8937393"  // إلزامي لـ TensorFlow Lite

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.petut"
        minSdk = 23  // مناسب لـ TensorFlow Lite
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // إعدادات إضافية لـ TensorFlow Lite
        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86_64'
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            
            // تحسينات للـ release
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    // إعدادات مهمة جداً لـ TensorFlow Lite
    packagingOptions {
        pickFirst '**/libc++_shared.so'
        pickFirst '**/libjsc.so'
        pickFirst '**/libtensorflowlite_jni.so'
        pickFirst '**/libtensorflowlite_c.so'
        
        // تجنب تضارب المكتبات
        exclude 'META-INF/DEPENDENCIES'
        exclude 'META-INF/LICENSE'
        exclude 'META-INF/LICENSE.txt'
        exclude 'META-INF/license.txt'
        exclude 'META-INF/NOTICE'
        exclude 'META-INF/NOTICE.txt'
        exclude 'META-INF/notice.txt'
        exclude 'META-INF/ASL2.0'
        exclude("META-INF/*.kotlin_module")
    }

    // إعدادات الذاكرة والأداء
    dexOptions {
        javaMaxHeapSize "4g"
    }

    // تأكد من دعم native libraries
    splits {
        abi {
            enable false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    
    // إضافات مفيدة لـ TensorFlow Lite (اختيارية)
    // implementation 'org.tensorflow:tensorflow-lite:2.13.0'
    // implementation 'org.tensorflow:tensorflow-lite-support:0.4.4'
}

flutter {
    source = "../.."
}
