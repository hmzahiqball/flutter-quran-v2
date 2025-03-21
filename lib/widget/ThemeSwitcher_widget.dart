import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/settings_provider.dart';

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    bool isDarkMode = settings.themeMode == ThemeMode.dark;

    return GestureDetector(
      onTap: () {
        Provider.of<SettingsProvider>(context, listen: false).toggleTheme(!isDarkMode);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: Icon(
          isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
          key: ValueKey<bool>(isDarkMode),
          size: 28,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
