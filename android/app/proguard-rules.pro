# -- Flutter Wrapper Config --
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# -- Firebase & Google Services --
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# -- Prevent R8 from breaking Models (Reflection) --
# If your app crashes saying "class not found" for your data models, 
# uncomment the line below and replace with your actual package name:
# -keep class io.flux.ledger.models.** { *; }

# -- Standard Flutter Warnings --
-dontwarn io.flutter.**
-dontwarn javax.annotation.**