# Flutter specific keep rules
-keep class io.flutter.** { *; }
-keep class com.eseru.manevirehber.** { *; }

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.core.app.** { *; }

# geolocator
-keep class com.baseflow.geolocator.** { *; }

# home_widget
-keep class es.antonborri.home_widget.** { *; }

# just_audio
-keep class com.ryanheise.just_audio.** { *; }

# share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Flutter deferred components (not used, but Flutter engine references them)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# General Android
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
