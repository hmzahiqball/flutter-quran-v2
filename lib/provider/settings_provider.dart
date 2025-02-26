import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  double _arabicFontSize = 22.0;
  double _latinFontSize = 16.0;
  double _translationFontSize = 16.0;
  String _arabicFontFamily = 'Scheherazade New';
  FontWeight _arabicFontWeight = FontWeight.bold;

  double get arabicFontSize => _arabicFontSize;
  double get latinFontSize => _latinFontSize;
  double get translationFontSize => _translationFontSize;
  String get arabicFontFamily => _arabicFontFamily;
  FontWeight get arabicFontWeight => _arabicFontWeight;

  SettingsProvider() {
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _arabicFontSize = prefs.getDouble('arabicFontSize') ?? 22.0;
    _latinFontSize = prefs.getDouble('latinFontSize') ?? 16.0;
    _translationFontSize = prefs.getDouble('translationFontSize') ?? 16.0;
    _arabicFontFamily = prefs.getString('arabicFontFamily') ?? 'Scheherazade New';
    String weightString = prefs.getString('arabicFontWeight') ?? 'normal';
    _arabicFontWeight = (weightString == 'bold') ? FontWeight.bold : FontWeight.normal;
    notifyListeners();
  }

  void setArabicFontSize(double value) async {
    _arabicFontSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('arabicFontSize', value);
    notifyListeners();
  }

  void setArabicFontFamily(String font) async {
    _arabicFontFamily = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('arabicFontFamily', font);
    notifyListeners();
  }

  void setArabicFontWeight(FontWeight weight) async {
    _arabicFontWeight = weight;
    notifyListeners();
  }

  void setlatinFontSize(double value) async {
    _latinFontSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('latinFontSize', value);
    notifyListeners();
  }

  void setTranslationFontSize(double value) async {
    _translationFontSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('translationFontSize', value);
    notifyListeners();
  }
}
