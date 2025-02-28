import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:flutter_quran/widget/LastReadModal_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../provider/settings_provider.dart';
import 'TafsirModal_widget.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart';

class AyatItem extends StatelessWidget {
  final int surahNumber;
  final String title;
  final String arabicTitle;
  final String type;
  final int number;
  final String arabicText;
  final String translation;
  final String latin;
  final AudioPlayer _audioPlayer = AudioPlayer();

  String convertToArabicNumeral(int number) {
    // Peta angka Latin (0-9) ke angka Arabic-Indic
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    // Ubah setiap digit angka menjadi angka Arab
    return number
        .toString()
        .split('')
        .map((digit) => arabicNumerals[int.parse(digit)])
        .join('');
  }

  Future<void> saveLastRead(
    String surah,
    String arabicSurah,
    String type,
    int ayat,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastReadSurah', surah);
    await prefs.setString('lastReadSurahArabic', arabicSurah);
    await prefs.setString('lastReadSurahType', type);
    await prefs.setInt('lastReadAyat', ayat);
  }

  Future<bool> checkAudioExists(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio');
    if (!await audioDir.exists()) {
      await audioDir.create();
    }
    final filePath = '${audioDir.path}/$fileName';
    return File(filePath).exists();
  }

  Future<void> downloadAudio(
    BuildContext context,
    String audioUrl,
    String fileName,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio');
    if (!await audioDir.exists()) {
      await audioDir.create();
    }
    final filePath = '${audioDir.path}/$fileName';

    double progress = 0.0;
    bool isDownloading = true;

    // Tampilkan dialog progres
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Mengunduh Audio"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Sedang mengunduh..."),
                  SizedBox(height: 10),
                  LinearProgressIndicator(value: progress),
                  SizedBox(height: 10),
                  Text("${(progress * 100).toStringAsFixed(1)}%"),
                ],
              ),
              actions: [
                if (isDownloading)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      isDownloading = false;
                    },
                    child: Text("Batal"),
                  ),
              ],
            );
          },
        );
      },
    );

    try {
      var request = http.Request('GET', Uri.parse(audioUrl));
      var response = await http.Client().send(request);

      if (response.statusCode == 200) {
        File file = File(filePath);
        var sink = file.openWrite();
        int downloaded = 0;
        int total = response.contentLength ?? 0;

        await for (var chunk in response.stream) {
          if (!isDownloading) {
            sink.close();
            file.delete();
            return;
          }

          downloaded += chunk.length;
          sink.add(chunk);

          // Update progress bar
          progress = total > 0 ? downloaded / total : 0;
          (context as Element).markNeedsBuild(); // Pastikan UI terupdate
        }

        await sink.close();

        if (isDownloading) {
          Navigator.pop(context); // Tutup dialog progres

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Unduhan selesai")));

          _audioPlayer.play(DeviceFileSource(filePath));
        }
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal mengunduh audio")));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void showDownloadDialog(
    BuildContext context,
    String audioUrl,
    String fileName,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Unduh Audio"),
            content: Text("Anda belum mengunduh audio ini. Unduh sekarang?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Tidak"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  downloadAudio(context, audioUrl, fileName);
                },
                child: Text("Ya"),
              ),
            ],
          ),
    );
  }

  void onQariSelected(
    BuildContext context,
    String qariId,
    int surahNumber,
    int ayatNumber,
  ) async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/json/surah/$surahNumber.json',
      );
      Map<String, dynamic> surahData = json.decode(jsonString);
      List<dynamic> ayatList = surahData['data']['ayat'];
      var ayatData = ayatList.firstWhereOrNull(
        (ayat) => ayat['nomorAyat'] == ayatNumber,
      );
      if (ayatData == null) {
        print("Ayat tidak ditemukan dalam JSON.");
        return;
      }

      if (ayatData != null) {
        String? audioUrl = ayatData['audio'][qariId];
        if (audioUrl != null) {
          String fileName = "${surahNumber}_${ayatNumber}_$qariId.mp3";
          bool exists = await checkAudioExists(fileName);
          if (!exists) {
            showDownloadDialog(context, audioUrl, fileName);
          } else {
            final dir = await getApplicationDocumentsDirectory();
            _audioPlayer.play(DeviceFileSource('${dir.path}/$fileName'));
          }
        } else {
          print("Qari ID tidak ditemukan untuk ayat ini.");
        }
      } else {
        print("Ayat tidak ditemukan dalam JSON.");
      }
    } catch (e) {
      print("Error saat membaca JSON: $e");
    }
  }

  void showAyatBottomSheet(BuildContext context, int number) {
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
            try {
              await saveLastRead(title, arabicTitle, type, number);
              Navigator.pop(context); // Tutup modal setelah berhasil menyimpan
            } catch (e) {
              print("Error menyimpan terakhir baca: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Gagal menyimpan terakhir baca")),
              );
            }
          },
          onPlayAudio: () {
            // Tambahkan logika untuk memutar audio di sini
            showQariSelectionModal(context, (selectedQariId) {
              onQariSelected(context, selectedQariId, surahNumber, number);
            });
          },
          onShowTafsir: () {
            // Tambahkan logika untuk menampilkan tafsir di sini
            showTafsirModal(context, surahNumber, number, title);
          },
        );
      },
    );
  }

  void showTafsirModal(
    BuildContext context,
    int surahNumber,
    int ayahNumber,
    String title,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => ModalTafsir(
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            title: title,
          ),
    );
  }

  void showQariSelectionModal(
    BuildContext context,
    Function(String) onQariSelected,
  ) {
    final List<Map<String, String>> qariList = [
      {"name": "Abdullah Al Juhany", "id": "01"},
      {"name": "Abdul Muhsin Al Qasim", "id": "02"},
      {"name": "Abdurrahman as Sudais", "id": "03"},
      {"name": "Ibrahim Al Dossari", "id": "04"},
      {"name": "Misyari Rasyid Al Afasi", "id": "05"},
    ];

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 10),
              Text(
                "Pilih Qari",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ...qariList.map(
                (qari) => ListTile(
                  title: Text(qari["name"]!),
                  onTap: () {
                    Navigator.pop(context);
                    onQariSelected(qari["id"]!);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  AyatItem({
    required this.surahNumber,
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
      onTap:
          () => showAyatBottomSheet(
            context,
            number,
          ), // Tampilkan modal saat dihold
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
                Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    return Expanded(
                      child: Text(
                        arabicText,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.getFont(
                          settings.arabicFontFamily,
                          fontSize: settings.arabicFontSize,
                          fontWeight: settings.arabicFontWeight,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              latin,
              style: GoogleFonts.baloo2(
                fontSize: settings.latinFontSize,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              translation,
              style: TextStyle(
                fontSize: settings.translationFontSize,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            Divider(color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}
