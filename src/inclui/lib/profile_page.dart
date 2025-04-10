import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
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

  // format the date in DD/MM/YYYY format
  String _formatDate(String isoDate) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : (_user != null ? _buildUserProfile() : _buildLoggedOutView()),
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
          color: Colors.grey[300]!,
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
                Text(
                  _userName ?? 'Loading...',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
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
                SizedBox(height: 50),
                if (_createdAt != null)
                  Text(
                    _formatDate(_createdAt!),
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
