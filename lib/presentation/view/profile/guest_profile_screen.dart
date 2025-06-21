import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/presentation/view/auth/login_screen.dart';
import 'package:flutter_projects/presentation/view/auth/register_screen.dart';
import 'package:flutter_projects/presentation/view/courses/courses_screen.dart';
import 'package:flutter_projects/presentation/view/tutor/search_tutors_screen.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../../../data/provider/settings_provider.dart';
import '../components/internet_alert.dart';

class GuestProfileScreen extends StatefulWidget {
  @override
  _GuestProfileScreenState createState() => _GuestProfileScreenState();
}

class _GuestProfileScreenState extends State<GuestProfileScreen> {
  bool isLoading = false;

  late double screenWidth;
  late double screenHeight;

  bool isSettingLoading = false;

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 1.0,
        left: 16.0,
        right: 16.0,
        child: CustomToast(
          message: message,
          isSuccess: isSuccess,
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    final settingsProvider = Provider.of<SettingsProvider>(context);

    final coursesAddon =
        settingsProvider.getSetting('data')?['installed_addons'];

    final isCoursesEnabled =
        (coursesAddon != null && coursesAddon['Learnty'] == true)
            ? true
            : false;

    return Consumer<ConnectivityProvider>(
        builder: (context, connectivityProvider, _) {
      if (!connectivityProvider.isConnected) {
        return Scaffold(
          backgroundColor: AppColors.backgroundColor(context),
          body: Center(
            child: InternetAlertDialog(
              onRetry: () async {
                await connectivityProvider.checkInitialConnection();
              },
            ),
          ),
        );
      }

      return WillPopScope(
        onWillPop: () async {
          if (isLoading) {
            return false;
          } else {
            return true;
          }
        },
        child: Directionality(
          textDirection: Localization.textDirection,
          child: Scaffold(
            backgroundColor: AppColors.backgroundColor(context),
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(100.0),
              child: Container(
                padding: EdgeInsets.only(
                    left: 15.0,
                    top: 50,
                    right: Localization.textDirection == TextDirection.rtl
                        ? 5.0
                        : 0.0),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        AppImages.guestUserIcon,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(Localization.translate('guest_user') ?? '').trim() != 'guest_user' && (Localization.translate('guest_user') ?? '').trim().isNotEmpty ? Localization.translate('guest_user') : 'Guest User'}',
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            color: AppColors.blackColor,
                            fontSize: FontSize.scale(context, 18),
                            fontFamily: AppFontFamily.boldFont,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${(Localization.translate('sign_in_role') ?? '').trim() != 'sign_in_role' && (Localization.translate('sign_in_role') ?? '').trim().isNotEmpty ? Localization.translate('sign_in_role') : 'Sign in as a Tutor or Student'}',
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 14),
                            fontFamily: AppFontFamily.regularFont,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            body: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        if (isCoursesEnabled) ...[
                          ListTile(
                            splashColor: Colors.transparent,
                            leading: SvgPicture.asset(
                              AppImages.courseIcon,
                              width: 20,
                              height: 20,
                              color: AppColors.greyColor(context),
                            ),
                            title: Transform.translate(
                              offset: const Offset(-10, 0.0),
                              child: Text(
                                '${(Localization.translate('courses') ?? '').trim() != 'courses' && (Localization.translate('courses') ?? '').trim().isNotEmpty ? Localization.translate('courses') : 'Courses'}',
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 16),
                                  fontFamily: AppFontFamily.regularFont,
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CoursesScreen()),
                              );
                            },
                          ),
                        ],
                        ListTile(
                          splashColor: Colors.transparent,
                          leading: SvgPicture.asset(
                            AppImages.search,
                            width: 20,
                            height: 20,
                            color: AppColors.greyColor(context),
                          ),
                          title: Transform.translate(
                            offset: const Offset(-10, 0.0),
                            child: Text(
                              "${(Localization.translate('find_tutors') ?? '').trim() != 'find_tutors' && (Localization.translate('find_tutors') ?? '').trim().isNotEmpty ? Localization.translate('find_tutors') : 'Find Tutors'}",
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                color: AppColors.greyColor(context),
                                fontSize: FontSize.scale(context, 16),
                                fontFamily: AppFontFamily.regularFont,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SearchTutorsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen(context),
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          Localization.translate('signIn'),
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: FontSize.scale(context, 16),
                            fontFamily: AppFontFamily.mediumFont,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 16.0),
                      child: RichText(
                        text: TextSpan(
                          text: Localization.translate(
                              "account_unavailable")
                              .isNotEmpty ==
                              true
                              ? Localization.translate(
                              "account_unavailable")
                              : "Don’t have an account?",
                          style: TextStyle(
                            fontSize: FontSize.scale(context, 14),
                            color: AppColors.greyColor(context),
                            fontFamily: AppFontFamily.mediumFont,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                          ),
                          children: [
                            TextSpan(
                              text: " ",
                            ),
                            TextSpan(
                              text: Localization.translate(
                                  "sign_up")
                                  .isNotEmpty ==
                                  true
                                  ? Localization.translate(
                                  "sign_up")
                                  : "Sign up",
                              style: TextStyle(
                                fontSize:
                                FontSize.scale(context, 14),
                                color:
                                AppColors.greyColor(context),
                                fontFamily:
                                AppFontFamily.mediumFont,
                                fontWeight: FontWeight.w500,
                                decoration:
                                TextDecoration.underline,
                                decorationThickness: 1,
                                fontStyle: FontStyle.normal,
                                height: 1.1,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            RegistrationScreen()),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
