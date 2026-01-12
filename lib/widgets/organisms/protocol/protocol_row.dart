import 'package:flutter/material.dart';
import '../../../../models/protocol_entry.dart';
import 'protocol_button.dart';

/// Row of protocol buttons for quick logging
class ProtocolRow extends StatelessWidget {
  final Map<ProtocolType, ProtocolButtonState> states;
  final Map<ProtocolType, String>? progressTexts;
  final Function(ProtocolType) onTap;
  final Function(ProtocolType)? onLongPress;
  final List<ProtocolType> types;
  final double buttonSize;
  final double spacing;

  const ProtocolRow({
    super.key,
    required this.states,
    this.progressTexts,
    required this.onTap,
    this.onLongPress,
    this.types = const [
      ProtocolType.gym,
      ProtocolType.meal,
      ProtocolType.dose,
      ProtocolType.meditation,
    ],
    this.buttonSize = 72,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: types.asMap().entries.map((entry) {
          final type = entry.value;
          final isLast = entry.key == types.length - 1;
          
          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : spacing),
            child: ProtocolButton(
              type: type,
              buttonState: states[type] ?? ProtocolButtonState.empty,
              progressText: progressTexts?[type],
              onTap: () => onTap(type),
              onLongPress: onLongPress != null ? () => onLongPress!(type) : null,
              size: buttonSize,
            ),
          );
        }).toList(),
      ),
    );
  }
}
