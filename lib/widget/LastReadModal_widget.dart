import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookmarkModalWidget extends StatelessWidget {
  final String title;
  final String ayat;
  final VoidCallback onSave;
  final VoidCallback onPlayAudio;
  final VoidCallback onShowTafsir;
  
  const BookmarkModalWidget({
    Key? key,
    required this.title,
    required this.ayat,
    required this.onSave,
    required this.onPlayAudio,
    required this.onShowTafsir,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Surah: $title',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Ayat ke- $ayat',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.primary),
            title: Text("Play Audio", style: TextStyle(fontSize: 16)),
            onTap: onPlayAudio,
          ),
          ListTile(
            leading: Icon(Icons.menu_book, color: Theme.of(context).colorScheme.primary),
            title: Text("Tafsir Ayat", style: TextStyle(fontSize: 16)),
            onTap: onShowTafsir,
          ),
          ListTile(
            leading: Icon(Icons.bookmark, color: Theme.of(context).colorScheme.primary),
            title: Text("Tandai Terakhir Baca", style: TextStyle(fontSize: 16)),
            onTap: onSave,
          ),
        ],
      ),
    );
  }
}