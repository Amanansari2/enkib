import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/api_structure/config/app_config.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/localization/localization.dart';
import 'package:flutter_projects/provider/connectivity_provider.dart';
import 'package:flutter_projects/provider/settings_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/components/internet_alert.dart';
import 'package:flutter_projects/view/components/login_required_alert.dart';
import 'package:flutter_projects/view/components/video_widget.dart';
import 'package:flutter_projects/view/profile/component/user_language_bottom_sheet.dart';
import 'package:flutter_projects/view/profile/skeleton/profile_setting_skeleton.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../components/bottom_sheet.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

class ProfileSettingsScreen extends StatefulWidget {
  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  File? _selectedVideo;

  String _gender = 'male';
  String? _selectedCountry;
  String? _selectedLanguage;
  String? _selectedState;
  late double screenWidth;
  late double screenHeight;
  List<String> _countries = [];
  List<String> _states = [];
  String? _addressError;
  String? _descriptionError;
  String ? _taglineError;
  String? _numberError;

  Map<int, String> _countryMap = {};
  Map<int, String> _statesMap = {};
  Map<int, String> _languageMap = {};

  String profilePhoneNumber = "no";
  String profile_video = "no";

  int? _selectedCountryId;
  int? _selectedStateId;

  List<int> _selectedLanguageIds = [];

  Map<String, dynamic>? _profileData;
  bool _isLoading = false;

  bool _isStateFieldVisible = false;
  bool _isNumberValid = true;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _languagesController = TextEditingController();
  final TextEditingController _userLanguagesController =
      TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _taglineController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_validateDescription);
    _addressController.addListener(_validateAddress);
    _taglineController.addListener(_validateTagline);
    _numberController.addListener(_validateNumber);
    _fetchCountries();
    _fetchLanguages();
    _fetchProfileData();
    _fetchUserLanguages();

    if (_selectedCountryId != null) {
      _fetchStates(_selectedCountryId!);
    }

    _descriptionController.addListener(_updateParsedDescription);
  }

  void _validateAddress(){
    final text = _addressController.text.trim();
    setState(() {
      if(text.isEmpty){
        _addressError = "Address cannot be empty";
      } else if(text.length < 10){
        _addressError = "Address must be at least 10 characters";
      } else {
        _addressError = null ;
      }
    });
  }
  void _validateTagline(){
    final text = _taglineController.text.trim();
    setState(() {
      if(text.isEmpty){
        _taglineError = "Tagline cannot be empty";
      } else if(text.length < 20){
        _taglineError = "Tagline field must be at least 20 characters";
      } else if (text.length > 254){
        _taglineError = "Tagline field must not be grater than 255 characters";
      } else {
        _taglineError = null;
      }
    });
  }
void _validateNumber(){
    final text = _numberController.text.trim();
    setState(() {
      if(text.isEmpty){
        _numberError = "Phone number cannot be empty";
      } else if(!RegExp(r'^[0-9]+$').hasMatch(text)){
        _numberError = "Phone number must contain only digits";
      } else if(text.length < 10){
        _numberError = " Phone number mus be atleast 10 digits";
      } else if(text.length >15){
        _numberError = "Phone number cannot exceed 15 digits";
      } else {
        _numberError = null;
      }
    });
}
void _validateDescription(){
    final text = _descriptionController.text.trim();
    setState(() {
      if(text.isEmpty){
        _descriptionError = "Description cannot be empty";
      } else if(text.length <20){
        _descriptionError = "Description must be at least 20 characters";
      } else if(text.length > 500){
        _descriptionError = "Description cannot exceed 500 characters";
      } else{
        _descriptionError = null ;
      }
    });
}
  void _updateParsedDescription() {
    setState(() {
      String parsedText = parse(_descriptionController.text).body?.text ?? '';
      if (_descriptionController.text != parsedText) {
        _descriptionController.value = TextEditingValue(
          text: parsedText,
          selection: TextSelection.fromPosition(
            TextPosition(offset: parsedText.length),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_updateParsedDescription);
    _descriptionController.removeListener(_validateDescription);
    _addressController.removeListener(_validateAddress);
    _taglineController.removeListener(_validateTagline);
    _numberController.removeListener(_validateNumber);
    _descriptionController.dispose();
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

  Future<void> _fetchUserLanguages() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await getLanguages(token!);

      final languages = response['data'];

      setState(() {
        _languages = languages.map<String>((language) {
          _languageMap[language['id']] = language['name'];
          return language['name'] as String;
        }).toList();
      });
    } catch (e) {}
  }

  Future<void> _fetchLanguages() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await getLanguages(token!);

      final languages = response['data'];

      setState(() {
        _languages = languages.map<String>((language) {
          return language['name'] as String;
        }).toList();
      });
    } catch (e) {}
  }

  void _showNaiveLanguageBottomSheet(
      TextEditingController languagesController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BottomSheetComponent(
              title: "${Localization.translate("select_native_language")}",
              items: _languages,
              selectedItem: _selectedLanguage,
              onItemSelected: (selectedItem) {
                setModalState(() {
                  _selectedLanguage = selectedItem;
                  languagesController.text = selectedItem;
                });
              },
            );
          },
        );
      },
    );
  }

  void _playIntroVideo(String videoUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: AppColors.blackColor,
          body: Center(
            // child: AspectRatio(
            //   aspectRatio: 16 / 9,
            //   child: VideoPlayerWidget(
            //     videoUrl: videoUrl,
            //     onClose: () {
            //       Navigator.pop(context);
            //     },
            //   ),
            // ),
            child : LayoutBuilder(
                builder: (context, constraints){
                  return Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: VideoPlayerWidget(
                        videoUrl: videoUrl,
                        onClose: (){
                          Navigator.pop(context);
                        }),
                  );
                }
            )
          ),
        );
      },
    );
  }

  void _showUserLanguageBottomSheet(TextEditingController languagesController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return UserLanguageBottomSheetComponent(
          title: "${Localization.translate("select_language")}",
          items: _languages,
          selectedItems: _selectedLanguageIds
              .map((id) => _languageMap[id])
              .where((name) => name != null)
              .toList()
              .cast<String>(),
          onItemsSelected: (selectedItems) {
            setState(() {
              _selectedLanguageIds = selectedItems
                  .map((name) => _languageMap.entries
                      .firstWhere((entry) => entry.value == name)
                      .key)
                  .toList();
              languagesController.text = selectedItems.join(', ');
            });
          },
        );
      },
    );
  }

  void _showStateBottomSheet(TextEditingController stateController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BottomSheetComponent(
              title: _selectedState == null ? '${Localization.translate("select_state")}' : '',
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

  Future<void> _fetchProfileData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;

    setState(() {
      _isLoading = true;
    });

    if (token != null && userId != null) {
      try {
        final response = await getProfile(token, userId);

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

          return;
        }

        setState(() {
          _profileData = response['data'];
          _isLoading = false;
        });

        if (_profileData != null && _profileData!['profile'] != null) {
          _firstNameController.text =
              _profileData!['profile']['first_name'] ?? '';
          _lastNameController.text =
              _profileData!['profile']['last_name'] ?? '';
          _emailController.text = _profileData!['email'] ?? '';
          _gender = _profileData!['profile']['gender'] ?? '';
          _descriptionController.text =
              _profileData!['profile']['description'] ?? '';
          _taglineController.text = _profileData!['profile']['tagline'] ?? '';
          _selectedLanguage = _profileData!['profile']['native_language'] ?? '';
          _numberController.text =
              _profileData!['profile']['phone_number'] ?? '';
          if (_profileData != null && _profileData!['address'] != null) {
            _addressController.text = _profileData!['address']['address_line'] ?? '';
          }

          if (_profileData!['profile']['image'] != null) {
            String cleanedImageUrl =
                _cleanUrl(_profileData!['profile']['image']);
            authProvider.updateProfileImage(cleanedImageUrl);
          }

          if (_profileData!['profile']['intro_video'] != null) {
            String cleanedVideoUrl =
                _cleanUrl(_profileData!['profile']['intro_video']);
            authProvider.updateUserProfile({'intro_video': cleanedVideoUrl});
          }

          if (_profileData!['address'] != null) {
            _cityController.text = _profileData!['address']['city'] ?? '';
            _postalCodeController.text =
                _profileData!['address']['zipcode'] ?? '';

            if (_profileData!['address']['country'] != null) {
              _selectedCountry = _profileData!['address']['country']['name'];
              _countryController.text = _selectedCountry ?? '';
              _selectedCountryId = _profileData!['address']['country_id'];
            }

            if (_profileData!['address']['state'] != null) {
              _selectedState = _profileData!['address']['state']['name'];
              _stateController.text = _selectedState ?? '';
              _selectedStateId = _profileData!['address']['state_id'];
              _isStateFieldVisible = true;
            } else {
              _isStateFieldVisible = false;
            }

            if (_selectedCountryId != null) {
              _fetchStates(_selectedCountryId!);
            }
          }

          if (_profileData!['languages'] != null) {
            List<dynamic> languages = _profileData!['languages'];
            _selectedLanguageIds =
                languages.map<int>((lang) => lang['id'] as int).toList();
            _userLanguagesController.text =
                languages.map((lang) => lang['name'] as String).join(', ');
            _languagesController.text = _selectedLanguage!;
          }
        } else {}
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

  List<String> _languages = [];
  bool _onPressLoading = false;


  void _saveAndUpdateProfile() async {


    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;
    print("token ----->>> $token");
    print("User ID: $userId");

    if (token == null || userId == null) {
      return;
    }
    print("Input data before submission:");
    print("First Name: ${_firstNameController.text.trim()}");
    print("Last Name: ${_lastNameController.text.trim()}");
    print("Gender: $_gender");
    print("Native Language: ${_selectedLanguage ?? ''}");
    print("Description: ${_descriptionController.text.trim()}");
    print("Country ID: ${_selectedCountryId?.toString() ?? ''}");
    print("State ID: ${_selectedStateId?.toString() ?? ''}");
    print("Tagline: ${_taglineController.text.trim()}");
    print("City: ${_cityController.text.trim()}");
    print("Zip Code: ${_postalCodeController.text.trim()}");
    print("Email: ${_emailController.text.trim()}");
    print("Phone Number: ${_numberController.text.trim()}");
    print("Languages: ${_selectedLanguageIds}");
    print("Profile Image Path: ${_selectedImage?.path}");
    print("Intro Video Path: ${_selectedVideo?.path}");
    setState(() {
      _onPressLoading = true;
    });

    try {
      final Uri uri = Uri.parse('$baseUrl/profile-settings/$userId');
      print("url ---->>> $uri");
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['first_name'] = _firstNameController.text.trim();
      request.fields['last_name'] = _lastNameController.text.trim();
      request.fields['gender'] = _gender;
      request.fields['native_language'] = _selectedLanguage ?? '';
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['country'] = _selectedCountryId?.toString() ?? '';
      request.fields['state'] = _selectedStateId?.toString() ?? '';
      request.fields['tagline'] = _taglineController.text.trim();
      request.fields['city'] = _cityController.text.trim();
      request.fields['zipcode'] = _postalCodeController.text.trim();
      request.fields['email'] = _emailController.text.trim();
      request.fields['phone_number'] = _numberController.text.trim();
      request.fields['address'] = _addressController.text.trim();

      request.fields['recommend_tutor'] = 'true';

      for (int i = 0; i < _selectedLanguageIds.length; i++) {
        request.fields['user_languages[$i]'] =
            _selectedLanguageIds[i].toString();
      }

      if (_selectedImage != null) {
        var imageFile = File(_selectedImage!.path);
        String mimeType =
            lookupMimeType(imageFile.path) ?? 'application/octet-stream';
        var mimeTypeData = mimeType.split('/');
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
        ));
      } else if (_profileData != null &&
          _profileData!['profile'] != null &&
          _profileData!['profile']['image'] != null) {
        request.fields['image'] = _profileData!['profile']['image'];
      }

      if (profile_video == "yes") {
        if (_selectedVideo == null) {
          setState(() {
            _onPressLoading = false;
          });

          showCustomToast(context, 'Intro video is required.', false);
          return;
        } else {
          var videoFile = File(_selectedVideo!.path);
          String mimeType =
              lookupMimeType(videoFile.path) ?? 'application/octet-stream';
          var mimeTypeData = mimeType.split('/');
          request.files.add(await http.MultipartFile.fromPath(
            'intro_video',
            videoFile.path,
            contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
          ));
        }
      }
      print("Sending request...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        print("Success Response: $responseData");
        showCustomToast(context, responseData['message'], true);

        setState(() {
          _onPressLoading = false;
        });

        if (responseData != null &&
            responseData.containsKey('data') &&
            responseData['data'].containsKey('profile')) {
          var profileData = responseData['data']['profile'];
          authProvider.updateUserProfiles(profileData);

          if (_selectedImage != null) {
            authProvider.updateProfileImage(profileData['image']);
          }

          if (_selectedVideo != null) {
            authProvider
                .updateUserProfile({'intro_video': profileData['intro_video']});
          }
        }
      }

      else if (response.statusCode == 403) {
        var errorData = jsonDecode(response.body);
        print("Forbidden Error Data: $errorData");
        setState(() {
          _isLoading = false;
        });

        String errorMessages = errorData['message'];
        print("Forbidden Error Message: $errorMessages");
        showCustomToast(context, errorMessages, false);
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
        });
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

        return;
      } else {
        var errorData = jsonDecode(response.body);
        String errorMessage =
            errorData['message'] ?? 'Failed to update profile';
        print("Error Message: $errorMessage");
        showCustomToast(context, errorMessage, false);
      }
    } catch (e) {

      print("Exception caught: $e");
      showCustomToast(context, 'Error updating profile: \$e', false);
    } finally {
      setState(() {
        _onPressLoading = false;
      });
    }
  }

  String _cleanUrl(String url) {
    if (url.contains(AppConfig.mediaBaseUrl)) {
      return url.replaceAll(AppConfig.mediaBaseUrl, '');
    }
    return url;
  }

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 2.0,
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

    final authProvider = Provider.of<AuthProvider>(context);
    String? profileImageUrl =
        authProvider.userData?['user']?['profile']?['image'];
    final settings = Provider.of<SettingsProvider>(context);

    profilePhoneNumber =
        settings.getSetting('data')?['_lernen']?['profile_phone_number'];
    profile_video = settings.getSetting('data')?['_lernen']?['profile_video'];

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
                      backgroundColor: AppColors.whiteColor,
                      forceMaterialTransparency: true,
                      elevation: 0,
                      titleSpacing: 0,
                      title: Text(
                        '${Localization.translate("profile_settings")}',
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
              body: _isLoading
                  ? ProfileSettingsSkeleton()
                  : SingleChildScrollView(
                      child: Container(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${Localization.translate("personal_Details")}',
                              style: TextStyle(
                                color: AppColors.greyColor(context),
                                fontSize: FontSize.scale(context, 16),
                                fontFamily: AppFontFamily.font,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              width: screenWidth,
                              decoration: BoxDecoration(
                                color: AppColors.whiteColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      GestureDetector(
                                        onTap: _showPhotoActionSheet,
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.rectangle,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: _selectedImage != null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Image.file(
                                                    _selectedImage!,
                                                    fit: BoxFit.cover,
                                                    width: 50,
                                                    height: 50,
                                                  ),
                                                )
                                              : (profileImageUrl != null &&
                                                      profileImageUrl.isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      child: CachedNetworkImage(
                                                          imageUrl:
                                                              profileImageUrl,
                                                          fit: BoxFit.cover,
                                                          width: 50,
                                                          height: 50,
                                                          placeholder:
                                                              (context, url) =>
                                                                  Center(
                                                                    child:
                                                                        SpinKitCircle(
                                                                      color: AppColors
                                                                          .primaryGreen(
                                                                              context),
                                                                    ),
                                                                  ),
                                                          errorWidget:
                                                              (context, url,
                                                                      error) =>
                                                                  Container(
                                                                    width: 20,
                                                                    height: 20,
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            10.0),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: AppColors
                                                                          .primaryGreen(
                                                                              context),
                                                                      shape: BoxShape
                                                                          .rectangle,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10),
                                                                    ),
                                                                    child: SvgPicture
                                                                        .asset(
                                                                      AppImages
                                                                          .placeHolder,
                                                                      height:
                                                                          20,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    ),
                                                                  )),
                                                    )
                                                  : Container(
                                                      width: 50,
                                                      height: 50,
                                                      padding:
                                                          EdgeInsets.all(10.0),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .primaryGreen(
                                                                context),
                                                        shape:
                                                            BoxShape.rectangle,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: SvgPicture.asset(
                                                        AppImages.placeHolder,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )),
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
                                          '${Localization.translate("upload_profile_photo")}',
                                          style: TextStyle(
                                            color: AppColors.blackColor,
                                            fontSize: FontSize.scale(context, 14),
                                            fontFamily: AppFontFamily.font,
                                            fontWeight: FontWeight.w400,
                                            fontStyle: FontStyle.normal,
                                          ),
                                        ),
                                        Text(
                                          '${Localization.translate("image_extension")}',
                                          style: TextStyle(
                                            color: AppColors.greyColor(context),
                                            fontSize: FontSize.scale(context, 12),
                                            fontFamily: AppFontFamily.font,
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
                            if (profile_video == "yes") ...[
                              SizedBox(height: 10),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                width: screenWidth,
                                decoration: BoxDecoration(
                                  color: AppColors.whiteColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (_profileData!['profile']
                                                    ['intro_video'] !=
                                                null) {
                                              String cleanedVideoUrl =
                                                  _profileData!['profile']
                                                      ['intro_video'];
                                              _playIntroVideo(cleanedVideoUrl);
                                            } else {
                                              _pickVideo();
                                            }
                                          },
                                          child: Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryGreen(
                                                  context),
                                              shape: BoxShape.rectangle,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              image: (_profileData != null &&
                                                      _profileData?[
                                                              'profile'] !=
                                                          null &&
                                                      _profileData?['profile']
                                                              ['intro_video'] !=
                                                          null)
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                          _profileData?[
                                                                  'profile']
                                                              ['intro_video']),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : (_selectedVideo != null)
                                                      ? DecorationImage(
                                                          image: FileImage(
                                                              _selectedVideo!),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                            ),
                                            child: (_profileData != null &&
                                                        _profileData?[
                                                                'profile'] !=
                                                            null &&
                                                        _profileData?['profile']
                                                                [
                                                                'intro_video'] !=
                                                            null) ||
                                                    _selectedVideo != null
                                                ? Center(
                                                    child: Icon(
                                                      Icons.play_circle_outline,
                                                      color:
                                                          AppColors.whiteColor,
                                                      size: 24,
                                                    ),
                                                  )
                                                : Padding(
                                                    padding:
                                                        EdgeInsets.all(10.0),
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        _pickVideo();
                                                      },
                                                      child: SvgPicture.asset(
                                                        AppImages
                                                            .videoPlaceHolder,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        if (_selectedVideo == null &&
                                            _profileData!['profile']
                                                    ['intro_video'] ==
                                                null)
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
                                                onTap: () {
                                                  _pickVideo();
                                                },
                                                child: CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor:
                                                      AppColors.primaryGreen(
                                                          context),
                                                  child: Icon(
                                                    Icons.add,
                                                    size: 16,
                                                    color: AppColors.whiteColor,
                                                  ),
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
                                        Row(
                                          children: [
                                            Text(
                                              _profileData!['profile']
                                                          ['intro_video'] !=
                                                      null
                                                  ? '${Localization.translate("play_video")}'
                                                  : '${Localization.translate("upload_video")}',
                                              style: TextStyle(
                                                color: AppColors.blackColor,
                                                fontSize:
                                                    FontSize.scale(context, 14),
                                                fontFamily: AppFontFamily.font,
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                              ),
                                            ),
                                            if (_profileData!['profile']
                                                    ['intro_video'] !=
                                                null)
                                              TextButton(
                                                onPressed: () {
                                                  _pickVideo();
                                                },
                                                child: Text(
                                                  '${Localization.translate("replace_video")}',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.primaryGreen(
                                                            context),
                                                    fontSize: FontSize.scale(
                                                        context, 12),
                                                    fontFamily:
                                                        AppFontFamily.font,
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle: FontStyle.normal,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        _profileData!['profile']
                                                    ['intro_video'] !=
                                                null
                                            ? Transform.translate(
                                                offset: Offset(0.0, -12.0),
                                                child: Text(
                                                  '${Localization.translate("tap_to_play")}',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: AppColors.greyColor(
                                                        context),
                                                    fontSize: FontSize.scale(
                                                        context, 12),
                                                    fontFamily:
                                                        AppFontFamily.font,
                                                    fontWeight: FontWeight.w400,
                                                    fontStyle: FontStyle.normal,
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                '${Localization.translate("video_extension")}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: AppColors.greyColor(
                                                      context),
                                                  fontSize: FontSize.scale(
                                                      context, 12),
                                                  fontFamily:
                                                      AppFontFamily.font,
                                                  fontWeight: FontWeight.w400,
                                                  fontStyle: FontStyle.normal,
                                                ),
                                              ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      CustomTextField(
                                        hint:
                                            '${Localization.translate("firstName")}',
                                        obscureText: false,
                                        controller: _firstNameController,
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
                                        hint:
                                            '${Localization.translate("lastName")}',
                                        obscureText: false,
                                        controller: _lastNameController,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            CustomTextField(
                              hint: '${Localization.translate("emailAddress")}',
                              controller: _emailController,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '${Localization.translate("gender")}',
                              style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: 16.0,
                                  fontFamily: AppFontFamily.font,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.normal),
                            ),
                            SizedBox(height: 16),
                            Wrap(
                              spacing: 28,
                              runSpacing: 16,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _gender = 'male';
                                    });
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _gender == 'male'
                                              ? AppColors.primaryGreen(context)
                                              : AppColors.whiteColor,
                                          border: Border.all(
                                            color: _gender == 'male'
                                                ? Colors.transparent
                                                : AppColors.dividerColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _gender == 'male'
                                                  ? Colors.white
                                                  : Colors.transparent,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '${Localization.translate("male")}',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontFamily: AppFontFamily.font,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.greyColor(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _gender =
                                          (_gender == 'female') ? '' : 'female';
                                    });
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _gender == 'female'
                                              ? AppColors.primaryGreen(context)
                                              : AppColors.whiteColor,
                                          border: Border.all(
                                            color: _gender == 'female'
                                                ? Colors.transparent
                                                : AppColors.dividerColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _gender == 'female'
                                                  ? Colors.white
                                                  : Colors.transparent,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '${Localization.translate("female")}',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontFamily: AppFontFamily.font,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.greyColor(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _gender = (_gender == 'not_specified')
                                          ? ''
                                          : 'not_specified';
                                    });
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _gender == 'not_specified'
                                              ? AppColors.primaryGreen(context)
                                              : AppColors.whiteColor,
                                          border: Border.all(
                                            color: _gender == 'not_specified'
                                                ? Colors.transparent
                                                : AppColors.dividerColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _gender == 'not_specified'
                                                  ? Colors.white
                                                  : Colors.transparent,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '${Localization.translate("unknown_gender")}',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontFamily: AppFontFamily.font,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.greyColor(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            CustomTextField(
                              hint:
                                  '${Localization.translate("select_country")}',
                              mandatory: true,
                              controller: _countryController,
                              absorbInput: true,
                              onTap: () {
                                _showCountryBottomSheet(_countryController);
                              },
                            ),
                            if (_isStateFieldVisible) SizedBox(height: 16),
                            if (_isStateFieldVisible)
                              CustomTextField(
                                hint:
                                    '${Localization.translate("select_state")}',
                                mandatory: true,
                                controller: _stateController,
                                absorbInput: true,
                                onTap: () {
                                  _showStateBottomSheet(_stateController);
                                },
                              ),
                            SizedBox(height: 16),
                            CustomTextField(
                              hint: '${Localization.translate("city")}',
                              controller: _cityController,
                            ),

                            SizedBox(height: 16,),

                            CustomTextField(
                                hint: "complete address",
                              controller: _addressController,
                            ),
                            if(_addressError != null )
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _addressError!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
                              ),


                            SizedBox(height: 16),
                            CustomTextField(
                              hint: '${Localization.translate("postal_code")}',
                              mandatory: false,
                              controller: _postalCodeController,
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(height: 16),
                            CustomTextField(
                              hint:
                                  '${Localization.translate("phoneNumber_field")}',
                              controller: _numberController,
                              hasError: !_isNumberValid,
                              keyboardType: TextInputType.number,
                            ),

                            if(_numberError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                              child:  Text(
                                _numberError!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16
                                ),
                              ),
                              ),

                            SizedBox(height: 16),
                            CustomTextField(
                              hint:
                                  '${Localization.translate("select_native_language")}',
                              mandatory: true,
                              controller: _languagesController,
                              absorbInput: true,
                              onTap: () {
                                _showNaiveLanguageBottomSheet(
                                    _languagesController);
                              },
                            ),
                            SizedBox(height: 16),
                            CustomTextField(
                              hint:
                                  '${Localization.translate("select_language")}',
                              mandatory: true,
                              controller: _userLanguagesController,
                              absorbInput: true,
                              onTap: () {
                                _showUserLanguageBottomSheet(
                                    _userLanguagesController);
                              },
                            ),
                            SizedBox(height: 16),
                            CustomTextField(
                              hint: '${Localization.translate("tagline")}',
                              mandatory: false,
                              controller: _taglineController,
                            ),
                            if(_taglineError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _taglineError!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16
                                ),
                              ),
                              ),
                            SizedBox(height: 16),
                            CustomTextField(
                              hint:
                                  '${Localization.translate("personal_description")}',
                              multiLine: true,
                              mandatory: false,
                              controller: _descriptionController,
                            ),
                            if(_descriptionError!=null)(
                            Padding(padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _descriptionError!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                            )
                            ),
                            SizedBox(height: 15),
                            Divider(
                              color: AppColors.dividerColor,
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _onPressLoading
                                  ? null
                                  : _saveAndUpdateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _onPressLoading
                                    ? AppColors.fadeColor
                                    : AppColors.primaryGreen(context),
                                minimumSize: Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${Localization.translate("save_update")}',
                                    textScaler: TextScaler.noScaling,
                                    style: TextStyle(
                                      fontSize: FontSize.scale(context, 16),
                                      color: _onPressLoading
                                          ? AppColors.greyColor(context)
                                          : AppColors.whiteColor,
                                      fontFamily: AppFontFamily.font,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.normal,
                                    ),
                                  ),
                                  if (_onPressLoading) ...[
                                    SizedBox(width: 10),

                                     SpinKitCircle(
                                        size: 25,

                                        color: AppColors.primaryGreen(context),

                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            )
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {

    try{

      PermissionStatus permissionStatus = PermissionStatus.denied;

      if(Platform.isAndroid){
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if(androidInfo.version.sdkInt <= 32){
          permissionStatus = await Permission.storage.request();
        } else{
          permissionStatus = await Permission.photos.request();
        }
      } else{
        permissionStatus = await Permission.photos.request();
      }
      if(permissionStatus.isGranted){
        final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

        if(pickedFile != null){
          setState(() {
            _selectedImage = File(pickedFile.path);
          });
        }
      } else if(permissionStatus.isDenied){
        showCustomToast(context, "Permission denied. Please allow in settings", false);
      }
      else if(permissionStatus.isPermanentlyDenied){
        showCustomToast(context, "Permission permanently denied. Please enable it from App Settings.", false);
        openAppSettings();
      }

    } on PlatformException catch(e){
      showCustomToast(context, "Failed to pick image: $e", false);
    }
  }

  Future<void> _pickVideo() async {

    try {

      PermissionStatus permissionStatus = PermissionStatus.denied;

      if(Platform.isAndroid){
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        if(androidInfo.version.sdkInt <=32){
          permissionStatus = await Permission.storage.request();
        }else{
          permissionStatus = await Permission.photos.request();
        }
      }else{
        permissionStatus = await Permission.photos.request();
      }
      if(permissionStatus.isGranted){
        final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);

        if(pickedFile != null){
          setState(() {
            _selectedVideo= File(pickedFile.path);
          });
        }
      } else if(permissionStatus.isDenied){
        showCustomToast(context, "Permission denied. Please allow in settings.", false);
      }
      else if(permissionStatus.isPermanentlyDenied){
        showCustomToast(context, "Permission is permanently denied. Please enable it from App Setting.", false);
        openAppSettings();
      }
    } on PlatformException catch(e){
      showCustomToast(context, "Failed to pick image: $e", false);
    }

    // try {
    //   final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    //
    //   if (pickedFile != null) {
    //     setState(() {
    //       _selectedVideo = File(pickedFile.path);
    //     });
    //   } else {}
    // } catch (e) {}
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
            content: Text('${Localization.translate("upload_profile_image")}.'),
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
      isScrollControlled: true,
      backgroundColor: AppColors.sheetBackgroundColor,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: Container(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.25),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
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
                Text(
                  "${Localization.translate("select_option")}",
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: FontSize.scale(context, 18),
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                    fontFamily: AppFontFamily.font,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryWhiteColor,
                        borderRadius: BorderRadius.circular(12),
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
                ),
              ],
            ),
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
                fontFamily: AppFontFamily.font,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
