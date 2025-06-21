import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_projects/animated_screen/animated_thank_you.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/api_structure/config/app_config.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/localization/localization.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/bookSession/skeleton/payment_screen_skeleton.dart';
import 'package:flutter_projects/view/components/bottom_sheet.dart';
import 'package:flutter_projects/view/components/login_required_alert.dart';
import 'package:flutter_projects/view/web_view/payment_webview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../provider/auth_provider.dart';
import '../../provider/connectivity_provider.dart';
import '../../provider/settings_provider.dart';
import '../components/internet_alert.dart';

class PaymentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartData;
  final Map<String, dynamic> sessionData;

  const PaymentScreen({
    Key? key,
    required this.cartData,
    required this.sessionData,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _companyTitleController = TextEditingController();
  final TextEditingController _emailAddressController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _companyTitleFocusNode = FocusNode();
  final FocusNode _emailAddressFocusNode = FocusNode();
  final FocusNode _numberFocusNode = FocusNode();
  final FocusNode _countryFocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _zipFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _stateFocusNode = FocusNode();

  bool _isFirstNameValid = true;
  bool _isLastNameValid = true;
  bool _isEmailValid = true;
  bool _isPhoneNumberValid = true;
  bool _isCountryValid = true;
  bool _isCityValid = true;
  bool _isZipCodeValid = true;
  bool _isStateValid = true;
  bool _isChecked = false;

  String _firstNameError = '';
  String _lastNameError = '';
  String _emailError = '';
  String _phoneError = '';
  String _countryError = '';
  String _cityError = '';
  String _zipCodeError = '';
  String _isStateError = '';

  List<String> _countries = [];
  Map<int, String> _countryMap = {};
  int? _selectedCountryId;
  String? _selectedCountry;
  bool _allFieldsFilled = false;

  String? _selectedState;
  List<String> _states = [];
  Map<int, String> _statesMap = {};

  bool _isStateFieldVisible = false;

  bool _isLoading = true;
  bool _onPressLoading = false;
  bool _refreshLoading = false;


  String _paymentMethod = '';

  List<Map<String, dynamic>> _paymentMethods = [];

  late double screenWidth;
  late double screenHeight;


  void initState() {
    super.initState();
    _fetchBillingDetail();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _firstNameController.text = authProvider.firstName ?? '';
    _lastNameController.text = authProvider.lastName ?? '';
    _emailAddressController.text = authProvider.email ?? '';
    _numberController.text = authProvider.phone ?? '';
    _countryController.text = authProvider.country ?? '';
    _stateController.text = authProvider.state ?? '';
    _cityController.text = authProvider.city ?? '';
    _zipController.text = authProvider.zipCode ?? '';
    _descriptionController.text = authProvider.description ?? '';
    _companyTitleController.text = authProvider.company ?? '';

    _firstNameController.addListener(() {
      authProvider.setFirstName(_firstNameController.text);
    });
    _lastNameController.addListener(() {
      authProvider.setLastName(_lastNameController.text);
    });
    _emailAddressController.addListener(() {
      authProvider.setEmail(_emailAddressController.text);
    });
    _numberController.addListener(() {
      authProvider.setPhone(_numberController.text);
    });
    _countryController.addListener(() {
      authProvider.setCountry(_countryController.text);
    });
    _stateController.addListener(() {
      authProvider.setState(_stateController.text);
    });
    _cityController.addListener(() {
      authProvider.setCity(_cityController.text);
    });
    _zipController.addListener(() {
      authProvider.setZipCode(_zipController.text);
    });
    _descriptionController.addListener(() {
      authProvider.setDescription(_descriptionController.text);
    });
    _companyTitleController.addListener(() {
      authProvider.setCompany(_companyTitleController.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchCountries();
      await _fetchData();

      if (_selectedCountryId != null) {
        await _fetchStates(_selectedCountryId!);
      }
    });
  }


Future<void> _fetchBillingDetail() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final token = authProvider.token;
  final userId = authProvider.userId;
print("userId -->> $userId");
  if (token != null && userId != null) {
    try {
      final response = await getBillingDetail(token, userId);
      print("response -->> $response");
      final billingDetailData = response['data']['billingDetail'] as Map<
          String,
          dynamic>?;
      print("Billing detail data --->> $billingDetailData");
      final billingDetailAddressData = billingDetailData?['address'] as Map<
          String,
          dynamic>?;
print("Billing detail address data --->> $billingDetailAddressData");
      if (billingDetailData != null && billingDetailAddressData != null) {
        setState(() {
          _firstNameController.text = billingDetailData['first_name'] ?? '';
          _lastNameController.text = billingDetailData['last_name'] ?? '';
          _companyTitleController.text = billingDetailData['company'] ?? '';
          _emailAddressController.text = billingDetailData['email'] ?? '';
          _numberController.text = billingDetailData['phone'] ?? '';
          _countryController.text =
              billingDetailAddressData['country']['name'] ?? '';
          _cityController.text = billingDetailAddressData['city'] ?? '';
          _zipController.text = billingDetailAddressData['zipcode'] ?? '';
          _stateController.text =
              billingDetailAddressData['state']['name'] ?? '';
        });
      }
    } catch (e) {
      showCustomToast(context, 'Failed to fetch billing details', false);
    } finally {
      setState(() => _isLoading = false);
    }
  } else {
    setState(() => _isLoading = false);
  }
}

  Future<void> _fetchData() async {
    setState(() {
      _refreshLoading = true;
    });
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    try {
      AppConfig().clearSettingsCache();
      final settings = await AppConfig().getSettings();
      settingsProvider.setSettings(settings);
    } catch (e) {}
    _initializePaymentMethods();

    setState(() {
      _refreshLoading = false;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailAddressController.dispose();
    _numberController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _descriptionController.dispose();
    _companyTitleController.dispose();
    super.dispose();
  }

  Future<void> _fetchCountries() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await getCountries(token!);
      final countriesData = response['data'];
      setState(() {
        _countries = countriesData.map<String>((country) {
          _countryMap[country['id']] = country['name'];
          return country['name'] as String;
        }).toList();
      });
    } catch (e) {}
  }

  Future<void> _fetchStates(int countryId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await getCountryStates(token!, countryId);
      final statesData = response['data'];
      setState(() {
        _states = statesData.map<String>((state) {
          _statesMap[state['id']] = state['name'];
          return state['name'] as String;
        }).toList();

        _isStateFieldVisible = _states.isNotEmpty;
        if (_isStateFieldVisible && _selectedState != null) {
          _stateController.text = _selectedState!;
        } else {
          _stateController.clear();
        }
      });
    } catch (e) {
      setState(() {
        _isStateFieldVisible = false;
      });
    }
  }

  void _showCountryBottomSheet(TextEditingController countryController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BottomSheetComponent(
              title: "${Localization.translate("select_country")}",
              items: _countries,
              selectedItem: _selectedCountry,
              onItemSelected: (selectedItem) async {
                setModalState(() {
                  _selectedCountry = selectedItem;
                  countryController.text = selectedItem;
                  _selectedCountryId = _countryMap.entries
                      .firstWhere((entry) => entry.value == selectedItem)
                      .key;
                });

                if (_selectedCountryId != null) {
                  await _fetchStates(_selectedCountryId!);
                }
              },
            );
          },
        );
      },
    );
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

  Future<void> _payOut() async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String emailAddress = _emailAddressController.text.trim();
    String phoneNumber = _numberController.text.trim();
    String country = _countryController.text.trim();
    String state = _stateController.text.trim();
    String city = _cityController.text.trim();
    String zipCode = _zipController.text.trim();
    String company = _companyTitleController.text.trim();
    String description = _descriptionController.text.trim();
    double totalAmount = _calculateTotal();
    int? zipCodeInt = int.tryParse(zipCode);

    setState(() {
      _isFirstNameValid = firstName.isNotEmpty;
      _isLastNameValid = lastName.isNotEmpty;
      _isEmailValid = emailAddress.isNotEmpty && emailAddress.contains('@');
      _isPhoneNumberValid = phoneNumber.isNotEmpty;
      _isCountryValid = country.isNotEmpty;
      _isStateValid = state.isNotEmpty;
      _isCityValid = city.isNotEmpty;
      _isZipCodeValid = zipCodeInt != null;
    });

    if (_isFirstNameValid &&
        _isLastNameValid &&
        _isEmailValid &&
        _isPhoneNumberValid &&
        _isCountryValid &&
        _isCityValid &&
        _isStateValid &&
        _isZipCodeValid) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        setState(() {
          _onPressLoading = true;
        });

        Map<String, dynamic> data = {
          'firstName': firstName,
          'lastName': lastName,
          'paymentMethod': _paymentMethod,
          'phone': phoneNumber,
          'email': emailAddress,
          'country': country,
          'state': state,
          'zipcode': zipCodeInt,
          'city': city,
          'description': description,
          'company': company,
          'useWalletBalance': _isChecked,
          'amount': totalAmount.toString(),
        };


        print("Data --->>> $data");

        try {
          final response = await postCheckOut(token, data);

print("Response --->> $response");
          if (response['status'] == 200) {
            final paymentStatus = response['data']['payment_status'];
            final paymentUrl = response['data']['payment_url'];
            final cancelMessage =
                response['message'] ?? "${Localization.translate("payment_cancelled")}";

            if (paymentStatus == 'completed') {
              _navigateToThankYouPage();
            } else if (paymentStatus == 'pending') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentWebView(
                    url: paymentUrl,
                    onPaymentSuccess: _navigateToThankYouPage,
                    onPaymentCancelled: (message) {
                      showCustomToast(context, message, false);
                      Navigator.pop(context);
                    },
                    cancelMessage: cancelMessage,
                  ),
                ),
              );
            } else {
              showCustomToast(
                  context, response['message'] ?? "${Localization.translate("payment_processing")}", true);
            }
          }

          else if (response['status'] == 403) {
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
          }
          else {
            String errorMessage =
                _getValidationErrors(response['errors'] ?? {});
            showCustomToast(context, errorMessage, false);
          }
        } catch (e) {
          showCustomToast(context, '${Localization.translate("error_message")}', false);
        } finally {
          setState(() {
            _onPressLoading = false;
          });
        }
      } else {
        showCustomToast(context, '${Localization.translate("unauthorized_access")}', false);
      }
    } else {
      showCustomToast(
          context, '${Localization.translate("required_field")}', false);
    }
  }

  String _getValidationErrors(Map<String, dynamic> errors) {
    if (errors.isEmpty) return '${Localization.translate("required_field")}';

    return errors.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');
  }

  void _navigateToThankYouPage() {
    showCustomToast(context, "${Localization.translate("payment_completed")}", true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ThankYouPage()),
    );
  }

  double _calculateTotal() {
    return widget.cartData.fold(0.0, (sum, session) {
      String priceString = session['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
      double price = double.tryParse(priceString) ?? 0.0;
      return sum + price;
    });
  }

  void _initializePaymentMethods() async {
    setState(() {
      _isLoading = true;
    });

    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final settings = settingsProvider.settings;

    if (settings.isNotEmpty) {
      List<dynamic> paymentMethodsData =
          settings['data']['payment_methods'] ?? [];

      setState(() {
        _paymentMethods =
            paymentMethodsData.map<Map<String, dynamic>>((method) {
          return {
            'name': method['name'],
            'slug': method['slug'],
            'image': method['image'],
            'is_selected': method['is_selected'] ?? false,
          };
        }).toList();

        final selectedMethod = _paymentMethods.firstWhere(
          (method) => method['is_selected'] == true,
          orElse: () => <String, dynamic>{},
        );

        _paymentMethod = selectedMethod['slug'] ?? '';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildPaymentMethodsContainer() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _paymentMethods.map((method) {
          bool isSelected = _paymentMethod == method['slug'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _paymentMethod = method['slug'];
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 5),
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: AppColors.primaryWhiteColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isSelected ? AppColors.primaryGreen(context) : Colors.transparent,
                  width: 2.0,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Radio<String>(
                      value: method['slug'],
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                      fillColor: MaterialStateProperty.resolveWith<Color>(
                        (states) => isSelected
                            ? AppColors.primaryGreen(context)
                            : AppColors.blackColor,
                      ),
                    ),
                    SizedBox(width: 8),
                    if (method['image'] != null)
                      Image.network(
                        method['image'],
                        width: 30,
                        height: 30,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.error),
                      ),
                    SizedBox(width: 8),
                    Text(
                      method['name'],
                      style: TextStyle(
                        fontSize: 16.0,
                        fontFamily: AppFontFamily.font,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                        color: AppColors.greyColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final String? balance = userData != null && userData['user'] != null
        ? userData['user']['balance']?.toString()
        : null;
    double? balanceValue = double.tryParse((balance ?? '0.00').replaceAll(RegExp(r'[^0-9.]'), ''));

    double total = _calculateTotal();
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

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
          return !_isLoading;
        },
        child: Directionality(
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
                    forceMaterialTransparency: true,
                    backgroundColor: AppColors.whiteColor,
                    elevation: 0,
                    titleSpacing: 0,
                    title: Text(
                      '${Localization.translate("payment")}',
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
                            size: 20, color: Colors.black),
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
            body: RefreshIndicator(
              onRefresh: _fetchData,
              color: AppColors.primaryGreen(context),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _isLoading
                        ? const PaymentMethodsSkeleton()
                        : _paymentMethods.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${Localization.translate("payment_methods")}',
                                    style: TextStyle(
                                      fontSize: FontSize.scale(context, 18),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFontFamily.font,
                                      color: AppColors.blackColor
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  _buildPaymentMethodsContainer(),
                                  SizedBox(height: 16),
                                  Divider(),
                                ],
                              )
                            : Center(
                                child: Text(
                                  '${Localization.translate("empty_payment_methods")}',
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 16),
                                    fontWeight: FontWeight.w400,
                                    fontFamily: AppFontFamily.font,
                                    fontStyle: FontStyle.normal,
                                  ),),
                              ),
                    SizedBox(height: 10),
                    Text(
                      '${Localization.translate("billing_details")}',
                      style: TextStyle(
                          fontSize: FontSize.scale(context, 18),
                          fontFamily: AppFontFamily.font,
                          color: AppColors.blackColor,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CustomTextField(
                                hint: '${Localization.translate('firstName')}',
                                obscureText: false,
                                controller: _firstNameController,
                                focusNode: _firstNameFocusNode,
                                hasError: !_isFirstNameValid,
                              ),
                              if (_firstNameError.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _firstNameError,
                                    style: TextStyle(color: AppColors.redColor),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CustomTextField(
                                hint: '${Localization.translate('lastname')}',
                                obscureText: false,
                                controller: _lastNameController,
                                focusNode: _lastNameFocusNode,
                                hasError: !_isLastNameValid,
                              ),
                              if (_lastNameError.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _lastNameError,
                                    style: TextStyle(color: AppColors.redColor),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    CustomTextField(
                      hint: '${Localization.translate('company_title')}',
                      controller: _companyTitleController,
                      focusNode: _companyTitleFocusNode,
                      mandatory: false,
                    ),
                    SizedBox(height: 15),
                    CustomTextField(
                      hint: '${Localization.translate('emailAddress')}',
                      controller: _emailAddressController,
                      focusNode: _emailAddressFocusNode,
                      hasError: !_isEmailValid,
                    ),
                    if (_emailError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _emailError,
                          style: TextStyle(color: AppColors.redColor),
                        ),
                      ),
                    SizedBox(height: 15),
                    CustomTextField(
                      hint: '${Localization.translate('phoneNumber_field')}',
                      mandatory: true,
                      controller: _numberController,
                      focusNode: _numberFocusNode,
                      keyboardType: TextInputType.number,
                      hasError: !_isPhoneNumberValid,
                    ),
                    if (_phoneError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _phoneError,
                          style: TextStyle(color: AppColors.redColor),
                        ),
                      ),
                    SizedBox(height: 15),
                    CustomTextField(
                      hint: '${Localization.translate('country')}',
                      mandatory: true,
                      controller: _countryController,
                      absorbInput: true,
                      onTap: () {
                        _showCountryBottomSheet(_countryController);
                      },
                    ),
                    if (_countryError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _countryError,
                          style: TextStyle(color: AppColors.redColor),
                        ),
                      ),
                    SizedBox(
                      height: 16,
                    ),
                    CustomTextField(
                      hint: '${Localization.translate('state')}',
                      controller: _stateController,
                      focusNode: _stateFocusNode,
                      hasError: !_isStateValid,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1.0),
                      child: Text(
                        _isStateError,
                        style: TextStyle(color: AppColors.redColor),
                      ),
                    ),
                    CustomTextField(
                      hint: '${Localization.translate('city')}',
                      mandatory: true,
                      controller: _cityController,
                      focusNode: _cityFocusNode,
                      hasError: !_isCityValid,
                    ),
                    if (_cityError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _cityError,
                          style: TextStyle(color: AppColors.redColor),
                        ),
                      ),
                    SizedBox(height: 16),
                    CustomTextField(
                      hint: '${Localization.translate('zip_code')}',
                      mandatory: true,
                      keyboardType: TextInputType.number,
                      controller: _zipController,
                      focusNode: _zipFocusNode,
                      hasError: !_isZipCodeValid,
                    ),
                    if (_zipCodeError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _zipCodeError,
                          style: TextStyle(color: AppColors.redColor),
                        ),
                      ),
                    SizedBox(height: 16),
                    CustomTextField(
                      hint: '${Localization.translate('description')}',
                      multiLine: true,
                      mandatory: false,
                      controller: _descriptionController,
                      focusNode: _descriptionFocusNode,
                    ),
                    SizedBox(height: 10),
                    balanceValue != null && balanceValue > 0.00
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 1.3,
                                    child: Checkbox(
                                      value: _isChecked,
                                      checkColor: AppColors.whiteColor,
                                      activeColor: AppColors.primaryGreen(context),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0),
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
                                  Text(
                                    '${Localization.translate('pay_wallet')}',
                                    style: TextStyle(
                                      fontSize: FontSize.scale(context, 16),
                                      color: AppColors.greyColor(context),
                                      fontFamily: AppFontFamily.font,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.normal,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$balance',
                                style: TextStyle(
                                  color: AppColors.blackColor,
                                  fontSize: FontSize.scale(context, 18),
                                  fontFamily: AppFontFamily.font,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                            ],
                          )
                        : SizedBox.shrink(),
                    SizedBox(height: 8),
                    Divider(
                      color: AppColors.dividerColor,
                    ),
                    SizedBox(height: 25),
                    Text(
                      '${Localization.translate('order_summary')}',
                      style: TextStyle(
                        fontSize: FontSize.scale(context, 18),
                        fontFamily: AppFontFamily.font,
                        color: AppColors.blackColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Column(
                      children: [
                        ...widget.cartData.asMap().entries.map((entry) {
                          final index = entry.key;
                          final session = entry.value;

                          return Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  session['image'] is String &&
                                          session['image'].isNotEmpty && session['image'] != 'https://enkib.com/storage/placeholder.png'
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            session['image'],
                                            width: 55,
                                            height: 55,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace){
                                              return Image.asset(AppImages.courseImage,
                                              width: 55,
                                                height: 55,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                            loadingBuilder: (context, child, loadingProgress){
                                              if(loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                  ?loadingProgress.cumulativeBytesLoaded/loadingProgress.expectedTotalBytes!
                                                  : null,
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      // : Container(
                                      //     width: 50,
                                      //     height: 50,
                                      //     color: Colors.grey[200],
                                      //     child: Icon(
                                      //       Icons.image,
                                      //       color:  AppColors.greyColor(context),
                                      //     ),
                                      //   ),
                                  : ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      AppImages.courseImage,
                                      width: 55,
                                      height: 55,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          session['subject_name']??'',
                                          style: TextStyle(
                                            fontSize: FontSize.scale(context, 16),
                                            fontFamily: AppFontFamily.font,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          session['subject_group']??'',
                                          style: TextStyle(
                                            fontSize: FontSize.scale(context, 14),
                                            color:  AppColors.greyColor(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                   // '\$${(double.tryParse(session['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0).toStringAsFixed(2)} /session',

                                    '${NumberFormat.currency(locale: "en_IN", symbol: "₹").format(double.tryParse(session['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0)} /session',
                                    style: TextStyle(
                                      fontSize: FontSize.scale(context, 16),
                                      fontFamily: AppFontFamily.font,
                                      color: AppColors.blackColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (index < widget.cartData.length - 1)
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey[300],
                                ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                    Divider(),
                    ListTile(
                      title: Text('${Localization.translate("grand_total")}',
                          style: TextStyle(
                            fontSize: FontSize.scale(context, 18),
                            color: AppColors.blackColor,
                            fontFamily: AppFontFamily.font,
                            fontWeight: FontWeight.w800,
                          )),
                      trailing: Text(
                        //'\$${(double.tryParse(total.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0).toStringAsFixed(2)}',

          '${NumberFormat.currency(locale: "en_IN", symbol: "₹").format(double.tryParse(total.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0)}',
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 16),
                          color: AppColors.blackColor,
                          fontFamily: AppFontFamily.font,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(right: 15, left: 15),
                      child: ElevatedButton(
                        onPressed: _onPressLoading ? null : _payOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen(context),
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: _onPressLoading
                            ?  SpinKitCircle(
                                  color: AppColors.primaryGreen(context),
                                  size: 30,

                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    //'${Localization.translate("pay")} \$${total.toStringAsFixed(2)}',
                                    '${Localization.translate("pay")} ${NumberFormat.currency(locale: "en_IN", symbol : "₹").format(total)}',

                                    style: TextStyle(
                                      fontSize: FontSize.scale(context, 16),
                                      color:  AppColors.whiteColor,
                                      fontFamily: AppFontFamily.font,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.normal,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
