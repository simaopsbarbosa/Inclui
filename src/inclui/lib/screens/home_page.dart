import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:inclui/constants.dart';
import 'package:inclui/services/auth_service.dart';
import 'dart:convert';
import 'dart:math';

import 'package:inclui/widgets/circle_icon.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

Future<Position> _determinePosition() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }
  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }
  return await Geolocator.getCurrentPosition();
}

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late Future<Position> _positionFuture;
  final Set<Marker> _markers = {};
  bool _isLoading = false;
  String _greeting = "Welcome!";

  @override
  void initState() {
    super.initState();
    _positionFuture = _determinePosition();
    _fetchReports();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _updateGreeting();
    });

    FirebaseAuth.instance.userChanges().listen((User? user) {
      _updateGreeting();
    });

    _updateGreeting();
  }

  Future<void> _updateGreeting() async {
    String greeting = await AuthService.getFormattedUserName();
    setState(() {
      _greeting = greeting;
    });
  }

  Future<LatLng> _getLatLngFromPlaceId(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Places API HTTP ${response.statusCode} for placeId $placeId',
      );
    }

    final Map<String, dynamic> body = jsonDecode(response.body);

    final status = body['status'] as String?;
    if (status != 'OK') {
      final errMsg = body['error_message'] ?? 'no error_message';
      throw Exception('Places API status=$status: $errMsg');
    }

    final result = body['result'] as Map<String, dynamic>?;
    final geometry = result?['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;

    if (location == null ||
        location['lat'] == null ||
        location['lng'] == null) {
      throw Exception('No geometry.location for placeId $placeId');
    }

    final lat = (location['lat'] as num).toDouble();
    final lng = (location['lng'] as num).toDouble();

    return LatLng(lat, lng);
  }

  Future<CircleIcon> _getPlaceIcon(String placeId) async {
    final dbRef =
        FirebaseDatabase.instance.ref().child('reports').child(placeId);
    final snapshot = await dbRef.get();

    final CircleIcon fallbackIcon = CircleIcon(
      icon: Icons.error,
      size: 100.0,
      iconColor: Colors.white,
      backgroundColor: Theme.of(context).primaryColor,
    );

    if (!snapshot.exists || snapshot.value == null) {
      return fallbackIcon;
    }

    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

    final Map<String, int> counts = {};
    data.forEach((issueType, reportsMap) {
      if (reportsMap is Map) {
        counts[issueType.toString()] = reportsMap.length;
      }
    });

    if (counts.isEmpty) {
      return fallbackIcon;
    }

    final List<String> preferences = await AuthService.getUserPreferences();

    final Map<String, int> preferredCounts = {
      for (final entry in counts.entries)
        if (preferences.contains(entry.key)) entry.key: entry.value,
    };

    String chosenType;

    bool usedPrefereces = false;
    if (preferredCounts.isNotEmpty) {
      final int maxPreferred = preferredCounts.values.reduce(max);
      final List<String> topPreferred = preferredCounts.entries
          .where((entry) => entry.value == maxPreferred)
          .map((entry) => entry.key)
          .toList()
        ..sort();
      chosenType = topPreferred.first;
      usedPrefereces = true;
    } else {
      final int maxGeneral = counts.values.reduce(max);
      final List<String> topGeneral = counts.entries
          .where((entry) => entry.value == maxGeneral)
          .map((entry) => entry.key)
          .toList()
        ..sort();
      chosenType = topGeneral.first;
    }
    return CircleIcon(
      icon: accessibilityIssues[chosenType] ?? Icons.error,
      size: usedPrefereces ? 100.0 : 80.0,
      backgroundColor:
          usedPrefereces ? Theme.of(context).primaryColor : Colors.white,
      iconColor: usedPrefereces ? Colors.white : Theme.of(context).primaryColor,
      transparency: usedPrefereces ? 1.0 : 0.95,
    );
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
    });

    final dbRef = FirebaseDatabase.instance.ref().child("reports");
    final snapshot = await dbRef.get();

    if (!snapshot.exists) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final data = snapshot.value as Map<dynamic, dynamic>;
    final double size = 100.0;

    _markers.clear();
    for (final placeId in data.keys) {
      try {
        final LatLng loc = await _getLatLngFromPlaceId(placeId as String);
        final CircleIcon icon = await _getPlaceIcon(placeId);

        _markers.add(
          Marker(
            markerId: MarkerId(placeId),
            position: loc,
            icon: await icon.toBitmapDescriptor(
                logicalSize: Size(size, size), imageSize: Size(size, size)),
          ),
        );
      } catch (e) {
        debugPrint('Could not load marker for $placeId → $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Position>(
      future: _positionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey.shade100,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          Position userLocation = snapshot.data!;
          return Container(
            color: Colors.grey.shade100,
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Text(
                    _greeting,
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Discover accessible places around you',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 30),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: Stack(
                          children: [
                            GoogleMap(
                              key: ValueKey('google_map'),
                              markers: _markers,
                              myLocationEnabled: true,
                              initialCameraPosition: CameraPosition(
                                target: LatLng(userLocation.latitude,
                                    userLocation.longitude),
                                zoom: 18.0,
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 75,
                              child: PhysicalModel(
                                color: Colors.transparent,
                                elevation: 2.0,
                                shadowColor: Colors.black87,
                                shape: BoxShape.circle,
                                child: ClipOval(
                                  child: Material(
                                    color: _isLoading
                                        ? Colors.white
                                        : Theme.of(context).primaryColor,
                                    child: InkWell(
                                      onTap: _isLoading ? null : _fetchReports,
                                      child: SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: Center(
                                          child: _isLoading
                                              ? CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Colors.grey.shade600,
                                                  ),
                                                )
                                              : Icon(Icons.refresh,
                                                  color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return Container(
            color: Colors.grey.shade100,
            child: Center(child: Text('No location data available')),
          );
        }
      },
    );
  }
}
