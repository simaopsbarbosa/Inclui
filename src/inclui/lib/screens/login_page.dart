import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  String? _errorMessage;
  bool _isRegistering = false;

  Future<void> _signIn() async {
    try {
      await AuthService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      _showSnackbar('Login successful');
      Navigator.pop(context, true);
    } catch (e) {
      _setError(_formatFirebaseError(e));
    }
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final repeatPassword = _repeatPasswordController.text;
    final name = _nameController.text.trim();

    if (password != repeatPassword) return _setError("Passwords don't match");
    if (name.isEmpty) return _setError("Please enter your name");

    try {
      await AuthService.signUp(email, password, name);
      _showSnackbar('Registration successful');
      Navigator.pop(context, true);
    } catch (e) {
      _setError(_formatFirebaseError(e));
    }
  }

  void _setError(String message) {
    setState(() => _errorMessage = message);
  }

  void _toggleMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _errorMessage = null;
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRegistering = _isRegistering;

    return Scaffold(
      backgroundColor: const Color(0xff060A21),
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          isRegistering ? 'Register' : 'Login',
          style: GoogleFonts.inter(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xff060A21),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        reverse: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: isRegistering ? 40 : 100),
            Image.asset('assets/logo/inclui-w.png', height: 64),
            const SizedBox(height: 100),
            if (isRegistering) ...[
              _buildTextField(controller: _nameController, hint: 'Name'),
              const SizedBox(height: 12),
            ],
            _buildTextField(controller: _emailController, hint: 'Email'),
            const SizedBox(height: 12),
            _buildPasswordField(
                controller: _passwordController, hint: 'Password'),
            if (isRegistering) ...[
              const SizedBox(height: 12),
              _buildPasswordField(
                  controller: _repeatPasswordController,
                  hint: 'Repeat password'),
            ],
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.red),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isRegistering ? _register : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                minimumSize: const Size(120, 40),
              ),
              child: Text(
                isRegistering ? 'Register' : 'Login',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            TextButton(
              onPressed: _toggleMode,
              child: Text.rich(
                TextSpan(
                  text: isRegistering
                      ? 'Already have an account? '
                      : 'Don’t have an account? ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(
                      text: isRegistering ? 'Login' : 'Register',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordField(
      {required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        filled: false,
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade900, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      obscureText: true,
    );
  }
}

String _formatFirebaseError(dynamic e) {
  final match = RegExp(r'\]\s(.+)').firstMatch(e.toString());
  return match != null ? match.group(1)! : 'An unexpected error occurred.';
}
