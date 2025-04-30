import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchPage extends StatefulWidget {
  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _reports = [];
  String _searchQuery = '';

  double _maxDistance = 1000.0;
  String? _selectedIssueType;
  final List<String> _issueTypes = ['wheelchair', 'elevator', 'braille'];

  @override
  void initState() {
    super.initState();
    _listenForReports();
  }

  void _listenForReports() {
    _database.child('reports').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        List<Map<String, dynamic>> newReports = [];
        data.forEach((key, value) {
          if (value is Map) {
            newReports.add({
              'timestamp': value['timestamp'] ?? '',
              'name': value['name'] ?? 'Unknown Place',
              'issue': value['issue'] ?? 'Unknown Issue',
              'distance':
                  double.tryParse(value['distance']?.toString() ?? '0') ?? 0.0,
            });
          }
        });

        setState(() {
          _reports = newReports.reversed.toList();
        });
      }
    });
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
    return Container(
      color: Colors.blueAccent,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by place name...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
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
                                    thumbColor: Theme.of(context).primaryColor,
                                    activeColor: Theme.of(context).primaryColor,
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
                                        MediaQuery.of(context).size.width * 0.8,
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
                                            backgroundColor:
                                                Theme.of(context).primaryColor,
                                            textStyle: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            foregroundColor: Colors.white),
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
                                          style: TextStyle(color: Colors.red),
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
                  icon: Icon(
                    Icons.filter_list,
                    color: Colors.white,
                  ),
                  label: Text("Filters"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    textStyle: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: Builder(
                builder: (context) {
                  final filtered = getFilteredReports();
                  return filtered.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No reports available'
                                : 'No places found matching "$_searchQuery"',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final report = filtered[index];
                            return Card(
                              color: Colors.white,
                              margin: EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading:
                                    Icon(Icons.report, color: Colors.black),
                                title: Text(
                                  report['name'],
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Issue: ${report['issue']}'),
                                    Text('Distance: ${report['distance']} km'),
                                    Text('Date: ${report['timestamp']}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
