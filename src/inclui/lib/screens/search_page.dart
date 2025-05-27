import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:inclui/screens/place_detail_page.dart';

class SearchPage extends StatefulWidget {
  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;

  List<Map<String, dynamic>> _reports = [];
  List<Map<String, String>> _placePredictions = [];
  String _searchQuery = '';

  double _maxDistance = 1000.0;
  String? _selectedIssueType;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final query = _searchController.text;
      if (query.isEmpty) {
        setState(() => _placePredictions = []);
        return;
      }

      final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}'
        '&components=country:pt'
        '&types=establishment',
      ));

      final json = jsonDecode(response.body);
      if (json['status'] == 'OK') {
        final predictions = json['predictions'] as List;
        setState(() {
          _placePredictions = predictions.map((p) {
            return {
              'name': p['structured_formatting']['main_text'] as String,
              'address': p['description'] as String,
              'placeId': p['place_id'] as String,
            };
          }).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> getFilteredReports() {
    return _reports.where((report) {
      final nameMatches =
          report['name'].toLowerCase().contains(_searchQuery.toLowerCase());

      final distanceMatches = report['distance'] <= _maxDistance;

      final issueMatches = _selectedIssueType == null ||
          _selectedIssueType!.isEmpty ||
          report['issue'].toString().toLowerCase() ==
              _selectedIssueType!.toLowerCase();

      return nameMatches && distanceMatches && issueMatches;
    }).toList();
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          ),
          SizedBox(height: 16),
          Text(
            'Search for a place',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Type in the search bar to find accessible places',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            'No results found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Try searching with different keywords or check the spelling',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: Colors.grey.shade100,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search by place name...',
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey[600]),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close,
                                      color: Colors.grey[600]),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _placePredictions = []);
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 2.0),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                          _onSearchChanged();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: _searchController.text.isEmpty
                    ? _buildEmptySearchState()
                    : _placePredictions.isEmpty &&
                            _searchController.text.isNotEmpty
                        ? _buildNoResultsFound()
                        : ListView.builder(
                            itemCount: _placePredictions.length,
                            itemBuilder: (context, index) {
                              final prediction = _placePredictions[index];
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: Colors.grey.shade300, width: 1.0),
                                ),
                                margin: EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 6),
                                color: Colors.white,
                                shadowColor: Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        onTap: () {
                                          final placeId = prediction['placeId'];
                                          final placeName = prediction['name'];
                                          final placeAddr =
                                              prediction['address'];
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PlaceDetailPage(
                                                placeId: placeId!,
                                                placeName: placeName!,
                                                placeAddr: placeAddr!,
                                              ),
                                            ),
                                          );
                                        },
                                        leading: Icon(Icons.place,
                                            color:
                                                Theme.of(context).primaryColor),
                                        title: Text(prediction['name'] ?? '',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                            )),
                                        subtitle:
                                            Text(prediction['address'] ?? ''),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
