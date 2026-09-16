import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'features/settings/privacy_intro_screen.dart';
import 'features/settings/privacy_security_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
  late final Future<bool> _introFuture = _hasCompletedIntro();

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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _introFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            home: const _IntroLoadingScreen(),
          );
        }
        if (snapshot.data == false) {
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
      },
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
