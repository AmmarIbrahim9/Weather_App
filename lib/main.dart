import 'dart:async';
import 'package:flutter/material.dart';
import 'package:weather_app/weather_api.dart'; // Assuming this is where API services are defined
import 'package:weather_app/weather_model.dart'; // Assuming this is where Weather model is defined

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto', // Use Roboto font for a modern look
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with SingleTickerProviderStateMixin {
  WeatherApiService _apiService = WeatherApiService(); // Your Weather API service
  Weather? _weather;
  TextEditingController _cityController = TextEditingController();
  List<String> _suggestions = [];
  Timer? _debounce;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  // Static list of cities (you can expand this list as needed)
  final List<String> _cityList = [
    'New York',
    'Los Angeles',
    'Chicago',
    'Houston',
    'Phoenix',
    'Philadelphia',
    'San Antonio',
    'San Diego',
    'Dallas',
    'San Jose',
    'Austin',
    'Jacksonville',
    'San Francisco',
    'Indianapolis',
    'Columbus',
    'Fort Worth',
    'Charlotte',
    'Seattle',
    'Denver',
    'Washington',
    'Boston',
    'El Paso',
    'Nashville',
    'Portland',
    'Las Vegas',
    // Add more cities here
  ];

  @override
  void initState() {
    super.initState();
    _cityController.addListener(_onCitySearchChanged);

    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onCitySearchChanged() {
    final minCharsForSuggestions = 2; // Changed to 2 characters

    if (_cityController.text.length >= minCharsForSuggestions) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _loadSuggestions();
      });
    } else {
      setState(() {
        _suggestions = [];
      });
    }
  }

  void _loadSuggestions() {
    setState(() {
      _isLoading = true;
    });

    // Filter city list based on input
    String inputText = _cityController.text.trim().toLowerCase();
    List<String> filteredCities = _cityList.where((city) =>
        city.toLowerCase().startsWith(inputText)).toList();

    setState(() {
      _suggestions = filteredCities;
      _isLoading = false;
    });
  }

  void fetchWeatherData(String cityName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      Weather weather = await _apiService.fetchWeather(cityName);
      setState(() {
        _weather = weather;
        _cityController.text = cityName; // Update text field with selected city
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching weather data: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to fetch weather data'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildWeatherIcon() {
    if (_weather == null) {
      return SizedBox.shrink();
    }

    IconData weatherIcon = Icons.wb_sunny; // Default icon

    if (_weather!.description.toLowerCase().contains('rain')) {
      weatherIcon = Icons.beach_access; // Change to rain icon
    } else if (_weather!.description.toLowerCase().contains('cloud')) {
      weatherIcon = Icons.cloud; // Change to cloud icon
    }

    return Container(
      padding: EdgeInsets.all(16.0),
      child: Icon(
        weatherIcon,
        size: 100,
        color: Colors.orange,
      ),
    );
  }

  BoxDecoration _getBackgroundDecoration() {
    if (_weather == null) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.lightBlue],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    }

    Color startColor = Colors.blue;
    Color endColor = Colors.lightBlue;

    if (_weather!.temperature < 10) {
      startColor = Colors.lightBlue;
      endColor = Colors.blue;
    } else if (_weather!.temperature > 30) {
      startColor = Colors.orange;
      endColor = Colors.red;
    }

    return BoxDecoration(
      gradient: LinearGradient(
        colors: [startColor, endColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
      ),
      body: Container(
        decoration: _getBackgroundDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'Enter city name',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () => fetchWeatherData(_cityController.text),
                    ),
                  ),
                  onChanged: (value) => _onCitySearchChanged(),
                ),
                SizedBox(height: 20),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _suggestions.isEmpty
                    ? SizedBox.shrink()
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _suggestions
                      .map((suggestion) => ListTile(
                    title: Text(suggestion),
                    onTap: () => fetchWeatherData(suggestion),
                  ))
                      .toList(),
                ),
                SizedBox(height: 20),
                if (_weather != null)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _buildWeatherIcon(),
                            SizedBox(height: 10),
                            Text(
                              _weather!.cityName,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),
                            Text(
                              '${_weather!.temperature.toStringAsFixed(1)} °C',
                              style: TextStyle(fontSize: 24),
                            ),
                            SizedBox(height: 10),
                            Text(
                              _weather!.description,
                              style: TextStyle(fontSize: 20),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
