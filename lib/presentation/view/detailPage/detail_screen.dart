import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../../../data/provider/settings_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import '../auth/login_screen.dart';
import '../bookSession/book_session.dart';
import '../components/certification_card.dart';
import '../components/education_card.dart';
import '../components/experience_card.dart';
import '../components/internet_alert.dart';
import '../components/login_required_alert.dart';
import '../components/student_card.dart';
import '../student/student_reviews.dart';
import 'package:chewie/chewie.dart';
import 'component/skeleton/detail_page_skeleton.dart';

class TutorDetailScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  TutorDetailScreen({required this.profile});

  @override
  _TutorDetailScreenState createState() => _TutorDetailScreenState();
}

class _TutorDetailScreenState extends State<TutorDetailScreen> {
  late double screenHeight;
  late double screenWidth;

  ChewieController? _chewieController;
  bool _isBuffering = true;
  late VideoPlayerController _videoController;

  Map<String, dynamic>? tutorDetails;
  String? videoUrl;
  Map<String, dynamic>? studentReviews;
  int currentPage = 1;

  bool isExpanded = false;
  String paymentEnabled = "no";

  void _initializeChewie(String videoUrl) async {
    _videoController = VideoPlayerController.network(videoUrl);
    await _videoController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: false,
      looping: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.primaryGreen(context),
        handleColor: AppColors.whiteColor,
        backgroundColor: AppColors.greyColor(context),
      ),
      showControls: true,
      showControlsOnInitialize: true,
    );

    setState(() {
      _isBuffering = false;
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Map<String, dynamic>? tutorEducation;

  Future<void> fetchTutorDetails(String slug) async {

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final fetchedDetails = await getTutors(token, slug);

      setState(() {
        _isBuffering = false;
      });

      if (fetchedDetails['status'] == 401) {
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
        tutorDetails = fetchedDetails;
        videoUrl = fetchedDetails['data']['profile']['intro_video'];

        if (videoUrl != null && videoUrl!.isNotEmpty) {
          _initializeChewie(videoUrl!);
        }
      });
    } catch (e) {}
  }

  Future<void> fetchTutorEducation(int tutorId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final fetchedEducation = await getTutorsEducation(token, tutorId);
      if (fetchedEducation['status'] == 401) {
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
        tutorEducation = fetchedEducation;
      });
    } catch (e) {}
  }

  Future<void> fetchTutorExperience(int tutorId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final fetchedExperience = await getTutorsExperience(token, tutorId);
      if (fetchedExperience['status'] == 401) {
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
        tutorExperience = fetchedExperience;
      });
    } catch (e) {}
  }

  Future<void> fetchTutorCertification(int tutorId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final fetchedCertification = await getTutorsCertification(token, tutorId);
      if (fetchedCertification['status'] == 401) {
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
        tutorCertification = fetchedCertification;
      });
    } catch (e) {}
  }

  Future<void> fetchStudentReviews(int tutorId, {int page = 1}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final fetchedReviews = await getStudentReviews(
        token,
        tutorId,
        page: page,
      );
      if (fetchedReviews['status'] == 401) {
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
        studentReviews = fetchedReviews;
      });
    } catch (e) {}
  }

  Map<String, dynamic>? tutorExperience;

  Map<String, dynamic>? tutorCertification;

  bool isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();

    fetchTutorDetails(widget.profile['slug']);

    fetchTutorEducation(widget.profile['id']);

    fetchTutorExperience(widget.profile['id']);

    fetchTutorCertification(widget.profile['id']);

    fetchStudentReviews(widget.profile['id'], page: currentPage);
  }

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 5.0,
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

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final String? role =
        userData != null && userData['user'] != null
            ? userData['user']['role']
            : null;

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
            return !_isBuffering;
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
                    padding: const EdgeInsets.only(top: 20.0),
                    child: AppBar(
                      forceMaterialTransparency: true,
                      backgroundColor: AppColors.whiteColor,
                      elevation: 0,
                      titleSpacing: 0,
                      centerTitle: false,
                      title: Text(
                        Localization.translate("tutor_detail"),
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
                      actions: [
                        if (role == 'student' &&
                            authProvider.token != null &&
                            authProvider.userData != null)
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              final isFavorite = authProvider.isTutorFavorite(
                                widget.profile['id'],
                              );

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: IconButton(
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onPressed:
                                      isLoadingFavorite
                                          ? null
                                          : () async {
                                            setState(() {
                                              isLoadingFavorite = true;
                                            });

                                            final token = authProvider.token;
                                            if (token != null) {
                                              try {
                                                final response =
                                                    await addDeleteFavouriteTutors(
                                                      token,
                                                      widget.profile['id'],
                                                      authProvider,
                                                    );

                                                if (response['status'] == 200) {
                                                  showCustomToast(
                                                    context,
                                                    '${response['message']}',
                                                    true,
                                                  );
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
                                                    response['message'],
                                                    false,
                                                  );
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (
                                                      BuildContext context,
                                                    ) {
                                                      return CustomAlertDialog(
                                                        title:
                                                            Localization.translate(
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
                                                  showCustomToast(
                                                    context,
                                                    response['message'],
                                                    false,
                                                  );
                                                }
                                              } catch (e) {
                                                showCustomToast(
                                                  context,
                                                  '${Localization.translate("error_message")} $e',
                                                  false,
                                                );
                                              } finally {
                                                setState(() {
                                                  isLoadingFavorite = false;
                                                });
                                              }
                                            }
                                          },
                                  icon:
                                      isLoadingFavorite
                                          ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primaryGreen(
                                                context,
                                              ),
                                            ),
                                          )
                                          : Icon(
                                            isFavorite
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color:
                                                isFavorite
                                                    ? AppColors.redColor
                                                    : AppColors.greyColor(
                                                      context,
                                                    ),
                                            size: 22,
                                          ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              body:
                  tutorDetails != null
                      ? SafeArea(
                        bottom:
                            Theme.of(context).platform == TargetPlatform.iOS
                                ? false
                                : true,
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildVideoSection(),
                                    _buildProfileSection(tutorDetails!),
                                    SizedBox(height: 10.0),
                                    _buildAboutMeSection(tutorDetails!),
                                    SizedBox(height: 10.0),
                                    if (tutorEducation != null)
                                      _buildEducationSection(
                                        List<Map<String, dynamic>>.from(
                                          tutorEducation!['data'] ?? '',
                                        ),
                                      ),
                                    SizedBox(height: 10.0),
                                    if (tutorExperience != null)
                                      _buildExperienceSection(
                                        List<Map<String, dynamic>>.from(
                                          tutorExperience!['data'] ?? '',
                                        ),
                                      ),
                                    SizedBox(height: 10.0),
                                    if (tutorCertification != null)
                                      _buildCertificationSection(
                                        List<Map<String, dynamic>>.from(
                                          tutorCertification!['data'] ?? '',
                                        ),
                                      ),
                                    SizedBox(height: 16.0),
                                    if (studentReviews != null &&
                                        studentReviews!['data'] != null &&
                                        studentReviews!['data']['list'] !=
                                            null &&
                                        studentReviews!['data']['list']
                                            .isNotEmpty)
                                      _buildStudentReviewsSection(),
                                    SizedBox(height: 20.0),
                                  ],
                                ),
                              ),
                            ),
                            tutorDetails != null
                                ? _buildBottomButton()
                                : BottomButtonSkeleton(),
                          ],
                        ),
                      )
                      : Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  VideoSectionSkeleton(),
                                  ProfileSectionSkeleton(),
                                  SizedBox(height: 10),
                                  AboutMeSectionSkeleton(),
                                  SizedBox(height: 10),
                                  EducationSectionSkeleton(),
                                  SizedBox(height: 10),
                                  ExperienceSectionSkeleton(),
                                  SizedBox(height: 10),
                                  CertificationSectionSkeleton(),
                                  SizedBox(height: 10),
                                  StudentReviewsSectionSkeleton(),
                                  SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                          BottomButtonSkeleton(),
                        ],
                      ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoSection() {
    if (_chewieController == null ||
        !_chewieController!.videoPlayerController.value.isInitialized) {
      return VideoSectionSkeleton();
    }

    if (_chewieController!.videoPlayerController.dataSource.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            Localization.translate("empty_video"),
            style: TextStyle(
              color: AppColors.greyColor(context),
              fontSize: FontSize.scale(context, 16),
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.normal,
              fontFamily: AppFontFamily.mediumFont,
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _chewieController!.videoPlayerController.value.aspectRatio,
      child:
          _isBuffering
              ? VideoSectionSkeleton()
              : Chewie(controller: _chewieController!),
    );
  }

  Widget _buildProfileSection(Map<String, dynamic> tutorDetails) {
    if (tutorDetails == null) {
      return ProfileSectionSkeleton();
    }

    if (tutorDetails.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            Localization.translate("detail_empty"),
            style: TextStyle(
              color: AppColors.blackColor,
              fontSize: FontSize.scale(context, 16),
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.normal,
              fontFamily: AppFontFamily.mediumFont,
            ),
          ),
        ),
      );
    }

    final profile = tutorDetails['data']['profile'];
    final fullName = profile['full_name'];
    final imageUrl = profile['image'];
    final minPrice = tutorDetails['data']['min_price'];
    final sessions = tutorDetails['data']['sessions'];
    final activeStudents = tutorDetails['data']['active_students'];
    final totalReviews = tutorDetails['data']['total_reviews'];
    final languages = tutorDetails['data']['languages'] ?? [];
    ;
    final subjects = tutorDetails['data']['subjects'] ?? [];
    final online = tutorDetails['data']['is_online'];
    final country = tutorDetails['data']['country'] ?? {};
    final countryShortCode = country['short_code'] ?? 'default';
    final active = tutorDetails['data']['email_verified_at'] ?? {};
    final rating = tutorDetails['data']['avg_rating'];
    final formattedRating =
        (rating != null)
            ? double.parse(rating.toString()).toStringAsFixed(1)
            : '0.0';
    final countryFlagUrl =
        '${AppUrls.flagUrl}${countryShortCode.toLowerCase()}.png';

    int visibleSubjectsCount = isExpanded ? subjects.length : 2;
    int remainingSubjectsCount = subjects.length - visibleSubjectsCount;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String profileImageUrl =
        authProvider.userData?['user']?['profile']?['image'] ?? '';

    final settingsProvider = Provider.of<SettingsProvider>(context);

    paymentEnabled =
        settingsProvider.getSetting('data')?['_lernen']?['payment_enabled'];

    Widget displayProfileImage() {
      Widget _buildShimmerSkeleton() {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 60,
            height: 60,
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
                  width: 60,
                  height: 60,
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
                      fit: BoxFit.cover,
                      width: 40,
                      height: 40,
                      color: AppColors.greyColor(context),
                    );
                  },
                ),
              ],
            );
          },
        );
      }

      if (imageUrl.isNotEmpty) {
        return buildImage(imageUrl);
      } else if (profileImageUrl.isNotEmpty) {
        return buildImage(profileImageUrl);
      } else {
        return SvgPicture.asset(
          AppImages.placeHolder,
          fit: BoxFit.cover,
          width: 60,
          height: 60,
          color: AppColors.greyColor(context),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: displayProfileImage(),
                    ),
                    Positioned(
                      bottom: -10,
                      left: 22,
                      child:
                          online == true
                              ? Image.asset(
                                AppImages.onlineIndicator,
                                width: 16,
                                height: 16,
                              )
                              : Container(),
                    ),
                  ],
                ),
                SizedBox(width: 10.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          fullName,
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            color: AppColors.blackColor,
                            fontSize: FontSize.scale(context, 18),
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.normal,
                            fontFamily: AppFontFamily.mediumFont,
                          ),
                        ),
                        active != null
                            ? Image.asset(
                              AppImages.active,
                              scale: 1,
                              width: 45,
                              height: 16,
                            )
                            : SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: FadeInImage.assetNetwork(
                            placeholder: AppImages.flag,
                            image: countryFlagUrl ?? '',
                            width: 18,
                            height: 14,
                            imageErrorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                AppImages.flag,
                                width: 18,
                                height: 18,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    if (paymentEnabled == "yes") ...[
                      SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          text: '${Localization.translate("starting")} ',
                          style: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontFamily: AppFontFamily.regularFont,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '$minPrice',
                              style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: FontSize.scale(context, 16),
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                                fontFamily: AppFontFamily.mediumFont,
                              ),
                            ),
                            TextSpan(text: ' '),
                            TextSpan(
                              text: Localization.translate("hr"),
                              style: TextStyle(
                                color: AppColors.greyColor(context),
                                fontSize: FontSize.scale(context, 14),
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontFamily: AppFontFamily.regularFont,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (subjects.isNotEmpty) ...[
              SizedBox(height: 20),
              Text(
                subjects
                    .map(
                      (sub) => sub['name'].toString().replaceAll('&amp;', '&'),
                    )
                    .join(" , "),
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: AppColors.blackColor,
                  fontSize: FontSize.scale(context, 14),
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.normal,
                  fontFamily: AppFontFamily.mediumFont,
                ),
              ),
            ],

            if (totalReviews != null) ...[
              SizedBox(height: 10),
              Row(
                children: [
                  SvgPicture.asset(
                    formattedRating == '5.0'
                        ? AppImages.filledStar
                        : AppImages.star,
                    width: 16,
                    height: 16,
                  ),
                  SizedBox(width: 5),
                  Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: formattedRating,
                          style: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                            fontFamily: AppFontFamily.mediumFont,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${(Localization.translate('total_rating') ?? '').trim() != 'total_rating' && (Localization.translate('total_rating') ?? '').trim().isNotEmpty ? Localization.translate('total_rating') : '/5.0'} ($totalReviews ${Localization.translate("reviews")})',
                          style: TextStyle(
                            color: AppColors.greyColor(
                              context,
                            ).withOpacity(0.7),
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontFamily: AppFontFamily.regularFont,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            if (activeStudents != null) ...[
              SizedBox(height: 10),
              Row(
                children: [
                  SvgPicture.asset(
                    AppImages.userIcon,
                    width: 14,
                    height: 14,
                    color: AppColors.greyColor(context),
                  ),
                  SizedBox(width: 5),
                  Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: '$activeStudents',
                          style: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                            fontFamily: AppFontFamily.mediumFont,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' ${Localization.translate("active")}${(activeStudents == 1) ? ' ${Localization.translate("active_student")}' : ' ${Localization.translate("active_students")}'}',
                          style: TextStyle(
                            color: AppColors.greyColor(
                              context,
                            ).withOpacity(0.7),
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontFamily: AppFontFamily.regularFont,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (sessions != null) ...[
              SizedBox(height: 10),
              Row(
                children: [
                  SvgPicture.asset(
                    AppImages.sessions,
                    width: 14,
                    height: 14,
                    color: AppColors.greyColor(context),
                  ),
                  SizedBox(width: 8),
                  Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: '$sessions ',
                          style: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                            fontFamily: AppFontFamily.mediumFont,
                          ),
                        ),
                        TextSpan(
                          text: Localization.translate("sessions"),
                          style: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontFamily: AppFontFamily.regularFont,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (subjects.isNotEmpty) ...[
              SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: SvgPicture.asset(
                      AppImages.bookEducationIcon,
                      width: 14,
                      height: 14,
                      color: AppColors.greyColor(context),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: '${Localization.translate("teach")} ',
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFontFamily.mediumFont,
                            ),
                          ),
                          for (
                            int i = 0;
                            i < visibleSubjectsCount && i < subjects.length;
                            i++
                          )
                            TextSpan(
                              text:
                                  '${subjects[i]['name']}${i < visibleSubjectsCount - 1 && i < subjects.length - 1 ? ', ' : ''}',
                              style: TextStyle(
                                color: AppColors.greyColor(
                                  context,
                                ).withOpacity(0.7),
                                fontSize: FontSize.scale(context, 14),
                                fontWeight: FontWeight.w400,
                                fontFamily: AppFontFamily.regularFont,
                              ),
                            ),
                          if (subjects.length > 2)
                            TextSpan(
                              text: ' ',
                              style: TextStyle(
                                fontSize: FontSize.scale(context, 14),
                              ),
                            ),
                          if (subjects.length > 2)
                            TextSpan(
                              text:
                                  isExpanded
                                      ? '${Localization.translate("show_less")}'
                                      : '+$remainingSubjectsCount ${Localization.translate("show_more")}',
                              style: TextStyle(
                                color: AppColors.greyColor(
                                  context,
                                ).withOpacity(0.9),
                                fontSize: FontSize.scale(context, 14),
                                fontWeight: FontWeight.w500,
                                fontFamily: AppFontFamily.regularFont,
                              ),
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap = () {
                                      setState(() {
                                        isExpanded = !isExpanded;
                                      });
                                    },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (languages.isNotEmpty) ...[
              SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: SvgPicture.asset(
                      AppImages.language,
                      width: 14,
                      height: 14,
                      color: AppColors.greyColor(context),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: Localization.translate("languages"),
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              fontFamily: AppFontFamily.mediumFont,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' ${languages.map((lang) => lang['name']).join(", ")}',
                            style: TextStyle(
                              color: AppColors.greyColor(
                                context,
                              ).withOpacity(0.7),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                              fontFamily: AppFontFamily.regularFont,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutMeSection(Map<String, dynamic> tutorDetails) {
    if (tutorDetails == null ||
        tutorDetails['data']['profile']['description'] == null) {
      return AboutMeSectionSkeleton();
    }

    if (tutorDetails.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              '${Localization.translate("empty_description")} ',
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

    final description =
        tutorDetails['data']['profile']['description'] ??
        '${Localization.translate("description_unavailable")}';
    final words = description.split(RegExp(r'\s+'));
    final isExpanded = ValueNotifier<bool>(false);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.whiteColor),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Localization.translate("about"),
                style: TextStyle(
                  color: AppColors.blackColor,
                  fontSize: FontSize.scale(context, 18),
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFontFamily.mediumFont,
                ),
              ),
              SizedBox(height: 10.0),
              ValueListenableBuilder<bool>(
                valueListenable: isExpanded,
                builder: (context, expanded, child) {
                  String aboutDescription;
                  bool showSeeMore = words.length > 20;

                  if (expanded || !showSeeMore) {
                    aboutDescription = description;
                  } else {
                    aboutDescription =
                        description.split(' ').take(20).join(' ') + '... ';
                  }

                  return RichText(
                    text: TextSpan(
                      children: [
                        WidgetSpan(
                          child: HtmlWidget(
                            aboutDescription,
                            textStyle: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 15),
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
        ),
      ),
    );
  }

  Widget _buildEducationSection(List<Map<String, dynamic>> educationData) {
    if (educationData == null) {
      return EducationSectionSkeleton();
    }

    if (educationData.isEmpty) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              '${Localization.translate("education_empty")}',
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
      decoration: BoxDecoration(color: AppColors.whiteColor),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${Localization.translate("education")}',
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 18),
                fontWeight: FontWeight.w600,
                fontFamily: AppFontFamily.mediumFont,
              ),
            ),
            SizedBox(height: 10),
            ...educationData.asMap().entries.map((entry) {
              final index = entry.key;
              final education = entry.value;
              final showDivider = index < educationData.length - 1;

              final startDate = education['start_date'];
              final endDate =
                  education['ongoing'] == 1 ? 'Current' : education['end_date'];

              return EducationCard(
                courseTitle: education['course_title'],
                institute: education['institute_name'],
                location:
                    '${education['city']}, ${education['country']['name']}',
                duration: '$startDate - $endDate',
                description: education['description'],
                showDivider: showDivider,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceSection(List<Map<String, dynamic>> experienceData) {
    if (experienceData == null) {
      return ExperienceSectionSkeleton();
    }

    if (experienceData.isEmpty) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              '${Localization.translate("experience_empty")}',
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
      decoration: BoxDecoration(color: AppColors.whiteColor),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${Localization.translate("experience")}',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 18),
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.normal,
                fontFamily: AppFontFamily.mediumFont,
              ),
            ),
            SizedBox(height: 10),
            ...experienceData.map((experience) {
              final String position =
                  experience['title']?.toString() ?? 'Unknown Title';
              final String institute =
                  experience['company']?.toString() ?? 'Unknown Institute';
              final String employmentType =
                  experience['employment_type']?.toString() ?? 'Unknown Type';
              final String location =
                  experience['location']?.toString().toLowerCase() ??
                  'Unknown Location';
              final String formattedLocation =
                  location[0].toUpperCase() + location.substring(1);
              final String startDate =
                  experience['start_date']?.toString() ?? 'Unknown Start Date';
              final String endDate =
                  experience['end_date']?.toString() ?? 'Unknown End Date';
              final String description =
                  experience['description']?.toString() ??
                  'No Description Available';

              return ExperienceCard(
                experienceTitle: position,
                institute: institute,
                employmentType: employmentType,
                location: formattedLocation,
                duration: "$startDate - $endDate",
                description: description,
                showDivider: experience != experienceData.last,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationSection(
    List<Map<String, dynamic>> certificationData,
  ) {
    if (certificationData.isEmpty) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              '${Localization.translate("certificate_empty")}',
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
      decoration: BoxDecoration(color: AppColors.whiteColor),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${Localization.translate("certification")}',
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 18),
                fontWeight: FontWeight.w600,
                fontFamily: AppFontFamily.mediumFont,
              ),
            ),
            SizedBox(height: 10),
            ...certificationData.map((certification) {
              return CertificateCard(
                imagePath: certification['image'] ?? "",
                certificateTitle: certification['title'],
                institute: certification['institute_name'],
                issued:
                    "${Localization.translate("issued")} ${certification['issue_date']}",
                duration:
                    "${Localization.translate("expiry")} ${certification['expiry_date']}",
                description: certification['description'],
                showDivider: certification != certificationData.last,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentReviewsSection() {
    if (studentReviews == null) {
      return StudentReviewsSectionSkeleton();
    }

    if (studentReviews!['data']['list'].isEmpty) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              '${Localization.translate("empty_reviews")}',
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

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Localization.translate("student_reviews")}',
                style: TextStyle(
                  color: AppColors.blackColor,
                  fontSize: FontSize.scale(context, 16),
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.normal,
                  fontFamily: AppFontFamily.mediumFont,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: () {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final token = authProvider.token;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentReviewsScreen(
                              initialPage: 1,
                              fetchReviews: (page) async {
                                return await getStudentReviews(
                                  token,
                                  widget.profile['id'],
                                  page: page,
                                );
                              },
                            ),
                      ),
                    );
                  },
                  child: Text(
                    '${Localization.translate("explore")}',
                    style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 14),
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                      fontFamily: AppFontFamily.mediumFont,
                    ),
                  ),
                  style: ButtonStyle(
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                    splashFactory: NoSplash.splashFactory,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                studentReviews != null
                    ? studentReviews!['data']['list'].length
                    : 0,
                (index) {
                  final review = studentReviews!['data']['list'][index];
                  final profile = review['profile'];
                  final country = review['country'];

                  return ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 150),
                    child: StudentCard(
                      name: profile['short_name'],
                      date: review['created_at'],
                      description: review['comment'],
                      rating: review['rating'].toDouble(),
                      image: profile['image'],
                      countryFlag:
                          country != null && country['short_code'] != null
                              ? '${AppUrls.flagUrl}${country['short_code'].toLowerCase()}.png'
                              : '',
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    return Container(
      height: screenHeight * 0.09,
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
          if (token == null) {
            _showLoginRequiredDialog();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        BookSessionScreen(tutorDetail: tutorDetails?['data']),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${Localization.translate("book_session")}',
              style: TextStyle(
                color: AppColors.whiteColor,
                fontSize: FontSize.scale(context, 16),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 8.0),
            SvgPicture.asset(
              AppImages.addSessionIcon,
              height: 20,
              color: AppColors.whiteColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: "${Localization.translate("login_required")}",
          content: "${Localization.translate("login_access")}",
          buttonText: "${Localization.translate("goToLogin")}",
          buttonAction: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
        );
      },
    );
  }
}
