import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/theme_constants.dart';
import '../widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  List<dynamic> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    try {
      // 1. Load User Profile
      final profileJson = await rootBundle.loadString('data/user/user_profile.json');
      final List<dynamic> profileList = json.decode(profileJson);
      if (profileList.isNotEmpty) {
        _userProfile = profileList.first;
      }

      // 2. Load Achievements
      final achievementsJson = await rootBundle.loadString('data/gamification/achievement.json');
      _achievements = json.decode(achievementsJson);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userProfile == null) {
      return const Center(child: Text("User profile not found"));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Header
            ProfileHeader(
              name: '${_userProfile!['first_name']} ${_userProfile!['last_name']}',
              bio: _userProfile!['bio'] ?? 'No bio yet.',
              location: _userProfile!['location'] ?? 'Unknown',
              avatarUrl: _userProfile!['photo_url'],
              totalWorkouts: 42, // Mock from aggregations
              totalMindfulness: 18,
            ),

            const SizedBox(height: 40),

            // Achievements Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACHIEVEMENTS',
                    style: ThemeConstants.subheadingStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: _achievements.map((achievement) {
                      return AchievementBadge(
                        title: achievement['name'],
                        icon: achievement['icon_url'] ?? '🏆', // Emoji fallback
                        isLocked: false, // Assume unlocked for demo
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Settings / Account Options
            _buildOptionTile(Icons.person_outline, 'Personal Details'),
            _buildOptionTile(Icons.notifications_outlined, 'Notifications'),
            _buildOptionTile(Icons.privacy_tip_outlined, 'Privacy & Data'),
            _buildOptionTile(Icons.help_outline, 'Help & Support'),
            _buildOptionTile(Icons.logout, 'Log Out', isDestructive: true),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon, 
        color: isDestructive ? ThemeConstants.uiError : ThemeConstants.textSecondary,
      ),
      title: Text(
        title,
        style: ThemeConstants.bodyStyle.copyWith(
          color: isDestructive ? ThemeConstants.uiError : ThemeConstants.textOnLight,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: ThemeConstants.textMuted),
      onTap: () {},
    );
  }
}
