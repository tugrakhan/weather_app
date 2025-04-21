class WeeklyWeather {
  final DateTime date;
  final double temperature;
  final String description;
  final String icon;
  final int humidity;
  final double feelsLike;
  final double windSpeed;
  final String main;

  WeeklyWeather({
    required this.date,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.feelsLike,
    required this.windSpeed,
    required this.main,
  });

  //fromJson ile json dan veriyi alıyourz
  // get the data from json with fromJson
  factory WeeklyWeather.fromJson(Map<String, dynamic> json) {
    return WeeklyWeather(
      date: DateTime.parse(json['dt_txt']),
      temperature: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      humidity: json['main']['humidity'],
      feelsLike: json['main']['feels_like'].toDouble(),
      windSpeed: json['wind']['speed'].toDouble(),
      main: json['weather'][0]['main'],
    );
  }

  //toMap ile veritabanına veriyi yazıyoruz
  //we write the data to the database with toMap
  Map<String, dynamic> toMap(String city) {
    return {
      'city': city,
      'date': date.toIso8601String(),
      'main': main,
      'temp_min': temperature, // veya farklı şekilde ayırabilirsin
      'temp_max': temperature,
    };
  }

  //fromMap ile veritabanından veriyi okuyoruz
  //bu verileri kartlarda kullanacağımız için bazı verileri dbde saklama gereği duymadık
  //we read the data from the database with fromMap
  //we didn't feel the need to store some data in the db because we will use this data in the cards
  // DB'de saklanmadı mean didn't store in the DB
  factory WeeklyWeather.fromMap(Map<String, dynamic> map) {
    return WeeklyWeather(
      date: DateTime.parse(map['date']),
      temperature: (map['temp_max'] as num).toDouble(),
      description: '', // DB'de saklanmadı
      icon: '', // DB'de saklanmadı
      humidity: 0, // DB'de saklanmadı
      feelsLike: 0, // DB'de saklanmadı
      windSpeed: 0, // DB'de saklanmadı
      main: map['main'],
    );
  }
}
