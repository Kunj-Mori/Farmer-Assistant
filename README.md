# Farmer Assistant

A comprehensive mobile application designed to assist farmers with real-time weather updates, APMC market prices, and agricultural information.

## Features

### 1. Weather Information
- Real-time weather updates with current conditions
- 7-day weather forecast with detailed information
- Dynamic location-based weather data
- Search functionality for different cities
- Detailed weather metrics including:
  - Temperature
  - Humidity
  - Wind Speed
  - Weather conditions
  - High/Low temperatures

### 2. APMC Price Tracking
- Real-time APMC market prices
- Search functionality for commodities
- Price trends and market analysis
- Offline data support
- Features include:
  - Commodity prices per kg
  - Market location information
  - Price trend indicators
  - Last updated timestamps

### 3. User Authentication
- Secure email and password authentication
- User profile management
- Offline data persistence
- State and district selection

## Technical Features

### 1. Data Management
- Firebase Authentication for user management
- Cloud Firestore for data storage
- Offline persistence enabled
- Real-time data synchronization

### 2. UI/UX Features
- Modern and intuitive interface
- Responsive design
- Pull-to-refresh functionality
- Loading indicators
- Error handling with user feedback
- Dark/Light theme support
- Smooth animations and transitions

### 3. Search Capabilities
- City search for weather information
- Commodity search in APMC prices
- Real-time search results
- Fuzzy search support

## Getting Started

### Prerequisites
- Flutter SDK
- Firebase account
- Android Studio / VS Code
- API keys for:
  - Weather API
  - Data.gov.in API

### Installation

1. Clone the repository
```bash
git clone [repository-url]
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
- Add your `google-services.json` for Android
- Add your `GoogleService-Info.plist` for iOS

4. Set up environment variables
Create a `.env` file in the root directory and add:
```
DATA_GOV_API_KEY=your_api_key_here
WEATHER_API_KEY=your_api_key_here
```

5. Run the application
```bash
flutter run
```

## Architecture

The project follows a service-based architecture with:
- Separate service classes for different functionalities
- Provider for state management
- Repository pattern for data handling
- Clean separation of concerns

## Dependencies

- firebase_core: ^2.x.x
- firebase_auth: ^4.x.x
- cloud_firestore: ^4.x.x
- provider: ^6.x.x
- http: ^1.x.x
- geolocator: ^10.x.x
- flutter_dotenv: ^5.x.x
- intl: ^0.18.x

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details

## Acknowledgments

- Weather data provided by OpenWeatherMap
- APMC price data provided by data.gov.in
- Icons from Material Design
- Flutter and Firebase teams for excellent documentation

## Contact

Your Name - [your-email@example.com]

Project Link: [https://github.com/yourusername/farmer-assistant]
