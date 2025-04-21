import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/models/weekly_weather_model.dart';

class WeatherDatabase {
  static final WeatherDatabase instance = WeatherDatabase._init();

  static Database? _database;

  WeatherDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('weather.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE weather (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cityName TEXT NOT NULL,
        temperature REAL NOT NULL,
        description TEXT NOT NULL,
        feelsLike REAL NOT NULL,
        windSpeed REAL NOT NULL
      )
      ''');

    //migration için yeni tablo oluşturuyoruz kullanıcıya uygulaayı sil yükle diyemeyeceğimize göre :D

    await db.execute('''
  CREATE TABLE IF NOT EXISTS weekly_weather (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    city TEXT NOT NULL,
    date TEXT NOT NULL,
    main TEXT NOT NULL,
    temp_min REAL NOT NULL,
    temp_max REAL NOT NULL
  )
''');
  }

  //upgrade function for migration things
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      // Geçici tablo oluşturuyoruz
      //temporary table for migration
      await db.execute('ALTER TABLE weather RENAME TO weather_old');

      // Yeni tabloyu oluşturuyoruz
      //creating new table
      await _createDB(db, newVersion);

      // Eski verileri yeni tabloya aktarıyoruz
      //copying old data to new table
      await db.execute('''
        INSERT INTO weather (cityName, temperature, description, feelsLike, windSpeed)
        SELECT cityName, temperature, description, 0, 0 FROM weather_old
      ''');

      // Eski tabloyu siliyoruz
      //deleting old table
      await db.execute('DROP TABLE weather_old');
    }
  }

  Future<void> insertWeather(Weather weather) async {
    final db = await instance.database;

    // Eğer feelsLike veya windSpeed null ise, default değerler atıyoruz
    // If feelsLike or windSpeed is null, we assign default values
    // final feelsLike = weather.feelsLike.isNaN ? 0.0 : weather.feelsLike;
    // final windSpeed = weather.windSpeed.isNaN ? 0.0 : weather.windSpeed;

    await db.insert(
      'weather',
      weather.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertWeeklyWeather(
    String city,
    List<WeeklyWeather> forecast,
  ) async {
    final db = await instance.database;

    // Önce bu şehre ait eski verileri temizleyelim
    // First, let's clean the old data for this city
    await db.delete('weekly_weather', where: 'city = ?', whereArgs: [city]);

    // Sonra yeni verileri ekleyelim
    // Then let's add the new data
    for (var day in forecast) {
      await db.insert(
        'weekly_weather',
        day.toMap(city),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<Weather?> getStoredWeather() async {
    final db = await instance.database;
    final maps = await db.query('weather', orderBy: 'id DESC', limit: 1);

    if (maps.isNotEmpty) {
      return Weather.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<WeeklyWeather>> getWeeklyWeather(String city) async {
    final db = await instance.database;

    final result = await db.query(
      'weekly_weather',
      where: 'city = ?',
      whereArgs: [city],
      orderBy: 'date ASC',
    );

    return result.map((map) => WeeklyWeather.fromMap(map)).toList();
  }
}
