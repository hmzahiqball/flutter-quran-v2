import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'SurahNumber.dart';
import 'SurahDetail_widget.dart';

class SuraItem extends StatelessWidget {
  final int number;
  final String title;
  final String details;
  final String arabicTitle;
  final Map<String, dynamic> surahData;

  const SuraItem({
    required this.number,
    required this.title,
    required this.details,
    required this.arabicTitle,
    required this.surahData,
  });

  void showSurahDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SurahDetailModal(
          title: surahData['namaLatin'],
          arabicTitle: surahData['nama'],
          arti: surahData['arti'],
          ayat: surahData['jumlahAyat'].toString(),
          type: surahData['tempatTurun'],
          urutan: surahData['urut'].toString(),
          deskripsi: surahData['deskripsi'],
          audio: surahData['audioFull']['01'], // Ambil salah satu audio
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SurahNumberIcon(number: number),
              SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: width * 0.042, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  SizedBox(height: 7),
                  Text(details, style: TextStyle(fontSize: width * 0.038, color: Theme.of(context).colorScheme.secondary)),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                arabicTitle,
                style: GoogleFonts.scheherazadeNew(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: width * 0.055,
                  // fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () => showSurahDetail(context)
              ),
            ],
          ),
        ],
      ),
    );
  }
}