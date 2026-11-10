# JNI entry points are looked up by name from the native engine.
-keepclasseswithmembers,includedescriptorclasses class * {
    native <methods>;
}

# Pigeon APIs are referenced by Flutter's channel registration and reflection.
-keep class org.hams.app.EngineApi* { *; }
-keep class org.hams.app.PingRequest { *; }
-keep class org.hams.app.PingReply { *; }
-keep class org.hams.app.SessionSnapshot { *; }
-keep class org.hams.app.SessionEvent { *; }

# Foreground services are instantiated by Android from the manifest.
-keep class org.hams.app.SpeakerService { *; }
-keep class org.hams.app.ListenerService { *; }
-keep class org.hams.app.PackageUpdateReceiver { *; }
