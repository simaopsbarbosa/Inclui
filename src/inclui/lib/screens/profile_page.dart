import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:inclui/constants.dart';
import 'package:inclui/services/auth_service.dart';
import 'package:inclui/services/report_service.dart';
import 'package:inclui/widgets/circle_icon.dart';
import 'package:inclui/widgets/user_preferences_modal.dart';
import 'package:inclui/widgets/report_history_card.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  StreamSubscription<User?>? _authSubscription;
  String? _userName;
  String? _createdAt;
  bool _isLoading = true;
  bool _dataFetchError = false;
  Map<String, List<Map<String, dynamic>>> _reportsByUser = {};
  Map<String, Map<String, String>> _placeDetailsMap = {};
  bool _isLoadingReports = false;
  bool _reportsDataFetchError = false;
  StreamSubscription? _reportSubscription;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _setupAuthListener();

    _reportSubscription = ReportService().onReportUpdate.listen((_) {
      if (_user != null && mounted) {
        _fetchUserReports(_user!.uid);
      }
    });

    if (_user != null) {
      _fetchUserData(_user!.uid);
      _fetchUserReports(_user!.uid);
    } else {
      _isLoading = false;
    }
  }

  void _setupAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((user) async {
      if (user != null && (user.uid != _user?.uid)) {
        if (mounted) {
          setState(() {
            _user = user;
            _userName = null;
            _createdAt = null;
            _isLoading = true;
            _dataFetchError = false;
          });
        }
        await _fetchUserData(user.uid);
      } else if (user == null) {
        if (mounted) {
          setState(() {
            _user = null;
            _userName = null;
            _createdAt = null;
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final snapshot = await _db
          .child('users')
          .child(uid)
          .get()
          .timeout(Duration(seconds: 5));

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        if (mounted) {
          setState(() {
            _userName = data['name']?.toString();
            _createdAt = data['createdAt']?.toString();
            _isLoading = false;
            _dataFetchError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        await Future.delayed(Duration(seconds: 1));
        if (mounted && _user != null) {
          _fetchUserData(_user!.uid);
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _dataFetchError = true;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _dataFetchError = true;
        });
      }
      await Future.delayed(Duration(seconds: 2));
      if (mounted && _user != null) {
        _fetchUserData(_user!.uid);
      }
    }
  }

  Future<Map<String, String>?> _fetchPlaceDetails(String placeId) async {
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

  Future<void> _fetchUserReports(String uid) async {
    if (mounted) {
      setState(() {
        _isLoadingReports = true;
        _reportsDataFetchError = false;
      });
    }

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('reports')
          .get()
          .timeout(const Duration(seconds: 5));

      if (snapshot.exists) {
        final allReports = snapshot.value;
        if (allReports is! Map) {
          if (mounted) {
            setState(() {
              _isLoadingReports = false;
              _reportsDataFetchError = false;
              _reportsByUser = {};
            });
          }
          return;
        }

        Map<String, List<Map<String, dynamic>>> groupedReports = {};

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
                    Map<String, String>? placeDetails =
                        await _fetchPlaceDetails(reportId);
                    if (placeDetails != null && mounted) {
                      setState(() {
                        _placeDetailsMap[reportId] = placeDetails;
                      });
                    }
                  }
                } catch (e) {
                  debugPrint('Error processing report data: $e');
                }
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _reportsByUser = groupedReports;
            _isLoadingReports = false;
            _reportsDataFetchError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingReports = false;
            _reportsDataFetchError = false;
            _reportsByUser = {};
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isLoadingReports = false;
          _reportsDataFetchError = true;
        });
      }
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _fetchUserReports(uid);
      }
    } catch (e) {
      debugPrint('Error fetching reports: $e');
      if (mounted) {
        setState(() {
          _isLoadingReports = false;
          _reportsDataFetchError = true;
        });
      }
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _fetchUserReports(uid);
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _reportSubscription?.cancel();
    super.dispose();
  }

  void _redirectToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _sendVerificationEmail() async {
    try {
      if (_user != null && !_user!.emailVerified) {
        await _user!.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification email sent.'),
            backgroundColor: Theme.of(context).primaryColor,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void _verifyAccountAction() async {
    final user = AuthService.currentUser;
    final email = user?.email ?? '';
    final maskedEmail = maskEmail(email);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.grey.shade300,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Verification Email",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                "We have sent a verification link to:",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),
              Text(
                maskedEmail,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await _user?.reload();
                  var updatedUser = AuthService.currentUser;
                  if (updatedUser?.emailVerified == true) {
                    setState(() {
                      _user = updatedUser;
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Verification successful."),
                        backgroundColor: Theme.of(context).primaryColor,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Still not verified"),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Verify',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 0),
              TextButton(
                onPressed: _sendVerificationEmail,
                child: Text(
                  'Did not receive an email? Resend',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getReportCountText() {
    int totalReports = 0;

    for (var reports in _reportsByUser.values) {
      totalReports += reports.length;
    }

    if (totalReports == 0) {
      return "No reports yet";
    } else if (totalReports == 1) {
      return "1 report";
    } else {
      return "$totalReports reports";
    }
  }

  Widget _buildUserReports() {
    if (_user == null) return SizedBox();

    if (_isLoadingReports) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    if (_reportsDataFetchError) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            Text(
              "Failed to load reports",
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton(
              onPressed: () {
                if (_user != null) {
                  _fetchUserReports(_user!.uid);
                }
              },
              child: Text("Retry"),
            )
          ],
        ),
      );
    }

    return ReportCard(
      userId: _user!.uid,
      reportsByUser: _reportsByUser,
      placeDetailsMap: _placeDetailsMap,
      onReportRemoved: () {
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      backgroundColor: Colors.transparent,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Setting up your profile...",
                      style: GoogleFonts.inter(),
                    ),
                  ],
                ),
              )
            : _dataFetchError
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text(
                          "Failed to load profile data",
                          style: GoogleFonts.inter(),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (_user != null) {
                              setState(() {
                                _isLoading = true;
                                _dataFetchError = false;
                              });
                              _fetchUserData(_user!.uid);
                            }
                          },
                          child: Text("Retry"),
                        ),
                      ],
                    ),
                  )
                : (_user != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUserProfile(),
                          if (!_user!.emailVerified) _verifyAccount(),
                          UserPreferencesModal(
                            onPreferencesUpdated: () {
                              setState(() {});
                            },
                          ),
                          if (_reportsByUser.values.fold<int>(
                                  0, (sum, list) => sum + list.length) >
                              0)
                            Padding(
                              padding: const EdgeInsets.only(left: 30.0),
                              child: Text(
                                "Previous Reports",
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          SizedBox(height: 10),
                          _buildUserReports(),
                          SizedBox(height: 10),
                        ],
                      )
                    : _buildLoggedOutView()),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
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
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _userName ?? 'Loading...',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_user != null && _user?.emailVerified == true) ...[
                      SizedBox(width: 5),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Icon(
                          Icons.verified,
                          color: Theme.of(context).primaryColor,
                          size: 18.5,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _user?.email ?? 'No email',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 15),
                FutureBuilder<List<String>>(
                  future: AuthService.getUserPreferences(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(25.0),
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            color: Colors.blue,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox(
                        height: 5,
                      );
                    }

                    final selectedIssues = snapshot.data!;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: selectedIssues.map((issue) {
                          final icon = accessibilityIssues[issue] ??
                              FontAwesomeIcons.question;
                          return Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: CircleIcon(
                              icon: icon,
                              size: 55,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 15),
                if (_createdAt != null)
                  Text(
                    formatDate(_createdAt!),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  _getReportCountText(),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifyAccount() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: Colors.pinkAccent,
            size: 25,
          ),
          SizedBox(width: 13),
          Expanded(
            child: Text(
              'Your account needs to be verified in order to leave reviews.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              _sendVerificationEmail();
              _verifyAccountAction();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 15)),
            child: Text(
              'Verify Now',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedOutView() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'You are not logged in. \nLog in to access exclusive features.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _redirectToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Login',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String maskEmail(String email) {
  final parts = email.split('@');
  final visible = parts[0].substring(0, 2);
  final masked = '*' * (parts[0].length - 2);
  return '$visible$masked@${parts[1]}';
}

String formatDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate).toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return "Joined $day/$month/$year";
  } catch (e) {
    return '';
  }
}
