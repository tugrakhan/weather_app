import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

class ConnectivityHelper {
  final Connectivity _connectivity = Connectivity();

  // Singleton yapı
  // Use singleton pattern
  ConnectivityHelper._();

  static final ConnectivityHelper instance = ConnectivityHelper._();

  // Bağlantı tipini kontrol et (WiFi / Mobil/ Yok)
  //Check the connection type (WiFi / Mobile / None)
  Future<bool> initConnectivity() async {
    List<ConnectivityResult> result = [ConnectivityResult.none];
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (_) {
      return false;
    }

    return _updateConnectionStatus(result);
  }

  Future<bool> _updateConnectionStatus(List<ConnectivityResult> result) async {
    if (result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile)) {
      return true;
    } else {
      return false;
    }
  }

  // İnternet erişimi aktif mi? (Gerçekten internete çıkabiliyor muyuz?)
  // Is internet access active? (Can we really go out to the internet?)
  Future<bool> isConnectionAlive() async {
    final bool hasInternetConnection = await initConnectivity();
    bool webSite = false;
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('connected');
        webSite = true;
      }
    } on SocketException catch (_) {
      print('not connected');
    }

    return (webSite && hasInternetConnection);
  }
}
