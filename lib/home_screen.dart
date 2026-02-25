import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'google_sheets_service.dart';
import 'weather_data_model.dart';
import 'dart:async';
import 'historical_data_screen.dart';
import 'widgets/copyright_footer.dart';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoogleSheetsService _googleSheetsService = GoogleSheetsService();
  final AuthService _auth = AuthService();
  WeatherData? _weatherData;
  bool _isFetching = false;
  bool _isInitialLoad = true;
  String? _selectedTimePeriod;
  final List<String> _timePeriods = ['1 day', '7 days', '1 month'];
  String _currentTime = '';
  String _currentDate = '';
  Timer? _timeTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _updateTime();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
    Timer.periodic(const Duration(seconds: 20), (Timer timer) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final dayOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][now.weekday - 1];
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      _currentDate = '${dayOfWeek[0].toUpperCase()}${dayOfWeek.substring(1).toLowerCase()}, ${now.day}/${now.month}/${now.year}';
    });
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isFetching = true);

    try {
      final data = await _googleSheetsService.fetchFirstRow();
      if (!mounted) return;
      setState(() {
        _weatherData = WeatherData.fromMap(data);
        _isInitialLoad = false;
        _isFetching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFetching = false);

      final errorMessage = _parseErrorMessage(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String _parseErrorMessage(String error) {
    if (error.contains('No network')) return 'Out of network coverage';
    if (error.contains('timeout')) return 'Connection timeout';
    if (error.contains('Server')) return 'Service unavailable';
    if (error.contains('No data')) return 'No data available';
    return 'Please check your connection';
  }

  void _showTimePeriodDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Time Period'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _timePeriods.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(_timePeriods[index]),
                  onTap: () {
                    Navigator.pop(context);
                    _fetchHistoricalData(_timePeriods[index]);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchHistoricalData(String timePeriod) async {
    if (!mounted) return;
    setState(() {
      _isFetching = true;
      _selectedTimePeriod = timePeriod;
    });

    try {
      final now = DateTime.now();
      late DateTime startDate;

      switch (timePeriod) {
        case '1 day':
          startDate = now.subtract(const Duration(days: 1));
          break;
        case '7 days':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case '1 month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        default:
          startDate = now.subtract(const Duration(days: 1));
      }

      final allData = await _googleSheetsService.fetchAllData();
      final filteredData = <WeatherData>[];

      for (final row in allData) {
        try {
          final dateTime = _googleSheetsService.parseDateTime(row['DATE'], row['TIME']);
          if (dateTime != null && dateTime.isAfter(startDate)) {
            filteredData.add(WeatherData(
              temperature: row['Temp'],
              humidity: row['Hum'],
              gas: row['Gas'],
              timestamp: '${row['DATE']} ${row['TIME']}',
            ));
          }
        } catch (e) {
          continue;
        }
      }

      filteredData.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HistoricalDataScreen(
            historicalData: filteredData,
            timePeriod: timePeriod,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final errorMessage = _parseErrorMessage(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;

          if (user == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Weather Station')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Please sign in to view weather data'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      child: const Text('Sign In'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(
                              toggleView: () {},
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Weather Station Data'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await _auth.signOut();
                  },
                ),
              ],
            ),
            body: _isInitialLoad
                ? const Center(
              child: SpinKitFadingCircle(
                color: Colors.blue,
                size: 50.0,
              ),
            )
                : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Welcome, ${user.email?.split('@')[0] ?? 'User'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Column(
                                children: [
                                  Text(
                                    _currentTime,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _currentDate,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                ],
                              ),
                              _buildDataRow('Temperature', '${_weatherData?.temperature.toStringAsFixed(2)}°C'),
                              const Divider(),
                              _buildDataRow('Humidity', '${_weatherData?.humidity.toStringAsFixed(2)}%'),
                              const Divider(),
                              _buildDataRow('Gas Level', '${_weatherData?.gas.toStringAsFixed(2)} ppm'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _showTimePeriodDialog,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'View Historical Data',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (_isFetching)
                            const Padding(
                              padding: EdgeInsets.only(top: 16.0),
                              child: SpinKitFadingCircle(
                                color: Colors.blue,
                                size: 30.0,
                              ),
                            ),
                        ],
                      ),
                      const CopyrightFooter(),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// // WITH ERROR HANDLING THAT MATCHES THE GOOGLE SHEETS SERVICE FILE
// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'google_sheets_service.dart';
// import 'weather_data_model.dart';
// import 'dart:async';
// import 'historical_data_screen.dart';
// import 'widgets/copyright_footer.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({Key? key}) : super(key: key);
//
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   final GoogleSheetsService _googleSheetsService = GoogleSheetsService();
//   WeatherData? _weatherData;
//   bool _isFetching = false;
//   bool _isInitialLoad = true;
//   String? _selectedTimePeriod;
//   final List<String> _timePeriods = ['1 day', '7 days', '1 month'];
//   String _currentTime = '';
//   String _currentDate = '';
//   Timer? _timeTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchData();
//     _updateTime();
//     _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       _updateTime();
//     });
//     Timer.periodic(const Duration(seconds: 20), (Timer timer) {
//       _fetchData();
//     });
//   }
//
//   @override
//   void dispose() {
//     _timeTimer?.cancel();
//     super.dispose();
//   }
//
//   void _updateTime() {
//     final now = DateTime.now();
//     final dayOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][now.weekday - 1];
//     setState(() {
//       _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
//       _currentDate = '${dayOfWeek[0].toUpperCase()}${dayOfWeek.substring(1).toLowerCase()}, ${now.day}/${now.month}/${now.year}';
//     });
//   }
//
//   Future<void> _fetchData() async {
//     if (!mounted) return;
//     setState(() => _isFetching = true);
//
//     try {
//       final data = await _googleSheetsService.fetchFirstRow();
//       if (!mounted) return;
//       setState(() {
//         _weatherData = WeatherData.fromMap(data);
//         _isInitialLoad = false;
//         _isFetching = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _isFetching = false);
//
//       final errorMessage = _parseErrorMessage(e.toString());
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(errorMessage),
//           duration: const Duration(seconds: 5),
//         ),
//       );
//     }
//   }
//
//   String _parseErrorMessage(String error) {
//     if (error.contains('No network')) return 'Out of network coverage';
//     if (error.contains('timeout')) return 'Connection timeout';
//     if (error.contains('Server')) return 'Service unavailable';
//     if (error.contains('No data')) return 'No data available';
//     return 'Please check your connection';
//   }
//
//   void _showTimePeriodDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Select Time Period'),
//           content: SizedBox(
//             width: double.maxFinite,
//             child: ListView.builder(
//               shrinkWrap: true,
//               itemCount: _timePeriods.length,
//               itemBuilder: (BuildContext context, int index) {
//                 return ListTile(
//                   title: Text(_timePeriods[index]),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _fetchHistoricalData(_timePeriods[index]);
//                   },
//                 );
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Future<void> _fetchHistoricalData(String timePeriod) async {
//     if (!mounted) return;
//     setState(() {
//       _isFetching = true;
//       _selectedTimePeriod = timePeriod;
//     });
//
//     try {
//       final now = DateTime.now();
//       late DateTime startDate;
//
//       switch (timePeriod) {
//         case '1 day':
//           startDate = now.subtract(const Duration(days: 1));
//           break;
//         case '7 days':
//           startDate = now.subtract(const Duration(days: 7));
//           break;
//         case '1 month':
//           startDate = DateTime(now.year, now.month - 1, now.day);
//           break;
//         default:
//           startDate = now.subtract(const Duration(days: 1));
//       }
//
//       final allData = await _googleSheetsService.fetchAllData();
//       final filteredData = <WeatherData>[];
//
//       for (final row in allData) {
//         try {
//           final dateTime = _googleSheetsService.parseDateTime(row['DATE'], row['TIME']);
//           if (dateTime != null && dateTime.isAfter(startDate)) {
//             filteredData.add(WeatherData(
//               temperature: row['Temp'],
//               humidity: row['Hum'],
//               gas: row['Gas'],
//               timestamp: '${row['DATE']} ${row['TIME']}',
//             ));
//           }
//         } catch (e) {
//           continue;
//         }
//       }
//
//       filteredData.sort((a, b) => b.timestamp.compareTo(a.timestamp));
//
//       if (!mounted) return;
//       Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (context) => HistoricalDataScreen(
//             historicalData: filteredData,
//             timePeriod: timePeriod,
//           ),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       final errorMessage = _parseErrorMessage(e.toString());
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(errorMessage),
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() => _isFetching = false);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Weather Station Data'),
//         centerTitle: true,
//       ),
//       body: _isInitialLoad
//           ? const Center(
//         child: SpinKitFadingCircle(
//           color: Colors.blue,
//           size: 50.0,
//         ),
//       )
//           : RefreshIndicator(
//         onRefresh: _fetchData,
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 Card(
//                   elevation: 4,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Column(
//                       children: [
//                         Column(
//                           children: [
//                             Text(
//                               _currentTime,
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             Text(
//                               _currentDate,
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.black,
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             const Divider(),
//                           ],
//                         ),
//                         _buildDataRow('Temperature', '${_weatherData?.temperature.toStringAsFixed(2)}°C'),
//                         const Divider(),
//                         _buildDataRow('Humidity', '${_weatherData?.humidity.toStringAsFixed(2)}%'),
//                         const Divider(),
//                         _buildDataRow('Gas Level', '${_weatherData?.gas.toStringAsFixed(2)} ppm'),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Column(
//                   children: [
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _showTimePeriodDialog,
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: const Text(
//                           'View Historical Data',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                     if (_isFetching)
//                       const Padding(
//                         padding: EdgeInsets.only(top: 16.0),
//                         child: SpinKitFadingCircle(
//                           color: Colors.blue,
//                           size: 30.0,
//                         ),
//                       ),
//                   ],
//                 ),
//                 const CopyrightFooter(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDataRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
