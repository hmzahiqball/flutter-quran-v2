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
    });
  }

  _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('arabicFontSize', _arabicFontSize);
    prefs.setInt('latinFontSize', _latinFontSize);
    prefs.setInt('translationFontSize', _translationFontSize);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
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
            'Ukuran Font',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Arabic', style: TextStyle(fontSize: 22)),
              Slider(
                value: _arabicFontSize.toDouble(),
                min: 18,
                max: 30,
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
              Text('Terjemahan', style: TextStyle(fontSize: 22)),
              Slider(
                value: _translationFontSize.toDouble(),
                min: 12,
                max: 24,
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
              Text('Latin Teks', style: TextStyle(fontSize: 22)),
              Slider(
                value: _latinFontSize.toDouble(),
                min: 12,
                max: 24,
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
