import 'package:flutter/material.dart';
import 'package:inclui/constants.dart';
import 'package:inclui/services/report_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportCard extends StatefulWidget {
  final String userId;
  final Map<String, List<Map<String, dynamic>>> reportsByUser;
  final Map<String, Map<String, String>> placeDetailsMap;
  final Function()? onReportRemoved;

  const ReportCard({
    required this.userId,
    required this.reportsByUser,
    required this.placeDetailsMap,
    this.onReportRemoved,
    super.key,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  Map<String, List<Map<String, dynamic>>> get reportsByUser =>
      widget.reportsByUser;
  Map<String, Map<String, String>> get _placeDetailsMap =>
      widget.placeDetailsMap;

  @override
  void initState() {
    super.initState();
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

                        setState(() {
                          reportsByUser[report['email']]?.remove(report);
                          if (reportsByUser[report['email']]?.isEmpty ??
                              false) {
                            reportsByUser.remove(report['email']);
                          }
                        });

                        ReportService().notifyReportUpdate();

                        if (widget.onReportRemoved != null) {
                          widget.onReportRemoved!();
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Report deleted."),
                            backgroundColor: Theme.of(context).primaryColor,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } catch (e) {
                        print("Failed to delete report: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
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
                        padding: EdgeInsets.symmetric(horizontal: 15)),
                    child: Text("Delete",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                  const SizedBox(width: 14),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel",
                        style: GoogleFonts.inter(
                            color: Colors.pinkAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 17)),
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
    if (widget.reportsByUser.isEmpty) return Text("No reports found.");

    return Column(
      children: reportsByUser.values.expand((reports) => reports).map((report) {
        final placeId = report['reportId'];
        final placeDetails = _placeDetailsMap[placeId];
        return Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(20, 10, 20, 10),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(placeDetails?['name'] ?? '',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
              SizedBox(height: 4),
              Text(placeDetails?['address'] ?? '',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
              SizedBox(height: 10),
              Text(
                  "Created on ${DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.fromMillisecondsSinceEpoch(int.parse(report['timestamp'].toString())))}",
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 10)),
              SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 10),
                        Icon(accessibilityIssues[report['issue']],
                            color: Colors.white, size: 25),
                        SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Accessibility Issue",
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            SizedBox(height: 0),
                            Text(report['issue'],
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                        onPressed: () {
                          _deletionConfirmation(report);
                        },
                        icon: Icon(Icons.delete_forever,
                            color: Colors.white, size: 35)),
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
