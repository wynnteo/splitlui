# SplitLui receipt OCR currently uses TextRecognitionScript.latin only.
# google_mlkit_text_recognition's Android plugin also references these
# *optional* scripts, which are not on the release classpath.
# Suppress ONLY these absent recogniser options. Never blanket-ignore ML Kit
# or suppress missing dependencies for scripts actually enabled in the app.
#
# If we later enable Chinese/Japanese/Korean/Devanagari OCR, REMOVE the
# corresponding -dontwarn line and add its ML Kit implementation dependency
# in android/app/build.gradle.kts.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
