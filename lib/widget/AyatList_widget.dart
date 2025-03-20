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
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CancelToken {
  bool isCancelled = false;

  void cancel() {
    isCancelled = true;
  }
}

class AudioController {
  static final AudioController _instance = AudioController._internal();
  final ItemScrollController itemScrollController = ItemScrollController();
  ItemScrollController? scrollController;

void setScrollController(ItemScrollController controller) {
  scrollController = controller;
}

  factory AudioController() {
    return _instance;
  }

  AudioController._internal();

  final Map<String, _AyatItemState> _ayatItems = {};
  _AyatItemState? _activePlayer;
  
  // Track download status for each ayat
  final Map<String, bool> _downloadStatus = {}; // true = downloaded, false = downloading

  // Queue for background downloads
  final List<Map<String, dynamic>> _downloadQueue = [];
  bool _isDownloading = false;
  
  // Map to store each ayat's position
  final Map<String, GlobalKey> _ayatKeys = {};

  // Stream untuk menerima event perubahan status player
  final StreamController<bool> _playerStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onPlayerStatusChanged => _playerStatusController.stream;

  // New stream for ayat changes
  final StreamController<Map<String, dynamic>> _ayatChangeController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onAyatChanged => _ayatChangeController.stream;

  void registerAyatItem(_AyatItemState ayatItem) {
    final key = "${ayatItem.widget.surahNumber}_${ayatItem.widget.number}";
    _ayatItems[key] = ayatItem;
    
    // Register the ayat's key for scrolling
    _ayatKeys[key] = GlobalKey();
  }

  void unregisterAyatItem(_AyatItemState ayatItem) {
    final key = "${ayatItem.widget.surahNumber}_${ayatItem.widget.number}";
    _ayatItems.remove(key);
    _ayatKeys.remove(key);

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
    
    // Notify listeners about the ayat change
    _ayatChangeController.add({
      'surahNumber': player.widget.surahNumber,
      'ayatNumber': player.widget.number
    });
    
    // Scroll to the active ayat
    scrollToAyat(player.widget.number); // Untuk scroll saat audio diputar
  }

  GlobalKey? getAyatKey(int surahNumber, int ayatNumber) {
    final key = "${surahNumber}_${ayatNumber}";
    return _ayatKeys[key];
  }

  void scrollToAyat(int ayatNumber, {bool isLastRead = false}) {
    if (scrollController == null) return;

    int index = isLastRead ? ayatNumber - 1 : ayatNumber + 1;

    scrollController!.scrollTo(
      index: ayatNumber + 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  _AyatItemState? findAyatItem(int surahNumber, int ayatNumber) {
    final key = "${surahNumber}_${ayatNumber}";
    return _ayatItems[key];
  }

  // Get download status for a specific ayat
  bool isAyatDownloaded(int surahNumber, int ayatNumber, String qariId) {
    final key = "${surahNumber}_${ayatNumber}_$qariId";
    return _downloadStatus[key] == true;
  }

  // Set download status for a specific ayat
  void setAyatDownloadStatus(int surahNumber, int ayatNumber, String qariId, bool status) {
    final key = "${surahNumber}_${ayatNumber}_$qariId";
    _downloadStatus[key] = status;
  }

  // Add ayat to download queue
  Future<void> queueAyatDownload(int surahNumber, int ayatNumber, String qariId, BuildContext context) async {
    final key = "${surahNumber}_${ayatNumber}_$qariId";
    
    // Skip if already downloaded or in the queue
    if (_downloadStatus[key] == true || 
        _downloadQueue.any((item) => 
            item['surahNumber'] == surahNumber && 
            item['ayatNumber'] == ayatNumber && 
            item['qariId'] == qariId)) {
      return;
    }
    
    // Add to queue
    _downloadQueue.add({
      'surahNumber': surahNumber,
      'ayatNumber': ayatNumber,
      'qariId': qariId,
      'context': context,
    });
    
    // Set initial status to downloading
    _downloadStatus[key] = false;
    
    // Start processing the queue if not already processing
    if (!_isDownloading) {
      _processDownloadQueue();
    }
  }

  // Process the download queue
  Future<void> _processDownloadQueue() async {
    if (_downloadQueue.isEmpty || _isDownloading) return;
    
    _isDownloading = true;
    
    while (_downloadQueue.isNotEmpty) {
      final item = _downloadQueue.removeAt(0);
      final surahNumber = item['surahNumber'];
      final ayatNumber = item['ayatNumber'];
      final qariId = item['qariId'];
      final context = item['context'];
      
      final ayatItem = findAyatItem(surahNumber, ayatNumber);
      if (ayatItem != null) {
        try {
          await ayatItem._downloadAudioInBackground(qariId);
        } catch (e) {
          print("Error downloading audio: $e");
          // Set status to not downloaded on error
          setAyatDownloadStatus(surahNumber, ayatNumber, qariId, false);
        }
      }
    }
    
    _isDownloading = false;
  }

  void dispose() {
    _playerStatusController.close();
    _ayatChangeController.close();
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
  final GlobalKey itemKey = GlobalKey();

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
  
  // Tracks if this ayat is currently being downloaded
  bool _isDownloading = false;

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
        
        // Queue download of next several ayats when current ayat starts playing
        if (currentQariId != null) {
          _queueNextAyatsDownload();
        }
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

  // Queue downloads for next several ayats
  Future<void> _queueNextAyatsDownload() async {
    if (currentQariId == null) return;
    
    // Download next 5 ayats
    for (int i = 1; i <= 5; i++) {
      int nextAyat = widget.number + i;
      _AyatItemState? nextAyatItem = AudioController().findAyatItem(
        widget.surahNumber,
        nextAyat,
      );
      
      if (nextAyatItem != null) {
        AudioController().queueAyatDownload(
          widget.surahNumber,
          nextAyat,
          currentQariId!,
          context
        );
      }
    }
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

  // Method to get audio URL from JSON for a specific ayat
  Future<String?> _getAudioUrl(int surahNumber, int ayatNumber, String qariId) async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/json/surah/$surahNumber.json',
      );
      Map<String, dynamic> surahData = json.decode(jsonString);
      List<dynamic> ayatList = surahData['data']['ayat'];
      var ayatData = ayatList.firstWhereOrNull(
        (ayat) => ayat['nomorAyat'] == ayatNumber,
      );

      if (ayatData != null) {
        return ayatData['audio'][qariId];
      }
    } catch (e) {
      print("Error saat membaca JSON: $e");
    }
    return null;
  }

  // Background download without showing dialog
  Future<void> _downloadAudioInBackground(String qariId) async {
    if (_isDownloading) return;
    
    _isDownloading = true;
    final fileName = "${widget.surahNumber}_${widget.number}_$qariId.mp3";
    final filePath = await getAudioFilePath(fileName);

    // Check if file already exists
    if (await File(filePath).exists()) {
      AudioController().setAyatDownloadStatus(widget.surahNumber, widget.number, qariId, true);
      _isDownloading = false;
      return;
    }

    try {
      String? audioUrl = await _getAudioUrl(widget.surahNumber, widget.number, qariId);
      
      if (audioUrl == null) {
        _isDownloading = false;
        return;
      }

      // Download file
      final dioInstance = dio_package.Dio();
      await dioInstance.download(
        audioUrl,
        filePath,
      );

      // Mark as downloaded
      AudioController().setAyatDownloadStatus(widget.surahNumber, widget.number, qariId, true);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ayat ${widget.number} berhasil diunduh", style: TextStyle(color: Colors.white)),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("Error downloading audio: $e");
      // Delete partial file if it exists
      if (await File(filePath).exists()) {
        await File(filePath).delete();
      }
      AudioController().setAyatDownloadStatus(widget.surahNumber, widget.number, qariId, false);
    }
    
    _isDownloading = false;
  }

  // Primary download function when user explicitly wants to play
  Future<void> downloadAudio(
    BuildContext context,
    String audioUrl,
    String fileName,
  ) async {
    final filePath = await getAudioFilePath(fileName);
    
    // Extract qari ID from filename
    final qariId = fileName.split('_').last.split('.').first;

    // Gunakan library dio
    final dioInstance = dio_package.Dio();

    try {
      // Cek apakah file sudah ada
      if (await File(filePath).exists()) {
        AudioController().setAyatDownloadStatus(widget.surahNumber, widget.number, qariId, true);
        await _audioPlayer.play(DeviceFileSource(filePath));
        AudioController().setActivePlayer(this);
        return;
      }

      // Mulai download audio
      setState(() {
        _isDownloading = true;
      });
      
      await dioInstance.download(
        audioUrl,
        filePath,
      );

      setState(() {
        _isDownloading = false;
      });

      // Setelah download selesai, tampilkan snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Unduhan selesai", style: TextStyle(color: Colors.white)),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }

      // Set download status
      AudioController().setAyatDownloadStatus(widget.surahNumber, widget.number, qariId, true);

      // Set qari yang sedang diputar
      setState(() {
        currentQariId = qariId;
        currentAyatNumber = widget.number;
      });
      
      // Play audio
      await _audioPlayer.play(DeviceFileSource(filePath));
      AudioController().setActivePlayer(this);
      
      // Queue download for next ayats
      _queueNextAyatsDownload();
      
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      
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

    // Check download status first
    bool isDownloaded = AudioController().isAyatDownloaded(widget.surahNumber, widget.number, qariId);
    bool fileExists = await checkAudioExists(fileName);
    
    // Update status if file exists but not marked as downloaded
    if (fileExists && !isDownloaded) {
      AudioController().setAyatDownloadStatus(widget.surahNumber, widget.number, qariId, true);
      isDownloaded = true;
    }
    
    if (isDownloaded && fileExists) {
      // Set active ayat
      AudioController().setActivePlayer(this);

      setState(() {
        currentAyatNumber = widget.number;
        isPlaying = true;
      });

      await _audioPlayer.play(DeviceFileSource(filePath));
      
      // Queue download for next ayats
      _queueNextAyatsDownload();
      return;
    }
    
    // Check if currently downloading
    if (_isDownloading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pengunduhan belum selesai, coba lagi", style: TextStyle(color: Colors.white)),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    // Need to download the file
    try {
      String? audioUrl = await _getAudioUrl(widget.surahNumber, widget.number, qariId);
      
      if (audioUrl != null) {
        if (autoPlay) {
          showDownloadDialog(context, audioUrl, fileName);
        }
      }
    } catch (e) {
      print("Error saat membaca JSON: $e");
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
      // Check if downloaded
      bool isDownloaded = AudioController().isAyatDownloaded(
        widget.surahNumber, 
        prevAyat, 
        currentQariId!
      );
      
      bool fileExists = await prevAyatItem.checkAudioExists(
        "${widget.surahNumber}_${prevAyat}_${currentQariId!}.mp3"
      );
      
      if (!isDownloaded || !fileExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pengunduhan belum selesai, coba lagi", style: TextStyle(color: Colors.white)),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        return;
      }
      
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
      // Check if downloaded
      bool isDownloaded = AudioController().isAyatDownloaded(
        widget.surahNumber, 
        nextAyat, 
        currentQariId!
      );
      
      bool fileExists = await nextAyatItem.checkAudioExists(
        "${widget.surahNumber}_${nextAyat}_${currentQariId!}.mp3"
      );
      
      if (!isDownloaded || !fileExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pengunduhan belum selesai, coba lagi", style: TextStyle(color: Colors.white)),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        
        // Try to download it now
        String? audioUrl = await _getAudioUrl(widget.surahNumber, nextAyat, currentQariId!);
        if (audioUrl != null) {
          nextAyatItem.downloadAudio(
            context, 
            audioUrl, 
            "${widget.surahNumber}_${nextAyat}_${currentQariId!}.mp3"
          );
        }
        return;
      }
      
      await stopAudio();
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
      key: widget.itemKey, // Use the item's GlobalKey
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
              style: GoogleFonts.getFont(
                settings.latinFontFamily,
                fontSize: settings.latinFontSize,
                fontWeight: settings.latinFontWeight,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.translation,
              style: GoogleFonts.getFont(
                settings.translateFontFamily,
                fontSize: settings.translationFontSize,
                fontWeight: settings.translateFontWeight,
                color: Theme.of(context).colorScheme.primary,
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
