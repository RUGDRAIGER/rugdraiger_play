import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// ── Custom fader thumb — idéntico al thumb de la web ─────────────────────────
//
// Web CSS del thumb:
//   width: 10px (visual), height: 28px (visual)
//   background: linear-gradient(to bottom,
//     #FF4444 0%, #FF2020 35%,
//     rgba(255,255,255,0.22) 48%, rgba(255,255,255,0.22) 52%,
//     #FF2020 65%, #CC1010 100%)
//   box-shadow: 0 2px 6px rgba(0,0,0,0.6), 0 0 10px rgba(255,32,32,0.5)
//   border: 1px solid rgba(255,60,60,0.7)
//   border-radius: 5px

class _FaderThumbShape extends SliderComponentShape {
  final bool isEqBand;
  const _FaderThumbShape({this.isEqBand = false});

  static const double _thumbW = 10.0; // visual width
  static const double _thumbH = 28.0; // visual height

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    // Para el EQ el slider está girado 270°, así que intercambiamos dimensiones
    // para que visualmente queden correctas tras la rotación.
    return isEqBand
        ? const Size(_thumbH, _thumbW) // pre-rotación: 28 (largo track) × 10 (alto)
        : const Size(_thumbW, _thumbH); // volumen horizontal: 10 × 28
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final enabled = enableAnimation.value > 0.5;

    // En pre-rotación, para el EQ: thumb es 28 × 10 (queda 10 × 28 tras girar)
    // Para volumen: thumb es 10 × 28
    final w = isEqBand ? _thumbH : _thumbW;
    final h = isEqBand ? _thumbW : _thumbH;

    final rect = Rect.fromCenter(center: center, width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(5));

    // 1. Sombra suave
    canvas.drawRRect(
      rrect.shift(const Offset(0, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // 2. Halo rojo (glow)
    if (enabled) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(0x66FF2020)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // 3. Cuerpo con gradiente
    final gradColors = enabled
        ? const <Color>[
            Color(0xFFFF4444),
            Color(0xFFFF2020),
            Color(0x38FFFFFF),
            Color(0x38FFFFFF),
            Color(0xFFFF2020),
            Color(0xFFCC1010),
          ]
        : const <Color>[
            Color(0xFF555555),
            Color(0xFF444444),
            Color(0x38FFFFFF),
            Color(0x38FFFFFF),
            Color(0xFF444444),
            Color(0xFF333333),
          ];

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          gradColors,
          const [0.0, 0.35, 0.48, 0.52, 0.65, 1.0],
        ),
    );

    // 4. Borde
    canvas.drawRRect(
      rrect,
      Paint()
        ..color =
            enabled ? const Color(0xB3FF3C3C) : const Color(0x80888888)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }
}

// ── VolumeFader horizontal ─────────────────────────────────────────────────────
//
// Idéntico al VolumeFader de la web:
//   - Rail oscuro 5px de alto
//   - Fill rojo (rgba 0.40) proporcional al nivel
//   - Thumb: fader de mezcla rojo con gradiente

class VolumeFader extends StatelessWidget {
  final double volume;
  final bool isMuted;
  final ValueChanged<double> onVolumeChange;
  final VoidCallback onToggleMute;
  final double width;
  final bool showIcon;

  const VolumeFader({
    super.key,
    required this.volume,
    required this.isMuted,
    required this.onVolumeChange,
    required this.onToggleMute,
    this.width = 120,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final level = isMuted ? 0.0 : volume;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon)
          GestureDetector(
            onTap: onToggleMute,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                isMuted || volume == 0
                    ? Icons.volume_off_rounded
                    : volume < 0.5
                        ? Icons.volume_down_rounded
                        : Icons.volume_up_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
        SizedBox(
          width: width,
          height: 28,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Rail oscuro
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: AppColors.surface3),
                    ),
                  ),
                ),
              ),
              // Fill rojo
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: width * level.clamp(0.0, 1.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0x66FF2020),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              // Slider invisible con thumb personalizado
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 28,
                  thumbShape: const _FaderThumbShape(),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  disabledThumbColor: AppColors.textTertiary,
                ),
                child: Slider(
                  value: level.clamp(0.0, 1.0),
                  onChanged: onVolumeChange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── EqBandFader vertical ───────────────────────────────────────────────────────
//
// Réplica del eq-band de la web:
//   - Track: rgba(255,32,32,0.20), border rgba(255,32,32,0.12)
//   - Fill rojo desde el centro hasta el valor
//   - Thumb: mismo fader de mezcla girado 90°

class EqBandFader extends StatelessWidget {
  final double value; // -12..12 dB
  final String label;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final double height;

  const EqBandFader({
    super.key,
    required this.value,
    required this.label,
    required this.enabled,
    required this.onChanged,
    this.height = 160,
  });

  static const _trackW = 32.0;

  @override
  Widget build(BuildContext context) {
    final fillH = (value.abs() / 12) * (height / 2);
    final norm = ((value + 12) / 24).clamp(0.0, 1.0);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Valor dB
          Text(
            value > 0
                ? '+${value.toStringAsFixed(0)}'
                : value.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: !enabled
                  ? AppColors.textTertiary
                  : value == 0
                      ? AppColors.textSecondary
                      : AppColors.accent,
            ),
          ),
          const SizedBox(height: 4),
          // Fader
          SizedBox(
            width: _trackW,
            height: height,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Track vertical
                Positioned(
                  left: (_trackW - 5) / 2,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: const Color(0x33FF2020),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: const Color(0x1FFF2020)),
                    ),
                  ),
                ),
                // Línea central (0 dB)
                Positioned(
                  top: height / 2 - 0.5,
                  child: Container(
                    width: 14,
                    height: 1,
                    color: Colors.white24,
                  ),
                ),
                // Fill desde el centro
                if (fillH > 0)
                  Positioned(
                    left: (_trackW - 5) / 2,
                    top: value >= 0 ? height / 2 - fillH : height / 2,
                    child: Container(
                      width: 5,
                      height: fillH.clamp(0.0, height / 2),
                      decoration: BoxDecoration(
                        color: enabled
                            ? const Color(0x66FF2020)
                            : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                // Slider girado con thumb de mezcla
                RotatedBox(
                  quarterTurns: 3,
                  child: SizedBox(
                    width: height,
                    height: _trackW,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: _trackW,
                        thumbShape: const _FaderThumbShape(isEqBand: true),
                        overlayShape: SliderComponentShape.noOverlay,
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        disabledThumbColor: AppColors.textTertiary,
                      ),
                      child: Slider(
                        value: norm,
                        onChanged: enabled
                            ? (v) => onChanged((v * 24) - 12)
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Etiqueta de frecuencia
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
