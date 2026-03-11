import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'google_sheets_service.dart';
import 'weather_data_model.dart';
import 'dart:async';
import 'historical_data_screen.dart';
import 'widgets/copyright_footer.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoogleSheetsService _googleSheetsService = GoogleSheetsService();
  WeatherData? _weatherData;
  bool _isFetching = false;
  bool _isInitialLoad = true;
  String? _selectedTimePeriod;
  final List<String> _timePeriods = ['1 day', '7 days', '1 month', '3 months', 'All time'];
  String _currentTime = '';
  String _currentDate = '';
  Timer? _timeTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _updateTime();

    // Updates the digital clock every second
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });

    // Auto-refresh weather data every 20 seconds
    Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (mounted) _fetchData();
    });
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    final dayOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][now.weekday - 1];
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      _currentDate = '${dayOfWeek}, ${now.day}/${now.month}/${now.year}';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_parseErrorMessage(e.toString()))),
      );
    }
  }

  String _parseErrorMessage(String error) {
    if (error.contains('No network')) return 'Out of network coverage';
    if (error.contains('timeout')) return 'Connection timeout';
    return 'Please check your connection or Google Sheet settings';
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
              itemBuilder: (context, index) {
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
    setState(() => _isFetching = true);

    try {
      final allData = await _googleSheetsService.fetchAllData();

      // Convert Map data to WeatherData objects
      List<WeatherData> weatherList = allData.map((row) {
        return WeatherData(
          timestamp: "${row['DATE']} ${row['TIME']}",
          temperature: row['Temp'],
          humidity: row['Hum'],
          gas: row['Gas'],
        );
      }).toList();

      DateTime now = DateTime.now();

      // Filter based on selected time period
      if (timePeriod != 'All time') {
        weatherList = weatherList.where((data) {
          DateTime dataTime = DateTime.parse(data.timestamp);

          if (timePeriod == '1 day') {
            return now.difference(dataTime).inDays <= 1;
          }
          else if (timePeriod == '7 days') {
            return now.difference(dataTime).inDays <= 7;
          }
          else if (timePeriod == '1 month') {
            return now.difference(dataTime).inDays <= 30;
          }
          else if (timePeriod == '3 months') {
            return now.difference(dataTime).inDays <= 90;
          }

          return true;
        }).toList();
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HistoricalDataScreen(
            historicalData: weatherList,
            timePeriod: timePeriod,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching historical data")),
      );
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // REMOVED StreamBuilder. Returning Scaffold directly.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Station Data'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Log out by going back to login screen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginScreen(toggleView: () {})),
              );
            },
          ),
        ],
      ),
      body: _isInitialLoad
          ? const Center(child: SpinKitFadingCircle(color: Colors.blue, size: 50.0))
          : RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'IoT Weather Station',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(_currentTime, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(_currentDate, style: const TextStyle(fontSize: 16)),
                        const Divider(height: 32),
                        _buildDataRow('Temperature', '${_weatherData?.temperature.toStringAsFixed(1) ?? "--"}°C'),
                        const Divider(),
                        _buildDataRow('Humidity', '${_weatherData?.humidity.toStringAsFixed(1) ?? "--"}%'),
                        const Divider(),
                        _buildDataRow('Gas Level', '${_weatherData?.gas.toStringAsFixed(1) ?? "--"} ppm'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showTimePeriodDialog,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('View Historical Data', style: TextStyle(fontSize: 18)),
                  ),
                ),
                if (_isFetching)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: SpinKitFadingCircle(color: Colors.blue, size: 30.0),
                  ),
                const CopyrightFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}