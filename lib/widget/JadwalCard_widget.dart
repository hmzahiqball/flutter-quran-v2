import 'package:flutter/material.dart';

class JadwalCard extends StatelessWidget {
  final String keterangan;
  final String estimasi;
  final String lokasi;
  final VoidCallback onTapLocation;

  JadwalCard({
    required this.keterangan,
    required this.estimasi,
    required this.lokasi,
    required this.onTapLocation,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Keterangan
          Text(
            keterangan,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
                    fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2, // Bisa diubah sesuai kebutuhan
            overflow: TextOverflow.ellipsis, // Tambahkan "..." jika teks terlalu panjang
          ),
          SizedBox(height: 4),

          // Estimasi & Lokasi dalam satu baris
          Wrap(
            spacing: 4, // Jarak antar elemen dalam Wrap
            children: [
              Text(
                estimasi,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                    fontSize: width * 0.04,
                ),
              ),
              Text('|'),
              GestureDetector(
                onTap: onTapLocation,
                child: Text(
                  lokasi,
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: width * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
