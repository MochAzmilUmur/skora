import 'package:flutter/material.dart';
import 'package:animated_login/animated_login.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/language_constants.dart';
import '../../../../widgets/dialog_builder.dart';
import '../controllers/auth_controller.dart';

class SignupScreenRefactored extends StatefulWidget {
  const SignupScreenRefactored({super.key});

  @override
  State<SignupScreenRefactored> createState() => _SignupScreenRefactoredState();
}

class _SignupScreenRefactoredState extends State<SignupScreenRefactored> {
  LanguageOption _language = _languageOptions[1];

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return AnimatedLogin(
      onSignup: (SignUpData data) => authController.handleSignup(data),
      logo: Image.asset('assets/kroniva.webp'),
      signUpMode: SignUpModes.both,
      socialLogins: _buildSocialLogins(authController),
      loginDesktopTheme: _desktopTheme,
      loginMobileTheme: _mobileTheme,
      loginTexts: _buildLoginTexts(),
      changeLanguageCallback: _handleLanguageChange,
      languageOptions: _languageOptions,
      selectedLanguage: _language,
      initialMode: AuthMode.signup,
    );
  }

  void _handleLanguageChange(LanguageOption? selectedLanguage) {
    if (selectedLanguage != null) {
      final message = LanguageConstants.translate('languageChanged', selectedLanguage.code);
      DialogBuilder(context).showResultDialog('$message ${selectedLanguage.value}');
      if (mounted) setState(() => _language = selectedLanguage);
    }
  }

  List<SocialLogin> _buildSocialLogins(AuthController controller) => [
        SocialLogin(
          callback: () => controller.handleSocialLogin('Google'),
          iconPath: 'assets/images/google.png',
        ),
        SocialLogin(
          callback: () => controller.handleSocialLogin('Facebook'),
          iconPath: 'assets/images/facebook.png',
        ),
        SocialLogin(
          callback: () => controller.handleSocialLogin('Linkedin'),
          iconPath: 'assets/images/linkedin.png',
        ),
      ];

  LoginTexts _buildLoginTexts() => LoginTexts(
        nameHint: LanguageConstants.translate('username', _language.code),
        login: LanguageConstants.translate('login', _language.code),
        signUp: LanguageConstants.translate('signup', _language.code),
      );

  static List<LanguageOption> get _languageOptions => const [
        LanguageOption(
          value: 'Turkish',
          code: 'TR',
          iconPath: 'assets/images/tr.png',
        ),
        LanguageOption(
          value: 'English',
          code: 'EN',
          iconPath: 'assets/images/en.png',
        ),
      ];

  LoginViewTheme get _desktopTheme => _mobileTheme.copyWith(
        actionButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(Colors.white),
        ),
        dialogTheme: const AnimatedDialogTheme(
          languageDialogTheme: LanguageDialogTheme(
            optionMargin: EdgeInsets.symmetric(horizontal: 80),
          ),
        ),
      );

  LoginViewTheme get _mobileTheme => LoginViewTheme(
        backgroundColor: Colors.blue,
        formFieldBackgroundColor: Colors.white,
        formWidthRatio: 60,
        checkColor: Colors.blue,
      );
}
