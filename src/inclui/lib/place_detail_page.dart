import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inclui/profile_page.dart';
import 'package:http/http.dart' as http;
import 'package:inclui/report_panel.dart';
import 'package:firebase_database/firebase_database.dart';

class PlaceDetailPage extends StatelessWidget {
  final String placeId;
  final String placeName;
  final String placeAddr;

  const PlaceDetailPage({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.placeAddr,
  });

  Future<String?> fetchPlacePhotoUrl(String placeId) async {
    final detailsRes = await http.get(Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId&fields=photo&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}',
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

  @override
  Widget build(BuildContext context) {
    final verified = isEmailVerified();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: Text(
          'Place Details',
          style: GoogleFonts.inter(),
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
        future: fetchPlacePhotoUrl(placeId),
        builder: (context, snapshot) {
          final imageUrl = snapshot.data;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        placeName,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        placeAddr,
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                FutureBuilder<DataSnapshot>(
                  future:
                      FirebaseDatabase.instance.ref('reports/$placeId').get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: LinearProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data?.value == null) {
                      return const SizedBox.shrink();
                    }

                    final data = snapshot.data!.value as Map<dynamic, dynamic>;
                    final issueCounts = <String, int>{};

                    for (final entry in data.entries) {
                      final issue = entry.key as String;
                      final userMap = entry.value as Map<dynamic, dynamic>;
                      issueCounts[issue] = userMap.length;
                    }

                    final totalReports =
                        issueCounts.values.fold(0, (a, b) => a + b);

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFD72B5E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalReports Reports',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Accessibility Issues:',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...issueCounts.entries.map((entry) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    '(${entry.value}) ${entry.key}.',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (verified)
                  ReportIssueSection(
                    placeId: placeId,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(32.0),
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
                              Icons.warning_amber_rounded,
                              color: Colors.grey.shade500,
                              size: 32,
                            ),
                            const SizedBox(width: 8),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
