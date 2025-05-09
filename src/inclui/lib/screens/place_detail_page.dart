import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:inclui/constants.dart';
import 'package:inclui/widgets/report_modal.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:inclui/services/auth_service.dart';

class PlaceDetailPage extends StatefulWidget {
  final String placeId;
  final String placeName;
  final String placeAddr;

  const PlaceDetailPage({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.placeAddr,
  });

  @override
  _PlaceDetailPageState createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  late Future<String?> _photoFuture;
  late Future<DataSnapshot> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _photoFuture = fetchPlacePhotoUrl();
    _reportsFuture = _loadReports();
  }

  Future<String?> fetchPlacePhotoUrl() async {
    final detailsRes = await http.get(Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=${widget.placeId}&fields=photo&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}',
    ));

    if (detailsRes.statusCode == 200) {
      final json = jsonDecode(detailsRes.body);
      final photos = json['result']?['photos'];
      if (photos != null && photos.isNotEmpty) {
        final photoRef = photos[0]['photo_reference'];
        return 'https://maps.googleapis.com/maps/api/place/photo'
            '?maxwidth=400'
            '&photo_reference=$photoRef'
            '&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}';
      }
    }
    return null;
  }

  Future<DataSnapshot> _loadReports() {
    return FirebaseDatabase.instance.ref('reports/${widget.placeId}').get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        title: Text(
          'Place Details',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: BackButton(),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: FutureBuilder<String?>(
        future: _photoFuture,
        builder: (context, photoSnap) {
          if (photoSnap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              backgroundColor: Colors.transparent,
              color: Colors.blue,
            ));
          }
          final imageUrl = photoSnap.data;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                if (imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        height: 200,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      borderRadius: imageUrl != null
                          ? const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            )
                          : BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.placeName,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.placeAddr,
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                FutureBuilder<DataSnapshot>(
                  future: _reportsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: LinearProgressIndicator(),
                      );
                    }
                    if (!snap.hasData || snap.data!.value == null) {
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          "No reports available",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      );
                    }
                    final data = snap.data!.value as Map<dynamic, dynamic>;
                    final issueCounts = <String, int>{};
                    for (final entry in data.entries) {
                      final issue = entry.key as String;
                      final userMap = entry.value as Map<dynamic, dynamic>;
                      issueCounts[issue] = userMap.length;
                    }
                    final totalReports =
                        issueCounts.values.fold(0, (a, b) => a + b);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              '$totalReports Reports',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          Issues(issueCounts: issueCounts),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                ),
                if (AuthService.isUserVerified())
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 48),
                    child: ReportIssueSection(
                      placeId: widget.placeId,
                      onReport: () {
                        setState(() {
                          _reportsFuture = _loadReports();
                        });
                      },
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesomeIcons.triangleExclamation,
                              color: Colors.grey.shade500,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'In order to place reviews, you must be logged in and verified',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 64),
              ],
            ),
          );
        },
      ),
    );
  }
}

class Issues extends StatelessWidget {
  const Issues({
    super.key,
    required this.issueCounts,
  });

  final Map<String, int> issueCounts;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x33D72B5E),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.triangleExclamation,
                color: Color(0xFFD72B5E),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Accessibility Issues:',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(issueCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    accessibilityIssues[entry.key] ??
                        FontAwesomeIcons.solidCircleQuestion,
                    color: Color(0xFFD72B5E),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '(${entry.value})',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: ' ${entry.key}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
