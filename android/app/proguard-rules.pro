# Flutter Rules
-keep class io.flutter.** { *; }
-keep class com.zspeed.app.** { *; }

# Flutter Deferred Components / Play Core optional dependency rules
-dontwarn com.google.android.play.core.**

# NEXGO POS Smart SDK & Xinguodu System Driver Rules
# Prevents R8/ProGuard from obfuscating or stripping NEXGO & Xinguodu SDK classes, interfaces, and native methods
-keep class com.nexgo.** { *; }
-keepclassmembers class com.nexgo.** { *; }
-dontwarn com.nexgo.**

-keep class com.xinguodu.** { *; }
-keepclassmembers class com.xinguodu.** { *; }
-dontwarn com.xinguodu.**

-keep class com.xgd.** { *; }
-keepclassmembers class com.xgd.** { *; }
-dontwarn com.xgd.**

-keep class net.sourceforge.zbar.** { *; }
-dontwarn net.sourceforge.zbar.**

