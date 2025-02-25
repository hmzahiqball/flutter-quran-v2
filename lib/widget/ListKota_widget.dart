import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LocationPickerWidget extends StatefulWidget {
  final Function(String) onLocationSelected;

  const LocationPickerWidget({Key? key, required this.onLocationSelected}) : super(key: key);

  @override
  _LocationPickerWidgetState createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  List<String> cities = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCities();
  }

  Future<void> fetchCities() async {
    final response = await http.get(
      Uri.parse('https://raw.githubusercontent.com/lakuapik/jadwalsholatorg/master/kota.json'),
    );

    if (response.statusCode == 200) {
      setState(() {
        cities = List<String>.from(json.decode(response.body));
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
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
          Center(
            child: Text(
              'List Kota',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          isLoading
              ? Expanded(child: Center(child: CircularProgressIndicator()))
              : Expanded(
                  child: ListView.builder(
                    itemCount: cities.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(cities[index]),
                        onTap: () async {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString('selected_location', cities[index]);
                          widget.onLocationSelected(cities[index]);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
