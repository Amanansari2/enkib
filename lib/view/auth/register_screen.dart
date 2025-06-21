import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/localization/localization.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/privacy_policy.dart';
import 'package:flutter_projects/view/auth/terms_conditions.dart';
import 'package:flutter_projects/view/components/login_required_alert.dart';
import 'package:flutter_projects/view/tutor/search_tutors_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../provider/settings_provider.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _numberFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isFirstNameValid = true;
  bool _isLastNameValid = true;
  bool _isEmailValid = true;
  bool _isNumberValid = true;
  bool _isPasswordValid = true;
  bool _isConfirmPasswordValid = true;
  String _isChecked = "";
  bool _isCheckboxValid = true;

  String _firstNameErrorMessage = '';
  String _lastNameErrorMessage = '';
  String _emailErrorMessage = '';
  String _numberErrorMessage = '';
  String _passwordErrorMessage = '';
  String _confirmPasswordErrorMessage = '';
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
    Future.delayed(const Duration(seconds: 2), () {
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
  }

  void _validateAndSubmit() async {
    String firstName = _firstNameController.text;
    String lastName = _lastNameController.text;
    String email = _emailController.text;
    String number = _numberController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    setState(() {
      if (firstName.isEmpty) {
        _firstNameErrorMessage = Localization.translate('firstName');
        _isFirstNameValid = false;
      } else {
        _firstNameErrorMessage = '';
        _isFirstNameValid = true;
      }

      if (lastName.isEmpty) {
        _lastNameErrorMessage = Localization.translate('lastName');
        _isLastNameValid = false;
      } else {
        _lastNameErrorMessage = '';
        _isLastNameValid = true;
      }

      if (email.isEmpty) {
        _emailErrorMessage = Localization.translate('emailShouldNotBeEmpty');
        _isEmailValid = false;
      } else if (!_isValidEmail(email)) {
        _emailErrorMessage = Localization.translate('invalidEmailAddress');
        _isEmailValid = false;
      } else {
        _emailErrorMessage = '';
        _isEmailValid = true;
      }

      if (_phoneNumberOnSignup == "yes") {
        if (number.isEmpty) {
          _numberErrorMessage = Localization.translate('phoneNumber');
          _isNumberValid = false;
        } else {
          _numberErrorMessage = '';
          _isNumberValid = true;
        }
      } else {
        _isNumberValid = true;
      }

      if (password.isEmpty) {
        _passwordErrorMessage =
            Localization.translate('passwordShouldNotBeEmpty');
        _isPasswordValid = false;
      } else if (password.length < 8) {
        _passwordErrorMessage = Localization.translate('passwordAtLeast8');
        _isPasswordValid = false;
      } else {
        _passwordErrorMessage = '';
        _isPasswordValid = true;
      }

      if (confirmPassword.isEmpty) {
        _confirmPasswordErrorMessage =
            Localization.translate('confirmPasswordShouldNotBeEmpty');
        _isConfirmPasswordValid = false;
      } else if (password != confirmPassword) {
        _confirmPasswordErrorMessage =
            Localization.translate('passwordAndConfirmMustMatch');
        _isConfirmPasswordValid = false;
      } else {
        _confirmPasswordErrorMessage = '';
        _isConfirmPasswordValid = true;
      }

      if (_isChecked.isEmpty) {
        showCustomToast(
            context, '${Localization.translate("aggree")}', false);
      }
    });

    if (_isFirstNameValid &&
        _isLastNameValid &&
        _isEmailValid &&
        _isNumberValid &&
        _isPasswordValid &&
        _isConfirmPasswordValid &&
        _isChecked.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      Map<String, dynamic> userData = {
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "password": password,
        "password_confirmation": confirmPassword,
        "user_role": role,
        "terms": _isChecked,
      };

      if (_phoneNumberOnSignup == "yes" && number.isNotEmpty) {
        userData["phone_number"] = number;
      }

      try {
        final responseData = await registerUser(userData);
        if (responseData['status'] == 403) {
          showCustomToast(context, responseData['message'], false);
        }

        if (responseData['status'] == 422) {
          showCustomToast(
              context,
              '${Localization.translate("email_taken")}',
              false);
        } else if (responseData['status'] == 401) {
          showCustomToast(
              context, '${Localization.translate("unauthorized_access")}', false);
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
        }

        showCustomToast(context,
            responseData['message'] ?? 'Registration successful', true);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              registrationResponse: responseData,
            ),
          ),
        );
      } catch (error) {
        if (error is Map<String, dynamic> && error.containsKey('message')) {
          showCustomToast(context, error['message'], false);
        } else {
          showCustomToast(
              context, 'Registration failed. Please try again.', false);
        }
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
        ?['student_display_name'];
    tutorName =
        settingsProvider.getSetting('data')?['_lernen']?['tutor_display_name'];

    final appLogo = AppImages.getDynamicAppLogo(context);

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
                                    builder: (context) => SearchTutorsScreen()),
                                (Route<dynamic> route) => false,
                              );
                            },
                            style: ButtonStyle(
                              overlayColor:
                                  MaterialStateProperty.all(Colors.transparent),
                              splashFactory: NoSplash.splashFactory,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  Localization.translate('skip'),
                                  style: TextStyle(
                                    color: AppColors.greyColor(context),
                                    fontSize: FontSize.scale(context, 15),
                                    fontFamily: AppFontFamily.font,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                SizedBox(height: 10),
                                appLogo.startsWith('http')
                                    ? Image.network(
                                        appLogo,
                                        width: 60,
                                        height: 110,
                                        alignment: Alignment.center,
                                      )
                                    : Image.asset(
                                        appLogo,
                                        width: 60,
                                        height: 110,
                                        alignment: Alignment.center,
                                      ),
                                SizedBox(height: 20),
                                Text(
                                  Localization.translate('create'),

                                  textScaler: TextScaler.noScaling,
                                  style: TextStyle(
                                    fontFamily: AppFontFamily.font,
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
                                   // Localization.translate('roleRegister'),

                                    "Join EnkiB as a Student or Tutor and Kickstart Your Educational Journey with Personalized Learning Today!",

                                    textScaler: TextScaler.noScaling,
                                    style: TextStyle(
                                      fontFamily: AppFontFamily.font,
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                      fontSize: FontSize.scale(context, 16),
                                      color: AppColors.greyColor(context),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: 60),
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
                                          if (_firstNameErrorMessage.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(
                                                _firstNameErrorMessage,
                                                style: TextStyle(
                                                    color: AppColors.redColor),
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
                                          if (_lastNameErrorMessage.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(
                                                _lastNameErrorMessage,
                                                style: TextStyle(
                                                    color: AppColors.redColor),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15),
                                CustomTextField(
                                  hint: Localization.translate('emailAddress'),
                                  obscureText: false,
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  hasError: !_isEmailValid,
                                ),
                                if (_emailErrorMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _emailErrorMessage,
                                      style:
                                          TextStyle(color: AppColors.redColor),
                                    ),
                                  ),
                                if (_phoneNumberOnSignup == "yes")
                                  Column(
                                    children: [
                                      SizedBox(height: 15),
                                      CustomTextField(
                                        hint: Localization.translate(
                                            "phoneNumber_field"),
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
                                SizedBox(height: 15),
                                CustomTextField(
                                  hint: Localization.translate('password'),
                                  obscureText: true,
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  hasError: !_isPasswordValid,
                                ),
                                if (_passwordErrorMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _passwordErrorMessage,
                                      style:
                                          TextStyle(color: AppColors.redColor),
                                    ),
                                  ),
                                SizedBox(height: 15),
                                CustomTextField(
                                  hint:
                                      Localization.translate('confirmPassword'),
                                  obscureText: true,
                                  controller: _confirmPasswordController,
                                  focusNode: _confirmPasswordFocusNode,
                                  hasError: !_isConfirmPasswordValid,
                                ),
                                if (_confirmPasswordErrorMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _confirmPasswordErrorMessage,
                                      style:
                                          TextStyle(color: AppColors.redColor),
                                    ),
                                  ),
                                SizedBox(height: 16),
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
                                                      ? AppColors.primaryGreen(
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
                                                          ? AppColors.whiteColor
                                                          : Colors.transparent,
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
                                                  fontFamily:
                                                      AppFontFamily.font,
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
                                                      ? AppColors.primaryGreen(
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
                                                          ? AppColors.whiteColor
                                                          : Colors.transparent,
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
                                                  fontFamily:
                                                      AppFontFamily.font,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            text:
                                                Localization.translate('agree'),
                                            style: TextStyle(
                                              fontSize:
                                                  FontSize.scale(context, 14),
                                              fontFamily: AppFontFamily.font,
                                              fontWeight: FontWeight.w400,
                                              color:
                                                  AppColors.greyColor(context),
                                            ),
                                            children: [
                                              TextSpan(
                                                text: Localization.translate(
                                                    'terms'),
                                                style: TextStyle(
                                                  fontSize: FontSize.scale(
                                                      context, 14),
                                                  fontFamily:
                                                      AppFontFamily.font,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppColors.blueColor,
                                                ),
                                                recognizer:
                                                    TapGestureRecognizer()
                                                       ..onTap = () async {
                                                      //   final Uri url =
                                                      //       Uri.parse(AppUrls
                                                      //           .termsConditionUrl);
                                                      //   if (await canLaunchUrl(
                                                      //       url)) {
                                                      //     await launchUrl(url);
                                                      //   } else {
                                                      //     throw 'Could not launch $url';
                                                      //   }
                                                        Navigator.push(
                                                            context, MaterialPageRoute(builder: (context)=> TermsConditionsScreen()));
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
                                                  fontFamily:
                                                      AppFontFamily.font,
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
                                                  fontFamily:
                                                      AppFontFamily.font,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppColors.blueColor,
                                                ),
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap = () async {
                                                        //final Uri url =
                                                        //     Uri.parse(AppUrls
                                                        //         .privacyPolicyUrl);
                                                        // if (await canLaunchUrl(
                                                        //     url)) {
                                                        //   await launchUrl(url);
                                                        // } else {
                                                        //   throw 'Could not launch $url';
                                                        // }

                                                        Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()));
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
                                    Localization.translate('join_now'),
                                    style: TextStyle(
                                      color: AppColors.blueColor,
                                      fontSize: FontSize.scale(context, 16),
                                      fontFamily: AppFontFamily.font,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 15.0, horizontal: 16.0),
                                    child: RichText(
                                      text: TextSpan(
                                        text: Localization.translate('already'),
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 16),
                                          color: AppColors.greyColor(context),
                                          fontFamily: AppFontFamily.font,
                                          fontWeight: FontWeight.w500,
                                          fontStyle: FontStyle.normal,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: Localization.translate(
                                                'sign_in_now'),
                                            style: TextStyle(
                                              fontSize:
                                                  FontSize.scale(context, 16),
                                              fontFamily: AppFontFamily.font,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  AppColors.greyColor(context),
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationThickness: 1,
                                              fontStyle: FontStyle.normal,
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
                        child: SpinKitCircle(
                          color: AppColors.primaryGreen(context),
                          size: 180,
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
  }
}
