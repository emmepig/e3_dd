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
