# Add project specific ProGuard rules here.

# Keep Play Core
-keep class com.google.android.play.core.** {*;}

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase Auth
-keep class com.google.firebase.** { *; }
-keep class com.firebase.** { *; }
-keep class org.apache.** { *; }
-keepnames class com.fasterxml.jackson.** { *; }
-keepnames class javax.servlet.** { *; }
-keepnames class org.ietf.jgss.** { *; }
-dontwarn org.apache.**
-dontwarn org.w3c.dom.**

# Preserve the line number information for debugging stack traces.
-keepattributes SourceFile,LineNumberTable

# Keep Serializable classes and needed members
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep Parcelable classes (required for AIDL)
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Kotlin serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.SerializationKt
-keep,includedescriptorclasses class com.rjinnovativemedia.mybyajbook.**$$serializer { *; }
-keepclassmembers class com.rjinnovativemedia.mybyajbook.** {
    *** Companion;
}
-keepclasseswithmembers class com.rjinnovativemedia.mybyajbook.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# URL Launcher plugin uses reflection
-keep class androidx.lifecycle.DefaultLifecycleObserver { *; }
