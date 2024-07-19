import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weather_app/weather_model.dart';

class WeatherApiService {
  static const String apiKey = 'c98eb50389c22cd88756d85efb8b4df1'; // Replace with your OpenWeatherMap API key
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<Weather> fetchWeather(String cityName) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/weather?q=$cityName&appid=$apiKey&units=metric'));

      if (response.statusCode == 200) {
        return Weather.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load weather data: $e');
    }
  }

  Future<List<String>> fetchCities(String query) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/find?q=${Uri.encodeQueryComponent(query)}&type=like&sort=population&cnt=10&appid=$apiKey'));

      if (response.statusCode == 200) {
        List<dynamic> cities = jsonDecode(response.body)['list'];
        List<String> cityNames = cities.map((city) => city['name'].toString()).toList();
        return cityNames;
      } else {
        throw Exception('Failed to load cities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load cities: $e');
    }
  }
}
