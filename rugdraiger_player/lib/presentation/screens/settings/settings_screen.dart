import 'package:flutter/material.dart';
import '../../../core/navigation/view_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/settings_service.dart';
import '../../widgets/skin_picker.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<ViewName>? onNavigateEqualizer;

  const SettingsScreen({super.key, this.onNavigateEqualizer});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService.instance;

  @override
  void initState() {
    super.initState();
    _settings.load();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            Text('Ajustes', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Personaliza reproducción e interfaz',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Reproducción'),
            _toggle(
              'Reproducción gapless',
              'Sin silencio entre pistas de un álbum',
              _settings.gaplessPlayback,
              _settings.setGaplessPlayback,
            ),
            _toggle(
              'ReplayGain',
              'Volumen uniforme entre canciones',
              _settings.replayGainEnabled,
              _settings.setReplayGainEnabled,
            ),
            _toggle(
              'Teclas multimedia',
              'Controles desde auriculares y Bluetooth',
              _settings.mediaKeysEnabled,
              _settings.setMediaKeysEnabled,
            ),
            const SizedBox(height: 16),
            _sectionTitle('Interfaz'),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Skin del reproductor',
                style: AppTextStyles.bodyLarge,
              ),
            ),
            const SkinPicker(),
            const SizedBox(height: 8),
            _toggle(
              'Colores dinámicos',
              'Acentos desde la carátula actual',
              _settings.dynamicColors,
              _settings.setDynamicColors,
            ),
            _toggle(
              'Modo conducción',
              'Botones grandes para manejar',
              _settings.drivingMode,
              _settings.setDrivingMode,
            ),
            _toggle(
              'Mostrar letras',
              'Letras sincronizadas cuando estén disponibles',
              _settings.showLyrics,
              _settings.setShowLyrics,
            ),
            const SizedBox(height: 16),
            _sectionTitle('Ecualizador'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Abrir ecualizador', style: AppTextStyles.bodyLarge),
              subtitle: Text(
                '10 bandas y presets personalizables',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              onTap: () => widget.onNavigateEqualizer?.call(ViewName.equalizer),
            ),
            const SizedBox(height: 16),
            _sectionTitle('Próximamente'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Sincronización en la nube',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary),
              ),
              subtitle: Text(
                'Google Drive, Dropbox…',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.neonRed,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _toggle(
    String title,
    String subtitle,
    bool value,
    Future<void> Function(bool) onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
      value: value,
      activeThumbColor: AppColors.neonRed,
      activeTrackColor: AppColors.neonRed.withValues(alpha: 0.45),
      onChanged: (v) => onChanged(v),
    );
  }
}
