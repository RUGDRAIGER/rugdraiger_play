import 'package:flutter/foundation.dart';

/// Notifica a los widgets de carátula que deben recargar (p. ej. tras búsqueda manual).
class ArtworkRefresh {
  ArtworkRefresh._();

  static final notifier = ValueNotifier<int>(0);

  static void bump() {
    notifier.value++;
  }
}
