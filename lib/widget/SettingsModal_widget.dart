import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../provider/settings_provider.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({Key? key}) : super(key: key);

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  int _arabicFontSize = 22;
  int _latinFontSize = 16;
  int _translationFontSize = 16;
  String _arabicFontFamily = 'ScheherazadeNew';
  FontWeight _arabicFontWeight = FontWeight.bold;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _arabicFontSize = (prefs.getInt('arabicFontSize') ?? 22);
      _latinFontSize = (prefs.getInt('latinFontSize') ?? 22);
      _translationFontSize = (prefs.getInt('translationFontSize') ?? 16);
      _arabicFontFamily = (prefs.getString('arabicFontFamily') ?? 'ScheherazadeNew');
      String weightString = prefs.getString('arabicFontWeight') ?? 'normal';
      _arabicFontWeight = (weightString == 'bold') ? FontWeight.bold : FontWeight.normal;
    });
  }

  _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('arabicFontSize', _arabicFontSize);
    prefs.setInt('latinFontSize', _latinFontSize);
    prefs.setInt('translationFontSize', _translationFontSize);
    prefs.setString('arabicFontFamily', _arabicFontFamily);
    String weightString = (_arabicFontWeight == FontWeight.bold) ? 'bold' : 'normal';
    await prefs.setString('arabicFontWeight', weightString);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Text(
            'Font Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Arabic Font', style: TextStyle(fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: settings.arabicFontFamily,
                  items: [
                    DropdownMenuItem(value: 'Scheherazade New', child: Text('Scheherazade New')),
                    DropdownMenuItem(value: 'Amiri Quran', child: Text('Amiri Quran')),
                    DropdownMenuItem(value: 'Amiri', child: Text('Amiri')),
                    DropdownMenuItem(value: 'Lateef', child: Text('Lateef')),
                    DropdownMenuItem(value: 'Noto Naskh Arabic', child: Text('Noto Naskh Arabic')),
                    DropdownMenuItem(value: 'Noto Nastaliq Urdu', child: Text('Noto Nastaliq Urdu')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      settings.setArabicFontFamily(value);
                      setState(() {
                        _arabicFontFamily = value;
                      });
                      _saveSettings();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Arabic Font Weight', style: TextStyle(fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<FontWeight>(
                  value: settings.arabicFontWeight,
                  items: [
                    DropdownMenuItem(value: FontWeight.normal, child: Text('Regular')),
                    DropdownMenuItem(value: FontWeight.bold, child: Text('Bold')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      settings.setArabicFontWeight(value);
                      setState(() {
                        _arabicFontWeight = value;
                      });
                      _saveSettings();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Arabic', style: TextStyle(fontSize: 18)),
              Slider(
                value: _arabicFontSize.toDouble(),
                min: 20,
                max: 34,
                divisions: 22,
                label: _arabicFontSize.round().toString(),
                onChanged: (value) {
                  settings.setArabicFontSize(value);
                  setState(() {
                    _arabicFontSize = value.round();
                  });
                  _saveSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Terjemahan', style: TextStyle(fontSize: 18)),
              Slider(
                value: _translationFontSize.toDouble(),
                min: 14,
                max: 34,
                divisions: 16,
                label: _translationFontSize.round().toString(),
                onChanged: (value) {
                  settings.setTranslationFontSize(value);
                  setState(() {
                    _translationFontSize = value.round();
                  });
                  _saveSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Latin Teks', style: TextStyle(fontSize: 18)),
              Slider(
                value: _latinFontSize.toDouble(),
                min: 14,
                max: 34,
                divisions: 16,
                label: _latinFontSize.round().toString(),
                onChanged: (value) {
                  settings.setlatinFontSize(value);
                  setState(() {
                    _latinFontSize = value.round();
                  });
                  _saveSettings();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
