import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_quran/widget/SurahCard_widget.dart';
import 'package:flutter_quran/widget/AyatList_widget.dart';
import 'package:flutter_quran/widget/SettingsModal_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class SurahPage extends StatefulWidget {
  const SurahPage({super.key});

  @override
  _SurahPageState createState() => _SurahPageState();
}

class _SurahPageState extends State<SurahPage> {
  Map<String, dynamic>? surahData;
  List<dynamic> ayatList = [];
  int? surahNumber;
  int? ayatNumber;
  final Map<int, GlobalKey> _ayatKeys = {};
  final ItemScrollController _itemScrollController = ItemScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      surahNumber = args;
    } else if (args is Map<String, dynamic>) {
      surahNumber = args['nomor'] as int?;
      ayatNumber = args['ayat'] as int?;
    }

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

    // Tunggu sampai UI siap sebelum menggulir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ayatNumber != null) {
        Future.delayed(Duration(milliseconds: 10), () {
          if (mounted) {
            scrollToAyat(ayatNumber! + 1);
          }
        });
      }
    });
  }

  void scrollToAyat(int ayatIndex) {
    _itemScrollController.scrollTo(
      index: ayatIndex,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOutCubic,
    );
  }

  void showSettingBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
        backgroundColor: Color(0xFFF9F9F9),
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
        child: ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          itemCount:
              ayatList.length + (surahData?['nomor'].toString() != '1' ? 2 : 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return SurahCard(
                title: surahData?['namaLatin'] ?? 'Loading...',
                verse: surahData?['jumlahAyat'].toString() ?? '0',
                type: surahData?['tempatTurun'] ?? '',
                arabicTitle: surahData?['nama'] ?? '',
                arti: surahData?['arti'] ?? '',
                urutan: surahData?['urut'].toString() ?? 'Tidak diketahui',
              );
            } else if (surahData?['nomor'].toString() != '1' && index == 1) {
              return Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Image.asset(
                        'assets/images/bismillah.png',
                        width: 200,
                      ),
                    ),
                  ),
                  Divider(color: Colors.grey.shade300),
                ],
              );
            }

            int ayatIndex =
                (surahData?['nomor'].toString() != '1') ? index - 2 : index - 1;

            if (ayatIndex < ayatList.length) {
              var ayat = ayatList[ayatIndex];
              return Container(
                key: _ayatKeys[ayat['nomorAyat']],
                child: AyatItem(
                  surahNumber: surahData?['nomor'],
                  title: surahData?['namaLatin'],
                  arabicTitle: surahData?['nama'],
                  type: surahData?['tempatTurun'],
                  number: ayat['nomorAyat'],
                  arabicText: ayat['teksArab'],
                  translation: ayat['teksIndonesia'],
                  latin: ayat['teksLatin'],
                ),
              );
            }
            return SizedBox();
          },
        ),
      ),
    );
  }
}
