import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_projects/data/provider/dispute_discussion_provider.dart';
import 'package:flutter_projects/presentation/view/auth/login_screen.dart';
import 'package:flutter_projects/presentation/view/tutor/search_tutors_screen.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'data/localization/localization.dart';
import 'data/provider/auth_provider.dart';
import 'data/provider/connectivity_provider.dart';
import 'data/provider/settings_provider.dart';
import 'domain/api_structure/config/app_config.dart';
import 'presentation/view/components/internet_alert.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> settingsData = {};
  try {
    settingsData = await AppConfig().getSettings();
    await Localization.settingsTranslation(settingsData['data'],
        settingsData['data']['_general']['default_language']);
  } catch (e) {
    Localization.currentLocale = 'en';
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (context) => DisputeDiscussionProvider()),
      ],
      child: MaterialApp(
        supportedLocales: [Locale(Localization.currentLocale)],
        locale: Locale(Localization.currentLocale),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isSettingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    try {
      Map<String, dynamic> fetchedSettings = await AppConfig().getSettings();

      settingsProvider.setSettings(fetchedSettings);
    } catch (error) {}

    setState(() {
      _isSettingsLoaded = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Lernen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final splashImage = AppImages.getDynamicSplash(context);

    return Scaffold(
      backgroundColor: AppColors.primaryGreen(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            splashImage.startsWith('http')
                ? (splashImage.endsWith('.svg')
                ? SvgPicture.network(
              splashImage,
              width: MediaQuery.of(context).size.width * 0.2,
              height: MediaQuery.of(context).size.height * 0.2,
              fit: BoxFit.contain,
              placeholderBuilder: (context) =>
                  CircularProgressIndicator(
                    color: AppColors.whiteColor,
                    strokeWidth: 2.0,
                  ),
            )
                : Image.network(
              splashImage,
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  SvgPicture.asset(
                    AppImages.defaultSplash,
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * 0.4,
                    fit: BoxFit.contain,
                  ),
            ))
                : SvgPicture.asset(
              AppImages.defaultSplash,
              width: MediaQuery.of(context).size.width * 0.4,
              height: MediaQuery.of(context).size.height * 0.4,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            if (!_isSettingsLoaded)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.greyColor(context),
                  strokeWidth: 2.0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Lernen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, _) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        if (!connectivityProvider.isConnected) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: AppColors.backgroundColor(context),
              body: Center(
                child: InternetAlertDialog(
                  onRetry: () async {
                    await connectivityProvider.checkInitialConnection();
                    (context as Element).reassemble();
                  },
                ),
              ),
            ),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: authProvider.isLoggedIn ? SearchTutorsScreen() : LoginScreen(),
        );
      },
    );
  }
}
