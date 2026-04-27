import 'package:firebase_messaging/firebase_messaging.dart';
import 'firestore_service.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> init(String uid) async {
    // 1. Request permission (iOS mostly, but good practice)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // 2. Get the token
      String? token = await _messaging.getToken();
      if (token != null) {
        // 3. Save to user profile
        await _firestoreService.updateFcmToken(uid, token);
      }

      // 4. Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        _firestoreService.updateFcmToken(uid, newToken);
      });
    }
  }
}
