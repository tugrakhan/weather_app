class Weather {
  final String cityName;
  final double temperature;
  final String description;
  final double feelsLike;
  final double windSpeed;
  final int humidity;
  final String main;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.feelsLike,
    required this.windSpeed,
    required this.humidity,
    required this.main,
  });

  // API'den JSON verisini dönüştürüyoruz
  // We convert the JSON data from the API
  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json["name"],
      temperature: json["main"]["temp"].toDouble(),
      description:
          json["weather"][0]["description"], //Dil desteği olan açıklama
      feelsLike: json["main"]["feels_like"].toDouble(),
      windSpeed: json["wind"]["speed"].toDouble(),
      humidity: json["main"]["humidity"], // Varsayılan değer
      main: json["weather"][0]["main"], // Ana hava durumu durumu
    );
  }

  //fromMap ile veritabanından veriyi alıyoruz
  // We get the data from the database with fromMap
  factory Weather.fromMap(Map<String, dynamic> map) {
    return Weather(
      cityName: map['cityName'] ?? "",
      temperature: map['temperature'] ?? 0.0,
      description: map['description'] ?? "Bilinmiyor",
      feelsLike: map['feelsLike'] ?? 0.0,
      windSpeed: map['windSpeed'] ?? 0.0,
      humidity: map['humidity'] ?? 0,
      main: map['main'] ?? "Bilinmiyor",
    );
  }

  //toMap ile veriyi veritabanına atıyoruz
  // We write the data to the database with toMap
  Map<String, dynamic> toMap() {
    return {
      'cityName': cityName,
      'temperature': temperature,
      'description': description,
      'feelsLike': feelsLike,
      'windSpeed': windSpeed,
    };
  }
}
