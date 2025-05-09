import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:inclui/services/auth_service.dart';
import 'package:inclui/constants.dart';
import 'package:inclui/widgets/circle_icon.dart';

class ReportIssueSection extends StatefulWidget {
  final String placeId;
  final VoidCallback? onReport;

  const ReportIssueSection({
    super.key,
    required this.placeId,
    this.onReport,
  });

  @override
  State<ReportIssueSection> createState() => _ReportIssueSectionState();
}

class _ReportIssueSectionState extends State<ReportIssueSection> {
  String? selectedIssue;

  void _showReportModal() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => ReportIssueModal(placeId: widget.placeId),
    );

    if (result != null) {
      setState(() {
        selectedIssue = result;
      });
      widget.onReport?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showReportModal,
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
    );
  }
}

class ReportIssueModal extends StatefulWidget {
  final String placeId;

  const ReportIssueModal({super.key, required this.placeId});

  @override
  State<ReportIssueModal> createState() => _ReportIssueModalState();
}

class _ReportIssueModalState extends State<ReportIssueModal> {
  String? tempSelected;

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.of(context).size.height * 0.8;

    return SafeArea(
      child: Container(
        height: maxHeight,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 5,
              width: 40,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(
              'Report an Accessibility Issue',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Please select the accessibility issue you noticed in this place. '
                'Don\'t worry, you can leave more than one review.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: accessibilityIssues.length,
                itemBuilder: (context, index) {
                  final issue = accessibilityIssues.keys.toList()[index];
                  final icon = accessibilityIssues[issue];
                  final isSelected = tempSelected == issue;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        tempSelected = issue;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleIcon(
                            icon: icon ?? Icons.warning,
                            size: 50,
                            backgroundColor: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade200,
                            iconColor: isSelected
                                ? Colors.grey.shade200
                                : Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              issue,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.blue.shade700
                                    : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (tempSelected == null) return;

                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  final userId = user.uid;
                  final email = AuthService.getUserEmail();
                  final reportRef = FirebaseDatabase.instance
                      .ref("reports/${widget.placeId}/$tempSelected/$userId");

                  try {
                    final snapshot = await reportRef.get();
                    if (snapshot.exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'You have already reported this issue for this place.',
                            style: GoogleFonts.inter(),
                          ),
                          backgroundColor: Colors.redAccent,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      Navigator.of(context).pop(tempSelected);
                      return;
                    }

                    await reportRef.set({
                      'timestamp': ServerValue.timestamp,
                      'email': email,
                    });

                    Navigator.of(context).pop(tempSelected);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Report submitted successfully.',
                          style: GoogleFonts.inter(),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                    );
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Submit Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
