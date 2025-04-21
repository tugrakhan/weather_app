import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  static String wind(BuildContext context) {
    return Intl.message(
      'Wind',
      name: 'wind',
      desc: 'Wind direction text',
      locale: Localizations.localeOf(context).toString(),
    );
  }

  static String humidity(BuildContext context) {
    return Intl.message(
      'Humidity',
      name: 'humidity',
      desc: 'Humidity text',
      locale: Localizations.localeOf(context).toString(),
    );
  }

  static String temperature(BuildContext context) {
    return Intl.message(
      'Temperature',
      name: 'temperature',
      desc: 'Temperature text',
      locale: Localizations.localeOf(context).toString(),
    );
  }

  static String feelsLike(BuildContext context) {
    return Intl.message(
      'Feels Like',
      name: 'feelsLike',
      desc: 'Feels Like text',
      locale: Localizations.localeOf(context).toString(),
    );
  }

  static String windSpeed(BuildContext context) {
    return Intl.message(
      'Wind Speed',
      name: 'windSpeed',
      desc: 'Wind Speed text',
      locale: Localizations.localeOf(context).toString(),
    );
  }
}
