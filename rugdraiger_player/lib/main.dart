import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'data/repositories/music_repository.dart';
import 'services/audio_service.dart';
import 'services/equalizer_service.dart';
import 'services/permission_service.dart';
import 'presentation/bloc/player/player_bloc.dart';
import 'presentation/bloc/library/library_bloc.dart';
import 'presentation/screens/home/main_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surfaceElevated,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await _initPlatformServices();
  runApp(const RugdraigerApp());
}

Future<void> _initPlatformServices() async {
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  } catch (e, st) {
    debugPrint('AudioSession init failed: $e\n$st');
  }

  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.rugdraiger.player.channel.audio',
      androidNotificationChannelName: 'Rugdraiger Play',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_stat_music_note',
      notificationColor: AppColors.accent,
      preloadArtwork: true,
    );
    AudioPlayerService.backgroundEnabled = true;
  } catch (e, st) {
    AudioPlayerService.backgroundEnabled = false;
    debugPrint('JustAudioBackground init failed (playback sin notificación): $e\n$st');
  }

  try {
    await EqualizerService().init();
  } catch (e, st) {
    debugPrint('EqualizerService init failed: $e\n$st');
  }
}

class RugdraigerApp extends StatelessWidget {
  const RugdraigerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = MusicRepository();
    final audioService = AudioPlayerService();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MusicRepository>(create: (_) => repository),
        RepositoryProvider<AudioPlayerService>(create: (_) => audioService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<PlayerBloc>(
            create: (_) => PlayerBloc(
              audioService: audioService,
              repository: repository,
            ),
          ),
          BlocProvider<LibraryBloc>(
            create: (_) => LibraryBloc(repository: repository),
          ),
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const _AppBootstrap(),
        ),
      ),
    );
  }
}

class _AppBootstrap extends StatelessWidget {
  const _AppBootstrap();

  @override
  Widget build(BuildContext context) => const _PermissionGate();
}

class _PermissionGate extends StatefulWidget {
  const _PermissionGate();

  @override
  State<_PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<_PermissionGate> {
  bool _loading = true;
  bool _granted = false;
  bool _permanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    final hasAccess = await PermissionService.hasMediaAccess();
    if (hasAccess) {
      await PermissionService.requestNotificationsOptional();
      if (mounted) {
        setState(() {
          _granted = true;
          _loading = false;
        });
      }
      return;
    }

    // Primera apertura: pedir permiso de inmediato
    await _requestAccess();
  }

  Future<void> _requestAccess() async {
    setState(() => _loading = true);

    final granted = await PermissionService.requestMediaAccess();
    if (granted) {
      await PermissionService.requestNotificationsOptional();
    }

    final permanent = !granted && await PermissionService.isPermanentlyDenied();

    if (mounted) {
      setState(() {
        _granted = granted;
        _permanentlyDenied = permanent;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AppLogo(),
              SizedBox(height: 32),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonRed),
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Preparando Rugdraiger Play...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (!_granted) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _AppLogo(),
                const SizedBox(height: 32),
                const Icon(Icons.library_music_rounded, color: AppColors.accent, size: 48),
                const SizedBox(height: 20),
                const Text(
                  'Acceso a tu música',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Rugdraiger Play necesita permiso para leer la música almacenada en tu dispositivo, escanear tu biblioteca y reproducir canciones.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Toca "Permitir acceso" y acepta el permiso de archivos de audio en el diálogo del sistema.',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _permanentlyDenied
                        ? () async {
                            await openAppSettings();
                            await _requestAccess();
                          }
                        : _requestAccess,
                    icon: Icon(_permanentlyDenied ? Icons.settings_rounded : Icons.check_rounded),
                    label: Text(_permanentlyDenied ? 'ABRIR AJUSTES' : 'PERMITIR ACCESO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (!_permanentlyDenied) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _requestAccess,
                    child: const Text('Reintentar', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return const MainScaffold(autoScanOnStart: true);
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icons/app_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.play_circle_filled_rounded,
                color: AppColors.accent,
                size: 52,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'RUGDRAIGER',
          style: TextStyle(
            color: AppColors.neonRed,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
        const Text(
          'MUSIC PLAYER',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            letterSpacing: 3,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
