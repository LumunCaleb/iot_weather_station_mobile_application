class WeatherData {
  final double temperature;
  final double humidity;
  final double gas;
  final String timestamp;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.gas,
    required this.timestamp,
  });

  factory WeatherData.fromMap(Map<String, dynamic> map) {
    return WeatherData(
      temperature: map['Temp'],
      humidity: map['Hum'],
      gas: map['Gas'],
      timestamp: map['Timestamp'] ?? '',
    );
  }
}

// class WeatherData {
//   final double temperature;
//   final double humidity;
//   final double gas;
//
//   WeatherData({required this.temperature, required this.humidity, required this.gas});
//
//   factory WeatherData.fromMap(Map<String, dynamic> map) {
//     return WeatherData(
//       temperature: map['Temp'],  // Matches 'Temp' from fetchFirstRow
//       humidity: map['Hum'],      // Matches 'Hum' from fetchFirstRow
//       gas: map['Gas'],           // Matches 'Gas' from fetchFirstRow
//     );
//   }
// }