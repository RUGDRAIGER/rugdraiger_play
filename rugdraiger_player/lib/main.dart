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
      androidNotificationIcon: 'mipmap/ic_launcher',
      preloadArtwork: false,
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

/// Gate de permisos antes de mostrar la app principal.
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

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await _requestPermissions();
    if (mounted) {
      setState(() {
        _granted = status;
        _loading = false;
      });
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      final permissions = <Permission>[
        Permission.audio,
        Permission.notification,
      ];

      for (final permission in permissions) {
        final current = await permission.status;
        if (current.isGranted) continue;
        final result = await permission.request().timeout(const Duration(seconds: 20));
        if (result.isPermanentlyDenied) {
          return false;
        }
      }

      final audioGranted = await Permission.audio.isGranted;
      if (audioGranted) return true;

      // Android 12 y anteriores
      final storage = await Permission.storage.request().timeout(const Duration(seconds: 20));
      return storage.isGranted || audioGranted;
    } catch (e) {
      debugPrint('Permission request failed: $e');
      return false;
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
            ],
          ),
        ),
      );
    }

    if (!_granted) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _AppLogo(),
                const SizedBox(height: 32),
                const Text(
                  'Permiso de almacenamiento',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Rugdraiger Play necesita acceder a tu música para escanear la biblioteca.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    await openAppSettings();
                    await _checkPermission();
                  },
                  child: const Text('ABRIR AJUSTES'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _granted = true),
                  child: const Text(
                    'Continuar sin permiso',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const MainScaffold();
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
