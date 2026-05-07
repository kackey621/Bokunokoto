import 'package:flutter/material.dart';
import '../models/symbol.dart';

class SymbolBadge extends StatelessWidget {
  final String? symbolType;
  final int requiredLevel;
  final bool isVisible;

  const SymbolBadge({
    Key? key,
    required this.symbolType,
    required this.requiredLevel,
    this.isVisible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible || symbolType == null) {
      return const SizedBox.shrink();
    }

    final symbol = SymbolTypeExt.fromString(symbolType);
    if (symbol == null) return const SizedBox.shrink();

    return Tooltip(
      message: symbol.label,
      child: Semantics(
        label: 'Symbol: ${symbol.label}',
        button: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: symbol.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: symbol.color,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                symbol.icon,
                size: 14,
                color: symbol.color,
              ),
              const SizedBox(width: 4),
              Text(
                symbol.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: symbol.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
