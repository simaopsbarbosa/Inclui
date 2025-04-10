import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _reports = [];
  String _searchQuery = '';

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
              'distance': value['distance']?.toString() ?? '0',
            });
          }
        });

        setState(() {
          _reports = newReports.reversed.toList();
        });
      }
    });
  }

  void _clearReports() {
    _database.child('reports').set({}).then((_) {
      setState(() {
        _reports.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).primaryColor,
          content: Text("All reports cleared"),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  // Modificado para filtrar APENAS pelo nome
  List<Map<String, dynamic>> get _filteredReports {
    if (_searchQuery.isEmpty) {
      return _reports;
    }
    return _reports.where((report) => 
      report['name'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueAccent,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by place name...', // Texto mais específico
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
                Text(
                  'Reports',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (_reports.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                      size: 32,
                    ),
                    onPressed: _clearReports,
                  ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: _filteredReports.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty 
                          ? 'No reports available'
                          : 'No places found matching "$_searchQuery"', // Mensagem mais descritiva
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = _filteredReports[index];
                        return Card(
                          color: Colors.white,
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: Icon(Icons.report, color: Colors.black),
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
                    ),
            ),
          ],
        ),
      ),
    );
  }
}