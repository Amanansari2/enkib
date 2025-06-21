import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/data/provider/settings_provider.dart';
import 'package:flutter_projects/domain/api_structure/api_service.dart';
import 'package:flutter_projects/presentation/view/assignment/component/custom_assignment_dialog.dart';
import 'package:flutter_projects/presentation/view/assignment/submitAssignment/submit_assignment.dart';
import 'package:flutter_projects/presentation/view/auth/login_screen.dart';
import 'package:flutter_projects/presentation/view/community/component/utils/date_utils.dart';
import 'package:flutter_projects/presentation/view/components/login_required_alert.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../data/localization/localization.dart';
import '../../../../data/provider/auth_provider.dart';
import '../../../../data/provider/connectivity_provider.dart';
import '../../../../styles/app_styles.dart';
import '../../components/internet_alert.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'skeleton/start_assignment_skeleton.dart';

class StartAssignment extends StatefulWidget {
  final String assignmentId;
  const StartAssignment({super.key, required this.assignmentId});

  @override
  State<StartAssignment> createState() => _StartAssignmentState();
}

class _StartAssignmentState extends State<StartAssignment> {
  int maxCharacters = 800;
  bool isLoading = false;
  late double screenHeight;
  late double screenWidth;
  final TextEditingController _descriptionController = TextEditingController();
  Map<String, dynamic> assignmentDetails = {};
  List<Map<String, String>> downloadedFiles = [];

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_updateCharacterCount);
    _fetchAssignmentDetails();
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
          if (assignmentDetails['assignment_attachments'] != null) {
            downloadedFiles =
                (assignmentDetails['assignment_attachments'] as List).map((
                  attachment,
                ) {
                  return {
                    'name': (attachment['name'] ?? '').toString(),
                    'size': (attachment['size'] ?? '').toString(),
                    'url': (attachment['url'] ?? '').toString(),
                    'type': (attachment['type'] ?? '').toString(),
                  };
                }).toList();
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

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      var status = await Permission.storage.request();

      if (status.isDenied) {
        showCustomToast(
          context,
          "${(Localization.translate('storagePermissionDenied') ?? '').trim() != 'storagePermissionDenied' && (Localization.translate('storagePermissionDenied') ?? '').trim().isNotEmpty ? Localization.translate('storagePermissionDenied') : 'Storage permission denied. Please grant permission.'}",
          false,
        );
        return;
      }

      if (status.isPermanentlyDenied) {
        showCustomToast(
          context,
          "${(Localization.translate('storagePermissionPermanentlyDenied') ?? '').trim() != 'storagePermissionPermanentlyDenied' && (Localization.translate('storagePermissionPermanentlyDenied') ?? '').trim().isNotEmpty ? Localization.translate('storagePermissionPermanentlyDenied') : 'Storage permission permanently denied. Open app settings to enable it.'}",
          false,
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

        showCustomToast(
          context,
          "${(Localization.translate('downloadedSuccessfully') ?? '').trim() != 'downloadedSuccessfully' && (Localization.translate('downloadedSuccessfully') ?? '').trim().isNotEmpty ? Localization.translate('downloadedSuccessfully') : 'Downloaded successfully to $filePath'}",
          true,
        );
      } else {
        throw Exception(
          '${(Localization.translate('downloadFailedFile') ?? '').trim() != 'downloadFailedFile' && (Localization.translate('downloadFailedFile') ?? '').trim().isNotEmpty ? Localization.translate('downloadFailed') : 'Failed to download file'}',
        );
      }
    } catch (e) {
      showCustomToast(
        context,
        "${(Localization.translate('downloadFailed') ?? '').trim() != 'downloadFailed' && (Localization.translate('downloadFailed') ?? '').trim().isNotEmpty ? Localization.translate('downloadFailed') : 'Download failed'}",
        false,
      );
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

  @override
  void dispose() {
    _descriptionController.removeListener(_updateCharacterCount);
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateCharacterCount() {
    setState(() {});
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
                  ? StartAssignmentSkeleton()
                  : Directionality(
                    textDirection: Localization.textDirection,
                    child: Scaffold(
                      backgroundColor: AppColors.backgroundColor(context),
                      appBar: PreferredSize(
                        preferredSize: Size.fromHeight(70.0),
                        child: Container(
                          color: AppColors.whiteColor,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: AppBar(
                              forceMaterialTransparency: true,
                              backgroundColor: AppColors.whiteColor,
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
                                },
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
                                  _buildImageSection(),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildProfileSection(),
                                      SizedBox(height: 10),
                                      _buildDescription(),
                                      SizedBox(height: 10),
                                      _buildDownloadedDocuments(),
                                      SizedBox(height: 20.0),
                                    ],
                                  ),
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

  Widget _buildImageSection() {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final settings = settingsProvider.getSetting('data')?['_assignments'];
    String? thumbnail;
    String? heading;

    if (settings != null) {
      thumbnail =
          (settings['assignment_banner_image'] != null &&
                  settings['assignment_banner_image'] is List &&
                  settings['assignment_banner_image'].isNotEmpty)
              ? settings['assignment_banner_image'][0]['thumbnail']
              : null;

      heading = settings['attempt_assignment_heading'];
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          AppImages.startAssignment,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
        ),
        Column(
          children: [
            if (thumbnail != null)
              (thumbnail.endsWith('.svg')
                  ? SvgPicture.network(
                    thumbnail,
                    width: 35,
                    height: 35,
                    fit: BoxFit.contain,
                    placeholderBuilder:
                        (context) => CircularProgressIndicator(
                          color: AppColors.whiteColor,
                          strokeWidth: 2.0,
                        ),
                  )
                  : Image.network(
                    thumbnail,
                    width: 35,
                    height: 35,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) => SvgPicture.asset(
                          AppImages.defaultSplash,
                          width: 35,
                          height: 35,
                          fit: BoxFit.contain,
                        ),
                  ))
            else
              SvgPicture.asset(
                AppImages.defaultSplash,
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
            SizedBox(height: 20),
            Text(
              '${heading ?? "You're About to Start Your Assignment"}',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: AppColors.whiteColor.withOpacity(0.9),
                fontSize: FontSize.scale(context, 18),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildDownloadedDocuments() {
    if (downloadedFiles.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              "${(Localization.translate('empty_attachments') ?? '').trim() != 'empty_attachments' && (Localization.translate('empty_attachments') ?? '').trim().isNotEmpty ? Localization.translate('empty_attachments') : 'No Attachments Available'}",
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
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            children: List.generate(downloadedFiles.length, (index) {
              return _buildFileItem(downloadedFiles[index], index);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(Map<String, String> file, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dividerColor, width: 1),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            file['type']?.toLowerCase() == 'image'
                ? AppImages.imageIcon
                : AppImages.fileIcon,
            color: AppColors.greyColor(context),
            width: 20.0,
            height: 20.0,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file['name'] ?? '',
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
                  file['size'] ?? '',
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

  Widget _buildBottomButton() {
    return Container(
      height: screenHeight * 0.09,
      width: screenWidth,
      decoration: BoxDecoration(
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
        onPressed: () {
          if (assignmentDetails['result'] == 'assigned') {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return CustomAssignmentDialog(
                  buttonAction: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => SubmitAssignment(
                              assignmentId: widget.assignmentId,
                            ),
                      ),
                    );
                  },
                );
              },
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        SubmitAssignment(assignmentId: widget.assignmentId),
              ),
            );
          }
        },
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
        child: Text(
          assignmentDetails['result'] == 'assigned'
              ? "${(Localization.translate('start_assignment') ?? '').trim() != 'start_assignment' && (Localization.translate('start_assignment') ?? '').trim().isNotEmpty ? Localization.translate('start_assignment') : 'Start Assignment'}"
              : "${(Localization.translate('review_assignment_result') ?? '').trim() != 'review_assignment_result' && (Localization.translate('review_assignment_result') ?? '').trim().isNotEmpty ? Localization.translate('review_assignment_result') : 'Review Assignment Result'}",
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
}
