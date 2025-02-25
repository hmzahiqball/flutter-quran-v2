import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LastReadCard extends StatelessWidget {
  final String title;
  final String verse;
  final String type;
  final String arabicTitle;

  const LastReadCard({
    required this.title,
    required this.verse,
    required this.type,
    required this.arabicTitle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: width * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                verse != null ? verse + ' | ' + type : "",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: width * 0.038,
                ),
              ),
            ],
          ),
          Text(
            arabicTitle != null ? arabicTitle : "",
            style: GoogleFonts.scheherazadeNew(
              color: Theme.of(context).colorScheme.primary,
              fontSize: width * 0.055,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}