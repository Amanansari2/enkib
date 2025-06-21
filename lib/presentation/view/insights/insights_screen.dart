import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/presentation/view/insights/skeleton/insight_screen_skeleton.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../base_components/custom_toast.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import '../auth/login_screen.dart';
import '../components/login_required_alert.dart';
import 'component/custom_field.dart';
import 'component/payout_method.dart';
import 'component/wallet_balance_card.dart';


class InsightScreen extends StatefulWidget {
  InsightScreen({
    Key? key,
  }) : super(key: key);

  @override
  _InsightScreenState createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController routingController = TextEditingController();
  final TextEditingController ibanController = TextEditingController();
  final TextEditingController swiftController = TextEditingController();

  late double screenWidth;
  late double screenHeight;
  int? _selectedCardIndex;
  Map<String, dynamic>? _payoutStatus;

  IconData _appBarIcon = Icons.arrow_back_ios;
  bool _isLoading = true;

  Map<String, dynamic> _earningDetails = {
    'earned_amount': 0,
    'wallet_balance': 0,
    'pending_withdrawals': 0,
    'completed_withdrawals': 0,
    'pending_balance': 0
  };

  TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isEmailValid = true;
  String _errorMessage = '';

  String getFormattedAmount(dynamic value) {
    if (value == null) return '\$0.00';
    double? numericValue =
        double.tryParse(value.toString().replaceAll(RegExp(r'[^\d.]'), ''));
    return numericValue != null
        ? '\$${numericValue.toStringAsFixed(2)}'
        : '\$0.00';
  }

  @override
  void initState() {
    super.initState();
    _fetchEarningDetails();
    _fetchPayoutStatus();
    _fetchGraphData();
  }

  List<ChartData> graphData = [];
  double yAxisMax = 0.0;
  double yAxisInterval = 20.0;

  Future<void> _fetchGraphData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token != null) {
      try {
        setState(() {
          _isLoading = true;
        });

        final response = await getEarningDetails(token);

        graphData.clear();
        final earnings = response['data']?['earnings'];

        if (earnings is Map<String, dynamic> && earnings.isNotEmpty) {
          double maxValue = 0;

          earnings.forEach((day, value) {
            double earningsValue = (value as num).toDouble();
            if (earningsValue > 0) {
              int dayInt = int.parse(day);
              graphData.add(ChartData(dayInt, earningsValue));
              maxValue = earningsValue > maxValue ? earningsValue : maxValue;
            }
          });

          yAxisMax = (maxValue + 39) ~/ 40 * 40.0;

          if (maxValue <= 50) {
            yAxisInterval = 10;
          } else if (maxValue > 50 && maxValue <= 100) {
            yAxisInterval = 20;
          } else if (maxValue > 100 && maxValue <= 150) {
            yAxisInterval = 30;
          } else if (maxValue > 150) {
            yAxisInterval = 100;
          }
        } else {
          yAxisMax = 50;
          yAxisInterval = 10;
        }
      } catch (e) {
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchEarningDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;

    if (token != null && userId != null) {
      try {
        final response = await getMyEarnings(token, userId);
        setState(() {
          _earningDetails = response['data'];
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPayoutStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token != null) {
      try {
        final response = await getPayoutStatus(token);

        setState(() {
          _payoutStatus = response['data'];
          _isLoading = false;
        });
        if (response['status'] == 401) {
          showCustomToast(context,
              '${Localization.translate("unauthorized_access")}', false);
          setState(() {
            _isLoading = false;
          });
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
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getButtonTitle(String payoutMethod) {
    if (_payoutStatus != null && _payoutStatus![payoutMethod] != null) {
      return '${
          Localization.translate("remove_account").isNotEmpty == true
              ? Localization.translate("remove_account")
              : '${
              Localization.translate("remove_account").isNotEmpty == true
                  ? Localization.translate("remove_account")
                  : '${
                  Localization.translate("remove_account").isNotEmpty == true
                      ? Localization.translate("remove_account")
                      : "Remove Account"
              }'
          }'
      }';
    }
    return '${Localization.translate("setup_account")}';
  }

  Future<void> _deletePayoutMethod(int index, String method) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await deletePayoutMethod(token, method);
        if (response['status'] == 200) {
          showCustomToast(
            context,
            response['message'],
            true,
          );

          setState(() {
            _payoutStatus![method] = null;
          });
        } else if (response['status'] == 403) {
          showCustomToast(
            context,
            response['message'],
            false,
          );
        } else if (response['status'] == 401) {
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
            'Failed to delete payout method: ${response['message']}',
            false,
          );
        }
      } catch (error) {
        showCustomToast(
          context,
          'Error occurred while deleting payout method: $error',
          false,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      showCustomToast(
        context,
        '${Localization.translate("unauthorized_access")}',
        false,
      );
    }
  }

  void showDeleteConfirmation(BuildContext context, int index, String method) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.trashBgColor,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  AppImages.trashIcon,
                  height: 30,
                  color: AppColors.redColor,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '${Localization.translate("remove_alert_message")}',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: FontSize.scale(context, 20),
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.normal,
                    fontFamily: AppFontFamily.mediumFont
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '${Localization.translate("remove_item_text")}',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 14),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.normal,
                      fontFamily: AppFontFamily.mediumFont),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side:
                            BorderSide(color: AppColors.dividerColor, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        child: Text(
                          '${Localization.translate("cancel")}',
                          style: TextStyle(
                              fontSize: FontSize.scale(context, 16),
                              color: AppColors.greyColor(context),
                              fontFamily: AppFontFamily.mediumFont),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _deletePayoutMethod(index, method);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.redBackgroundColor,
                      side: BorderSide(
                        color: AppColors.redBorderColor,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                    ),
                    child: Text(
                      '${Localization.translate("delete_text")}',
                      style: TextStyle(
                        fontSize: FontSize.scale(context, 14),
                        color: AppColors.redColor,
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _onButtonTap(int index, String buttonTitle) {
    final method = index == 0
        ? 'paypal'
        : index == 1
            ? 'payoneer'
            : 'bank';

    if (buttonTitle == '${
        Localization.translate("remove_account").isNotEmpty == true
            ? Localization.translate("remove_account")
            : "Remove Account"
    }') {
      showDeleteConfirmation(context, index, method);
    } else if (method == 'bank') {
      _bankAccountBottomSheet(index, buttonTitle);
    } else {
      showModalBottomSheet(
        isScrollControlled: true,
        backgroundColor: AppColors.sheetBackgroundColor,
        context: context,
        builder: (context) {
          return Directionality(
            textDirection: Localization.textDirection,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.4,
                  minChildSize: 0.3,
                  maxChildSize: 0.9,
                  builder: (context, scrollController) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0),
                          ),
                        ),
                        height: screenHeight,
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            SizedBox(height: 10),
                            Text(
                              '${Localization.translate("setup_account")}',
                              style: TextStyle(
                                fontSize: FontSize.scale(context, 18),
                                color: AppColors.blackColor,
                                fontFamily: AppFontFamily.mediumFont,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                            SizedBox(height: 16),
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                controller: scrollController,
                                children: [
                                  CustomTextField(
                                    hint:
                                        '${Localization.translate("insight_mail_label")}',
                                    obscureText: false,
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    hasError: !_isEmailValid,
                                    mandatory: true,
                                  ),
                                  if (_errorMessage.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        _errorMessage,
                                        style: TextStyle(
                                            color: AppColors.redColor),
                                      ),
                                    ),
                                  SizedBox(height: 16),
                                  _isLoading
                                      ? Center(
                                          child: SizedBox(
                                          width: 20.0,
                                          height: 20.0,
                                          child: CircularProgressIndicator(
                                            color:
                                                AppColors.primaryGreen(context),
                                            strokeWidth: 2.0,
                                          ),
                                        ))
                                      : ElevatedButton(
                                          onPressed: () async {
                                            final accountEmail =
                                                _emailController.text;

                                            if (accountEmail.isEmpty) {
                                              setState(() {
                                                _errorMessage =
                                                    '${Localization.translate("field_required")}';
                                              });
                                              return;
                                            }

                                            setState(() {
                                              _errorMessage = '';
                                              _isLoading = true;
                                            });

                                            final payoutData = {
                                              'email': accountEmail,
                                              'current_method': method,
                                            };

                                            final authProvider =
                                                Provider.of<AuthProvider>(
                                                    context,
                                                    listen: false);
                                            final token = authProvider.token;

                                            if (token != null) {
                                              final response =
                                                  await payoutMethod(
                                                      token, payoutData);

                                              if (response['status'] == 200) {
                                                showCustomToast(
                                                  context,
                                                  response['message'],
                                                  true,
                                                );

                                                await _fetchEarningDetails();
                                                await _fetchPayoutStatus();

                                                Navigator.pop(context);
                                                _emailController.clear();
                                              } else if (response['status'] ==
                                                  403) {
                                                showCustomToast(
                                                  context,
                                                  response['message'],
                                                  false,
                                                );
                                              } else if (response['status'] ==
                                                  401) {
                                                showCustomToast(
                                                    context,
                                                    '${Localization.translate("unauthorized_access")}',
                                                    false);
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder:
                                                      (BuildContext context) {
                                                    return CustomAlertDialog(
                                                      title: Localization
                                                          .translate(
                                                              'invalidToken'),
                                                      content: Localization
                                                          .translate(
                                                              'loginAgain'),
                                                      buttonText: Localization
                                                          .translate(
                                                              'goToLogin'),
                                                      buttonAction: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  LoginScreen()),
                                                        );
                                                      },
                                                      showCancelButton: false,
                                                    );
                                                  },
                                                );
                                              } else {
                                                showCustomToast(
                                                  context,
                                                  response['message'],
                                                  false,
                                                );
                                              }
                                            }

                                            setState(() {
                                              _isLoading = false;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryGreen(context),
                                            minimumSize:
                                                Size(double.infinity, 50),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                          ),
                                          child: Text(
                                            '${Localization.translate("save_update")}',
                                            style: TextStyle(
                                              fontSize:
                                                  FontSize.scale(context, 16),
                                              color: AppColors.whiteColor,
                                              fontFamily: AppFontFamily.mediumFont,
                                              fontWeight: FontWeight.w500,
                                              fontStyle: FontStyle.normal,
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      );
    }
  }

  void _bankAccountBottomSheet(int index, String buttonTitle) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    Map<String, String> _errorMessages = {};

    if (buttonTitle == '${Localization.translate("setup_account")}') {
      showModalBottomSheet(
        backgroundColor: AppColors.sheetBackgroundColor,
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Directionality(
            textDirection: Localization.textDirection,
            child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.6,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  builder: (context, scrollController) {
                    return SingleChildScrollView(
                        controller: scrollController,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.sheetBackgroundColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10.0),
                              topRight: Radius.circular(10.0),
                            ),
                          ),
                          padding: EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 5,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.topBottomSheetDismissColor,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  '${Localization.translate("bank_account")}',
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 18),
                                    color: AppColors.blackColor,
                                    fontFamily: AppFontFamily.mediumFont,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
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
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 10),
                                      CustomField(
                                        controller: titleController,
                                        labelText:
                                            '${Localization.translate("account_title")}',
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return '${Localization.translate("field_required")}';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 10),
                                      CustomField(
                                        controller: numberController,
                                        labelText:
                                            '${Localization.translate("bank_account_number")}',
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (_errorMessages['accountNumber'] !=
                                              null) {
                                            return _errorMessages[
                                                'accountNumber'];
                                          }
                                          if (value == null || value.isEmpty) {
                                            return '${Localization.translate("field_required")}';
                                          }
                                          if (value.length < 8 ||
                                              value.length > 20) {
                                            return 'The account number must be between 8 and 20 digits.';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 10),
                                      CustomField(
                                        controller: nameController,
                                        labelText:
                                            '${Localization.translate("bank_account_name")}',
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return '${Localization.translate("field_required")}';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 10),
                                      CustomField(
                                        controller: routingController,
                                        labelText:
                                            '${Localization.translate("bank_routing_number")}',
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (_errorMessages[
                                                  'bankRoutingNumber'] !=
                                              null) {
                                            return _errorMessages[
                                                'bankRoutingNumber'];
                                          }
                                          if (value == null || value.isEmpty) {
                                            return '${Localization.translate("field_required")}';
                                          }
                                          if (value.length != 9) {
                                            return '${Localization.translate("bank_routing_message")}';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 10),
                                      CustomField(
                                        controller: ibanController,
                                        labelText:
                                            '${Localization.translate("bank_iban_number")}',
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return '${Localization.translate("field_required")}';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 10),
                                      CustomField(
                                        controller: swiftController,
                                        labelText:
                                            '${Localization.translate("bank_swift")}',
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return '${Localization.translate("field_required")}';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 10),
                                      _isLoading
                                          ? Center(
                                              child: CircularProgressIndicator(
                                              color: AppColors.primaryGreen(
                                                  context),
                                            ))
                                          : ElevatedButton(
                                              onPressed: () async {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  setState(() {
                                                    _isLoading = true;
                                                  });

                                                  final Map<String, dynamic>
                                                      payoutData = {
                                                    'title':
                                                        titleController.text,
                                                    'bankName':
                                                        nameController.text,
                                                    'bankRoutingNumber':
                                                        routingController.text,
                                                    'bankIban':
                                                        ibanController.text,
                                                    'bankBtc':
                                                        swiftController.text,
                                                    'current_method': 'bank',
                                                    'accountNumber':
                                                        numberController.text,
                                                  };

                                                  final authProvider =
                                                      Provider.of<AuthProvider>(
                                                          context,
                                                          listen: false);
                                                  final token =
                                                      authProvider.token;

                                                  if (token != null) {
                                                    final response =
                                                        await payoutMethod(
                                                            token, payoutData);

                                                    if (response['status'] ==
                                                        200) {
                                                      showCustomToast(
                                                        context,
                                                        response['message'],
                                                        true,
                                                      );

                                                      await _fetchEarningDetails();
                                                      await _fetchPayoutStatus();

                                                      Navigator.pop(context);
                                                    } else if (response[
                                                                'status'] ==
                                                            400 &&
                                                        response['errors'] !=
                                                            null) {
                                                      setState(() {
                                                        _errorMessages =
                                                            response['errors'];
                                                      });
                                                    } else if (response[
                                                            'status'] ==
                                                        403) {
                                                      showCustomToast(
                                                        context,
                                                        response['message'],
                                                        false,
                                                      );
                                                    } else if (response[
                                                            'status'] ==
                                                        401) {
                                                      showCustomToast(
                                                          context,
                                                          '${Localization.translate("unauthorized_access")}',
                                                          false);
                                                      showDialog(
                                                        context: context,
                                                        barrierDismissible:
                                                            false,
                                                        builder: (BuildContext
                                                            context) {
                                                          return CustomAlertDialog(
                                                            title: Localization
                                                                .translate(
                                                                    'invalidToken'),
                                                            content: Localization
                                                                .translate(
                                                                    'loginAgain'),
                                                            buttonText: Localization
                                                                .translate(
                                                                    'goToLogin'),
                                                            buttonAction: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            LoginScreen()),
                                                              );
                                                            },
                                                            showCancelButton:
                                                                false,
                                                          );
                                                        },
                                                      );
                                                    } else {
                                                      showCustomToast(
                                                        context,
                                                        '${Localization.translate("failed_update_bank_details")} ${response['message']}',
                                                        false,
                                                      );
                                                    }
                                                  }
                                                  setState(() {
                                                    _isLoading = false;
                                                  });
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primaryGreen(
                                                        context),
                                                minimumSize:
                                                    Size(double.infinity, 50),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0),
                                                ),
                                              ),
                                              child: Text(
                                                '${Localization.translate("save_update")}',
                                                style: TextStyle(
                                                  fontSize: FontSize.scale(
                                                      context, 16),
                                                  color: AppColors.whiteColor,
                                                  fontFamily:
                                                      AppFontFamily.mediumFont,
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle: FontStyle.normal,
                                                ),
                                              ),
                                            ),
                                      SizedBox(height: 20),
                                      Text(
                                        "${Localization.translate("bank_detail_message")}",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 14),
                                          color: AppColors.greyColor(context)
                                              .withOpacity(0.7),
                                          fontFamily: AppFontFamily.mediumFont,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ));
                  },
                ),
              );
            }),
          );
        },
      );
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
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    bool areAllPayoutMethodsActive =
        _payoutStatus?['payoneer']?['status'] == 'active' ||
            _payoutStatus?['bank']?['status'] == 'active' ||
            _payoutStatus?['paypal']?['status'] == 'active';

    bool isWalletBalanceAvailable =
        _earningDetails.containsKey('wallet_balance') &&
            _earningDetails['wallet_balance'] != null;

    String walletBalance =
        _earningDetails['wallet_balance']?.toString() ?? '\$0.00';

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    return WillPopScope(
      onWillPop: () async {
        return !_isLoading;
      },
      child: Directionality(
        textDirection: Localization.textDirection,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.backgroundColor(context),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(80.0),
            child: Container(
              color: AppColors.whiteColor,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: AppBar(
                  backgroundColor: AppColors.whiteColor,
                  forceMaterialTransparency: true,
                  leading: IconButton(
                    icon: Icon(
                      _appBarIcon,
                      color: AppColors.blackColor,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  centerTitle: false,
                  elevation: 0,
                  titleSpacing: 0,
                  title: Text(
                    '${Localization.translate("earning_title")}',
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      color: AppColors.blackColor,
                      fontSize: FontSize.scale(context, 20),
                      fontFamily: AppFontFamily.mediumFont,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: _isLoading
              ? InsightScreenSkeleton()
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: screenHeight * 0.23,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                String amount;
                                String title;
                                String backgroundImage;
                                String iconPath;

                                if (index == 0) {
                                  amount = getFormattedAmount(
                                      _earningDetails['earned_amount']);
                                  title =
                                      '${Localization.translate("earned_income")}';
                                  backgroundImage = AppImages.insightsBg;
                                  iconPath = AppImages.insightsIcon;
                                } else if (index == 1) {
                                  amount = getFormattedAmount(
                                      _earningDetails['wallet_balance']);
                                  title =
                                      '${Localization.translate("wallet_balance")}';
                                  backgroundImage = AppImages.walletBalanceBg;
                                  iconPath = AppImages.walletBalanceIcon;
                                } else if (index == 2) {
                                  amount = getFormattedAmount(
                                      _earningDetails['pending_balance']);
                                  title =
                                      '${Localization.translate("pending_amount")}';
                                  backgroundImage = AppImages.pendingAmountBg;
                                  iconPath = AppImages.clockInsightIcon;
                                } else if (index == 3) {
                                  amount = getFormattedAmount(
                                      _earningDetails['completed_withdrawals']);
                                  title =
                                      '${Localization.translate("wallet_funds")}';
                                  backgroundImage = AppImages.walletFundsBg;
                                  iconPath = AppImages.dollarInsightIcon;
                                } else {
                                  amount = getFormattedAmount(
                                      _earningDetails['pending_withdrawals']);
                                  title =
                                      '${Localization.translate("pending_withdraw")}';
                                  backgroundImage = AppImages.withdrawBg;
                                  iconPath = AppImages.pendingWithDrawIcon;
                                }

                                return earningCard(
                                  backgroundImage: backgroundImage,
                                  iconPath: iconPath,
                                  title: title,
                                  amount: amount,
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            '${Localization.translate("earning_details_title")}',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 16),
                              fontFamily: AppFontFamily.mediumFont,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.greyColor(context)
                                      .withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(12.0),
                              color: AppColors.whiteColor,
                            ),
                            padding: EdgeInsets.only(
                              top: 20,
                              left: 8,
                              right: 8,
                              bottom: 12,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                padding: EdgeInsets.only(
                                    left: Localization.textDirection ==
                                            TextDirection.rtl
                                        ? 2
                                        :10.0,
                                    top: 10,
                                    right: 20),
                                width: MediaQuery.of(context).size.width * 2,
                                child: LineChart(
                                  LineChartData(
                                    minX: Localization.textDirection ==
                                        TextDirection.rtl?0.3:1,
                                    maxX: 31,
                                    minY: -5,
                                    maxY: yAxisMax,
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize:
                                              Localization.textDirection ==
                                                      TextDirection.rtl
                                                  ? 35
                                                  : 50,
                                          interval: yAxisInterval,
                                          getTitlesWidget: (value, meta) {
                                            if (value >= 0 &&
                                                value % yAxisInterval == 0) {
                                              return Text(
                                                value.toInt().toString(),
                                                style: TextStyle(
                                                  color: AppColors.greyColor(
                                                      context),
                                                  fontSize: FontSize.scale(
                                                      context, 14),
                                                  fontFamily:
                                                      AppFontFamily.mediumFont,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              );
                                            }
                                            return SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize:
                                              Localization.textDirection ==
                                                      TextDirection.rtl
                                                  ? 30
                                                  : 20,
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            if (value >= 1) {
                                              return Padding(
                                                padding: EdgeInsets.only(
                                                  left: Localization
                                                              .textDirection ==
                                                          TextDirection.rtl
                                                      ? 5
                                                      : 0,
                                                  right: Localization
                                                              .textDirection ==
                                                          TextDirection.rtl
                                                      ? 0
                                                      : 5,
                                                ),
                                                child: Text(
                                                  value.toInt().toString(),
                                                  style: TextStyle(
                                                    color: AppColors.greyColor(
                                                        context),
                                                    fontSize: FontSize.scale(
                                                        context, 12),
                                                    fontFamily:
                                                        AppFontFamily.mediumFont,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              );
                                            }
                                            return SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: true,
                                      getDrawingHorizontalLine: (value) =>
                                          FlLine(
                                        color: AppColors.dividerColor,
                                        strokeWidth: 1,
                                        dashArray: [5, 5],
                                      ),
                                      getDrawingVerticalLine: (value) => FlLine(
                                        color: AppColors.dividerColor,
                                        strokeWidth: 1,
                                        dashArray: [5, 5],
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: graphData
                                            .map((data) => FlSpot(
                                                data.x.toDouble(),
                                                data.y.toDouble()))
                                            .toList(),
                                        isCurved: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primaryGreen(context),
                                            AppColors.primaryGreen(context)
                                                .withOpacity(0.8),
                                          ],
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primaryGreen(context)
                                                  .withOpacity(0.3),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter:
                                              (spot, percent, barData, index) =>
                                                  FlDotCirclePainter(
                                            radius: 4,
                                            color:
                                                AppColors.primaryGreen(context),
                                            strokeWidth: 2,
                                            strokeColor: AppColors.whiteColor,
                                          ),
                                        ),
                                        barWidth: 2,
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      touchTooltipData: LineTouchTooltipData(
                                        tooltipRoundedRadius: 8,
                                        tooltipPadding: EdgeInsets.all(8),
                                        tooltipMargin: 8,
                                        fitInsideHorizontally: true,
                                        fitInsideVertically: true,
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots
                                              .map((LineBarSpot touchedSpot) {
                                            return LineTooltipItem(
                                              '${touchedSpot.y.toStringAsFixed(2)}',
                                              TextStyle(
                                                color: AppColors.whiteColor,
                                                fontSize:
                                                    FontSize.scale(context, 12),
                                                backgroundColor:
                                                    AppColors.blackColor,
                                              ),
                                            );
                                          }).toList();
                                        },
                                      ),
                                      handleBuiltInTouches: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            '${Localization.translate("setup_payout_methods")}',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                                color: AppColors.greyColor(context),
                                fontSize: FontSize.scale(context, 16),
                                fontFamily: AppFontFamily.mediumFont,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                PayoutMethodCard(
                                  index: 0,
                                  imagePath: AppImages.paypal,
                                  title:
                                      '${Localization.translate("paypal_balance")}',
                                  amount: _payoutStatus != null &&
                                          _payoutStatus!['balance']
                                                  ?['paypal'] !=
                                              null
                                      ? '${_payoutStatus!['balance']!['paypal'].toString()}'
                                      : '\$0',
                                  buttonTitle: _getButtonTitle('paypal'),
                                  onButtonTap: _onButtonTap,
                                  onCardTap: (index) {
                                    setState(() {
                                      _selectedCardIndex = index;
                                    });
                                  },
                                  selectedCardIndex: _selectedCardIndex,
                                  isActive: _payoutStatus != null &&
                                      _payoutStatus!['paypal']?['status'] ==
                                          'active',
                                ),
                                SizedBox(width: 16),
                                PayoutMethodCard(
                                  index: 1,
                                  imagePath: AppImages.payoneer,
                                  title:
                                      '${Localization.translate("payoneer_balance")}',
                                  amount: _payoutStatus != null &&
                                          _payoutStatus!['balance']
                                                  ?['payoneer'] !=
                                              null
                                      ? '${_payoutStatus!['balance']!['payoneer'].toString()}'
                                      : '\$0',
                                  buttonTitle: _getButtonTitle('payoneer'),
                                  onButtonTap: _onButtonTap,
                                  onCardTap: (index) {
                                    setState(() {
                                      _selectedCardIndex = index;
                                    });
                                  },
                                  selectedCardIndex: _selectedCardIndex,
                                  isActive: _payoutStatus != null &&
                                      _payoutStatus!['payoneer']?['status'] ==
                                          'active',
                                ),
                                SizedBox(width: 16),
                                PayoutMethodCard(
                                  index: 2,
                                  imagePath: AppImages.bankTransfer,
                                  title:
                                      '${Localization.translate("bank_transfer")}',
                                  amount: _payoutStatus != null &&
                                          _payoutStatus!['balance']?['bank'] !=
                                              null
                                      ? '${_payoutStatus!['balance']!['bank'].toString()}'
                                      : '\$0',
                                  buttonTitle: _getButtonTitle('bank'),
                                  onButtonTap: _onButtonTap,
                                  onCardTap: (index) {
                                    setState(() {
                                      _selectedCardIndex = index;
                                    });
                                  },
                                  selectedCardIndex: _selectedCardIndex,
                                  isActive: _payoutStatus != null &&
                                      _payoutStatus!['bank']?['status'] ==
                                          'active',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 170,
                          )
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: WalletBalanceCard(
                        walletBalance: walletBalance,
                        areAllPayoutMethodsActive: areAllPayoutMethodsActive,
                        isWalletBalanceAvailable: isWalletBalanceAvailable,
                        token: token!,
                        onBalanceUpdated: (double updatedBalance) {
                          setState(() {
                            walletBalance =
                                '\$${updatedBalance.toStringAsFixed(2)}';
                          });
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget earningCard({
    required String backgroundImage,
    required String iconPath,
    required String title,
    required String amount,
  }) {
    return Container(
      width: screenWidth * 0.36,
      margin: EdgeInsets.only(right: 16),
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: 20,
                height: 20,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            amount,
            style: TextStyle(
              color: AppColors.whiteColor,
              fontSize: FontSize.scale(context, 15),
              fontFamily: AppFontFamily.mediumFont,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.normal,
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppColors.whiteColor,
              fontSize: FontSize.scale(context, 12),
              fontFamily: AppFontFamily.mediumFont,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}
