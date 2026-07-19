import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/enums.dart';

final databaseProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
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
      version: 2,
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

    await db.execute('''
      CREATE TABLE gesture_map (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        decoyType   TEXT NOT NULL,
        gestureSlot TEXT NOT NULL,
        protocolId  INTEGER,
        UNIQUE(decoyType, gestureSlot)
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key   TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      db.execute('''
        CREATE TABLE gesture_map(
          id $idType,
          decoyType $textType,
          gestureSlot $textType, 
          protocolId INTEGER,
          UNIQUE(decoyType, gestureSlot)
        )
      ''');

      final decoyTypes = [
        DecoyType.fakeCall.dbValue,
        DecoyType.socialFeed.dbValue,
        DecoyType.notesDash.dbValue,
      ];
      final List<String> slots = [
        Gestures.upperDouble.dbValue,
        Gestures.upperLong.dbValue,
        Gestures.middleDouble.dbValue,
        Gestures.lowerDouble.dbValue,
        Gestures.lowerLong.dbValue,
      ];

      for (var type in decoyTypes) {
        for (var slot in slots) {
          await db.insert('gesture_map', {
            'decoyType': type,
            'gestureSlot': slot,
            'protocolId': null,
          });
        }
      }

      await db.execute('''
          CREATE TABLE app_settings (
            key   TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
    }
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

  Future<Map<String, dynamic>?> getProtocolById(int id) async {
    final db = await database;
    final result = await db.query('protocols', where: 'id = ?', whereArgs: [id]);
    return result.isEmpty ? null : result.first;
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

  Future<void> setGestureProtocol(String decoyType, String slot, int? protocolId) async {
    final db = await database;
    await db.update(
      'gesture_map',
      {'protocolId': protocolId},
      where: 'decoyType = ? AND gestureSlot = ?',
      whereArgs: [decoyType, slot],
    );
  }

  Future<List<Map<String, dynamic>>> getGestureMapForDecoy(String decoyType) async {
    final db = await database;
    return await db.query(
      'gesture_map',
      where: 'decoyType = ?',
      whereArgs: [decoyType],
    );
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return result.isEmpty ? null : result.first['value'] as String?;
  }

}
