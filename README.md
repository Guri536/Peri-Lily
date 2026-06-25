# **Scope of Project: Peri-Lily**

## **1\. What it is**

Peri-Lily is a privacy-first, serverless mobile safety application designed to empower women by providing discreet, highly customizable emergency communication tools.

Unlike traditional panic-button apps that require obvious user actions or rely on centralized cloud accounts, Peri-Lily operates entirely locally on the user's device. The application focuses on de-escalation and covert communication. It allows users to trigger tiered emergency protocols, such as sharing live GPS coordinates or sending SOS messages, through hidden on-screen gestures and a "Fake UI" decoy screen that actively listens for predefined safe words.

The core philosophy of Peri-Lily is to ensure user safety without alerting potential aggressors, while maintaining absolute data privacy.

## **2\. Features**

* **Tiered Emergency Contacts:** \* Users can categorize their emergency contacts into distinct tiers (e.g., Tier 1 for location sharing during an Uber ride, Tier 2 for urgent SOS alerts).
    * Protocols trigger sequentially or concurrently based on the assigned tier and the severity of the situation.
* **"Fake UI" Decoy Screen:** \* A discreet, hidden on-screen gesture instantly transitions the app into a decoy interface (e.g., a simulated social media feed or a fake incoming phone call).
    * This provides visual camouflage to de-escalate situations if an aggressor demands to see the phone.
* **Active Contextual Keyword Listening:** \* To bypass OS battery constraints and background-listening restrictions, the device's microphone is only activated when the "Fake UI" screen is triggered.
    * Once active, the app continuously transcribes speech locally and scans for the user's predefined "Safe Words" to trigger backend emergency protocols.
* **Automated SOS & Location Dispatch:** \* Upon protocol activation (via gesture or safe word), the app fetches the user's exact GPS coordinates.
    * Alerts are sent to the tiered contacts.
* **Offline SMS Fallback:** \* If the user lacks an active internet connection, the app automatically falls back to native offline SMS to ensure location coordinates and SOS messages are still transmitted.
* **Local-First Architecture:** \* No central servers, no account registration, and no cloud data storage. All contact lists, safe words, and settings are encrypted and stored locally on the device.

## **3\. Implementation**

The application will be developed using a single-codebase, cross-platform approach to ensure availability Android only.

* **Core Framework:** Flutter (Dart)
* **Architecture Pattern:** Local-only, serverless implementation prioritizing speed and offline availability.
* **Data Storage:** Local device storage using SQLite (sqflite) or shared\_preferences for managing tiered contacts and user settings securely.
* **Key Integrations & Packages:**
    * speech\_to\_text: To tap into Apple's and Google's native, on-device speech recognition engines for keyword scanning during the "Fake UI" state.
    * geolocator: To securely and accurately fetch the device's current GPS coordinates.
    * flutter\_sms: To handle the automated background dispatch of SOS messages and map links.
    * contacts\_service: To allow users to easily import phone numbers from their native device address book into the Peri-Lily tiers.
    * permission\_handler: To rigorously manage OS-level user permissions (Microphone, Location, Contacts, SMS) required for the app to function securely.