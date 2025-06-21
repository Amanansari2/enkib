import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/presentation/view/auth/register_screen.dart';
import 'package:flutter_projects/presentation/view/auth/reset_password_screen.dart';
import 'package:flutter_projects/presentation/view/auth/social_auth/social_auth_register.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/settings_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import '../../../domain/api_structure/config/app_config.dart';
import '../tutor/search_tutors_screen.dart';

class LoginScreen extends StatefulWidget {
  final Map<String, dynamic>? registrationResponse;
  LoginScreen({this.registrationResponse});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  bool _isChecked = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isEmailValid = true;
  String _errorMessage = '';
  String _passwordErrorMessage = '';
  bool _isPasswordValid = true;
  bool _isLoading = false;
  late GoogleSignIn _googleSignIn;
  late String? enableSocialLogin;
  bool _onPressLoading = false;

  static bool isValidEmail(String email) {
    bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
    return emailValid;
  }

  void _validateEmailAndSubmit() async {
    String email = _emailController.text;
    String password = _passwordController.text;

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
      if (password.isEmpty) {
        _passwordErrorMessage = Localization.translate(
          'passwordShouldNotBeEmpty',
        );
        _isPasswordValid = false;
      } else if (password.length < 6) {
        _passwordErrorMessage = Localization.translate('passwordAtLeast6');
        _isPasswordValid = false;
      } else {
        _passwordErrorMessage = '';
        _isPasswordValid = true;
      }
    });

    if (_isEmailValid && _isPasswordValid) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await loginUser(email, password);
        final String token = response['data']['token'];
        final Map<String, dynamic> userData = response['data'];
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        await authProvider.setToken(token);
        await authProvider.setUserData(userData);

        setState(() {
          _isLoading = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SearchTutorsScreen()),
        );

        _emailController.clear();
        _passwordController.clear();
        showCustomToast(context, response['message'], true);
      } catch (error) {
        showCustomToast(context, "${error.toString()}", false);

        setState(() {
          _isEmailValid = false;
          _isPasswordValid = false;
          _isLoading = false;
        });
        final errorMessage = error.toString();
        if (errorMessage.contains("Not verified")) {
          showCustomToast(
            context,
            "${Localization.translate("verify_email").isNotEmpty == true ? Localization.translate("verify_email") : "Kindly verify your email first"}",
            false,
          );
          _openBottomSheet(context);
        }
      }
    } else {
      if (!_isEmailValid) {
        _emailFocusNode.requestFocus();
      } else if (!_isPasswordValid) {
        _passwordFocusNode.requestFocus();
      }
    }
  }

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

  Future<void> handleResendEmail({required StateSetter setModalState}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String? _token = authProvider.token;

    if (_token != null) {
      try {
        setModalState(() {
          _onPressLoading = true;
        });

        final response = await resendEmail(_token);
        if (response['status'] == 200) {
          setModalState(() {
            _onPressLoading = false;
          });
          Navigator.pop(context);
          showCustomToast(context, response['message'], true);
        } else if (response['status'] == 403) {
          setModalState(() {
            _onPressLoading = false;
          });
          Navigator.pop(context);
          showCustomToast(context, response['message'], false);
        } else if (response['status'] == 401) {
          setModalState(() {
            _onPressLoading = false;
          });
          Navigator.pop(context);
          showCustomToast(context, response['message'], false);
        }
      } catch (error) {
        setModalState(() {
          _onPressLoading = false;
        });
        showCustomToast(context, 'Error: Failed to resend email.', false);
      }
    } else {
      setModalState(() {
        _onPressLoading = false;
      });
    }
  }

  void _initializeGoogleSignIn() {
    final clientId =
        AppConfig()
            .settings?['data']?['_api']?['social_google_client_id_android'];

    final clientIdIOS =
        AppConfig().settings?['data']?['_api']?['social_google_client_id_ios'];

    final serverClientId =
        AppConfig().settings?['data']?['_api']?['social_google_client_id'];

    if (clientId != null && clientId.isNotEmpty) {
      _googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? clientIdIOS : clientId,
        serverClientId: serverClientId,
        scopes: ['email', 'profile', 'openid'],
      );
    } else {}
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;

      if (currentUser != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userData = {
          'email': currentUser.email,
          'displayName': currentUser.displayName,
          'photoUrl': currentUser.photoUrl,
          'id': currentUser.id,
        };

        await authProvider.setUserData(userData);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SearchTutorsScreen()),
        );

        setState(() {
          _isLoading = false;
        });
        return;
      }

      await _googleSignIn.signOut();

      final GoogleSignInAccount? user = await _googleSignIn.signIn();

      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final authCode = user.serverAuthCode;

      if (authCode != null) {
        try {
          final response = await socialLogin(authCode);
          if (response['status'] == 200) {
            final String token = response['data']['token'];
            final Map<String, dynamic> userData = response['data'];
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );

            await authProvider.setToken(token);
            await authProvider.setUserData(userData);

            showCustomToast(
              context,
              response['message'] ?? "User Login Successfully.",
              true,
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SearchTutorsScreen()),
            );
          } else if (response['status'] == 422) {
            setState(() {
              _isLoading = false;
            });
            showCustomToast(context, response['message'], false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SocialAuthScreen(user: user),
              ),
            );
          } else if (response['status'] == 401) {
            setState(() {
              _isLoading = false;
            });
            showCustomToast(context, response['message'], false);
          } else if (response['status'] == 403) {
            setState(() {
              _isLoading = false;
            });
            showCustomToast(context, response['message'], false);
          } else {
            showCustomToast(
              context,
              'Unexpected error occurred. Please try again.',
              false,
            );
          }
        } catch (error) {
          setState(() {
            _isLoading = false;
          });
          showCustomToast(context, 'Login Failed: $error', false);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        throw Exception('Server auth code is null');
      }
    } catch (error) {
      showCustomToast(context, 'Sign-In Failed: $error', false);
      setState(() {
        _isLoading = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: AppColors.backgroundColor(context),
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.21,
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.topBottomSheetDismissColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      Localization.translate('emailVerification'),
                      style: TextStyle(
                        fontSize: FontSize.scale(context, 18),
                        color: AppColors.blackColor,
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(8.0),
                      color: AppColors.whiteColor,
                    ),
                    child: ElevatedButton(
                      onPressed:
                          _onPressLoading
                              ? null
                              : () {
                                handleResendEmail(setModalState: setModalState);
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen(context),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Localization.translate('resendEmail'),
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 16),
                              color: AppColors.whiteColor,
                              fontFamily: AppFontFamily.mediumFont,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          if (_onPressLoading) ...[
                            SizedBox(width: 10),
                            SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.whiteColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _saveTokenToProvider(String token) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setAuthToken(token);
  }

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    if (widget.registrationResponse != null) {
      final String? token = widget.registrationResponse?['data']['token'];
      if (token != null) {
        _saveTokenToProvider(token);
      } else {}
    }

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final appLogo = AppImages.getDynamicAppLogo(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    enableSocialLogin =
        settingsProvider.getSetting('data')?['_api']?['enable_social_login'] ??
        '0';

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
                                  builder: (context) => SearchTutorsScreen(),
                                ),
                                (Route<dynamic> route) => false,
                              );
                            },
                            style: ButtonStyle(
                              overlayColor: MaterialStateProperty.all(
                                Colors.transparent,
                              ),
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
                                    fontStyle: FontStyle.normal,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(height: 124),
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
                                Column(
                                  children: [
                                    Text(
                                      '${(Localization.translate('loginToYourAccount') ?? '').trim() != 'loginToYourAccount' && (Localization.translate('loginToYourAccount') ?? '').trim().isNotEmpty ? Localization.translate('loginToYourAccount') : 'Login to your account'}',
                                      style: TextStyle(
                                        fontFamily: AppFontFamily.boldFont,
                                        fontWeight: FontWeight.w700,
                                        fontSize: FontSize.scale(context, 24),
                                        color: AppColors.blackColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: height * 0.01),
                                    Text(
                                      '${(Localization.translate('accessCourses') ?? '').trim() != 'accessCourses' && (Localization.translate('accessCourses') ?? '').trim().isNotEmpty ? Localization.translate('accessCourses') : 'Access courses, manage your schedule, and stay connected.'}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: AppFontFamily.regularFont,
                                        fontWeight: FontWeight.w400,
                                        fontSize: FontSize.scale(context, 16),
                                        color: AppColors.greyColor(context),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: height * 0.12),
                                CustomTextField(
                                  hint: Localization.translate('emailAddress'),
                                  obscureText: false,
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  hasError: !_isEmailValid,
                                ),
                                if (_errorMessage.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: height * 0.01,
                                    ),
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(
                                        color: AppColors.redColor,
                                      ),
                                    ),
                                  ),
                                SizedBox(height: height * 0.02),
                                CustomTextField(
                                  hint: Localization.translate('password'),
                                  obscureText: true,
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  hasError: !_isPasswordValid,
                                ),
                                if (_passwordErrorMessage.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: height * 0.01,
                                    ),
                                    child: Text(
                                      _passwordErrorMessage,
                                      style: TextStyle(
                                        color: AppColors.redColor,
                                      ),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Transform.translate(
                                      offset: Offset(-10, 0),
                                      child: Transform.scale(
                                        scale: 1.3,
                                        child: Checkbox(
                                          value: _isChecked,
                                          checkColor: AppColors.whiteColor,
                                          activeColor: AppColors.primaryGreen(
                                            context,
                                          ),
                                          fillColor:
                                              MaterialStateProperty.resolveWith<
                                                Color
                                              >((states) {
                                                if (states.contains(
                                                  MaterialState.selected,
                                                )) {
                                                  return AppColors.primaryGreen(
                                                    context,
                                                  );
                                                }
                                                return AppColors.whiteColor;
                                              }),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              5.0,
                                            ),
                                          ),
                                          side: BorderSide(
                                            color: AppColors.dividerColor,
                                            width: 1.5,
                                          ),
                                          onChanged: (bool? value) {
                                            setState(() {
                                              _isChecked = value ?? false;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Transform.translate(
                                        offset: Offset(-12, 0),
                                        child: Text(
                                          Localization.translate('rememberMe'),
                                          style: TextStyle(
                                            fontSize: FontSize.scale(
                                              context,
                                              16,
                                            ),
                                            color: AppColors.greyColor(context),
                                            fontFamily:
                                                AppFontFamily.regularFont,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => ResetPassword(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        Localization.translate(
                                          'forgetPassword',
                                        ),
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 16),
                                          color: AppColors.greyColor(context),
                                          fontFamily: AppFontFamily.mediumFont,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: height * 0.024),
                                ElevatedButton(
                                  onPressed: _validateEmailAndSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen(
                                      context,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 15,
                                    ),
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
                                if (enableSocialLogin == '1') ...[
                                  SizedBox(height: height * 0.024),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          thickness: 1,
                                          color: AppColors.greyColor(
                                            context,
                                          ).withOpacity(0.3),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Text(
                                          Localization.translate(
                                                    "sign_in_wth",
                                                  ).isNotEmpty ==
                                                  true
                                              ? Localization.translate(
                                                "sign_in_wth",
                                              )
                                              : "Or sign in with",
                                          style: TextStyle(
                                            color: AppColors.greyColor(context),
                                            fontSize: FontSize.scale(
                                              context,
                                              16,
                                            ),
                                            fontFamily:
                                                AppFontFamily.regularFont,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          thickness: 1,
                                          color: AppColors.greyColor(
                                            context,
                                          ).withOpacity(0.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: height * 0.024),
                                  GestureDetector(
                                    onTap: _handleGoogleSignIn,
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 8,
                                      ),
                                      decoration: ShapeDecoration(
                                        color: AppColors.whiteColor,
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            width: 1,
                                            color: AppColors.dividerColor,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            AppImages.googleIcon,
                                            width: 20,
                                            height: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            Localization.translate(
                                                      "sign_in_google",
                                                    ).isNotEmpty ==
                                                    true
                                                ? Localization.translate(
                                                  "sign_in_google",
                                                )
                                                : "Sign in with Google",
                                            style: TextStyle(
                                              color: AppColors.greyColor(
                                                context,
                                              ),
                                              fontSize: FontSize.scale(
                                                context,
                                                16,
                                              ),
                                              fontFamily:
                                                  AppFontFamily.mediumFont,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                SizedBox(height: height * 0.024),
                                Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 15.0,
                                      horizontal: 16.0,
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        text:
                                            Localization.translate(
                                                      "account_unavailable",
                                                    ).isNotEmpty ==
                                                    true
                                                ? Localization.translate(
                                                  "account_unavailable",
                                                )
                                                : "Don’t have an account?",
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 14),
                                          color: AppColors.greyColor(context),
                                          fontFamily: AppFontFamily.mediumFont,
                                          fontWeight: FontWeight.w500,
                                          fontStyle: FontStyle.normal,
                                        ),
                                        children: [
                                          TextSpan(text: " "),
                                          TextSpan(
                                            text:
                                                Localization.translate(
                                                          "sign_up",
                                                        ).isNotEmpty ==
                                                        true
                                                    ? Localization.translate(
                                                      "sign_up",
                                                    )
                                                    : "Sign up",
                                            style: TextStyle(
                                              fontSize: FontSize.scale(
                                                context,
                                                14,
                                              ),
                                              color: AppColors.greyColor(
                                                context,
                                              ),
                                              fontFamily:
                                                  AppFontFamily.mediumFont,
                                              fontWeight: FontWeight.w500,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationThickness: 1,
                                              fontStyle: FontStyle.normal,
                                              height: 1.1,
                                            ),
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = () {
                                                    Navigator.pushReplacement(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                                RegistrationScreen(),
                                                      ),
                                                    );
                                                  },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: height * 0.02),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
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
  }
}
