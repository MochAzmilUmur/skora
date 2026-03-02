import 'package:flutter/material.dart';
import 'package:animated_login/animated_login.dart';
import 'package:frontend/widgets/dialog_builder.dart';
import 'package:frontend/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LanguageOption language = _languageOptions[1];

  @override
  Widget build(BuildContext context) {
    return AnimatedLogin(
      onLogin: AuthService(context).onLogin,
      onSignup: AuthService(context).onSignup,
      onForgotPassword: AuthService(context).onForgotPassword,
      logo: Image.asset('assets/kroniva.webp'),
      signUpMode: SignUpModes.both,
      socialLogins: _socialLogins(context),
      loginDesktopTheme: _desktopTheme,
      loginMobileTheme: _mobileTheme,
      loginTexts: _loginTexts,
      changeLanguageCallback: (LanguageOption? selectedlanguage) {
        if (selectedlanguage != null) {
          DialogBuilder(context).showResultDialog(
              'Successfully changed the language to: ${selectedlanguage.value}.');
          if (mounted) setState(() => language = selectedlanguage);
        }
      },
      languageOptions: _languageOptions,
      selectedLanguage: language,
      initialMode: AuthMode.login,
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