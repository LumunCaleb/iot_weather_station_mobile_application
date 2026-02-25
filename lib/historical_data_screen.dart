import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart'; // Add this import
import 'weather_data_model.dart';

class HistoricalDataScreen extends StatelessWidget {
  final List<WeatherData> historicalData;
  final String timePeriod;

  const HistoricalDataScreen({
    Key? key,
    required this.historicalData,
    required this.timePeriod,
  }) : super(key: key);

  void _copyToClipboard(BuildContext context) {
    final csvData = const ListToCsvConverter().convert([
      ['Timestamp', 'Temperature (°C)', 'Humidity (%)', 'Gas (ppm)'],
      ...historicalData.map((data) => [
        data.timestamp,
        data.temperature.toStringAsFixed(2),
        data.humidity.toStringAsFixed(2),
        data.gas.toStringAsFixed(2),
      ]),
    ]);

    Clipboard.setData(ClipboardData(text: csvData));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV data copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historical Data ($timePeriod)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyToClipboard(context),
            tooltip: 'Copy as CSV',
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Date & Time')),
              DataColumn(label: Text('Temp (°C)'), numeric: true),
              DataColumn(label: Text('Humidity (%)'), numeric: true),
              DataColumn(label: Text('Gas (ppm)'), numeric: true),
            ],
            rows: historicalData.map((data) {
              return DataRow(
                cells: [
                  DataCell(Text(data.timestamp)),
                  DataCell(Text(data.temperature.toStringAsFixed(2))),
                  DataCell(Text(data.humidity.toStringAsFixed(2))),
                  DataCell(Text(data.gas.toStringAsFixed(2))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

