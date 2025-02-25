import 'package:flutter/material.dart';

class ListKotaWidget extends StatelessWidget {
  ListKotaWidget({Key? key}) : super(key: key);

  final List<String> _listKota = [
    'Jakarta',
    'Surabaya',
    'Bandung',
    'Medan',
    'Semarang',
    'Makassar',
    'Palembang',
    'Padang',
    'Bekasi',
    'Tangerang',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView.builder(
        itemCount: _listKota.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_listKota[index]),
          );
        },
      ),
    );
  }
}

