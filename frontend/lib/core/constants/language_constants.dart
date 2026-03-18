class LanguageConstants {
  static const String defaultLanguageCode = 'EN';
  
  static const Map<String, Map<String, String>> translations = {
    'EN': {
      'username': 'Username',
      'login': 'Login',
      'signup': 'Sign Up',
      'languageChanged': 'Successfully changed the language to:',
    },
    'TR': {
      'username': 'Kullanıcı Adı',
      'login': 'Giriş Yap',
      'signup': 'Kayıt Ol',
      'languageChanged': 'Dil başarıyla değiştirildi:',
    },
  };

  static String translate(String key, String languageCode) {
    return translations[languageCode]?[key] ?? translations[defaultLanguageCode]![key]!;
  }
}
