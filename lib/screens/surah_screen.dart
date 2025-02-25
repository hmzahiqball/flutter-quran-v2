import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_quran/widget/SurahCard_widget.dart';
import 'package:flutter_quran/widget/AyatItem_widget.dart';
import 'package:flutter_quran/widget/Settings_widget.dart';

class SurahPage extends StatefulWidget {
  const SurahPage({super.key});

  @override
  _SurahPageState createState() => _SurahPageState();
}

class _SurahPageState extends State<SurahPage> {
  Map<String, dynamic>? surahData;
  List<dynamic> ayatList = [];
  int? surahNumber;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    surahNumber = ModalRoute.of(context)?.settings.arguments as int?;
    if (surahNumber != null) {
      loadAyatData(surahNumber!);
    }
  }

  Future<void> loadAyatData(int nomor) async {
    String data = await rootBundle.loadString('assets/json/surah/$nomor.json');
    Map<String, dynamic> jsonResult = json.decode(data);

    setState(() {
      surahData = jsonResult['data'];
      ayatList = surahData?['ayat'] ?? [];
    });
  }

  void showSettingBottomSheet(BuildContext context) {
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
        return SettingsWidget();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => showSettingBottomSheet(context),
          ),
        ],
        title: Text(
          surahData?['namaLatin'] ?? 'Loading...',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: surahData?['nomor'].toString() != '1'
                    ? ayatList.length + 1
                    : ayatList.length,
                itemBuilder: (context, index) {
                  if (surahData?['nomor'].toString() != '1' && index == 0) {
                    return Center(
                      child: Image.asset(
                        'assets/images/bismillah.png',
                        width: 200,
                      ),
                    );
                  } else if (index == 0) {
                    return SurahCard(
                      title: surahData?['namaLatin'] ?? 'Loading...',
                      verse: surahData?['jumlahAyat'].toString() ?? '0',
                      type: surahData?['tempatTurun'] ?? '',
                      arabicTitle: surahData?['nama'] ?? '',
                      arti: surahData?['arti'] ?? '',
                      urutan: surahData?['urut'].toString() ?? 'Tidak diketahui',
                    );
                  } else {
                    var ayat =
                        // surahData?['nomor'].toString() == '1' ? ayatList[index - 1] : ayatList[index - 2];
                        surahData?['nomor'].toString() == '1' ? ayatList[index - 1] : ayatList[index - 1];
                    return AyatItem(
                      title: surahData?['namaLatin'],
                      arabicTitle: surahData?['nama'],
                      type: surahData?['tempatTurun'],
                      number: ayat['nomorAyat'],
                      arabicText: ayat['teksArab'],
                      translation: ayat['teksIndonesia'],
                      latin: ayat['teksLatin'],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
