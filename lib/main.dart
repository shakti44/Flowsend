import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'features/settings/privacy_intro_screen.dart';
import 'features/settings/privacy_security_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Fonts aren't bundled as assets, so avoid blocking/slowing launch on a
  // network fetch — fall back to the platform default font instantly instead.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Force portrait orientation on mobile for Phase 1
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar: transparent, light icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FlowSendApp());
}

/// Root application widget.
class FlowSendApp extends StatefulWidget {
  const FlowSendApp({super.key});

  @override
  State<FlowSendApp> createState() => _FlowSendAppState();
}

class _FlowSendAppState extends State<FlowSendApp> {
  bool? _introCompleted;

  @override
  void initState() {
    super.initState();
    _hasCompletedIntro().then((completed) {
      if (mounted) setState(() => _introCompleted = completed);
    });
  }

  Future<bool> _hasCompletedIntro() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool('privacy_intro_completed') ?? false;
    } on Object {
      return true;
    }
  }

  Future<void> _completeIntro() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('privacy_intro_completed', true);
    if (mounted) setState(() => _introCompleted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_introCompleted == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _IntroLoadingScreen(),
      );
    }
    if (_introCompleted == false) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: PrivacyIntroScreen(
          onContinue: _completeIntro,
          onPrivacyPolicy: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
          ),
        ),
      );
    }
    return MaterialApp.router(
      title: 'FlowSend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}

class _IntroLoadingScreen extends StatelessWidget {
  const _IntroLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark.scaffoldBackgroundColor,
      body: Center(
        child: Text('FlowSend', style: AppTheme.dark.textTheme.headlineMedium),
      ),
    );
  }
}
