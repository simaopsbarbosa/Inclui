import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:inclui/profile_page.dart';

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

                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      final userId = user.uid;
                      final email = getUserEmail();
                      final reportRef = FirebaseDatabase.instance.ref(
                          "reports/${widget.placeId}/$tempSelected/$userId");

                      try {
                        final snapshot = await reportRef.get();
                        if (snapshot.exists) {
                          // Duplicate found
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'You have already reported this issue for this place.',
                                style: GoogleFonts.inter(),
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        // Not yet reported — push it
                        await reportRef.set({
                          'timestamp': ServerValue.timestamp,
                          'email': email,
                        });

                        setState(() => selectedIssue = tempSelected);
                        Navigator.of(context).pop();
                      } on FirebaseException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to send report: ${e.message}',
                              style: GoogleFonts.inter(),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
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
