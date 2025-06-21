import 'package:flutter/services.dart';

class Localization {
  static Map<String, String> _localizedStrings = {};
  static late String currentLocale;
  static bool _enableRtl = false;

  static Future<void> settingsTranslation(Map<String, dynamic> apiResponse, String locale) async {
    currentLocale = locale;

    if (apiResponse['translations'] != null) {
      _localizedStrings = Map<String, String>.from(apiResponse['translations']);
    } else {
      _localizedStrings = {};
    }
    _enableRtl = apiResponse['_general']?['enable_rtl'] == '1';
  }


  static String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  static TextDirection get textDirection {
    return _enableRtl ? TextDirection.rtl : TextDirection.ltr;
  }
}
