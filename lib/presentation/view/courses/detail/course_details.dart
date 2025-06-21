import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/domain/api_structure/api_service.dart';
import 'package:flutter_projects/presentation/view/course_taking/course_taking_listing.dart';
import 'package:flutter_projects/presentation/view/courses/component/course_card.dart';
import 'package:flutter_projects/presentation/view/courses/detail/review_details.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../../data/localization/localization.dart';
import '../../../../data/provider/auth_provider.dart';
import '../../../../data/provider/connectivity_provider.dart';
import '../../../../data/provider/settings_provider.dart';
import '../../auth/login_screen.dart';
import '../../bookSession/component/order_summary_bottom_sheet.dart';
import '../../community/component/utils/date_utils.dart';
import '../../components/internet_alert.dart';
import '../../components/login_required_alert.dart';
import '../../components/student_card.dart';
import '../../detailPage/component/skeleton/detail_page_skeleton.dart';
import '../skeleton/course_detail_skeleton.dart';

class CourseDetailScreen extends StatefulWidget {
  final String slug;
  final int id;

  CourseDetailScreen({required this.slug, required this.id});
  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late double screenHeight;
  late double screenWidth;

  ChewieController? _chewieController;
  late VideoPlayerController _videoController;
  bool _isBuffering = true;
  bool onPresLoading = false;
  bool isFreeEnrolled = false;
  bool isEnrolled = false;

  Map<String, dynamic>? courseDetails;
  String? videoUrl;
  String paymentEnabled = "no";

  @override
  void initState() {
    super.initState();
    fetchCourseDetails();
  }

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
      deviceOrientationsOnEnterFullScreen: [DeviceOrientation.portraitUp],
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
    );

    setState(() {
      _isBuffering = false;
    });
  }

  Future<void> fetchCourseDetails() async {
    try {
      _initializeChewie(videoUrl ?? "");

      setState(() {
        _isBuffering = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final fetchedDetails = await getCourseDetails(token, widget.slug);

      if (fetchedDetails['status'] == 200) {
        setState(() {
          courseDetails = fetchedDetails;
          isEnrolled = courseDetails?['data']['is_enrolled'] ?? false;
          videoUrl = fetchedDetails['data']['promotional_video']?['url'] ?? '';
          _isBuffering = false;
        });

        if (videoUrl != null && videoUrl!.isNotEmpty) {
          _initializeChewie(videoUrl!);
        }
      } else if (fetchedDetails['status'] == 401) {
        setState(() {
          _isBuffering = false;
        });
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
      } else {
        showCustomToast(context, fetchedDetails['message'] ?? "Error", false);
      }
    } catch (e) {
      setState(() {
        _isBuffering = false;
      });
    }
  }

  Future<Map<String, dynamic>> _addEnrollFreeCourseToCart(
    BuildContext context,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final String courseId = widget.id.toString();

    if (token != null) {
      try {
        setState(() {
          isFreeEnrolled = true;
        });

        final Map<String, dynamic> data = {'slug': widget.slug};

        final response = await enrolledFreeCourse(token, data, courseId);

        if (response['status'] == 200) {
          showCustomToast(context, response['message'], true);
          await fetchCourseDetails();
          await Future.delayed(Duration(milliseconds: 200));
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CourseTakingScreen()),
          );
        } else if (response['status'] == 403 || response['status'] == 400) {
          showCustomToast(context, response['message'], false);
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
          showCustomToast(context, response['message'], false);
        }
        return response;
      } catch (e) {
        final errorMessage =
            '${Localization.translate("failed_book_session")} $e';
        final Map<String, dynamic> errorResponse = {
          'status': 500,
          'message': errorMessage,
        };
        showCustomToast(context, errorMessage, false);
        return errorResponse;
      } finally {
        setState(() {
          isFreeEnrolled = false;
        });
      }
    } else {
      final errorResponse = {
        'status': 401,
        'message': '${Localization.translate("unauthorized_access")}',
      };
      return errorResponse;
    }
  }

  Future<void> _addCourseToCart(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final String courseId = widget.id.toString();

    if (token != null) {
      try {
        setState(() {
          onPresLoading = true;
        });

        final Map<String, dynamic> data = {'slug': widget.slug};

        final response = await bookCourseCart(token, data, courseId);

        if (response['status'] == 200) {
          setState(() {
            onPresLoading = false;
          });
          showCustomToast(context, response['message'], true);
          await Future.delayed(Duration(milliseconds: 500));
          await _fetchCourseCart(context);
        } else if (response['status'] == 403) {
          setState(() {
            onPresLoading = false;
          });
          showCustomToast(context, response['message'], false);
        } else if (response['status'] == 401) {
          setState(() {
            onPresLoading = false;
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
          showCustomToast(context, response['message'], false);
          setState(() {
            onPresLoading = false;
          });
        }
      } catch (e) {
        showCustomToast(context, "$e", false);
        setState(() {
          onPresLoading = false;
        });
      } finally {
        setState(() {
          onPresLoading = false;
        });
      }
    } else {}
  }

  Future<void> _fetchCourseCart(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token != null) {
      try {
        final response = await getBookingCart(token);

        final Map<String, dynamic> cartData = Map<String, dynamic>.from(
          response['data'],
        );

        final List<Map<String, dynamic>> cartItems =
            (cartData['cartItems'] as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();

        if (paymentEnabled == "yes") {
          await showModalBottomSheet(
            backgroundColor: AppColors.sheetBackgroundColor,
            context: context,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder:
                (context) => OrderSummaryBottomSheet(
                  sessionData: {},
                  profileDta: {},
                  cartData: cartItems,
                  total: cartData['total'],
                  subtotal: cartData['subtotal'],
                ),
          );
        } else {}

        fetchCourseDetails();
      } catch (e) {
        showCustomToast(
          context,
          '${Localization.translate("failed_fetch_courses")} $e',
          false,
        );
      }
    } else {
      showCustomToast(
        context,
        '${Localization.translate("unauthorized_access")} ',
        false,
      );
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    paymentEnabled =
        settingsProvider.getSetting('data')?['_lernen']?['payment_enabled'];

    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final token = authProvider.token;
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
            if (_isBuffering) {
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
                    padding: const EdgeInsets.only(top: 20.0),
                    child: AppBar(
                      forceMaterialTransparency: true,
                      backgroundColor: AppColors.whiteColor,
                      elevation: 0,
                      titleSpacing: 0,
                      centerTitle: false,
                      title: Text(
                        "${(Localization.translate('course_details') ?? '').trim() != 'course_details' && (Localization.translate('course_details') ?? '').trim().isNotEmpty ? Localization.translate('course_details') : 'Course Details'}",
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
                          _buildVideoSection(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileSection(courseDetails),
                              SizedBox(height: 10),
                              _buildAboutCourse(courseDetails),
                              SizedBox(height: 10),
                              _buildLearn(courseDetails),
                              SizedBox(height: 10),
                              _buildCourseCurriculum(courseDetails),
                              SizedBox(height: 10),
                              buildFaq(courseDetails),
                              SizedBox(height: 10),
                              _buildPrerequisites(courseDetails),
                              SizedBox(height: 10),
                              _buildReviewsSection(courseDetails),
                              SizedBox(height: 20.0),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (role == "student" &&
                      userData != null &&
                      token != null) ...[
                    courseDetails != null
                        ? _buildBottomButton()
                        : BottomButtonSkeleton(),
                  ],
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

  Widget _buildProfileSection(Map<String, dynamic>? courseDetails) {
    if (courseDetails == null) {
      return CourseProfileSkeleton();
    }

    final subtitle = courseDetails['data']['subtitle'] ?? '';
    final title = courseDetails['data']['title'] ?? '';
    final name = courseDetails['data']['instructor']['name'] ?? '';
    final imageUrl = courseDetails['data']['instructor']['image'] ?? '';
    final lessons = courseDetails['data']['curriculums_count'] ?? '';
    final date = courseDetails['data']['updated_at'] ?? '';
    final online = courseDetails['data']['instructor']['is_online'];
    final country = courseDetails['data']['instructor'];

    final countryShortCode = country['country_short_code'] ?? '';

    final countryFlagUrl =
        '${AppUrls.flagUrl}${countryShortCode.toLowerCase()}.png';

    String _formatDate(String date) {
      return formatDateWithMinMonth(date);
    }

    final formattedDate = _formatDate(date);

    final languages = courseDetails['data']['language']['name'] ?? '';
    final enrollment =
        courseDetails['data']['enrollments_count'] ??
        '${(Localization.translate('empty_enrolled_students') ?? '').trim() != 'empty_enrolled_students' && (Localization.translate('empty_enrolled_students') ?? '').trim().isNotEmpty ? Localization.translate('empty_enrolled_students') : 'No enrolled students'}';

    Widget buildCountryFlag() {
      return Image.network(
        countryFlagUrl,
        width: 18,
        height: 14,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox.shrink();
        },
      );
    }

    final active = courseDetails['data']['instructor']['verified_at'] ?? {};
    final rating = courseDetails['data']['ratings_avg_rating'] ?? '';
    final level = courseDetails['data']['level'] ?? '';

    String capitalizedLevel =
        level.isNotEmpty
            ? level[0].toUpperCase() + level.substring(1).toLowerCase()
            : '';

    bool _isValidDouble(String value) {
      return double.tryParse(value) != null;
    }

    final formattedRating =
        (rating != null && _isValidDouble(rating.toString()))
            ? double.parse(rating.toString()).toStringAsFixed(1)
            : '0.0';
    final totalReviews = courseDetails['data']['ratings_count'] ?? '';
    final views = courseDetails['data']['views_count'] ?? '';

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String profileImageUrl =
        authProvider.userData?['user']?['profile']?['image'] ?? '';

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

      if (imageUrl.isNotEmpty) {
        return buildImage(imageUrl);
      } else if (profileImageUrl.isNotEmpty) {
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
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: displayProfileImage(),
                    ),
                    Positioned(
                      bottom: -10,
                      left: 12,
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
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$name',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: AppColors.blackColor,
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: AppFontFamily.mediumFont,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 6),
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
                            child: buildCountryFlag(),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$subtitle',
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
              '$title',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 18),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '$subtitle',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: AppColors.greyColor(context),
                fontSize: FontSize.scale(context, 14),
                fontFamily: AppFontFamily.regularFont,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                lessons != null && lessons.toString().isNotEmpty
                    ? Row(
                      children: [
                        SvgPicture.asset(
                          AppImages.bookEducationIcon,
                          width: 15,
                          height: 15,
                          color: AppColors.greyColor(context),
                        ),
                        SizedBox(width: 6),
                        Text.rich(
                          TextSpan(
                            children:
                                lessons != null && lessons.toString().isNotEmpty
                                    ? <TextSpan>[
                                      TextSpan(
                                        text: '$lessons',
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
                                            (lessons == 0 || lessons == 1)
                                                ? "${(Localization.translate('lessons') ?? '').trim() == 'Lessons'
                                                    ? 'Lesson'
                                                    : (Localization.translate('lessons') ?? '').trim().isNotEmpty
                                                    ? Localization.translate('lessons')
                                                    : 'Lesson'}"
                                                : "${(Localization.translate('lessons') ?? '').trim() != 'lessons' && (Localization.translate('lessons') ?? '').trim().isNotEmpty ? Localization.translate('lessons') : 'Lessons'}",
                                        style: TextStyle(
                                          color: AppColors.greyColor(
                                            context,
                                          ).withOpacity(0.7),
                                          fontSize: FontSize.scale(context, 14),
                                          fontWeight: FontWeight.w400,
                                          fontFamily: AppFontFamily.regularFont,
                                        ),
                                      ),
                                    ]
                                    : [],
                          ),
                        ),
                      ],
                    )
                    : SizedBox.shrink(),
                Row(
                  children: [
                    SvgPicture.asset(
                      AppImages.timerIcon,
                      width: 15,
                      height: 15,
                      color: AppColors.greyColor(context),
                    ),
                    SizedBox(width: 8),
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: '$formattedDate',
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
                                "${(Localization.translate('last_updated') ?? '').trim() != 'last_updated' && (Localization.translate('last_updated') ?? '').trim().isNotEmpty ? Localization.translate('last_updated') : 'Last updated'}",
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
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      formattedRating == '5.0'
                          ? AppImages.filledStar
                          : AppImages.star,
                      width: 15,
                      height: 15,
                    ),
                    SizedBox(width: 6),
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: '$formattedRating',
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
                                '${(Localization.translate('total_rating') ?? '').trim() != 'total_rating' && (Localization.translate('total_rating') ?? '').trim().isNotEmpty ? Localization.translate('total_rating') : '/5.0'} ($totalReviews ${Localization.translate(totalReviews == 0 || totalReviews == 1 ? "review" : "reviews")})',
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
                      AppImages.showIcon,
                      width: 15,
                      height: 15,
                      color: AppColors.greyColor(context),
                    ),
                    SizedBox(width: 8),
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: '$views',
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
                                (views == 0 || views == 1)
                                    ? "${(Localization.translate('views') ?? '').trim() == 'Views'
                                        ? 'View'
                                        : (Localization.translate('views') ?? '').trim().isNotEmpty
                                        ? Localization.translate('views')
                                        : 'View'}"
                                    : "${(Localization.translate('views') ?? '').trim() != 'views' && (Localization.translate('views') ?? '').trim().isNotEmpty ? Localization.translate('views') : 'Views'}",
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
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      AppImages.levelIcon,
                      width: 15,
                      height: 15,
                      color: AppColors.greyColor(context),
                    ),
                    SizedBox(width: 6),
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: '$capitalizedLevel',
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
                                "${(Localization.translate('level') ?? '').trim() != 'level' && (Localization.translate('level') ?? '').trim().isNotEmpty ? Localization.translate('level') : 'Level'}",
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
                      AppImages.language,
                      width: 15,
                      height: 15,
                      color: AppColors.greyColor(context),
                    ),
                    SizedBox(width: 8),
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: '$languages',
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
                                '${(Localization.translate('language') ?? '').trim() == 'Languages'
                                    ? 'Language'
                                    : (Localization.translate('language') ?? '').trim().isNotEmpty
                                    ? Localization.translate('language')
                                    : 'Language'}',
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
            SizedBox(height: 10),
            enrollment != null && lessons.toString().isNotEmpty
                ? Row(
                  children: [
                    SvgPicture.asset(
                      AppImages.userIcon,
                      width: 15,
                      height: 15,
                      color: AppColors.greyColor(context),
                    ),
                    SizedBox(width: 6),
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: '$enrollment',
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
                                (enrollment == 0 || enrollment == 1)
                                    ? "${(Localization.translate('enrolments') ?? '').trim() == 'Enrolments'
                                        ? 'Enrolment'
                                        : (Localization.translate('enrolments') ?? '').trim().isNotEmpty
                                        ? Localization.translate('enrolments')
                                        : 'Enrolment'}"
                                    : "${(Localization.translate('enrolments') ?? '').trim() != 'enrolments' && (Localization.translate('enrolments') ?? '').trim().isNotEmpty ? Localization.translate('enrolments') : 'Enrolments'}",
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
                )
                : SizedBox.shrink(),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCourse(Map<String, dynamic>? courseDetails) {
    if (courseDetails == null || courseDetails['data']['description'] == null) {
      return AboutCourseSkeleton();
    }

    if (courseDetails.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              "${(Localization.translate('description_empty') ?? '').trim() != 'description_empty' && (Localization.translate('description_empty') ?? '').trim().isNotEmpty ? Localization.translate('description_empty') : 'Courses description empty'}",
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
        courseDetails['data']['description'] ??
        '${Localization.translate("description_unavailable")}';
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
            "${(Localization.translate('about_course') ?? '').trim() != 'about_course' && (Localization.translate('about_course') ?? '').trim().isNotEmpty ? Localization.translate('about_course') : 'About This Course'}",
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: AppColors.blackColor,
              fontSize: FontSize.scale(context, 18),
              fontFamily: AppFontFamily.mediumFont,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
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
    );
  }

  Widget _buildLearn(Map<String, dynamic>? courseDetails) {
    final learn =
        (courseDetails?['data']['learning_objectives'] is List)
            ? List<String>.from(
              courseDetails?['data']['learning_objectives'] ?? [],
            )
            : [];

    if (courseDetails == null) {
      return AboutCourseSkeleton();
    }

    if (learn.isEmpty) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              "${(Localization.translate('empty_learnings') ?? '').trim() != 'empty_learnings' && (Localization.translate('empty_learnings') ?? '').trim().isNotEmpty ? Localization.translate('empty_learnings') : 'Learnings not available'}",
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
          Text(
            "${(Localization.translate('what_learn_text') ?? '').trim() != 'what_learn_text' && (Localization.translate('what_learn_text') ?? '').trim().isNotEmpty ? Localization.translate('what_learn_text') : "What you'll learn"}",
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: AppColors.blackColor,
              fontSize: FontSize.scale(context, 18),
              fontFamily: AppFontFamily.mediumFont,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
          Column(
            children:
                learn.isNotEmpty
                    ? learn.map<Widget>((learning) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Transform.translate(
                              offset: Offset(0, 6.0),
                              child: SvgPicture.asset(
                                AppImages.checkCircle,
                                height: 15.0,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                learning,
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 14),
                                  fontFamily: AppFontFamily.regularFont,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()
                    : [
                      Text(
                        "${(Localization.translate('empty_learnings_objectives') ?? '').trim() != 'empty_learnings_objectives' && (Localization.translate('empty_learnings_objectives') ?? '').trim().isNotEmpty ? Localization.translate('empty_learnings_objectives') : "No learning objectives available."}",
                        style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.regularFont,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCurriculum(Map<String, dynamic>? courseDetails) {
    final List<Map<String, dynamic>> courseSections =
        (courseDetails?['data']['sections'] as List?)?.map((section) {
          return {
            "title": section["title"],
            "lectures": section["curriculums_count"] ?? 0,
            "duration": section["content_length"] ?? "",
            "expanded": false,
            "description": section["description"] ?? "",
            "lessons":
                (section["curriculums"] as List?)?.map((lesson) {
                  return {
                    "title": lesson["title"],
                    "duration": lesson["content_length"] ?? "",
                    "preview": lesson["is_preview"] ?? false,
                    "description": lesson["description"] ?? "",
                    "media_path": lesson["media_path"] ?? "",
                  };
                }).toList() ??
                [],
          };
        }).toList() ??
        [];

    if (courseDetails == null) {
      return AboutCourseSkeleton();
    }

    if (courseSections.isEmpty) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              "${(Localization.translate('empty_curriculum') ?? '').trim() != 'empty_curriculum' && (Localization.translate('empty_curriculum') ?? '').trim().isNotEmpty ? Localization.translate('empty_curriculum') : "Course Curriculum not available"}",
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
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: AppColors.whiteColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${(Localization.translate('course_curriculum') ?? '').trim() != 'course_curriculum' && (Localization.translate('course_curriculum') ?? '').trim().isNotEmpty ? Localization.translate('course_curriculum') : "Course Curriculum"}",
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: AppColors.blackColor,
              fontSize: FontSize.scale(context, 18),
              fontFamily: AppFontFamily.mediumFont,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
          Column(
            children: List.generate(courseSections.length, (index) {
              return _buildCourseSection(courseSections[index]);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSection(Map<String, dynamic> section) {
    return StatefulBuilder(
      builder: (context, setState) {
        final String titleText = section["title"] ?? '';
        String formatDuration(String duration) {
          return duration
              .replaceAll('minutes', 'min')
              .replaceAll('mins', 'min')
              .replaceAll('minute', 'min')
              .replaceAll('sec', 'sec')
              .replaceAll('seconds', 'sec')
              .replaceAll('second', 'sec')
              .replaceAll('hours', 'hr')
              .replaceAll('hour', 'hr');
        }

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isMultiLine = titleText.length > 30;

              return StatefulBuilder(
                builder: (context, setState) {
                  bool isExpanded = section["expanded"] ?? false;
                  return ExpansionTile(
                    initiallyExpanded: section["expanded"],
                    tilePadding: EdgeInsets.symmetric(horizontal: 2),
                    leading: Icon(
                      section["expanded"]
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.chevron_right,
                      size: 20,
                      color: AppColors.greyColor(context),
                    ),
                    title:   HtmlWidget(
                     titleText ?? '',
                      textStyle:TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 14),
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Transform.translate(
                      offset: isMultiLine ? Offset(0, -10) : Offset(0, 0),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "${section["lectures"]}",
                              style: TextStyle(
                                color: AppColors.greyColor(context),
                                fontSize: FontSize.scale(context, 12),
                                fontFamily: AppFontFamily.mediumFont,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(text: " "),
                            TextSpan(
                              text:
                                  "${(Localization.translate('lectures_title') ?? '').trim() != 'lectures_title' && (Localization.translate('lectures_title') ?? '').trim().isNotEmpty ? Localization.translate('lectures_title') : "Lectures"}",
                              style: TextStyle(
                                color: AppColors.greyColor(context),
                                fontSize: FontSize.scale(context, 12),
                                fontFamily: AppFontFamily.mediumFont,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(text: " "),
                            TextSpan(
                              text:
                                  "${formatDuration(section['duration'] ?? '')}",
                              style: TextStyle(
                                color: AppColors.greyColor(
                                  context,
                                ).withOpacity(0.7),
                                fontSize: FontSize.scale(context, 12),
                                fontFamily: AppFontFamily.regularFont,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    onExpansionChanged: (expanded) {
                      setState(() {
                        section["expanded"] = expanded;
                      });
                    },
                    childrenPadding: EdgeInsets.only(
                      left: 35,
                      right: 10,
                      bottom: 8,
                    ),
                    children: [
                      if (section["description"].isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8, left: 5),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child:
                            HtmlWidget(
                                section["description"] ?? '',                              textStyle: TextStyle(
                                color: AppColors.greyColor(context),
                                fontSize: FontSize.scale(context, 14),
                                fontFamily: AppFontFamily.regularFont,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      if ((section["lessons"] as List).isNotEmpty)
                        Column(
                          children:
                              (section["lessons"] as List).map((lesson) {
                                return _buildLessonTile(lesson);
                              }).toList(),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLessonTile(Map<String, dynamic> lesson) {
    String formatDuration(String duration) {
      return duration
          .replaceAll('minutes', 'min')
          .replaceAll('mins', 'min')
          .replaceAll('minute', 'min')
          .replaceAll('sec', 'sec')
          .replaceAll('seconds', 'sec')
          .replaceAll('second', 'sec')
          .replaceAll('hours', 'hr')
          .replaceAll('hour', 'hr');
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.fadeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                (Localization.textDirection == TextDirection.rtl
                    ? AppImages.playIconRTL
                    : AppImages.playIcon),
                height: 15.0,
                color: AppColors.greyColor(context).withOpacity(0.7),
              ),
              SizedBox(width: 8),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        lesson["title"] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 12),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),

                    if (lesson["preview"] == false)
                      SvgPicture.asset(
                        AppImages.lockCourseIcon,
                        width: 15,
                        height: 15,
                        color: AppColors.greyColor(context),
                      ),
                  ],
                ),
              ),

              SizedBox(width: 8),
              Text(
                "${formatDuration(lesson['duration'] ?? '')}",
                style: TextStyle(
                  color: AppColors.greyColor(context).withOpacity(0.7),
                  fontSize: FontSize.scale(context, 12),
                  fontFamily: AppFontFamily.regularFont,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          if (lesson["description"].isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 7, right: 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      lesson["description"] ?? '',
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 12),
                        fontFamily: AppFontFamily.regularFont,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  if (lesson["preview"] == true)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => FullScreenVideoPlayer(
                                  videoUrl: lesson["media_path"],
                                ),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${(Localization.translate('preview') ?? '').trim() != 'preview' && (Localization.translate('preview') ?? '').trim().isNotEmpty ? Localization.translate('preview') : "Preview"}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.greyColor(
                              context,
                            ).withOpacity(0.8),
                            fontSize: FontSize.scale(context, 12),
                            fontFamily: AppFontFamily.mediumFont,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget buildFaq(Map<String, dynamic>? courseDetails) {
    final List<Map<String, dynamic>> faqs =
        (courseDetails?['data']['faqs'] as List?)?.map((faq) {
          return {
            "question": faq["question"],
            "answer": faq["answer"] ?? "",
            "expanded": false,
          };
        }).toList() ??
        [];

    if (courseDetails == null) {
      return AboutCourseSkeleton();
    }

    if (faqs.isEmpty) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              "${(Localization.translate('empty_faq') ?? '').trim() != 'empty_faq' && (Localization.translate('empty_faq') ?? '').trim().isNotEmpty ? Localization.translate('empty_faq') : "FAQs not available"}",
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
          Text(
            "${(Localization.translate('faq_title') ?? '').trim() != 'faq_title' && (Localization.translate('faq_title') ?? '').trim().isNotEmpty ? Localization.translate('faq_title') : "Frequently Asked Questions"}",
            style: TextStyle(
              color: AppColors.blackColor,
              fontSize: FontSize.scale(context, 18),
              fontFamily: AppFontFamily.mediumFont,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
          Column(
            children:
                faqs.map((faq) {
                  return _buildFaqTile(faq);
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(Map<String, dynamic> faq) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: StatefulBuilder(
        builder: (context, setState) {
          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              initiallyExpanded: faq["expanded"],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: AppColors.fadeColor,
              collapsedBackgroundColor: AppColors.fadeColor,
              title: Text(
                faq["question"] ?? '',
                style: TextStyle(
                  color: AppColors.greyColor(context),
                  fontSize: FontSize.scale(context, 14),
                  fontFamily:
                      faq["expanded"]
                          ? AppFontFamily.mediumFont
                          : AppFontFamily.regularFont,
                  fontWeight:
                      faq["expanded"] ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: Icon(
                faq["expanded"]
                    ? Icons.keyboard_arrow_down
                    : Icons.chevron_right,
                color: AppColors.greyColor(context),
              ),
              onExpansionChanged: (expanded) {
                setState(() {
                  faq["expanded"] = expanded;
                });
              },
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: Text(
                    faq["answer"] ?? '',
                    style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 15),
                      fontFamily: AppFontFamily.regularFont,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrerequisites(Map<String, dynamic>? courseDetails) {
    final prerequisitesHtml = courseDetails?['data']['prerequisites'] ?? '';

    if (courseDetails == null) {
      return AboutCourseSkeleton();
    }

    if (prerequisitesHtml.isEmpty) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              "${(Localization.translate('empty_prerequisite') ?? '').trim() != 'empty_prerequisite' && (Localization.translate('empty_prerequisite') ?? '').trim().isNotEmpty ? Localization.translate('empty_prerequisite') : "Prerequisites not available"}",
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

    List<String> listItems = _parseHtmlToList(prerequisitesHtml);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.whiteColor),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${(Localization.translate('prerequisite_title') ?? '').trim() != 'prerequisite_title' && (Localization.translate('prerequisite_title') ?? '').trim().isNotEmpty ? Localization.translate('prerequisite_title') : "Prerequisites"}",
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: AppColors.blackColor,
              fontSize: FontSize.scale(context, 18),
              fontFamily: AppFontFamily.mediumFont,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
          if (listItems.isNotEmpty)
            Column(
              children:
                  listItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: SvgPicture.asset(
                              AppImages.checkCircle,
                              height: 15.0,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                color: AppColors.greyColor(context),
                                fontSize: FontSize.scale(context, 14),
                                fontFamily: AppFontFamily.regularFont,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            )
          else
            HtmlWidget(
              prerequisitesHtml,
              textStyle: TextStyle(
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

  List<String> _parseHtmlToList(String html) {
    final regex = RegExp(r'<li>(.*?)<\/li>', multiLine: true);
    final matches = regex.allMatches(html);

    List<String> listItems = [];
    for (var match in matches) {
      listItems.add(match.group(1) ?? '');
    }
    return listItems;
  }

  Widget _buildReviewsSection(Map<String, dynamic>? courseDetails) {
    if (courseDetails == null) {
      return StudentReviewsSectionSkeleton();
    }

    final ratings = courseDetails?['data']['ratings'] as List? ?? [];

    if (ratings.isEmpty) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              "${(Localization.translate('empty_course_reviews') ?? '').trim() != 'empty_course_reviews' && (Localization.translate('empty_course_reviews') ?? '').trim().isNotEmpty ? Localization.translate('empty_course_reviews') : "Reviews not available"}",
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
                "${(Localization.translate('course_reviews') ?? '').trim() != 'course_reviews' && (Localization.translate('course_reviews') ?? '').trim().isNotEmpty ? Localization.translate('course_reviews') : "Reviews"}",
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => DetailReviewScreen(ratings: ratings),
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
              children: List.generate(ratings.length, (index) {
                final review = ratings[index];
                final user = review['user'] ?? {};
                final reviewDate = review['created_at'] ?? '';
                final country = user ?? '';

                final countryShortCode = country['short_code'] ?? '';

                final countryFlagUrl =
                    '${AppUrls.flagUrl}${countryShortCode.toLowerCase()}.png';

                return ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 150),
                  child: StudentCard(
                    name: user['name'] ?? '',
                    date: reviewDate,
                    description: review['comment'] ?? '',
                    rating: review['rating'].toDouble(),
                    image: user['image'] ?? '',
                    countryFlag:
                        countryFlagUrl != null && countryFlagUrl != null
                            ? countryFlagUrl
                            : '',
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      height: screenHeight * 0.085,
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
        onPressed:
            (paymentEnabled == "yes")
                ? (onPresLoading || isEnrolled)
                    ? null
                    : () => _addCourseToCart(context)
                : (isFreeEnrolled || isEnrolled)
                ? null
                : () async {
                  await _addEnrollFreeCourseToCart(context);
                },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.disabled) ||
                (paymentEnabled == "yes" ? onPresLoading : isFreeEnrolled) ||
                isEnrolled) {
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
              (paymentEnabled == "yes")
                  ? "${(Localization.translate('add_cart') ?? '').trim() != 'add_cart' && (Localization.translate('add_cart') ?? '').trim().isNotEmpty ? Localization.translate('add_cart') : "Add to Cart"}"
                  : "${(Localization.translate('get_course') ?? '').trim() != 'get_course' && (Localization.translate('get_course') ?? '').trim().isNotEmpty ? Localization.translate('get_course') : "Get Course"}",

              style: TextStyle(
                color:
                    isEnrolled
                        ? AppColors.greyColor(context).withOpacity(0.5)
                        : AppColors.whiteColor,
                fontSize: FontSize.scale(context, 16),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 8.0),
            SvgPicture.asset(
              AppImages.cartIcon,
              height: 20,
              color:
                  isEnrolled
                      ? AppColors.greyColor(context).withOpacity(0.5)
                      : AppColors.whiteColor,
            ),
            if (paymentEnabled == "yes" ? onPresLoading : isFreeEnrolled) ...[
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
    );
  }
}
