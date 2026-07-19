import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> hasInternet() async {
  final result = await Connectivity().checkConnectivity();
  return result.isNotEmpty && !result.contains(ConnectivityResult.none);
}