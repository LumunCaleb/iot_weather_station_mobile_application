import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'widgets/copyright_footer.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback toggleView;
  const LoginScreen({Key? key, required this.toggleView}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';

  // Hard-coded credentials map
  final Map<String, String> _validCredentials = {
    'admin@weather.com': 'admin123',
    'admin': 'admin',
    'Master': '1234',
  };

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      if (_validCredentials.containsKey(username) && _validCredentials[username] == password) {
        // SUCCESS: Navigate to HomeScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // FAILURE: Show error
        setState(() {
          _errorMessage = 'Invalid username or password';
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Station Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wb_sunny_outlined, size: 80, color: Colors.blue),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username or Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => value!.isEmpty ? 'Enter username' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) => value!.isEmpty ? 'Enter password' : null,
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('LOGIN', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
            const CopyrightFooter(),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
//
// class LoginScreen extends StatefulWidget {
//   final VoidCallback toggleView;
//   const LoginScreen({Key? key, required this.toggleView}) : super(key: key);
//
//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//   String _errorMessage = '';
//
//   Future<void> _signInWithEmailAndPassword() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = '';
//       });
//
//       try {
//         // await FirebaseAuth.instance.signInWithEmailAndPassword(
//           email: _emailController.text.trim(),
//           password: _passwordController.text.trim(),
//         );
//       // } on FirebaseAuthException catch (e) {
//         setState(() {
//           _errorMessage = _getErrorMessage(e.code);
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   String _getErrorMessage(String code) {
//     switch (code) {
//       case 'invalid-email':
//         return 'Enter a valid email address';
//       case 'user-disabled':
//         return 'This account has been disabled';
//       case 'user-not-found':
//         return 'No account found for this email';
//       case 'wrong-password':
//         return 'Incorrect password';
//       default:
//         return 'Login failed. Please try again';
//     }
//   }
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sign In'),
//         actions: [
//           TextButton(
//             onPressed: widget.toggleView,
//             child: const Text(
//               'Register',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               TextFormField(
//                 controller: _emailController,
//                 decoration: const InputDecoration(labelText: 'Email'),
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (value) =>
//                 value!.isEmpty ? 'Enter your email' : null,
//               ),
//               TextFormField(
//                 controller: _passwordController,
//                 decoration: const InputDecoration(labelText: 'Password'),
//                 obscureText: true,
//                 validator: (value) =>
//                 value!.isEmpty ? 'Enter your password' : null,
//               ),
//               if (_errorMessage.isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8.0),
//                   child: Text(
//                     _errorMessage,
//                     style: const TextStyle(color: Colors.red),
//                   ),
//                 ),
//               ElevatedButton(
//                 onPressed: _signInWithEmailAndPassword,
//                 child: const Text('Sign In'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

