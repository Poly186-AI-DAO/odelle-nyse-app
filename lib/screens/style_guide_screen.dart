import 'package:flutter/material.dart';
import '../constants/design_constants.dart';
import '../constants/theme_constants.dart';
import '../widgets/buttons/gradient_button_modern.dart';
import '../widgets/glass/glass_card_modern.dart';
import '../widgets/inputs/glass_text_field.dart';
import '../widgets/portal_theme.dart';

class StyleGuideScreen extends StatelessWidget {
  const StyleGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PortalTheme(
      title: 'Style Guide',
      child: Container(
        decoration: BoxDecoration(
          gradient: ThemeConstants.orbyteDarkGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(DesignConstants.spaceL),
          children: [
            _buildSectionHeader('Typography'),
            _buildTypographySection(),
            const SizedBox(height: DesignConstants.spaceXL),
            _buildSectionHeader('Colors & Gradients'),
            _buildColorSection(),
            const SizedBox(height: DesignConstants.spaceXL),
            _buildSectionHeader('Buttons'),
            _buildButtonSection(),
            const SizedBox(height: DesignConstants.spaceXL),
            _buildSectionHeader('Glass Cards'),
            _buildCardSection(),
            const SizedBox(height: DesignConstants.spaceXL),
            _buildSectionHeader('Inputs'),
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        const GlassTextField(
          hintText: 'Search notes...',
          prefixIcon: Icons.search,
        ),
        const SizedBox(height: 16),
        const GlassTextField(
          hintText: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spaceM),
      child: Text(
        title,
        style: DesignConstants.headingM.copyWith(
          color: DesignConstants.orbyteOrange,
        ),
      ),
    );
  }

  Widget _buildTypographySection() {
    return GlassCardModern(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Display Large', style: DesignConstants.displayL),
          const SizedBox(height: 8),
          Text('Heading XL', style: DesignConstants.headingXL),
          const SizedBox(height: 8),
          Text('Heading L', style: DesignConstants.headingL),
          const SizedBox(height: 8),
          Text('Heading M', style: DesignConstants.headingM),
          const SizedBox(height: 8),
          Text('Body Large', style: DesignConstants.bodyL),
          const SizedBox(height: 8),
          Text('Body Medium', style: DesignConstants.bodyM),
          const SizedBox(height: 8),
          Text('Caption', style: DesignConstants.captionText),
        ],
      ),
    );
  }

  Widget _buildColorSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildColorSwatch('Purple', DesignConstants.orbytePurple),
            _buildColorSwatch('Orange', DesignConstants.orbyteOrange),
            _buildColorSwatch('Dark Bg', DesignConstants.orbyteBackground),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: ThemeConstants.orbytePrimaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Primary Gradient',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSwatch(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
        ),
        const SizedBox(height: 8),
        Text(name, style: DesignConstants.bodyS),
      ],
    );
  }

  Widget _buildButtonSection() {
    return Column(
      children: [
        GradientButtonModern(
          text: 'Primary Action',
          onPressed: () {},
          icon: Icons.rocket_launch,
        ),
        const SizedBox(height: 16),
        GradientButtonModern(
          text: 'Loading State',
          onPressed: () {},
          isLoading: true,
        ),
      ],
    );
  }

  Widget _buildCardSection() {
    return Column(
      children: [
        GlassCardModern(
          showGlow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DesignConstants.orbytePurple.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: DesignConstants.orbytePurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('AI Assistant', style: DesignConstants.headingS),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'This is a glowing glass card with the new Orbyte style. It uses a subtle gradient border and backdrop blur.',
                style: DesignConstants.bodyM,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCardModern(
          gradient: LinearGradient(
            colors: [
              DesignConstants.orbytePurple.withOpacity(0.1),
              DesignConstants.orbyteOrange.withOpacity(0.1),
            ],
          ),
          child: const Center(
            child: Text(
              'Gradient Glass Card',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
