import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peri_lily_android/core/enums.dart';

import '../database/database.dart';
import '../dispatch/dispatch_service.dart';
import '../settings/settings_screen.dart';

enum TapRegion { upper, middle, lower }

class DecoyGestureWrapper extends ConsumerStatefulWidget {
  final DecoyType decoyType;
  final Widget child;

  const DecoyGestureWrapper({
    super.key,
    required this.decoyType,
    required this.child,
  });

  @override
  ConsumerState<DecoyGestureWrapper> createState() => _DecoyGestureWrapperState();
}

class _DecoyGestureWrapperState extends ConsumerState<DecoyGestureWrapper> {
  Map<String, int?> _gestureMap = {};
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadGestureMap();
  }

  Future<void> _loadGestureMap() async {
    final db = ref.read(databaseProvider);
    final rows = await db.getGestureMapForDecoy(widget.decoyType.dbValue);
    final map = <String, int?>{
      for (var row in rows) row['gestureSlot'] as String: row['protocolId'] as int?,
    };

    if (mounted) {
      setState(() {
        _gestureMap = map;
        _ready = true;
      });
    }
  }

  TapRegion _getRegion(Offset position, double screenHeight) {
    final y = position.dy;
    if (y < screenHeight * 0.33) return TapRegion.upper;
    if (y < screenHeight * 0.66) return TapRegion.middle;
    return TapRegion.lower;
  }

  String? _slotForDoubleTap(TapRegion region) {
    switch (region) {
      case TapRegion.upper:
        return Gestures.upperDouble.dbValue;
      case TapRegion.middle:
        return Gestures.middleDouble.dbValue;
      case TapRegion.lower:
        return Gestures.lowerDouble.dbValue;
    }
  }

  String? _slotForLongPress(TapRegion region) {
    switch (region) {
      case TapRegion.upper:
        return Gestures.upperLong.dbValue;
      case TapRegion.lower:
        return Gestures.lowerLong.dbValue;
      case TapRegion.middle:
        return null;
    }
  }

  Future<void> _fireSlot(String? slotKey) async {
    if (slotKey == null) return;

    final protocolId = _gestureMap[slotKey];
    if (protocolId == null) {
      debugPrint('No protocol assigned to slot: $slotKey');
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

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white54)),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onDoubleTapDown: (details) {
        final region = _getRegion(details.localPosition, screenHeight);
        _fireSlot(_slotForDoubleTap(region));
      },
      onLongPressStart: (details) {
        final region = _getRegion(details.localPosition, screenHeight);
        _fireSlot(_slotForLongPress(region));
      },
      child: widget.child,
    );
  }
}