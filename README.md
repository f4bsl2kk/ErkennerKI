# Van Detector App

Eine mobile App zur Erkennung von weißen Lieferwagen mit Kamera.

## Features

- Einfache Kamera-Oberfläche
- Automatische Erkennung von weißen Lieferwagen
- Tracking-Rectangle um erkannte Lieferwagen
- Audio-Feedback bei Erkennung
- Moderne Material Design 3 UI
- Kamera-Berechtigungsabfrage

## Setup

### Voraussetzungen

- Flutter SDK (min. Version 3.0.0)
- Android Studio oder VS Code
- Ein Android/iOS Gerät oder Emulator

### Installation

1. Flutter SDK installieren:
   ```bash
   flutter doctor
   ```

2. Projekt abhängigkeiten installieren:
   ```bash
   flutter pub get
   ```

3. TensorFlow Lite Modell erstellen:
   - Trainieren Sie ein Modell mit TensorFlow
   - Konvertieren Sie das Modell zu TFLite
   - Platzieren Sie das Modell in `assets/model/van_detector.tflite`
   - Platzieren Sie die Labels in `assets/model/labels.txt`

4. Sound-Datei hinzufügen:
   - Fügen Sie ein Sound-File (`detection_sound.mp3`) in den `assets/sounds` Ordner hinzu

5. App starten:
   ```bash
   flutter run
   ```

## Verwendung

1. Starten Sie die App
2. Gewähren Sie die Kamera-Berechtigung
3. Halten Sie das Handy auf einen weißen Lieferwagen
4. Die App erkennt den Lieferwagen und:
   - Zeigt ein grünes Tracking-Rectangle
   - Spielt einen Sound ab
   - Zeigt die Erkennungswahrscheinlichkeit an

## Technische Details

- Flutter Framework
- TensorFlow Lite für die Objekterkennung
- Camera Plugin für den Zugriff auf die Kamera
- AudioPlayer für die Sound-Abspielung
- Material Design 3 für die UI

## Lizenz

MIT License - siehe LICENSE Datei
