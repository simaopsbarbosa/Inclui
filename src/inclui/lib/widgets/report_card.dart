import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:inclui/constants.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportCard extends StatefulWidget {
  final String userId;
  final Function(int)? onReportsCountChanged;

  const ReportCard({
    required this.userId,
    this.onReportsCountChanged,
    super.key,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  bool _isLoading = true;
  bool _dataFetchError = false;
  Map<String, List<Map<String, dynamic>>> reportsByUser = {};
  Map<String, Map<String, String>> _placeDetailsMap = {};
  StreamSubscription<DatabaseEvent>? _reportsSubscription;

  @override
  void initState() {
    super.initState();
    _setupReportsListener(widget.userId);
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }

  void _updateReportsCount() {
    final count = reportsByUser.values.expand((reports) => reports).length;
    widget.onReportsCountChanged?.call(count);
  }

  Future<Map<String, String>?> fetchPlaceDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];
          final String name = result['name'] ?? 'Unknown Place';
          final String address =
              result['formatted_address'] ?? 'Unknown Address';
          String cleanedAddress = address.replaceAll('s/n, ', '').trim();

          return {'name': name, 'address': cleanedAddress};
        } else {
          debugPrint('Error: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('Error: Failed to fetch data');
        return null;
      }
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }

  void _setupReportsListener(String uid) {
    final reportsRef = FirebaseDatabase.instance.ref('reports');

    _reportsSubscription = reportsRef.onValue.listen((event) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      _processReportsData(event.snapshot, uid);
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _dataFetchError = true;
        });
      }
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _setupReportsListener(uid);
        }
      });
    });
  }

  Future<void> _processReportsData(DataSnapshot snapshot, String uid) async {
    try {
      if (snapshot.exists) {
        final allReports = snapshot.value;
        if (allReports is! Map) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _dataFetchError = false;
              reportsByUser = {};
            });
            _updateReportsCount();
          }
          return;
        }

        Map<String, List<Map<String, dynamic>>> groupedReports = {};
        List<String> placeIdsToFetch = [];

        for (var reportEntry in (allReports).entries) {
          final reportId = reportEntry.key.toString();
          final issueMap = reportEntry.value;

          if (issueMap is! Map) continue;

          for (var issueEntry in (issueMap).entries) {
            final issue = issueEntry.key.toString();
            final userMap = issueEntry.value;

            if (userMap is! Map) continue;

            for (var userEntry in (userMap).entries) {
              final userId = userEntry.key.toString();
              final data = userEntry.value;

              if (userId == uid && data is Map) {
                try {
                  final email = data['email']?.toString() ?? 'unknown';
                  final timestamp = data['timestamp']?.toString();

                  groupedReports.putIfAbsent(email, () => []).add({
                    'issue': issue,
                    'userId': userId,
                    'reportId': reportId,
                    'timestamp': timestamp,
                    'email': email,
                  });

                  if (!_placeDetailsMap.containsKey(reportId)) {
                    placeIdsToFetch.add(reportId);
                  }
                } catch (e) {
                  debugPrint('Error processing report data: $e');
                }
              }
            }
          }
        }

        if (placeIdsToFetch.isNotEmpty) {
          await _fetchMissingPlaceDetails(placeIdsToFetch);
        }

        if (mounted) {
          setState(() {
            reportsByUser = groupedReports;
            _isLoading = false;
            _dataFetchError = false;
          });
          _updateReportsCount();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _dataFetchError = false;
            reportsByUser = {};
          });
          _updateReportsCount();
        }
      }
    } catch (e) {
      debugPrint('Error processing reports: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _dataFetchError = true;
        });
      }
    }
  }

  Future<void> _fetchMissingPlaceDetails(List<String> placeIds) async {
    for (final placeId in placeIds) {
      if (_placeDetailsMap.containsKey(placeId)) continue;

      Map<String, String>? placeDetails = await fetchPlaceDetails(placeId);
      if (placeDetails != null && mounted) {
        setState(() {
          _placeDetailsMap[placeId] = placeDetails;
        });
      }
    }
  }

  void _deletionConfirmation(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Confirm Deletion",
                  style: GoogleFonts.inter(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  )),
              const SizedBox(height: 8),
              Text("Are you sure you want to delete this report?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  )),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        final reportRef = FirebaseDatabase.instance.ref(
                          'reports/${report['reportId']}/${report['issue']}/${report['userId']}',
                        );

                        await reportRef.remove();
                        _updateReportsCount();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Report deleted."),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } catch (e) {
                        debugPrint("Failed to delete report: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Failed to delete report."),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColorDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                      ),
                    ),
                    child: Text(
                      "Delete",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.inter(
                        color: Colors.pinkAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_dataFetchError) {
      return const Text("Error loading reports.");
    }
    if (reportsByUser.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: reportsByUser.values.expand((reports) => reports).map((report) {
        final placeId = report['reportId'];
        final placeDetails = _placeDetailsMap[placeId];
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                placeDetails?['name'] ?? '',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(placeDetails?['address'] ?? '',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
              const SizedBox(height: 10),
              Text(
                "Created on ${DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.fromMillisecondsSinceEpoch(int.parse(report['timestamp'].toString())))}",
                style: GoogleFonts.inter(color: Colors.white, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Icon(
                            accessibilityIssues[report['issue']] ?? Icons.error,
                            color: Colors.white,
                            size: 25,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Accessibility Issue",
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                const SizedBox(height: 0),
                                Text(
                                  report['issue'],
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _deletionConfirmation(report);
                      },
                      icon: const Icon(Icons.delete_forever,
                          color: Colors.white, size: 35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
