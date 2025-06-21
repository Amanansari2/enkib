
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
import 'package:flutter_projects/view/insights/component/custom_field.dart';
import 'package:flutter_projects/view/tutor/component/dialog_component.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ExperienceDetailsScreen extends StatefulWidget {
  @override
  _ExperienceDetailsScreenState createState() =>
      _ExperienceDetailsScreenState();
}

class _ExperienceDetailsScreenState extends State<ExperienceDetailsScreen> {
  List<String> _countries = [];
  Map<int, String> _countryMap = {};
  int? _selectedCountryId;
  String? _selectedCountry;
  bool _onPressLoading = false;
  bool _isFirstLoad = true;
  late double screenWidth;
  late double screenHeight;

  final Map<String, String> _employmentTypeMap = {
    "full_time": '${Localization.translate("full_time_label")}',
    "self_employed": '${Localization.translate("self_employed_label")}',
    "contract": '${Localization.translate("contract_label")}',
    "part_time": '${Localization.translate("part_time_label")}',
  };

  String? _selectedEmploymentTypeId;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
    _loadExperiences();
  }

  Future<void> _loadExperiences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final tutorId = authProvider.userId;

    try {
      await authProvider.fetchExperienceList(token, tutorId!,context);
      setState(() {
        _isFirstLoad = false;
      });
    } catch (e) {
      setState(() {
        _isFirstLoad = false;
      });
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
          return country['name'] as String;
        }).toList();
      });
    } catch (e) {}
  }

  void _showCountryBottomSheet(
      StateSetter setModalState, TextEditingController countryController) {
    showModalBottomSheet(
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

  void _openBottomSheet(
      {Experience? experience, int? index, required bool isUpdate}) {
    final TextEditingController jobTitleController = TextEditingController(
      text: experience != null ? experience.jobTitle : '',
    );
    final TextEditingController companyController = TextEditingController(
      text: experience != null ? experience.company : '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: experience != null ? experience.description : '',
    );

    DateTime? fromDate;
    try {
      fromDate = experience != null
          ? DateFormat('MMMM d, yyyy').parse(experience.fromDate)
          : null;
    } catch (e) {
    }

    DateTime? toDate;
    try {
      toDate = experience != null
          ? DateFormat('MMMM d, yyyy').parse(experience.toDate)
          : null;
    } catch (e) {
    }

    if (experience != null) {
      _selectedEmploymentTypeId = experience.employmentType;
      _selectedCountryId = _countryMap.entries
          .firstWhere((entry) => entry.value == experience.country,
              orElse: () => MapEntry(0, "Unknown"))
          .key;
    }

    final TextEditingController employmentTypeController =
        TextEditingController(
      text: experience != null
          ? _employmentTypeMap[experience.employmentType] ?? ''
          : '',
    );
    final TextEditingController countryController = TextEditingController(
      text: experience != null ? experience.country : '',
    );
    final TextEditingController cityController = TextEditingController(
      text: experience != null ? experience.city : '',
    );
    final TextEditingController locationTypeController = TextEditingController(
      text: experience != null ? capitalize(experience.location) : '',
    );

    bool _isChecked = experience?.isCurrent ?? false;

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
                        horizontal: 10.0, vertical: 10.0),
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
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            '${Localization.translate("experience_label")}',
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
                                    color: AppColors.greyColor(context).withOpacity(0.1),
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
                                  CustomField(
                                    controller: jobTitleController,
                                    labelText: '${Localization.translate("job_title")}',
                                    borderColor: _hasError &&
                                            jobTitleController.text.isEmpty
                                        ? AppColors.redColor
                                        : AppColors.dividerColor,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '${Localization.translate("field_required")}';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 10),
                                  CustomField(
                                    controller: companyController,
                                    labelText: '${Localization.translate("company_name")}',
                                    borderColor: _hasError &&
                                            companyController.text.isEmpty
                                        ? AppColors.redColor
                                        : AppColors.dividerColor,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '${Localization.translate("field_required")}';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 10),
                                  TextField(
                                    cursorColor: AppColors.blackColor,
                                    controller: employmentTypeController,
                                    onTap: () {
                                      _openEmploymentTypeBottomSheet(
                                          context,
                                          setModalState,
                                          employmentTypeController);
                                    },
                                    decoration: InputDecoration(
                                      labelText: '${Localization.translate("employment_type")}',
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
                                                    employmentTypeController
                                                        .text.isEmpty
                                                ? AppColors.redColor
                                                : AppColors.dividerColor,
                                            width: 1.5),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: _hasError &&
                                                    employmentTypeController
                                                        .text.isEmpty
                                                ? AppColors.redColor
                                                : AppColors.dividerColor,
                                            width: 1.5),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: _hasError &&
                                                    employmentTypeController
                                                        .text.isEmpty
                                                ? AppColors.redColor
                                                : AppColors.dividerColor,
                                            width: 1.5),
                                      ),
                                      contentPadding: EdgeInsets.only(bottom: 8),
                                      suffixIcon: Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 25,
                                        color:  AppColors.greyColor(context),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  TextField(
                                    cursorColor: AppColors.blackColor,
                                    controller: locationTypeController,
                                    onTap: () {
                                      _openCompanyTypeBottomSheet(context,
                                          setModalState, locationTypeController);
                                    },
                                    decoration: InputDecoration(
                                      labelText: '${Localization.translate("location")}',
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
                                                    locationTypeController
                                                        .text.isEmpty
                                                ? AppColors.redColor
                                                : AppColors.dividerColor,
                                            width: 1.5),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: _hasError &&
                                                    locationTypeController
                                                        .text.isEmpty
                                                ? AppColors.redColor
                                                : AppColors.dividerColor,
                                            width: 1.5),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: _hasError &&
                                                    locationTypeController
                                                        .text.isEmpty
                                                ? AppColors.redColor
                                                : AppColors.dividerColor,
                                            width: 1.5),
                                      ),
                                      contentPadding: EdgeInsets.only(bottom: 8),
                                      suffixIcon: Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 25,
                                        color:  AppColors.greyColor(context),
                                      ),
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
                                          labelText: '${Localization.translate("select_country")}',
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
                                                        countryController
                                                            .text.isEmpty
                                                    ? AppColors.redColor
                                                    : AppColors.dividerColor,
                                                width: 1.5),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: _hasError &&
                                                        countryController
                                                            .text.isEmpty
                                                    ? AppColors.redColor
                                                    : AppColors.dividerColor,
                                                width: 1.5),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: _hasError &&
                                                        countryController
                                                            .text.isEmpty
                                                    ? AppColors.redColor
                                                    : AppColors.dividerColor,
                                                width: 1.5),
                                          ),
                                          contentPadding:
                                              EdgeInsets.only(bottom: 8),
                                          suffixIcon: Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 25,
                                            color:  AppColors.greyColor(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  CustomField(
                                    controller: cityController,
                                    labelText: '${Localization.translate("city_name")}',
                                    borderColor:
                                        _hasError && cityController.text.isEmpty
                                            ? AppColors.redColor
                                            : AppColors.dividerColor,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '${Localization.translate("field_required")}';
                                      }
                                      return null;
                                    },
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
                                          labelText: '${Localization.translate("start_date")}',
                                          labelStyle: TextStyle(
                                            fontSize: FontSize.scale(context, 16),
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
                                                width: 1.5),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color:
                                                    _hasError && fromDate == null
                                                        ? AppColors.redColor
                                                        : AppColors.dividerColor,
                                                width: 1.5),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color:
                                                    _hasError && fromDate == null
                                                        ? AppColors.redColor
                                                        : AppColors.dividerColor,
                                                width: 1.5),
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
                                          labelText: '${Localization.translate("end_date")}',
                                          labelStyle: TextStyle(
                                            fontSize: FontSize.scale(context, 16),
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
                                                width: 1.5),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: _hasError && toDate == null
                                                    ? AppColors.redColor
                                                    : AppColors.dividerColor,
                                                width: 1.5),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: _hasError && toDate == null
                                                    ? AppColors.redColor
                                                    : AppColors.dividerColor,
                                                width: 1.5),
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
                                            activeColor: AppColors.primaryGreen(context),
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
                                          offset: Offset(-12, -10),
                                          child: Text(
                                            '${Localization.translate("experience_detail_text")}',
                                            style: TextStyle(
                                              fontSize:
                                                  FontSize.scale(context, 16),
                                              color: AppColors.greyColor(context),
                                              fontWeight: FontWeight.w400,
                                              fontFamily: AppFontFamily.font,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(
                                    color: AppColors.dividerColor,
                                    thickness: 2,
                                    height: 1,
                                    indent: 2.0,
                                    endIndent: 2.0,
                                  ),
                                  TextField(
                                    cursorColor: AppColors.blackColor,
                                    controller: descriptionController,
                                    maxLines: 5,
                                    decoration: InputDecoration(
                                      labelText: '${Localization.translate("description")}',
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
                                      contentPadding: EdgeInsets.only(bottom: 10),
                                      alignLabelWithHint: true,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () async {
                                      setModalState(() {
                                        _hasError = false;
                                      });

                                      if (jobTitleController.text.isEmpty ||
                                          companyController.text.isEmpty ||
                                          cityController.text.isEmpty ||
                                          countryController.text.isEmpty ||
                                          employmentTypeController.text.isEmpty ||
                                          locationTypeController.text.isEmpty ||
                                          fromDate == null ||
                                          toDate == null ||
                                          descriptionController.text.isEmpty) {
                                        setModalState(() {
                                          _hasError = true;
                                        });

                                        if (jobTitleController.text.isEmpty ||
                                            companyController.text.isEmpty ||
                                            cityController.text.isEmpty ||
                                            countryController.text.isEmpty ||
                                            employmentTypeController
                                                .text.isEmpty ||
                                            locationTypeController.text.isEmpty) {
                                          showCustomToast(
                                              context,
                                              "${Localization.translate("required_fields")}",
                                              false);
                                        } else if (fromDate == null ||
                                            toDate == null) {
                                          showCustomToast(context,
                                              "${Localization.translate("select_dates")}.", false);
                                        } else if (descriptionController
                                            .text.isEmpty) {
                                          showCustomToast(context,
                                              "${Localization.translate("description_required")}", false);
                                        }

                                        return;
                                      }

                                      if (jobTitleController.text.isNotEmpty &&
                                          companyController.text.isNotEmpty &&
                                          fromDate != null &&
                                          (toDate != null || _isChecked)) {
                                        final authProvider =
                                            Provider.of<AuthProvider>(context,
                                                listen: false);
                                        final token = authProvider.token;

                                        if (_selectedCountryId == null ||
                                            _selectedCountryId == 0) {
                                          showCustomToast(
                                              context,
                                              "${Localization.translate("country_validation_message")}",
                                              false);
                                          return;
                                        }

                                        String? employmentTypeKey;
                                        _employmentTypeMap.forEach((key, value) {
                                          if (value ==
                                              employmentTypeController.text) {
                                            employmentTypeKey = key;
                                          }
                                        });

                                        if (employmentTypeKey == null) {
                                          showCustomToast(
                                              context,
                                              "${Localization.translate("valid_employment_message")}",
                                              false);
                                          return;
                                        }

                                        final Map<String, dynamic>
                                            experienceData = {
                                          "title": jobTitleController.text,
                                          "employment_type": employmentTypeKey,
                                          "company": companyController.text,
                                          "location": locationTypeController.text
                                              .toLowerCase(),
                                          "country":
                                              _selectedCountryId!.toString(),
                                          "city": cityController.text,
                                          "start_date": DateFormat('yyyy-MM-dd')
                                              .format(fromDate!),
                                          "end_date": toDate != null
                                              ? DateFormat('yyyy-MM-dd')
                                                  .format(toDate!)
                                              : '',
                                          "is_current": _isChecked ? "1" : "0",
                                          "description":
                                              descriptionController.text,
                                        };

                                        try {
                                          setModalState(() {
                                            _onPressLoading = true;
                                            _isFirstLoad =true;
                                          });
                                          final response = isUpdate
                                              ? await updateExperience(token!,
                                                  experience!.id, experienceData)
                                              : await addExperience(
                                                  token!, experienceData);

                                          if (response['status'] == 200) {
                                            final responseData = response['data'];
                                            final employmentType =
                                                responseData['employment_type'];
                                            final countryId =
                                                responseData['country_id'];
                                            final countryName = _countryMap[
                                                    int.parse(countryId)] ??
                                                "Unknown Country";

                                            final newExperience = Experience(
                                              id: responseData['id'] ?? 0,
                                              jobTitle:
                                                  responseData['title'] ?? '',
                                              company:
                                                  responseData['company'] ?? '',
                                              country: countryName,
                                              city: responseData['city'] ??
                                                  'Unknown City',
                                              employmentType: employmentType,
                                              location:
                                                  responseData['location'] ?? '',
                                              fromDate:
                                                  responseData['start_date'] ??
                                                      '',
                                              toDate:
                                                  responseData['end_date'] ?? '',
                                              description:
                                                  responseData['description'] ??
                                                      '',
                                            );

                                            if (isUpdate) {
                                              authProvider.updateExperienceList(index!,
                                                  newExperience);
                                            } else {
                                              await authProvider
                                                  .saveExperience(newExperience);
                                            }
                                            await authProvider.fetchExperienceList(token, authProvider.userId!,context);

                                            Navigator.pop(context);

                                            showCustomToast(
                                              context,
                                              response['message'],
                                              true,
                                            );
                                          } else if (response['status'] == 403) {
                                            showCustomToast(
                                              context,
                                              response['message'],
                                              false,
                                            );
                                          } else if (response['status'] == 401) {
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
                                            final errors = response['errors'];
                                            if (errors != null &&
                                                errors.isNotEmpty) {
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

                                              showCustomToast(
                                                context,
                                                errorMessage.trim(),
                                                false,
                                              );
                                            } else {
                                              showCustomToast(
                                                context,
                                                response['message'] ??
                                                    "An unknown error occurred.",
                                                false,
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          showCustomToast(
                                              context, '${e.toString()}', false);
                                        } finally {
                                          setModalState(() {
                                            _onPressLoading = false;
                                            _isFirstLoad=false;

                                          });
                                        }
                                      } else {
                                        showCustomToast(
                                          context,
                                          "${Localization.translate("required_fields")}",
                                          false,
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen(context),
                                      minimumSize: Size(double.infinity, 45),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${Localization.translate("save_update")}',
                                          style: TextStyle(
                                            fontSize: FontSize.scale(context, 16),
                                            color: AppColors.blueColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (_onPressLoading) ...[
                                          SizedBox(width: 10),

                                           SpinKitCircle(
                                             size: 25,
                                              color: AppColors.blueColor,
                                            ),

                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 30),
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
      },
    );
  }

  void _openEmploymentTypeBottomSheet(BuildContext context,
      StateSetter setModalState, TextEditingController controller) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: Localization.textDirection,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                height: screenHeight * 0.42,
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
                      horizontal: 10.0, vertical: 10.0),
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
                          '${Localization.translate("employment_type_label")}',
                          style: TextStyle(
                            fontSize: FontSize.scale(context, 18),
                            color: AppColors.blackColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: _employmentTypeMap.entries.map((entry) {
                                return Column(
                                  children: [
                                    _buildRadioTile(
                                      context: context,
                                      value: entry.value,
                                      groupValue: controller.text,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedEmploymentTypeId = entry.key;
                                          controller.text = value!;
                                          Navigator.pop(context);
                                        });
                                      },
                                    ),
                                    Divider(
                                      color: AppColors.dividerColor,
                                      thickness: 1,
                                      height: 1,
                                      indent: 16.0,
                                      endIndent: 16.0,
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openCompanyTypeBottomSheet(BuildContext context,
      StateSetter setModalState, TextEditingController controller) {
    final List<String> _locationTypes = ['remote', 'onsite', 'hybrid'];

    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: Localization.textDirection,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                height: screenHeight * 0.35,
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
                      horizontal: 10.0, vertical: 10.0),
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
                          'Select Location Type',
                          style: TextStyle(
                            fontSize: FontSize.scale(context, 18),
                            color: AppColors.blackColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
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
                              children:
                                  List.generate(_locationTypes.length, (index) {
                                final locationType = _locationTypes[index];
                                return Column(
                                  children: [
                                    _buildRadioTile(
                                      context: context,
                                      value: capitalize(locationType),
                                      groupValue: controller.text,
                                      onChanged: (value) {
                                        setState(() {
                                          controller.text = value!;
                                          Navigator.pop(context);
                                        });
                                      },
                                    ),
                                    if (index != _locationTypes.length - 1)
                                      Divider(
                                        color: AppColors.dividerColor,
                                        thickness: 1,
                                        height: 1,
                                        indent: 16.0,
                                        endIndent: 16.0,
                                      ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRadioTile({
    required BuildContext context,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(value),
      trailing: Radio<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: AppColors.primaryGreen(context),
        fillColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return AppColors.primaryGreen(context);
            }
            return AppColors.greyColor(context);
          },
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      onTap: () {
        onChanged(value);
      },
    );
  }

  String capitalize(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }



  void _showRemoveDialog(BuildContext context, int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (index >= 0 && index < authProvider.experienceList.length) {
      final experienceId = authProvider.experienceList[index].id;

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return DialogComponent(
            onRemove: () async {
              if (token != null) {
                try {
                  final response = await deleteExperience(token, experienceId);

                  if (response['status'] == 200) {
                    await authProvider.removeExperience(index);
                    await authProvider.fetchExperienceList(token, authProvider.userId!,context);

                    final message = response['message'] ?? '${Localization.translate("experience_removed")}';

                    if (context.mounted) {
                      showCustomToast(context, message, true);
                    }
                  }
                  else if (response['status'] == 403) {
                    showCustomToast(
                      context,
                      response['message'],
                      false,
                    );
                  } else if (response['status'] == 401) {
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
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                            );
                          },
                          showCancelButton: false,
                        );
                      },
                    );
                  }

                  else {
                    final errorMessage = response['message'] ?? "${Localization.translate("experience_delete_failed")}";
                    Navigator.of(context).pop();
                    showCustomToast(context, errorMessage, false);
                  }
                } catch (error) {
                  if (context.mounted) {
                    showCustomToast(context, "Error occurred: $error", false);
                  }
                }
              } else {
                if (context.mounted) {
                  showCustomToast(context, "${Localization.translate("unauthorized_access")}", false);
                }
              }
            },
            title: '${Localization.translate("remove_alert_message")}',
            message: "${Localization.translate("remove_item_text")}",
          );
        },
      );
    } else {
      if (context.mounted) {
        showCustomToast(context, "Invalid operation. Please try again.", false);
      }
    }
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
                  '${Localization.translate("experience_details_label")}',
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
              Expanded(child: _buildSkeletonLoader(context))
            else if (authProvider.experienceList.isEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        AppImages.emptyExperience,
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
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '${Localization.translate("record_empty_message")}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 12),
                          color: AppColors.greyColor(context),
                          fontFamily: AppFontFamily.font,
                          fontWeight: FontWeight.w400,
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ListView.builder(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0),
                      itemCount: authProvider.experienceList.length,
                      itemBuilder: (context, index) {
                        final experience = authProvider.experienceList[index];

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
                                child: Text(
                                  experience.jobTitle,
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 12),
                                    color: AppColors.greyColor(context),
                                    fontFamily: AppFontFamily.font,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                    experience.company,
                                    style: TextStyle(
                                      fontSize: FontSize.scale(context, 15),
                                      color: AppColors.blackColor,
                                      fontFamily: AppFontFamily.font,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                                        '${experience.fromDate} - ${experience.toDate}',
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 12),
                                          color: AppColors.greyColor(context),
                                          fontFamily: AppFontFamily.font,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        AppImages.locationIcon,
                                        width: 14,
                                        height: 14,
                                        color: AppColors.greyColor(context),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        experience.country.isNotEmpty &&
                                                experience.city.isNotEmpty
                                            ? '${experience.country}, ${experience.city}'
                                            : "${Localization.translate("location_empty")}",
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 12),
                                          color: AppColors.greyColor(context),
                                          fontFamily: AppFontFamily.font,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        AppImages.briefcase,
                                        width: 14,
                                        height: 14,
                                        color: AppColors.greyColor(context),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        _employmentTypeMap[
                                                experience.employmentType] ??
                                            "Unknown",
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 12),
                                          color: AppColors.greyColor(context),
                                          fontFamily: AppFontFamily.font,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      SvgPicture.asset(
                                        AppImages.locationIcon,
                                        width: 14,
                                        height: 14,
                                        color: AppColors.greyColor(context),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        experience.location[0].toUpperCase() +
                                            experience.location
                                                .substring(1)
                                                .toLowerCase(),
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 12),
                                          color: AppColors.greyColor(context),
                                          fontFamily: AppFontFamily.font,
                                          fontWeight: FontWeight.w400,
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
                                              experience: experience,
                                              isUpdate: true,
                                              index: index,
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: AppColors.whiteColor,
                                            side: BorderSide(
                                              color: AppColors.greyColor(context),
                                              width: 0.1,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 30),
                                          ),
                                          child: Text(
                                            "${Localization.translate("edit_text")}",
                                            style: TextStyle(
                                              fontSize:
                                                  FontSize.scale(context, 16),
                                              color: AppColors.greyColor(context),
                                              fontFamily: AppFontFamily.font,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            _showRemoveDialog(context, index);
                                          },
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.redBackgroundColor,
                                            side: BorderSide(
                                              color: AppColors.redBorderColor,
                                              width: 1,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 30),
                                          ),
                                          child: Text(
                                            "${Localization.translate("delete_text")}",
                                            style: TextStyle(
                                              fontSize:
                                                  FontSize.scale(context, 14),
                                              color: AppColors.blueColor,
                                              fontFamily: AppFontFamily.font,
                                              fontWeight: FontWeight.w500,
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
                    );
                  },
                ),
              ),
            if (_isFirstLoad)
                Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
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
                                top: BorderSide(
                                    width: 1.0, color: AppColors.dividerColor),
                              )),
                        ),
                        SizedBox(
                          height: 10,
                        )
                      ],
                    ),
                  ),
                )
            else if (authProvider.experienceList.isNotEmpty)
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
    );
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
                        height: 16,
                        width: double.infinity,
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
                          width: 150,
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
                              width: 80,
                              color: Colors.grey[300],
                            ),
                          ),
                          SizedBox(width: 10),
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
                              width: 80,
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
    ],
  );
}

class Experience {
  final int id;
  final String jobTitle;
  final String company;
  final String location;
  final String country;
  final String city;
  final String employmentType;
  final String fromDate;
  final String toDate;
  final String description;
  final bool isCurrent;

  Experience({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.country,
    required this.city,
    required this.employmentType,
    required this.fromDate,
    required this.toDate,
    required this.description,
    this.isCurrent = false,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']) ?? 0,
      jobTitle: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      country: json['country']['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      employmentType: json['employment_type'] as String ?? '',
      location: json['location'] as String? ?? '',
      fromDate: json['start_date'] as String? ?? '',
      toDate: json['end_date'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isCurrent: json['is_current'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': jobTitle,
      'company': company,
      'location': location,
      'country': country,
      'city': city,
      'employment_type': employmentType,
      'fromDate': fromDate,
      'toDate': toDate,
      'description': description,
      'is_current': isCurrent ? "1" : "0",
    };
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
  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}
