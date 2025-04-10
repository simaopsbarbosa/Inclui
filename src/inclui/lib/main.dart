import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'package:inclui/report_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF006CFF),
        scaffoldBackgroundColor: Color(0xFF060A21),
        canvasColor: Colors.grey[200],
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: HomeScreen(),
    );
  }
}

Future<Position> _determinePosition() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }
  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }
  return await Geolocator.getCurrentPosition();
}

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return HomePage();
      case 1:
        return SearchPage();
      case 2:
        return ReportPage();
      case 3:
        return ProfilePage();
      default:
        return HomePage();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleAuthButton() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _selectedIndex = 3;
      });
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      if (result == true) {
        setState(() {
          _selectedIndex = 3;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).canvasColor,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.all(5),
              child: Image.asset(
                'assets/logo/inclui-b.png',
                height: 24,
              ),
            ),
            TextButton(
              onPressed: _handleAuthButton,
              child: Text(
                FirebaseAuth.instance.currentUser != null ? 'Profile' : 'Login',
                style: GoogleFonts.inter(
                  color: Theme.of(context).primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          ],
        ),
      ),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.black,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        iconSize: 32,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_rounded),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Position>(
      future: _determinePosition(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.lightGreenAccent,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
                backgroundColor: Colors.black,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          Position userLocation = snapshot.data!;
          return Container(
            color: Colors.lightGreenAccent,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'User Location:',
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    userLocation.toString(),
                    style: GoogleFonts.inter(fontSize: 16),
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            ),
          );
        } else {
          return Center(child: Text('No location data available'));
        }
      },
    );
  }
}

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _filteredReports = [];

  double _maxDistance = 10.0;
  String? _selectedIssueType;
  final List<String> _issueTypes = ['wheelchair', 'elevator', 'braille'];

  @override
  void initState() {
    super.initState();
    _listenForReports();
  }

  void _listenForReports() {
    _database.child('reports').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        List<Map<String, dynamic>> newReports = [];
        data.forEach((key, value) {
          if (value is Map) {
            newReports.add({
              'timestamp': value['timestamp'] ?? '',
              'name': value['name'] ?? 'Unknown Place',
              'issue': value['issue'] ?? 'Unknown Issue',
              'distance':
                  double.tryParse(value['distance']?.toString() ?? '0') ?? 0.0,
            });
          }
        });
        setState(() {
          _reports = newReports.reversed.toList();
          _filteredReports = _reports;
        });
      }
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredReports = _reports.where((report) {
        if (report['distance'] > _maxDistance) {
          return false;
        }

        if (_selectedIssueType != null && _selectedIssueType!.isNotEmpty) {
          if (report['issue'].toString().toLowerCase() !=
              _selectedIssueType!.toLowerCase()) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _maxDistance = 10.0;
      _selectedIssueType = null;
      _filteredReports = _reports;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueAccent,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      backgroundColor: Colors.white,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (BuildContext context,
                              StateSetter modalSetState) {
                            return Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Filters',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Max Distance (km)',
                                    style: GoogleFonts.inter(fontSize: 14),
                                  ),
                                  Slider(
                                    thumbColor: Theme.of(context).primaryColor,
                                    activeColor: Theme.of(context).primaryColor,
                                    inactiveColor: Colors.grey[300],
                                    value: _maxDistance,
                                    min: 0,
                                    max: 1000,
                                    divisions: 20,
                                    label:
                                        '${_maxDistance.toStringAsFixed(0)} km',
                                    onChanged: (value) {
                                      modalSetState(() {
                                        _maxDistance = value;
                                      });
                                      setState(() {});
                                    },
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Issue Type',
                                    style: GoogleFonts.inter(fontSize: 14),
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    child: DropdownButton<String>(
                                      menuWidth:
                                          MediaQuery.of(context).size.width *
                                              0.5,
                                      value: _selectedIssueType,
                                      isExpanded: true,
                                      hint: Text('Select'),
                                      items: _issueTypes.map((String type) {
                                        return DropdownMenuItem<String>(
                                          value: type,
                                          child: Text(type),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        modalSetState(() {
                                          _selectedIssueType = value;
                                        });
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          _applyFilters();
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Theme.of(context).primaryColor,
                                            textStyle: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            foregroundColor: Colors.white),
                                        child: Text("Apply"),
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          _clearFilters();
                                          Navigator.pop(context);
                                        },
                                        icon: Icon(Icons.delete_forever,
                                            color: Colors.red),
                                        label: Text(
                                          'Clear Filters',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 40),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  icon: Icon(
                    Icons.filter_list,
                    color: Colors.white,
                  ),
                  label: Text("Filters"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    textStyle: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: _filteredReports.isEmpty
                  ? Center(
                      child: Text(
                        'No reports found',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = _filteredReports[index];
                        return Card(
                          color: Colors.white,
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: Icon(Icons.report, color: Colors.black),
                            title: Text(
                              report['name'],
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Issue: ${report['issue']}'),
                                Text('Distance: ${report['distance']} km'),
                                Text('Date: ${report['timestamp']}'),
                              ],
                            ),
                          ),
                          subtitle: Text(
                            _reports[index],
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ReportPage extends StatelessWidget {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  void _logReport() {
    final timestamp = DateTime.now().toString();
    _database.child('reports').push().set({'timestamp': timestamp});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepOrangeAccent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Button below adds \nreport into database',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 18),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _logReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                textStyle: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: Text('Add Report'),
            ),
          ],
        ),
      ),
    );
  }
}
