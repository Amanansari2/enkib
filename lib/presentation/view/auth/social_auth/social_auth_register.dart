import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/localization/localization.dart';
import '../../../../data/provider/auth_provider.dart';
import '../../../../data/provider/connectivity_provider.dart';
import '../../../../data/provider/settings_provider.dart';
import '../../../../domain/api_structure/api_service.dart';
import '../../components/internet_alert.dart';
import '../../tutor/search_tutors_screen.dart';
import '../login_screen.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';

class SocialAuthScreen extends StatefulWidget {
  final GoogleSignInAccount user;
  const SocialAuthScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<SocialAuthScreen> createState() => _SocialAuthScreenState();
}

class _SocialAuthScreenState extends State<SocialAuthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _numberController = TextEditingController();

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _numberFocusNode = FocusNode();

  bool _isFirstNameValid = true;
  bool _isLastNameValid = true;
  bool _isEmailValid = true;
  bool _isNumberValid = true;
  String _isChecked = "";
  bool _isCheckboxValid = true;

  String _firstNameErrorMessage = '';
  String _lastNameErrorMessage = '';
  String _emailErrorMessage = '';
  String _numberErrorMessage = '';

  String role = 'student';

  bool _isLoading = false;

  String _phoneNumberOnSignup = "no";

  late String studentName = "";
  late String tutorName = "";

  bool _isValidEmail(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  @override
  void dispose() {
    _controller.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _numberController.dispose();
    super.dispose();
  }

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
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _controller.repeat(reverse: true);

    _firstNameController = TextEditingController(
      text: widget.user.displayName?.split(' ').first ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.user.displayName?.split(' ').last ?? '',
    );
    _emailController = TextEditingController(
      text: widget.user.email,
    );
  }

  void _validateAndSubmit() async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String email = _emailController.text.trim();
    String number = _numberController.text.trim();

    setState(() {
      _isFirstNameValid = firstName.isNotEmpty;
      _firstNameErrorMessage =
          _isFirstNameValid ? '' : Localization.translate('firstName');

      _isLastNameValid = lastName.isNotEmpty;
      _lastNameErrorMessage =
          _isLastNameValid ? '' : Localization.translate('lastName');

      _isEmailValid = email.isNotEmpty && _isValidEmail(email);
      _emailErrorMessage = !_isEmailValid
          ? (email.isEmpty
              ? Localization.translate('emailShouldNotBeEmpty')
              : Localization.translate('invalidEmailAddress'))
          : '';

      if (_phoneNumberOnSignup == "yes") {
        _isNumberValid = number.isNotEmpty;
        _numberErrorMessage =
            _isNumberValid ? '' : Localization.translate('phoneNumber');
      } else {
        _isNumberValid = true;
      }

      if (_isChecked.isEmpty) {
        showCustomToast(
          context,
          Localization.translate("aggree"),
          false,
        );
      }
    });

    if (_isFirstNameValid &&
        _isLastNameValid &&
        _isEmailValid &&
        _isNumberValid &&
        _isChecked.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await socialProfile(
          email,
          firstName,
          lastName,
          number,
          role,
          _isChecked,
        );

        if (response['status'] == 200) {
          final String token = response['data']['token'];
          final Map<String, dynamic> userData = response['data'];
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          await authProvider.setToken(token);
          await authProvider.setUserData(userData);
          setState(() {
            _isLoading = false;
          });
          showCustomToast(
            context,
            response['message'] ?? 'Registration successful',
            true,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SearchTutorsScreen()),
          );
        } else if (response['status'] == 403) {
          setState(() {
            _isLoading = false;
          });
          showCustomToast(context, response['message'], false);
        } else if (response['status'] == 422) {
          setState(() {
            _isLoading = false;
          });
          showCustomToast(
            context,
            Localization.translate("email_taken"),
            false,
          );
        } else {
          showCustomToast(
            context,
            'Unexpected error occurred. Please try again.',
            false,
          );
        }
      } catch (error) {
        showCustomToast(
          context,
          'Registration failed. Please try again.',
          false,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    final settingsProvider = Provider.of<SettingsProvider>(context);
    _phoneNumberOnSignup = settingsProvider.getSetting('data')?['_lernen']
        ?['phone_number_on_signup'];
    studentName = settingsProvider.getSetting('data')?['_lernen']
            ?['student_display_name'] ??
        'Student';
    tutorName = settingsProvider.getSetting('data')?['_lernen']
            ?['tutor_display_name'] ??
        'Tutor';

    final appLogo = AppImages.getDynamicAppLogo(context);

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
          if (_isLoading) {
            return false;
          } else {
            return true;
          }
        },
        child: Directionality(
          textDirection: Localization.textDirection,
          child: Scaffold(
            backgroundColor: AppColors.backgroundColor(context),
            body: Container(
              height: height,
              child: Stack(
                children: [
                  SafeArea(
                    child: Column(
                      children: [
                        Align(
                          alignment:
                              Localization.textDirection == TextDirection.rtl
                                  ? Alignment.topLeft
                                  : Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10, right: 20),
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          SearchTutorsScreen()),
                                  (Route<dynamic> route) => false,
                                );
                              },
                              style: ButtonStyle(
                                overlayColor: MaterialStateProperty.all(
                                    Colors.transparent),
                                splashFactory: NoSplash.splashFactory,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    Localization.translate('skip'),
                                    style: TextStyle(
                                        color: AppColors.greyColor(context),
                                        fontSize: FontSize.scale(context, 16),
                                        fontFamily: AppFontFamily.regularFont,
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.normal),
                                  ),
                                  SizedBox(width: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: SvgPicture.asset(
                                      Localization.textDirection ==
                                              TextDirection.rtl
                                          ? AppImages.backArrow
                                          : AppImages.forwardArrow,
                                      width: 15,
                                      height: 15,
                                      color: AppColors.greyColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 90),
                                  appLogo.startsWith('http')
                                      ? (appLogo.endsWith('.svg')
                                          ? SvgPicture.network(
                                              appLogo,
                                              width: 70,
                                              height: 70,
                                              alignment: Alignment.center,
                                            )
                                          : Image.network(
                                              appLogo,
                                              width: 100,
                                              height: 100,
                                              alignment: Alignment.center,
                                              fit: BoxFit.contain,
                                            ))
                                      : SvgPicture.asset(
                                          AppImages.logo,
                                          width: 70,
                                          height: 70,
                                          alignment: Alignment.center,
                                        ),
                                  SizedBox(height: 20),
                                  Text(
                                    Localization.translate("almost_there_text")
                                                .isNotEmpty ==
                                            true
                                        ? Localization.translate(
                                            "almost_there_text")
                                        : "Almost there",
                                    textScaler: TextScaler.noScaling,
                                    style: TextStyle(
                                      fontFamily: AppFontFamily.boldFont,
                                      fontWeight: FontWeight.w700,
                                      fontStyle: FontStyle.normal,
                                      fontSize: FontSize.scale(context, 24),
                                      color: AppColors.blackColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0),
                                    child: Text(
                                      Localization.translate(
                                                      "create_account_details")
                                                  .isNotEmpty ==
                                              true
                                          ? Localization.translate(
                                              "create_account_details")
                                          : "Just a few more details to create your account.",
                                      textScaler: TextScaler.noScaling,
                                      style: TextStyle(
                                        fontFamily: AppFontFamily.regularFont,
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.normal,
                                        fontSize: FontSize.scale(context, 16),
                                        color: AppColors.greyColor(context),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(height: 30),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            CustomTextField(
                                              hint: Localization.translate(
                                                  'firstName'),
                                              obscureText: false,
                                              controller: _firstNameController,
                                              focusNode: _firstNameFocusNode,
                                              hasError: !_isFirstNameValid,
                                            ),
                                            if (_firstNameErrorMessage
                                                .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8.0),
                                                child: Text(
                                                  _firstNameErrorMessage,
                                                  style: TextStyle(
                                                      color:
                                                          AppColors.redColor),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            CustomTextField(
                                              hint: Localization.translate(
                                                  'lastName'),
                                              obscureText: false,
                                              controller: _lastNameController,
                                              focusNode: _lastNameFocusNode,
                                              hasError: !_isLastNameValid,
                                            ),
                                            if (_lastNameErrorMessage
                                                .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8.0),
                                                child: Text(
                                                  _lastNameErrorMessage,
                                                  style: TextStyle(
                                                      color:
                                                          AppColors.redColor),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 15),
                                  CustomTextField(
                                    hint:
                                        Localization.translate('emailAddress'),
                                    obscureText: false,
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    hasError: !_isEmailValid,
                                    readOnly: true,
                                  ),
                                  if (_emailErrorMessage.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        _emailErrorMessage,
                                        style: TextStyle(
                                            color: AppColors.redColor),
                                      ),
                                    ),
                                  if (_phoneNumberOnSignup == "yes")
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 15),
                                        CustomTextField(
                                          hint: Localization.translate(
                                              "phone_number_label"),
                                          controller: _numberController,
                                          focusNode: _numberFocusNode,
                                          hasError: !_isNumberValid,
                                          keyboardType: TextInputType.number,
                                        ),
                                        if (_numberErrorMessage.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              _numberErrorMessage,
                                              style: TextStyle(
                                                  color: AppColors.redColor),
                                            ),
                                          ),
                                      ],
                                    ),
                                  SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          Localization.translate("role")
                                                      .isNotEmpty ==
                                                  true
                                              ? Localization.translate("role")
                                              : "Role",
                                          style: TextStyle(
                                            fontSize:
                                                FontSize.scale(context, 16),
                                            fontFamily:
                                                AppFontFamily.regularFont,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.greyColor(context),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 2,
                                        ),
                                        SvgPicture.asset(
                                          AppImages.mandatory,
                                          height: 12.0,
                                          color: AppColors.redColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                role = (role == 'student')
                                                    ? ''
                                                    : 'student';
                                              });
                                            },
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: role == 'student'
                                                        ? AppColors
                                                            .primaryGreen(
                                                                context)
                                                        : AppColors.whiteColor,
                                                    border: Border.all(
                                                      color: role == 'student'
                                                          ? Colors.transparent
                                                          : AppColors
                                                              .dividerColor,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Container(
                                                      width: 9,
                                                      height: 9,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: role == 'student'
                                                            ? AppColors
                                                                .whiteColor
                                                            : Colors
                                                                .transparent,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  studentName ?? "",
                                                  style: TextStyle(
                                                    fontSize: FontSize.scale(
                                                        context, 16),
                                                    fontFamily: AppFontFamily
                                                        .regularFont,
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.greyColor(
                                                        context),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 20),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                role = (role == 'tutor')
                                                    ? ''
                                                    : 'tutor';
                                              });
                                            },
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: role == 'tutor'
                                                        ? AppColors
                                                            .primaryGreen(
                                                                context)
                                                        : AppColors.whiteColor,
                                                    border: Border.all(
                                                      color: role == 'tutor'
                                                          ? Colors.transparent
                                                          : AppColors
                                                              .dividerColor,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Container(
                                                      width: 9,
                                                      height: 9,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: role == 'tutor'
                                                            ? AppColors
                                                                .whiteColor
                                                            : Colors
                                                                .transparent,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  tutorName,
                                                  style: TextStyle(
                                                    fontSize: FontSize.scale(
                                                        context, 16),
                                                    fontFamily: AppFontFamily
                                                        .regularFont,
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.greyColor(
                                                        context),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Transform.translate(
                                        offset: Offset(-10.0, -12.0),
                                        child: Transform.scale(
                                          scale: 1.3,
                                          child: Checkbox(
                                            value: _isChecked == 'accepted',
                                            checkColor: AppColors.whiteColor,
                                            activeColor:
                                                AppColors.primaryGreen(context),
                                            fillColor: MaterialStateProperty
                                                .resolveWith<Color>((states) {
                                              if (states.contains(
                                                  MaterialState.selected)) {
                                                return AppColors.primaryGreen(
                                                    context);
                                              }
                                              return AppColors.whiteColor;
                                            }),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                            ),
                                            side: BorderSide(
                                              color: _isCheckboxValid
                                                  ? AppColors.dividerColor
                                                  : AppColors.redColor,
                                              width: 1,
                                            ),
                                            onChanged: (bool? value) {
                                              setState(() {
                                                _isChecked =
                                                    value! ? 'accepted' : '';
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Transform.translate(
                                          offset: Offset(-12, 0),
                                          child: RichText(
                                            text: TextSpan(
                                              text: Localization.translate(
                                                  'agree'),
                                              style: TextStyle(
                                                fontSize:
                                                    FontSize.scale(context, 14),
                                                fontFamily:
                                                    AppFontFamily.regularFont,
                                                fontWeight: FontWeight.w400,
                                                color: AppColors.greyColor(
                                                    context),
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: Localization.translate(
                                                      'terms'),
                                                  style: TextStyle(
                                                    fontSize: FontSize.scale(
                                                        context, 14),
                                                    fontFamily: AppFontFamily
                                                        .regularFont,
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.blueColor,
                                                  ),
                                                  recognizer:
                                                      TapGestureRecognizer()
                                                        ..onTap = () async {
                                                          final Uri url =
                                                              Uri.parse(AppUrls
                                                                  .termsConditionUrl);
                                                          if (await canLaunchUrl(
                                                              url)) {
                                                            await launchUrl(
                                                                url);
                                                          } else {
                                                            throw 'Could not launch $url';
                                                          }
                                                        },
                                                ),
                                                TextSpan(
                                                  text: ' ',
                                                ),
                                                TextSpan(
                                                  text: Localization.translate(
                                                      'and'),
                                                  style: TextStyle(
                                                    fontSize: FontSize.scale(
                                                        context, 14),
                                                    fontFamily: AppFontFamily
                                                        .regularFont,
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.greyColor(
                                                        context),
                                                    height: 1.7,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: Localization.translate(
                                                      'privacy'),
                                                  style: TextStyle(
                                                    fontSize: FontSize.scale(
                                                        context, 14),
                                                    fontFamily: AppFontFamily
                                                        .regularFont,
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.blueColor,
                                                  ),
                                                  recognizer:
                                                      TapGestureRecognizer()
                                                        ..onTap = () async {
                                                          final Uri url =
                                                              Uri.parse(AppUrls
                                                                  .privacyPolicyUrl);
                                                          if (await canLaunchUrl(
                                                              url)) {
                                                            await launchUrl(
                                                                url);
                                                          } else {
                                                            throw 'Could not launch $url';
                                                          }
                                                        },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: _validateAndSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen(context),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      Localization.translate("setup_account")
                                                  .isNotEmpty ==
                                              true
                                          ? Localization.translate(
                                              "setup_account")
                                          : "Setup Account",
                                      style: TextStyle(
                                        color: AppColors.whiteColor,
                                        fontSize: FontSize.scale(context, 16),
                                        fontFamily: AppFontFamily.mediumFont,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 15.0, horizontal: 16.0),
                                      child: RichText(
                                        text: TextSpan(
                                          text:
                                              Localization.translate('already'),
                                          style: TextStyle(
                                            fontSize:
                                                FontSize.scale(context, 14),
                                            color: AppColors.greyColor(context),
                                            fontFamily:
                                                AppFontFamily.mediumFont,
                                            fontWeight: FontWeight.w500,
                                            fontStyle: FontStyle.normal,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: Localization.translate(
                                                  'sign_in_now'),
                                              style: TextStyle(
                                                fontSize:
                                                    FontSize.scale(context, 14),
                                                color: AppColors.greyColor(
                                                    context),
                                                fontFamily:
                                                    AppFontFamily.mediumFont,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationThickness: 1,
                                                fontStyle: FontStyle.normal,
                                                height: 1,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            LoginScreen()),
                                                  );
                                                },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.grey.withOpacity(0.5),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen(context),
                          ),
                        ),
                      ),
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
