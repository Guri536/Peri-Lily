import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peri_lily_android/features/database/database.dart';
import 'package:peri_lily_android/features/dispatch/dispatch_service.dart';

class ProtocolTrigger {
  static Future<void> fire(WidgetRef ref, int? protocolId) async {
    if (protocolId == null) {
      debugPrint('No protocol assigned to this trigger');
      return;
    }

    final db = ref.read(databaseProvider);
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
}