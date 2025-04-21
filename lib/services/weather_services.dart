import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/models/weather_model.dart';

class WeatherServices {
  static const BASE_URL = "https://api.openweathermap.org/data/2.5/weather";
  final String apiKey;

  WeatherServices(this.apiKey);

  Future<Weather> getWeather(String cityName, String languageCode) async {
    final Response = await http.get(
      Uri.parse(
        "$BASE_URL?q=$cityName&appid=$apiKey&units=metric&lang=$languageCode",
      ),
    );

    if (Response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(Response.body));
    } else {
      throw Exception("Failed to load weather data");
    }
  }

  // Kullanıcıdan konum tespiti için izin talep ediyoruz
  // Ask for permission to detect the user's location
  Future<String> getCurrentCity() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Konum değişikliği dinleyip, ilk değeri alacağız.
    // We will listen for location changes and get the first value.
    final position =
        await Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.best, // en iyi hassasiyet, best accuracy
            distanceFilter: 0, // her değişikliği bildir, notify on every change
          ),
        ).first; // İlk konum güncellemesini al, get the first location update

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    String? city = placemarks[0].administrativeArea;
    return city ?? "";
  }

  Future<List<Map<String, dynamic>>> getWeeklyWeather(
    double lat,
    double lon,
    String languageCode,
  ) async {
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=$languageCode",
    );

    //print("Haftalık Hava API URL: $url");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> forecastList = data['list'];

      final dailyForecasts = <Map<String, dynamic>>[];
      final seenDates = <String>{};

      for (var item in forecastList) {
        String dateText = item['dt_txt'];
        if (dateText.contains('12:00:00')) {
          // Öğlen verisi
          String date = dateText.split(' ')[0];
          if (!seenDates.contains(date)) {
            seenDates.add(date);
            dailyForecasts.add(item);
          }
        }
      }

      return dailyForecasts;
    } else {
      throw Exception("Failed to load weekly weather data");
    }
  }

  //haftalık karltarımızdaki hava durumunu ana göstergemize göre değiştirmek için
  //konum bilgilerini almak için kullanıyoruz.
  // We use this to get the location information to change the weather in our weekly chart according to our main indicator.
  Future<Position> getCityCoordinates(String cityName) async {
    List<Location> locations = await locationFromAddress(cityName);
    final loc = locations.first;
    return Position(
      latitude: loc.latitude,
      longitude: loc.longitude,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      headingAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      isMocked: false,
    );
  }
}
