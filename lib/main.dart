import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_projects/api_structure/config/app_config.dart';
import 'package:flutter_projects/localization/localization.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/provider/connectivity_provider.dart';
import 'package:flutter_projects/provider/settings_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/components/internet_alert.dart';
import 'package:flutter_projects/view/tutor/search_tutors_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   print("App is initialized........");
//
//   FlutterError.onError = (FlutterErrorDetails details) {
//     FlutterError.presentError(details);
//     print("Flutter Error: ${details.exceptionAsString()}");
//   };
//   Map<String, dynamic> settingsData = {};
//
//   try {
//     settingsData = await AppConfig().getSettings().timeout(Duration(seconds: 10));
//     print("Settings loaded :$settingsData");
//     await Localization.settingsTranslation(settingsData['data'],
//         settingsData['data']['_general']['default_language']);
//   } catch (e) {
//     print("Initialized error --->>>>>> $e");
//     Localization.currentLocale = 'en';
//   }
//
//
//
//   print("Running the app......");
//
//    runApp(MyApp());
//
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("App is initializing...");

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print("Flutter Error: ${details.exceptionAsString()}");
  };

  Map<String, dynamic> settingsData = {};

  try {
    settingsData = await AppConfig().getSettings().timeout(Duration(seconds: 10));
    print("Settings loaded: $settingsData");

    if (settingsData.containsKey('data') &&
        settingsData['data'].containsKey('_general') &&
        settingsData['data']['_general'].containsKey('default_language')) {
      await Localization.settingsTranslation(
        settingsData['data'],
        settingsData['data']['_general']['default_language'],
      );
    } else {
      print("Missing settings data, defaulting to English.");
      Localization.currentLocale = 'en';
    }
  } catch (e) {
    print("Initialization error: $e");
    Localization.currentLocale = 'en'; // Fallback to English
  }

  print("Running the app...");
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
print("Settings provider fetched before initialized : $settingsProvider");
    try {
      Map<String, dynamic> fetchedSettings = await AppConfig().getSettings().timeout(Duration(seconds: 10));
      print("Fetched settings: $fetchedSettings");
      settingsProvider.setSettings(fetchedSettings);

    } catch (error) {
      print('Error loading settings : $error');
      Localization.currentLocale = 'en';
    }


    setState(() {
      _isSettingsLoaded = true;
    });

    print("Navigating to Lernen...");

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
      backgroundColor: AppColors.whiteColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            splashImage.startsWith('http')
                ? Image.network(
                    splashImage,
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace){
                      return Image.asset(
                        AppImages.defaultSplash,
                        width: MediaQuery.of(context).size.width*0.7,
                        height: MediaQuery.of(context).size.width*0.7,
                      );
              },
                  )
                : Image.asset(
                    AppImages.defaultSplash,
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    fit: BoxFit.contain,
                  ),
            const SizedBox(height: 20),
            if (!_isSettingsLoaded)
               SpinKitCircle(
                  color: AppColors.blueColor,
                 size: 200,
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
          return InternetAlertDialog(onRetry: () async{
            await connectivityProvider.checkInitialConnection();
          });

          //   MaterialApp(
          //   debugShowCheckedModeBanner: false,
          //   home: Scaffold(
          //     backgroundColor: AppColors.backgroundColor(context),
          //     body: Center(
          //       child: InternetAlertDialog(
          //         onRetry: () async {
          //           await connectivityProvider.checkInitialConnection();
          //           (context as Element).reassemble();
          //         },
          //       ),
          //     ),
          //   ),
          // );
        }

        return  authProvider.isLoggedIn
            ? SearchTutorsScreen()
            : LoginScreen();

        //   MaterialApp(
        //   debugShowCheckedModeBanner: false,
        //   home: authProvider.isLoggedIn ? SearchTutorsScreen() : LoginScreen(),
        // );
      },
    );
  }
}
