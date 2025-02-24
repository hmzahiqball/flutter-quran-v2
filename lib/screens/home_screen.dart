import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_quran/widget/LastReadCard_widget.dart';
import 'package:flutter_quran/widget/FilterBar_widget.dart';
import 'package:flutter_quran/widget/SuraItem_widget.dart';
import 'package:flutter_quran/widget/DoaItem_widget.dart';
import 'package:flutter_quran/widget/DoaModal_widget.dart';
import 'package:flutter_quran/widget/Settings_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List surahList = [];
  List doaList = [];
  List searchResults = [];
  String selectedFilter = "Surah";
  int selectedIndex = 0;
  final List<String> filters = ["Surah", "Mekah", "Madinah", "Doa"];

  @override
  void initState() {
    super.initState();
    loadSurahData();
    loadDoaData();
  }

  Future<void> loadSurahData() async {
    String data = await rootBundle.loadString('assets/json/surah.json');
    Map<String, dynamic> jsonResult = json.decode(data);
    setState(() {
      surahList = jsonResult['data'];
    });
  }

  Future<void> loadDoaData() async {
    String data = await rootBundle.loadString('assets/json/doa.json');
    List<dynamic> jsonResult = json.decode(data);
    setState(() {
      doaList = jsonResult;
    });
  }

  Future<List<String?>> getLastRead() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return [
      prefs.getString('lastReadSurah'),
      prefs.getString('lastReadSurahArabic'),
      prefs.getString('lastReadSurahType'),
      prefs.getInt('lastReadAyat')?.toString(),
    ];
  }

  void searchData(String query) {
    setState(() {
      searchResults = query.isEmpty
          ? []
          : surahList
              .where((surah) => surah['namaLatin'].toLowerCase().contains(query.toLowerCase()))
              .toList()
              ..addAll(
                doaList.where((doa) => doa['doa'].toLowerCase().contains(query.toLowerCase())),
              );
    });
  }

  void applyFilter() {
    setState(() {
      switch (selectedIndex) {
        case 1:
          surahList = surahList.where((surah) => surah['tempatTurun'] == 'Mekah').toList();
          break;
        case 2:
          surahList = surahList.where((surah) => surah['tempatTurun'] == 'Madinah').toList();
          break;
        case 3:
          surahList = doaList;
          break;
        default:
          loadSurahData();
      }
    });
  }

  void showDoaBottomSheet(BuildContext context, Map<String, dynamic> doa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DoaBottomSheet(
        title: doa['doa'],
        arabicText: doa['ayat'],
        latinText: doa['latin'],
        translation: doa['artinya'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(hintText: "Cari Surah atau Doa..."),
                onChanged: searchData,
              )
            : Text(
                "Al-Qur'an & Doa",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                searchController.clear();
                searchResults.clear();
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            FutureBuilder<List<String?>> (
              future: getLastRead(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data![0] == null) {
                  return Text("Belum ada bacaan terakhir");
                }
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/surah', arguments: int.parse(snapshot.data![0]!)),
                  child: LastReadCard(
                    title: snapshot.data![0]!,
                    arabicTitle: snapshot.data![1]!,
                    type: snapshot.data![2]!,
                    verse: snapshot.data![3] != null ? "Ayat ${snapshot.data![3]}" : "",
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            FilterBar(
              filters: filters,
              selectedIndex: selectedIndex,
              onSelected: (index) {
                setState(() {
                  selectedIndex = index;
                  applyFilter();
                });
              },
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.isNotEmpty ? searchResults.length : surahList.length,
                itemBuilder: (context, index) {
                  var item = searchResults.isNotEmpty ? searchResults[index] : surahList[index];
                  return GestureDetector(
                    onTap: () => item.containsKey('doa')
                        ? showDoaBottomSheet(context, item)
                        : Navigator.pushNamed(context, '/surah', arguments: item['nomor']),
                    child: item.containsKey('doa')
                        ? DoaItem(number: index + 1, title: item['doa'])
                        : SuraItem(
                            number: index + 1,
                            title: item['namaLatin'],
                            details: '${item['jumlahAyat']} Ayat | ${item['tempatTurun']} | Surah ke-${item['nomor']}',
                            arabicTitle: item['nama'],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
