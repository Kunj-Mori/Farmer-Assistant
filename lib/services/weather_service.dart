import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';

class WeatherService {
  final String _apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  final String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  final String _geoUrl = 'https://api.openweathermap.org/geo/1.0';
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
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('recent_cities') ?? [];
    } catch (e) {
      print('Error getting recent cities: $e');
      return [];
    }
  }

  Future<void> addRecentCity(String cityName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentCities = await getRecentCities();
      
      if (!recentCities.contains(cityName)) {
        recentCities.insert(0, cityName);
        if (recentCities.length > 5) {
          recentCities.removeLast();
        }
        await prefs.setStringList('recent_cities', recentCities);
      }
    } catch (e) {
      print('Error adding recent city: $e');
    }
  }

  Future<List<Map<String, String>>> searchCities(String query) async {
    if (query.length < 3) return [];

    try {
      final response = await http.get(
        Uri.parse('$_geoUrl/direct?q=$query&limit=5&appid=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((city) {
          return {
            'name': city['name'] as String,
            'state': city['state'] as String? ?? '',
            'country': city['country'] as String,
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

  Future<String> getCityFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        return placemarks.first.locality ?? 'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      print('Error getting city name: $e');
      return 'Unknown';
    }
  }

  Future<Map<String, dynamic>> getWeatherByLocation(Position position) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'temperature': data['main']['temp'],
          'description': data['weather'][0]['description'],
          'humidity': data['main']['humidity'],
          'windSpeed': data['wind']['speed'],
          'cityName': data['name'],
        };
      }
      throw Exception('Failed to load weather data');
    } catch (e) {
      print('Error getting weather by location: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWeatherByCity(String cityName) async {
    try {
      // First get city coordinates
      final geoResponse = await http.get(
        Uri.parse('$_geoUrl/direct?q=$cityName&limit=1&appid=$_apiKey'),
      );

      if (geoResponse.statusCode == 200) {
        final List<dynamic> locations = json.decode(geoResponse.body);
        if (locations.isEmpty) throw Exception('City not found');

        final location = locations.first;
        final lat = location['lat'];
        final lon = location['lon'];

        // Then get weather data
        final weatherResponse = await http.get(
          Uri.parse(
            '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
          ),
        );

        if (weatherResponse.statusCode == 200) {
          final data = json.decode(weatherResponse.body);
          return {
            'temperature': data['main']['temp'],
            'description': data['weather'][0]['description'],
            'humidity': data['main']['humidity'],
            'windSpeed': data['wind']['speed'],
            'cityName': data['name'],
          };
        }
      }
      throw Exception('Failed to load weather data');
    } catch (e) {
      print('Error getting weather by city: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getWeatherForecast(String cityName) async {
    try {
      // First get city coordinates
      final geoResponse = await http.get(
        Uri.parse('$_geoUrl/direct?q=$cityName&limit=1&appid=$_apiKey'),
      );

      if (geoResponse.statusCode == 200) {
        final List<dynamic> locations = json.decode(geoResponse.body);
        if (locations.isEmpty) throw Exception('City not found');

        final location = locations.first;
        final lat = location['lat'];
        final lon = location['lon'];

        // Then get forecast data
        final forecastResponse = await http.get(
          Uri.parse(
            '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
          ),
        );

        if (forecastResponse.statusCode == 200) {
          final data = json.decode(forecastResponse.body);
          final List<dynamic> list = data['list'];

          // Group forecasts by day
          final Map<String, Map<String, dynamic>> dailyForecasts = {};

          for (var item in list) {
            final dateTime = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
            final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
            final dateString = date.toIso8601String().split('T')[0];

            if (!dailyForecasts.containsKey(dateString)) {
              dailyForecasts[dateString] = {
                'dateTime': date,
                'temperature': item['main']['temp'],
                'minTemp': item['main']['temp_min'],
                'maxTemp': item['main']['temp_max'],
                'description': item['weather'][0]['description'],
                'humidity': item['main']['humidity'],
                'windSpeed': item['wind']['speed'],
                'hourlyForecasts': [],
              };
            }

            // Add hourly forecast data
            (dailyForecasts[dateString]!['hourlyForecasts'] as List).add({
              'time': dateTime,
              'temperature': item['main']['temp'],
              'description': item['weather'][0]['description'],
              'humidity': item['main']['humidity'],
              'windSpeed': item['wind']['speed'],
            });

            // Update min/max temperatures
            final currentTemp = item['main']['temp'] as double;
            if (currentTemp < dailyForecasts[dateString]!['minTemp']) {
              dailyForecasts[dateString]!['minTemp'] = currentTemp;
            }
            if (currentTemp > dailyForecasts[dateString]!['maxTemp']) {
              dailyForecasts[dateString]!['maxTemp'] = currentTemp;
            }
          }

          return dailyForecasts.values.take(7).toList();
        }
      }
      throw Exception('Failed to load forecast data');
    } catch (e) {
      print('Error getting forecast: $e');
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