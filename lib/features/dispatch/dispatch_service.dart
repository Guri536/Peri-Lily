import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:send_message/send_message.dart';
import 'location_service.dart';
import '../database/database.dart';

final dispatchProvider = Provider((ref) => DispatchService(ref));

class DispatchService {
  final Ref ref;

  DispatchService(this.ref);

// Replace executeProtocol with executeActions
  Future<void> executeActions(int tier, List<String> actions) async {
    debugPrint("🚨 Executing Tier $tier Protocol with actions: $actions");

    final dbService = ref.read(databaseProvider);
    List<String> recipients = await dbService.getContactsByTier(tier);

    if (recipients.isEmpty) {
      debugPrint("No contacts found for Tier $tier. Aborting dispatch.");
      return;
    }

    // Loop through dynamic actions selected by user in the SQLite DB
    for (String action in actions) {
      switch (action) {
        case 'shareLoc':
          await _shareLocation(tier, recipients, dbService);
          break;
        case 'shareMes':
          await _sendCovertSMS("SOS EMERGENCY: I have triggered a safety protocol and need immediate assistance.", recipients);
          break;
        case 'startVoice':
        // TODO: Trigger device audio recording integration
          debugPrint("Initiating covert audio recording...");
          break;
        case 'startVid':
        // TODO: Trigger device video recording integration
          debugPrint("Initiating covert video recording...");
          break;
      }
    }
  }

  // Extracted location logic into its own helper
  Future<void> _shareLocation(int tier, List<String> recipients, ContactStorageService dbService) async {
    final locationService = ref.read(locationProvider);
    final position = await locationService.getCurrentLocation();

    String locationLink = position != null
        ? "https://maps.google.com/?q=${position.latitude},${position.longitude}"
        : "Location currently unavailable.";

    String message = "Safety Alert: I have triggered a location sharing protocol. My location: $locationLink";

    await dbService.saveLocationHistory(
      locationLink,
      "Tier $tier Contacts (${recipients.length})",
    );

    await _sendCovertSMS(message, recipients);
  }

  Future<void> _sendCovertSMS(String message, List<String> recipients) async {
    try {
      debugPrint("Sending to: $recipients \nMessage: $message");
      String result = await sendSMS(
          message: message,
          recipients: recipients
      );
      debugPrint("SMS Dispatch Result: $result");
    } catch (error) {
      debugPrint("Failed to send SMS: $error");
    }
  }

}