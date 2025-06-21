import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/presentation/view/chat/chat_list.dart';
import 'package:flutter_projects/presentation/view/course_taking/course_taking_listing.dart';
import 'package:flutter_projects/presentation/view/courses/courses_screen.dart';
import 'package:flutter_projects/presentation/view/dispute/dispute_listing_screen.dart';
import 'package:flutter_projects/presentation/view/profile/profile_setting_screen.dart';
import 'package:flutter_projects/presentation/view/profile/skeleton/profile_image_skeleton.dart';
import 'package:flutter_projects/presentation/view/tutor/assignment/published_assignment.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../../../data/provider/settings_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import '../assignment/manage_assignments.dart';
import '../auth/login_screen.dart';
import '../billing/billing_information.dart';
import '../components/internet_alert.dart';
import '../components/login_required_alert.dart';
import '../insights/insights_screen.dart';
import '../invoice/invoice_screen.dart';
import '../notification/notification_listing.dart';
import '../payouts/payout_history.dart';
import '../settings/account_settings.dart';
import '../tutor/certificate/certificate_detail.dart';
import '../tutor/education/education_details.dart';
import '../tutor/experience/experience_detail.dart';
import '../tutor/saved_tutors.dart';
import 'identity_verification/identity_verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;

  late double screenWidth;
  late double screenHeight;
  late String studentName = "";
  late String tutorName = "";
  late String identityRole = "";

  bool isSettingLoading = false;

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 1.0,
            left: 16.0,
            right: 16.0,
            child: CustomToast(message: message, isSuccess: isSuccess),
          ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token != null) {
      setState(() {
        isLoading = true;
      });

      try {
        final response = await logout(token);
        if (response['status'] == 200) {
          showCustomToast(context, response['message'], true);

          await authProvider.clearToken();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else if (response['status'] == 403) {
          showCustomToast(context, response['message'], false);
        } else if (response['status'] == 401) {
          showCustomToast(
            context,
            '${Localization.translate("unauthorized_access")}',
            false,
          );

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return CustomAlertDialog(
                title: Localization.translate('invalidToken'),
                content: Localization.translate('loginAgain'),
                buttonText: Localization.translate('goToLogin'),
                buttonAction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                showCancelButton: false,
              );
            },
          );
        } else {
          showCustomToast(
            context,
            '${Localization.translate("logout_failed")} ${response['message']}',
            false,
          );
        }
      } catch (e) {
        showCustomToast(context, 'Error during logout: $e', false);
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      showCustomToast(
        context,
        'No token found, clearing session locally',
        false,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.userData != null) {
        String balance =
            (authProvider.userData?['user']?['balance'] is double
                ? (authProvider.userData?['user']?['balance'] as double)
                    .toStringAsFixed(2)
                : double.tryParse(
                  authProvider.userData?['user']?['balance']?.replaceAll(
                        RegExp(r'[^\d.]'),
                        '',
                      ) ??
                      '',
                )?.toStringAsFixed(2)) ??
            "\$0.0";

        String cleanedBalance = balance.replaceAll("\$", "").trim();

        try {
          double balanceValue = double.parse(cleanedBalance);
          authProvider.updateBalance(balanceValue);
          setState(() {});
        } catch (e) {
          authProvider.updateBalance(0.0);
        }
      }
    });
  }

  final List<Color> availableColors = [
    AppColors.yellowColor,
    AppColors.blueColor,
    AppColors.lightGreenColor,
    AppColors.purpleColor,
    AppColors.orangeColor,
  ];

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;

    String profileImageUrl =
        authProvider.userData?['user']?['profile']?['image'] ?? '';

    final bool identityVerified =
        authProvider.userData?['user']?['profile']?['verified'] ?? false;

    final bool profileVerified =
        authProvider.userData?['user']?['profile_completed'] ?? false;

    final String? fullName =
        userData != null && userData['user'] != null
            ? userData['user']['profile']['full_name']
            : null;
    final String? role =
        userData != null && userData['user'] != null
            ? userData['user']['role']
            : null;

    final settingsProvider = Provider.of<SettingsProvider>(context);

    final studentName =
        settingsProvider.getSetting(
          'data',
        )?['_lernen']?['student_display_name'] ??
        'Student';
    final tutorName =
        settingsProvider.getSetting(
          'data',
        )?['_lernen']?['tutor_display_name'] ??
        '';
    final identityRole =
        settingsProvider.getSetting(
          'data',
        )?['_lernen']?['identity_verification_for_role'];

    final coursesAddon =
        settingsProvider.getSetting('data')?['installed_addons'];

    final assignmentsAddon =
        settingsProvider.getSetting('data')?['installed_addons'];

    final isCoursesEnabled =
        (coursesAddon != null && coursesAddon['Learnty'] == true)
            ? true
            : false;

    final isAssignmentsEnabled =
        (assignmentsAddon != null && assignmentsAddon['Assignora'] == true)
            ? true
            : false;
    final random = Random();

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
                    right:
                        Localization.textDirection == TextDirection.rtl
                            ? 5.0
                            : 0.0,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: screenWidth * 0.078,
                        child: ClipOval(
                          child:
                              profileImageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                    imageUrl: profileImageUrl,
                                    width: screenWidth * 0.15,
                                    height: screenHeight * 0.15,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) => ProfileImageSkeleton(
                                          radius: screenWidth * 0.078,
                                        ),
                                    errorWidget:
                                        (context, url, error) => CircleAvatar(
                                          radius: screenWidth * 0.07,
                                          backgroundColor:
                                              availableColors[random.nextInt(
                                                availableColors.length,
                                              )],
                                          child: Text(
                                            fullName != null &&
                                                    fullName.isNotEmpty
                                                ? fullName[0].toUpperCase()
                                                : 'N',
                                            style: TextStyle(
                                              color: AppColors.blackColor,
                                              fontSize: FontSize.scale(
                                                context,
                                                20,
                                              ),
                                              fontFamily:
                                                  AppFontFamily.mediumFont,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                  )
                                  : CachedNetworkImage(
                                    imageUrl: profileImageUrl,
                                    width: screenWidth * 0.15,
                                    height: screenHeight * 0.15,
                                    fit: BoxFit.cover,
                                    errorWidget:
                                        (context, url, error) => CircleAvatar(
                                          radius: screenWidth * 0.07,
                                          backgroundColor:
                                              availableColors[random.nextInt(
                                                availableColors.length,
                                              )],
                                          child: Text(
                                            fullName != null &&
                                                    fullName.isNotEmpty
                                                ? fullName[0].toUpperCase()
                                                : 'N',
                                            style: TextStyle(
                                              color: AppColors.blackColor,
                                              fontSize: FontSize.scale(
                                                context,
                                                20,
                                              ),
                                              fontFamily:
                                                  AppFontFamily.boldFont,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                  ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            fullName ?? '',
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
                            role == "student"
                                ? studentName ?? 'Student'
                                : role == "tutor"
                                ? tutorName ?? 'Tutor'
                                : '',
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
                          ListTile(
                            splashColor: Colors.transparent,
                            leading: SvgPicture.asset(
                              AppImages.personOutline,
                              width: 20,
                              height: 20,
                            ),
                            title: Transform.translate(
                              offset: const Offset(-10, 0.0),
                              child: Text(
                                Localization.translate('profile_settings'),
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
                                  builder: (context) => ProfileSettingsScreen(),
                                ),
                              );
                            },
                          ),
                          if (role == "tutor")
                            ListTile(
                              splashColor: Colors.transparent,
                              leading: SvgPicture.asset(
                                AppImages.insightsIcon,
                                width: 20,
                                height: 20,
                              ),
                              title: Transform.translate(
                                offset: const Offset(-10, 0.0),
                                child: Text(
                                  Localization.translate('insights'),
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
                                    builder: (_) => InsightScreen(),
                                  ),
                                );
                              },
                            ),
                          if (identityRole == 'both' ||
                              (identityRole == 'tutor' && role == 'tutor'))
                            ListTile(
                              splashColor: Colors.transparent,
                              leading: SvgPicture.asset(
                                AppImages.identityVerification,
                                width: 20,
                                height: 20,
                              ),
                              title: Transform.translate(
                                offset: const Offset(-10, 0.0),
                                child: Text(
                                  Localization.translate(
                                    'identity_verification',
                                  ),
                                  style: TextStyle(
                                    color: AppColors.greyColor(context),
                                    fontSize: FontSize.scale(context, 16),
                                    fontFamily: AppFontFamily.regularFont,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.normal,
                                  ),
                                ),
                              ),
                              trailing:
                                  identityVerified
                                      ? Icon(
                                        Icons.check_circle,
                                        color: AppColors.primaryGreen(context),
                                        size: 25.0,
                                      )
                                      : null,
                              onTap: () {
                                if (!profileVerified) {
                                  showCustomToast(
                                    context,
                                    '${Localization.translate("complete_profile")}',
                                    false,
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              IdentityVerificationScreen(),
                                    ),
                                  );
                                }
                              },
                            )
                          else
                            SizedBox.shrink(),
                          ListTile(
                            splashColor: Colors.transparent,
                            leading: SvgPicture.asset(
                              AppImages.bellIcon,
                              width: 20,
                              height: 20,
                            ),
                            title: Transform.translate(
                              offset: const Offset(-10, 0.0),
                              child: Text(
                                '${(Localization.translate('notification') ?? '').trim() != 'notification' && (Localization.translate('notification') ?? '').trim().isNotEmpty ? Localization.translate('notification') : 'Notification'}',
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
                                  builder: (context) => NotificationListing(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            splashColor: Colors.transparent,
                            leading: SvgPicture.asset(
                              AppImages.chatIcon,
                              width: 20,
                              height: 20,
                            ),
                            title: Transform.translate(
                              offset: const Offset(-10, 0.0),
                              child: Text(
                                '${(Localization.translate('chat') ?? '').trim() != 'chat' && (Localization.translate('chat') ?? '').trim().isNotEmpty ? Localization.translate('chat') : 'Chat'}',
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
                                  builder: (context) => ChatListScreen(),
                                ),
                              );
                            },
                          ),

                          if (isAssignmentsEnabled) ...[
                            ListTile(
                              splashColor: Colors.transparent,
                              leading: SvgPicture.asset(
                                AppImages.disputeIcon,
                                width: 20,
                                height: 20,
                                color: AppColors.greyColor(context),
                              ),
                              title: Transform.translate(
                                offset: const Offset(-10, 0.0),
                                child: Text(
                                  '${(Localization.translate('assignments') ?? '').trim() != 'assignments' && (Localization.translate('assignments') ?? '').trim().isNotEmpty ? Localization.translate('assignments') : 'Assignments'}',
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
                                if (role == "student") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ManageAssignments(),
                                    ),
                                  );
                                } else if (role == "tutor") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => PublishedAssignment(),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],

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
                                    builder: (context) => CoursesScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                          if (role == "student" && isCoursesEnabled)
                            ListTile(
                              splashColor: Colors.transparent,
                              leading: SvgPicture.asset(
                                AppImages.learningIcon,
                                width: 20,
                                height: 20,
                                color: AppColors.greyColor(context),
                              ),
                              title: Transform.translate(
                                offset: const Offset(-10, 0.0),
                                child: Text(
                                  '${(Localization.translate('my_learning') ?? '').trim() != 'my_learning' && (Localization.translate('my_learning') ?? '').trim().isNotEmpty ? Localization.translate('my_learning') : 'My Learning'}',
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
                                    builder: (context) => CourseTakingScreen(),
                                  ),
                                );
                              },
                            ),
                          ListTile(
                            splashColor: Colors.transparent,
                            leading: SvgPicture.asset(
                              AppImages.disputeIcon,
                              width: 20,
                              height: 20,
                              color: AppColors.greyColor(context),
                            ),
                            title: Transform.translate(
                              offset: const Offset(-10, 0.0),
                              child: Text(
                                '${(Localization.translate('dispute') ?? '').trim() != 'dispute' && (Localization.translate('dispute') ?? '').trim().isNotEmpty ? Localization.translate('dispute') : 'Dispute'}',
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
                                  builder: (context) => DisputeListing(),
                                ),
                              );
                            },
                          ),
                          if (role == "tutor")
                            ListTile(
                              splashColor: Colors.transparent,
                              leading: SvgPicture.asset(
                                AppImages.bookEducationIcon,
                                width: 20,
                                height: 20,
                              ),
                              title: Transform.translate(
                                offset: const Offset(-10, 0.0),
                                child: Text(
                                  Localization.translate("education"),
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
                                    builder:
                                        (context) => EducationalDetailsScreen(),
                                  ),
                                );
                              },
                            ),
                          if (role == "tutor")
                            ListTile(
                              splashColor: Colors.transparent,
                              leading: SvgPicture.asset(
                                AppImages.briefcase,
                                width: 20,
                                height: 20,
                                color: AppColors.greyColor(context),
                              ),
                              title: Transform.translate(
                                offset: const Offset(-10, 0.0),
                                child: Text(
                                  Localization.translate("experience"),
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
                                    builder:
                                        (context) => ExperienceDetailsScreen(),
                                  ),
                                );
                              },
                            ),
                          if (role == "tutor")
                            ListTile(
                              splashColor: Colors.transparent,
                              leading: SvgPicture.asset(
                                AppImages.certificateIcon,
                                width: 20,
                                height: 20,
                              ),
                              title: Transform.translate(
                                offset: const Offset(-10, 0.0),
                                child: Text(
                                  Localization.translate("certificate"),
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
                                    builder: (context) => CertificateDetail(),
                                  ),
                                );
                              },
                            ),
                          if (role == "tutor")
                            Divider(
                              color: AppColors.dividerColor,
                              height: 0,
                              thickness: 0.7,
                              indent: 15.0,
                              endIndent: 15.0,
                            ),
                          ListTile(
                            splashColor: Colors.transparent,
                            leading: SvgPicture.asset(
                              AppImages.settingIcon,
                              width: 20,
                              height: 20,
                              color: AppColors.greyColor(context),
                            ),
                            title: Transform.translate(
                              offset: const Offset(-10, 0.0),
                              child: Text(
                                Localization.translate("accounts"),
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
                                  builder: (context) => AccountSettings(),
                                ),
                              );
                            },
                          ),
                          if (role == "tutor")
                            ListTile(
                              splashColor: Colors.transparent,
                              leading: SvgPicture.asset(
                                AppImages.dollarIcon,
                                width: 20,
                                height: 20,
                                color: AppColors.greyColor(context),
                              ),
                              title: Transform.translate(
                                offset: const Offset(-10, 0.0),
                                child: Text(
                                  Localization.translate("payouts"),
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
                                    builder: (context) => PayoutsHistory(),
                                  ),
                                );
                              },
                            ),
                          if (role == "student")
                            ListTile(
                              splashColor: Colors.transparent,
                              leading: SvgPicture.asset(
                                AppImages.favorite,
                                width: 20,
                                height: 20,
                                color: AppColors.greyColor(context),
                              ),
                              title: Transform.translate(
                                offset: const Offset(-10, 0.0),
                                child: Text(
                                  Localization.translate("favorite_tutors"),
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
                                    builder:
                                        (context) => FavoritesTutorsScreen(),
                                  ),
                                );
                              },
                            ),
                          if (role == "student")
                            ListTile(
                              splashColor: Colors.transparent,
                              leading: SvgPicture.asset(
                                AppImages.invoicesIcon,
                                width: 20,
                                height: 22,
                                color: AppColors.greyColor(context),
                              ),
                              title: Transform.translate(
                                offset: const Offset(-10, 0.0),
                                child: Text(
                                  Localization.translate("invoices"),
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
                                    builder: (context) => InvoicesScreen(),
                                  ),
                                );
                              },
                            ),
                          if (role == "student")
                            ListTile(
                              splashColor: Colors.transparent,
                              leading: SvgPicture.asset(
                                AppImages.walletIcon,
                                width: 20,
                                height: 20,
                                color: AppColors.greyColor(context),
                              ),
                              title: Transform.translate(
                                offset: const Offset(-10, 0.0),
                                child: Text(
                                  Localization.translate("billing"),
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
                                    builder: (context) => BillingInformation(),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(right: 15, left: 15),
                      child: Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final userData = authProvider.userData;

                          String rawBalance =
                              userData?['user']?['balance']?.toString() ?? "";
                          String cleanedBalance =
                              rawBalance
                                  .replaceAll(RegExp(r'[\$,]'), "")
                                  .trim();

                          double balanceValue =
                              double.tryParse(cleanedBalance) ?? 0.0;

                          String displayBalance =
                              "\$" +
                              balanceValue
                                  .toStringAsFixed(2)
                                  .replaceAllMapped(
                                    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                                    (Match m) => "${m[1]},",
                                  );

                          return Container(
                            padding: EdgeInsets.all(10.0),
                            height: 55,
                            decoration: BoxDecoration(
                              color: AppColors.primaryWhiteColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      AppImages.walletIcon,
                                      width: 20,
                                      height: 20,
                                      color: AppColors.greyColor(context),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      Localization.translate("wallet_balance"),
                                      style: TextStyle(
                                        color: AppColors.greyColor(context),
                                        fontSize: FontSize.scale(context, 16),
                                        fontFamily: AppFontFamily.regularFont,
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  displayBalance ?? '',
                                  style: TextStyle(
                                    color: AppColors.blackColor,
                                    fontSize: FontSize.scale(context, 18),
                                    fontFamily: AppFontFamily.mediumFont,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(right: 15, left: 15),
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _logout,
                        icon: Icon(
                          Icons.power_settings_new,
                          color: AppColors.redColor,
                          size: 20.0,
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Localization.translate("logout"),
                              style: TextStyle(
                                color: AppColors.redColor,
                                fontFamily: AppFontFamily.regularFont,
                                fontSize: FontSize.scale(context, 16),
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                            if (isLoading) ...[
                              SizedBox(width: 10),
                              SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryGreen(context),
                                ),
                              ),
                            ],
                          ],
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          side: BorderSide(
                            color: AppColors.redBorderColor,
                            width: 0.7,
                          ),
                          backgroundColor: AppColors.redBackgroundColor,
                          minimumSize: Size(double.infinity, 50),
                          textStyle: TextStyle(
                            fontSize: FontSize.scale(context, 16),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
