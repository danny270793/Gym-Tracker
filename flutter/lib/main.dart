import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_session_notifier.dart';
import 'core/di/injection.dart';
import 'core/locale/app_locale_controller.dart';
import 'core/logger/app_logger.dart';
import 'core/security/app_biometric_unlock_controller.dart';
import 'core/storage/legacy_local_data_migrator.dart';
import 'core/storage/local_json_store.dart';
import 'core/theme/app_theme_controller.dart';
import 'core/units/app_weight_unit_controller.dart';
import 'features/exercises/presentation/cubit/exercises_cubit.dart';
import 'features/plan/presentation/cubit/plan_cubit.dart';
import 'features/workouts/presentation/cubit/workouts_cubit.dart';
import 'router.dart';

// Dart's HttpClient (used under the hood by package:http and thus by
// Supabase) has its own bundled trust store, independent of the Android/iOS
// OS trust store - installing a corporate proxy's root CA (e.g. Zscaler) at
// the OS level does nothing for it. Debug-only: trust it here too, so local
// dev works behind a TLS-intercepting proxy. Never runs in release builds.
Future<void> _trustDevProxyCertificateIfNeeded() async {
  if (!kDebugMode) return;
  try {
    final bytes = await rootBundle.load('assets/certs/zscaler_root_ca.pem');
    SecurityContext.defaultContext.setTrustedCertificatesBytes(
      bytes.buffer.asUint8List(),
    );
    AppLogger.info('trusted dev proxy certificate');
  } catch (e) {
    AppLogger.info('no dev proxy certificate to trust: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only Android has a Firebase config (android/app/google-services.json);
  // add ios/Runner/GoogleService-Info.plist before enabling it on iOS.
  if (defaultTargetPlatform == TargetPlatform.android) {
    AppLogger.info('initializing Firebase');
    await Firebase.initializeApp();
    AppLogger.info('Firebase initialized');
  }
  await _trustDevProxyCertificateIfNeeded();

  // Supabase is used for sign-in only. Gym data lives on the device for now
  // (see LocalJsonStore) so the schema can evolve without migrations.
  AppLogger.info('initializing Supabase');
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  AppLogger.info('Supabase initialized');

  final store = await LocalJsonStore.open();
  setupDi(store: store);
  AppLogger.info('DI setup complete');
  await getIt<AppLocaleController>().load();
  await getIt<AppThemeController>().load();
  await getIt<AppWeightUnitController>().load();
  await getIt<AppBiometricUnlockController>().load();

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  static Locale? _resolveDeviceLocale(
    Locale? deviceLocale,
    Iterable<Locale> supported,
  ) {
    if (deviceLocale == null) return supported.first;
    for (final loc in supported) {
      if (loc.languageCode == deviceLocale.languageCode) return loc;
    }
    return supported.first;
  }

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late final GoRouter _router = buildRouter();

  /// True after [AppLifecycleState.paused]; cleared on resume so cold start does not lock.
  bool _shouldUnlockOnNextResume = false;

  /// Full-screen gate: no router navigation visible until cleared.
  bool _biometricLockActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _shouldUnlockOnNextResume = true;
    } else if (state == AppLifecycleState.resumed &&
        _shouldUnlockOnNextResume) {
      _shouldUnlockOnNextResume = false;
      unawaited(_activateBiometricLockIfNeeded());
    }
  }

  Future<void> _activateBiometricLockIfNeeded() async {
    if (!getIt<AuthSessionNotifier>().isSignedIn) return;
    final bio = getIt<AppBiometricUnlockController>();
    await bio.refreshAuthenticatorAvailability();
    if (!bio.enabled || !bio.authenticatorAvailable) return;
    if (!mounted) return;
    setState(() => _biometricLockActive = true);
  }

  void _clearBiometricLock() {
    if (_biometricLockActive) {
      setState(() => _biometricLockActive = false);
    }
  }

  ThemeData _theme(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepOrange,
      brightness: brightness,
    ),
    useMaterial3: true,
    bottomSheetTheme: const BottomSheetThemeData(clipBehavior: Clip.antiAlias),
  );

  @override
  Widget build(BuildContext context) {
    final appLocale = getIt<AppLocaleController>();
    final appTheme = getIt<AppThemeController>();
    final session = getIt<AuthSessionNotifier>();
    return ListenableBuilder(
      listenable: Listenable.merge([appLocale, appTheme, session]),
      builder: (context, _) {
        return MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: appLocale.materialAppLocale,
          localeResolutionCallback: App._resolveDeviceLocale,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          themeMode: appTheme.themeMode,
          routerConfig: _router,
          builder: (context, child) {
            if (_biometricLockActive) {
              return PopScope(
                canPop: false,
                child: _BiometricLockScreen(onUnlocked: _clearBiometricLock),
              );
            }
            // Per-user data cubits sit above the navigator so every route can
            // read them. Keyed by user id: signing in as someone else
            // recreates (and reloads) them. The gate first uploads data left
            // by the device-only version of the app, once per account.
            return _UserDataGate(
              key: ValueKey(session.userId ?? '-'),
              userId: session.userId,
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => getIt<ExercisesCubit>()..load()),
                  BlocProvider(create: (_) => getIt<PlanCubit>()..load()),
                  BlocProvider(create: (_) => getIt<WorkoutsCubit>()..load()),
                ],
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }
}

/// Runs [LegacyLocalDataMigrator] for [userId] before showing [child], so the
/// cubits load what was just uploaded. Failures (e.g. offline) don't block
/// the app; the upload is retried on the next launch.
class _UserDataGate extends StatefulWidget {
  const _UserDataGate({super.key, required this.userId, required this.child});

  final String? userId;
  final Widget child;

  @override
  State<_UserDataGate> createState() => _UserDataGateState();
}

class _UserDataGateState extends State<_UserDataGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (widget.userId == null) {
      _ready = true;
    } else {
      unawaited(_migrate());
    }
  }

  Future<void> _migrate() async {
    try {
      await getIt<LegacyLocalDataMigrator>().migrateIfNeeded();
    } catch (e, s) {
      AppLogger.error('uploading on-device data failed; will retry', e, s);
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    final l10n = AppLocalizations.of(context);
    return Material(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            if (l10n != null) Text(l10n.syncingLocalData),
          ],
        ),
      ),
    );
  }
}

class _BiometricLockScreen extends StatefulWidget {
  const _BiometricLockScreen({required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<_BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<_BiometricLockScreen> {
  /// True while refresh + system biometric UI may be active — disables the Unlock button.
  bool _busy = false;

  /// Prevents overlapping [_attemptUnlock] runs (e.g. double-tap before first await).
  bool _unlockInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptUnlock());
  }

  Future<void> _attemptUnlock() async {
    if (!mounted) return;

    if (!getIt<AuthSessionNotifier>().isSignedIn) {
      widget.onUnlocked();
      return;
    }

    if (_unlockInFlight) return;
    _unlockInFlight = true;
    setState(() => _busy = true);

    try {
      final bio = getIt<AppBiometricUnlockController>();
      await bio.refreshAuthenticatorAvailability();
      if (!mounted) return;

      if (!bio.enabled || !bio.authenticatorAvailable) {
        widget.onUnlocked();
        return;
      }

      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;

      final ok = await bio.localAuth
          .authenticate(
            localizedReason: l10n.settingsBiometricResumeReason,
            biometricOnly: true,
            persistAcrossBackgrounding: true,
          )
          .catchError(
            (Object _) => false,
            test: (e) => e is LocalAuthException,
          );
      if (!mounted) return;

      if (ok) {
        widget.onUnlocked();
      }
    } finally {
      _unlockInFlight = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 56,
                  color: scheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.biometricLockTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.biometricLockBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _busy ? null : _attemptUnlock,
                  icon: _busy
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.fingerprint_rounded),
                  label: Text(l10n.biometricLockUnlockButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
