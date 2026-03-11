import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() async { // <--- Added 'async' here
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env"); // Now 'await' will work

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Weather Station',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Optional: gives it a more modern look
      ),
      // The app now starts directly at the Login Screen
      home: LoginScreen(
        toggleView: () {
          // You can leave this empty since we aren't using Registration for now
        },
      ),
    );
  }
}