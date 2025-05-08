import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:inclui/constants.dart';
import 'package:inclui/services/auth_service.dart';
import 'package:inclui/widgets/circle_icon.dart';
import 'package:inclui/widgets/user_preferences_modal.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User? _user;
  late final Stream<User?> _authStateChanges;
  String? _userName;
  String? _createdAt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _authStateChanges = _auth.authStateChanges();

    // listen to auth state changes
    _authStateChanges.listen((user) {
      setState(() {
        _user = user;
        _userName = null;
        _createdAt = null;
        _isLoading = user != null;
      });

      if (user != null) {
        _fetchUserData(user.uid);
      }
    });

    if (_user != null) {
      _fetchUserData(_user!.uid);
    }
  }

  Future<void> _fetchUserData(String uid) async {
    final snapshot = await _db.child('users').child(uid).get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _userName = data['name']?.toString();
        _createdAt = data['createdAt']?.toString();
        _isLoading = false;
      });
    }
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
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print(e.toString());
    }
  }

  String maskEmail(String email) {
    final parts = email.split('@');
    final visible = parts[0].substring(0, 2);
    final masked = '*' * (parts[0].length - 2);
    return '$visible$masked@${parts[1]}';
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
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Still not verified"),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : (_user != null
              ? Column(
                  children: [
                    _buildUserProfile(),
                    if (!_user!.emailVerified) _verifyAccount(),
                    UserPreferencesModal(
                      onPreferencesUpdated: () {
                        setState(() {});
                      },
                    ),
                  ],
                )
              : _buildLoggedOutView()),
    );
  }

  Widget _buildUserProfile() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xffF2F2F2),
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
                    Text(
                      _userName ?? 'Loading...',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                  future: AuthService().getUserPreferences(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
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
                  "No reports yet",
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
              //_startCountdown();
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
    return Center(
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
    );
  }
}

// format the date in DD/MM/YYYY format
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
