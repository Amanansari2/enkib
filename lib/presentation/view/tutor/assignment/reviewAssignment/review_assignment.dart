import 'dart:io';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/data/provider/settings_provider.dart';
import 'package:flutter_projects/presentation/view/auth/login_screen.dart';
import 'package:flutter_projects/presentation/view/components/login_required_alert.dart';
import 'package:flutter_projects/presentation/view/tutor/assignment/skeleton/review_assignment_skeleton.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../../../base_components/textfield.dart';
import '../../../../../data/localization/localization.dart';
import '../../../../../data/provider/auth_provider.dart';
import '../../../../../data/provider/connectivity_provider.dart';
import '../../../../../styles/app_styles.dart';
import '../../../components/internet_alert.dart';
import 'package:http/http.dart' as http;
import '../../../../../domain/api_structure/api_service.dart';
import 'package:flutter_projects/presentation/view/community/component/utils/date_utils.dart'
    as CustomDateUtils;

class ReviewAssignment extends StatefulWidget {
  final String assignmentId;
  const ReviewAssignment({super.key, required this.assignmentId});

  @override
  State<ReviewAssignment> createState() => _ReviewAssignmentState();
}

class _ReviewAssignmentState extends State<ReviewAssignment> {
  late String studentName = "";
  int maxCharacters = 800;
  bool isLoading = false;
  late double screenHeight;
  late double screenWidth;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _marksController = TextEditingController();
  final TextEditingController _attachmentMarksController =
      TextEditingController();
  final TextEditingController _marksBothAssignmentTypeController =
      TextEditingController();

  Map<String, dynamic>? assignmentData;

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      var status = await Permission.storage.request();

      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Storage permission denied. Please grant permission.',
            ),
          ),
        );
        return;
      }

      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Storage permission permanently denied. Open app settings to enable it.',
            ),
          ),
        );
        openAppSettings();
        return;
      }

      final directory = await _getDownloadDirectory();
      final filePath = '${directory.path}/$fileName';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded successfully to $filePath')),
        );
      } else {
        throw Exception('Failed to download file');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      return directory!;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      return directory;
    }
  }

  int remainingCharacters = 800;

  @override
  void initState() {
    super.initState();
    remainingCharacters = maxCharacters - _descriptionController.text.length;
    _descriptionController.addListener(() {
      setState(() {
        remainingCharacters =
            maxCharacters - _descriptionController.text.length;
        if (remainingCharacters < 0) {
          remainingCharacters = 0;
        }
      });
    });
    _marksController.addListener(() {
      setState(() {});
    });
    _attachmentMarksController.addListener(() {
      setState(() {});
    });
    _marksBothAssignmentTypeController.addListener(() {
      setState(() {});
    });
    _fetchReviewAssignmentDetails();
  }

  Future<void> _fetchReviewAssignmentDetails() async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await getReviewAssignmentDetail(
        token,
        id: widget.assignmentId,
      );

      if (response != null && response['status'] == 200) {
        setState(() {
          assignmentData = response['data'];
          if (response['data']['submission_text'] != null) {
            _descriptionController.text = response['data']['submission_text'];
          }
        });
      } else if (response['status'] == 401) {
        showCustomToast(context, response['message'], false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: Localization.translate("invalidToken"),
              content: Localization.translate("loginAgain"),
              buttonText: Localization.translate("goToLogin"),
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
        showCustomToast(context, response['message'] ?? "Error", false);
        setState(() {
          isLoading = false;
        });
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
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
            if (isLoading) {
              return false;
            } else {
              return true;
            }
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
                      automaticallyImplyLeading: false,
                      elevation: 0,
                      titleSpacing: 0,
                      centerTitle: false,
                      title: Text(
                        "${(Localization.translate('submit_assignment') ?? '').trim() != 'submit_assignment' && (Localization.translate('submit_assignment') ?? '').trim().isNotEmpty ? Localization.translate('submit_assignment') : 'Submit Assignment'}",
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 20),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      leading: IconButton(
                        splashColor: Colors.transparent,
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.greyColor(context),
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                      ),
                    ),
                  ),
                ),
              ),
              body:
                  isLoading
                      ? ReviewAssignmentSkeleton()
                      : Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProfileSection(),
                                  SizedBox(height: 10),
                                  _buildDescription(),
                                  SizedBox(height: 10),
                                  if (assignmentData != null)
                                    if (assignmentData!['assignment']['type'] ==
                                        'both') ...[
                                      _buildForBothAssignmentType(),
                                    ] else if (assignmentData!['assignment']['type'] ==
                                        'document')
                                      _buildUploadedDocuments()
                                    else if (assignmentData!['assignment']['type'] ==
                                        'text')
                                      _buildAnswer()
                                    else
                                      SizedBox(),
                                  SizedBox(height: 20.0),
                                ],
                              ),
                            ),
                          ),
                          _buildBottomButton(),
                        ],
                      ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection() {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    studentName =
        settingsProvider.getSetting(
          'data',
        )?['_lernen']?['student_display_name'] ??
        '';
    if (assignmentData == null) return SizedBox();

    final student = assignmentData!['student'];
    final assignment = assignmentData!['assignment'];
    final submittedAt = assignmentData!['submitted_at'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.whiteColor),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child:
                      student['image'] != null
                          ? Image.network(
                            student['image'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                AppImages.placeHolderImage,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                          : Image.asset(
                            AppImages.placeHolderImage,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        student['full_name'] ?? '',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        studentName,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w400,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              assignment['title'] ?? '',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 16),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              assignment['related_type'] ?? '',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: AppColors.greyColor(context),
                fontSize: FontSize.scale(context, 12),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                SvgPicture.asset(
                  AppImages.calendarIcon,
                  width: 15,
                  height: 15,
                  color: AppColors.greyColor(context),
                ),
                SizedBox(width: 6),
                Text.rich(
                  TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            submittedAt != null
                                ? CustomDateUtils.formatDate(submittedAt)
                                : '',
                        style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFontFamily.mediumFont,
                        ),
                      ),
                      TextSpan(text: ' '),
                      TextSpan(
                        text:
                            "${(Localization.translate('submitted_at') ?? '').trim() != 'submitted_at' && (Localization.translate('submitted_at') ?? '').trim().isNotEmpty ? Localization.translate('submitted_at') : 'Submitted at'}",
                        style: TextStyle(
                          color: AppColors.greyColor(context).withOpacity(0.7),
                          fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFontFamily.regularFont,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      AppImages.marksIcon,
                      width: 15,
                      height: 15,
                      color: AppColors.greyColor(context),
                    ),
                    SizedBox(width: 6),
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: assignment['total_marks']?.toString() ?? '0',
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFontFamily.mediumFont,
                            ),
                          ),
                          TextSpan(text: ' '),
                          TextSpan(
                            text:
                                "${(Localization.translate('total_marks') ?? '').trim() != 'total_marks' && (Localization.translate('total_marks') ?? '').trim().isNotEmpty ? Localization.translate('total_marks') : 'Total Marks'}",
                            style: TextStyle(
                              color: AppColors.greyColor(
                                context,
                              ).withOpacity(0.7),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w400,
                              fontFamily: AppFontFamily.regularFont,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SvgPicture.asset(
                      AppImages.identityVerification,
                      width: 15,
                      height: 15,
                      color: AppColors.greyColor(context),
                    ),
                    SizedBox(width: 8),
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: '${assignment['passing_percentage']}%',
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFontFamily.mediumFont,
                            ),
                          ),
                          TextSpan(text: ' '),
                          TextSpan(
                            text:
                                "${(Localization.translate('passing_grade') ?? '').trim() != 'passing_grade' && (Localization.translate('passing_grade') ?? '').trim().isNotEmpty ? Localization.translate('passing_grade') : 'Passing Grade'}",
                            style: TextStyle(
                              color: AppColors.greyColor(
                                context,
                              ).withOpacity(0.7),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w400,
                              fontFamily: AppFontFamily.regularFont,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    if (assignmentData == null) {
      return ReviewAssignmentSkeleton();
    }

    if (assignmentData!['assignment']['description'] == null) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              '${(Localization.translate('empty_description') ?? '').trim() != 'empty_description' && (Localization.translate('empty_description') ?? '').trim().isNotEmpty ? Localization.translate('empty_description') : 'Description Empty'}',
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 14),
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
                fontFamily: AppFontFamily.mediumFont,
              ),
            ),
          ),
        ),
      );
    }

    final description = assignmentData!['assignment']['description'] ?? '';
    final words = description.split(RegExp(r'\s+'));
    final isExpanded = ValueNotifier<bool>(false);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.whiteColor),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${(Localization.translate('description') ?? '').trim() != 'description' && (Localization.translate('description') ?? '').trim().isNotEmpty ? Localization.translate('description') : 'Description'}",
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: AppColors.blackColor.withOpacity(0.7),
              fontSize: FontSize.scale(context, 16),
              fontFamily: AppFontFamily.mediumFont,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
          ValueListenableBuilder<bool>(
            valueListenable: isExpanded,
            builder: (context, expanded, child) {
              String aboutDescription;
              bool showSeeMore = words.length > 25;

              if (expanded || !showSeeMore) {
                aboutDescription = description;
              } else {
                aboutDescription =
                    description.split(' ').take(25).join(' ') + '... ';
              }

              return RichText(
                text: TextSpan(
                  children: [
                    WidgetSpan(
                      child: HtmlWidget(
                        aboutDescription,
                        textStyle: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFontFamily.regularFont,
                        ),
                      ),
                    ),
                    if (showSeeMore)
                      TextSpan(
                        text:
                            expanded
                                ? '  ${Localization.translate("show_less")}'
                                : ' ${Localization.translate("read_more")}',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 15),
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFontFamily.mediumFont,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                isExpanded.value = !expanded;
                              },
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnswer() {
    if (assignmentData == null) {
      return ReviewAssignmentSkeleton();
    }

    if (assignmentData!['submission_text'] == null) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              '${(Localization.translate('empty_answer') ?? '').trim() != 'empty_answer' && (Localization.translate('empty_answer') ?? '').trim().isNotEmpty ? Localization.translate('empty_answer') : 'No answer submitted'}',
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 14),
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
                fontFamily: AppFontFamily.mediumFont,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.whiteColor),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${(Localization.translate('answer') ?? '').trim() != 'answer' && (Localization.translate('answer') ?? '').trim().isNotEmpty ? Localization.translate('answer') : 'Answer'}",
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: AppColors.blackColor.withOpacity(0.7),
                  fontSize: FontSize.scale(context, 16),
                  fontFamily: AppFontFamily.mediumFont,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.0, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.fadeColor,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                      width: 40,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.dividerColor,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.greyColor(
                              context,
                            ).withOpacity(0.05),
                            offset: Offset(0, 2),
                            spreadRadius: 1,
                            blurRadius: 2,
                          ),
                        ],
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: TextField(
                        cursorHeight: 15,
                        cursorColor: AppColors.greyColor(context),
                        controller: _marksController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        readOnly: assignmentData!['marks_awarded'] != null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(
                            bottom: Platform.isIOS ? 10 : 12,
                          ),
                          hintText:
                              '${assignmentData!['marks_awarded'] ?? '0'}',
                          hintStyle: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 14),
                            fontFamily: AppFontFamily.regularFont,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && int.tryParse(value) != null) {
                            int enteredValue = int.parse(value);
                            if (enteredValue > 100) {
                              _marksController.text = '100';
                              _marksController
                                  .selection = TextSelection.collapsed(
                                offset: _marksController.text.length,
                              );
                            }
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "${(Localization.translate('total_number') ?? '').trim() != 'total_number' && (Localization.translate('total_number') ?? '').trim().isNotEmpty ? Localization.translate('total_number') : '/100'}",
                        style: TextStyle(
                          color: AppColors.blackColor.withOpacity(0.9),
                          fontSize: FontSize.scale(context, 12),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          CustomTextField(
            hint:
                "${(Localization.translate('answer') ?? '').trim() != 'answer' && (Localization.translate('answer') ?? '').trim().isNotEmpty ? Localization.translate('answer') : 'Answer'}",
            multiLine: true,
            mandatory: false,
            controller: _descriptionController,
            readOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedDocuments() {
    if (assignmentData == null) {
      return ReviewAssignmentSkeleton();
    }

    if (assignmentData!['attachments'].isEmpty) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              '${Localization.translate("empty_attachments")}',
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 14),
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
                fontFamily: AppFontFamily.mediumFont,
              ),
            ),
          ),
        ),
      );
    }

    final attachments = assignmentData!['attachments'] as List<dynamic>;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.whiteColor),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${(Localization.translate('attachments') ?? '').trim() != 'attachments' && (Localization.translate('attachments') ?? '').trim().isNotEmpty ? Localization.translate('attachments') : 'Attachments'}",
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: AppColors.blackColor.withOpacity(0.7),
                  fontSize: FontSize.scale(context, 16),
                  fontFamily: AppFontFamily.mediumFont,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.0, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.fadeColor,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                      width: 40,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.dividerColor,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.greyColor(
                              context,
                            ).withOpacity(0.05),
                            offset: Offset(0, 2),
                            spreadRadius: 1,
                            blurRadius: 2,
                          ),
                        ],
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: TextField(
                        cursorHeight: 15,
                        cursorColor: AppColors.greyColor(context),
                        controller: _attachmentMarksController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        readOnly: assignmentData!['marks_awarded'] != null,

                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(
                            bottom: Platform.isIOS ? 10 : 12,
                          ),
                          hintText:
                              '${assignmentData!['marks_awarded']?.toString() ?? '0'}',
                          hintStyle: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 14),
                            fontFamily: AppFontFamily.regularFont,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && int.tryParse(value) != null) {
                            int enteredValue = int.parse(value);
                            if (enteredValue > 100) {
                              _attachmentMarksController.text = '100';
                              _attachmentMarksController
                                  .selection = TextSelection.collapsed(
                                offset: _attachmentMarksController.text.length,
                              );
                            }
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "${(Localization.translate('total_number') ?? '').trim() != 'total_number' && (Localization.translate('total_number') ?? '').trim().isNotEmpty ? Localization.translate('total_number') : '/100'}",
                        style: TextStyle(
                          color: AppColors.blackColor.withOpacity(0.9),
                          fontSize: FontSize.scale(context, 12),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Column(
            children:
                attachments.map((attachment) {
                  return _buildShowAttachedFileItem({
                    'name': attachment['name'],
                    'size': attachment['size'],
                    'url': attachment['url'],
                    'type': attachment['type'],
                  }, attachments.indexOf(attachment));
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildForBothAssignmentType() {
    if (assignmentData == null) {
      return ReviewAssignmentSkeleton();
    }

    if (assignmentData!['submission_text'] == null) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              '${(Localization.translate('empty_answer') ?? '').trim() != 'empty_answer' && (Localization.translate('empty_answer') ?? '').trim().isNotEmpty ? Localization.translate('empty_answer') : 'No answer submitted'}',
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 14),
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
                fontFamily: AppFontFamily.mediumFont,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.whiteColor),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${(Localization.translate('answer') ?? '').trim() != 'answer' && (Localization.translate('answer') ?? '').trim().isNotEmpty ? Localization.translate('answer') : 'Answer'}",
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: AppColors.blackColor.withOpacity(0.7),
                  fontSize: FontSize.scale(context, 16),
                  fontFamily: AppFontFamily.mediumFont,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.0, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.fadeColor,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                      width: 40,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.dividerColor,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.greyColor(
                              context,
                            ).withOpacity(0.05),
                            offset: Offset(0, 2),
                            spreadRadius: 1,
                            blurRadius: 2,
                          ),
                        ],
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: TextField(
                        cursorHeight: 15,
                        cursorColor: AppColors.greyColor(context),
                        controller: _marksBothAssignmentTypeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        readOnly: assignmentData!['marks_awarded'] != null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(
                            bottom: Platform.isIOS ? 10 : 12,
                          ),
                          hintText:
                              '${assignmentData!['marks_awarded'] ?? '0'}',
                          hintStyle: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 14),
                            fontFamily: AppFontFamily.regularFont,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && int.tryParse(value) != null) {
                            int enteredValue = int.parse(value);
                            if (enteredValue > 100) {
                              _marksBothAssignmentTypeController.text = '100';
                              _marksBothAssignmentTypeController
                                  .selection = TextSelection.collapsed(
                                offset:
                                    _marksBothAssignmentTypeController
                                        .text
                                        .length,
                              );
                            }
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "${(Localization.translate('total_number') ?? '').trim() != 'total_number' && (Localization.translate('total_number') ?? '').trim().isNotEmpty ? Localization.translate('total_number') : '/100'}",
                        style: TextStyle(
                          color: AppColors.blackColor.withOpacity(0.9),
                          fontSize: FontSize.scale(context, 12),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          CustomTextField(
            hint:
                "${(Localization.translate('answer') ?? '').trim() != 'answer' && (Localization.translate('answer') ?? '').trim().isNotEmpty ? Localization.translate('answer') : 'Answer'}",
            multiLine: true,
            mandatory: false,
            controller: _descriptionController,
            readOnly: true,
          ),
          SizedBox(height: 10),
          _buildBothAssignmentTypeUploadedDocuments(),
        ],
      ),
    );
  }

  Widget _buildBothAssignmentTypeUploadedDocuments() {
    if (assignmentData == null) {
      return ReviewAssignmentSkeleton();
    }

    if (assignmentData!['attachments'].isEmpty) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              '${Localization.translate("empty_attachments")}',
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 14),
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
                fontFamily: AppFontFamily.mediumFont,
              ),
            ),
          ),
        ),
      );
    }

    final attachments = assignmentData!['attachments'] as List<dynamic>;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.whiteColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${(Localization.translate('attachments') ?? '').trim() != 'attachments' && (Localization.translate('attachments') ?? '').trim().isNotEmpty ? Localization.translate('attachments') : 'Attachments'}",
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: AppColors.blackColor.withOpacity(0.7),
              fontSize: FontSize.scale(context, 16),
              fontFamily: AppFontFamily.mediumFont,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
          Column(
            children:
                attachments.map((attachment) {
                  return _buildShowAttachedFileItem({
                    'name': attachment['name'],
                    'size': attachment['size'],
                    'url': attachment['url'],
                    'type': attachment['type'],
                  }, attachments.indexOf(attachment));
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    bool isButtonEnabled = false;
    if (assignmentData != null && assignmentData!['result'] == 'in_review') {
      String assignmentType = assignmentData!['assignment']['type'];

      if (assignmentType == 'text') {
        isButtonEnabled = _marksController.text.isNotEmpty;
      } else if (assignmentType == 'document') {
        isButtonEnabled = _attachmentMarksController.text.isNotEmpty;
      } else if (assignmentType == 'both') {
        isButtonEnabled = _marksBothAssignmentTypeController.text.isNotEmpty;
      }
    }

    return Container(
      height: screenHeight * 0.09,
      width: screenWidth,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 8,
            blurRadius: 10,
          ),
        ],
        color: AppColors.whiteColor,
        border: Border(
          top: BorderSide(color: AppColors.dividerColor, width: 1),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 10.0,
        bottom: Platform.isIOS ? 20.0 : 10.0,
      ),
      child: ElevatedButton(
        onPressed:
            isButtonEnabled
                ? () async {
                  if (token == null) return;

                  setState(() {
                    isLoading = true;
                  });

                  try {
                    int? marksAwarded;
                    String assignmentType =
                        assignmentData!['assignment']['type'];

                    if (assignmentType == 'both') {
                      marksAwarded = int.tryParse(
                        _marksBothAssignmentTypeController.text,
                      );
                    } else if (assignmentType == 'document') {
                      marksAwarded = int.tryParse(
                        _attachmentMarksController.text,
                      );
                    } else if (assignmentType == 'text') {
                      marksAwarded = int.tryParse(_marksController.text);
                    }

                    if (marksAwarded == null) {
                      showCustomToast(
                        context,
                        "${(Localization.translate('enter_valid_marks') ?? '').trim() != 'enter_valid_marks' && (Localization.translate('enter_valid_marks') ?? '').trim().isNotEmpty ? Localization.translate('enter_valid_marks') : 'Enter valid marks'}",
                        false,
                      );
                      setState(() {
                        isLoading = false;
                      });
                      return;
                    }

                    final response = await submitAssignmentResult(
                      token,
                      id: widget.assignmentId,
                      marks_awarded: marksAwarded,
                    );
                    if (response['status'] == 200) {
                      await _fetchReviewAssignmentDetails();
                      showCustomToast(
                        context,
                        response['message'] ??
                            "${(Localization.translate('result_submitted_successfully') ?? '').trim() != 'result_submitted_successfully' && (Localization.translate('result_submitted_successfully') ?? '').trim().isNotEmpty ? Localization.translate('result_submitted_successfully') : 'Result submitted successfully'}",
                        true,
                      );
                    } else if (response['status'] == 401) {
                      showCustomToast(context, response['message'], false);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return CustomAlertDialog(
                            title: Localization.translate("invalidToken"),
                            content: Localization.translate("loginAgain"),
                            buttonText: Localization.translate("goToLogin"),
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
                    } else if (response['status'] == 403) {
                      showCustomToast(context, response['message'], false);
                    } else {
                      showCustomToast(
                        context,
                        response['message'] ??
                            '${(Localization.translate('failed_to_submit_assignment_result') ?? '').trim() != 'failed_to_submit_assignment_result' && (Localization.translate('failed_to_submit_assignment_result') ?? '').trim().isNotEmpty ? Localization.translate('failed_to_submit_assignment_result') : 'Failed to submit assignment result'}',
                        false,
                      );
                    }
                  } catch (e) {
                    showCustomToast(
                      context,
                      '${(Localization.translate('failed_to_submit_assignment_result') ?? '').trim() != 'failed_to_submit_assignment_result' && (Localization.translate('failed_to_submit_assignment_result') ?? '').trim().isNotEmpty ? Localization.translate('failed_to_submit_assignment_result') : 'Failed to submit assignment result'}',
                      false,
                    );
                  } finally {
                    setState(() {
                      isLoading = false;
                    });
                  }
                }
                : null,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.disabled)) {
              return AppColors.fadeColor;
            }
            return AppColors.primaryGreen(context);
          }),
          padding: MaterialStateProperty.all(
            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        child:
            isLoading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.whiteColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "${(Localization.translate('submits_result') ?? '').trim() != 'submits_result' && (Localization.translate('submits_result') ?? '').trim().isNotEmpty ? Localization.translate('submits_result') : 'Submits Result'}",
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: FontSize.scale(context, 16),
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
                : Text(
                  "${(Localization.translate('submits_result') ?? '').trim() != 'submits_result' && (Localization.translate('submits_result') ?? '').trim().isNotEmpty ? Localization.translate('submits_result') : 'Submits Result'}",
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: FontSize.scale(context, 16),
                    fontFamily: AppFontFamily.mediumFont,
                    fontWeight: FontWeight.w500,
                  ),
                ),
      ),
    );
  }

  Widget _buildShowAttachedFileItem(Map<String, String> file, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dividerColor, width: 1),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            file['type'] == 'image'
                ? AppImages.imageIcon
                : AppImages.documentFileIcon,
            width: 20,
            height: 20,
            fit: BoxFit.cover,
            color: AppColors.greyColor(context),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file['name']!,
                  style: TextStyle(
                    color: AppColors.blackColor.withOpacity(0.7),
                    fontSize: FontSize.scale(context, 14),
                    fontFamily: AppFontFamily.mediumFont,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  file['size']!,
                  style: TextStyle(
                    color: AppColors.greyColor(context),
                    fontSize: FontSize.scale(context, 12),
                    fontFamily: AppFontFamily.regularFont,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: SvgPicture.asset(
              AppImages.downloadIcon,
              width: 20,
              height: 20,
              color: AppColors.greyColor(context),
            ),
            onPressed: () {
              _downloadFile(file['url']!, file['name']!);
            },
          ),
        ],
      ),
    );
  }
}
