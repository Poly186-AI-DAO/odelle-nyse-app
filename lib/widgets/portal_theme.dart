import 'package:flutter/material.dart';
import '../constants/design_constants.dart';
import '../constants/theme_constants.dart';
import 'glass/glass_button.dart';

class PortalTheme extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showSystemHeader;

  const PortalTheme({
    super.key,
    required this.title,
    required this.child,
    this.showSystemHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: ThemeConstants.paddingMedium,
              child: Row(
                children: [
                  // Back button
                  if (canPop) ...[
                    GlassButton(
                      onPressed: () => Navigator.pop(context),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Back',
                            style: DesignConstants.bodyM,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: ThemeConstants.spacingMedium),
                  ],
                  // Title
                  Expanded(
                    child: Text(
                      title,
                      style: DesignConstants.headingM,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
