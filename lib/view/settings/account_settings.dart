import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/localization/localization.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/components/login_required_alert.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../../provider/auth_provider.dart';

class AccountSettings extends StatefulWidget {
  @override
  _AccountSettingsState createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isPasswordValid = true;
  bool _isConfirmPasswordValid = true;
  String _passwordErrorMessage = '';
  String _confirmPasswordErrorMessage = '';

  late double screenWidth;
  late double screenHeight;
  bool _isLoading = false;

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

  void _updatePassword() async {
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    setState(() {
      if (password.isEmpty) {
        _passwordErrorMessage = "${Localization.translate('password_required')}";
        _isPasswordValid = false;
      } else if (password.length < 8) {
        _passwordErrorMessage =
        "${Localization.translate('passwordAtLeast8')}";
        _isPasswordValid = false;
      } else {
        _passwordErrorMessage = '';
        _isPasswordValid = true;
      }

      if (confirmPassword.isEmpty) {
        _confirmPasswordErrorMessage = "${Localization.translate('confirm_password_required')}";

        _isConfirmPasswordValid = false;
      } else if (password != confirmPassword) {
        _confirmPasswordErrorMessage = "${Localization.translate('passwordAndConfirmMustMatch')}";
        _isConfirmPasswordValid = false;
      } else {
        _confirmPasswordErrorMessage = '';
        _isConfirmPasswordValid = true;
      }
    });

    if (_isPasswordValid && _isConfirmPasswordValid) {
      setState(() {
        _isLoading = true;
      });

      Map<String, dynamic> userData = {
        "password": password,
        "confirm": confirmPassword,
      };

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;
        final userId = authProvider.userId;

        final responseData = await updatePassword(userData, token!, userId!);

        setState(() {
          _isLoading = false;
        });

        if (responseData['status'] == 200) {
          showCustomToast(context, responseData['message'], true);
          _passwordController.clear();
          _confirmPasswordController.clear();
        } else if (responseData['status'] == 403) {
          showCustomToast(context, responseData['message'], false);
        } else if (responseData['status'] == 401) {
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
          showCustomToast(context, responseData['message'], false);
        }
      } catch (error) {
        showCustomToast(
            context, '${Localization.translate('password_error')} $error', false);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: Localization.textDirection,

      child: Scaffold(
        backgroundColor: AppColors.backgroundColor(context),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.0),
          child: Container(
            color: AppColors.whiteColor,
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: AppBar(
                backgroundColor: AppColors.whiteColor,
                forceMaterialTransparency: true,
                elevation: 0,
                titleSpacing: 0,
                title: Text(
                  '${Localization.translate('accounts')}',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: FontSize.scale(context, 20),
                    fontFamily: AppFontFamily.font,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.arrow_back_ios,
                        size: 20, color: AppColors.blackColor),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                centerTitle: false,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 10,
                ),
                Container(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${Localization.translate('change_password')}',
                        style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 16),
                          fontFamily: AppFontFamily.font,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      SizedBox(height: 15),
                      CustomTextField(
                        hint: '${Localization.translate('enter_new_password')}',
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
                            style: TextStyle(color: AppColors.redColor),
                          ),
                        ),
                      SizedBox(height: 15),
                      CustomTextField(
                        hint: '${Localization.translate('retype_new_password')}',
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
                            style: TextStyle(color: AppColors.redColor),
                          ),
                        ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _updatePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen(context),
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${Localization.translate('update')}',
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                fontSize: FontSize.scale(context, 16),
                                color: AppColors.whiteColor,
                                fontFamily: AppFontFamily.font,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                            if (_isLoading) SizedBox(width: 10),
                            if (_isLoading)
                              SpinKitCircle(
                                  color: AppColors.blueColor,
                              size: 40,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
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
