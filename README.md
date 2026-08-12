# e3_map

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

<h1>CONFIGURAZIONE</h1>
<h2>JDK 17</h2>
<p>https://adoptium.net/temurin/releases/?version=17</p>
<p>flutter config --jdk-dir "C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot"</p>
<p>flutter doctor -v</p>
<p>Dovresti vedere una riga simile a: Java version OpenJDK 17.x</p>
<h2>Gradle 8.10.2</h2>
<p>Apri: android\gradle\wrapper\gradle-wrapper.properties</p>
<p>imposta distributionUrl=https\://services.gradle.org/distributions/gradle-8.10.2-all.zip</p>
<h2>Disabilita le cache Kotlin che stanno esplodendo</h2>
<p>Apri: android\gradle.properties</p>
<p>e aggiungi in fondo:</p>
<p>kotlin.incremental=false<br/>
kotlin.caching.enabled=false<br/>
org.gradle.caching=false</p>
<hr/>
<h1>Pulisci tutto</h1>
<p>flutter clean</p>
<p>flutter pub cache repair</p>
<p>flutter pub get</p>
<p>flutter build apk --debug</p>

Prima di cambiare Java e Gradle
Facciamo il tentativo meno invasivo, che spesso risolve proprio il tuo errore.
Apri:
android\gradle.properties

e aggiungi:
kotlin.incremental=false
kotlin.caching.enabled=false
org.gradle.caching=false

Poi esegui:
flutter clean
flutter pub get
flutter build apk --debug

flutter devices
flutter run

keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android

impronte digitali:
Impronte digitali certificato:

Portatile:
SHA1: 77:4E:A2:4B:C9:EE:43:B7:27:49:32:E3:DC:F2:61:AF:90:BC:5C:61
SHA256: 27:AB:F3:77:C3:A7:BA:9B:AB:49:EF:23:F2:9D:0C:D7:A1:10:5E:02:5D:C5:F6:D4:81:64:36:77:CC:D7:46:76

Fisso Regione:
C8:D3:52:71:60:EF:E9:98:5B:4A:50:BC:01:2A:BB:E2:DB:8E:0B:F8

flutter build apk --release.
flutter build apk --release --no-tree-shake-icons
flutter build appbundle --release --no-tree-shake-icons

Il file finale si troverà nel percorso build/app/outputs/flutter-apk/app-release.apk
