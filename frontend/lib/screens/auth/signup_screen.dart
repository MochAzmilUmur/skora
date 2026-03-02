import 'package:flutter/material.dart';
import 'package:animated_login/animated_login.dart';
import 'package:frontend/widgets/dialog_builder.dart';
import 'package:frontend/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  LanguageOption language = _languageOptions[1];

  @override
  Widget build(BuildContext context) {
    return AnimatedLogin(
      onSignup: AuthService(context).onSignup,
      
      logo: Image.asset('assets/kroniva.webp'),
      signUpMode: SignUpModes.both,
      socialLogins: _socialLogins(context),
      loginDesktopTheme: _desktopTheme,
      loginMobileTheme: _mobileTheme,
      loginTexts: _loginTexts,
      changeLanguageCallback: (LanguageOption? selectedLanguage) {
        if (selectedLanguage != null) {
          DialogBuilder(context).showResultDialog(
              'Successfully changed the language to: ${selectedLanguage.value}.');
          if (mounted) setState(() => language = selectedLanguage);
        }
      },
      languageOptions: _languageOptions,
      selectedLanguage: language,
      initialMode: AuthMode.signup,
    );
  }

  static List<LanguageOption> get _languageOptions => const <LanguageOption>[
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
              optionMargin: EdgeInsets.symmetric(horizontal: 80)),
        ),
      );

  LoginViewTheme get _mobileTheme => LoginViewTheme(
        backgroundColor: Colors.blue,
        formFieldBackgroundColor: Colors.white,
        formWidthRatio: 60,
        checkColor: Colors.blue,
      );

  LoginTexts get _loginTexts => LoginTexts(
        nameHint: _username,
        login: _login,
        signUp: _signup,
      );

  String get _username => language.code == 'TR' ? 'Kullanıcı Adı' : 'Username';
  String get _login => language.code == 'TR' ? 'Giriş Yap' : 'Login';
  String get _signup => language.code == 'TR' ? 'Kayıt Ol' : 'Sign Up';

  List<SocialLogin> _socialLogins(BuildContext context) => <SocialLogin>[
        SocialLogin(
            callback: () async => AuthService(context).socialLogin('Google'),
            iconPath: 'assets/images/google.png'),
        SocialLogin(
            callback: () async => AuthService(context).socialLogin('Facebook'),
            iconPath: 'assets/images/facebook.png'),
        SocialLogin(
            callback: () async => AuthService(context).socialLogin('Linkedin'),
            iconPath: 'assets/images/linkedin.png'),
      ];
}