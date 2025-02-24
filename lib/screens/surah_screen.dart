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
  ScrollController _scrollController = ScrollController();
  int? nomorAyat; // Menyimpan nomor ayat yang akan di-scroll
  Map<String, dynamic>? surahData;
  List<dynamic> ayatList = [];
  int? surahNumber;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ambil nomor surah dari arguments
    surahNumber = ModalRoute.of(context)?.settings.arguments as int?;
    if (surahNumber != null) {
      loadAyatData(surahNumber!);
    }
  }

  Future<void> loadAyatData(int nomor) async {
    String data = await rootBundle.loadString(
      'assets/json/surah.json',
    ); 
    List<dynamic> jsonResult = json.decode(data);

    // Cari surah dengan nomor yang sesuai
    var selectedSurah = jsonResult.firstWhere(
      (surah) => surah['nomor'] == nomor.toString(),
      orElse: () => null,
    );

    if (selectedSurah != null) {
      setState(() {
        surahData = selectedSurah;
        ayatList = surahData?['isi'] ?? [];
      });
    }
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
        leading: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              Navigator.pop(context, true); // Kirim nilai `true` saat kembali
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              showSettingBottomSheet(context);
            },
          ),
        ],
        title: Text(
          surahData?['nama'] ?? 'Loading...',
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
            SurahCard(
              title: surahData?['nama'] ?? 'Loading...',
              verse: surahData?['ayat'].toString() ?? '0',
              type: surahData?['type'] ?? '',
              arabicTitle: surahData?['asma'] ?? '',
              arti: surahData?['arti'] ?? '',
              nomor: surahData?['nomor'] ?? '',
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: ayatList.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Center(
                      child: Image.asset('assets/images/bismillah.png', width: 250),
                    );
                  } else {
                    var ayat = ayatList[index - 1];
                    return AyatItem(
                      title: surahData?['nama'],
                      arabicTitle: surahData?['asma'],
                      type: surahData?['type'],
                      number: int.tryParse(ayat['nomor']) ?? 0,
                      arabicText: ayat['ar'],
                      translation: ayat['id'],
                      latin: ayat['tr'],
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

