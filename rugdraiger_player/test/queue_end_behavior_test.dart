import 'package:flutter_test/flutter_test.dart';
import 'package:rugdraiger_player/core/constants/app_constants.dart';

/// Lógica pura para calcular el siguiente índice de cola (paridad con audio_service).
int? nextQueueIndex({
  required int currentIndex,
  required int queueLength,
  required RepeatMode repeatMode,
}) {
  if (queueLength == 0) return null;
  if (repeatMode == RepeatMode.none && currentIndex >= queueLength - 1) {
    return null;
  }
  if (repeatMode == RepeatMode.all) {
    return (currentIndex + 1) % queueLength;
  }
  final next = currentIndex + 1;
  return next >= queueLength ? null : next;
}

void main() {
  test('sin repeat no avanza al terminar la última canción', () {
    expect(
      nextQueueIndex(currentIndex: 4, queueLength: 5, repeatMode: RepeatMode.none),
      isNull,
    );
  });

  test('sin repeat sí avanza en canciones intermedias', () {
    expect(
      nextQueueIndex(currentIndex: 2, queueLength: 5, repeatMode: RepeatMode.none),
      3,
    );
  });

  test('repeat all vuelve al inicio desde la última', () {
    expect(
      nextQueueIndex(currentIndex: 4, queueLength: 5, repeatMode: RepeatMode.all),
      0,
    );
  });

  test('repeat one no usa nextQueueIndex (just_audio maneja loop)', () {
    expect(
      nextQueueIndex(currentIndex: 0, queueLength: 3, repeatMode: RepeatMode.one),
      1,
    );
  });
}
