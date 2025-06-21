import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/api_structure/api_service.dart';
import '../../domain/api_structure/config/app_config.dart';
import '../../presentation/view/auth/login_screen.dart';
import '../../presentation/view/components/login_required_alert.dart';
import '../../presentation/view/tutor/certificate/certificate_detail.dart';
import '../../presentation/view/tutor/education/education_details.dart';
import '../../presentation/view/tutor/experience/experience_detail.dart';
import '../localization/localization.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _userData;
  List<Education> _educationList = [];
  List<Experience> _experienceList = [];
  List<Certificate> _certificateList = [];
  Map<String, dynamic>? _identityVerificationData;
  String? _personalPhotoPath;
  String? _idPhotoPath;

  String? _firstName;
  String? _lastName;
  String? _email;
  String? _phone;
  String? _country;
  String? _state;
  String? _city;
  String? _zipCode;
  String? _description;
  String? _company;
  bool _isLoading = false;
  List<int> favoriteTutorIds = [];
  List<int> favoriteCourseIds = [];

  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get email => _email;
  String? get phone => _phone;
  String? get country => _country;
  String? get state => _state;
  String? get city => _city;
  String? get zipCode => _zipCode;
  String? get description => _description;
  String? get company => _company;

  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;
  List<Education> get educationList => _educationList;
  List<Experience> get experienceList => _experienceList;
  List<Certificate> get certificateList => _certificateList;
  Map<String, dynamic>? get identityVerificationData =>
      _identityVerificationData;
  String? get personalPhotoPath => _personalPhotoPath;
  String? get idPhotoPath => _idPhotoPath;

  bool get isLoading => _isLoading;

  bool get isLoggedIn => _token != null;

  int? get userId {
    if (_userData != null &&
        _userData!.containsKey('user') &&
        _userData!['user'].containsKey('id')) {
      return _userData!['user']['id'];
    }
    return null;
  }

  AuthProvider() {
    _loadSession();
    loadFromPreferences();
    _initializeToken();
  }

  Future<void> saveIdentityVerificationData(
      Map<String, dynamic> data, String? personalPhoto, String? idPhoto) async {
    _identityVerificationData = data;
    _personalPhotoPath = personalPhoto;
    _idPhotoPath = idPhoto;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('identityVerificationData', jsonEncode(data));
    if (personalPhoto != null) {
      await prefs.setString('personalPhotoPath', personalPhoto);
    }
    if (idPhoto != null) {
      await prefs.setString('idPhotoPath', idPhoto);
    }

    notifyListeners();
  }

  Future<void> loadIdentityVerificationData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('identityVerificationData');
    _personalPhotoPath = prefs.getString('personalPhotoPath');
    _idPhotoPath = prefs.getString('idPhotoPath');

    if (dataString != null) {
      _identityVerificationData = jsonDecode(dataString);
    }

    notifyListeners();
  }

  Future<void> clearIdentityVerificationData() async {
    _identityVerificationData = null;
    _personalPhotoPath = null;
    _idPhotoPath = null;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('identityVerificationData');
    await prefs.remove('personalPhotoPath');
    await prefs.remove('idPhotoPath');

    notifyListeners();
  }

  Future<void> fetchEducationList(
      String? token, int id, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await getTutorsEducation(token, id);

      if (response['status'] == 401) {
        showCustomToast(context, response['message'], false);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: Localization.translate('invalidToken'),
              content: Localization.translate('loginAgain'),
              buttonText: Localization.translate('goToLogin'),
              buttonAction: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              showCancelButton: false,
            );
          },
        );
      } else {
        final educationData = response['data'] as List<dynamic>;
        _educationList = educationData
            .map((educationJson) => Education.fromJson(educationJson))
            .toList();
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExperienceList(
      String? token, int id, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await getTutorsExperience(token, id);
      if (response['status'] == 401) {
        showCustomToast(context, response['message'], false);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: Localization.translate('invalidToken'),
              content: Localization.translate('loginAgain'),
              buttonText: Localization.translate('goToLogin'),
              buttonAction: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              showCancelButton: false,
            );
          },
        );
      }
      final experienceData = response['data'] as List<dynamic>;
      _experienceList = experienceData
          .map((experienceJson) => Experience.fromJson(experienceJson))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCertificationList(
      String? token, int id, BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await getTutorsCertification(token, id);

      if (response['status'] == 200) {
        final certificationData = response['data'] as List<dynamic>;

        _certificateList = certificationData
            .map((certificateJson) => Certificate(
                  id: certificateJson['id'],
                  jobTitle: certificateJson['title'],
                  company: certificateJson['institute_name'],
                  description: certificateJson['description'],
                  fromDate: certificateJson['issue_date'],
                  toDate: certificateJson['expiry_date'],
                  imagePath: certificateJson['image'],
                ))
            .toList();
      } else if (response['status'] == 401) {
        showCustomToast(context, response['message'], false);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: Localization.translate('invalidToken'),
              content: Localization.translate('loginAgain'),
              buttonText: Localization.translate('goToLogin'),
              buttonAction: () {
                Navigator.pushReplacement(
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addFavoriteTutor(int tutorId) {
    favoriteTutorIds.add(tutorId);
    notifyListeners();
  }

  void addFavoriteCourse(int courseId) {
    favoriteCourseIds.add(courseId);
    notifyListeners();
  }

  void removeFavoriteTutor(int tutorId) {
    favoriteTutorIds.remove(tutorId);
    notifyListeners();
  }

  void removeFavoriteCourses(int tutorId) {
    favoriteCourseIds.remove(tutorId);
    notifyListeners();
  }

  void toggleFavoriteStatus(int tutorId) {
    if (favoriteTutorIds.contains(tutorId)) {
      removeFavoriteTutor(tutorId);
    } else {
      addFavoriteTutor(tutorId);
    }

    notifyListeners();
  }

  void toggleFavoriteCourseStatus(int courseId) {
    if (favoriteCourseIds.contains(courseId)) {
      removeFavoriteCourses(courseId);
    } else {
      addFavoriteCourse(courseId);
    }

    notifyListeners();
  }

  bool isTutorFavorite(int tutorId) {
    return favoriteTutorIds.contains(tutorId);
  }

  bool isCourseFavorite(int courseId) {
    return favoriteCourseIds.contains(courseId);
  }

  Future<void> fetchFavoriteTutors() async {
    final response = await savedTutors(token!);
    if (response['status'] == 200) {
      favoriteTutorIds =
          List<int>.from(response['data'].map((tutor) => tutor['id']));
      notifyListeners();
    }
  }

  void updateBalance(double newBalance) {
    if (userData != null && userData!['user'] != null) {
      userData!['user']['balance'] = newBalance;
      notifyListeners();
    }
  }

  Future<void> _initializeToken() async {
    _token = _token;
    notifyListeners();
  }

  Future<void> _loadSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    final userDataString = prefs.getString('userData');
    if (userDataString != null) {
      _userData = jsonDecode(userDataString) as Map<String, dynamic>;
    }

    final educationListString = prefs.getString('educationList');
    if (educationListString != null) {
      final List<dynamic> educationData = jsonDecode(educationListString);
      _educationList = educationData
          .map((item) => Education.fromJson(jsonDecode(item)))
          .toList();
    } else {
      _educationList = [];
    }

    final experienceListString = prefs.getString('experienceList');
    if (experienceListString != null) {
      final List<dynamic> experienceData = jsonDecode(experienceListString);
      _experienceList = experienceData
          .map((item) => Experience.fromJson(jsonDecode(item)))
          .toList();
    } else {
      _experienceList = [];
    }

    notifyListeners();
  }

  Future<void> saveEducation(Education newEducation) async {
    _educationList.add(newEducation);
    notifyListeners();
  }

  void updateEducation(int index, Education updatedEducation) {
    _educationList[index] = updatedEducation;
    notifyListeners();
  }

  Future<void> loadEducationFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final educationListString = prefs.getString('educationList');
    if (educationListString != null) {
      final List<dynamic> educationData = jsonDecode(educationListString);
      _educationList = educationData
          .map((item) => Education.fromJson(jsonDecode(item)))
          .toList();
    } else {
      _educationList = [];
    }
  }

  Future<void> removeEducation(int index) async {
    _educationList.removeAt(index);
    notifyListeners();
  }

  Future<void> loadExperiences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? experienceJson = prefs.getString('experienceList');

    if (experienceJson != null) {
      List<dynamic> decoded = jsonDecode(experienceJson);

      _experienceList =
          decoded.map((exp) => Experience.fromJson(jsonDecode(exp))).toList();

      notifyListeners();
    }
  }

  Future<void> removeExperience(int index) async {
    _experienceList.removeAt(index);
    notifyListeners();
  }

  Future<void> saveExperience(Experience newExperience) async {
    _experienceList.add(newExperience);
    notifyListeners();
  }

  Future<void> updateExperienceList(
      int index, Experience updatedExperience) async {
    _experienceList[index] = updatedExperience;
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    _token = token;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    notifyListeners();
  }

  Future<void> setAuthToken(String token) async {
    _token = token;
    notifyListeners();
  }

  Future<void> setUserData(Map<String, dynamic> userData) async {
    _userData = userData;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(userData));
    notifyListeners();
  }

  Future<void> clearToken() async {
    _token = null;
    _userData = null;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  Future<void> loadCertificates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final certificateListString = prefs.getString('certificateList');
    if (certificateListString != null) {
      try {
        final List<dynamic> certificateData = jsonDecode(certificateListString);
        _certificateList = certificateData.map((item) {
          if (item is Map<String, dynamic>) {
            return Certificate.fromJson(item);
          } else if (item is String) {
            return Certificate.fromJson(jsonDecode(item));
          } else {
            throw Exception("${item.runtimeType}");
          }
        }).toList();
      } catch (e) {
        _certificateList = [];
      }
    } else {
      _certificateList = [];
    }
    notifyListeners();
  }

  Future<void> saveCertificate(Certificate certificate) async {
    _certificateList.add(certificate);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addCertificateToApi(
      String token, Certificate certificate) async {
    _setLoading(true);
    try {
      final Map<String, dynamic> certificateData = certificate.toJson()
        ..remove('id');

      final response = await addCertification(token, certificateData);

      if (response['status'] == 200) {
        final responseData = response['data'];
        if (responseData != null && responseData.containsKey('id')) {
          int newCertificateId = responseData['id'];

          final Certificate updatedCertificate =
              certificate.copyWith(id: newCertificateId);
          await saveCertificate(updatedCertificate);
        }
      } else {
        final errors = response['errors'] ?? {};
        if (errors.isNotEmpty) {
          final errorMessages = errors.values.join(', ');
        }

        throw Exception(response['message'] ??
            '${Localization.translate("failed_certification")}');
      }

      return response;
    } catch (e) {
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> updateCertificateToApi(
      String token, Certificate certificate) async {
    _setLoading(true);
    try {
      final Map<String, dynamic> certificationData = certificate.toJson();
      certificationData.remove('id');

      final response =
          await updateCertification(token, certificate.id, certificationData);

      if (response['status'] == 200) {
        int index =
            _certificateList.indexWhere((cert) => cert.id == certificate.id);
        if (index >= 0) {
          _certificateList[index] = certificate;
        }
        await saveCertificate(certificate);
        notifyListeners();

        return response;
      } else {
        throw Exception(response['message'] ??
            Localization.translate("update_certification"));
      }
    } catch (e) {
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeCertificate(int index) async {
    _certificateList.removeAt(index);
    notifyListeners();
  }

  Future<void> updateUserProfiles(Map<String, dynamic>? updatedProfile) async {
    if (updatedProfile != null && _userData != null) {
      _userData!['user']['profile'] = updatedProfile;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(_userData));
      notifyListeners();
    } else {}
  }

  void updateProfileImage(String newImageUrl) {
    if (_userData != null && _userData!['user'] != null) {
      _userData!['user']['profile']['image'] = _cleanUrl(newImageUrl);
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('userData', jsonEncode(_userData));
        notifyListeners();
      });
    }
  }

  String _cleanUrl(String url) {
    String cleanedUrl = url.replaceAll(AppConfig.mediaBaseUrl, '');
    return '${AppConfig.mediaBaseUrl}$cleanedUrl';
  }

  Future<void> updateUserProfile(Map<String, dynamic> newProfileData) async {
    if (_userData != null) {
      _userData!['profile'] = newProfileData;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(_userData));
      notifyListeners();
    }
  }

  void setFirstName(String value) {
    _firstName = value;
    saveToPreferences();
    notifyListeners();
  }

  void setLastName(String value) {
    _lastName = value;
    saveToPreferences();
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    saveToPreferences();
    notifyListeners();
  }

  void setPhone(String value) {
    _phone = value;
    saveToPreferences();
    notifyListeners();
  }

  void setCountry(String value) {
    _country = value;
    saveToPreferences();
    notifyListeners();
  }

  void setState(String value) {
    _state = value;
    saveToPreferences();
    notifyListeners();
  }

  void setCity(String value) {
    _city = value;
    saveToPreferences();
    notifyListeners();
  }

  void setZipCode(String value) {
    _zipCode = value;
    saveToPreferences();
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    saveToPreferences();
    notifyListeners();
  }

  void setCompany(String value) {
    _company = value;
    saveToPreferences();
    notifyListeners();
  }

  Future<void> saveToPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', _firstName ?? '');
    await prefs.setString('lastName', _lastName ?? '');
    await prefs.setString('email', _email ?? '');
    await prefs.setString('phone', _phone ?? '');
    await prefs.setString('country', _country ?? '');
    await prefs.setString('state', _state ?? '');
    await prefs.setString('city', _city ?? '');
    await prefs.setString('zipCode', _zipCode ?? '');
    await prefs.setString('description', _description ?? '');
    await prefs.setString('company', _company ?? '');
  }

  Future<void> loadFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _firstName = prefs.getString('firstName') ?? '';
    _lastName = prefs.getString('lastName') ?? '';
    _email = prefs.getString('email') ?? '';
    _phone = prefs.getString('phone') ?? '';
    _country = prefs.getString('country') ?? '';
    _state = prefs.getString('state') ?? '';
    _city = prefs.getString('city') ?? '';
    _zipCode = prefs.getString('zipCode') ?? '';
    _description = prefs.getString('description') ?? '';
    _company = prefs.getString('company') ?? '';

    notifyListeners();
  }
}

void showCustomToast(BuildContext context, String message, bool isSuccess) {
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 5.0,
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
