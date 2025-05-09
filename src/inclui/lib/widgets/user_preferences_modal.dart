import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inclui/constants.dart';
import 'package:inclui/widgets/circle_icon.dart';
import 'package:inclui/services/auth_service.dart';

class UserPreferencesModal extends StatelessWidget {
  final VoidCallback onPreferencesUpdated;
  const UserPreferencesModal({super.key, required this.onPreferencesUpdated});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<List<String>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          builder: (context) => const AccessibilityPreferencesModal(),
        );

        if (result != null) {
          onPreferencesUpdated();
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select the\naccommodations\nyou need',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SvgPicture.asset(
              'assets/icons/labels.svg',
              semanticsLabel: 'Select Accommodations',
              width: 140,
            ),
          ],
        ),
      ),
    );
  }
}

class AccessibilityPreferencesModal extends StatefulWidget {
  const AccessibilityPreferencesModal({super.key});

  @override
  State<AccessibilityPreferencesModal> createState() =>
      _AccessibilityPreferencesModalState();
}

class _AccessibilityPreferencesModalState
    extends State<AccessibilityPreferencesModal> {
  final Set<String> selectedPreferences = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await AuthService().getUserPreferences();
    setState(() {
      selectedPreferences.addAll(prefs);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.of(context).size.height * 0.8;

    return SafeArea(
      child: Container(
        height: maxHeight,
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: Colors.blue,
                ),
              )
            : Column(
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
                    'Your Accessibility Requirements',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Tap the icons to select the accessibility issues you want to avoid. '
                      'We’ll use these to highlight places that suit you.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
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
                        final isSelected = selectedPreferences.contains(issue);

                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedPreferences.remove(issue);
                              } else {
                                selectedPreferences.add(issue);
                              }
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
                                  icon: icon ?? FontAwesomeIcons.question,
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
                        await AuthService()
                            .saveUserPreferences(selectedPreferences.toList());
                        Navigator.pop(context, selectedPreferences.toList());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Save',
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
