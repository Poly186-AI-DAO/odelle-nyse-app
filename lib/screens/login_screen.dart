import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/social_auth_provider.dart';
import '../models/user_model.dart';
import '../services/poly_auth_service.dart';
import '../constants/theme_constants.dart';
import '../constants/design_constants.dart';
import '../constants/app_routes.dart';
import '../utils/logger.dart';
import '../widgets/glass/dynamic_background.dart';
import '../widgets/glass/glass_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  String? _error;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: dotenv.env['GOOGLE_IOS_CLIENT_ID'],
    serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    scopes: [
      'email',
      'openid',
      'https://www.googleapis.com/auth/userinfo.profile',
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCachedLogin();
  }

  Future<void> _checkCachedLogin() async {
    try {
      final polyAuth = context.read<PolyAuthService>();
      final navigator = Navigator.of(context);
      final isAuthenticated = await polyAuth.isAuthenticated();

      Logger.info('Checking cached login', data: {
        'category': 'LoginScreen',
        'isAuthenticated': isAuthenticated,
      });

      if (isAuthenticated) {
        // Get user data from secure storage
        final userData = await polyAuth.getUserData();
        if (userData != null && mounted) {
          navigator.pushReplacementNamed(AppRoutes.home);
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Error checking cached login',
          data: {
            'category': 'LoginScreen',
            'error': e.toString(),
          },
          stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _handleSocialLogin(SocialAuthProvider provider) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final polyAuth = context.read<PolyAuthService>();
      final backendUser = switch (provider) {
        SocialAuthProvider.google => await _loginWithGoogle(polyAuth),
        SocialAuthProvider.facebook => await _loginWithFacebook(polyAuth),
        SocialAuthProvider.windows ||
        SocialAuthProvider.linkedin ||
        SocialAuthProvider.shopify ||
        SocialAuthProvider.tiktok ||
        SocialAuthProvider.notion ||
        SocialAuthProvider.slack ||
        SocialAuthProvider.x =>
          throw UnimplementedError(
              '${provider.displayLabel} login not yet implemented'),
      };

      Logger.info('Login successful', data: {
        'category': 'LoginScreen',
        'provider': provider.headerValue,
        'userId': backendUser.id,
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e, stackTrace) {
      final message = 'Failed to login with ${provider.displayLabel}';
      Logger.error(
        message,
        data: {
          'category': 'LoginScreen',
          'provider': provider.headerValue,
          'error': e.toString(),
        },
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _error = '$message: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<UserModel> _loginWithGoogle(PolyAuthService authService) async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final auth = await account.authentication;
    final serverAuthCode = account.serverAuthCode;
    final token = auth.idToken ?? '';
    if (token.isEmpty) {
      throw Exception('No ID token received from Google.');
    }

    final accountPayload = <String, dynamic>{
      'id_token': auth.idToken,
      if (serverAuthCode != null) 'refresh_token': serverAuthCode,
      'token_type': 'bearer',
      if (auth.accessToken != null) 'access_token': auth.accessToken,
    };

    return authService.loginWithProvider(
      provider: SocialAuthProvider.google,
      token: token,
      user: {
        'email': account.email,
        'name': account.displayName,
        'profileImage': account.photoUrl,
      },
      account: accountPayload,
    );
  }

  Future<UserModel> _loginWithFacebook(PolyAuthService authService) async {
    final result = await FacebookAuth.instance.login(
      permissions: const [
        'email',
        'public_profile',
        'pages_show_list',
        'pages_messaging',
        'pages_read_engagement',
        'pages_manage_engagement',
        'pages_manage_posts',
        'publish_video',
        'instagram_content_publish',
        'instagram_manage_insights',
        'instagram_manage_comments',
        'instagram_manage_messages',
        'whatsapp_business_messaging',
      ],
    );

    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw Exception(result.message ?? 'Facebook login failed.');
    }

    final accessToken = result.accessToken!;
    final userData = await FacebookAuth.instance.getUserData(
      fields: 'id,name,email,picture.width(400)',
    );
    final email = (userData['email'] as String?) ?? '';
    if (email.isEmpty) {
      throw Exception(
          'Facebook did not return an email address. Please ensure the email permission is granted.');
    }

    final accountPayload = <String, dynamic>{
      'expires_at': accessToken.expires.millisecondsSinceEpoch,
      'token_type': 'bearer',
      'granted_scopes': accessToken.grantedPermissions?.toList() ?? [],
    };

    return authService.loginWithProvider(
      provider: SocialAuthProvider.facebook,
      token: accessToken.token,
      user: {
        'email': email,
        'name': userData['name'],
        'profileImage': userData['picture']?['data']?['url'],
      },
      account: accountPayload,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScreen(
      backgroundType: BackgroundType.login,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: ThemeConstants.paddingScreen,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                SvgPicture.asset(
                  'assets/icons/poly_320x320.svg',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: ThemeConstants.spacingXXLarge),

                // Title
                Text(
                  'Login',
                  style: DesignConstants.headingXL,
                ),
                const SizedBox(height: ThemeConstants.spacingSmall),
                Text(
                  'Choose your login provider',
                  style: DesignConstants.bodyM,
                ),
                const SizedBox(height: ThemeConstants.spacingLarge),

                // Divider
                Container(
                  width: 60,
                  height: 2,
                  color: Colors.white.withOpacity(0.1),
                ),
                const SizedBox(height: ThemeConstants.spacingLarge),

                // Social Grid
                _buildSocialGrid(),

                // Dev Login (Hidden/Subtle)
                _buildDevLoginButton(),

                // Error message
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(
                        top: ThemeConstants.spacingMedium),
                    child: Text(
                      _error!,
                      style: DesignConstants.bodyS.copyWith(
                        color: ThemeConstants.errorColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialGrid() {
    final providers = [
      (icon: FontAwesomeIcons.google, provider: SocialAuthProvider.google),
      (icon: FontAwesomeIcons.facebookF, provider: SocialAuthProvider.facebook),
      (icon: FontAwesomeIcons.microsoft, provider: SocialAuthProvider.windows),
      (
        icon: FontAwesomeIcons.linkedinIn,
        provider: SocialAuthProvider.linkedin
      ),
      (icon: FontAwesomeIcons.shopify, provider: SocialAuthProvider.shopify),
      (icon: FontAwesomeIcons.tiktok, provider: SocialAuthProvider.tiktok),
      (icon: FontAwesomeIcons.notion, provider: SocialAuthProvider.notion),
      (icon: FontAwesomeIcons.slack, provider: SocialAuthProvider.slack),
      (icon: FontAwesomeIcons.xTwitter, provider: SocialAuthProvider.x),
    ];

    return Wrap(
      spacing: ThemeConstants.spacingMedium,
      runSpacing: ThemeConstants.spacingMedium,
      alignment: WrapAlignment.center,
      children: providers.map((item) {
        return GlassButton(
          onPressed:
              _isLoading ? null : () => _handleSocialLogin(item.provider),
          width: 64,
          height: 64,
          padding: EdgeInsets.zero,
          child: Center(
            child: FaIcon(
              item.icon,
              size: 24,
              color: ThemeConstants.textColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDevLoginButton() {
    return Padding(
      padding: const EdgeInsets.only(top: ThemeConstants.spacingLarge),
      child: TextButton(
        onPressed: () async {
          try {
            setState(() => _isLoading = true);
            final auth = context.read<PolyAuthService>();
            await auth.loginWithDevToken(
              token: 'poly-mobile-dev-2024-f8a3b7c9d1e4f6a2b8c5d7e9f1a3b5c7',
              userId: '90682750-261b-4f2c-ab5e-73691f17ded0::1.0',
              email: 'princepspolycap@gmail.com',
            );
            if (mounted) {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            }
          } catch (e) {
            setState(() => _error = e.toString());
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
        child: Text(
          'Dev Login',
          style: DesignConstants.bodyS.copyWith(
            color: ThemeConstants.polyWhite.withOpacity(0.5),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
