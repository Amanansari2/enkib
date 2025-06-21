import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../data/localization/localization.dart';
import '../../../../data/provider/auth_provider.dart';
import '../../../../domain/api_structure/api_service.dart';
import '../../auth/login_screen.dart';
import '../../components/bottom_sheet.dart';
import '../../components/login_required_alert.dart';
import 'component/identity_verification_skeleton.dart';

class IdentityVerificationScreen extends StatefulWidget {
  @override
  _IdentityVerificationScreenState createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _schoolIdController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _parentController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _dobFocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _zipFocusNode = FocusNode();
  final FocusNode _schoolIdFocusNode = FocusNode();
  final FocusNode _schoolNameNode = FocusNode();
  final FocusNode _parentNameNode = FocusNode();
  final FocusNode _parentEmailNode = FocusNode();
  final FocusNode _parentPhoneNode = FocusNode();
  final FocusNode _countryFocusNode = FocusNode();
  final FocusNode _stateFocusNode = FocusNode();

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  File? _selectedIdImage;

  String? _selectedCountry;
  String? _selectedCity;
  String? _selectedLanguage;
  late double screenWidth;
  late double screenHeight;

  List<String> _countries = [];
  Map<int, String> _countryMap = {};
  Map<int, bool> _countryStatesMap = {};
  int? _selectedCountryId;

  List<String> _states = [];
  Map<int, String> _statesMap = {};
  int? _selectedStateId;
  String? _selectedState;

  bool _isLoading = true;

  Map<String, dynamic>? _identityVerificationData;
  String? _personalPhotoUrl;
  String? _transcriptUrl;
  bool _isStateFieldVisible = false;

  @override
  void initState() {
    super.initState();
    _fetchIdentityVerification();
    _loadSavedIdentityVerificationData();
    _fetchCountries();
    if (_selectedCountryId != null) {
      _fetchStates(_selectedCountryId!).then((_) {
        if (_selectedState != null) {
          _stateController.text = _selectedState!;
        }
      });
    } else if (_selectedState != null) {
      _stateController.text = _selectedState!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _cityController.dispose();
    _nameFocusNode.dispose();
    _dobFocusNode.dispose();
    _cityFocusNode.dispose();
    _zipController.dispose();
    _zipFocusNode.dispose();
    _schoolIdController.dispose();
    _schoolIdFocusNode.dispose();
    _schoolNameController.dispose();
    _schoolNameNode.dispose();
    _parentController.dispose();
    _parentNameNode.dispose();
    _parentPhoneController.dispose();
    _parentPhoneNode.dispose();
    _parentEmailController.dispose();
    _parentEmailNode.dispose();
    _countryController.dispose();
    _countryFocusNode.dispose();
    _stateController.dispose();
    _stateFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSavedIdentityVerificationData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadIdentityVerificationData();

    if (authProvider.identityVerificationData != null) {
      final data = authProvider.identityVerificationData!;

      setState(() {
        _nameController.text = data['name'] ?? '';
        _dobController.text = data['dateOfBirth'] ?? '';
        _selectedCountryId = data['country'];
        _selectedStateId = data['state'];
        _cityController.text = data['city'] ?? '';
        _zipController.text = data['zipcode'] ?? '';

        if (authProvider.personalPhotoPath != null) {
          _selectedImage = File(authProvider.personalPhotoPath!);
        }
        if (authProvider.idPhotoPath != null) {
          _selectedIdImage = File(authProvider.idPhotoPath!);
        }
      });

      _countryController.text = _countryMap[_selectedCountryId] ?? '';
      _stateController.text = _statesMap[_selectedStateId] ?? '';
    }
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

          bool countryHasStates =
              country['states'] != null && country['states'].isNotEmpty;
          _countryStatesMap[country['id']] = countryHasStates;

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

        if (_selectedState != null && _states.contains(_selectedState)) {
          _stateController.text = _selectedState!;
        }
      });
    } catch (e) {
      setState(() {
        _isStateFieldVisible = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            primaryColor: AppColors.primaryGreen(context),
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGreen(context),
              onPrimary: AppColors.whiteColor,
              onSurface: AppColors.blackColor,
            ),
            dialogBackgroundColor: AppColors.whiteColor,
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _dobController.text = DateFormat('MMMM-dd-yyyy').format(selectedDate);
      });
    }
  }



  void _showCountryBottomSheet(TextEditingController countryController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sheetBackgroundColor,
      isScrollControlled: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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

                  _isStateFieldVisible = false;
                  _stateController.clear();
                  _selectedState = null;
                  _selectedStateId = null;
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

  void _showStateBottomSheet(TextEditingController stateController) {
    if (_isStateFieldVisible) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.sheetBackgroundColor,
        isScrollControlled: true,
        useRootNavigator: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return BottomSheetComponent(
                title: _selectedState == null ? 'Select State' : '',
                items: _states,
                selectedItem: _selectedState,
                onItemSelected: (selectedItem) {
                  setModalState(() {
                    _selectedState = selectedItem;
                    stateController.text = selectedItem;
                    _selectedStateId = _statesMap.entries
                        .firstWhere((entry) => entry.value == selectedItem)
                        .key;
                  });
                },
              );
            },
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

  Future<void> _fetchIdentityVerification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;

    if (token != null) {
      try {
        final response = await getIdentityVerification(token, userId!);

        if (response['status'] == 401) {
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

        final identityVerificationData = response['data'] ?? {};
        final identityVerificationAddressData =
            identityVerificationData['address'] ?? {};

        final fullName = identityVerificationData['name'];
        final personalPhoto = identityVerificationData['attachments'];
        final transcript = identityVerificationData['transcript'];
        final dateOfBirth = identityVerificationData['dob'];
        final city = identityVerificationAddressData['city'];
        final zipCode = identityVerificationAddressData['zipcode'];
        final schoolId = identityVerificationData['school_id'];
        final schoolName = identityVerificationData['school_name'];
        final parentName = identityVerificationData['parent_name'];
        final parentPhone = identityVerificationData['parent_phone'];
        final parentEmail = identityVerificationData['parent_email'];
        final countryId = identityVerificationAddressData['country']?['name'];
        final stateId = identityVerificationAddressData['state']?['name'];

        setState(() {
          _identityVerificationData = identityVerificationData;
          _personalPhotoUrl = personalPhoto;
          _transcriptUrl = transcript;
          _nameController.text = fullName ?? '';
          _dobController.text = dateOfBirth ?? '';
          _cityController.text = city ?? '';
          _zipController.text = zipCode ?? '';
          _schoolIdController.text = schoolId ?? '';
          _schoolNameController.text = schoolName ?? '';
          _parentController.text = parentName ?? '';
          _parentPhoneController.text = parentPhone ?? '';
          _parentEmailController.text = parentEmail ?? '';
          _countryController.text = countryId ?? '';
          _stateController.text = stateId ?? '';

          _selectedCountryId =
              identityVerificationAddressData['country']?['id'];
          _selectedStateId = identityVerificationAddressData['state']?['id'];

          _countryHasStates = _selectedCountryId != null &&
              _countryStatesMap.containsKey(_selectedCountryId);

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

  Future<File?> downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();

        final filePath =
            '${directory.path}/image_${DateTime.now().millisecondsSinceEpoch}.png';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return file;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitIdentityVerification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userData = authProvider.userData;
    final String? role = userData != null && userData['user'] != null
        ? userData['user']['role']
        : null;

    if (!_validateFields()) {
      return;
    }

    if (token == null) {
      showCustomToast(context, 'No token found', false);
      return;
    }

    setState(() {
      _isLoading = true;
      _identityVerificationData ??= {};
      _identityVerificationData!['status'] = 'pending';
    });

    final Map<String, dynamic> identityData = {
      'name': _nameController.text.trim(),
      'dateOfBirth': _dobController.text.trim(),
      'status': 'pending',
      'country': _selectedCountryId,
      'state': _selectedStateId,
      'city': _cityController.text.trim(),
      'zipcode': _zipController.text.trim(),
    };
    if (role == 'student') {
      identityData.addAll({
        'schoolId': _schoolIdController.text.trim(),
        'schoolName': _schoolNameController.text.trim(),
        'parentName': _parentController.text.trim(),
        'parentPhone': _parentPhoneController.text.trim(),
        'parentEmail': _parentEmailController.text.trim(),
        'transcript': _transcriptUrl != null ? File(_transcriptUrl!) : null,
      });
    } else if (role == 'tutor') {
      identityData['identificationCard'] =
          _transcriptUrl != null ? File(_transcriptUrl!) : null;
    }
    if (_transcriptUrl != null &&
        Uri.tryParse(_transcriptUrl!)?.isAbsolute == true) {
      final downloadedImage = await downloadImage(_transcriptUrl!);
      if (downloadedImage != null) {
        _transcriptUrl = downloadedImage.path;
      } else {
        showCustomToast(context, 'Failed to download image.', false);
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    try {
      final response = await identityVerification(
        token,
        identityData,
        _selectedImage,
        _selectedIdImage,
        _transcriptUrl != null ? File(_transcriptUrl!) : null,
      );

      setState(() {
        if (response['status'] == 200) {
          final responseData = response['data'];
          _identityVerificationData = {
            ..._identityVerificationData!,
            'status': responseData['status'],
            'data': responseData,
          };
          showCustomToast(context, response['message'], true);
        } else if (response['status'] == 422) {
          _handleValidationErrors(response['errors']);
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
        } else if (response['status'] == 403) {
          showCustomToast(
            context,
            response['message'],
            false,
          );
        } else {
          showCustomToast(
            context,
            response['message'] ?? '${Localization.translate("error_message")}',
            false,
          );
        }
      });
    } catch (e) {
      showCustomToast(context, 'Failed to submit verification', false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleValidationErrors(Map<String, dynamic>? errors) {
    if (errors != null && errors is Map) {
      errors.forEach((key, value) {
        if (value is String) {
          showCustomToast(context, '$key: $value', false);
        } else if (value is List) {
          showCustomToast(context, '$key: ${value.join(', ')}', false);
        }
      });
    } else {
      showCustomToast(
          context, '${Localization.translate("error_message")}', false);
    }
  }

  bool _validateFields() {
    if (_selectedCountryId == null) {
      showCustomToast(context,
          '${Localization.translate("country_validation_message")}', false);
      return false;
    }

    if (_countryHasStates && _selectedStateId == null) {
      showCustomToast(context,
          '${Localization.translate("state_validation_message")}', false);
      return false;
    }

    if (_nameController.text.isEmpty ||
        _dobController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _zipController.text.isEmpty) {
      showCustomToast(
          context, '${Localization.translate("required_fields")}', false);
      return false;
    }

    if (_selectedImage == null) {
      showCustomToast(
          context, '${Localization.translate("image_required")}', false);
      return false;
    }

    return true;
  }

  bool _countryHasStates = false;

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final String? role = userData != null && userData['user'] != null
        ? userData['user']['role']
        : null;

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
                forceMaterialTransparency: true,
                backgroundColor: AppColors.whiteColor,
                elevation: 0,
                titleSpacing: 0,
                title: Text(
                  '${Localization.translate("identity_verification")}',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: FontSize.scale(context, 20),
                    fontFamily: AppFontFamily.mediumFont,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.arrow_back_ios,
                        size: 20,
                      color: AppColors.blackColor,

                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                centerTitle: false,
              ),
            ),
          ),
        ),
        body: _isLoading
            ? IdentitySkeleton()
            : _identityVerificationData != null &&
                    _identityVerificationData!['status'] == 'accepted'
                ? Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border:
                          Border.all(width: 4.0, color: AppColors.whiteColor),
                      image: DecorationImage(
                        image: AssetImage(AppImages.accepted),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${Localization.translate("accepted_title")}",
                          style: TextStyle(
                              fontSize: FontSize.scale(context, 20),
                              fontWeight: FontWeight.bold,
                              color: AppColors.whiteColor,
                              fontFamily: AppFontFamily.mediumFont),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "${Localization.translate("accepted_status")}",
                          style: TextStyle(
                              color: AppColors.whiteColor,
                              fontFamily: AppFontFamily.mediumFont,
                              fontSize: FontSize.scale(context, 15)),
                        ),
                      ],
                    ),
                  )
                : _identityVerificationData != null &&
                        _identityVerificationData!['status'] == 'pending'
                    ? Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.fadeColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              width: 2.0, color: AppColors.dividerColor),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.pending_actions,
                                    color: AppColors.blackColor, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  "${Localization.translate("pending_title")}",
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 20),
                                    fontFamily: AppFontFamily.mediumFont,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blackColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              "${Localization.translate("pending_status")}",
                              style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: FontSize.scale(context, 16),
                                fontFamily: AppFontFamily.mediumFont,
                              ),
                            ),
                            SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _identityVerificationData!['status'] = null;
                                });
                              },
                              child: Text(
                                "${Localization.translate("re_upload")}",
                                style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 14),
                                  fontFamily: AppFontFamily.mediumFont,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Container(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                width: screenWidth,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryWhiteColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.rectangle,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            image: DecorationImage(
                                              image: _selectedImage != null
                                                  ? FileImage(_selectedImage!)
                                                  : (_personalPhotoUrl != null
                                                          ? NetworkImage(
                                                              '$_personalPhotoUrl')
                                                          : AssetImage(AppImages
                                                              .imagePlaceholder))
                                                      as ImageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: -8,
                                          right: -8,
                                          child: Container(
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: AppColors.whiteColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: AppColors.whiteColor,
                                                  width: 2),
                                            ),
                                            child: GestureDetector(
                                              onTap: _showPhotoActionSheet,
                                              child: CircleAvatar(
                                                radius: 12,
                                                backgroundColor:
                                                    AppColors.primaryGreen(
                                                        context),
                                                child: Icon(Icons.add,
                                                    size: 16,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${Localization.translate("upload_photo")}',
                                          style: TextStyle(
                                            color: AppColors.blackColor,
                                            fontSize:
                                                FontSize.scale(context, 14),
                                            fontFamily: AppFontFamily.regularFont,
                                            fontWeight: FontWeight.w400,
                                            fontStyle: FontStyle.normal,
                                          ),
                                        ),
                                        Text(
                                          '${Localization.translate("image_format")}',
                                          style: TextStyle(
                                            color: AppColors.greyColor(context),
                                            fontSize:
                                                FontSize.scale(context, 12),
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
                              SizedBox(height: 15),
                              CustomTextField(
                                hint: '${Localization.translate("full_name")}',
                                mandatory: true,
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                              ),
                              SizedBox(height: 15),
                              CustomTextField(
                                hint: '${Localization.translate("birth_date")}',
                                mandatory: true,
                                controller: _dobController,
                                focusNode: _dobFocusNode,
                                dateIcon: true,
                                showSuffixIcon: true,
                                absorbInput: true,
                                onTap: () {
                                  _selectDate(context);
                                },
                              ),
                              SizedBox(height: 16),
                              CustomTextField(
                                hint: '${Localization.translate("country")}',
                                mandatory: true,
                                absorbInput: true,
                                showSuffixIcon: true,
                                controller: _countryController,
                                focusNode: _countryFocusNode,
                                onTap: () {
                                  _showCountryBottomSheet(_countryController);
                                },
                              ),
                              if (_countryHasStates)
                                Column(
                                  children: [
                                    SizedBox(height: 16),
                                    CustomTextField(
                                      hint:
                                          '${Localization.translate("select_state")}',
                                      mandatory: true,
                                      showSuffixIcon: true,
                                      controller: _stateController,
                                      absorbInput: true,
                                      onTap: () {
                                        _showStateBottomSheet(_stateController);
                                      },
                                    ),
                                  ],
                                ),
                              SizedBox(height: 16),
                              CustomTextField(
                                hint: '${Localization.translate("city")}',
                                mandatory: false,
                                controller: _cityController,
                                focusNode: _cityFocusNode,
                              ),
                              SizedBox(height: 16),
                              CustomTextField(
                                hint: '${Localization.translate("zip_code")}',
                                mandatory: false,
                                controller: _zipController,
                                focusNode: _zipFocusNode,
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                width: screenWidth,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryWhiteColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.rectangle,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            image: DecorationImage(
                                              image: _selectedIdImage != null
                                                  ? FileImage(_selectedIdImage!)
                                                  : (_transcriptUrl != null
                                                          ? NetworkImage(
                                                              '$_transcriptUrl')
                                                          : AssetImage(AppImages
                                                              .placeHolder))
                                                      as ImageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: -8,
                                          right: -8,
                                          child: Container(
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: AppColors.whiteColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: AppColors.whiteColor,
                                                  width: 2),
                                            ),
                                            child: GestureDetector(
                                              onTap: _showIdActionSheet,
                                              child: CircleAvatar(
                                                radius: 12,
                                                backgroundColor:
                                                    AppColors.primaryGreen(
                                                        context),
                                                child: Icon(Icons.add,
                                                    size: 16,
                                                    color: AppColors.whiteColor),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            role == 'student'
                                                ? '${Localization.translate("upload_transcript")}'
                                                : '${Localization.translate("upload_id")}',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.blackColor,
                                              fontSize:
                                                  FontSize.scale(context, 14),
                                              fontFamily: AppFontFamily.regularFont,
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                            ),
                                          ),
                                          Text(
                                            '${Localization.translate("file_size")}',
                                            style: TextStyle(
                                              color:
                                                  AppColors.greyColor(context),
                                              fontSize:
                                                  FontSize.scale(context, 12),
                                              fontFamily: AppFontFamily.regularFont,
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              if (role == "student")
                                CustomTextField(
                                  hint:
                                      '${Localization.translate("enrollment_id")}',
                                  mandatory: true,
                                  controller: _schoolIdController,
                                  focusNode: _schoolIdFocusNode,
                                ),
                              SizedBox(height: 16),
                              if (role == "student")
                                CustomTextField(
                                  hint:
                                      '${Localization.translate("school_name")}',
                                  mandatory: true,
                                  controller: _schoolNameController,
                                  focusNode: _schoolNameNode,
                                ),
                              SizedBox(height: 16),
                              if (role == "student")
                                CustomTextField(
                                  hint:
                                      '${Localization.translate("parent_name")}',
                                  mandatory: true,
                                  controller: _parentController,
                                  focusNode: _parentNameNode,
                                ),
                              SizedBox(height: 16),
                              if (role == "student")
                                CustomTextField(
                                  hint:
                                      '${Localization.translate("parent_phone")}',
                                  mandatory: true,
                                  controller: _parentPhoneController,
                                  focusNode: _parentPhoneNode,
                                ),
                              SizedBox(height: 16),
                              if (role == "student")
                                CustomTextField(
                                  hint:
                                      '${Localization.translate("parent_email")}',
                                  mandatory: true,
                                  controller: _parentEmailController,
                                  focusNode: _parentEmailNode,
                                ),
                              SizedBox(height: 15),
                              Divider(
                                color: AppColors.dividerColor,
                              ),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        if (_validateFields()) {
                                          await _submitIdentityVerification();
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.primaryGreen(context),
                                  minimumSize: Size(double.infinity, 55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                child: _isLoading
                                    ? CircularProgressIndicator(
                                        color: AppColors.whiteColor)
                                    : Text(
                                        '${Localization.translate("save_update")}',
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 16),
                                          color: AppColors.whiteColor,
                                          fontFamily: AppFontFamily.mediumFont,
                                          fontWeight: FontWeight.w500,
                                          fontStyle: FontStyle.normal,
                                        ),
                                      ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickIdImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedIdImage = File(pickedFile.path);
      });
    }
  }

  void _viewProfilePhoto() {
    if (_selectedImage != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('${Localization.translate("profile_photo")}'),
            content: Image.file(_selectedImage!),
            actions: <Widget>[
              TextButton(
                child: Text('${Localization.translate("close")}'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title:
                Text('${Localization.translate("unSelected_profile_photo")}'),
            content: Text('${Localization.translate("upload_profile_image")}'),
            actions: <Widget>[
              TextButton(
                child: Text('${Localization.translate("ok")}'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _showPhotoActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sheetBackgroundColor,
      builder: (BuildContext context) {
        return Container(
          height: screenHeight * 0.27,
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "${Localization.translate("select_option")}",
                style: TextStyle(
                  color: AppColors.blackColor,
                  fontSize: FontSize.scale(context, 18),
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.normal,
                  fontFamily: AppFontFamily.mediumFont,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Container(
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
                    children: [
                      _buildActionItem(
                        icon: Icons.photo_library,
                        text:
                            '${Localization.translate("upload_profile_photo")}',
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage();
                        },
                      ),
                      Divider(
                        color: AppColors.dividerColor,
                        height: 0,
                        thickness: 0.5,
                        indent: 24,
                        endIndent: 24,
                      ),
                      _buildActionItem(
                        icon: Icons.image,
                        text: '${Localization.translate("view_photo")}',
                        onTap: () {
                          Navigator.pop(context);
                          _viewProfilePhoto();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _viewIdImage() {
    if (_selectedIdImage != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('${Localization.translate("profile_photo")}'),
            content: Image.file(_selectedIdImage!),
            actions: <Widget>[
              TextButton(
                child: Text('${Localization.translate('close')}'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('${Localization.translate("id_empty")}'),
            content: Text('${Localization.translate("id_photo")}'),
            actions: <Widget>[
              TextButton(
                child: Text('${Localization.translate('ok')}'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _showIdActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sheetBackgroundColor,
      builder: (BuildContext context) {
        return Container(
          height: screenHeight * 0.27,
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "${Localization.translate('select_option')}",
                style: TextStyle(
                  color: AppColors.blackColor,
                  fontSize: FontSize.scale(context, 18),
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.normal,
                  fontFamily: AppFontFamily.mediumFont,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Container(
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
                    children: [
                      _buildActionItem(
                        icon: Icons.photo_library,
                        text: '${Localization.translate("id_photo")}',
                        onTap: () {
                          Navigator.pop(context);
                          _pickIdImage();
                        },
                      ),
                      Divider(
                        color: AppColors.dividerColor,
                        height: 0,
                        thickness: 0.5,
                        indent: 24,
                        endIndent: 24,
                      ),
                      _buildActionItem(
                        icon: Icons.image,
                        text: '${Localization.translate("view_photo")}',
                        onTap: () {
                          Navigator.pop(context);
                          _viewIdImage();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionItem(
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 24.0),
        decoration: BoxDecoration(
            color: AppColors.primaryWhiteColor,
            borderRadius: BorderRadius.circular(10.0)),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: AppColors.greyColor(context),
            ),
            SizedBox(width: 24.0),
            Text(
              text,
              style: TextStyle(
                color: AppColors.greyColor(context),
                fontSize: FontSize.scale(context, 16),
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.normal,
                fontFamily: AppFontFamily.mediumFont,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
