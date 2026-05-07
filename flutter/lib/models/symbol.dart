import 'package:flutter/material.dart';

enum SymbolType {
  eye,
  lock,
  heart,
  star,
  alert,
  check,
  clock,
  fire,
  shield,
  secret,
}

extension SymbolTypeExt on SymbolType {
  String get name {
    return toString().split('.').last;
  }

  IconData get icon {
    switch (this) {
      case SymbolType.eye:
        return Icons.visibility;
      case SymbolType.lock:
        return Icons.lock;
      case SymbolType.heart:
        return Icons.favorite;
      case SymbolType.star:
        return Icons.star;
      case SymbolType.alert:
        return Icons.warning;
      case SymbolType.check:
        return Icons.check_circle;
      case SymbolType.clock:
        return Icons.schedule;
      case SymbolType.fire:
        return Icons.local_fire_department;
      case SymbolType.shield:
        return Icons.security;
      case SymbolType.secret:
        return Icons.vpn_key;
    }
  }

  String get label {
    switch (this) {
      case SymbolType.eye:
        return 'Watch carefully';
      case SymbolType.lock:
        return 'Private information';
      case SymbolType.heart:
        return 'Personal';
      case SymbolType.star:
        return 'Important';
      case SymbolType.alert:
        return 'Urgent';
      case SymbolType.check:
        return 'Verified';
      case SymbolType.clock:
        return 'Time-sensitive';
      case SymbolType.fire:
        return 'Sensitive';
      case SymbolType.shield:
        return 'Protected';
      case SymbolType.secret:
        return 'Confidential';
    }
  }

  Color get color {
    switch (this) {
      case SymbolType.eye:
        return Colors.blue;
      case SymbolType.lock:
        return Colors.red;
      case SymbolType.heart:
        return Colors.pink;
      case SymbolType.star:
        return Colors.amber;
      case SymbolType.alert:
        return Colors.orange;
      case SymbolType.check:
        return Colors.green;
      case SymbolType.clock:
        return Colors.purple;
      case SymbolType.fire:
        return Colors.deepOrange;
      case SymbolType.shield:
        return Colors.indigo;
      case SymbolType.secret:
        return Colors.grey;
    }
  }

  static SymbolType? fromString(String? value) {
    if (value == null) return null;
    try {
      return SymbolType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SymbolType.secret,
      );
    } catch (e) {
      return null;
    }
  }
}
