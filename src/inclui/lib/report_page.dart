import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();

  String? _selectedIssue;

  void _logReport() {
    if (_formKey.currentState!.validate() && _selectedIssue != null) {
      final timestamp = DateTime.now().toString();
      final name = _nameController.text.trim();
      final issue = _selectedIssue!;
      final distance = int.tryParse(_distanceController.text.trim()) ?? 0;

      _database.child('reports').push().set({
        'timestamp': timestamp,
        'name': name,
        'issue': issue,
        'distance': distance,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report added')),
      );

      _formKey.currentState!.reset();
      _nameController.clear();
      _distanceController.clear();
      setState(() => _selectedIssue = null);
    } else if (_selectedIssue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an issue')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrangeAccent,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  'Fill the form below to log a report',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 18, color: Colors.white),
                ),
                SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Place Name',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _distanceController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Distance (km)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Required';
                    final number = int.tryParse(value);
                    if (number == null || number < 0)
                      return 'Enter a valid number';
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Issue:',
                        style: GoogleFonts.inter(color: Colors.white)),
                    ...['wheelchair', 'elevator', 'braille'].map((issue) {
                      return RadioListTile<String>(
                        title: Text(issue, style: GoogleFonts.inter()),
                        value: issue,
                        groupValue: _selectedIssue,
                        onChanged: (value) {
                          setState(() => _selectedIssue = value);
                        },
                        tileColor: Colors.white,
                      );
                    }).toList(),
                  ],
                ),
                SizedBox(height: 20),
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
        ),
      ),
    );
  }
}
