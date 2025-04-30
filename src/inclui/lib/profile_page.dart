import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  late User? _user;
  late final Stream<User?> _authStateChanges;
  String? _userName;
  String? _createdAt;
  bool _isLoading = true;
  int _countdown = 0;
  Timer? _countdownTimer;
  final int timerDuration = 60;

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
        _loadCooldown();
      }
    });

    if (_user != null) {
      _fetchUserData(_user!.uid);
      _loadCooldown();
    }
  }

  Future<void> _loadCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSentTime = prefs.getInt('lastVerificationEmailTime') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    if (lastSentTime > 0) {
      final elapsedSeconds = (currentTime - lastSentTime) ~/ 1000;
      if (elapsedSeconds < timerDuration) {
        setState(() {
          _countdown = timerDuration - elapsedSeconds;
        });
        _startCountdown();
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown <= 0) {
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      // check if user data is available in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? cachedUserName = prefs.getString('userName');
      String? cachedCreatedAt = prefs.getString('createdAt');

      if (cachedUserName != null && cachedCreatedAt != null) {
        setState(() {
          _userName = cachedUserName;
          _createdAt = cachedCreatedAt;
          _isLoading = false;
        });
      } else {
        // fetch from Firebase if not cached
        final snapshot = await _db.child('users').child(uid).get();
        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          setState(() {
            _userName = data['name']?.toString();
            _createdAt = data['createdAt']?.toString();
            _isLoading = false;
          });

          prefs.setString('userName', _userName!);
          prefs.setString('createdAt', _createdAt!);
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _signOut() async {
    await _auth.signOut();

    setState(() {
      _isLoading = false;
      _user = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged out'),
        backgroundColor: Theme.of(context).primaryColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _redirectToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  /* void _setError(String message) {
    setState(() => _errorMessage = message);
  }

  Future<void> _updateEmail(String newEmail, String password) async {
    if (newEmail.isEmpty) {
      return _setError("Please enter a new email.");
    }
    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(newEmail)) {
      return _setError("Please enter a valid email.");
    }
    if (password.isEmpty) {
      return _setError("Please enter your password.");
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        await user.verifyBeforeUpdateEmail(newEmail);
        _verifyAccountAction();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email updated. Please verify.'),
            backgroundColor: Theme.of(context).primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _changeEmail() async {
    String newEmail = '';
    String password = '';

    await showDialog(
      context: context, 
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Color(0xFF0A1128),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Change Email",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                ),
              ),
              TextField(
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                ),
                onChanged: (value) => newEmail = value,
                decoration: InputDecoration(
                  hintText: "Enter new email",
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  )
                ),
              ),
              TextField(
                obscureText: true,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                ),
                onChanged: (value) => password = value,
                decoration: InputDecoration(
                  hintText: "Enter password",
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  )
                ),
              ),
              SizedBox(height: 15),
              Row (
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 13),
                  TextButton(
                    child: Text(
                      'Cancel',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await Future.delayed(Duration(milliseconds: 100));
                      _verifyAccountAction();
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Update',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      _updateEmail(newEmail, password);
                      Navigator.of(context).pop();
                    },
                  ),
                  SizedBox(width: 13),
                ],
              ), 
            ],
          ),
        ),
      )
    );
  }

  void _startCountdown() {
    setState(() {
      _countdown = 90;
    });
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  } */

  Future<void> _sendVerificationEmail() async {
    if (_countdown > 0) return;

    try {
      if (_user != null && !_user!.emailVerified) {
        await _user!.sendEmailVerification();
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('lastVerificationEmailTime', currentTime);

        setState(() => _countdown = timerDuration);
        _startCountdown();

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

  Widget _verifyAccount() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF0A1128),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFF242B41),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: Colors.pinkAccent,
            size: 35,
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your account needs to be verified in order to leave reviews.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
                if (_countdown > 0)
                  Text(
                    'Wait $_countdown seconds to resend',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton(
            onPressed: _countdown > 0 ? null : () => _verifyAccountAction(),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _countdown > 0 ? Colors.grey : Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _countdown > 0 ? 'Wait' : 'Verify Now',
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

  void _verifyAccountAction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email ?? '';
    final maskedEmail = _maskEmail(email);

    // Send email immediately if no countdown is active
    if (_countdown == 0) {
      await _sendVerificationEmail();
    }

    // Create stream controller for real-time countdown updates
    final streamController = StreamController<int>();
    streamController.add(_countdown); // Initial value

    // Timer to update the stream every second
    Timer? updateTimer;
    if (_countdown > 0) {
      updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_countdown > 0) {
          streamController.add(_countdown);
        } else {
          timer.cancel();
          streamController.add(0);
        }
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            // Clean up resources when dialog is closed
            if (didPop) {
              return;
            }
            updateTimer?.cancel();
            streamController.close();
          },
          child: StreamBuilder<int>(
            stream: streamController.stream,
            initialData: _countdown,
            builder: (context, snapshot) {
              final currentCountdown = snapshot.data ?? _countdown;

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Color(0xFF0A1128),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Verification Email",
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "We have sent a verification link to:",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        maskedEmail,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await user.reload();
                          if (user.emailVerified) {
                            Navigator.of(context).pop();
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Verification successful."),
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Still not verified"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text("Verify"),
                      ),
                      SizedBox(height: 20),
                      Column(
                        children: [
                          TextButton(
                            onPressed: currentCountdown > 0
                                ? null
                                : () async {
                                    await _sendVerificationEmail();
                                    updateTimer?.cancel();
                                    streamController.close();
                                    Navigator.of(context).pop();
                                    _verifyAccountAction(); // Reopen dialog
                                  },
                            child: Column(
                              children: [
                                Text(
                                  'Resend verification email',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: currentCountdown > 0
                                        ? Colors.grey
                                        : Theme.of(context).primaryColor,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  currentCountdown > 0
                                      ? 'New email available in $currentCountdown seconds'
                                      : 'Click to resend verification email',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: currentCountdown > 0
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      // Additional cleanup when dialog is dismissed by clicking outside
      updateTimer?.cancel();
      streamController.close();
    });
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return email;
    return '${name.substring(0, 2)}${'*' * (name.length - 2)}@$domain';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : (_user != null
              ? Column(
                  children: [
                    _buildUserProfile(),
                    if (!_user!.emailVerified) _verifyAccount(),
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
        color: Color(0xFF0A1128),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFF242B41),
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
                        color: Colors.white,
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
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 50),
                if (_createdAt != null)
                  Text(
                    formatDate(_createdAt!),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  "No reports yet",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _signOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Logout',
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
              color: Colors.white,
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

bool isEmailVerified() {
  final user = FirebaseAuth.instance.currentUser;
  return user?.emailVerified ?? false;
}
