import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peri_lily_android/core/enums.dart';
import 'package:peri_lily_android/features/database/database.dart';

class DecoySettingsScreen extends ConsumerStatefulWidget {
  const DecoySettingsScreen({super.key});

  @override
  ConsumerState<DecoySettingsScreen> createState() => _DecoySettingsScreenState();
}

class _DecoySettingsScreenState extends ConsumerState<DecoySettingsScreen> {
  DecoyType _selectedDecoyType = DecoyType.fakeCall;
  List<Map<String, dynamic>> _protocols = [];
  Map<String, int?> _gestureAssignments = {}; // slot dbValue -> protocol_id
  int? _volumeProtocolId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);

    final protocols = await db.getAllProtocols();
    final savedDecoyType = await db.getSetting(SettingKeys.activeDecoyType.dbValue);
    final volumeProtocolStr = await db.getSetting(SettingKeys.volumeTriggerProtocolId.dbValue);

    final decoyType = DecoyType.values.firstWhere(
          (d) => d.dbValue == savedDecoyType,
      orElse: () => DecoyType.fakeCall,
    );

    final gestureRows = await db.getGestureMapForDecoy(decoyType.dbValue);
    final assignments = {
      for (var row in gestureRows)
        row['gestureSlot'] as String: row['protocolId'] as int?
    };

    if (mounted) {
      setState(() {
        _protocols = protocols;
        _selectedDecoyType = decoyType;
        _gestureAssignments = assignments;
        _volumeProtocolId = volumeProtocolStr != null ? int.tryParse(volumeProtocolStr) : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _onDecoyTypeChanged(DecoyType? newType) async {
    if (newType == null || newType == _selectedDecoyType) return;

    final db = ref.read(databaseProvider);
    await db.setSetting(SettingKeys.activeDecoyType.dbValue, newType.dbValue);

    final gestureRows = await db.getGestureMapForDecoy(newType.dbValue);
    final assignments = <String, int?>{
      for (var row in gestureRows)
        row['gestureSlot'] as String: row['protocolId'] as int?,
    };

    if (mounted) {
      setState(() {
        _selectedDecoyType = newType;
        _gestureAssignments = assignments;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Active decoy set to ${newType.displayName}')),
      );
    }
  }

  Widget _buildGestureAssignmentList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: Gestures.values.length,
      itemBuilder: (context, index) {
        final slot = Gestures.values[index];
        final currentProtocolId = _gestureAssignments[slot.dbValue];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: DropdownButtonFormField<int?>(
            value: currentProtocolId,
            decoration: InputDecoration(
              labelText: slot.displayName,
              border: const OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Unassigned')),
              ..._protocols.map((p) => DropdownMenuItem<int?>(
                value: p['id'] as int,
                child: Text(p['name'] ?? 'Unnamed Protocol'),
              )),
            ],
            onChanged: (protocolId) async {
              await ref.read(databaseProvider).setGestureProtocol(
                _selectedDecoyType.dbValue,
                slot.dbValue,
                protocolId,
              );
              setState(() => _gestureAssignments[slot.dbValue] = protocolId);
            },
          ),
        );
      },
    );
  }

  Future<void> _onGestureAssigned(Gestures slot, int? protocolId) async {
    await ref
        .read(databaseProvider)
        .setGestureProtocol(_selectedDecoyType.dbValue, slot.dbValue, protocolId);

    if (mounted) {
      setState(() => _gestureAssignments[slot.dbValue] = protocolId);
    }
  }

  Future<void> _onVolumeProtocolAssigned(int? protocolId) async {
    await ref
        .read(databaseProvider)
        .setSetting(SettingKeys.volumeTriggerProtocolId.dbValue, protocolId?.toString() ?? '');

    if (mounted) {
      setState(() => _volumeProtocolId = protocolId);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_protocols.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Decoy & Trigger Settings')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Create a protocol first under the Protocols tab before assigning gestures.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Decoy & Trigger Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Active Decoy Screen'),
          _buildDecoyTypeSelector(),
          const SizedBox(height: 28),

          _buildSectionHeader('Decoy Screen Gestures'),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
            child: Text(
              'Assign which saved protocol fires for each gesture on the '
                  '${_selectedDecoyType.displayName} screen.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          _buildGestureAssignmentList(),
          const SizedBox(height: 28),

          _buildSectionHeader('Volume Button Trigger'),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
            child: const Text(
              'Works even when the app is in the background or the screen is locked.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          _buildVolumeProtocolSelector(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDecoyTypeSelector() {
    return DropdownButtonFormField<DecoyType>(
      value: _selectedDecoyType,
      decoration: const InputDecoration(
        labelText: 'Decoy Screen Type',
        border: OutlineInputBorder(),
      ),
      items: DecoyType.values.map((type) {
        return DropdownMenuItem(value: type, child: Text(type.displayName));
      }).toList(),
      onChanged: _onDecoyTypeChanged,
    );
  }

  Widget _buildVolumeProtocolSelector() {
    return DropdownButtonFormField<int?>(
      value: _volumeProtocolId,
      decoration: const InputDecoration(
        labelText: 'Volume Up ×3 Trigger',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Disabled')),
        ..._protocols.map((p) {
          return DropdownMenuItem<int?>(
            value: p['id'] as int,
            child: Text(p['name'] ?? 'Unnamed Protocol'),
          );
        }),
      ],
      onChanged: _onVolumeProtocolAssigned,
    );
  }
}