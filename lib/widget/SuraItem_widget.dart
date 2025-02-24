import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widget/SurahNumber.dart';

class SuraItem extends StatelessWidget {
  final int number;
  final String title;
  final String details;
  final String arabicTitle;

  const SuraItem({
    required this.number,
    required this.title,
    required this.details,
    required this.arabicTitle,
  });

  @override
  Widget build(BuildContext context) {
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
                  Text(title, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  SizedBox(height: 7),
                  Text(details, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.secondary)),
                ],
              ),
            ],
          ),
          Text(arabicTitle, style: GoogleFonts.scheherazadeNew(color: Theme.of(context).colorScheme.primary, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}