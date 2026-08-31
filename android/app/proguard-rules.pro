-keep class io.objectbox.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.objectbox.**
-dontwarn com.google.android.play.core.**

-keep class com.google.ai.edge.litert.** { *; }
-dontwarn com.google.ai.edge.litert.**

-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

-keep class fr.jaetan.mybudget.nano.** { *; }
-keep class com.google.mlkit.genai.** { *; }
-dontwarn com.google.mlkit.genai.**
