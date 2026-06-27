import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'location_service.dart';
import 'package:flutter/services.dart';
import '../database/database.dart';

final dispatchProvider = Provider((ref) => DispatchService(ref));

class DispatchService {
  final Ref ref;
  static const smsChannel = MethodChannel("com.perilily/sms");

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
          debugPrint("Initiating covert audio recording...");
          break;
        case 'startVid':
          debugPrint("Initiating covert video recording...");
          break;
      }
    }
  }

  Future<void> _shareLocation(int tier, List<String> recipients, ContactStorageService dbService) async {
    final locationService = ref.read(locationProvider);
    final position = await locationService.getCurrentLocation();

    if (position != null) {
      final String gmapLink = "https://maps.google.com/?q=${position.latitude},${position.longitude}";

      await _sendCovertSMS(
        "Safety Alert: I need immediate help. My coordinates:",
        recipients,
      );

      await Future.delayed(const Duration(seconds: 2));
      // Message 2: Just coordinates (no URL, no http)
      await _sendCovertSMS(
        "${position.latitude}, ${position.longitude}",
        recipients,
      );

      // Save as full Google Maps link in DB
      await dbService.saveLocationHistory(
        gmapLink,
        "Tier $tier Contacts (${recipients.length})",
      );

    } else {
      await _sendCovertSMS("Safety Alert: Location unavailable. Please call me.", recipients);
    }
  }

  Future<void> _sendCovertSMS(String message, List<String> recipients) async {
    try {
      debugPrint("Sending background SMS to: $recipients \nMessage: $message");

      final String result = await smsChannel.invokeMethod('sendBackgroundSms', {
        'message': message,
        'recipients': recipients,
      });

      debugPrint("SMS Dispatch Result: $result");
    } catch (error) {
      debugPrint("Failed to send background SMS: $error");
    }
  }

}