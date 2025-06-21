import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/presentation/view/auth/login_screen.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import '../components/internet_alert.dart';
import '../components/login_required_alert.dart';
import '../tutor/search_tutors_screen.dart';
import 'register_screen.dart';

class ResetPassword extends StatefulWidget {
  @override
  State<ResetPassword> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<ResetPassword>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isEmailValid = true;
  String _errorMessage = '';
  bool _isLoading = false;

  static bool isValidEmail(String email) {
    bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
    return emailValid;
  }

  void _forgetPassword() async {
    String email = _emailController.text;

    setState(() {
      if (email.isEmpty) {
        _errorMessage = Localization.translate('emailShouldNotBeEmpty');
        _isEmailValid = false;
      } else if (isValidEmail(email)) {
        _errorMessage = '';
        _isEmailValid = true;
      } else {
        _errorMessage = Localization.translate('invalidEmailAddress');
        _isEmailValid = false;
      }
    });

    if (_isEmailValid) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await forgetPassword(email);

        if (response['status'] == 200) {
          showCustomToast(context, response['message'], true);
        } else if (response['status'] == 403) {
          showCustomToast(context, response['message'], false);
        }  else if (response['status'] == 401) {
         showCustomToast(context,
              '${Localization.translate("unauthorized_access")}', false);
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
          showCustomToast(context, response['message'], false);
        }
      } catch (e) {
        showCustomToast(context, 'Failed to send email: $e', false);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

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
                body: SafeArea(
                  child: Column(
                    children: [
                      Align(
                        alignment: Localization.textDirection ==
                            TextDirection.rtl ? Alignment.topLeft : Alignment
                            .topRight,
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
                                      fontSize: FontSize.scale(context, 16),
                                      fontFamily: AppFontFamily.regularFont,
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal

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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 90),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(height: 70),
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
                                      SizedBox(height: 30.0),
                                      Text(
                                        Localization.translate('reset'),
                                        textScaler: TextScaler.noScaling,
                                        style: TextStyle(
                                            fontFamily: AppFontFamily.boldFont,
                                            fontWeight: FontWeight.w700,
                                            fontStyle: FontStyle.normal,
                                            fontSize: FontSize.scale(
                                                context, 24),
                                            color: AppColors.blackColor),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        Localization.translate('reset_info'),
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
                                      SizedBox(height: 50.0),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 70,
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomTextField(
                                      hint: Localization.translate(
                                          'emailAddress'),
                                      obscureText: false,
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                      hasError: !_isEmailValid,
                                    ),
                                    if (_errorMessage.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 8.0),
                                        child: Text(
                                          _errorMessage,
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                              color: AppColors.redColor),
                                        ),
                                      ),
                                    SizedBox(height: 20.0),
                                    ElevatedButton(
                                      onPressed: _forgetPassword,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isLoading
                                            ? AppColors.fadeColor
                                            : AppColors.primaryGreen(context),
                                        minimumSize: Size(double.infinity, 55),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            Localization.translate('send_link'),
                                            style: TextStyle(
                                              fontSize: FontSize.scale(
                                                  context, 16),
                                              color: _isLoading
                                                  ? AppColors.greyColor(context)
                                                  : AppColors.whiteColor,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: AppFontFamily
                                                  .mediumFont,
                                              fontStyle: FontStyle.normal,
                                            ),
                                          ),
                                          if (_isLoading) ...[
                                            SizedBox(width: 10),
                                            SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primaryGreen(
                                                    context),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 16.0),
                                    Container(
                                      width: double.infinity,
                                      decoration: ShapeDecoration(
                                        color: AppColors.whiteColor,
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                              width: 1,
                                              color: AppColors.dividerColor),
                                          borderRadius: BorderRadius.circular(
                                              12),
                                        ),
                                      ),
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    RegistrationScreen()),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 15, horizontal: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                12),
                                          ),
                                          backgroundColor: AppColors.whiteColor,
                                        ),
                                        child: Text(
                                          Localization.translate(
                                              'account_unavailable'),
                                          style: TextStyle(
                                            color: AppColors.greyColor(context),
                                            fontSize: FontSize.scale(
                                                context, 16),
                                            fontFamily: AppFontFamily
                                                .mediumFont,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 6.0),
                                    Center(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 15.0, horizontal: 16.0),
                                        child: RichText(
                                          text: TextSpan(
                                            text: Localization.translate(
                                                'already'),
                                            style: TextStyle(
                                              fontSize: FontSize.scale(
                                                  context, 14),
                                              color: AppColors.greyColor(
                                                  context),
                                              fontFamily: AppFontFamily
                                                  .mediumFont,
                                              fontWeight: FontWeight.w500,
                                              fontStyle: FontStyle.normal,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: Localization.translate(
                                                    'sign_in_now'),
                                                style: TextStyle(
                                                  fontSize: FontSize.scale(
                                                      context, 14),
                                                  fontFamily: AppFontFamily
                                                      .mediumFont,
                                                  color: AppColors.greyColor(
                                                      context),
                                                  decoration: TextDecoration
                                                      .underline,
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
                                    SizedBox(height: 20.0),
                                  ],
                                ),
                              ],
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
        },
    );
  }
}
