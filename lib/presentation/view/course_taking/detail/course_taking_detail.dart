import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import '../../../../data/localization/localization.dart';
import '../../../../data/provider/auth_provider.dart';
import '../../../../data/provider/connectivity_provider.dart';
import '../../../../domain/api_structure/api_service.dart';
import '../../../../styles/app_styles.dart';
import 'package:chewie/chewie.dart';
import '../../auth/login_screen.dart';
import '../../community/component/utils/date_utils.dart';
import '../../components/internet_alert.dart';
import '../../components/login_required_alert.dart';
import '../../courses/skeleton/course_detail_skeleton.dart';
import '../../detailPage/component/skeleton/detail_page_skeleton.dart';
import '../component/video_display.dart';

class CourseTakingDetailScreen extends StatefulWidget {
  final String slug;

  CourseTakingDetailScreen({required this.slug});
  @override
  _CourseTakingDetailScreenState createState() =>
      _CourseTakingDetailScreenState();
}

class _CourseTakingDetailScreenState extends State<CourseTakingDetailScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> noticeBoard = [];

  late double screenHeight;
  late double screenWidth;

  late TabController _tabController;
  ChewieController? _chewieController;
  late VideoPlayerController _videoController;
  bool _isLoading = true;

  Map<String, dynamic>? courseDetails;
  Map<String, dynamic>? courseTakingDetails;
  String? videoUrl;
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    fetchCourseDetails();
    fetchCourseTakingDetails();
    _tabController = TabController(length: 4, vsync: this);
  }

  Future<void> fetchCourseTakingDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getCourseTakingDetails(token, widget.slug);

      if (response['status'] == 200) {
        setState(() {
          courseTakingDetails = response;
          _isLoading = false;
          progress =
              ((response['data']['progress'] as num?)?.toDouble() ?? 0) / 100;

          if (response['data'] != null &&
              response['data']['noticeboards'] != null) {
            noticeBoard = List<Map<String, dynamic>>.from(
              response['data']['noticeboards'].map((item) {
                String date = item["created_at"] ?? "";
                String formattedDate = "";

                if (date.isNotEmpty) {
                  formattedDate = formatDateWithMinMonth(date);
                }

                return {"date": formattedDate, "notice": item["content"] ?? ""};
              }),
            );
          } else {
            noticeBoard = [];
          }
        });
      } else if (response['status'] == 401) {
        setState(() {
          _isLoading = false;
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
        showCustomToast(context, response['message'] ?? "Error", false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchCourseDetails() async {
    try {
      _initializeChewie(videoUrl ?? "");

      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final fetchedDetails = await getCourseDetails(token, widget.slug);

      if (fetchedDetails['status'] == 200) {
        setState(() {
          courseDetails = fetchedDetails;
          videoUrl = fetchedDetails['data']['promotional_video']?['url'] ?? '';
          _isLoading = false;
        });

        if (videoUrl != null && videoUrl!.isNotEmpty) {
          _initializeChewie(videoUrl!);
        }
      } else if (fetchedDetails['status'] == 401) {
        setState(() {
          _isLoading = false;
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
        _isLoading = false;
      });
    }
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
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    _tabController..dispose();
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
            if (_isLoading) {
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
                      title: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 15.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(Localization.translate('course_progress') ?? '').trim() != 'course_progress' && (Localization.translate('course_progress') ?? '').trim().isNotEmpty ? Localization.translate('course_progress') : 'Course Progress'}',
                                  style: TextStyle(
                                    color: AppColors.blackColor,
                                    fontSize: FontSize.scale(context, 12),
                                    fontWeight: FontWeight.w400,
                                    fontFamily: AppFontFamily.regularFont,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    left:
                                        Localization.textDirection ==
                                                TextDirection.rtl
                                            ? 15.0
                                            : 0.0,
                                  ),
                                  child: Text(
                                    '${(progress * 100).toInt()}${(Localization.translate('percent_symbol') ?? '').trim() != 'percent_symbol' && (Localization.translate('percent_symbol') ?? '').trim().isNotEmpty ? Localization.translate('percent_symbol') : '%'}',
                                    style: TextStyle(
                                      color: AppColors.greyColor(
                                        context,
                                      ).withOpacity(0.8),
                                      fontSize: FontSize.scale(context, 12),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFontFamily.mediumFont,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.only(
                              right: 15.0,
                              left:
                                  Localization.textDirection ==
                                          TextDirection.rtl
                                      ? 15.0
                                      : 0.0,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: AppColors.dividerColor,
                                color: AppColors.indicatorColor,
                                minHeight: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      leading: IconButton(
                        splashColor: Colors.transparent,
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.greyColor(context),
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.pop(context, progress);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVideoSection(),
                        SizedBox(height: 20),
                        _isLoading
                            ? Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                ),
                              ),
                            )
                            : Container(
                              width: double.infinity,
                              color: AppColors.whiteColor,
                              child: TabBar(
                                isScrollable: true,
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                tabAlignment: TabAlignment.start,
                                indicatorPadding: EdgeInsets.zero,
                                dividerColor: Colors.transparent,
                                indicatorSize: TabBarIndicatorSize.tab,
                                controller: _tabController,
                                indicator: UnderlineTabIndicator(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(20.0),
                                    topLeft: Radius.circular(20.0),
                                  ),
                                  borderSide: BorderSide(
                                    width: 5.0,
                                    color: AppColors.primaryGreen(context),
                                  ),
                                ),
                                indicatorWeight: 4.0,
                                labelColor: AppColors.blackColor,
                                unselectedLabelColor: AppColors.greyColor(
                                  context,
                                ),
                                labelStyle: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 16),
                                  fontFamily: AppFontFamily.mediumFont,
                                  fontWeight: FontWeight.w500,
                                ),
                                unselectedLabelStyle: TextStyle(
                                  color: AppColors.greyColor(
                                    context,
                                  ).withOpacity(0.9),
                                  fontSize: FontSize.scale(context, 16),
                                  fontFamily: AppFontFamily.regularFont,
                                  fontWeight: FontWeight.w400,
                                ),
                                tabs: [
                                  Tab(
                                    text:
                                        '${(Localization.translate('overview') ?? '').trim() != 'overview' && (Localization.translate('overview') ?? '').trim().isNotEmpty ? Localization.translate('overview') : 'Overview'}',
                                  ),
                                  Tab(
                                    text:
                                        '${(Localization.translate('content') ?? '').trim() != 'content' && (Localization.translate('content') ?? '').trim().isNotEmpty ? Localization.translate('content') : 'Content'}',
                                  ),
                                  Tab(
                                    text:
                                        '${(Localization.translate('preReq_faq') ?? '').trim() != 'preReq_faq' && (Localization.translate('preReq_faq') ?? '').trim().isNotEmpty ? Localization.translate('preReq_faq') : 'Prerequisites & FAQs'}',
                                  ),
                                  Tab(
                                    text:
                                        '${(Localization.translate('notice_board') ?? '').trim() != 'notice_board' && (Localization.translate('notice_board') ?? '').trim().isNotEmpty ? Localization.translate('notice_board') : 'Noticeboard'}',
                                  ),
                                ],
                              ),
                            ),
                        SizedBox(height: 10),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildOverviewTab(),
                              _buildContentTab(),
                              _buildPrerequisitesAndFAQsTab(),
                              _buildNotice(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
          _isLoading
              ? VideoSectionSkeleton()
              : Chewie(controller: _chewieController!),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileSection(courseDetails),
          SizedBox(height: 10),
          _buildAboutCourse(courseDetails),
          SizedBox(height: 10),
          _buildLearn(courseDetails),
          SizedBox(height: 20.0),
        ],
      ),
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              AppImages.checkCircle,
                              height: 15.0,
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

  Widget _buildCourseCurriculum(Map<String, dynamic>? courseTakingDetails) {
    final List<Map<String, dynamic>> courseSections =
        (courseTakingDetails?['data']['sections'] as List?)?.map((course) {
          return {
            "id": courseTakingDetails?['data']["id"],
            "title": course["title"],
            "lectures": course["curriculums_count"] ?? 0,
            "duration": course["content_length"] ?? "",
            "expanded": false,
            "description": course["description"] ?? "",
            "lessons":
                (course["curriculums"] as List?)?.map((curriculum) {
                  return {
                    "id": curriculum["id"],
                    "title": curriculum["title"],
                    "duration": curriculum["content_length"] ?? "",
                    "preview": curriculum["is_preview"] ?? false,
                    "description": curriculum["description"] ?? "",
                    "media_path": curriculum["media_path"] ?? "",
                    "is_watched": curriculum["is_watched"] ?? "",
                  };
                }).toList() ??
                [],
          };
        }).toList() ??
        [];

    if (courseTakingDetails == null) {
      return AboutCourseSkeleton();
    }

    if (courseTakingDetails.isEmpty) {
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

  Widget _buildCourseSection(Map<String, dynamic> course) {
    return StatefulBuilder(
      builder: (context, setState) {
        final String titleText = course["title"] ?? '';
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
                  bool isExpanded = course["expanded"] ?? false;

                  return ExpansionTile(
                    initiallyExpanded: course["expanded"],
                    tilePadding: EdgeInsets.symmetric(horizontal: 2),
                    leading: Icon(
                      course["expanded"]
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.chevron_right,
                      size: 20,
                      color: AppColors.greyColor(context),
                    ),
                    title: Text(
                      titleText,
                      style: TextStyle(
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
                              text: "${course["lectures"]}",
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
                                  "${formatDuration(course['duration'] ?? '')}",
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
                        isExpanded = expanded;
                        course["expanded"] = expanded;
                      });
                    },
                    childrenPadding: EdgeInsets.only(
                      left: 35,
                      right: 10,
                      bottom: 8,
                    ),
                    children: [
                      if (course["description"].isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8, left: 5),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child:
                            HtmlWidget(
                                course["description"] ?? '',
                              textStyle: TextStyle(
                                color: AppColors.greyColor(context),
                                fontSize: FontSize.scale(context, 15),
                                fontFamily: AppFontFamily.regularFont,
                                fontWeight: FontWeight.w400,
                              ),
                            )
                          ),
                        ),
                      if ((course["lessons"] as List).isNotEmpty)
                        Column(
                          children: List.generate(course["lessons"].length, (
                            index,
                          ) {
                            return _buildLessonTile(
                              course["lessons"][index],
                              course["id"].toString(),
                              course["lessons"],
                              index,
                            );
                          }),
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

  Widget _buildLessonTile(
    Map<String, dynamic> curriculums,
    String courseId,
    List<Map<String, dynamic>> course,
    int currentLessonIndex,
  ) {
    Future<void> _handleUpdateProgress(
      String courseId,
      String curriculumId,
      List<Map<String, dynamic>> course,
      int currentLessonIndex,
    ) async {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;

        Map<String, dynamic> response = await updateProgress(
          token!,
          {},
          courseId,
          curriculumId,
        );

        if (response['status'] == 200) {
          showCustomToast(context, '${response['message']}', true);

          await fetchCourseTakingDetails();
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
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                showCancelButton: false,
              );
            },
          );
        } else {
          String errorMessage = response['message'] ?? "";
          showCustomToast(context, errorMessage, false);
        }
      } catch (e) {}
    }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: Offset(0.0, 2.0),
                child: SvgPicture.asset(
                  (curriculums["is_watched"] == true)
                      ? (Localization.textDirection == TextDirection.rtl
                          ? AppImages.playIconFilledRTL
                          : AppImages.playIconFilled)
                      : (Localization.textDirection == TextDirection.rtl
                          ? AppImages.playIconRTL
                          : AppImages.playIcon),
                  height: 15.0,
                  color:
                      curriculums["is_watched"] == true
                          ? AppColors.blackColor
                          : AppColors.greyColor(context).withOpacity(0.7),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  curriculums["title"] ?? '',
                  style: TextStyle(
                    color: AppColors.greyColor(context),
                    fontSize: FontSize.scale(context, 12),
                    fontFamily: AppFontFamily.mediumFont,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                "${formatDuration(curriculums['duration'] ?? '')}",
                style: TextStyle(
                  color: AppColors.greyColor(context).withOpacity(0.7),
                  fontSize: FontSize.scale(context, 12),
                  fontFamily: AppFontFamily.regularFont,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          if (curriculums["description"].isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 7, right: 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      curriculums["description"] ?? '',
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 12),
                        fontFamily: AppFontFamily.regularFont,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(width: 3),
                  if (curriculums["preview"] != null)
                    GestureDetector(
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => VideoDisplay(
                                  videoUrl: curriculums["media_path"],
                                  lessons: course,
                                  currentLessonIndex: currentLessonIndex,
                                  courseId: courseId,
                                  curriculumId: curriculums["id"].toString(),
                                  onUpdateProgress: _handleUpdateProgress,
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

  Widget _buildContentTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCourseCurriculum(courseTakingDetails),
          SizedBox(height: 20.0),
        ],
      ),
    );
  }

  Widget _buildPrerequisitesAndFAQsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPrerequisites(courseDetails),
          SizedBox(height: 10),
          buildFaq(courseDetails),
          SizedBox(height: 20.0),
        ],
      ),
    );
  }

  Widget _buildNotice() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildNoticeBoard(), SizedBox(height: 20.0)],
      ),
    );
  }

  Widget _buildNoticeBoard() {
    if (noticeBoard == null) {
      return AboutCourseSkeleton();
    }

    if (noticeBoard.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "${(Localization.translate('empty_noticeboard') ?? '').trim() != 'empty_noticeboard' && (Localization.translate('empty_noticeboard') ?? '').trim().isNotEmpty ? Localization.translate('empty_noticeboard') : "Noticeboard is empty"}",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.blackColor,
            fontSize: FontSize.scale(context, 16),
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.normal,
            fontFamily: AppFontFamily.mediumFont,
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: AppColors.whiteColor),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${(Localization.translate('notice_board') ?? '').trim() != 'notice_board' && (Localization.translate('notice_board') ?? '').trim().isNotEmpty ? Localization.translate('notice_board') : "Noticeboard"}",
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 16),
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.normal,
                fontFamily: AppFontFamily.mediumFont,
              ),
            ),
            SizedBox(height: 10),
            Column(
              children:
                  noticeBoard.map((noticeDetails) {
                    return _buildNoticeList(noticeDetails);
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeList(Map<String, dynamic> noticeDetails) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.0),
      margin: EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dividerColor, width: 1.0),
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          Text(
            noticeDetails["date"],
            style: TextStyle(
              color: AppColors.greyColor(context).withOpacity(0.7),
              fontSize: FontSize.scale(context, 14),
              fontFamily: AppFontFamily.regularFont,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 5),
          HtmlWidget(
            noticeDetails["notice"]??'',
            textStyle: TextStyle(
              color: AppColors.greyColor(context),
              fontSize: FontSize.scale(context, 15),
              fontFamily: AppFontFamily.regularFont,
              fontWeight: FontWeight.w400,
            ),
          )
        ],
      ),
    );
  }
}
