import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme_constants.dart';

class CyberpunkInstructionsEditor extends StatefulWidget {
  final String instructions;
  final Function(String) onInstructionsChanged;

  const CyberpunkInstructionsEditor({
    super.key,
    required this.instructions,
    required this.onInstructionsChanged,
  });

  @override
  State<CyberpunkInstructionsEditor> createState() =>
      _CyberpunkInstructionsEditorState();
}

class _CyberpunkInstructionsEditorState
    extends State<CyberpunkInstructionsEditor> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.instructions);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: ThemeConstants.spacingMedium,
        vertical: ThemeConstants.spacingSmall,
      ),
      padding: const EdgeInsets.all(ThemeConstants.spacingMedium),
      decoration: BoxDecoration(
        border: Border.all(
          color: ThemeConstants.borderColor,
          width: ThemeConstants.borderWidth,
        ),
        color: Colors.black87,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INSTRUCTIONS',
                style: GoogleFonts.pressStart2p(
                  color: ThemeConstants.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.save : Icons.edit,
                  color: ThemeConstants.primaryColor,
                  size: 20,
                ),
                onPressed: () {
                  if (_isEditing) {
                    widget.onInstructionsChanged(_controller.text);
                  }
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingMedium),
          Container(
            padding: const EdgeInsets.all(ThemeConstants.spacingMedium),
            decoration: BoxDecoration(
              border: Border.all(
                color: ThemeConstants.primaryColor.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: _isEditing
                ? TextField(
                    controller: _controller,
                    style: GoogleFonts.sourceCodePro(
                      color: ThemeConstants.primaryColor,
                      fontSize: 14,
                    ),
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter instructions...',
                      hintStyle: GoogleFonts.sourceCodePro(
                        color:
                            ThemeConstants.primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : Text(
                    widget.instructions,
                    style: GoogleFonts.sourceCodePro(
                      color: ThemeConstants.primaryColor,
                      fontSize: 14,
                    ),
                  ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: ThemeConstants.spacingSmall),
            Text(
              'Click save icon when done',
              style: GoogleFonts.pressStart2p(
                color: ThemeConstants.secondaryTextColor.withValues(alpha: 0.7),
                fontSize: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
