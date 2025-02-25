import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_quran/widget/LastReadCard_widget.dart';
import 'package:flutter_quran/widget/FilterBar_widget.dart';
import 'package:flutter_quran/widget/SuraItem_widget.dart';
import 'package:flutter_quran/widget/DoaItem_widget.dart';
import 'package:flutter_quran/widget/DoaModal_widget.dart';
import 'package:flutter_quran/widget/Settings_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List searchResults = [];
  String selectedFilter = "Surah";
  int selectedIndex = 0;
  final List<String> filters = ["Surah", "Doa"];
  List surahList = [];
  List doaList = [];
  List filteredSurahList = [];

  @override
  void initState() {
    super.initState();
    loadSurahData();
    loadDoaData();
  }

  Future<List<String?>> getLastRead() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    String? surah = prefs.getString('lastReadSurah');
    String? surahArabic = prefs.getString('lastReadSurahArabic');
    String? surahType = prefs.getString('lastReadSurahType');
    int? ayat = prefs.getInt('lastReadAyat');
    return [
      surah,
      surahArabic,
      surahType,
      ayat != null ? ayat.toString() : null,
    ];
  }

  void searchData(String query) {
    setState(() {
      if (query.isEmpty) {
        searchResults.clear();
      } else {
        searchResults =
            surahList
                .where(
                  (surah) =>
                      surah['namaLatin'].toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      surah['arti'].toLowerCase().contains(query.toLowerCase()),
                )
                .toList();

        searchResults.addAll(
          doaList
              .where(
                (doa) => doa['doa'].toLowerCase().contains(query.toLowerCase()),
              )
              .toList(),
        );
      }
    });
  }

  Future<void> loadSurahData() async {
    String data = await rootBundle.loadString('assets/json/surah.json');
    // List<dynamic> jsonResult = json.decode(data);
    Map<String, dynamic> jsonResult = json.decode(data);

    setState(() {
      surahList = jsonResult['data'];
      filteredSurahList = List.from(surahList); // Default tanpa filter
    });
  }

  Future<void> loadDoaData() async {
    String data = await rootBundle.loadString('assets/json/doa.json');
    List<dynamic> doajsonResult = json.decode(data);

    setState(() {
      doaList = doajsonResult;
    });
  }

  void applyFilter() {
    setState(() {
      // Default tanpa filter (Surah)
      filteredSurahList = List.from(surahList);
      if (selectedIndex == 1) {
        // Default tanpa filter (doa)
        filteredSurahList = List.from(doaList);
      }
    });
  }

  void showDoaBottomSheet(BuildContext context, Map<String, dynamic> doa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DoaBottomSheet(
          title: doa['doa'],
          arabicText: doa['ayat'],
          latinText: doa['latin'],
          translation: doa['artinya'],
        );
      },
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
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        title:
            isSearching
                ? Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Cari Surah atau Doa...",
                      border: InputBorder.none,
                    ),
                    onChanged: searchData,
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    "Al-Qur'an & Doa",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        actions: [
          isSearching
              ? IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    isSearching = false;
                    searchController.clear();
                    searchResults.clear();
                  });
                },
              )
              : IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    isSearching = true;
                  });
                },
              ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Read',
              style: TextStyle(
                fontSize: width * 0.05,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 15),

            FutureBuilder<List<String?>>(
              future:
                  getLastRead(), // Ambil data terbaru dari SharedPreferences
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return LastReadCard(
                    title: "Loading...",
                    arabicTitle: "-",
                    type: "-",
                    verse: "-",
                  );
                }
                if (!snapshot.hasData || snapshot.data![0] == null) {
                  return LastReadCard(
                    title: "Belum ada bacaan terakhir",
                    arabicTitle: "-",
                    type: "-",
                    verse: "-",
                  );
                }

                List<String?> lastRead = snapshot.data!;
                return GestureDetector(
                  onTap: () {
                    if (lastRead[0] != null) {
                      // Cari Surah berdasarkan nama
                      var surahData = surahList.firstWhere(
                        (surah) =>
                            surah['namaLatin'].toLowerCase() ==
                            lastRead[0]!.toLowerCase(),
                        orElse: () => null, // Jika tidak ditemukan, return null
                      );

                      if (surahData != null) {
                        Navigator.pushNamed(
                          context,
                          '/surah',
                          arguments: surahData['nomor'],
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Surah tidak ditemukan")),
                        );
                        print("masuk");
                      }
                    }
                  },
                  child: LastReadCard(
                    title: lastRead[0] ?? "",
                    arabicTitle: lastRead[1] ?? "",
                    type: lastRead[2] ?? "",
                    verse: lastRead[3] != null ? "Ayat ${lastRead[3]}" : "",
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
                itemCount:
                    searchResults.isNotEmpty
                        ? searchResults.length
                        : filteredSurahList.length,
                itemBuilder: (context, index) {
                  var item =
                      searchResults.isNotEmpty
                          ? searchResults[index]
                          : filteredSurahList[index];

                  return GestureDetector(
                    onTap: () {
                      if (item.containsKey('doa')) {
                        showDoaBottomSheet(context, item);
                      } else {
                        Navigator.pushNamed(
                          context,
                          '/surah',
                          arguments: item['nomor'],
                        ).then(
                          (_) => setState(() {}),
                        ); // Refresh FutureBuilder setelah kembali;
                      }
                    },
                    child:
                        item.containsKey('doa')
                            ? DoaItem(number: index + 1, title: item['doa'])
                            : SuraItem(
                              number: index + 1,
                              title: item['namaLatin'],
                              details:
                                  '${item['jumlahAyat']} Ayat | ${item['tempatTurun']}',
                              arabicTitle: item['nama'],
                              surahData: item,
                            ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.schedule,
              color: Theme.of(context).colorScheme.secondary,
            ),
            label: 'Jadwal Adzan',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.secondary,
            ),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/jadwal');
              break;
            case 2:
              showSettingBottomSheet(context);
              break;
          }
        },
      ),
    );
  }
}
