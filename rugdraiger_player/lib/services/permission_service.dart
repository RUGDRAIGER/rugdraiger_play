import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

/// Gestión unificada de permisos para escanear y reproducir música en Android.
class PermissionService {
  PermissionService._();

  static final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Comprueba si la app puede acceder a la música del dispositivo.
  static Future<bool> hasMediaAccess() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _audioQuery.permissionsStatus();
    } catch (e) {
      debugPrint('hasMediaAccess error: $e');
      return false;
    }
  }

  /// Solicita permisos de música (y carátulas). Obligatorio para escanear/reproducir.
  static Future<bool> requestMediaAccess() async {
    if (!Platform.isAndroid) return true;

    try {
      // on_audio_query pide READ_MEDIA_AUDIO + READ_MEDIA_IMAGES (API 33+)
      var granted = await _audioQuery.checkAndRequest(retryRequest: true);
      if (granted) return true;

      // Refuerzo con permission_handler
      final results = await [
        Permission.audio,
        Permission.photos,
        Permission.storage,
      ].request();

      if (results[Permission.audio]?.isGranted == true) return true;
      if (results[Permission.storage]?.isGranted == true) return true;

      granted = await _audioQuery.permissionsRequest(retryRequest: true);
      return granted || await _audioQuery.permissionsStatus();
    } catch (e) {
      debugPrint('requestMediaAccess error: $e');
      return false;
    }
  }

  /// Notificaciones (opcional, no bloquea la app).
  static Future<void> requestNotificationsOptional() async {
    if (!Platform.isAndroid) return;
    try {
      await Permission.notification.request();
    } catch (e) {
      debugPrint('notification permission error: $e');
    }
  }

  static Future<bool> isPermanentlyDenied() async {
    if (!Platform.isAndroid) return false;
    final audio = await Permission.audio.status;
    if (audio.isPermanentlyDenied) return true;
    final storage = await Permission.storage.status;
    return storage.isPermanentlyDenied;
  }
}
