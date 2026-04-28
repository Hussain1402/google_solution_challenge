import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    await _remoteConfig.setDefaults({
      'admin_private_key': 'xyz',
    });
    
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // Offline or fetch failed, fallback to defaults
    }
  }

  String get adminPrivateKey => _remoteConfig.getString('admin_private_key');
}
