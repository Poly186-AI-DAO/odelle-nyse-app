import 'dart:convert';

import 'package:flutter/services.dart';

import '../utils/logger.dart';

/// UserContextService - Loads the full user context documents for LLM consumption
///
/// Provides the LLM with complete context about the user:
/// - Princeps_Prime.md - Identity, archetypes, mission, philosophy
/// - Princeps_Mantras.md - 694 affirmations organized by protocol
/// - WHITEPAPER.md - The 10-week experiment, supplements, daily schedule, CBT reframes
///
/// No compression - LLMs have 120k-400k context windows, we pass everything as-is.
class UserContextService {
  static const String _tag = 'UserContextService';

  // Cached content
  String? _primeContent;
  String? _mantrasContent;
  String? _whitepaperContent;
  Map<String, dynamic>? _genesisProfile;

  // Parsed data
  List<MantraCategory>? _mantraCategories;
  List<SupplementConfig>? _supplements;

  bool _isLoaded = false;

  /// Whether the context has been loaded
  bool get isLoaded => _isLoaded;

  /// Load all context documents
  Future<void> loadContext() async {
    if (_isLoaded) return;

    Logger.info('Loading user context documents...', tag: _tag);

    try {
      // Load the 3 markdown documents
      _primeContent = await _loadAsset('docs/Princeps_Prime.md');
      _mantrasContent = await _loadAsset('docs/Princeps_Mantras.md');
      _whitepaperContent = await _loadAsset('docs/WHITEPAPER.md');

      // Load genesis profile JSON
      final genesisJson = await _loadAsset('data/user/genesis_profile.json');
      if (genesisJson != null) {
        _genesisProfile = jsonDecode(genesisJson) as Map<String, dynamic>;
      }

      // Parse mantras into categories
      if (_mantrasContent != null) {
        _mantraCategories = _parseMantras(_mantrasContent!);
        Logger.info(
          'Parsed ${_mantraCategories!.length} mantra categories with '
          '${_mantraCategories!.fold<int>(0, (sum, cat) => sum + cat.mantras.length)} total mantras',
          tag: _tag,
        );
      }

      // Parse supplements from whitepaper
      if (_whitepaperContent != null) {
        _supplements = _parseSupplements(_whitepaperContent!);
        Logger.info('Parsed ${_supplements!.length} supplements', tag: _tag);
      }

      _isLoaded = true;
      Logger.info('User context loaded successfully', tag: _tag);
    } catch (e, stack) {
      Logger.error('Failed to load user context: $e',
          tag: _tag, error: e, stackTrace: stack);
    }
  }

  /// Load an asset file, returning null if not found
  Future<String?> _loadAsset(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      Logger.warning('Asset not found: $path', tag: _tag);
      return null;
    }
  }

  /// Get the full system prompt for the LLM with all user context
  ///
  /// This is the complete context - no compression.
  /// Pass this as the system prompt to give the LLM full understanding of the user.
  String getFullSystemPrompt() {
    final buffer = StringBuffer();

    buffer.writeln('# USER CONTEXT - PRINCEPS POLYCAP');
    buffer.writeln('');
    buffer.writeln(
        'You are the AI companion for Princeps Polycap. Below is everything you need to know about him.');
    buffer.writeln(
        'Use this context to personalize all responses, generate content that aligns with his values,');
    buffer.writeln(
        'and help him on his journey of self-actualization through the Odelle Nyse protocol.');
    buffer.writeln('');

    // Genesis Profile (structured data)
    if (_genesisProfile != null) {
      buffer.writeln('## IDENTITY & COSMIC PROFILE');
      buffer.writeln('```json');
      buffer
          .writeln(const JsonEncoder.withIndent('  ').convert(_genesisProfile));
      buffer.writeln('```');
      buffer.writeln('');
    }

    // Prime document (full)
    if (_primeContent != null) {
      buffer.writeln('## PRINCEPS PRIME - WHO I AM');
      buffer.writeln(_primeContent);
      buffer.writeln('');
    }

    // Mantras document (full)
    if (_mantrasContent != null) {
      buffer.writeln('## MY MANTRAS & PROTOCOLS');
      buffer.writeln(_mantrasContent);
      buffer.writeln('');
    }

    // Whitepaper (full)
    if (_whitepaperContent != null) {
      buffer.writeln('## THE ODELLE NYSE PROTOCOL (WHITEPAPER)');
      buffer.writeln(_whitepaperContent);
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// Get a shorter context for quick queries (still substantial)
  ///
  /// Includes: Genesis profile + archetypes + mission + sample mantras
  String getQuickContext() {
    final buffer = StringBuffer();

    buffer.writeln('# USER: PRINCEPS POLYCAP');
    buffer.writeln('');

    if (_genesisProfile != null) {
      final identity = _genesisProfile!['identity'] as Map<String, dynamic>?;
      final mission = _genesisProfile!['mission'] as Map<String, dynamic>?;
      final archetypes =
          _genesisProfile!['archetypes'] as Map<String, dynamic>?;
      final cosmic = _genesisProfile!['cosmicProfile'] as Map<String, dynamic>?;

      buffer.writeln('## Identity');
      buffer.writeln('- Name: ${identity?['name'] ?? 'Princeps Polycap'}');
      buffer.writeln('- DOB: ${identity?['dateOfBirth'] ?? '1996-06-18'}');
      buffer.writeln('- MBTI: ${identity?['mbti'] ?? 'INTJ'}');
      buffer.writeln('');

      final zodiac = identity?['zodiac'] as Map<String, dynamic>?;
      if (zodiac != null) {
        buffer.writeln('## Astrology');
        buffer.writeln('- Sun: ${zodiac['sun']} (The Communicator)');
        buffer.writeln('- Moon: ${zodiac['moon']} (Emotional harmony seeker)');
        buffer.writeln(
            '- Rising: ${zodiac['rising']} (Intense, magnetic presence)');
        buffer.writeln('');
      }

      final numerology = identity?['numerology'] as Map<String, dynamic>?;
      if (numerology != null) {
        buffer.writeln('## Numerology');
        buffer.writeln(
            '- Life Path: ${numerology['lifePathNumber']} (The Builder)');
        buffer.writeln(
            '- Birth Number: ${numerology['birthNumber']} (The Diplomat)');
        buffer
            .writeln('- Destiny: ${numerology['destinyNumber']} (The Seeker)');
        buffer.writeln('');
      }

      final primary = archetypes?['primary'] as Map<String, dynamic>?;
      if (primary != null) {
        buffer.writeln('## Archetypes');
        buffer.writeln('- Ego: ${primary['ego']} (The Hero)');
        buffer.writeln('- Soul: ${primary['soul']} (The Creator)');
        buffer.writeln('- Self: ${primary['self']} (The Magician)');
        buffer.writeln('');
      }

      if (cosmic != null) {
        buffer.writeln('## Cosmic Synthesis');
        buffer.writeln(cosmic['synthesis']);
        buffer.writeln('');
      }

      if (mission != null) {
        buffer.writeln('## Mission');
        buffer.writeln('- Primary: ${mission['primary']}');
        buffer.writeln('- Vision: ${mission['vision']}');
        buffer.writeln('');
      }
    }

    // Add sample mantras
    if (_mantraCategories != null && _mantraCategories!.isNotEmpty) {
      buffer.writeln('## Sample Mantras');
      for (final category in _mantraCategories!.take(3)) {
        buffer.writeln('### ${category.name}');
        for (final mantra in category.mantras.take(5)) {
          buffer.writeln('- $mantra');
        }
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// Get genesis profile data
  Map<String, dynamic>? get genesisProfile => _genesisProfile;

  /// Get all mantra categories
  List<MantraCategory> get mantraCategories => _mantraCategories ?? [];

  /// Get all mantras as a flat list
  List<String> get allMantras {
    if (_mantraCategories == null) return [];
    return _mantraCategories!.expand((cat) => cat.mantras).toList();
  }

  /// Get supplements parsed from whitepaper
  List<SupplementConfig> get supplements => _supplements ?? [];

  /// Generate a psychograph prophecy reading
  ///
  /// This creates a mythological, prophecy-style reading of the user's
  /// cosmic profile, numerology, and archetypes for the current day.
  String generatePsychographPrompt(DateTime date) {
    final dayOfWeek = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ][date.weekday % 7];

    final identity = _genesisProfile?['identity'] as Map<String, dynamic>?;
    final zodiac = identity?['zodiac'] as Map<String, dynamic>?;
    final numerology = identity?['numerology'] as Map<String, dynamic>?;
    final archetypes = _genesisProfile?['archetypes'] as Map<String, dynamic>?;
    final primary = archetypes?['primary'] as Map<String, dynamic>?;
    final cosmic = _genesisProfile?['cosmicProfile'] as Map<String, dynamic>?;

    return '''
Generate a psychograph prophecy reading for Princeps Polycap for $dayOfWeek, ${date.month}/${date.day}/${date.year}.

This should be a 2-3 paragraph mythological, inspiring reading that:
1. Speaks in second person ("You are...")
2. Weaves together his cosmic profile as a prophecy
3. Connects today's energy to his mission
4. Feels like a wise sage speaking eternal truths
5. Is specific to HIM, not generic horoscope fluff

HIS COSMIC PROFILE:
- Sun: ${zodiac?['sun'] ?? 'Gemini'} (The Communicator - intellectual curiosity, adaptability)
- Moon: ${zodiac?['moon'] ?? 'Libra'} (Emotional harmony seeker, values balance)
- Rising: ${zodiac?['rising'] ?? 'Scorpio'} (Intense, magnetic, transformative presence)
- Life Path: ${numerology?['lifePathNumber'] ?? 4} (The Builder - methodical, creates lasting foundations)
- Birth Number: ${numerology?['birthNumber'] ?? 2} (The Diplomat - bridge between worlds)
- Destiny Number: ${numerology?['destinyNumber'] ?? 7} (The Seeker - pursuer of hidden truths)

HIS ARCHETYPES:
- Ego: ${primary?['ego'] ?? 'Hero'} - Where there's a will, there's a way
- Soul: ${primary?['soul'] ?? 'Creator'} - If you can imagine it, it can be done
- Self: ${primary?['self'] ?? 'Magician'} - I make things happen

COSMIC SYNTHESIS:
${cosmic?['synthesis'] ?? 'A Gemini sun\'s intellectual versatility combined with Libra moon\'s emotional equilibrium, projected through Scorpio rising\'s transformative intensity.'}

HIS MISSION:
To raise the conscious awareness of the human race. Data-driven behavioral change in pursuit of self-actualization.

Write the prophecy now. Make it feel mythic, personal, and inspiring.
Do NOT use generic phrases like "the stars align" - be specific to his profile.
''';
  }

  /// Parse mantras from the markdown file into categories
  List<MantraCategory> _parseMantras(String content) {
    final categories = <MantraCategory>[];
    String? currentCategory;
    final currentMantras = <String>[];

    for (final line in content.split('\n')) {
      final trimmed = line.trim();

      // Check for category header (contains #protocol)
      if (trimmed.contains('#protocol')) {
        // Save previous category if exists
        if (currentCategory != null && currentMantras.isNotEmpty) {
          categories.add(MantraCategory(
            name: currentCategory,
            mantras: List.from(currentMantras),
          ));
          currentMantras.clear();
        }
        // Extract category name (text before #protocol)
        currentCategory =
            trimmed.replaceAll('#protocol', '').replaceAll('#', '').trim();
      } else if (trimmed.isNotEmpty &&
          !trimmed.startsWith('-') &&
          !trimmed.startsWith('```') &&
          currentCategory != null) {
        // This is a mantra line
        // Clean up any markdown formatting
        var mantra = trimmed;
        if (mantra.startsWith('- ')) mantra = mantra.substring(2);
        if (mantra.isNotEmpty && mantra.length > 5) {
          currentMantras.add(mantra);
        }
      }
    }

    // Save last category
    if (currentCategory != null && currentMantras.isNotEmpty) {
      categories.add(MantraCategory(
        name: currentCategory,
        mantras: List.from(currentMantras),
      ));
    }

    return categories;
  }

  /// Parse supplements from whitepaper
  List<SupplementConfig> _parseSupplements(String content) {
    // These are the supplements mentioned in the whitepaper + user's additions
    return [
      // From whitepaper: psilocybin protocol
      SupplementConfig(
        name: 'Psilocybin Microdose',
        brand: 'Protocol Supply',
        category: 'nootropic',
        defaultDoseMg: 250,
        unit: 'mg',
        notes:
            '40 capsules x 250mg. Take Mon/Tue/Thu/Fri at 6:45 AM. Wednesday = integration day.',
        isActive: true,
        takeWithFood: false,
        maxDailyMg: 250,
        preferredTimes: ['06:45'],
      ),
      // User's additions
      SupplementConfig(
        name: 'B-Complex with B-12',
        brand: 'Generic',
        category: 'vitamin',
        defaultDoseMg: 1000, // typical B-12 dose in mcg = 1000
        unit: 'mcg',
        notes: 'B-vitamin complex including B-12 for energy and nerve health',
        isActive: true,
        takeWithFood: true,
        preferredTimes: ['morning'],
      ),
      SupplementConfig(
        name: 'Multivitamin',
        brand: 'Centrum Advanced',
        category: 'vitamin',
        defaultDoseMg: 1, // 1 tablet
        unit: 'tablet',
        notes: 'Daily multivitamin for general health',
        isActive: true,
        takeWithFood: true,
        preferredTimes: ['morning'],
      ),
      // Common additions for the protocol
      SupplementConfig(
        name: 'Vitamin D3',
        brand: 'Generic',
        category: 'vitamin',
        defaultDoseMg: 5000,
        unit: 'IU',
        notes: 'Fat-soluble, take with fatty meal for absorption',
        isActive: true,
        takeWithFood: true,
        takeWithFat: true,
        preferredTimes: ['morning'],
      ),
      SupplementConfig(
        name: 'Omega-3 Fish Oil',
        brand: 'Generic',
        category: 'essential_fatty_acid',
        defaultDoseMg: 1000,
        unit: 'mg',
        notes: 'EPA/DHA for brain health, anti-inflammatory',
        isActive: true,
        takeWithFood: true,
        preferredTimes: ['morning'],
      ),
      SupplementConfig(
        name: 'Magnesium Glycinate',
        brand: 'Generic',
        category: 'mineral',
        defaultDoseMg: 400,
        unit: 'mg',
        notes: 'For sleep quality and muscle recovery. Take before bed.',
        isActive: true,
        takeWithFood: false,
        preferredTimes: ['evening'],
      ),
    ];
  }
}

/// A category of mantras (e.g., "Flow States", "I Am Spells")
class MantraCategory {
  final String name;
  final List<String> mantras;

  const MantraCategory({
    required this.name,
    required this.mantras,
  });
}

/// A supplement configuration (from user documents)
/// This is a simple data class - converted to models.tracking.Supplement for database storage
class SupplementConfig {
  final String name;
  final String? brand;
  final String category;
  final double defaultDoseMg;
  final String unit;
  final String? notes;
  final bool isActive;
  final bool takeWithFood;
  final bool takeWithFat;
  final double? maxDailyMg;
  final List<String>? preferredTimes;
  final List<String>? interactions;
  final String? imageUrl;

  const SupplementConfig({
    required this.name,
    this.brand,
    required this.category,
    required this.defaultDoseMg,
    this.unit = 'mg',
    this.notes,
    this.isActive = true,
    this.takeWithFood = false,
    this.takeWithFat = false,
    this.maxDailyMg,
    this.preferredTimes,
    this.interactions,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'brand': brand,
        'category': category,
        'default_dose_mg': defaultDoseMg,
        'unit': unit,
        'notes': notes,
        'is_active': isActive ? 1 : 0,
        'take_with_food': takeWithFood ? 1 : 0,
        'take_with_fat': takeWithFat ? 1 : 0,
        'max_daily_mg': maxDailyMg,
        'preferred_times': preferredTimes?.join(','),
        'interactions': interactions?.join(','),
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      };
}
