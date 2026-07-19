import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peri_lily_android/core/enums.dart';
import 'package:peri_lily_android/features/database/database.dart';
import 'package:peri_lily_android/features/decoy_ui/gesture_wrapper.dart';
import 'package:peri_lily_android/features/dispatch/dispatch_service.dart';

class FakeNote {
  final String title;
  final String preview;
  final String body;
  final String timestamp;

  FakeNote({
    required this.title,
    required this.preview,
    required this.body,
    required this.timestamp,
  });
}

class FakeNoteGenerator {
  static final _notes = [
    FakeNote(
      title: 'Grocery List',
      preview: 'Milk, eggs, bread, ...',
      body: 'Milk\nEggs\nBread\nSpinach\nCoffee\nPaper towels',
      timestamp: '2:14 PM',
    ),
    FakeNote(
      title: 'Call Mom',
      preview: 'Ask about weekend plans',
      body: 'Ask about weekend plans\nDon\'t forget her birthday is next month',
      timestamp: 'Yesterday',
    ),
    FakeNote(
      title: 'Work Notes',
      preview: 'Meeting moved to Thursday',
      body: 'Meeting moved to Thursday 3pm\nSend the deck before EOD Wed\nFollow up with Priya',
      timestamp: 'Mon',
    ),
    FakeNote(
      title: 'Recipe Idea',
      preview: 'Lemon garlic pasta',
      body: 'Lemon garlic pasta\n- pasta\n- garlic\n- lemon\n- parmesan\n- olive oil',
      timestamp: 'Sun',
    ),
    FakeNote(
      title: 'Packing List',
      preview: 'Charger, passport, ...',
      body: 'Charger\nPassport\nHeadphones\nSunglasses\nBook',
      timestamp: 'Last week',
    ),
    FakeNote(
      title: 'Gift Ideas',
      preview: 'For the holidays',
      body: 'Candle set\nBook she mentioned\nThat mug from the market',
      timestamp: '2 weeks ago',
    ),
  ];

  static List<FakeNote> getNotes() => List.from(_notes);
}

class NotesDashboardScreen extends StatelessWidget {
  const NotesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = FakeNoteGenerator.getNotes();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
      body: DecoyGestureWrapper(
        decoyType: DecoyType.notesDash,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.more_horiz, color: Colors.grey.shade700),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300),
                  itemBuilder: (context, index) => _NoteRow(note: notes[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final FakeNote note;

  const _NoteRow({required this.note});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _NoteDetailScreen(note: note)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  note.title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                Text(
                  note.timestamp,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              note.preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteDetailScreen extends ConsumerWidget {
  final FakeNote note;

  const _NoteDetailScreen({required this.note});

  Future<void> _fireBackupTrigger(WidgetRef ref) async {
    final db = ref.read(databaseProvider);

    final gestureRows = await db.getGestureMapForDecoy(DecoyType.notesDash.dbValue);
    final middleSlot = gestureRows.firstWhere(
          (row) => row['gesture_slot'] == Gestures.middleDouble.dbValue,
      orElse: () => {},
    );

    final protocolId = middleSlot['protocol_id'] as int?;
    if (protocolId == null) {
      debugPrint('No protocol assigned to backup trigger slot');
      return;
    }

    final protocol = await db.getProtocolById(protocolId);
    if (protocol == null) return;

    final Map<String, dynamic> actionMap = jsonDecode(protocol['action_map']);
    final dispatch = ref.read(dispatchProvider);

    actionMap.forEach((tierStr, actionsList) {
      final tier = int.parse(tierStr);
      final actions = List<String>.from(actionsList);
      dispatch.executeActions(tier, actions);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF6E3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () => _fireBackupTrigger(ref),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note.timestamp, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Text(note.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(note.body, style: const TextStyle(fontSize: 16, height: 1.5)),
          ],
        ),
      ),
    );
  }
}