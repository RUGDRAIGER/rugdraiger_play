import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/equalizer_service.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  final _eqService = EqualizerService();

  @override
  Widget build(BuildContext context) {
    final state = _eqService.state;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildEqToggle(state),
                    const SizedBox(height: 24),
                    _buildPresets(state),
                    const SizedBox(height: 24),
                    _buildEqBands(state),
                    const SizedBox(height: 24),
                    _buildBassBoost(state),
                    const SizedBox(height: 24),
                    _buildResetButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text('Equalizer', style: AppTextStyles.headlineLarge),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildEqToggle(EqualizerState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('10-Band Equalizer', style: AppTextStyles.titleMedium),
              Text(
                state.enabled ? 'Active' : 'Inactive',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: state.enabled ? AppColors.neonRed : AppColors.textMuted,
                ),
              ),
            ],
          ),
          Switch(
            value: state.enabled,
            activeThumbColor: AppColors.neonRed,
            activeTrackColor: AppColors.neonRedSubtle,
            onChanged: (value) async {
              await _eqService.setEnabled(value);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresets(EqualizerState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Presets', style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EqPreset.values.where((p) => p != EqPreset.custom).map((preset) {
            final isSelected = state.preset == preset;
            return GestureDetector(
              onTap: () async {
                await _eqService.applyPreset(preset);
                setState(() {});
              },
              child: AnimatedContainer(
                duration: AppConstants.animFast,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.neonRed : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.neonRed : AppColors.border,
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Text(
                  preset.displayName,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEqBands(EqualizerState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Bands', style: AppTextStyles.titleLarge),
            Text('+12 / -12 dB', style: AppTextStyles.labelSmall),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          child: SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(AppConstants.eqBandCount, (index) {
                final value = state.bands[index];
                final freq = AppConstants.eqFrequencies[index];
                final label = freq >= 1000 ? '${freq ~/ 1000}k' : '$freq';

                return Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                              activeTrackColor: AppColors.neonRed,
                              inactiveTrackColor: AppColors.progressBackground,
                              thumbColor: AppColors.neonRed,
                              overlayColor: AppColors.neonRedGlow,
                            ),
                            child: Slider(
                              value: value,
                              min: -12,
                              max: 12,
                              onChanged: (v) async {
                                await _eqService.setBand(index, v);
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                      ),
                      Text(
                        label,
                        style: AppTextStyles.labelSmall.copyWith(fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${value >= 0 ? '+' : ''}${value.toStringAsFixed(0)}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: value != 0 ? AppColors.neonRed : AppColors.textMuted,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBassBoost(EqualizerState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Bass Boost', style: AppTextStyles.titleLarge),
            Text('${state.bassBoost}%', style: AppTextStyles.neonLabel),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            activeTrackColor: AppColors.neonRed,
            inactiveTrackColor: AppColors.progressBackground,
            thumbColor: AppColors.neonRed,
            overlayColor: AppColors.neonRedGlow,
          ),
          child: Slider(
            value: state.bassBoost.toDouble(),
            min: 0,
            max: 100,
            divisions: 10,
            onChanged: (v) async {
              await _eqService.setBassBoost(v.round());
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return GestureDetector(
      onTap: () async {
        await _eqService.reset();
        setState(() {});
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: Text(
          'RESET TO FLAT',
          style: AppTextStyles.labelLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
