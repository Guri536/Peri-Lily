import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../voice_engine/speech_service.dart';
import '../dispatch/dispatch_service.dart';

class FakeUiScreen extends ConsumerStatefulWidget {
  const FakeUiScreen({super.key});

  @override
  ConsumerState<FakeUiScreen> createState() => _FakeUiScreenState();
}

class _FakeUiScreenState extends ConsumerState<FakeUiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(speechServiceProvider.notifier).startListening();
    });
  }

  @override
  void dispose() {
    ref.read(speechServiceProvider.notifier).stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // GESTURE TRIGGER 1: Double tapping the fake App Bar triggers Tier 1 (Silent Alert)
        title: GestureDetector(
          onDoubleTap: () {
            ref.read(dispatchProvider).executeActions(1, ['shareLoc', 'shareMes']);
          },
          child: const Text('Recent Articles', style: TextStyle(color: Colors.black)),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[100],
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: const Icon(Icons.article, color: Colors.grey),
              title: Text('Interesting Topic ${index + 1}'),
              subtitle: const Text('Tap to read more about this fascinating subject...'),
              // GESTURE TRIGGER 2: Long pressing the 5th item triggers Tier 3 (High SOS)
              onLongPress: () {
                if (index == 4) { // 5th item
                  ref.read(dispatchProvider).executeActions(3, ['shareLoc', 'shareMes', 'startVoice']);
                }
              },
            ),
          );
        },
      ),
    );
  }
}