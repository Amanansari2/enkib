import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/localization/localization.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/components/bottom_sheet.dart';
import 'package:flutter_projects/view/components/login_required_alert.dart';
import 'package:flutter_projects/view/tutor/component/dialog_component.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class EducationalDetailsScreen extends StatefulWidget {
  @override
  _EducationalDetailsScreenState createState() =>
      _EducationalDetailsScreenState();
}

class _EducationalDetailsScreenState extends State<EducationalDetailsScreen> {
  late double screenWidth;
  late double screenHeight;
  List<Education> _educationList = [];
  bool _isChecked = false;
  List<String> _countries = [];
  Map<int, String> _countryMap = {};
  int? _selectedCountryId;
  String? _selectedCountry;
  bool _onpPressLoading = false;
  bool _isFirstLoad = false;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final tutorId = authProvider.userId;
    setState(() {
      _isFirstLoad = true;
      _educationList = authProvider.educationList;
    });

    authProvider.fetchEducationList(token, tutorId!, context).then((_) {
      setState(() {
        _isFirstLoad = false;
        _educationList = authProvider.educationList;
      });
    }).catchError((e) {
      setState(() {
        _isFirstLoad = false;
      });
    });
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

  void _showCountryBottomSheet(
      StateSetter setModalState, TextEditingController countryController) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return BottomSheetComponent(
          title: "${Localization.translate("select_country")}",
          items: _countries,
          selectedItem: _selectedCountry,
          onItemSelected: (selectedItem) {
            setModalState(() {
              _selectedCountry = selectedItem;
              countryController.text = selectedItem;
              _selectedCountryId = _countryMap.entries
                  .firstWhere((entry) => entry.value == selectedItem)
                  .key;
            });
          },
        );
      },
    );
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
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  void _openBottomSheet(
      {Education? education, int? index, required bool isUpdate}) {
    final TextEditingController degreeController =
        TextEditingController(text: education != null ? education.degree : '');
    final TextEditingController instituteController = TextEditingController(
        text: education != null ? education.institute : '');
    final TextEditingController cityController =
        TextEditingController(text: education != null ? education.city : '');
    final TextEditingController descriptionController = TextEditingController(
        text: education != null ? education.description : '');
    final TextEditingController countryController = TextEditingController(
      text: education != null ? education.country : '',
    );

    DateTime? fromDate;
    try {
      fromDate = education != null
          ? DateFormat('MMMM d, yyyy').parse(education.fromDate)
          : null;
    } catch (e) {}

    DateTime? toDate;
    try {
      toDate = education != null
          ? DateFormat('MMMM d, yyyy').parse(education.toDate)
          : null;
    } catch (e) {}

    bool _isChecked = education?.ongoing ?? false;

    if (education != null && education.country.isNotEmpty) {
      _selectedCountryId = _countryMap.entries
          .firstWhere((entry) => entry.value == education.country)
          .key;
    }

    if (education != null && education.country.isNotEmpty) {
      _selectedCountryId = _countryMap.entries
          .firstWhere((entry) => entry.value == education.country)
          .key;
    }

    Future<void> _selectDate(BuildContext context, DateTime? initialDate,
        Function(DateTime) onDateSelected) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primaryGreen(context),
                onPrimary: AppColors.whiteColor,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        onDateSelected(picked);
      }
    }

    showModalBottomSheet(
        backgroundColor: AppColors.sheetBackgroundColor,
        context: context,
        isScrollControlled: true,
        builder: (context) {
          bool _hasError = false;
          return Directionality(
            textDirection: Localization.textDirection,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return GestureDetector(
                  onTap: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.75,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sheetBackgroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4.0, vertical: 10.0),
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
                                color: AppColors.topBottomSheetDismissColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 10),
                            child: Text(
                              '${Localization.translate("institute_label")}',
                              style: TextStyle(
                                fontSize: FontSize.scale(context, 18),
                                color: AppColors.blackColor,
                                fontFamily: AppFontFamily.font,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Container(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 10),
                                    TextField(
                                      cursorColor: AppColors.blackColor,
                                      controller: degreeController,
                                      decoration: InputDecoration(
                                        labelText:
                                            '${Localization.translate("degree_label")}',
                                        labelStyle: TextStyle(
                                          fontSize: FontSize.scale(context, 16),
                                          color: AppColors.greyColor(context),
                                          fontFamily: AppFontFamily.font,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: _hasError &&
                                                    degreeController.text.isEmpty
                                                ? AppColors.redColor
                                                : AppColors.dividerColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: _hasError &&
                                                    degreeController.text.isEmpty
                                                ? AppColors.redColor
                                                : AppColors.dividerColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: _hasError &&
                                                    degreeController.text.isEmpty
                                                ? AppColors.redColor
                                                : AppColors.dividerColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            EdgeInsets.only(bottom: 8),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    TextField(
                                      cursorColor: AppColors.blackColor,
                                      controller: instituteController,
                                      decoration: InputDecoration(
                                        labelText:
                                            '${Localization.translate("institute_name")}',
                                        labelStyle: TextStyle(
                                          fontSize: FontSize.scale(context, 16),
                                          color: AppColors.greyColor(context),
                                          fontFamily: AppFontFamily.font,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: _hasError &&
                                                    instituteController
                                                        .text.isEmpty
                                                ? AppColors.redColor
                                                : AppColors.dividerColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: _hasError &&
                                                    instituteController
                                                        .text.isEmpty
                                                ? AppColors.redColor
                                                : AppColors.dividerColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: _hasError &&
                                                    instituteController
                                                        .text.isEmpty
                                                ? AppColors.redColor
                                                : AppColors.dividerColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            EdgeInsets.only(bottom: 8),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    TextField(
                                      cursorColor: AppColors.blackColor,
                                      controller: cityController,
                                      decoration: InputDecoration(
                                        labelText:
                                            '${Localization.translate("city_name")}',
                                        labelStyle: TextStyle(
                                          fontSize: FontSize.scale(context, 16),
                                          color: AppColors.greyColor(context),
                                          fontFamily: AppFontFamily.font,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: _hasError &&
                                                    cityController.text.isEmpty
                                                ? AppColors.redColor
                                                : AppColors.dividerColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: _hasError &&
                                                    cityController.text.isEmpty
                                                ? AppColors.redColor
                                                : AppColors.dividerColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: _hasError &&
                                                    cityController.text.isEmpty
                                                ? AppColors.redColor
                                                : AppColors.dividerColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            EdgeInsets.only(bottom: 8),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () {
                                        _showCountryBottomSheet(
                                            setModalState, countryController);
                                      },
                                      child: AbsorbPointer(
                                        child: TextField(
                                          cursorColor: AppColors.blackColor,
                                          controller: countryController,
                                          decoration: InputDecoration(
                                            labelText:
                                                '${Localization.translate("select_country")}',
                                            labelStyle: TextStyle(
                                              fontSize:
                                                  FontSize.scale(context, 16),
                                              color: AppColors.greyColor(context),
                                              fontFamily: AppFontFamily.font,
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                            ),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: _hasError &&
                                                        countryController
                                                            .text.isEmpty
                                                    ? AppColors.redColor
                                                    : AppColors.dividerColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: _hasError &&
                                                        countryController
                                                            .text.isEmpty
                                                    ? AppColors.redColor
                                                    : AppColors.dividerColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: _hasError &&
                                                        countryController
                                                            .text.isEmpty
                                                    ? AppColors.redColor
                                                    : AppColors.dividerColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.only(bottom: 8),
                                            suffixIcon: Icon(
                                              Icons.keyboard_arrow_down,
                                              size: 25,
                                              color: AppColors.greyColor(context),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () => _selectDate(context, fromDate,
                                          (selectedDate) {
                                        setModalState(() {
                                          fromDate = selectedDate;
                                        });
                                      }),
                                      child: AbsorbPointer(
                                        child: TextField(
                                          cursorColor: AppColors.blackColor,
                                          controller: TextEditingController(
                                            text: fromDate != null
                                                ? DateFormat('MMM dd, yyyy')
                                                    .format(fromDate!)
                                                : '',
                                          ),
                                          decoration: InputDecoration(
                                            labelText:
                                                '${Localization.translate("start_date")}',
                                            labelStyle: TextStyle(
                                              fontSize:
                                                  FontSize.scale(context, 16),
                                              color: AppColors.greyColor(context),
                                              fontFamily: AppFontFamily.font,
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                            ),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    _hasError && fromDate == null
                                                        ? AppColors.redColor
                                                        : AppColors.dividerColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    _hasError && fromDate == null
                                                        ? AppColors.redColor
                                                        : AppColors.dividerColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    _hasError && fromDate == null
                                                        ? AppColors.redColor
                                                        : AppColors.dividerColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.only(bottom: 8),
                                            suffixIcon: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 14),
                                              child: SvgPicture.asset(
                                                AppImages.dateTimeIcon,
                                                width: 14,
                                                height: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () => _selectDate(context, toDate,
                                          (selectedDate) {
                                        setModalState(() {
                                          toDate = selectedDate;
                                        });
                                      }),
                                      child: AbsorbPointer(
                                        child: TextField(
                                          cursorColor: AppColors.blackColor,
                                          controller: TextEditingController(
                                            text: toDate != null
                                                ? DateFormat('MMM dd, yyyy')
                                                    .format(toDate!)
                                                : '',
                                          ),
                                          decoration: InputDecoration(
                                            labelText:
                                                '${Localization.translate("end_date")}',
                                            labelStyle: TextStyle(
                                              fontSize:
                                                  FontSize.scale(context, 16),
                                              color: AppColors.greyColor(context),
                                              fontFamily: AppFontFamily.font,
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                            ),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: _hasError && toDate == null
                                                    ? AppColors.redColor
                                                    : AppColors.dividerColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: _hasError && toDate == null
                                                    ? AppColors.redColor
                                                    : AppColors.dividerColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: _hasError && toDate == null
                                                    ? AppColors.redColor
                                                    : AppColors.dividerColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.only(bottom: 8),
                                            suffixIcon: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 14),
                                              child: SvgPicture.asset(
                                                AppImages.dateTimeIcon,
                                                width: 14,
                                                height: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Transform.translate(
                                          offset: Offset(-10, -10),
                                          child: Transform.scale(
                                            scale: 1.3,
                                            child: Checkbox(
                                              value: _isChecked,
                                              checkColor: AppColors.whiteColor,
                                              activeColor:
                                                  AppColors.primaryGreen(context),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                              ),
                                              side: BorderSide(
                                                color: AppColors.dividerColor,
                                                width: 1.5,
                                              ),
                                              onChanged: (bool? value) {
                                                setModalState(() {
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
                                              '${Localization.translate("ongoing")}',
                                              style: TextStyle(
                                                fontSize:
                                                    FontSize.scale(context, 16),
                                                color:
                                                    AppColors.greyColor(context),
                                                fontWeight: FontWeight.w400,
                                                fontFamily: AppFontFamily.font,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Divider(
                                      color: AppColors.dividerColor,
                                      thickness: 2,
                                      height: 1,
                                      indent: 2.0,
                                      endIndent: 2.0,
                                    ),
                                    SizedBox(height: 10),
                                    TextField(
                                      cursorColor: AppColors.blackColor,
                                      controller: descriptionController,
                                      maxLines: 5,
                                      decoration: InputDecoration(
                                        labelText:
                                            '${Localization.translate("description")}',
                                        labelStyle: TextStyle(
                                          fontSize: FontSize.scale(context, 16),
                                          color: AppColors.greyColor(context),
                                          fontFamily: AppFontFamily.font,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding:
                                            EdgeInsets.only(bottom: 8),
                                        alignLabelWithHint: true,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () async {
                                        setModalState(() {
                                          _hasError = false;
                                        });

                                        if (degreeController.text.isEmpty ||
                                            instituteController.text.isEmpty ||
                                            cityController.text.isEmpty ||
                                            countryController.text.isEmpty ||
                                            fromDate == null ||
                                            toDate == null ||
                                            descriptionController.text.isEmpty) {
                                          setModalState(() {
                                            _hasError = true;
                                          });

                                          if (degreeController.text.isEmpty ||
                                              instituteController.text.isEmpty ||
                                              cityController.text.isEmpty ||
                                              countryController.text.isEmpty) {
                                            showCustomToast(
                                                context,
                                                "${Localization.translate("required_fields")}",
                                                false);
                                          } else if (fromDate == null ||
                                              toDate == null) {
                                            showCustomToast(
                                                context,
                                                "${Localization.translate('select_dates')}",
                                                false);
                                          } else if (descriptionController
                                              .text.isEmpty) {
                                            showCustomToast(
                                                context,
                                                "${Localization.translate("description_required")}",
                                                false);
                                          }

                                          return;
                                        }

                                        if (degreeController.text.isNotEmpty &&
                                            instituteController.text.isNotEmpty &&
                                            fromDate != null &&
                                            (toDate != null || _isChecked) &&
                                            _selectedCountryId != null &&
                                            cityController.text.isNotEmpty) {
                                          if (toDate == null ||
                                              fromDate!.isBefore(toDate!)) {
                                            final authProvider =
                                                Provider.of<AuthProvider>(context,
                                                    listen: false);
                                            final token = authProvider.token;

                                            final Map<String, dynamic>
                                                educationData = {
                                              "course_title":
                                                  degreeController.text,
                                              "institute_name":
                                                  instituteController.text,
                                              "country": _selectedCountryId,
                                              "city": cityController.text,
                                              "start_date":
                                                  DateFormat('MMM dd, yyyy')
                                                      .format(fromDate!),
                                              "end_date": toDate != null
                                                  ? DateFormat('MMM dd, yyyy')
                                                      .format(toDate!)
                                                  : '',
                                              "ongoing": _isChecked ? "1" : "0",
                                              "description":
                                                  descriptionController.text,
                                            };

                                            try {
                                              setModalState(() {
                                                _onpPressLoading = true;
                                                _isFirstLoad = true;
                                              });

                                              final response = isUpdate
                                                  ? await updateEducation(
                                                      token!,
                                                      education!.id,
                                                      educationData)
                                                  : await addEducation(
                                                      token!, educationData);

                                              if (response['status'] == 200) {
                                                final newEducation = Education(
                                                  id: response['data']['id'] ??
                                                      'N/A',
                                                  degree: response['data']
                                                          ['course_title'] ??
                                                      'N/A',
                                                  institute: response['data']
                                                          ['institute_name'] ??
                                                      'N/A',
                                                  country: _countryMap[
                                                          response['data']
                                                              ['country_id']] ??
                                                      'Unknown Country',
                                                  city: response['data']
                                                          ['city'] ??
                                                      'Unknown City',
                                                  fromDate: response['data']
                                                          ['start_date'] ??
                                                      '',
                                                  toDate: response['data']
                                                          ['end_date'] ??
                                                      '',
                                                  description: response['data']
                                                          ['description'] ??
                                                      '',
                                                );

                                                if (isUpdate) {
                                                  authProvider.updateEducation(
                                                      index!, newEducation);
                                                } else {
                                                  await authProvider
                                                      .saveEducation(
                                                          newEducation);
                                                }

                                                await authProvider
                                                    .fetchEducationList(
                                                        token,
                                                        authProvider.userId!,
                                                        context);

                                                Navigator.pop(context);
                                                showCustomToast(context,
                                                    response['message'], true);
                                              } else if (response['status'] ==
                                                  403) {
                                                showCustomToast(context,
                                                    response['message'], false);
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
                                                      title:
                                                          Localization.translate(
                                                              'invalidToken'),
                                                      content:
                                                          Localization.translate(
                                                              'loginAgain'),
                                                      buttonText:
                                                          Localization.translate(
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
                                                if (response
                                                        .containsKey('errors') &&
                                                    response['errors'] != null) {
                                                  final errors =
                                                      response['errors'];
                                                  String errorMessage = '';

                                                  errors.forEach((key, value) {
                                                    if (value is List) {
                                                      errorMessage +=
                                                          value.join(', ') + '\n';
                                                    } else {
                                                      errorMessage +=
                                                          value.toString() + '\n';
                                                    }
                                                  });

                                                  showCustomToast(context,
                                                      errorMessage.trim(), false);
                                                } else {
                                                  showCustomToast(
                                                      context,
                                                      response['message'] ??
                                                          "An unknown error occurred.",
                                                      false);
                                                }
                                              }
                                            } catch (e) {
                                              showCustomToast(context,
                                                  '${e.toString()}', false);
                                            } finally {
                                              setModalState(() {
                                                _onpPressLoading = false;
                                                _isFirstLoad = false;
                                              });
                                            }
                                          } else {
                                            _hasError = true;
                                            showCustomToast(
                                                context,
                                                "${Localization.translate("end_start_date_valid")}",
                                                false);
                                          }
                                        } else {
                                          _hasError = true;
                                          showCustomToast(
                                              context,
                                              "${Localization.translate("required_fields")}",
                                              false);
                                        }

                                        setModalState(() {});
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.primaryGreen(context),
                                        minimumSize: Size(double.infinity, 45),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "${Localization.translate("save_update")}",
                                            style: TextStyle(
                                              fontSize:
                                                  FontSize.scale(context, 16),
                                              color: AppColors.whiteColor,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: AppFontFamily.font,
                                              fontStyle: FontStyle.normal,
                                            ),
                                          ),
                                          if (_onpPressLoading) ...[
                                            SizedBox(width: 10),
                                             SpinKitCircle(
                                             size: 25,
                                                color: AppColors.blueColor,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      "${Localization.translate("educational_detail_text")}",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: FontSize.scale(context, 14),
                                        color: AppColors.greyColor(context)
                                            .withOpacity(0.7),
                                        fontFamily: AppFontFamily.font,
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        });
  }

  void _showRemoveDialog(BuildContext context, int index) {
    if (index < 0 || index >= _educationList.length) {
      showCustomToast(
          context, "${Localization.translate("invalid_selection")}", false);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return DialogComponent(
          onRemove: () async {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final token = authProvider.token;
            final educationId = _educationList[index].id;
            String message = '';
            bool isSuccess = false;

            if (token != null) {
              try {
                final response = await deleteEducation(token, educationId);

                if (response['status'] == 200) {
                  await authProvider.removeEducation(index);
                  await authProvider.fetchEducationList(
                      token, authProvider.userId!, context);
                  message = response['message'] ??
                      '${Localization.translate("education_removed")}';

                  if (context.mounted) {
                    showCustomToast(context, message, true);
                  }
                  isSuccess = true;
                } else if (response['status'] == 403) {
                  message =
                      response['message'] ?? "Failed to delete education.";
                  isSuccess = false;
                } else if (response['status'] == 401) {
                  showCustomToast(
                      context,
                      '${Localization.translate("unauthorized_access")}',
                      false);

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
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                          );
                        },
                        showCancelButton: false,
                      );
                    },
                  );
                } else if (response['status'] == 404) {
                  await authProvider.removeEducation(index);
                  message =
                      "${Localization.translate("education_unavailable")}";
                  isSuccess = false;
                } else {
                  message = response['message'] ??
                      "${Localization.translate("failed_delete_education")}";
                  isSuccess = false;
                }
              } catch (error) {
                message = "An error occurred while deleting education.";
                isSuccess = false;
              }
            } else {
              message = "Authorization token is missing.";
              isSuccess = false;
            }
            Future.microtask(() {
              if (mounted) {
                showCustomToast(context, message, isSuccess);
              }
            });
          },
          title: '${Localization.translate("remove_alert_message")}',
          message: "${Localization.translate("remove_item_text")}",
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    final authProvider = Provider.of<AuthProvider>(context);

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
                    '${Localization.translate("education_details_label")}',
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
          body: Column(
            children: [
              if (_isFirstLoad)
                Expanded(
                  child: _buildSkeletonLoader(context),
                )
              else if (_educationList.isEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          AppImages.emptyEducation,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(height: 15),
                        Text(
                          '${Localization.translate("record_empty")}',
                          style: TextStyle(
                            fontSize: FontSize.scale(context, 16),
                            color: AppColors.blackColor.withOpacity(0.7),
                            fontFamily: AppFontFamily.font,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "${Localization.translate("record_empty_message")}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: FontSize.scale(context, 12),
                            color: AppColors.blackColor.withOpacity(0.7),
                            fontFamily: AppFontFamily.font,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _openBottomSheet(isUpdate: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen(context),
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Text(
                            '${Localization.translate("add_new")}',
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 16),
                              color: AppColors.whiteColor,
                              fontFamily: AppFontFamily.font,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              itemCount: authProvider.educationList.length,
                              itemBuilder: (context, index) {
                                final education =
                                    authProvider.educationList[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.whiteColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        education.institute.isNotEmpty
                                            ? education.institute
                                            : "${Localization.translate("institute_empty")}",
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 12),
                                          color: AppColors.greyColor(context),
                                          fontFamily: AppFontFamily.font,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            education.degree.isNotEmpty
                                                ? education.degree
                                                : "${Localization.translate("degree_empty")}",
                                            style: TextStyle(
                                              fontSize:
                                                  FontSize.scale(context, 15),
                                              color: AppColors.blackColor,
                                              fontFamily: AppFontFamily.font,
                                              fontWeight: FontWeight.w500,
                                              fontStyle: FontStyle.normal,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              SvgPicture.asset(
                                                AppImages.locationIcon,
                                                width: 14,
                                                height: 14,
                                                color: AppColors.greyColor(
                                                    context),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                education.country.isNotEmpty &&
                                                        education
                                                            .city.isNotEmpty
                                                    ? '${education.country}, ${education.city}'
                                                    : "${Localization.translate("location_empty")}",
                                                style: TextStyle(
                                                  fontSize: FontSize.scale(
                                                      context, 12),
                                                  color: AppColors.greyColor(
                                                      context),
                                                  fontFamily:
                                                      AppFontFamily.font,
                                                  fontWeight: FontWeight.w400,
                                                  fontStyle: FontStyle.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              SvgPicture.asset(
                                                AppImages.dateIcon,
                                                width: 14,
                                                height: 14,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                '${education.fromDate} - ${education.toDate}',
                                                style: TextStyle(
                                                  fontSize: FontSize.scale(
                                                      context, 12),
                                                  color: AppColors.greyColor(
                                                      context),
                                                  fontFamily:
                                                      AppFontFamily.font,
                                                  fontWeight: FontWeight.w400,
                                                  fontStyle: FontStyle.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 14),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    _openBottomSheet(
                                                      education: education,
                                                      isUpdate: true,
                                                      index: index,
                                                    );
                                                  },
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.whiteColor,
                                                    side: BorderSide(
                                                      color:
                                                          AppColors.greyColor(
                                                              context),
                                                      width: 0.1,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 30),
                                                  ),
                                                  child: Text(
                                                    "${Localization.translate("edit_text")}",
                                                    style: TextStyle(
                                                      fontSize: FontSize.scale(
                                                          context, 16),
                                                      color:
                                                          AppColors.greyColor(
                                                              context),
                                                      fontFamily:
                                                          AppFontFamily.font,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontStyle:
                                                          FontStyle.normal,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    _showRemoveDialog(
                                                        context, index);
                                                  },
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    backgroundColor: AppColors
                                                        .redBackgroundColor,
                                                    side: BorderSide(
                                                      color: AppColors
                                                          .redBorderColor,
                                                      width: 1,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 30),
                                                  ),
                                                  child: Text(
                                                    "${Localization.translate("delete_text")}",
                                                    style: TextStyle(
                                                      fontSize: FontSize.scale(
                                                          context, 14),
                                                      color: AppColors.blueColor,
                                                      fontFamily:
                                                          AppFontFamily.font,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontStyle:
                                                          FontStyle.normal,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5)
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                    Container(
                      height: Platform.isIOS ? screenHeight * 0.09 : screenHeight * 0.1,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        border:
                        Border(top: BorderSide(color: AppColors.dividerColor, width: 1)),
                      ),
                      padding: EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        top: 10.0,
                        bottom: MediaQuery.of(context).padding.bottom > 10.0 ? 23.0 : 20.0,
                      ),
                      child:ElevatedButton(
                        onPressed: () => _openBottomSheet(isUpdate: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen(context),
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: Text(
                          '${Localization.translate("add_new")}',
                          style: TextStyle(
                            fontSize: FontSize.scale(context, 16),
                            color: AppColors.blueColor,
                            fontFamily: AppFontFamily.font,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ),
                    ),

                    ],
                  ),
                ),
            ],
          ),
        ));
  }
}

Widget _buildSkeletonLoader(BuildContext context) {
  return Column(
    children: [
      Expanded(
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 14,
                        width: 200,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 14,
                          width: 200,
                          color: Colors.grey[300],
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 14,
                              height: 14,
                              color: Colors.grey[300],
                            ),
                          ),
                          SizedBox(width: 8),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 14,
                              width: 120,
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 14,
                              height: 14,
                              color: Colors.grey[300],
                            ),
                          ),
                          SizedBox(width: 8),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 14,
                              width: 150,
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            children: [
              SizedBox(
                height: 5,
              ),
              Container(
                height: 55,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border(
                      top:
                          BorderSide(width: 1.0, color: AppColors.dividerColor),
                    )),
              ),
              SizedBox(
                height: 10,
              )
            ],
          ),
        ),
      ),
      SizedBox(
        height: 10,
      )
    ],
  );
}

class Education {
  final int id;
  final String degree;
  final String institute;
  final String country;
  final String city;
  final String fromDate;
  final String toDate;
  final String description;
  final bool ongoing;

  Education({
    required this.id,
    required this.degree,
    required this.institute,
    required this.country,
    required this.city,
    required this.fromDate,
    required this.toDate,
    required this.description,
    this.ongoing = false,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    final countryData = json['country'] ?? {};
    final countryName =
        countryData is Map<String, dynamic> ? countryData['name'] ?? '' : '';

    return Education(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      degree: json['course_title'] as String? ?? '',
      institute: json['institute_name'] as String? ?? '',
      country: countryName,
      city: json['city'] as String? ?? '',
      fromDate: json['start_date'] as String? ?? '',
      toDate: json['end_date'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ongoing: json['ongoing'] == 1 || json['ongoing'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'degree': degree,
      'institute': institute,
      'country': country,
      'city': city,
      'fromDate': fromDate,
      'toDate': toDate,
      'description': description,
      'ongoing': ongoing ? "1" : "0",
    };
  }
}
