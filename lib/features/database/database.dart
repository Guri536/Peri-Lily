import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

final databaseProvider = Provider<ContactStorageService>((ref) {
  return ContactStorageService();
});

class ContactStorageService {
  static Database? _database;
  static const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
  static const textType = 'TEXT NOT NULL';
  static const intType = 'INTEGER NOT NULL';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('perilily_contacts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts (
        id $idType,
        name $textType,
        phoneNumber $textType,
        tierLevel $intType
      )
    ''');

    // 2. Protocols
    await db.execute('''
      CREATE TABLE protocols (
        id $idType,
        name $textType,
        trigger_type $textType, 
        trigger_value $textType, 
        action_map $textType
      )
    ''');

    // 3. Locations
    await db.execute('''
      CREATE TABLE locations (
        id $idType,
        locationData $textType,
        recipients $textType,
        timestamp $textType
      )
    ''');

    // 4. Recordings
    await db.execute('''
      CREATE TABLE recordings (
        id $idType,
        title $textType,
        filePath $textType,
        duration $textType,
        timestamp $textType
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
  }

  Future<void> addTieredContact(String name, String phone, int tier) async {
    final db = await database;
    await db.insert('contacts', {
      'name': name,
      'phoneNumber': phone,
      'tierLevel': tier,
    });
  }

  Future<List<String>> getContactsByTier(int tier) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      columns: ['phoneNumber'],
      where: 'tierLevel = ?',
      whereArgs: [tier],
    );

    return maps.map((e) => e['phoneNumber'] as String).toList();
  }

  Future<void> saveProtocol({
    int? id,
    required String name,
    required String type,
    required List<String> values,
    required Map<int, List<String>> actions,
  }) async {
    final db = await database;
    final encodableActions = actions.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    final protocolData = {
      'name': name,
      'trigger_type': type,
      'trigger_value': jsonEncode(values.map((v) => v.toLowerCase()).toList()),
      'action_map': jsonEncode(encodableActions),
    };

    if (id != null) {
      await db.update(
        'protocols',
        protocolData,
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.insert('protocols', protocolData);
    }
  }

  Future<List<Map<String, dynamic>>> getAllProtocols() async {
    final db = await database;
    return await db.query('protocols');
  }

  Future<List<Map<String, dynamic>>> getProtocolStructure() async {
    final db = await database;
    return await db.rawQuery('PRAGMA table_info(protocols)');
  }

  Future<void> updateProtocol(
    int id,
    String type,
    List<String> values,
    String name,
    Map<int, List<String>> actions,
  ) async {
    final db = await database;
    await db.update(
      'protocols',
      {
        'trigger_type': type,
        'trigger_value': jsonEncode(
          values.map((v) => v.toLowerCase()).toList(),
        ),
        'action_map': jsonEncode(actions),
        'name': name,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Fetch full contact details for a specific tier
  Future<List<Map<String, dynamic>>> getDetailedContactsByTier(int tier) async {
    final db = await database;
    return await db.query(
      'contacts',
      where: 'tierLevel = ?',
      whereArgs: [tier],
    );
  }

  Future<List<Map<String, dynamic>>> getAllContacts() async {
    final db = await database;
    return await db.query('contacts');
  }

  // Remove a contact by its database ID
  Future<void> deleteContact(int id) async {
    final db = await database;
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteProtocol(int id) async {
    final db = await database;
    await db.delete('protocols', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveLocationHistory(
    String locationData,
    String recipients,
  ) async {
    final db = await database;
    await db.insert('locations', {
      'locationData': locationData,
      'recipients': recipients,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getRecentLocations() async {
    final db = await database;
    return await db.query('locations', orderBy: 'id DESC', limit: 10);
  }

  Future<void> saveRecordingMetadata(
    String title,
    String filePath,
    String duration,
  ) async {
    final db = await database;
    await db.insert('recordings', {
      'title': title,
      'filePath': filePath,
      'duration': duration,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getRecentRecordings() async {
    final db = await database;
    return await db.query('recordings', orderBy: 'id DESC', limit: 10);
  }

  Future<void> printDatabaseVersion() async {
    final db = await database;
    final version = await db.getVersion();
    print('Current Database Version: $version');
  }
}
