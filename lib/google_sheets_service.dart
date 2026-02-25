// WITH DEFINITE ERROR HANDLING MESSAGES
import 'dart:async';  // Add this import for TimeoutException
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'weather_data_model.dart';

class GoogleSheetsService {
  static const String _apiKey = 'AIzaSyCDoNiNs6iDh-1KERPDtXWagtQ4TRlqHyE';
  static const String _scriptId = '1lbGCOmPlX4HXzNW2WDfocolRO6E28uFGTNeeH_yBIbo';
  static const String _sheetName = 'Sheet1';

  Future<void> _checkNetwork() async {
    try {
      await InternetAddress.lookup('google.com');
    } on SocketException {
      throw 'No network connection';
    }
  }

  Future<Map<String, dynamic>> fetchFirstRow() async {
    await _checkNetwork();

    try {
      final url = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$_scriptId/values/$_sheetName!A2:F?key=$_apiKey',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw 'Server error (${response.statusCode})';
      }

      final data = jsonDecode(response.body);
      final rows = data['values'] as List<dynamic>? ?? [];

      if (rows.isEmpty) throw 'No data available';
      if (rows[0].length < 6) throw 'Incomplete data';

      return {
        'Temp': double.tryParse(rows[0][3].toString()) ?? 0.0,
        'Hum': double.tryParse(rows[0][4].toString()) ?? 0.0,
        'Gas': double.tryParse(rows[0][5].toString()) ?? 0.0,
      };
    } on TimeoutException {
      throw 'Connection timeout';
    } catch (e) {
      throw 'Failed to load current data';
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllData() async {
    await _checkNetwork();

    try {
      final url = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$_scriptId/values/$_sheetName!A2:F?key=$_apiKey',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw 'Server error (${response.statusCode})';
      }

      final data = jsonDecode(response.body);
      final rows = data['values'] as List<dynamic>? ?? [];

      return rows.map((row) {
        return {
          'DATE': row[0]?.toString() ?? '',
          'TIME': row[1]?.toString() ?? '',
          'Temp': double.tryParse(row[3].toString()) ?? 0.0,
          'Hum': double.tryParse(row[4].toString()) ?? 0.0,
          'Gas': double.tryParse(row[5].toString()) ?? 0.0,
        };
      }).toList();
    } on TimeoutException {
      throw 'Connection timeout';
    } catch (e) {
      throw 'Failed to load historical data';
    }
  }

  DateTime? parseDateTime(String dateStr, String timeStr) {
    try {
      final dateParts = dateStr.split('/');
      if (dateParts.length != 3) return null;

      final timeParts = timeStr.split(' ');
      if (timeParts.length != 2) return null;

      final timeValue = timeParts[0];
      final period = timeParts[1].toUpperCase();
      final timeComponents = timeValue.split(':');

      int hour = int.parse(timeComponents[0]);
      final minute = int.parse(timeComponents[1]);
      final second = timeComponents.length > 2 ? int.parse(timeComponents[2]) : 0;

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        hour,
        minute,
        second,
      );
    } catch (e) {
      return null;
    }
  }
}


