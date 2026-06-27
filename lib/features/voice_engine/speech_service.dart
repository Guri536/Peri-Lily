import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../dispatch/dispatch_service.dart';
import '../database/database.dart';

final speechServiceProvider = NotifierProvider<SpeechService, bool>(SpeechService.new);

class SpeechService extends Notifier<bool> {
  // Bridge to your Python engine
  static const platform = MethodChannel('com.perilily/python_stt');

  // Native OS speech listener
  final stt.SpeechToText _speech = stt.SpeechToText();
  List<Map<String, dynamic>> _activeProtocols = [];

  @override
  bool build() {
    return false;
  }

  Future<void> startListening() async {
    final db = ref.read(databaseProvider);
    _activeProtocols = await db.getAllProtocols();

    // 1. Initialize the native OS microphone with an auto-restart fallback
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('Speech Status: $status'),
      onError: (error) {
        debugPrint('Speech Error: ${error.errorMsg}');

        // If Android OS gives up, we force it to reboot and keep listening!
        if (error.errorMsg == 'error_speech_timeout' || error.errorMsg == 'error_no_match') {
          stopListening();
          Future.delayed(const Duration(seconds: 1), () => startListening());
        }
      },
    );

    if (available) {
      state = true;
      // 2. Start streaming the microphone data natively
      _speech.listen(
          onResult: (result) {
            String transcribedText = result.recognizedWords;
            // Only evaluate if we actually heard something
            if (transcribedText.isNotEmpty) {
              print(transcribedText);
              _checkForTriggers(transcribedText);
            }
          },
          listenOptions: stt.SpeechListenOptions(
            pauseFor: const Duration(seconds: 10),
            listenMode: stt.ListenMode.confirmation,
          )
      );
    } else {
      debugPrint("Speech recognition unavailable on this device.");
      state = false;
    }
  }

  void stopListening() {
    _speech.stop();
    state = false;
  }

  void _checkForTriggers(String transcribedText) async {
    for (var protocol in _activeProtocols) {
      if (protocol['trigger_type'] == 'keyword') {
        try {
          // 3. Send the transcribed text to your Local Python Script!
          final bool isTriggered = await platform.invokeMethod('analyzeText', {
            'text': transcribedText,
            'safeWords': protocol['trigger_value']
          });

          // 4. If Python says we have a match, execute the protocol
          if (isTriggered) {
            debugPrint('🚨 PYTHON ENGINE DETECTED SAFE WORD');

            Map<String, dynamic> actionMap = jsonDecode(protocol['action_map']);

            actionMap.forEach((tierStr, actionsList) {
              int tier = int.parse(tierStr);
              List<String> actions = List<String>.from(actionsList);
              ref.read(dispatchProvider).executeActions(tier, actions);
            });

            stopListening();
            // Optional: cool down period before listening again
            Future.delayed(const Duration(seconds: 5), () => startListening());
            return; // Exit loop so we don't trigger multiple times at once
          }
        } on PlatformException catch (e) {
          debugPrint("Failed to communicate with Python Engine: '${e.message}'.");
        }
      }
    }
  }
}