import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool _databaseInitialized = false;

/// Inicializa SQLite en Windows, macOS y Linux.
Future<void> initDesktopDatabase() async {
  if (_databaseInitialized) return;
  if (kIsWeb) return;

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _databaseInitialized = true;
  }
}
