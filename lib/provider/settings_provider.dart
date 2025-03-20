import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  double _arabicFontSize = 22.0;
  double _latinFontSize = 16.0;
  double _translationFontSize = 16.0;
  String _arabicFontFamily = 'Scheherazade New';
  FontWeight _arabicFontWeight = FontWeight.bold;
  String _latinFontFamily = 'Baloo 2';
  FontWeight _latinFontWeight = FontWeight.bold;
  String _translateFontFamily = 'Outfit';
  FontWeight _translateFontWeight = FontWeight.bold;

  double get arabicFontSize => _arabicFontSize;
  double get latinFontSize => _latinFontSize;
  double get translationFontSize => _translationFontSize;
  String get arabicFontFamily => _arabicFontFamily;
  FontWeight get arabicFontWeight => _arabicFontWeight;
  String get latinFontFamily => _latinFontFamily;
  FontWeight get latinFontWeight => _latinFontWeight;
  String get translateFontFamily => _translateFontFamily;
  FontWeight get translateFontWeight => _translateFontWeight;

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

    _latinFontFamily = prefs.getString('latinFontFamily') ?? 'Scheherazade New';
    String latinWeightString = prefs.getString('latinFontWeight') ?? 'normal';
    _latinFontWeight = (latinWeightString == 'bold') ? FontWeight.bold : FontWeight.normal;

    _translateFontFamily = prefs.getString('translateFontFamily') ?? 'Scheherazade New';
    String translateFontWeight = prefs.getString('translateFontWeight') ?? 'normal';
    _translateFontWeight = (translateFontWeight == 'bold') ? FontWeight.bold : FontWeight.normal;
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

  void setLatinFontFamily(String font) async {
    _latinFontFamily = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('latinFontFamily', font);
    notifyListeners();
  }

  void setLatinFontWeight(FontWeight weight) async {
    _latinFontWeight = weight;
    notifyListeners();
  }

  void setTranslationFontSize(double value) async {
    _translationFontSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('translationFontSize', value);
    notifyListeners();
  }

  void setTranslateFontFamily(String font) async {
    _translateFontFamily = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('translateFontFamily', font);
    notifyListeners();
  }

  void setTranslateFontWeight(FontWeight weight) async {
    _translateFontWeight = weight;
    notifyListeners();
  }
}
