# Peri-Lily
Peri-Lily is a covert personal safety and emergency response Android application built with Flutter. The application runs discreetly in the background, utilizing on-device natural language processing to listen for custom safe words. When a trigger is detected, the app automatically executes user-defined emergency protocols, such as broadcasting GPS coordinates, sending covert SMS messages to tiered contact lists, or launching a decoy user interface.

![Logo](lib/core/assets/Peri_Lily.png)

## Key Features
* **Background Voice Monitoring:** Continuously listens for predefined safe words using native Android Speech-to-Text combined with a local Python NLP engine for high-accuracy, offline trigger detection.
* **Covert Emergency Dispatch:** Silently sends SMS alerts and highly accurate GPS coordinates to designated emergency contacts without interrupting the device's visible state.
* **Tiered Contact Management:** Organize emergency contacts into distinct tiers, allowing different groups to receive varying alerts based on the severity of the situation.
* **Customizable Safety Protocols:** Map specific keywords to distinct automated actions, including location sharing, SMS alerts, and activating recording modules.
* **Decoy User Interface:** Features a fake incoming call screen designed to de-escalate situations or mask the application's true purpose while providing hidden gesture-based emergency triggers.
* **Persistent Operation:** Utilizes Android foreground services and lock screen widgets to ensure the safety monitoring remains active and easily accessible at all times.

## Architecture and Technologies
* **Frontend / Core Logic:** Flutter, Dart, Riverpod (State Management)
* **Local Database:** SQLite (sqflite) for contacts, protocols, and history logging.
* **Native Android Integration:** Kotlin, MethodChannels for background SMS management, foreground services, and AppWidgets.
* **Local NLP Engine:** Chaquopy (Python on Android) utilizing `difflib` for fuzzy string matching and reliable trigger detection.
* **Location Services:** Geolocator for high-accuracy GPS tracking.

## Prerequisites
* Flutter SDK (stable channel recommended)
* Android Studio / Android SDK (API level 26 or higher recommended for foreground services)
* A physical Android device is highly recommended for testing microphone, SMS, and background service capabilities.

## Required Permissions
To function correctly, Peri-Lily requires the following system permissions:
* Microphone (for voice trigger detection)
* Location (for GPS coordinates in emergency dispatches)
* SMS (for sending automated covert alerts)
* Contacts (for selecting emergency contacts)
* Notifications (for maintaining the persistent background service)

## How to Run
1. Clone the repository to your local machine.
2. Ensure you have the Flutter SDK installed and configured.
3. Connect a physical Android device (recommended for testing SMS and microphone features) or start an Android emulator.
4. Open a terminal in the root directory of the project.
5. Fetch the required dependencies:
   ```bash
   flutter pub get
   ```
6. Build and run the application:
    ```bash
    flutter run
    ```
Important Note: Because this application heavily utilizes native Android components (Foreground Services, SmsManager, AppWidgets) and Chaquopy for the local Python engine, it must be compiled and executed on an Android environment. It will not run on iOS or web platforms.

## Project Structure
* `lib/core/` - Global configurations, enums, and permission services.
* `lib/features/` - Feature-based modules including Contacts, Database, Decoy UI, Dispatch, Protocols, and Voice Engine.
* `android/app/src/main/kotlin/` - Native Android implementations
* `android/app/src/main/python/` - Local Python scripts for the NLP engine (`nlp_engine.py`).
