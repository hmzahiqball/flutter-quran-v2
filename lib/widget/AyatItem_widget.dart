import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_quran/widget/BookmarkModal_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../provider/settings_provider.dart';

class AyatItem extends StatelessWidget {
  final String title;
  final String arabicTitle;
  final String type;
  final int number;
  final String arabicText;
  final String translation;
  final String latin;

  String decodeHtml(String text) {
    final unescape = HtmlUnescape();
    return unescape.convert(text);
  }

  String convertToArabicNumeral(int number) {
    // Peta angka Latin (0-9) ke angka Arabic-Indic
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    // Ubah setiap digit angka menjadi angka Arab
    return number.toString().split('').map((digit) => arabicNumerals[int.parse(digit)]).join('');
  }

  Future<void> saveLastRead(String surah, String arabicSurah, String type, int ayat) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastReadSurah', surah);
    await prefs.setString('lastReadSurahArabic', arabicSurah);
    await prefs.setString('lastReadSurahType', type);
    await prefs.setInt('lastReadAyat', ayat);
  }

  void showDoaBottomSheet(BuildContext context, int number) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 500), // Durasi transisi
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return BookmarkModalWidget(
          title: title,
          ayat: number.toString(),
            onSave: () async {
            await saveLastRead(title, arabicTitle, type, number);
            Navigator.pop(context); // Tutup modal setelah menyimpan
          },
        );
      },
    );
  }

  const AyatItem({
    required this.title,
    required this.arabicTitle,
    required this.type,
    required this.number,
    required this.arabicText,
    required this.translation,
    required this.latin,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    
    return GestureDetector(
      onTap: () => showDoaBottomSheet(context, number), // Tampilkan modal saat diklik
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/ayatNumber.png',
                      width: 40,
                      height: 40,
                    ),
                    Text(
                      convertToArabicNumeral(number),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    arabicText,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.scheherazadeNew(
                      fontSize: settings.arabicFontSize,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
          // Html(
          //   data: latin,
          //   style: {
          //     "strong": Style(
          //       fontSize: FontSize(15),
          //       fontWeight: FontWeight.bold,
          //       color: Theme.of(context).colorScheme.secondary,
          //     ),
          //     "u": Style(
          //       fontSize: FontSize(15),
          //       fontWeight: FontWeight.bold,
          //       textDecoration: TextDecoration.underline,
          //       color: Theme.of(context).colorScheme.secondary,
          //     ),
          //     "body": Style(
          //       fontSize: FontSize(15),
          //       fontWeight: FontWeight.bold,
          //       padding: HtmlPaddings.zero,
          //     ),
          //   },
          // ),
            Text(
              translation,
              style: TextStyle(fontSize: settings.translationFontSize, color: Theme.of(context).colorScheme.secondary),
            ),
            Divider(color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

