import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblahCompassWidget extends StatefulWidget {
  const QiblahCompassWidget({super.key});

  @override
  State<QiblahCompassWidget> createState() => _QiblahCompassWidgetState();
}

class _QiblahCompassWidgetState extends State<QiblahCompassWidget> with SingleTickerProviderStateMixin {
  Animation<double>? animation;
  AnimationController? _animationController;
  double begin = 0.0;
  bool hasPermission = false;

  Future<void> _getPermission() async {
    if (await Permission.location.serviceStatus.isEnabled) {
      var status = await Permission.location.status;
      if (status.isGranted) {
        setState(() => hasPermission = true);
      } else {
        var result = await Permission.location.request();
        setState(() => hasPermission = (result == PermissionStatus.granted));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    animation = Tween(begin: 0.0, end: 0.0).animate(_animationController!);
    _getPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
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
          const Text(
            'Arah Kiblat',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          hasPermission
              ? StreamBuilder(
                  stream: FlutterQiblah.qiblahStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final qiblahDirection = snapshot.data;
                    animation = Tween(
                      begin: begin,
                      end: (qiblahDirection!.qiblah * (pi / 180) * -1),
                    ).animate(_animationController!);
                    begin = (qiblahDirection.qiblah * (pi / 180) * -1);
                    _animationController!.forward(from: 0);

                    return Column(
                      children: [
                        Text(
                          "${qiblahDirection.direction.toInt()}°",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 200,
                          child: AnimatedBuilder(
                            animation: animation!,
                            builder: (context, child) => Transform.rotate(
                              angle: animation!.value,
                              child: Image.asset('assets/images/kaaba.png'),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              : const Center(
                  child: Text(
                    "Izin lokasi diperlukan untuk menentukan arah kiblat.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
        ],
      ),
    );
  }
}
