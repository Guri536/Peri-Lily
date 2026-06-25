import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/actions.dart';
import '../database/database.dart';

class ProtocolSetupScreen extends ConsumerStatefulWidget {
  const ProtocolSetupScreen({super.key});

  @override
  ConsumerState<ProtocolSetupScreen> createState() =>
      _ProtocolSetupScreenState();
}

class _ProtocolSetupScreenState extends ConsumerState<ProtocolSetupScreen> {
  final List<String> _keywords = [];
  final TextEditingController _keywordController = TextEditingController();
  int? _editingProtocolId;
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> _protocols = [];

  final List<ProtocolActions> _availableActions = [
    ProtocolActions.shareLoc,
    ProtocolActions.shareMes,
    ProtocolActions.openScreen,
    ProtocolActions.startAlert,
    ProtocolActions.startVoice,
    ProtocolActions.startVid,
  ];

  Map<int, List<String>> _selectedActions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final db = ref.read(databaseProvider);

    final contacts = await db.getAllContacts();
    final Set<int> activeTiers = contacts
        .where((c) => c['tierLevel'] != null)
        .map((c) => c['tierLevel'] as int)
        .toSet();

    final protocols = await db.getAllProtocols();
    final nextProtocolNumber = protocols.length + 1;

    if (mounted) {
      setState(() {
        _protocols = protocols;
        _selectedActions = {for (var tier in activeTiers) tier: <String>[]};

        if (_editingProtocolId == null && _nameController.text.isEmpty) {
          _nameController.text = 'Protocol $nextProtocolNumber';
        }

        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Safe Words')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDropdownSelector(),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Protocol Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keywordController,
                    decoration: const InputDecoration(
                      labelText: 'Add Covert Keyword (e.g., "Pineapple")',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) =>
                        _addKeyword(), // Adds when user hits enter
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 32),
                  color: Theme.of(context).primaryColor,
                  onPressed: _addKeyword,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              alignment: WrapAlignment.start,
              children: _keywords
                  .map(
                    (keyword) => Chip(
                      label: Text(keyword),
                      onDeleted: () {
                        setState(() {
                          _keywords.remove(keyword);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: _selectedActions.keys.length,
                itemBuilder: (context, index) {
                  int tier = _selectedActions.keys.elementAt(index);
                  return ExpansionTile(
                    title: Text('Tier $tier Actions'),
                    subtitle: Text(
                      '${_selectedActions[tier]!.length} actions selected',
                    ),
                    children: _availableActions.map((action) {
                      return CheckboxListTile(
                        title: Text(action.identifier),
                        value: _selectedActions[tier]!.contains(action.name),
                        onChanged: (bool? isChecked) {
                          setState(() {
                            if (isChecked == true) {
                              _selectedActions[tier]!.add(action.name);
                            } else {
                              _selectedActions[tier]!.remove(action.name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                final protocolName = _nameController.text.trim();
                if (protocolName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a protocol name.'),
                    ),
                  );
                  return;
                }

                // Validate Keywords
                if (_keywords.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please add at least one keyword.'),
                    ),
                  );
                  return;
                }

                // Validate Actions
                bool hasActions = _selectedActions.values.any(
                  (list) => list.isNotEmpty,
                );
                if (!hasActions) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select at least one action.'),
                    ),
                  );
                  return;
                }

                // 3. Save to Database
                await ref
                    .read(databaseProvider)
                    .saveProtocol(
                      id: _editingProtocolId,
                      // Include the ID so it updates if editing
                      type: 'keyword',
                      values: _keywords,
                      name: protocolName,
                      actions: _selectedActions,
                    );

                // 4. Reset UI & Refresh protocols
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Protocol Saved Successfully!'),
                    ),
                  );

                  // Re-fetch to update the dropdown list
                  final protocols = await ref
                      .read(databaseProvider)
                      .getAllProtocols();
                  final nextNumber = protocols.length + 1;

                  setState(() {
                    _protocols = protocols; // Update state list
                    _editingProtocolId = null;
                    _nameController.text = 'Protocol $nextNumber';
                    _keywords.clear();
                    _keywordController.clear();
                    for (var tier in _selectedActions.keys) {
                      _selectedActions[tier] = [];
                    }
                  });
                }
              },
              child: const Text('Save Protocol'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
            child: DropdownMenu<int?>(
              width: 300.0,
              hintText: 'Select a protocol',
              initialSelection: _editingProtocolId,
              textAlign: TextAlign.center,
              menuStyle: MenuStyle(
                backgroundColor: WidgetStateProperty.all<Color>(Color(0xF8FFFFFF)),
                maximumSize: WidgetStateProperty.all<Size>(Size.fromHeight(150.0)),
              ),
              dropdownMenuEntries: _protocols.map((protocol) {
                return DropdownMenuEntry<int>(
                  value: protocol['id'] as int,
                  label: protocol['name'] ?? 'Unnamed Protocol',
                  style: ButtonStyle(
                    alignment: AlignmentDirectional.center,
                    textStyle: WidgetStateProperty.all<TextStyle>(TextStyle(fontSize: 15.5))
                  )
                );
              }).toList(),
              onSelected: (int? selectedId) {
                if (selectedId != null) {
                  _loadProtocolForEditing(selectedId);
                }
              }, 
            ),
        ),
        const SizedBox(height: 8),
        Center(
          child: InkWell(
            onTap: _createNewProtocol,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Create New Protocol'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _loadProtocolForEditing(int id) {
    final protocol = _protocols.firstWhere((p) => p['id'] == id);

    setState(() {
      _editingProtocolId = id;
      _nameController.text = protocol['name'] ?? '';

      // Decode keywords
      final String rawValues = protocol['trigger_value'] ?? '[]';
      List<dynamic> decodedValues = jsonDecode(rawValues);
      _keywords.clear();
      _keywords.addAll(decodedValues.map((e) => e.toString()));

      // Decode actions
      final String rawActions = protocol['action_map'] ?? '{}';
      Map<String, dynamic> decodedActions = jsonDecode(rawActions);

      // Reset all actions, then populate with saved ones
      for (var tier in _selectedActions.keys) {
        _selectedActions[tier] = [];
      }

      decodedActions.forEach((key, value) {
        int tier = int.parse(key);
        if (_selectedActions.containsKey(tier)) {
          _selectedActions[tier] = List<String>.from(value);
        }
      });
    });
  }

  void _createNewProtocol() {
    final nextNumber = _protocols.length + 1;
    setState(() {
      _editingProtocolId = null;
      _nameController.text = 'Protocol $nextNumber';
      _keywords.clear();
      _keywordController.clear();
      for (var tier in _selectedActions.keys) {
        _selectedActions[tier] = [];
      }
    });
  }

  void _addKeyword() {
    final text = _keywordController.text.trim();
    if (text.isNotEmpty && !_keywords.contains(text)) {
      setState(() {
        _keywords.add(text);
        _keywordController.clear();
      });
    }
  }
}
