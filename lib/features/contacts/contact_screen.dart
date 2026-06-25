import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/permission_service.dart';
import '../database/database.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  bool refreshContacts = true;

  Future<void> _pickAndAssignContact(int tier) async {
    final hasPermission = await PermissionsService.requestCorePermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions required to add contacts.'),
          ),
        );
      }
      return;
    }

    try {
      final Contact? contactInfo = await FlutterContacts.native.showPicker();

      if (contactInfo != null) {
        Contact? contact = await FlutterContacts.get(
          contactInfo.id!,
          properties: ContactProperties.all,
        );

        if (contact != null && contact.phones.isNotEmpty) {
          final name = contact.displayName;
          final phone = contact.phones.first.number;

          final Set<String> contacts =
              (await ref.read(databaseProvider).getContactsByTier(tier))
                  .toSet();

          if (contacts.contains(phone)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$name already exists in List $tier.')),
            );
          } else {
            await ref
                .read(databaseProvider)
                .addTieredContact(name!, phone, tier);

            setState(() {
              refreshContacts = !refreshContacts;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added $name to List $tier')),
              );
            }
          }
        } else if (contact != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected contact has no phone number.')),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Selected contact is empty.')));
      }
    } catch (e) {
      debugPrint("Failed to pick contact: $e");
    }
  }

  void _showTierContactsList(BuildContext context, int tier) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return TierContactsSheet(tier: tier, scrollController: controller);
          },
        );
      },
    );

    if(mounted) {
      setState(() {
        refreshContacts = !refreshContacts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Contact Lists')),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          final tierLevel = index + 1;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              // Open the floating widget when tapped
              onTap: () => _showTierContactsList(context, tierLevel),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(
                    'Contact List $tierLevel',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: FutureBuilder<List<Map<String, dynamic>>>(
                    key: ValueKey(refreshContacts),
                    future: ref
                        .read(databaseProvider)
                        .getDetailedContactsByTier(tierLevel),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return const Text("Error loading contacts");
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Text("Loading");
                      final contacts = snapshot.data ?? [];

                      return Text(
                        contacts.isEmpty
                            ? "Empty List"
                            : contacts.map((i) => i['name']).join(", "),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.person_add,
                      color: Colors.deepPurple,
                    ),
                    onPressed: () => _pickAndAssignContact(tierLevel),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The Floating Widget (Bottom Sheet) to display and remove contacts
class TierContactsSheet extends ConsumerStatefulWidget {
  final int tier;
  final ScrollController scrollController;

  const TierContactsSheet({
    super.key,
    required this.tier,
    required this.scrollController,
  });

  @override
  ConsumerState<TierContactsSheet> createState() => _TierContactsSheetState();
}

class _TierContactsSheetState extends ConsumerState<TierContactsSheet> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final contacts = await db.getDetailedContactsByTier(widget.tier);
    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  Future<void> _removeContact(int id, String name) async {
    final db = ref.read(databaseProvider);
    await db.deleteContact(id);
    await _loadContacts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name removed from Tier ${widget.tier}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drag Handle
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          height: 4,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          'Tier ${widget.tier} Contacts',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _contacts.isEmpty
              ? const Center(
                  child: Text(
                    'No contacts assigned to this tier yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple.withOpacity(0.2),
                        child: Text(
                          contact['name'].substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.deepPurple),
                        ),
                      ),
                      title: Text(contact['name']),
                      subtitle: Text(contact['phoneNumber']),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                        onPressed: () =>
                            _removeContact(contact['id'], contact['name']),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
