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

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surfaceElevated,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize background audio service
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.rugdraiger.player.channel.audio',
    androidNotificationChannelName: 'Rugdraiger Player',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );

  // Initialize Equalizer service
  await EqualizerService().init();

  runApp(const RugdraigerApp());
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
          home: const _PermissionGate(),
        ),
      ),
    );
  }
}

/// Handles storage permission before showing the main app.
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
    // Android 13+ uses READ_MEDIA_AUDIO; older uses READ_EXTERNAL_STORAGE
    final audioStatus = await Permission.audio.request();
    if (audioStatus.isGranted) return true;

    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
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
                  'Storage Permission Required',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Rugdraiger Player needs access to your music files to scan your library.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    await openAppSettings();
                    await _checkPermission();
                  },
                  child: const Text('GRANT PERMISSION'),
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
            border: Border.all(color: AppColors.neonRed, width: 2),
            color: AppColors.neonRedSubtle,
            boxShadow: [
              BoxShadow(
                color: AppColors.neonRed.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.play_circle_filled_rounded,
            color: AppColors.neonRed,
            size: 52,
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
