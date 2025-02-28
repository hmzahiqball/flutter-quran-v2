import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as root_bundle;

class ModalTafsir extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final String title;

  const ModalTafsir({Key? key, required this.surahNumber, required this.ayahNumber, required this.title}) : super(key: key);

  @override
  _ModalTafsirState createState() => _ModalTafsirState();
}

class _ModalTafsirState extends State<ModalTafsir> {
  String tafsirText = "Loading...";

  @override
  void initState() {
    super.initState();
    loadTafsir();
  }

  Future<void> loadTafsir() async {
    try {
      String jsonString = await root_bundle.rootBundle.loadString('assets/json/tafsir/${widget.surahNumber}.json');
      Map<String, dynamic> jsonData = json.decode(jsonString);
      List<dynamic> tafsirList = jsonData['data']['tafsir'];
      
      // Cari tafsir berdasarkan ayat
      var tafsirAyat = tafsirList.firstWhere(
        (tafsir) => tafsir['ayat'] == widget.ayahNumber,
        orElse: () => null,
      );
      
      setState(() {
        tafsirText = tafsirAyat != null ? tafsirAyat['teks'] : "Tafsir tidak tersedia untuk ayat ini";
      });
    } catch (e) {
      setState(() {
        tafsirText = "Gagal memuat tafsir";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                "Tafsir Surah ${widget.title} - Ayat ${widget.ayahNumber}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.45, // Menentukan tinggi agar tidak error
                child: SingleChildScrollView(
                  child: Text(
                    tafsirText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}