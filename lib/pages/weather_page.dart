import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:weather_app/localizations.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/models/weekly_weather_model.dart';
import 'package:weather_app/services/database_services.dart';
import 'package:weather_app/services/weather_services.dart';
import 'package:weather_app/services/connectivity_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/services/city_suggestion_services.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with TickerProviderStateMixin {
  final _WeatherService = WeatherServices("YOUR API KEY HERE OPENWHEATHER");
  Weather? _weather;
  List<WeeklyWeather> _weeklyWeatherList = [];
  WeeklyWeather? _selectedDayWeather;
  List<String> addedCities = [];
  late PageController _pageController;
  int _currentPage = 0;
  bool isLoading = true;

  late AnimationController _animationController;
  late Animation<Offset> _animationOffset;

  List<WeeklyWeather> weeklyForecast = [];

  @override
  void initState() {
    super.initState();
    loadCities();
    _pageController = PageController(initialPage: 0);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animationOffset = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWeather();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    try {
      final bool baglanabilir =
          await ConnectivityHelper.instance.isConnectionAlive();

      if (!baglanabilir) {
        final cachedWeather = await WeatherDatabase.instance.getStoredWeather();
        if (cachedWeather != null) {
          setState(() {
            _weather = cachedWeather;
            isLoading = false;
          });
        }
        return;
      }

      String cityName = await _WeatherService.getCurrentCity();
      Locale myLocale = Localizations.localeOf(context);

      final currentWeather = await _WeatherService.getWeather(
        cityName,
        myLocale.languageCode,
      );
      await WeatherDatabase.instance.insertWeather(currentWeather);

      final position = await Geolocator.getCurrentPosition();
      final weeklyData = await _WeatherService.getWeeklyWeather(
        position.latitude,
        position.longitude,
        myLocale.languageCode,
      );

      List<WeeklyWeather> weeklyWeatherList =
          weeklyData.map((item) => WeeklyWeather.fromJson(item)).toList();

      setState(() {
        _weather = currentWeather;
        _weeklyWeatherList = weeklyWeatherList;
        _selectedDayWeather =
            weeklyWeatherList.isNotEmpty ? weeklyWeatherList.first : null;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Weather data updated"),
          duration: Duration(seconds: 2),
        ),
      );

      _animationController.forward(from: 0);
    } catch (e) {
      final cachedWeather = await WeatherDatabase.instance.getStoredWeather();
      if (cachedWeather != null) {
        setState(() {
          _weather = cachedWeather;
          isLoading = false;
        });
      }
    }
  }

  Future<void> saveCities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('addedCities', addedCities);
  }

  Future<void> loadCities() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCities = prefs.getStringList('addedCities');
    if (savedCities != null) {
      setState(() {
        addedCities = savedCities;
      });
    }
  }

  Color getCardColor(String description) {
    final condition = description.toLowerCase();
    if (condition.contains('güneş') ||
        condition.contains('clear') ||
        condition.contains('açık')) {
      return Colors.orangeAccent.withOpacity(0.3);
    } else if (condition.contains('bulut') || condition.contains('cloud')) {
      return Colors.blueGrey.withOpacity(0.3);
    } else if (condition.contains('yağmur') || condition.contains('rain')) {
      return Colors.lightBlueAccent.withOpacity(0.3);
    } else if (condition.contains('fırtına') || condition.contains('thunder')) {
      return Colors.deepPurple.withOpacity(0.3);
    } else {
      return Colors.blueAccent.withOpacity(0.13);
    }
  }

  // String getWeatherAnimation(String? description) {
  //   if (description == null) return "assets/sunny.json";
  //   final condition = description.toLowerCase();
  //   if (condition.contains("bulut") || condition.contains("cloud"))
  //     return "assets/cloud.json";
  //   if (condition.contains("yağmur") || condition.contains("rain"))
  //     return "assets/rain.json";
  //   if (condition.contains("fırtına") || condition.contains("thunder"))
  //     return "assets/thunder.json";
  //   if (condition.contains("açık") || condition.contains("clear"))
  //     return "assets/sunny.json";
  //   return "assets/sunny.json";
  // }

  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return "assets/sunny.json";

    switch (mainCondition.toLowerCase()) {
      // Tertemiz güneşli
      case 'clear':
        return 'assets/sunny.json'; // Güneşli

      case 'partly cloudy':
        return 'assets/partly_cloudy.json'; // Parçalı bulutlu

      case 'clouds':
        return 'assets/cloud.json'; // Cloudy

      case 'mist':
        return 'assets/mist.json'; // Misty

      case 'fog':
      case 'haze':
      case 'dust':
      case 'smoke':
      case 'sand':
      case 'ash':
        return 'assets/foggy.json'; // Foggy

      case 'light rain':
      case 'rain':
        return 'assets/rain.json'; // Rainy

      case 'drizzle':
      case 'shower rain':
        return 'assets/storm_shower.json'; // Storm shower

      case 'thunderstorm':
        return 'assets/thunder.json'; // Thunderstorm

      case 'storm':
      case 'squall':
      case 'tornado':
        return 'assets/storm.json'; // Storm

      case 'snow':
        return 'assets/snow.json'; // Snowy

      case 'snow sunny':
        return 'assets/snow_sunny.json'; // Sunny snow

      case 'rain night':
        return 'assets/rainy_night.json'; //Night rain

      default:
        return 'assets/sunny.json'; // Default was sunny animation
    }
  }

  Color getWindColor(double windSpeed) {
    if (windSpeed < 3) return Colors.green;
    if (windSpeed < 8) return Colors.orange;
    return Colors.red;
  }

  Color getHumidityColor(int humidity) {
    if (humidity < 40) return Colors.lightBlue;
    if (humidity < 70) return Colors.blue;
    return Colors.pink;
  }

  String getDayName(DateTime date, BuildContext context) {
    Locale myLocale = Localizations.localeOf(context);
    return DateFormat('EEE', myLocale.toString()).format(date);
  }

  String getFormattedDate(DateTime date, BuildContext context) {
    Locale myLocale = Localizations.localeOf(context);
    return DateFormat('EEEE, dd MMMM yyyy', myLocale.toString()).format(date);
  }

  String normalizeCityName(String city) {
    return city
        .trim()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Future<void> removeCity(String cityName) async {
    setState(() {
      addedCities.remove(cityName);
    });
    await saveCities();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("$cityName şehri silindi")));
  }

  void onCityPageChanged(int index) async {
    setState(() {
      _currentPage = index;
    });

    if (index > 0) {
      final selectedCity = addedCities[index - 1];

      try {
        final position = await _WeatherService.getCityCoordinates(selectedCity);

        final weeklyData = await _WeatherService.getWeeklyWeather(
          position.latitude,
          position.longitude,
          'en',
        );

        final List<WeeklyWeather> fetched =
            weeklyData.map((item) => WeeklyWeather.fromJson(item)).toList();

        setState(() {
          _weeklyWeatherList = fetched;
          _selectedDayWeather = fetched.first;
        });

        await WeatherDatabase.instance.insertWeeklyWeather(
          selectedCity,
          fetched,
        );
      } catch (e) {
        debugPrint("Şehir için haftalik veri alinamadi: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final loadingText =
        locale.languageCode == 'tr' ? 'Şehir yükleniyor...' : 'Loading city...';

    return Scaffold(
      body:
          isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Veriler yükleniyor...'),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchWeather,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          buildSearchBar(),
                          SizedBox(
                            height: 400,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: addedCities.length + 1,
                              // onPageChanged: (index) {
                              //   setState(() {
                              //     _currentPage = index;
                              //   });
                              // },
                              onPageChanged: onCityPageChanged,

                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return buildCurrentWeather(loadingText);
                                } else {
                                  final city = addedCities[index - 1];
                                  return buildCityWeatherCard(city);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          buildPageIndicator(),
                          const SizedBox(height: 20),
                          buildWeeklyWeather(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  // Page indicator (dots) fonksiyonumuz
  // Basically, this is a page indicator (dots)
  Widget buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        addedCities.length + 1,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 12 : 8,
          height: _currentPage == index ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.blueAccent : Colors.grey,
          ),
        ),
      ),
    );
  }

  // Search bar fonksiyonumuz
  //Basically, this is a search bar
  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TypeAheadField<String>(
        //Kullanıcının yazdığına göre öneri alınacak servis
        suggestionsCallback: (pattern) async {
          return await CitySuggestionService.getCitySuggestions(pattern);
        },

        //Arayüzdeki TextFieldi burada inşa ediyoruz
        //We build the TextField here
        builder: (
          context,
          TextEditingController controller,
          FocusNode focusNode,
        ) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'Search city...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
            ),
          );
        },

        //Öneri listesinde şehirleri nasıl gösterileceği
        //How can we show the suggestions in the list
        itemBuilder: (context, String suggestion) {
          return ListTile(title: Text(suggestion));
        },

        //Bir öneri seçildiğinde çalışacak kod
        //What will happen when a suggestion is selected
        onSelected: (String suggestion) async {
          String normalizedCity = normalizeCityName(suggestion);
          try {
            final weather = await _WeatherService.getWeather(
              normalizedCity,
              Localizations.localeOf(context).languageCode,
            );

            if (!addedCities.contains(normalizedCity)) {
              setState(() {
                addedCities.add(normalizedCity);
                _currentPage = addedCities.length;
              });
              await saveCities();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$normalizedCity city added')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$normalizedCity already exists')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid city: "$normalizedCity"')),
            );
          }
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  // Mevcut konum hava durumu widget'ı
  // Current weather widget for the current location
  Widget buildCurrentWeather(String loadingText) {
    final selectedWeather = _selectedDayWeather;
    if (selectedWeather == null) return Text(loadingText);

    String windText = AppLocalizations.wind(context);
    String feelsLikeText = AppLocalizations.feelsLike(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          getFormattedDate(selectedWeather.date, context),
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Text(
          _weather?.cityName ?? loadingText,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Lottie.asset(
          getWeatherAnimation(selectedWeather.main),
          width: 150,
          height: 150,
        ),
        Text(
          "${selectedWeather.temperature.round()}°C",
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Text(
          "$feelsLikeText: ${selectedWeather.feelsLike.round()}°C",
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        buildWeatherDetailsRow(
          selectedWeather.windSpeed,
          selectedWeather.humidity,
        ),
        const SizedBox(height: 8),
        Text(selectedWeather.description, style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  // Şehirden veri çekip gösteren kart
  // Weather card that fetches data from the city
  Widget buildCityWeatherCard(String cityName) {
    return FutureBuilder<Weather>(
      future: _WeatherService.getWeather(
        cityName,
        Localizations.localeOf(context).languageCode,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('Veri bulunamadı'));
        }

        final weather = snapshot.data!;
        String windText = AppLocalizations.wind(context);
        String feelsLikeText = AppLocalizations.feelsLike(context);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cityName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => removeCity(cityName),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Lottie.asset(
              getWeatherAnimation(weather.description),
              width: 150,
              height: 150,
            ),
            Text(
              "${weather.temperature.round()}°C",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(
              "$feelsLikeText: ${weather.feelsLike.round()}°C",
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            buildWeatherDetailsRow(weather.windSpeed, weather.humidity),
            const SizedBox(height: 8),
            Text(weather.description, style: const TextStyle(fontSize: 18)),
          ],
        );
      },
    );
  }

  // Ortak: Rüzgar ve nem bilgilerini gösteren satır
  // Common use: Row showing wind and humidity information
  Widget buildWeatherDetailsRow(double windSpeed, int humidity) {
    String windText = AppLocalizations.wind(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(Icons.air, size: 16, color: getWindColor(windSpeed)),
            const SizedBox(width: 4),
            Text(
              "$windText: $windSpeed m/s",
              style: TextStyle(fontSize: 14, color: getWindColor(windSpeed)),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            Icon(Icons.water_drop, size: 16, color: getHumidityColor(humidity)),
            const SizedBox(width: 4),
            Text(
              "Humidity: $humidity%",
              style: TextStyle(fontSize: 14, color: getHumidityColor(humidity)),
            ),
          ],
        ),
      ],
    );
  }

  // Haftalık hava durumu widget'ı
  // Weekly weather widget
  Widget buildWeeklyWeather() {
    if (_weeklyWeatherList.isEmpty) return const SizedBox();

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _weeklyWeatherList.length,
        itemBuilder: (context, index) {
          final dayWeather = _weeklyWeatherList[index];
          final dayName = getDayName(dayWeather.date, context);
          final dateFormatted = getFormattedDate(dayWeather.date, context);
          String windText = AppLocalizations.wind(context);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayWeather = dayWeather;
              });
            },
            child: SlideTransition(
              position:
                  _animationController.isDismissed
                      ? const AlwaysStoppedAnimation(Offset.zero)
                      : _animationOffset,
              child: Container(
                width: 120,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                decoration: BoxDecoration(
                  color: getCardColor(dayWeather.description),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      dayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateFormatted,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),

                    //
                    Lottie.asset(
                      getWeatherAnimation(dayWeather.main),
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    ),

                    Text(
                      dayWeather.description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "${dayWeather.temperature.round()}°C",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "$windText: ${dayWeather.windSpeed} m/s",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
