import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Marker> databaseMarkers = [];
  Marker? currentLocationMarker;
  bool isLoading = true;
  bool hasError = false;
  LatLng? currentPosition;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    getData();
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Lokasi Tidak Diaktifkan!');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Lokasi Tidak Diizinkan!');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Gagal Memuat Lokasi Karena Lokasi Tidak Diizinkan!');
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
        currentLocationMarker = Marker(
          point: currentPosition!,
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 30,
          ),
        );
      });
    } catch (e) {
      setState(() {
        hasError = true;
      });
      print('Error Lokasi Tidak Ditemukan: $e');
    }
  }

  Future<void> getData() async {
    try {
      var response = await http.get(
        Uri.parse('http://192.168.18.106/maping/tampilkandata.php'),
      );

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        setState(() {
          databaseMarkers = data.map<Marker>((lokasi) {
            return Marker(
              point: LatLng(double.parse(lokasi['latitude']),
                  double.parse(lokasi['longitude'])),
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 20,
              ),
            );
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  void _launchCopyrightUrl() async {
    const url = 'https://openstreetmap.org/copyright';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SiBaDak'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 51, 61, 59),
        foregroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: currentPosition!,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        if (currentLocationMarker != null)
                          currentLocationMarker!,
                        ...databaseMarkers,
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'Esri World Imagery',
                          onTap: _launchCopyrightUrl,
                        ),
                      ],
                    ),
                  ],
                ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: () {},
                  child: const Icon(Icons.home, size: 30),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 5,
                ),
                FloatingActionButton(
                  onPressed: () {},
                  child: const Icon(Icons.bluetooth, size: 30),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
