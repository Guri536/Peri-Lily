import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dispatch/dispatch_service.dart';
import '../database/database.dart';

final speechServiceProvider = NotifierProvider<SpeechService, bool>(SpeechService.new);

class SpeechService extends Notifier<bool> {
  // 1. Establish the bridge to Android/Kotlin
  static const platform = MethodChannel('com.perilily/python_stt');
  List<Map<String, dynamic>> _activeProtocols = [];

  @override
  bool build() {
    // 2. Listen for Python sending recognized words back to Flutter
    platform.setMethodCallHandler(_handleNativeCall);
    return false;
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onWordRecognized') {
      final String words = call.arguments['text'];
      _checkForTriggers(words.toLowerCase());
    }
  }

  Future<void> startListening() async {
    final db = ref.read(databaseProvider);
    _activeProtocols = await db.getAllProtocols();

    try {
      // 3. Tell Kotlin/Python to wake up and start the mic
      await platform.invokeMethod('startListening');
      state = true;
    } on PlatformException catch (e) {
      debugPrint("Failed to start Python engine: '${e.message}'.");
      state = false;
    }
  }

  Future<void> stopListening() async {
    try {
      await platform.invokeMethod('stopListening');
      state = false;
    } on PlatformException catch (e) {
      debugPrint("Failed to stop Python engine: '${e.message}'.");
    }
  }

  void _checkForTriggers(String transcribedText) {
    for (var protocol in _activeProtocols) {
      if (protocol['trigger_type'] == 'keyword') {
        // Parse the JSON array of Safe Words
        List<dynamic> safeWords = jsonDecode(protocol['trigger_value']);

        for (String safeWord in safeWords) {
          if (transcribedText.contains(safeWord.toLowerCase())) {
            debugPrint('🚨 SAFE WORD DETECTED: $safeWord');

            // FIX: Parse the action_map JSON instead of the deleted action_tier
            Map<String, dynamic> actionMap = jsonDecode(protocol['action_map']);

            // Execute the specific actions mapped to each tier
            actionMap.forEach((tierStr, actionsList) {
              int tier = int.parse(tierStr);
              List<String> actions = List<String>.from(actionsList);
              ref.read(dispatchProvider).executeActions(tier, actions);
            });

            stopListening();
            Future.delayed(const Duration(seconds: 5), () => startListening());
            return; // Exit after first match to prevent duplicate triggers
          }
        }
      }
    }
  }
}