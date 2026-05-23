import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/equalizer_service.dart';
import '../../widgets/volume_fader.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  final _eqService = EqualizerService();

  String _bandLabel(int freq) => freq >= 1000 ? '${freq ~/ 1000}k' : '$freq';

  @override
  Widget build(BuildContext context) {
    final state = _eqService.state;
    const sliderH = 160.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ecualizador', style: AppTextStyles.displayMedium.copyWith(fontSize: 22)),
                Row(
                  children: [
                    const Text('Activar', style: AppTextStyles.bodyMedium),
                    const SizedBox(width: 8),
                    Switch(
                      value: state.enabled,
                      activeTrackColor: AppColors.accent.withValues(alpha: 0.5),
                      thumbColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected) ? AppColors.accent : null,
                      ),
                      onChanged: (v) async {
                        await _eqService.setEnabled(v);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'PRESETS',
              style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.eqDisplayPresets.map((preset) {
                final selected = state.preset == preset;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: state.enabled
                        ? () async {
                            await _eqService.applyPreset(preset);
                            setState(() {});
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accent : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.accent : AppColors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        preset.displayName,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Panel EQ — igual que web (bg-surface, border, faders rojos)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: sliderH + 36,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(AppConstants.eqBandCount, (index) {
                        return EqBandFader(
                          value: state.bands[index],
                          label: _bandLabel(AppConstants.eqFrequencies[index]),
                          enabled: state.enabled,
                          height: sliderH,
                          onChanged: (v) async {
                            await _eqService.setBand(index, v);
                            setState(() {});
                          },
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('+12 dB', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                      Text('0 dB', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text('-12 dB', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: state.enabled
                    ? () async {
                        await _eqService.reset();
                        setState(() {});
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderSubtle),
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                ),
                child: const Text('Restablecer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
