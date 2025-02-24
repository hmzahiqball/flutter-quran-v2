import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SurahDetailModal extends StatelessWidget {
  final String title;
  final String arabicTitle;
  final String arti;
  final String ayat;
  final String type;
  final String urutan;
  final String deskripsi;
  final String audio;

  const SurahDetailModal({
    Key? key,
    required this.title,
    required this.arabicTitle,
    required this.arti,
    required this.ayat,
    required this.type,
    required this.urutan,
    required this.deskripsi,
    required this.audio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5, // Setengah layar
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                arabicTitle,
                textAlign: TextAlign.right,
                style: GoogleFonts.scheherazadeNew(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
  child: SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arti
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Arti: ", style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            Expanded(
              child: Text(arti, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Jumlah Ayat
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Jumlah Ayat: ", style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            Expanded(
              child: Text(ayat, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Tempat Diturunkan
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tempat Diturunkan: ", style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            Expanded(
              child: Text(type, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Urutan Diturunkan
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Urutan Diturunkan: ", style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            Expanded(
              child: Text(type, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Deskripsi
        Text("Deskripsi:", style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        Text(
          deskripsi,
          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
        ),
      ],
    ),
  ),
),

        ],
      ),
    );
  }
}
