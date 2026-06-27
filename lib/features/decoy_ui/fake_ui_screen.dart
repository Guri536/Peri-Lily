import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import '../voice_engine/speech_service.dart';
import '../dispatch/dispatch_service.dart';
import '../database/database.dart';

class FakeUiScreen extends ConsumerStatefulWidget {
  const FakeUiScreen({super.key});

  @override
  ConsumerState<FakeUiScreen> createState() => _FakeUiScreenState();
}

class _FakeUiScreenState extends ConsumerState<FakeUiScreen> {
  late final SpeechService _speechNotifier;
  late String showContactName = "Unknown Contact";

  @override
  void initState() {
    super.initState();
    _initializeData();
    _speechNotifier = ref.read(speechServiceProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speechNotifier.startListening();
      _startRingingAndVibrating();
    });
  }

  Future<void> _initializeData() async {
    final getContactName = await ref.read(databaseProvider).getAllContacts();
    if (mounted) {
      setState(() {
        showContactName = getContactName.isEmpty
            ? "Unknown Contact"
            : (getContactName[0]['name'] ?? "Unknown Contact");
      });
    }
  }

  Future<void> _startRingingAndVibrating() async {
    FlutterRingtonePlayer().playRingtone();

    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(
        pattern: [1000, 1000],
        repeat: 1,
      );
    }
  }

  void _stopRingingAndVibrating() {
    FlutterRingtonePlayer().stop();
    Vibration.cancel();
  }

  @override
  void dispose() {
    _stopRingingAndVibrating();
    Future.microtask(() {
      _speechNotifier.stopListening();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C2C2E),
              Color(0xFF1C1C1E),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // TOP: Caller ID (Gesture Trigger 1)
              Column(
                children: [
                  const SizedBox(height: 50),
                  GestureDetector(
                    onDoubleTap: () {
                      ref.read(dispatchProvider).executeActions(1, ['shareLoc']);
                    },
                    child: Text(
                      showContactName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mobile',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),

              // MIDDLE: Avatar (Gesture Trigger 2)
              GestureDetector(
                onLongPress: () {
                  ref.read(dispatchProvider).executeActions(3, ['shareLoc', 'shareMes', 'startVoice']);
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    shape: BoxShape.circle,
                  ),
                  // Subtler icon color for a cleaner look
                  child: const Icon(Icons.person, size: 80, color: Colors.white54),
                ),
              ),

              // Secondary Actions & Call Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 50, left: 40, right: 40),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSecondaryAction(Icons.alarm, 'Remind Me'),
                        _buildSecondaryAction(Icons.message, 'Message'),
                      ],
                    ),
                    const SizedBox(height: 50),
                    _buildCallButtons(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Decline Button
        Column(
          children: [
            GestureDetector(
              onTap: () {
                _stopRingingAndVibrating();
                Navigator.pop(context);
              },
              child: Container(
                width: 75,
                height: 75,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call_end, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Decline', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),

        // Accept Button
        Column(
          children: [
            GestureDetector(
              onTap: () {
                _stopRingingAndVibrating();
                // Add active call transition here
              },
              child: Container(
                width: 75,
                height: 75,
                decoration: const BoxDecoration(
                  color: Color(0xFF34C759),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryAction(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}