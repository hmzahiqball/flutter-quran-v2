// Import semua package yang diperlukan di awal
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_quran/widget/LastReadModal_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../provider/settings_provider.dart';
import 'TafsirModal_widget.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart' as dio_package;
import 'dart:async';

class CancelToken {
  bool isCancelled = false;

  void cancel() {
    isCancelled = true;
  }
}


class AudioController {
  static final AudioController _instance = AudioController._internal();

  factory AudioController() {
    return _instance;
  }

  AudioController._internal();

  final Map<String, _AyatItemState> _ayatItems =
      {}; // key: "${surahNumber}_${ayatNumber}"
  _AyatItemState? _activePlayer;

  // Stream untuk menerima event perubahan status player
  final StreamController<bool> _playerStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get onPlayerStatusChanged => _playerStatusController.stream;

  void registerAyatItem(_AyatItemState ayatItem) {
    final key = "${ayatItem.widget.surahNumber}_${ayatItem.widget.number}";
    _ayatItems[key] = ayatItem;
  }

  void unregisterAyatItem(_AyatItemState ayatItem) {
    final key = "${ayatItem.widget.surahNumber}_${ayatItem.widget.number}";
    _ayatItems.remove(key);

    if (_activePlayer == ayatItem) {
      _activePlayer = null;
      _playerStatusController.add(false);
    }
  }

  void setActivePlayer(_AyatItemState player) {
    // Hentikan player yang aktif sebelumnya jika ada dan berbeda
    if (_activePlayer != null && _activePlayer != player) {
      _activePlayer!.stopAudio();
    }
    _activePlayer = player;
    _playerStatusController.add(true);
  }

  _AyatItemState? findAyatItem(int surahNumber, int ayatNumber) {
    final key = "${surahNumber}_${ayatNumber}";
    return _ayatItems[key];
  }

  void dispose() {
    _playerStatusController.close();
  }
}

class AyatItem extends StatefulWidget {
  final int surahNumber;
  final String title;
  final String arabicTitle;
  final String type;
  final int number;
  final String arabicText;
  final String translation;
  final String latin;

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
  State<AyatItem> createState() => _AyatItemState();
}

class _AyatItemState extends State<AyatItem> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  String? currentQariId;
  int? currentAyatNumber;
  StreamSubscription? _playerStateSubscription;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Mendengarkan perubahan status player
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      state,
    ) {
      if (state == PlayerState.completed) {
        setState(() {
          isPlaying = false;
        });
        // Secara opsional, lanjutkan ke ayat berikutnya
        if (currentQariId != null && currentAyatNumber == widget.number) {
          _playNextAyat();
        }
      } else if (state == PlayerState.playing) {
        setState(() {
          isPlaying = true;
          currentAyatNumber = widget.number;
        });
      } else if (state == PlayerState.paused || state == PlayerState.stopped) {
        setState(() {
          isPlaying = false;
        });
      }
    });

    // Mendaftarkan widget ini ke AudioController singleton
    AudioController().registerAyatItem(this);
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    AudioController().unregisterAyatItem(this);
    super.dispose();
  }

  String convertToArabicNumeral(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
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

  Future<String> getAudioFilePath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio');
    if (!await audioDir.exists()) {
      await audioDir.create();
    }
    return '${audioDir.path}/$fileName';
  }

  Future<bool> checkAudioExists(String fileName) async {
    final filePath = await getAudioFilePath(fileName);
    return File(filePath).exists();
  }

  Future<void> downloadAudio(
    BuildContext context,
    String audioUrl,
    String fileName,
  ) async {
    final filePath = await getAudioFilePath(fileName);

    // Gunakan library dio
    final dioInstance = dio_package.Dio();
    final dioCancelToken = dio_package.CancelToken();

    try {
      // Cek apakah file sudah ada, jika ada hapus
      if (await File(filePath).exists()) {
        // await File(filePath).delete();
        await _audioPlayer.play(DeviceFileSource(filePath));
        return; // Keluar dari fungsi setelah memutar audio
      }

      // Mulai download audio
      await dioInstance.download(
        audioUrl,
        filePath,
        cancelToken: dioCancelToken,
      );

      // Setelah download selesai, tampilkan snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unduhan selesai", style: TextStyle(color: Colors.white)),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      // Set qari yang sedang diputar
      setState(() {
        currentQariId = fileName.split('_').last.split('.').first;
        currentAyatNumber = widget.number;
      });
    } on Exception catch (e) {
      if (context.mounted) {
        // Jika terjadi error, hapus file jika ada
        if (await File(filePath).exists()) {
          await File(filePath).delete();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: Tidak Dapat Mendapatkan Audio", style: TextStyle(color: Colors.white)),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        // Download ulang setelah error
        await downloadAudio(context, audioUrl, fileName);
      }
    }
    try{
      // Beritahu AudioController bahwa player ini aktif
      AudioController().setActivePlayer(this);
      // Putar audio
      await _audioPlayer.play(DeviceFileSource(filePath));
    } on Exception catch (e) {
      if (context.mounted) {
        // Jika terjadi error, hapus file jika ada
        if (await File(filePath).exists()) {
          await File(filePath).delete();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: Tidak Dapat Mendapatkan Audio", style: TextStyle(color: Colors.white)),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        // Download ulang setelah error
        await downloadAudio(context, audioUrl, fileName);
      }
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

  Future<void> playAudio(String qariId, {bool autoPlay = true}) async {
    setState(() {
      currentQariId = qariId;
    });

    final fileName = "${widget.surahNumber}_${widget.number}_$qariId.mp3";
    final filePath = await getAudioFilePath(fileName);

    bool exists = await checkAudioExists(fileName);
    if (!exists) {
      try {
        String jsonString = await rootBundle.loadString(
          'assets/json/surah/${widget.surahNumber}.json',
        );
        Map<String, dynamic> surahData = json.decode(jsonString);
        List<dynamic> ayatList = surahData['data']['ayat'];
        var ayatData = ayatList.firstWhereOrNull(
          (ayat) => ayat['nomorAyat'] == widget.number,
        );

        if (ayatData != null) {
          String? audioUrl = ayatData['audio'][qariId];
          if (audioUrl != null) {
            if (autoPlay) {
              showDownloadDialog(context, audioUrl, fileName);
            } else {
              return;
            }
          }
        }
      } catch (e) {
        print("Error saat membaca JSON: $e");
      }
    } else {
      // Set active ayat
      AudioController().setActivePlayer(this);

      setState(() {
        currentAyatNumber = widget.number;
        isPlaying = true;
      });

      await _audioPlayer.play(DeviceFileSource(filePath));
    }
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
    setState(() {
      isPlaying = false;
    });
  }

  Future<void> resumeAudio() async {
    await _audioPlayer.resume();
    setState(() {
      isPlaying = true;
    });
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      isPlaying = false;
    });
  }

  Future<void> _playPreviousAyat() async {
    if (currentQariId == null) return;

    int prevAyat = widget.number - 1;
    if (prevAyat < 1) return; // Jika sudah ayat pertama

    // Cari dan play audio
    _AyatItemState? prevAyatItem = AudioController().findAyatItem(
      widget.surahNumber,
      prevAyat,
    );
    if (prevAyatItem != null) {
      await stopAudio();
      prevAyatItem.playAudio(currentQariId!);
    }
  }

  Future<void> _playNextAyat() async {
    if (currentQariId == null) return;

    int nextAyat = widget.number + 1;

    // Cari dan play audio
    _AyatItemState? nextAyatItem = AudioController().findAyatItem(
      widget.surahNumber,
      nextAyat,
    );
    if (nextAyatItem != null) {
    // Download audio untuk ayat berikutnya tanpa progress
    String fileName = "${nextAyatItem.widget.surahNumber}_${nextAyatItem.widget.number}_$currentQariId.mp3";
    String audioUrl = ""; // Ambil URL audio dari data yang sesuai

    // Ambil URL audio dari JSON atau sumber lain
    String jsonString = await rootBundle.loadString(
      'assets/json/surah/${nextAyatItem.widget.surahNumber}.json',
    );
    Map<String, dynamic> surahData = json.decode(jsonString);
    List<dynamic> ayatList = surahData['data']['ayat'];
    var ayatData = ayatList.firstWhereOrNull(
      (ayat) => ayat['nomorAyat'] == nextAyatItem.widget.number,
    );

    if (ayatData != null) {
      audioUrl = ayatData['audio'][currentQariId];
    }

    // Download audio untuk ayat berikutnya tanpa progress
    await downloadAudio(context, audioUrl, fileName);
    nextAyatItem.playAudio(currentQariId!);
    }
  }

  void onQariSelected(BuildContext context, String qariId) async {
    await playAudio(qariId);
  }

  void showAyatBottomSheet(BuildContext context, int number) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 500),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return BookmarkModalWidget(
          title: widget.title,
          ayat: number.toString(),
          onSave: () async {
            try {
              await saveLastRead(
                widget.title,
                widget.arabicTitle,
                widget.type,
                number,
              );
              Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Gagal menyimpan terakhir baca")),
              );
            }
          },
          onPlayAudio: () {
            showQariSelectionModal(context, (selectedQariId) {
              onQariSelected(context, selectedQariId);
            });
          },
          onShowTafsir: () {
            showTafsirModal(context, widget.surahNumber, number, widget.title);
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

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return GestureDetector(
      onTap: () => showAyatBottomSheet(context, widget.number),
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
                      convertToArabicNumeral(widget.number),
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
                        widget.arabicText,
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
              widget.latin,
              style: GoogleFonts.baloo2(
                fontSize: settings.latinFontSize,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.translation,
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

// Widget AudioFloatingController untuk tombol kontrol audio melayang
class AudioFloatingController extends StatefulWidget {
  @override
  _AudioFloatingControllerState createState() =>
      _AudioFloatingControllerState();
}

class _AudioFloatingControllerState extends State<AudioFloatingController> {
  bool isVisible = false;
  StreamSubscription? _playerStatusSubscription;

  @override
  void initState() {
    super.initState();

    // Dengarkan perubahan status player
    _playerStatusSubscription = AudioController().onPlayerStatusChanged.listen((
      active,
    ) {
      setState(() {
        isVisible = active;
      });
    });

    // Cek status awal
    isVisible = AudioController()._activePlayer != null;
  }

  @override
  void dispose() {
    _playerStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return SizedBox.shrink();

    return Positioned(
      bottom: 30,
      right: 20,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.skip_previous),
                onPressed: () {
                  final player = AudioController()._activePlayer;
                  if (player != null) {
                    player._playPreviousAyat();
                  }
                },
              ),
              StreamBuilder<PlayerState>(
                stream:
                    AudioController()
                        ._activePlayer
                        ?._audioPlayer
                        .onPlayerStateChanged,
                initialData: PlayerState.stopped,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data == PlayerState.playing;
                  return IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      final player = AudioController()._activePlayer;
                      if (player != null) {
                        if (isPlaying) {
                          player.pauseAudio();
                        } else {
                          player.resumeAudio();
                        }
                      }
                    },
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.skip_next),
                onPressed: () {
                  final player = AudioController()._activePlayer;
                  if (player != null) {
                    player._playNextAyat();
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  final player = AudioController()._activePlayer;
                  if (player != null) {
                    player.pauseAudio();
                    setState(() {
                      isVisible = false;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
