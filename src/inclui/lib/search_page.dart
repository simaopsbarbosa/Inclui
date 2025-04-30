import 'dart:async';
import 'dart:convert';
// import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:inclui/place_detail_page.dart';

class SearchPage extends StatefulWidget {
  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  // final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;

  List<Map<String, dynamic>> _reports = [];
  List<Map<String, String>> _placePredictions = [];
  String _searchQuery = '';

  double _maxDistance = 1000.0;
  String? _selectedIssueType;
  final List<String> _issueTypes = ['wheelchair', 'elevator', 'braille'];

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

  void _clearFilters() {
    setState(() {
      _maxDistance = 1000.0;
      _selectedIssueType = null;
      _searchQuery = '';
      _searchController.clear();
    });
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: Colors.white,
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
                        onChanged: (value) => _onSearchChanged(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.filter_list, color: Colors.white),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        showModalBottomSheet(
                          context: context,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          backgroundColor: Colors.white,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (BuildContext context,
                                  StateSetter modalSetState) {
                                return Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Filters',
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Max Distance (km)',
                                        style: GoogleFonts.inter(fontSize: 14),
                                      ),
                                      Slider(
                                        thumbColor:
                                            Theme.of(context).primaryColor,
                                        activeColor:
                                            Theme.of(context).primaryColor,
                                        inactiveColor: Colors.grey[300],
                                        value: _maxDistance,
                                        min: 0,
                                        max: 1000,
                                        divisions: 20,
                                        label:
                                            '${_maxDistance.toStringAsFixed(0)} km',
                                        onChanged: (value) {
                                          modalSetState(() {
                                            _maxDistance = value;
                                          });
                                          setState(() {});
                                        },
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Issue Type',
                                        style: GoogleFonts.inter(fontSize: 14),
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.8,
                                        child: DropdownButton<String>(
                                          value: _selectedIssueType,
                                          isExpanded: true,
                                          hint: Text('Select'),
                                          items: _issueTypes.map((String type) {
                                            return DropdownMenuItem<String>(
                                              value: type,
                                              child: Text(type),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            modalSetState(() {
                                              _selectedIssueType = value;
                                            });
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .primaryColor,
                                              textStyle: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              foregroundColor: Colors.white,
                                            ),
                                            child: Text("Apply"),
                                          ),
                                          TextButton.icon(
                                            onPressed: () {
                                              _clearFilters();
                                              Navigator.pop(context);
                                            },
                                            icon: Icon(Icons.delete_forever,
                                                color: Colors.red),
                                            label: Text(
                                              'Clear Filters',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 40),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _placePredictions.length,
                  itemBuilder: (context, index) {
                    final prediction = _placePredictions[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side:
                            BorderSide(color: Colors.grey.shade300, width: 1.0),
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                      color: Colors.grey.shade100,
                      shadowColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          children: [
                            ListTile(
                              onTap: () {
                                final placeId = prediction['placeId'];
                                final placeName = prediction['name'];
                                final placeAddr = prediction['address'];
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlaceDetailPage(
                                      placeId: placeId!,
                                      placeName: placeName!,
                                      placeAddr: placeAddr!,
                                    ),
                                  ),
                                );
                              },
                              leading: Icon(Icons.place,
                                  color: Theme.of(context).primaryColor),
                              title: Text(prediction['name'] ?? ''),
                              subtitle: Text(prediction['address'] ?? ''),
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
