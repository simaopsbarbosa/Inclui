import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inclui/profile_page.dart';
import 'package:http/http.dart' as http;

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
      ),
      body: FutureBuilder<String?>(
        future: fetchPlacePhotoUrl(placeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.network(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    height: 250,
                  ),
                ),
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
                if (!verified)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Add your report issue logic here
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).primaryColor),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        child: Text(
                          'Report Issues',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade500,
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
            );
          } else {
            return Center(
              child: Text(
                'No image available\n\nPlace ID: $placeId',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14),
              ),
            );
          }
        },
      ),
    );
  }
}
