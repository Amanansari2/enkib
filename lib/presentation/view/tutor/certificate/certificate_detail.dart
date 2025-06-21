import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../data/localization/localization.dart';
import '../../../../data/provider/auth_provider.dart';
import '../../../../domain/api_structure/api_service.dart';
import '../../auth/login_screen.dart';
import '../../components/login_required_alert.dart';
import '../component/dialog_component.dart';

class CertificateDetail extends StatefulWidget {
  @override
  _CertificateDetailState createState() => _CertificateDetailState();
}

class _CertificateDetailState extends State<CertificateDetail> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  late double screenWidth;
  late double screenHeight;
  bool _onPressLoading = false;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadAndUpdateCertificates();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final tutorId = authProvider.userId;
    authProvider
        .fetchCertificationList(token, tutorId!, context)
        .then((_) {
          setState(() {
            _isFirstLoad = false;
          });
        })
        .catchError((e) {
          setState(() {
            _isFirstLoad = false;
          });
        });
  }

  Future<void> _loadAndUpdateCertificates() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final tutorId = authProvider.userId;
    await Provider.of<AuthProvider>(
      context,
      listen: false,
    ).fetchCertificationList(token, tutorId!, context);
  }

  void _openBottomSheet({
    Certificate? certificate,
    int? index,
    required bool isUpdate,
  }) {
    final TextEditingController jobTitleController = TextEditingController(
      text: certificate != null ? certificate.jobTitle : '',
    );
    final TextEditingController companyController = TextEditingController(
      text: certificate != null ? certificate.company : '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: certificate != null ? certificate.description : '',
    );

    DateTime? fromDate;
    try {
      fromDate =
          certificate != null
              ? DateFormat('MMM dd, yyyy').parse(certificate.fromDate)
              : null;
    } catch (e) {}

    DateTime? toDate;
    try {
      toDate =
          certificate != null
              ? DateFormat('MMM dd, yyyy').parse(certificate.toDate)
              : null;
    } catch (e) {}

    if (isUpdate && certificate?.imagePath != null) {
      _selectedImage = null;
    } else if (certificate?.imagePath != null &&
        certificate!.imagePath!.isNotEmpty) {
      _selectedImage = File(certificate!.imagePath!);
    } else {
      _selectedImage = null;
    }

    Future<void> _selectDate(
      BuildContext context,
      DateTime? initialDate,
      Function(DateTime) onDateSelected,
      StateSetter setModalState,
    ) async {
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
        setModalState(() {});
      }
    }

    Future<void> _showPhotoActionSheet(StateSetter setModalState) async {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setModalState(() {
          _selectedImage = File(pickedFile.path);
        });
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
                      horizontal: 10.0,
                      vertical: 10.0,
                    ),
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
                            '${Localization.translate("certificate_detail_label")}',
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 18),
                              color: AppColors.blackColor,
                              fontFamily: AppFontFamily.mediumFont,
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
                                  SizedBox(height: 15),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          _showPhotoActionSheet(setModalState);
                                        },
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            if (_selectedImage != null)
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.rectangle,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  image: DecorationImage(
                                                    image: FileImage(
                                                      _selectedImage!,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              )
                                            else if (certificate?.imagePath !=
                                                    null &&
                                                certificate!.imagePath!
                                                    .startsWith('http'))
                                              CachedNetworkImage(
                                                imageUrl:
                                                    certificate!.imagePath!,
                                                placeholder:
                                                    (
                                                      context,
                                                      url,
                                                    ) => Shimmer.fromColors(
                                                      baseColor:
                                                          Colors.grey[300]!,
                                                      highlightColor:
                                                          Colors.grey[100]!,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color:
                                                              AppColors
                                                                  .whiteColor,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Image.asset(
                                                          AppImages
                                                              .placeHolderImage,
                                                          fit: BoxFit.cover,
                                                          width: 50,
                                                          height: 50,
                                                        ),
                                                fit: BoxFit.cover,
                                                width: 50,
                                                height: 50,
                                              )
                                            else
                                              Image.asset(
                                                AppImages.placeHolderImage,
                                                fit: BoxFit.cover,
                                                width: 50,
                                                height: 50,
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
                                                    width: 2,
                                                  ),
                                                ),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    _showPhotoActionSheet(
                                                      setModalState,
                                                    );
                                                  },
                                                  child: CircleAvatar(
                                                    radius: 12,
                                                    backgroundColor:
                                                        AppColors.primaryGreen(
                                                          context,
                                                        ),
                                                    child: Icon(
                                                      Icons.add,
                                                      size: 16,
                                                      color:
                                                          AppColors.whiteColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 15),
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${Localization.translate("upload_certificate")}',
                                              style: TextStyle(
                                                color: AppColors.blackColor,
                                                fontSize: FontSize.scale(
                                                  context,
                                                  14,
                                                ),
                                                fontFamily:
                                                    AppFontFamily.regularFont,
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                              ),
                                            ),
                                            Text(
                                              '${Localization.translate("certificate_image_size")}',
                                              style: TextStyle(
                                                color: AppColors.greyColor(
                                                  context,
                                                ),
                                                fontSize: FontSize.scale(
                                                  context,
                                                  12,
                                                ),
                                                fontFamily:
                                                    AppFontFamily.regularFont,
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 15),
                                  Divider(
                                    color: AppColors.dividerColor,
                                    height: 0,
                                    thickness: 1.5,
                                    indent: 2,
                                    endIndent: 2,
                                  ),
                                  SizedBox(height: 10),
                                  TextField(
                                    cursorColor: AppColors.blackColor,
                                    controller: jobTitleController,
                                    decoration: InputDecoration(
                                      labelText:
                                          '${Localization.translate("certificate_title")}',
                                      labelStyle: TextStyle(
                                        fontSize: FontSize.scale(context, 16),
                                        color: AppColors.greyColor(context),
                                        fontFamily: AppFontFamily.regularFont,
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.normal,
                                      ),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              _hasError &&
                                                      jobTitleController
                                                          .text
                                                          .isEmpty
                                                  ? AppColors.redColor
                                                  : AppColors.dividerColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              _hasError &&
                                                      jobTitleController
                                                          .text
                                                          .isEmpty
                                                  ? AppColors.redColor
                                                  : AppColors.dividerColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              _hasError &&
                                                      jobTitleController
                                                          .text
                                                          .isEmpty
                                                  ? AppColors.redColor
                                                  : AppColors.dividerColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.only(
                                        bottom: 8,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  TextField(
                                    cursorColor: AppColors.blackColor,
                                    controller: companyController,
                                    decoration: InputDecoration(
                                      labelText:
                                          '${Localization.translate("institute_title")}',
                                      labelStyle: TextStyle(
                                        fontSize: FontSize.scale(context, 16),
                                        color: AppColors.greyColor(context),
                                        fontFamily: AppFontFamily.regularFont,
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.normal,
                                      ),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              _hasError &&
                                                      companyController
                                                          .text
                                                          .isEmpty
                                                  ? AppColors.redColor
                                                  : AppColors.dividerColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              _hasError &&
                                                      companyController
                                                          .text
                                                          .isEmpty
                                                  ? AppColors.redColor
                                                  : AppColors.dividerColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              _hasError &&
                                                      companyController
                                                          .text
                                                          .isEmpty
                                                  ? AppColors.redColor
                                                  : AppColors.dividerColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.only(
                                        bottom: 8,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  GestureDetector(
                                    onTap:
                                        () => _selectDate(context, fromDate, (
                                          selectedDate,
                                        ) {
                                          setModalState(() {
                                            fromDate = selectedDate;
                                          });
                                        }, setModalState),
                                    child: AbsorbPointer(
                                      child: TextField(
                                        cursorColor: AppColors.blackColor,
                                        controller: TextEditingController(
                                          text:
                                              fromDate != null
                                                  ? DateFormat(
                                                    'MMM dd, yyyy',
                                                  ).format(fromDate!)
                                                  : '',
                                        ),
                                        decoration: InputDecoration(
                                          labelText:
                                              '${Localization.translate("start_date")}',
                                          labelStyle: TextStyle(
                                            fontSize: FontSize.scale(
                                              context,
                                              16,
                                            ),
                                            color: AppColors.greyColor(context),
                                            fontFamily:
                                                AppFontFamily.regularFont,
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
                                          contentPadding: EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          suffixIcon: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                            ),
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
                                    onTap:
                                        () => _selectDate(context, toDate, (
                                          selectedDate,
                                        ) {
                                          setModalState(() {
                                            toDate = selectedDate;
                                          });
                                        }, setModalState),
                                    child: AbsorbPointer(
                                      child: TextField(
                                        cursorColor: AppColors.blackColor,
                                        controller: TextEditingController(
                                          text:
                                              toDate != null
                                                  ? DateFormat(
                                                    'MMM dd, yyyy',
                                                  ).format(toDate!)
                                                  : '',
                                        ),
                                        decoration: InputDecoration(
                                          labelText:
                                              '${Localization.translate("end_date")}',
                                          labelStyle: TextStyle(
                                            fontSize: FontSize.scale(
                                              context,
                                              16,
                                            ),
                                            color: AppColors.greyColor(context),
                                            fontFamily:
                                                AppFontFamily.regularFont,
                                            fontWeight: FontWeight.w400,
                                            fontStyle: FontStyle.normal,
                                          ),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  _hasError && toDate == null
                                                      ? AppColors.redColor
                                                      : AppColors.dividerColor,
                                              width: 1.5,
                                            ),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  _hasError && toDate == null
                                                      ? AppColors.redColor
                                                      : AppColors.dividerColor,
                                              width: 1.5,
                                            ),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  _hasError && toDate == null
                                                      ? AppColors.redColor
                                                      : AppColors.dividerColor,
                                              width: 1.5,
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          suffixIcon: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                            ),
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
                                        fontFamily: AppFontFamily.regularFont,
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.normal,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.only(
                                        bottom: 8,
                                      ),
                                      alignLabelWithHint: true,
                                    ),
                                  ),
                                  SizedBox(height: 10),

                                  ElevatedButton(
                                    onPressed:
                                     _onPressLoading ? null
                                      :() async {
                                      setModalState(() {
                                        _hasError = false;
                                      });
                                      if (jobTitleController.text.isEmpty ||
                                          companyController.text.isEmpty ||
                                          fromDate == null ||
                                          toDate == null ||
                                          descriptionController.text.isEmpty) {
                                        setModalState(() {
                                          _hasError = true;
                                        });

                                        if (jobTitleController.text.isEmpty ||
                                            companyController.text.isEmpty) {
                                          showCustomToast(
                                            context,
                                            "${Localization.translate("required_fields")}",
                                            false,
                                          );
                                        } else if (fromDate == null ||
                                            toDate == null) {
                                          showCustomToast(
                                            context,
                                            "${Localization.translate("select_dates")}",
                                            false,
                                          );
                                        } else if (descriptionController
                                            .text
                                            .isEmpty) {
                                          showCustomToast(
                                            context,
                                            "${Localization.translate("description_required")}",
                                            false,
                                          );
                                        }
                                        return;
                                      }
                                      if (_selectedImage == null &&
                                          (certificate?.imagePath == null ||
                                              certificate!
                                                  .imagePath!
                                                  .isEmpty)) {
                                        showCustomToast(
                                          context,
                                          "${Localization.translate("image_required")}",
                                          false,
                                        );
                                        return;
                                      }
                                      final Certificate
                                      certificateToSubmit = Certificate(
                                        id: certificate?.id ?? 0,
                                        imagePath:
                                            _selectedImage != null
                                                ? _selectedImage?.path
                                                : certificate?.imagePath ?? "",
                                        jobTitle: jobTitleController.text,
                                        company: companyController.text,
                                        description: descriptionController.text,
                                        fromDate: DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(fromDate!),
                                        toDate: DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(toDate!),
                                      );

                                      try {
                                        setModalState(() {
                                          _onPressLoading = true;
                                          _isFirstLoad = true;
                                        });

                                        final authProvider =
                                            Provider.of<AuthProvider>(
                                              context,
                                              listen: false,
                                            );
                                        final token = authProvider.token;

                                        if (token != null) {
                                          Map<String, dynamic> response;

                                          if (certificateToSubmit.id != 0) {
                                            response = await authProvider
                                                .updateCertificateToApi(
                                                  token,
                                                  certificateToSubmit,
                                                );
                                          } else {
                                            response = await authProvider
                                                .addCertificateToApi(
                                                  token,
                                                  certificateToSubmit,
                                                );
                                          }

                                          if (response['status'] == 200) {
                                            await authProvider
                                                .fetchCertificationList(
                                                  token,
                                                  authProvider.userId!,
                                                  context,
                                                );

                                            showCustomToast(
                                              context,
                                              response['message'],
                                              true,
                                            );
                                            Navigator.pop(context);
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
                                              false,
                                            );
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (BuildContext context) {
                                                return CustomAlertDialog(
                                                  title: Localization.translate(
                                                    'invalidToken',
                                                  ),
                                                  content:
                                                      Localization.translate(
                                                        'loginAgain',
                                                      ),
                                                  buttonText:
                                                      Localization.translate(
                                                        'goToLogin',
                                                      ),
                                                  buttonAction: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                                LoginScreen(),
                                                      ),
                                                    );
                                                  },
                                                  showCancelButton: false,
                                                );
                                              },
                                            );
                                          } else {
                                            final errorMessages =
                                                response['errors']?.values.join(
                                                  ', ',
                                                ) ??
                                                'Unknown error occurred';
                                            showCustomToast(
                                              context,
                                              'Failed to process certificate: $errorMessages',
                                              false,
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        String errorMessage = e.toString();
                                        showCustomToast(
                                          context,
                                          errorMessage,
                                          false,
                                        );
                                      } finally {
                                        setModalState(() {
                                          _onPressLoading = false;
                                          _isFirstLoad = false;
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen(
                                        context,
                                      ),
                                      minimumSize: Size(double.infinity, 45),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${Localization.translate("save_update")}',
                                          style: TextStyle(
                                            fontSize: FontSize.scale(
                                              context,
                                              16,
                                            ),
                                            color: AppColors.whiteColor,
                                            fontWeight: FontWeight.w500,
                                            fontFamily:
                                                AppFontFamily.mediumFont,
                                          ),
                                        ),
                                        if (_onPressLoading) ...[
                                          SizedBox(width: 10),
                                          SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primaryGreen(context),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 20),
                                  Text(
                                    '${Localization.translate("certificate_detail_text")}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: FontSize.scale(context, 14),
                                      color: AppColors.greyColor(
                                        context,
                                      ).withOpacity(0.7),
                                      fontFamily: AppFontFamily.mediumFont,
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
      },
    );
  }

  void _showRemoveDialog(BuildContext context, int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (index >= 0 && index < authProvider.certificateList.length) {
      final certificateId = authProvider.certificateList[index].id;

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return DialogComponent(
            onRemove: () async {
              if (token != null) {
                try {
                  final response = await deleteCertification(
                    token,
                    certificateId,
                  );

                  if (response['status'] == 200) {
                    final message =
                        response['message'] ??
                        '${Localization.translate("delete_certificate_message")}';

                    if (context.mounted) {
                      showCustomToast(context, message, true);
                    }

                    await authProvider.removeCertificate(index);
                    await authProvider.fetchCertificationList(
                      token,
                      authProvider.userId!,
                      context,
                    );
                  } else if (response['status'] == 403) {
                    showCustomToast(context, response['message'], false);
                  } else if (response['status'] == 401) {
                    showCustomToast(
                      context,
                      '${Localization.translate("unauthorized_access")}',
                      false,
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
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                          },
                          showCancelButton: false,
                        );
                      },
                    );
                  } else {
                    if (context.mounted) {
                      showCustomToast(
                        context,
                        "${Localization.translate("failed_delete_certificate_message")} ${response['message']}",
                        false,
                      );
                    }
                  }
                } catch (error) {
                  if (context.mounted) {
                    showCustomToast(context, "Error occurred: $error", false);
                  }
                }
              } else {
                if (context.mounted) {
                  showCustomToast(
                    context,
                    "${Localization.translate("unauthorized_access")}",
                    false,
                  );
                }
              }
            },
            title: '${Localization.translate("remove_alert_message")}',
            message: "${Localization.translate("remove_item_text")}",
          );
        },
      );
    } else {
      showCustomToast(context, "Invalid operation. Please try again.", false);
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
                  '${Localization.translate("certificate_awards_title")}',
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
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: AppColors.blackColor,
                    ),
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
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Column(
              children: [
                if (_isFirstLoad)
                  Expanded(child: _buildSkeletonLoader(context))
                else if (authProvider.certificateList.isEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            AppImages.emptyCertificate,
                            width: 80,
                            height: 80,
                          ),
                          SizedBox(height: 15),
                          Text(
                            '${Localization.translate("record_empty")}',
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 16),
                              color: AppColors.blackColor.withOpacity(0.7),
                              fontFamily: AppFontFamily.mediumFont,
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
                              fontFamily: AppFontFamily.mediumFont,
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
                                fontFamily: AppFontFamily.mediumFont,
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
                    child:
                        _isFirstLoad
                            ? _buildSkeletonLoader(context)
                            : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 20.0,
                              ),
                              itemCount: authProvider.certificateList.length,
                              itemBuilder: (context, index) {
                                final certificate =
                                    authProvider.certificateList[index];
                                final issuedDate = certificate.fromDate;
                                final expiryDate = certificate.toDate;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.whiteColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Flexible(
                                                flex: 0,
                                                child: Container(
                                                  width: 70,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child:
                                                      certificate.imagePath !=
                                                                  null &&
                                                              certificate
                                                                  .imagePath!
                                                                  .isNotEmpty
                                                          ? ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),

                                                            child: Image.network(
                                                              Uri.encodeFull(
                                                                certificate
                                                                    .imagePath!,
                                                              ),
                                                              fit: BoxFit.cover,
                                                              loadingBuilder: (
                                                                context,
                                                                child,
                                                                loadingProgress,
                                                              ) {
                                                                if (loadingProgress ==
                                                                    null) {
                                                                  return child;
                                                                }
                                                                return Shimmer.fromColors(
                                                                  baseColor:
                                                                      Colors
                                                                          .grey[300]!,
                                                                  highlightColor:
                                                                      Colors
                                                                          .grey[100]!,
                                                                  child: Container(
                                                                    decoration: BoxDecoration(
                                                                      color:
                                                                          AppColors
                                                                              .whiteColor,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            8,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                              errorBuilder: (
                                                                context,
                                                                error,
                                                                stackTrace,
                                                              ) {
                                                                return Image.asset(
                                                                  AppImages
                                                                      .placeHolderImage,
                                                                  fit:
                                                                      BoxFit
                                                                          .cover,
                                                                );
                                                              },
                                                            ),
                                                          )
                                                          : Image.asset(
                                                            AppImages
                                                                .placeHolderImage,
                                                            fit: BoxFit.cover,
                                                          ),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      certificate.company,
                                                      style: TextStyle(
                                                        fontSize:
                                                            FontSize.scale(
                                                              context,
                                                              16,
                                                            ),
                                                        color:
                                                            AppColors
                                                                .blackColor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontFamily:
                                                            AppFontFamily
                                                                .mediumFont,
                                                      ),
                                                    ),
                                                    Text(
                                                      certificate.jobTitle,
                                                      style: TextStyle(
                                                        fontSize:
                                                            FontSize.scale(
                                                              context,
                                                              14,
                                                            ),
                                                        color:
                                                            AppColors.greyColor(
                                                              context,
                                                            ),
                                                        fontFamily:
                                                            AppFontFamily
                                                                .regularFont,
                                                      ),
                                                    ),
                                                  ],
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
                                                child: Row(
                                                  children: [
                                                    SvgPicture.asset(
                                                      AppImages.dateIcon,
                                                      width: 12,
                                                      height: 12,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Expanded(
                                                      child: RichText(
                                                        text: TextSpan(
                                                          text:
                                                              issuedDate ?? "",
                                                          style: TextStyle(
                                                            fontFamily:
                                                                AppFontFamily
                                                                    .mediumFont,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize:
                                                                FontSize.scale(
                                                                  context,
                                                                  14,
                                                                ),
                                                            color:
                                                                AppColors.greyColor(
                                                                  context,
                                                                ),
                                                          ),
                                                          children: <
                                                            InlineSpan
                                                          >[
                                                            WidgetSpan(
                                                              child: SizedBox(
                                                                width: 5,
                                                              ),
                                                            ),
                                                            TextSpan(
                                                              text:
                                                                  '${Localization.translate("certificate_issued_text")}',
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    AppFontFamily
                                                                        .regularFont,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                fontSize:
                                                                    FontSize.scale(
                                                                      context,
                                                                      14,
                                                                    ),
                                                                color:
                                                                    AppColors.greyColor(
                                                                      context,
                                                                    ).withOpacity(
                                                                      0.7,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    SvgPicture.asset(
                                                      AppImages.dateIcon,
                                                      width: 12,
                                                      height: 12,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Expanded(
                                                      child: RichText(
                                                        text: TextSpan(
                                                          text:
                                                              expiryDate ?? "",
                                                          style: TextStyle(
                                                            fontFamily:
                                                                AppFontFamily
                                                                    .mediumFont,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize:
                                                                FontSize.scale(
                                                                  context,
                                                                  14,
                                                                ),
                                                            color:
                                                                AppColors.greyColor(
                                                                  context,
                                                                ),
                                                          ),
                                                          children: <
                                                            InlineSpan
                                                          >[
                                                            WidgetSpan(
                                                              child: SizedBox(
                                                                width: 5,
                                                              ),
                                                            ),
                                                            TextSpan(
                                                              text:
                                                                  '${Localization.translate("certificate_expiry_text")}',
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    AppFontFamily
                                                                        .regularFont,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                fontSize:
                                                                    FontSize.scale(
                                                                      context,
                                                                      14,
                                                                    ),
                                                                color:
                                                                    AppColors.greyColor(
                                                                      context,
                                                                    ).withOpacity(
                                                                      0.7,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
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
                                                      certificate: certificate,
                                                      isUpdate: true,
                                                      index: index,
                                                    );
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.whiteColor,
                                                    side: BorderSide(
                                                      color:
                                                          AppColors.greyColor(
                                                            context,
                                                          ),
                                                      width: 0.1,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.0,
                                                          ),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 30,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    "${Localization.translate("edit_text")}",
                                                    style: TextStyle(
                                                      fontSize: FontSize.scale(
                                                        context,
                                                        16,
                                                      ),
                                                      color:
                                                          AppColors.greyColor(
                                                            context,
                                                          ),
                                                      fontFamily:
                                                          AppFontFamily
                                                              .mediumFont,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    _showRemoveDialog(
                                                      context,
                                                      index,
                                                    );
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors
                                                            .redBackgroundColor,
                                                    side: BorderSide(
                                                      color:
                                                          AppColors
                                                              .redBorderColor,
                                                      width: 1,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.0,
                                                          ),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 30,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    "${Localization.translate("delete_text")}",
                                                    style: TextStyle(
                                                      fontSize: FontSize.scale(
                                                        context,
                                                        14,
                                                      ),
                                                      color: AppColors.redColor,
                                                      fontFamily:
                                                          AppFontFamily
                                                              .mediumFont,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                if (_isFirstLoad)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 25.0,
                    ),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Column(
                        children: [
                          SizedBox(height: 5),
                          Container(
                            height: 55,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border(
                                top: BorderSide(
                                  width: 1.0,
                                  color: AppColors.dividerColor,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                  )
                else if (authProvider.certificateList.isNotEmpty)
                  Container(
                    height:
                        Platform.isIOS
                            ? screenHeight * 0.09
                            : screenHeight * 0.1,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor(context),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      left: 20.0,
                      right: 20.0,
                      top: 10.0,
                      bottom:
                          MediaQuery.of(context).padding.bottom > 10.0
                              ? 23.0
                              : 20.0,
                    ),
                    child: ElevatedButton(
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
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 0,
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: 70,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    height: 16,
                                    width: double.infinity,
                                    color: Colors.grey[300],
                                  ),
                                ),
                                SizedBox(height: 8),
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
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    color: Colors.grey[300],
                                  ),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      height: 14,
                                      width: double.infinity,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              children: [
                                Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    color: Colors.grey[300],
                                  ),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      height: 14,
                                      width: double.infinity,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                                ),
                              ],
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
                          SizedBox(width: 8),
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
                      SizedBox(height: 5),
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

class Certificate {
  final int id;
  final String jobTitle;
  final String company;
  final String fromDate;
  final String toDate;
  final String description;
  final String? imagePath;

  Certificate({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.fromDate,
    required this.toDate,
    required this.description,
    this.imagePath,
  });

  Certificate copyWith({
    int? id,
    String? jobTitle,
    String? company,
    String? fromDate,
    String? toDate,
    String? description,
    String? imagePath,
  }) {
    return Certificate(
      id: id ?? this.id,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': jobTitle,
      'institute_name': company,
      'issue_date': fromDate,
      'expiry_date': toDate,
      'description': description,
      'image': imagePath ?? '',
    };
  }

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']) ?? 0,
      jobTitle: json['title'],
      company: json['institute_name'],
      fromDate: json['issue_date'],
      toDate: json['expiry_date'],
      description: json['description'],
      imagePath: json['image'],
    );
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
}
