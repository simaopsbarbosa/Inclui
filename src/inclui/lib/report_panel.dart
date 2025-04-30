import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

class ReportIssueSection extends StatefulWidget {
  final String placeId;

  const ReportIssueSection({
    super.key,
    required this.placeId,
  });

  @override
  ReportIssueSectionState createState() => ReportIssueSectionState();
}

class ReportIssueSectionState extends State<ReportIssueSection> {
  final List<String> issues = [
    'Not wheelchair accessible',
    'Lack of wheelchair ramps',
    'Elevator out of service',
    'No braille option',
    'No non-binary bathroom',
    'Poor signage contrast',
    'Inaccessible restroom facilities',
    'No seating for elderly',
    'Too noisy',
    'Heavy doors',
    'Flashing Lights',
  ];

  String? selectedIssue;

  void _showIssueDialog() async {
    String? tempSelected = selectedIssue;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Container(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Select Issue Found',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Scrollbar(
                  thumbVisibility: true,
                  radius: const Radius.circular(8),
                  thickness: 6,
                  child: SingleChildScrollView(
                    child: Column(
                      children: issues.map((issue) {
                        return RadioListTile<String>(
                          activeColor: Theme.of(context).primaryColor,
                          value: issue,
                          groupValue: tempSelected,
                          title: Text(
                            issue,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              tempSelected = value;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () async {
                      if (tempSelected == null) return;
                      // 1. update local state
                      setState(() => selectedIssue = tempSelected);
                      // 2. push to Firebase
                      final reportsRef =
                          FirebaseDatabase.instance.ref().child('reports');
                      await reportsRef.push().set({
                        'placeId': widget.placeId,
                        'issue': tempSelected,
                        'timestamp': ServerValue.timestamp,
                      });
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Confirm',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _showIssueDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }
}
