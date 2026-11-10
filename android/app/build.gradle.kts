plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

val signingPropertiesFile = rootProject.file("key.properties")
val signingProperties = Properties()
if (signingPropertiesFile.isFile) {
    signingPropertiesFile.inputStream().use(signingProperties::load)
}
val splitPerAbi = project.hasProperty("split-per-abi")

android {
    namespace = "org.hams.app"
    compileSdk = 37
    ndkVersion = "28.2.13676358"
    buildFeatures {
        prefab = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.hams.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 37
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.create("release")
            if (signingPropertiesFile.isFile) {
                signingProperties.getProperty("keyAlias")?.let { releaseSigning.keyAlias = it }
                signingProperties.getProperty("keyPassword")?.let { releaseSigning.keyPassword = it }
                signingProperties.getProperty("storeFile")?.let {
                    releaseSigning.storeFile = rootProject.file(it)
                }
                signingProperties.getProperty("storePassword")?.let {
                    releaseSigning.storePassword = it
                }
            }
            signingConfig = if (signingPropertiesFile.isFile) releaseSigning
            else signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }

        defaultConfig {
            externalNativeBuild {
                cmake {
                    cppFlags += listOf("-std=c++20")
                    arguments += listOf("-DANDROID_STL=c++_shared")
                }
            }
            ndk {
                if (!splitPerAbi) {
                    abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
                }
            }
        }

        externalNativeBuild {
            cmake {
                path = file("src/main/cpp/CMakeLists.txt")
            }
        }

        packaging {
            jniLibs {
                useLegacyPackaging = true
            }
        }
    }

    dependencies {
        implementation("com.google.oboe:oboe:1.9.3")
        testImplementation("junit:junit:4.13.2")
    }
}

gradle.taskGraph.whenReady {
    if (allTasks.any { it.name.contains("Release") }) {
        val required = listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
        val missing = required.filter { signingProperties.getProperty(it).isNullOrBlank() }
        val storeFile = signingProperties.getProperty("storeFile")
        val storeExists = !storeFile.isNullOrBlank() && rootProject.file(storeFile).isFile
        if (!signingPropertiesFile.isFile || missing.isNotEmpty() || !storeExists) {
            throw GradleException(
                "android/key.properties with a valid keystore is required for release builds. " +
                    "Copy android/key.properties.example and follow README.md.",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
