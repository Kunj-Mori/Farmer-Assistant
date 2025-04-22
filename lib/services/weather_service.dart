import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  final String apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String citiesKey = 'recent_cities';
  static const int maxRecentCities = 5;

  // Popular cities list
  static const List<Map<String, String>> popularCities = [
    {'name': 'London', 'country': 'UK'},
    {'name': 'New York', 'country': 'US'},
    {'name': 'Tokyo', 'country': 'JP'},
    {'name': 'Paris', 'country': 'FR'},
    {'name': 'Mumbai', 'country': 'IN'},
    {'name': 'Delhi', 'country': 'IN'},
    {'name': 'Bangalore', 'country': 'IN'},
    {'name': 'Chennai', 'country': 'IN'},
    {'name': 'Kolkata', 'country': 'IN'},
    {'name': 'Hyderabad', 'country': 'IN'},
    {'name': 'Dubai', 'country': 'AE'},
    {'name': 'Singapore', 'country': 'SG'},
    {'name': 'Sydney', 'country': 'AU'},
    {'name': 'Moscow', 'country': 'RU'},
    {'name': 'Berlin', 'country': 'DE'},
  ];

  Future<List<String>> getRecentCities() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(citiesKey) ?? [];
  }

  Future<void> addRecentCity(String cityName) async {
    final prefs = await SharedPreferences.getInstance();
    final recentCities = await getRecentCities();
    
    if (!recentCities.contains(cityName)) {
      recentCities.insert(0, cityName);
      if (recentCities.length > maxRecentCities) {
        recentCities.removeLast();
      }
      await prefs.setStringList(citiesKey, recentCities);
    }
  }

  Future<List<Map<String, String>>> searchCities(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$apiKey'
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map<Map<String, String>>((city) {
          return {
            'name': city['name'],
            'country': city['country'],
            'state': city['state'] ?? '',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error searching cities: $e');
      return [];
    }
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, dynamic>> getCurrentWeather(
      {double? latitude, double? longitude}) async {
    try {
      Position? position;
      if (latitude == null || longitude == null) {
        position = await getCurrentLocation();
        latitude = position.latitude;
        longitude = position.longitude;
      }

      final response = await http.get(Uri.parse(
          '$baseUrl/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Error getting weather data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWeatherForecast(
      {double? latitude, double? longitude}) async {
    try {
      Position? position;
      if (latitude == null || longitude == null) {
        position = await getCurrentLocation();
        latitude = position.latitude;
        longitude = position.longitude;
      }

      final response = await http.get(Uri.parse(
          '$baseUrl/forecast?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load forecast data');
      }
    } catch (e) {
      print('Error getting forecast data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWeatherByCity(String cityName) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/weather?q=$cityName&appid=$apiKey&units=metric'));

      if (response.statusCode == 200) {
        await addRecentCity(cityName);
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather data for $cityName');
      }
    } catch (e) {
      print('Error getting weather data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getForecastByCity(String cityName) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/forecast?q=$cityName&appid=$apiKey&units=metric'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load forecast data for $cityName');
      }
    } catch (e) {
      print('Error getting forecast data: $e');
      rethrow;
    }
  }

  Map<String, dynamic> parseWeatherData(Map<String, dynamic> data) {
    return {
      'temperature': data['main']['temp'],
      'humidity': data['main']['humidity'],
      'windSpeed': data['wind']['speed'],
      'description': data['weather'][0]['description'],
      'icon': data['weather'][0]['icon'],
    };
  }

  List<Map<String, dynamic>> parseForecastData(Map<String, dynamic> data) {
    List<dynamic> list = data['list'];
    return list.map<Map<String, dynamic>>((item) {
      return {
        'dateTime': DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000),
        'temperature': item['main']['temp'],
        'humidity': item['main']['humidity'],
        'windSpeed': item['wind']['speed'],
        'description': item['weather'][0]['description'],
        'icon': item['weather'][0]['icon'],
      };
    }).toList();
  }
} 