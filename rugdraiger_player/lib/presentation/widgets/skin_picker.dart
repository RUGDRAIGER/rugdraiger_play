import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/player_skins.dart';
import '../../services/settings_service.dart';

class SkinPicker extends StatelessWidget {
  const SkinPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    final current = getSkinById(settings.skinId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tono actual: ${current.name}',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        ...skinGroupOrder.entries.map((entry) {
          final group = entry.key;
          final skins = getSkinsForGroup(group);
          if (skins.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: skins[skins.length ~/ 2].accent, width: 4),
                        bottom: BorderSide(color: AppColors.borderSubtle),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          skins.first.accent.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                skinGroupLabels[group] ?? group,
                                style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                              ),
                              Text(
                                skinGroupHints[group] ?? '',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${skins.length}',
                            style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skins.map((skin) {
                        final selected = settings.skinId == skin.id;
                        return InkWell(
                          onTap: () => settings.setSkinId(skin.id),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 76,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected ? skin.accent : AppColors.borderSubtle,
                                width: selected ? 2 : 1,
                              ),
                              color: selected
                                  ? skin.accent.withValues(alpha: 0.12)
                                  : AppColors.background,
                              boxShadow: selected
                                  ? [BoxShadow(color: skin.accent.withValues(alpha: 0.35), blurRadius: 12)]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: skin.accent,
                                    border: Border.all(color: Colors.white24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: skin.accent.withValues(alpha: 0.45),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  skin.name,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    color: selected ? skin.accent : AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
