import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:practice_widgets/instagram/home_screen.dart';
import 'package:practice_widgets/instagram/main_screen.dart';
import 'package:practice_widgets/instagram/register_screen.dart';
import 'package:provider/provider.dart';
import '../services/facebook_auth_service.dart';
import '../data/providers/auth_provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter username and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _authService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (token != null) {
        // Store token
        await Provider.of<AuthProvider>(context, listen: false).setToken(token);
        
        // Navigate to main screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid username or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
              child: Center(
                  child: Text(
            'English',
            style: TextStyle(color: Colors.white),
          ))),
          Expanded(
              flex: 2,
              child: Center(
                  child: Text(
                '',
                style: TextStyle(color: Colors.white),
              ))),
          Expanded(
              flex: 4,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 50,
                        width: 180,
                        child: Image(
                          image: AssetImage('assets/img/logo.png'),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(11)),
                          fillColor: Colors.grey.shade700,
                          prefixIconColor: Colors.white,
                          filled: true,
                          constraints:
                              BoxConstraints.tightFor(width: 327, height: 50),
                          hintStyle: TextStyle(color: Colors.grey),
                          hintText: 'Username',
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(11)),
                          fillColor: Colors.grey.shade700,
                          prefixIconColor: Colors.white,
                          filled: true,
                          constraints:
                              BoxConstraints.tightFor(width: 327, height: 50),
                          hintStyle: TextStyle(color: Colors.grey),
                          hintText: 'Password',
                        ),
                      ),
                      SizedBox(height: 10),
                      InkWell(
                        onTap: _isLoading ? null : _handleLogin,
                        child: Container(
                          width: 327,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: 327,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFF1877F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: () => _handleFacebookLogin(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.facebookF,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(
                                width: 7,
                              ),
                              Text(
                                'Log in with Facebook',
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: 327,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue, // Màu Google
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(FontAwesomeIcons.google),
                            const SizedBox(width: 7),
                            const Text(
                              'Log in with Google',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),

          Expanded(
              flex: 2,
              child: Center(
                  child: Text(
                '',
                style: TextStyle(color: Colors.white),
              ))),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(color: Colors.white),
                ),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RegisterScreen(),
                      ),
                    );
                  },
                  child: Text(
                    " Sign up",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFacebookLogin(BuildContext context) async {
    final facebookAuth = FacebookAuthService();
    final userData = await facebookAuth.signInWithFacebook();
    
    if (userData != null) {
      print('Logged in user: ${userData['name']}');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to login with Facebook'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
