Android build.gradle configuration:

Add to android/app/build.gradle:

android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.example.documorph"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    
    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

Ensure minSdkVersion is at least 21 for full compatibility.
