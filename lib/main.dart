import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peri_lily_android/core/permission_service.dart';
import 'package:peri_lily_android/features/database/database.dart';

import 'features/contacts/contact_screen.dart';
import 'features/decoy_ui/fake_ui_screen.dart';
import 'features/protocols/protocol_setup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(child: PeriLilyApp()),
  );
}

class PeriLilyApp extends StatelessWidget {
  const PeriLilyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peri-Lily',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4), // A more refined deep purple
          secondary: const Color(0xFFE8DEF8),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainDashboardScreen(),
        '/decoy': (context) => const FakeUiScreen(),
      },
    );
  }
}

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;

  // The list of screens for the BottomNavigationBar
  final List<Widget> _screens = [
    const HomeActivityTab(),
    const ContactsScreen(),
    ProtocolSetupScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50.0,
        title: GestureDetector(
          onLongPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FakeUiScreen()),
            );
          },
          child: Image(
            image: AssetImage("lib/core/assets/Asset 6Peri_Lily.png"),
            fit: BoxFit.contain,
            height: 50.0,
          ),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security),
            label: 'Protocols',
          ),
        ],
      ),
    );
  }
}

class HomeActivityTab extends ConsumerStatefulWidget {
  const HomeActivityTab({super.key});

  @override
  ConsumerState<HomeActivityTab> createState() => _HomeActivityTabState();
}

class _HomeActivityTabState extends ConsumerState<HomeActivityTab> {
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _recordings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSafeEnvironment();
  }

  Future<void> _initializeSafeEnvironment() async {
    await PermissionsService.requestCorePermissions();
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final db = ref.read(databaseProvider);
    final locations = await db.getRecentLocations();
    final recordings = await db.getRecentRecordings();

    if (mounted) {
      setState(() {
        _locations = locations;
        _recordings = recordings;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return DateFormat('MMM dd, h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionHeader('System Status'),
        const Card(
          elevation: 2,
          child: ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('Background Monitoring Active'),
            subtitle: Text('Voice engine is standing by for triggers.'),
          ),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Last Shared Locations'),
        if (_locations.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 4.0),
            child: Text(
              'No location history yet.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ..._locations.map(
          (loc) => _buildLocationCard(
            date: _formatDate(loc['timestamp']),
            location: loc['locationData'].toString().contains('http')
                ? 'GPS Coordinates Captured'
                : 'Location Unavailable',
            recipients: loc['recipients'],
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionHeader('Previously Stored Recordings'),
        if (_recordings.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 4.0),
            child: Text(
              'No stored audio recordings yet.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ..._recordings.map(
          (rec) => _buildRecordingCard(
            title: rec['title'],
            duration: rec['duration'],
            date: _formatDate(rec['timestamp']),
          ),
        ),
      ],
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

  Widget _buildLocationCard({
    required String date,
    required String location,
    required String recipients,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Shared with: $recipients',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingCard({
    required String title,
    required String duration,
    required String date,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.mic, color: Colors.red),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          '$date • $duration',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () {
            // TODO: Implement audio playback functionality using a package like audioplayers
          },
        ),
      ),
    );
  }
}
