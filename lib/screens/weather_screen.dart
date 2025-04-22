import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import 'dart:async';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = true;
  bool _showForecast = false;
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>>? _forecast;
  List<Map<String, String>> _searchResults = [];
  List<String> _recentCities = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadRecentCities();
    await _loadWeatherData();
  }

  Future<void> _loadRecentCities() async {
    final recentCities = await _weatherService.getRecentCities();
    setState(() => _recentCities = recentCities);
  }

  Future<void> _loadWeatherData() async {
    setState(() => _isLoading = true);
    try {
      final currentWeatherData = await _weatherService.getCurrentWeather();
      final forecastData = await _weatherService.getWeatherForecast();
      
      setState(() {
        _currentWeather = _weatherService.parseWeatherData(currentWeatherData);
        _forecast = _weatherService.parseForecastData(forecastData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading weather data: $e');
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        return;
      }

      setState(() => _isSearching = true);
      try {
        final results = await _weatherService.searchCities(query);
        setState(() => _searchResults = results);
      } catch (e) {
        _showError('Error searching cities: $e');
      } finally {
        setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _selectCity(String cityName) async {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isLoading = true;
    });

    try {
      final currentWeatherData = await _weatherService.getWeatherByCity(cityName);
      final forecastData = await _weatherService.getForecastByCity(cityName);
      
      setState(() {
        _currentWeather = _weatherService.parseWeatherData(currentWeatherData);
        _forecast = _weatherService.parseForecastData(forecastData);
        _isLoading = false;
      });
      
      await _loadRecentCities();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading weather data for $cityName: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search city...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _isSearching = false;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          )
        else if (_searchResults.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final city = _searchResults[index];
                return ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text(city['name']!),
                  subtitle: Text('${city['state']}, ${city['country']}'),
                  onTap: () => _selectCity(city['name']!),
                );
              },
            ),
          )
        else if (_recentCities.isNotEmpty)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Recent Cities',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _recentCities.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(_recentCities[index]),
                        onTap: () => _selectCity(_recentCities[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentWeather() {
    if (_currentWeather == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '${_currentWeather!['temperature'].toStringAsFixed(1)}°C',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _currentWeather!['description'].toString().toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherInfo(
                  Icons.water_drop,
                  'Humidity',
                  '${_currentWeather!['humidity']}%',
                ),
                _buildWeatherInfo(
                  Icons.air,
                  'Wind Speed',
                  '${_currentWeather!['windSpeed']} m/s',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecast() {
    if (_forecast == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '7-Day Forecast',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _forecast!.length,
              itemBuilder: (context, index) {
                final day = _forecast![index];
                return SizedBox(
                  width: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day['temperature'].toStringAsFixed(1)}°C',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        _getWeatherIcon(day['description']),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(day['dateTime']),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  IconData _getWeatherIcon(String description) {
    if (description.contains('rain')) return Icons.water_drop;
    if (description.contains('cloud')) return Icons.cloud;
    if (description.contains('clear')) return Icons.wb_sunny;
    return Icons.cloud;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day) return 'Today';
    if (date.day == now.day + 1) return 'Tomorrow';
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    if (_searchResults.isNotEmpty || _isSearching) {
      return Scaffold(
        body: _buildSearchBar(),
      );
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWeatherData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildSearchBar(),
                    _buildCurrentWeather(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showForecast ? 'Current Weather' : '7-Day Forecast',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Switch(
                          value: _showForecast,
                          onChanged: (value) {
                            setState(() => _showForecast = value);
                          },
                        ),
                      ],
                    ),
                    if (_showForecast) _buildForecast(),
                  ],
                ),
              ),
            ),
    );
  }
} 