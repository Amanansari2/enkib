import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/domain/api_structure/api_service.dart';
import 'package:flutter_projects/presentation/view/auth/login_screen.dart';
import 'package:flutter_projects/presentation/view/components/login_required_alert.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../base_components/textfield.dart';
import '../../../../data/localization/localization.dart';
import '../../../../data/provider/auth_provider.dart';
import '../../../../data/provider/connectivity_provider.dart';
import '../../../../styles/app_styles.dart';
import '../../components/internet_alert.dart';
import 'skeleton/submit_assignment_skeleton.dart';
import 'package:flutter_projects/presentation/view/community/component/utils/date_utils.dart';

class SubmitAssignment extends StatefulWidget {
  final String assignmentId;
  const SubmitAssignment({super.key, required this.assignmentId});

  @override
  State<SubmitAssignment> createState() => _SubmitAssignmentState();
}

class _SubmitAssignmentState extends State<SubmitAssignment> {
  int maxCharacters = 800;
  bool isLoading = false;
  late double screenHeight;
  late double screenWidth;
  bool isAssignmentSubmitted = false;
  bool isAssignmentPassed = false;
  bool isAssignmentFailed = false;
  bool isSubmitting = false;
  bool hasError = false;
  bool _hasFileUploadError = false;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  Map<String, dynamic> assignmentDetails = {};

  List<PlatformFile> uploadedFiles = [];

  Future<void> _pickFile() async {
    final maxFileCount = assignmentDetails['max_file_count'] ?? 1;
    if (uploadedFiles.length >= maxFileCount) {
      showCustomToast(
        context,
        '${(Localization.translate('max_files') ?? '').trim() != 'max_files' && (Localization.translate('max_files') ?? '').trim().isNotEmpty ? Localization.translate('max_files') : 'You can only upload a maximum $maxFileCount file${maxFileCount > 1 ? 's' : ''}'}',
        false,
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      if (uploadedFiles.length + result.files.length > maxFileCount) {
        showCustomToast(
          context,
          '${(Localization.translate('max_files') ?? '').trim() != 'max_files' && (Localization.translate('max_files') ?? '').trim().isNotEmpty ? Localization.translate('max_files') : 'You can only upload a maximum $maxFileCount file${maxFileCount > 1 ? 's' : ''}'}',
          false,
        );
        return;
      }

      setState(() {
        uploadedFiles.addAll(result.files);
      });
    }
  }

  int remainingCharacters = 800;

  @override
  void initState() {
    super.initState();
    _fetchAssignmentDetails();
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
  }

  Future<void> _fetchAssignmentDetails() async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getAssignmentDetail(token, widget.assignmentId);

      if (response['status'] == 200) {
        setState(() {
          isLoading = false;
          assignmentDetails = response['data'] ?? {};
          if (assignmentDetails['result'] == 'pass') {
            isAssignmentPassed = true;
            isAssignmentFailed = false;
            isAssignmentSubmitted = false;
          } else if (assignmentDetails['result'] == 'fail') {
            isAssignmentPassed = false;
            isAssignmentFailed = true;
            isAssignmentSubmitted = false;
          } else if (assignmentDetails['result'] == 'in_review') {
            isAssignmentPassed = false;
            isAssignmentFailed = false;
            isAssignmentSubmitted = true;
          } else {
            isAssignmentPassed = false;
            isAssignmentFailed = false;
            isAssignmentSubmitted = false;
          }
          if (assignmentDetails['submission_text'] != null) {
            _reviewController.text = assignmentDetails['submission_text'];
          } else {
            _reviewController.clear();
          }
        });
      } else if (response['status'] == 401) {
        setState(() {
          isLoading = false;
        });
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
        setState(() {
          isLoading = false;
        });
        showCustomToast(context, response['message'], false);
      }
    } catch (e) {
    } finally {
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
          child:
              isLoading
                  ? const SubmitAssignmentSkeleton()
                  : Directionality(
                    textDirection: Localization.textDirection,
                    child: Scaffold(
                      backgroundColor: AppColors.backgroundColor(context),
                      appBar: PreferredSize(
                        preferredSize: Size.fromHeight(70.0),
                        child: Container(
                          color: AppColors.whiteColor,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 20.0,
                              left: 20.0,
                            ),
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
                            ),
                          ),
                        ),
                      ),
                      body: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProfileSection(),
                                  SizedBox(height: 10),
                                  if (isAssignmentSubmitted) ...[
                                    _buildAssignmentSubmitted(),
                                    SizedBox(height: 20),
                                  ] else if (isAssignmentPassed) ...[
                                    _buildIsAssignmentPassed(),
                                    SizedBox(height: 20),
                                  ] else if (isAssignmentFailed) ...[
                                    _buildIsAssignmentFailed(),
                                    SizedBox(height: 20),
                                  ] else ...[
                                    _buildDescription(),
                                    SizedBox(height: 10),
                                    if (assignmentDetails['type'] ==
                                        'both') ...[
                                      _buildAnswer(),
                                      SizedBox(height: 10),
                                      _buildUploadedDocuments(),
                                    ] else if (assignmentDetails['type'] ==
                                        'document')
                                      _buildUploadedDocuments()
                                    else if (assignmentDetails['type'] ==
                                        'text')
                                      _buildAnswer()
                                    else
                                      SizedBox(),
                                    SizedBox(height: 20.0),
                                  ],
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
    String profileImageUrl = assignmentDetails['instructor']?['image'] ?? '';

    Widget displayProfileImage() {
      Widget _buildShimmerSkeleton() {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      Widget buildImage(String url) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = true;

            return Stack(
              alignment: Alignment.center,
              children: [
                if (isLoading) _buildShimmerSkeleton(),
                Image.network(
                  url,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      Future.microtask(() => setState(() => isLoading = false));
                      return child;
                    }
                    return const SizedBox();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return SvgPicture.asset(
                      AppImages.placeHolder,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      color: AppColors.greyColor(context),
                    );
                  },
                ),
              ],
            );
          },
        );
      }

      if (profileImageUrl.isNotEmpty) {
        return buildImage(profileImageUrl);
      } else {
        return SvgPicture.asset(
          AppImages.placeHolder,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          color: AppColors.greyColor(context),
        );
      }
    }

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
                  child: displayProfileImage(),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        assignmentDetails['instructor']?['name'] ?? '',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      Text(
                        '${(Localization.translate('author') ?? '').trim() != 'author' && (Localization.translate('author') ?? '').trim().isNotEmpty ? Localization.translate('author') : 'Author'}',
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
              assignmentDetails['title'] ?? '',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 18),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              assignmentDetails['related_type'] == 'Course'
                  ? 'Course'
                  : 'Subject',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: AppColors.greyColor(context),
                fontSize: FontSize.scale(context, 14),
                fontFamily: AppFontFamily.regularFont,
                fontWeight: FontWeight.w400,
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
                        text: formatDeadline(assignmentDetails['ended_at']),
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
                            "${(Localization.translate('deadline') ?? '').trim() != 'deadline' && (Localization.translate('deadline') ?? '').trim().isNotEmpty ? Localization.translate('deadline') : 'Deadline'}",
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
                            text:
                                assignmentDetails['total_marks']?.toString() ??
                                '',
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
                            text:
                                assignmentDetails['passing_percentage']
                                    ?.toString() ??
                                '',
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
    final description = assignmentDetails['description'] ?? '';
    final words = description.split(RegExp(r'\s+'));
    final isExpanded = ValueNotifier<bool>(false);
    if (description.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              "${(Localization.translate('empty_description') ?? '').trim() != 'empty_description' && (Localization.translate('empty_description') ?? '').trim().isNotEmpty ? Localization.translate('empty_description') : 'Description Empty'}",
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 16),
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
              bool showSeeMore = words.length > 12;

              if (expanded || !showSeeMore) {
                aboutDescription = description;
              } else {
                aboutDescription =
                    description.split(' ').take(12).join(' ') + '... ';
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
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          "${(Localization.translate('max_characters') ?? '').trim() != 'max_characters' && (Localization.translate('max_characters') ?? '').trim().isNotEmpty ? Localization.translate('max_characters') : 'Max. Characters:'}",
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 12),
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                        fontFamily: AppFontFamily.regularFont,
                      ),
                    ),
                    TextSpan(text: " "),
                    TextSpan(
                      text: '$remainingCharacters/$maxCharacters',
                      style: TextStyle(
                        color: AppColors.blackColor.withOpacity(0.7),
                        fontSize: FontSize.scale(context, 12),
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                        fontFamily: AppFontFamily.mediumFont,
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
                "${(Localization.translate('add_answer') ?? '').trim() != 'add_answer' && (Localization.translate('add_answer') ?? '').trim().isNotEmpty ? Localization.translate('add_answer') : 'Enter your answer'}",
            multiLine: true,
            mandatory: false,
            controller: _descriptionController,
            hasError: hasError,
            errorText:
                hasError
                    ? "${(Localization.translate('field_required') ?? '').trim() != 'field_required' && (Localization.translate('field_required') ?? '').trim().isNotEmpty ? Localization.translate('field_required') : 'This field is required'}"
                    : null,
            onChanged: (text) {
              if (text.length > maxCharacters) {
                _descriptionController.text = text.substring(0, maxCharacters);
                _descriptionController.selection = TextSelection.collapsed(
                  offset: maxCharacters,
                );
              }
              if (text.isNotEmpty) {
                setState(() {
                  hasError = false;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedDocuments() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
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
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          "${(Localization.translate('max_attachments') ?? '').trim() != 'max_attachments' && (Localization.translate('max_attachments') ?? '').trim().isNotEmpty ? Localization.translate('max_attachments') : 'Max. attachments:'}",
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 12),
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                        fontFamily: AppFontFamily.regularFont,
                      ),
                    ),
                    TextSpan(text: " "),
                    TextSpan(
                      text: '${assignmentDetails['max_file_count'] ?? 0}',
                      style: TextStyle(
                        color: AppColors.blackColor.withOpacity(0.7),
                        fontSize: FontSize.scale(context, 12),
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                        fontFamily: AppFontFamily.mediumFont,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Column(
            children: List.generate(uploadedFiles.length, (index) {
              return _buildFileItem(uploadedFiles[index], index);
            }),
          ),
          if (uploadedFiles.length < (assignmentDetails['max_file_count'] ?? 0))
            DottedBorder(
              color:
                  _hasFileUploadError && uploadedFiles.isEmpty
                      ? AppColors.redColor
                      : AppColors.dividerColor,
              strokeWidth: 2.0,
              dashPattern: [12, 15],
              borderType: BorderType.RRect,
              radius: Radius.circular(12),
              child: GestureDetector(
                onTap: () {
                  _pickFile();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: AppColors.fadeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _pickFile();
                        },
                        child: Image.asset(
                          AppImages.uploadDocument,
                          fit: BoxFit.cover,
                          width: 55,
                          height: 55,
                        ),
                      ),
                      SizedBox(width: 15),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        "${(Localization.translate('drop_file_here') ?? '').trim() != 'drop_file_here' && (Localization.translate('drop_file_here') ?? '').trim().isNotEmpty ? Localization.translate('drop_file_here') : 'Drop file here or'}",
                                    style: TextStyle(
                                      color: AppColors.greyColor(context),
                                      fontSize: FontSize.scale(context, 14),
                                      fontFamily: AppFontFamily.regularFont,
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                    ),
                                  ),
                                  TextSpan(text: " "),
                                  TextSpan(
                                    text:
                                        "${(Localization.translate('click_here') ?? '').trim() != 'click_here' && (Localization.translate('click_here') ?? '').trim().isNotEmpty ? Localization.translate('click_here') : 'click here'}",
                                    style: TextStyle(
                                      color: AppColors.greyColor(context),
                                      fontSize: FontSize.scale(context, 14),
                                      fontFamily: AppFontFamily.regularFont,
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.greyColor(
                                        context,
                                      ),
                                      decorationThickness: 0.6,
                                    ),
                                    recognizer:
                                        TapGestureRecognizer()
                                          ..onTap = () {
                                            _pickFile();
                                          },
                                  ),
                                  TextSpan(text: " "),
                                  TextSpan(
                                    text:
                                        "${(Localization.translate('to_upload') ?? '').trim() != 'to_upload' && (Localization.translate('to_upload') ?? '').trim().isNotEmpty ? Localization.translate('to_upload') : 'to upload'}",
                                    style: TextStyle(
                                      color: AppColors.greyColor(context),
                                      fontSize: FontSize.scale(context, 14),
                                      fontFamily: AppFontFamily.regularFont,
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "${(Localization.translate('image_format_size') ?? '').trim() != 'image_format_size' && (Localization.translate('image_format_size') ?? '').trim().isNotEmpty ? Localization.translate('image_format_size') : 'PNG, JPG (max. 800x400px)'}",
                              style: TextStyle(
                                color: AppColors.greyColor(
                                  context,
                                ).withOpacity(0.7),
                                fontSize: FontSize.scale(context, 12),
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
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileItem(PlatformFile file, int index) {
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
            AppImages.identityVerification,
            width: 20,
            height: 20,
            fit: BoxFit.cover,
            color: AppColors.primaryGreen(context),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
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
                  '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
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
              AppImages.removeIcon,
              width: 20,
              height: 20,
              color: AppColors.greyColor(context),
            ),
            onPressed: () {
              setState(() {
                uploadedFiles.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final bool isButtonEnabled =
        assignmentDetails['result'] == 'assigned' ||
        isAssignmentSubmitted ||
        isAssignmentPassed ||
        isAssignmentFailed;

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
            isButtonEnabled && !isSubmitting
                ? () async {
                  if (isAssignmentSubmitted ||
                      isAssignmentPassed ||
                      isAssignmentFailed) {
                    Navigator.pop(context);
                    return;
                  }

                  if (assignmentDetails['type'] == 'text' &&
                      _descriptionController.text.trim().isEmpty) {
                    setState(() {
                      hasError = true;
                    });
                    return;
                  } else if (assignmentDetails['type'] == 'document' &&
                      uploadedFiles.isEmpty) {
                    setState(() {
                      _hasFileUploadError = true;
                    });
                    showCustomToast(
                      context,
                      "${(Localization.translate('upload_assignment') ?? '').trim() != 'upload_assignment' && (Localization.translate('upload_assignment') ?? '').trim().isNotEmpty ? Localization.translate('upload_assignment') : 'Please upload your assignment'}",
                      false,
                    );
                    return;
                  } else if (assignmentDetails['type'] == 'both') {
                    if (_descriptionController.text.trim().isEmpty) {
                      setState(() {
                        hasError = true;
                        _hasFileUploadError = true;
                        showCustomToast(
                          context,
                          "${(Localization.translate('upload_assignment') ?? '').trim() != 'upload_assignment' && (Localization.translate('upload_assignment') ?? '').trim().isNotEmpty ? Localization.translate('upload_assignment') : 'Upload your assignment'}",
                          false,
                        );
                      });
                      return;
                    } else if (uploadedFiles.isEmpty) {
                      setState(() {
                        _hasFileUploadError = true;
                      });
                      showCustomToast(
                        context,
                        "${(Localization.translate('upload_assignment') ?? '').trim() != 'upload_assignment' && (Localization.translate('upload_assignment') ?? '').trim().isNotEmpty ? Localization.translate('upload_assignment') : 'Upload your assignment'}",
                        false,
                      );
                      return;
                    }
                  }

                  setState(() {
                    isSubmitting = true;
                  });

                  try {
                    final assignmentType = assignmentDetails['type'];
                    String? submissionText;
                    List<File>? attachments;

                    if (assignmentType == 'text') {
                      submissionText = _descriptionController.text.trim();
                    } else if (assignmentType == 'document') {
                      attachments =
                          uploadedFiles.map((pf) => File(pf.path!)).toList();
                    } else if (assignmentType == 'both') {
                      submissionText = _descriptionController.text.trim();
                      attachments =
                          uploadedFiles.map((pf) => File(pf.path!)).toList();
                    }

                    final response = await submitAssignment(
                      token: token!,
                      assignmentId: widget.assignmentId,
                      submissionText: submissionText,
                      attachments: attachments,
                    );
                    if (response['status'] == 200) {
                      await _fetchAssignmentDetails();
                      showCustomToast(
                        context,
                        response['data']['message'],
                        true,
                      );
                      Navigator.pop(context);
                    } else if (response['status'] == 422) {
                      String errorMsg = 'Validation error';
                      if (response['errors'] != null) {
                        if (response['errors']['errors'] != null) {
                          if (response['errors']['errors']['submission_text'] !=
                              null) {
                            errorMsg =
                                response['errors']['errors']['submission_text']
                                    .toString();
                          } else if (response['errors']['errors']['attachments'] !=
                              null) {
                            errorMsg =
                                response['errors']['errors']['attachments']
                                    .toString();
                          }
                        } else if (response['errors']['submission_text'] !=
                            null) {
                          errorMsg =
                              response['errors']['submission_text'].toString();
                        } else if (response['errors']['attachments'] != null) {
                          errorMsg =
                              response['errors']['attachments'].toString();
                        }
                      }

                      if (errorMsg == 'Validation error' &&
                          response['message'] != null) {
                        errorMsg = response['message'].toString();
                      }

                      showCustomToast(context, errorMsg, false);
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
                    } else if (response['status'] == 403) {
                      showCustomToast(context, response['message'], false);
                    } else if (response['status'] == 500) {
                      showCustomToast(context, response['message'], false);
                    } else {
                      showCustomToast(
                        context,
                        response['data']['message'] ??
                            '${Localization.translate("error_message")}',
                        false,
                      );
                    }
                  } catch (e) {
                  } finally {
                    setState(() {
                      isSubmitting = false;
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAssignmentSubmitted || isAssignmentPassed || isAssignmentFailed
                  ? "${(Localization.translate('go_to_dashboard') ?? '').trim() != 'go_to_dashboard' && (Localization.translate('go_to_dashboard') ?? '').trim().isNotEmpty ? Localization.translate('go_to_dashboard') : 'Go to Dashboard'}"
                  : '${(Localization.translate('submit_assignment') ?? '').trim() != 'submit_assignment' && (Localization.translate('submit_assignment') ?? '').trim().isNotEmpty ? Localization.translate('submit_assignment') : 'Submit Assignment'}',
              style: TextStyle(
                color: AppColors.whiteColor,
                fontSize: FontSize.scale(context, 16),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isSubmitting) ...[
              SizedBox(width: 12),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppColors.whiteColor,
                  strokeWidth: 2.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentSubmitted() {
    return Container(
      width: double.infinity,
      height: 500,
      decoration: BoxDecoration(color: AppColors.whiteColor),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppImages.submitAssignment,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 30),
          Text(
            '${(Localization.translate('assignment_submitted_successfully') ?? '').trim() != 'assignment_submitted_successfully' && (Localization.translate('assignment_submitted_successfully') ?? '').trim().isNotEmpty ? Localization.translate('assignment_submitted_successfully') : 'Assignment Submitted successfully!'}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.blackColor.withOpacity(0.7),
              fontSize: FontSize.scale(context, 16),
              fontFamily: AppFontFamily.mediumFont,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 5),
          Text(
            '${(Localization.translate('assignment_submitted_subtitle') ?? '').trim() != 'assignment_submitted_subtitle' && (Localization.translate('assignment_submitted_subtitle') ?? '').trim().isNotEmpty ? Localization.translate('assignment_submitted_subtitle') : 'The tutor will review your answers and notify you once the results are ready.'}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.greyColor(context),
              fontSize: FontSize.scale(context, 14),
              fontFamily: AppFontFamily.regularFont,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIsAssignmentPassed() {
    final List<dynamic> submissionAttachments =
        assignmentDetails['submission_attachments'] ?? [];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.whiteColor),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 15),
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.dividerColor, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Image.asset(
                    AppImages.confetti,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${(Localization.translate('congratulations_passed') ?? '').trim() != 'congratulations_passed' && (Localization.translate('congratulations_passed') ?? '').trim().isNotEmpty ? Localization.translate('congratulations_passed') : 'Congratulations You Passed!'}',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: AppColors.blackColor.withOpacity(0.7),
                      fontSize: FontSize.scale(context, 16),
                      fontFamily: AppFontFamily.mediumFont,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '${(Localization.translate('achievement_title') ?? '').trim() != 'achievement_title' && (Localization.translate('achievement_title') ?? '').trim().isNotEmpty ? Localization.translate('achievement_title') : 'Great job on your achievement and keep up the fantastic work!'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: AppFontFamily.regularFont,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
          if (assignmentDetails['type'] == 'text') ...[
            SizedBox(height: 20),
            Text(
              '${(Localization.translate('answer') ?? '').trim() != 'answer' && (Localization.translate('answer') ?? '').trim().isNotEmpty ? Localization.translate('answer') : 'Answer'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.blackColor.withOpacity(0.7),
                fontSize: FontSize.scale(context, 16),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10),
            CustomTextField(
              hint:
                  "${(Localization.translate('answer') ?? '').trim() != 'answer' && (Localization.translate('answer') ?? '').trim().isNotEmpty ? Localization.translate('answer') : 'Answer'}",
              multiLine: true,
              mandatory: false,
              controller: _reviewController,
              readOnly: true,
            ),
          ] else if (assignmentDetails['type'] == 'document') ...[
            SizedBox(height: 20),
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
              children: List.generate(submissionAttachments.length, (index) {
                final file = submissionAttachments[index];
                return _buildShowAttachedFileItem(file, index);
              }),
            ),
          ] else if (assignmentDetails['type'] == 'both') ...[
            SizedBox(height: 20),
            Text(
              '${(Localization.translate('answer') ?? '').trim() != 'answer' && (Localization.translate('answer') ?? '').trim().isNotEmpty ? Localization.translate('answer') : 'Answer'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.blackColor.withOpacity(0.7),
                fontSize: FontSize.scale(context, 16),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10),
            CustomTextField(
              hint:
                  "${(Localization.translate('write_answer') ?? '').trim() != 'write_answer' && (Localization.translate('write_answer') ?? '').trim().isNotEmpty ? Localization.translate('write_answer') : 'Write your answer here'}",
              multiLine: true,
              mandatory: false,
              controller: _reviewController,
              readOnly: true,
            ),
            SizedBox(height: 20),
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
              children: List.generate(submissionAttachments.length, (index) {
                final file = submissionAttachments[index];
                return _buildShowAttachedFileItem(file, index);
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIsAssignmentFailed() {
    final List<dynamic> submissionAttachments =
        assignmentDetails['submission_attachments'] ?? [];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.whiteColor),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 15),
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.dividerColor, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Image.asset(
                    AppImages.keepLearning,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "${(Localization.translate('keep_learning') ?? '').trim() != 'keep_learning' && (Localization.translate('keep_learning') ?? '').trim().isNotEmpty ? Localization.translate('keep_learning') : "Don't Give Up! Keep Learning!"}",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: AppColors.blackColor.withOpacity(0.7),
                      fontSize: FontSize.scale(context, 16),
                      fontFamily: AppFontFamily.mediumFont,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "${(Localization.translate('almost_there') ?? '').trim() != 'almost_there' && (Localization.translate('almost_there') ?? '').trim().isNotEmpty ? Localization.translate('almost_there') : "Almost there! You didn't pass this time, but every challenge leads to success."}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: AppFontFamily.regularFont,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
          if (assignmentDetails['type'] == 'text') ...[
            SizedBox(height: 20),
            Text(
              '${(Localization.translate('answer') ?? '').trim() != 'answer' && (Localization.translate('answer') ?? '').trim().isNotEmpty ? Localization.translate('answer') : 'Answer'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.blackColor.withOpacity(0.7),
                fontSize: FontSize.scale(context, 16),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10),
            CustomTextField(
              hint:
                  "${(Localization.translate('answer') ?? '').trim() != 'answer' && (Localization.translate('answer') ?? '').trim().isNotEmpty ? Localization.translate('answer') : 'Answer'}",
              multiLine: true,
              mandatory: false,
              controller: _reviewController,
            ),
          ] else if (assignmentDetails['type'] == 'document') ...[
            SizedBox(height: 20),
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
              children: List.generate(submissionAttachments.length, (index) {
                final file = submissionAttachments[index];
                return _buildShowAttachedFileItem(file, index);
              }),
            ),
          ] else if (assignmentDetails['type'] == 'both') ...[
            SizedBox(height: 20),
            Text(
              '${(Localization.translate('answer') ?? '').trim() != 'answer' && (Localization.translate('answer') ?? '').trim().isNotEmpty ? Localization.translate('answer') : 'Answer'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.blackColor.withOpacity(0.7),
                fontSize: FontSize.scale(context, 16),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10),
            CustomTextField(
              hint:
                  "${(Localization.translate('write_answer') ?? '').trim() != 'write_answer' && (Localization.translate('write_answer') ?? '').trim().isNotEmpty ? Localization.translate('write_answer') : 'Write your answer here'}",
              multiLine: true,
              mandatory: false,
              controller: _reviewController,
            ),
            SizedBox(height: 20),
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
              children: List.generate(submissionAttachments.length, (index) {
                final file = submissionAttachments[index];
                return _buildShowAttachedFileItem(file, index);
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShowAttachedFileItem(Map file, int index) {
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
            AppImages.identityVerification,
            width: 20,
            height: 20,
            fit: BoxFit.cover,
            color: AppColors.primaryGreen(context),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file['name']?.toString() ?? '',
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
                  file['size']?.toString() ?? '',
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
              AppImages.removeIcon,
              width: 20,
              height: 20,
              color: AppColors.greyColor(context),
            ),
            onPressed: () {
              setState(() {
                uploadedFiles.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }
}
