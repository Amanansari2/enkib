import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../data/provider/connectivity_provider.dart';
import '../../../../data/provider/settings_provider.dart';
import '../../auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../components/internet_alert.dart';
import '../../components/login_required_alert.dart';
import '../../../../base_components/custom_toast.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import '../../../../data/localization/localization.dart';
import '../../../../data/provider/auth_provider.dart';
import 'package:flutter_projects/domain/api_structure/api_service.dart';

class CourseCard extends StatefulWidget {
  final String title;
  final String instructor;
  final String instructorImage;
  final String level;
  final String language;
  final List<String> category;
  final String price;
  final double rating;
  final String reviews;
  final int lessons;
  final String duration;
  final String discount;
  final String videoUrl;
  final String imageUrl;
  final bool isFavorite;
  final bool filledStar;
  final int courseId;
  final Future<void> Function(bool isFavorite) onFavouriteToggle;
  final ValueNotifier<bool> isFavoriteNotifier;

  CourseCard({
    required this.courseId,
    required this.title,
    required this.instructor,
    required this.instructorImage,
    required this.category,
    required this.level,
    required this.language,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.lessons,
    required this.duration,
    required this.discount,
    required this.videoUrl,
    required this.imageUrl,
    required this.isFavorite,
    this.filledStar = false,
    required this.onFavouriteToggle,
  }) : isFavoriteNotifier = ValueNotifier(isFavorite);

  @override
  _CourseCardState createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Timer? _autoHideTimer;
  String paymentEnabled = "no";

  bool isLoadingFavorite = false;

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
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Future<void> toggleFavorite(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;

    setState(() {
      isLoadingFavorite = true;
    });

    try {
      final token = authProvider.token;
      if (token != null) {
        final response = await addDeleteFavouriteCourse(
          token,
          widget.courseId,
          authProvider,
        );

        if (response['status'] == 200) {
          showCustomToast(context, '${response['message']}', true);
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
          showCustomToast(context, response['message'], false);
        }
      } else if ((token == null || userData == null)) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: Localization.translate("login_required"),
              content: Localization.translate("login_access"),
              buttonText: Localization.translate("goToLogin"),
              buttonAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            );
          },
        );
        return;
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

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideControlsTimer?.cancel();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _toggleVideo() {
    setState(() {
      if (_isPlaying) {
        _controller.pause();
        _showControls = true;
      } else {
        _controller.play();
        _startAutoHideControls();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_isPlaying && _showControls) {
        _startAutoHideControls();
      }
    });
    _resetAutoHideTimer();
  }

  void _startAutoHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(Duration(seconds: 3), () {
      if (_isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _resetAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(Duration(seconds: 3), () {
      if (!_isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    final isFavorite = authProvider.isCourseFavorite(widget.courseId);
    final userData = authProvider.userData;
    final String? role =
        userData != null && userData['user'] != null
            ? userData['user']['role']
            : null;

    paymentEnabled =
        settingsProvider.getSetting('data')?['_lernen']?['payment_enabled'];

    Widget _buildTagChip(String tag) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: EdgeInsets.only(right: 8, bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.greyColor(context).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: AppColors.greyColor(context),
            fontSize: FontSize.scale(context, 12),
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
            fontFamily: AppFontFamily.regularFont,
          ),
        ),
      );
    }

    return Directionality(
      textDirection: Localization.textDirection,
      child: Container(
        margin: EdgeInsets.only(
          left: 10.0,
          right: 10.0,
          top: 2.0,
          bottom: 10.0,
        ),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.greyColor(context).withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GestureDetector(
                    onTap: _toggleControls,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.0,
                            vertical: 5.0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child:
                                  _isPlaying
                                      ? VideoPlayer(_controller)
                                      : widget.imageUrl.isEmpty
                                      ? Image.asset(
                                        AppImages.placeHolderImage,
                                        fit: BoxFit.cover,
                                      )
                                      : Image.network(
                                        widget.imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                            ),
                          ),
                        ),
                        if (_showControls || !_isPlaying)
                          Positioned(
                            child: GestureDetector(
                              onTap: _toggleVideo,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.whiteColor.withOpacity(0.21),
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.all(15),
                                child: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 35,
                                  color: AppColors.whiteColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 10,
                  right: 10,
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      Row(
                        children: [
                          if (_showControls || !_isPlaying)
                            IconButton(
                              icon: Icon(
                                _isMuted ? Icons.volume_off : Icons.volume_up,
                                color: AppColors.whiteColor,
                              ),
                              onPressed: _toggleMute,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (role == 'student')
                  Positioned(
                    top: 15,
                    right: 20,
                    child: GestureDetector(
                      onTap:
                          isLoadingFavorite
                              ? null
                              : () {
                                toggleFavorite(context);
                              },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child:
                            isLoadingFavorite
                                ? SizedBox(
                                  width: 25,
                                  height: 25,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryGreen(context),
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
                                          ).withOpacity(0.7),
                                  size: 25,
                                ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.instructorImage != null &&
                          widget.instructorImage.isNotEmpty)
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(widget.instructorImage),
                        ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.instructor != null &&
                                  widget.instructor.toString().isNotEmpty
                              ? widget.instructor
                              : '',
                          style: TextStyle(
                            color: AppColors.blackColor,
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontFamily: AppFontFamily.regularFont,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double maxWidth = constraints.maxWidth;
                      double currentWidth = 0;
                      List<Widget> rowChildren = [];
                      List<Widget> wrappedChildren = [];

                      for (String tag in widget.category) {
                        TextPainter textPainter = TextPainter(
                          text: TextSpan(
                            text: tag,
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 12),
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                              fontFamily: AppFontFamily.regularFont,
                            ),
                          ),
                          maxLines: 1,
                          textDirection: TextDirection.ltr,
                        )..layout();

                        double tagWidth = textPainter.width + 20;

                        if (currentWidth + tagWidth < maxWidth) {
                          rowChildren.add(_buildTagChip(tag));
                          currentWidth += tagWidth;
                        } else {
                          wrappedChildren.add(_buildTagChip(tag));
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (rowChildren.isNotEmpty)
                            Row(children: rowChildren),
                          if (wrappedChildren.isNotEmpty)
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 6.0,
                              children: wrappedChildren,
                            ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.title != null && widget.title.toString().isNotEmpty
                        ? widget.title
                        : '',
                    style: TextStyle(
                      color: AppColors.blackColor,
                      fontSize: FontSize.scale(context, 16),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.normal,
                      fontFamily: AppFontFamily.mediumFont,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      widget.level != null && widget.level.toString().isNotEmpty
                          ? Row(
                            children: [
                              SvgPicture.asset(
                                AppImages.levelIcon,
                                width: 18,
                                height: 18,
                              ),
                              SizedBox(width: 6),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "${widget.level}",
                                      style: TextStyle(
                                        color: AppColors.greyColor(context),
                                        fontSize: FontSize.scale(context, 14),
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.normal,
                                        fontFamily: AppFontFamily.mediumFont,
                                      ),
                                    ),
                                    TextSpan(
                                      text: " ",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          "${(Localization.translate('level') ?? '').trim() != 'level' && (Localization.translate('level') ?? '').trim().isNotEmpty ? Localization.translate('level') : 'Level'}",
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
                          )
                          : SizedBox.shrink(),
                      widget.rating != null &&
                              widget.rating.toString().isNotEmpty
                          ? Row(
                            children: [
                              SvgPicture.asset(
                                widget.filledStar
                                    ? AppImages.filledStar
                                    : AppImages.star,
                                width: 16,
                                height: 16,
                              ),
                              SizedBox(width: 6),
                              Text.rich(
                                TextSpan(
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: '${widget.rating}',
                                      style: TextStyle(
                                        color: AppColors.greyColor(context),
                                        fontSize: FontSize.scale(context, 14),
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.normal,
                                        fontFamily: AppFontFamily.mediumFont,
                                      ),
                                    ),
                                    TextSpan(text: ' '),
                                    TextSpan(
                                      text:
                                          '${(Localization.translate('total_rating') ?? '').trim() != 'total_rating' && (Localization.translate('total_rating') ?? '').trim().isNotEmpty ? Localization.translate('total_rating') : '/5.0'} (${widget.reviews} ${Localization.translate(widget.reviews == 0 || widget.reviews == 1 ? "review" : "reviews")})',
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
                          )
                          : SizedBox.shrink(),
                    ],
                  ),
                  SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      widget.language != null &&
                              widget.language.toString().isNotEmpty
                          ? Row(
                            children: [
                              SvgPicture.asset(
                                AppImages.language,
                                width: 18,
                                height: 18,
                              ),
                              SizedBox(width: 6),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "${widget.language}",
                                      style: TextStyle(
                                        color: AppColors.greyColor(context),
                                        fontSize: FontSize.scale(context, 14),
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.normal,
                                        fontFamily: AppFontFamily.mediumFont,
                                      ),
                                    ),
                                    TextSpan(
                                      text: " ",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
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
                                        fontStyle: FontStyle.normal,
                                        fontFamily: AppFontFamily.regularFont,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                          : SizedBox.shrink(),
                      widget.lessons != null &&
                              widget.lessons.toString().isNotEmpty
                          ? Row(
                            children: [
                              SvgPicture.asset(
                                AppImages.bookEducationIcon,
                                width: 18,
                                height: 18,
                              ),
                              SizedBox(width: 6),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "${widget.lessons}",
                                      style: TextStyle(
                                        color: AppColors.greyColor(context),
                                        fontSize: FontSize.scale(context, 14),
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.normal,
                                        fontFamily: AppFontFamily.mediumFont,
                                      ),
                                    ),
                                    TextSpan(
                                      text: " ",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          (widget.lessons == 0 ||
                                                  widget.lessons == 1)
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
                                        fontStyle: FontStyle.normal,
                                        fontFamily: AppFontFamily.regularFont,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                          : SizedBox.shrink(),
                    ],
                  ),
                  SizedBox(height: 16),
                  if ((widget.price.isNotEmpty && widget.price != "null") ||
                      (widget.discount.isNotEmpty &&
                          widget.discount != "0" &&
                          widget.discount != "null") ||
                      (widget.duration.isNotEmpty &&
                          widget.duration != "0" &&
                          widget.duration != "null"))
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.fadeColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          if (paymentEnabled == "yes") ...[
                            Text(
                              widget.price,
                              style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: FontSize.scale(context, 18),
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                                fontFamily: AppFontFamily.mediumFont,
                              ),
                            ),
                            SizedBox(width: 10),
                            if (widget.discount != "0" &&
                                widget.discount != "null" &&
                                widget.discount.isNotEmpty) ...[
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.disputeSessionText,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${widget.discount}${(Localization.translate('discount_text') ?? '').trim() != 'discount_text' && (Localization.translate('discount_text') ?? '').trim().isNotEmpty ? Localization.translate('discount_text') : '%OFF'}",
                                  style: TextStyle(
                                    color: AppColors.whiteColor,
                                    fontSize: FontSize.scale(context, 12),
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
                                    fontFamily: AppFontFamily.mediumFont,
                                  ),
                                ),
                              ),
                            ],
                          ],
                          if (paymentEnabled == "yes") ...[Spacer()],
                          if (widget.duration != "0" &&
                              widget.duration != "null" &&
                              widget.duration.isNotEmpty) ...[
                            SvgPicture.asset(
                              AppImages.timerIcon,
                              width: 18,
                              height: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              widget.duration,
                              style: TextStyle(
                                color: AppColors.greyColor(context),
                                fontSize: FontSize.scale(context, 16),
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontFamily: AppFontFamily.regularFont,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const FullScreenVideoPlayer({Key? key, required this.videoUrl})
    : super(key: key);

  @override
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);

    try {
      await _videoPlayerController.initialize();
      if (mounted) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            autoPlay: false,
            looping: false,
            showControls: true,
            showControlsOnInitialize: true,
            allowFullScreen: true,
            fullScreenByDefault: false,
            deviceOrientationsOnEnterFullScreen: [],
            deviceOrientationsAfterFullScreen: [],
            materialProgressColors: ChewieProgressColors(
              playedColor: AppColors.primaryGreen(context),
              handleColor: AppColors.whiteColor,
              backgroundColor: AppColors.greyColor(context),
            ),
          );

          _chewieController!.addListener(() {
            if (_chewieController!.isFullScreen) {
              _chewieController!.exitFullScreen();
              Navigator.pop(context);
            }
          });
        });
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              backgroundColor: AppColors.blackColor,
              body: Center(
                child:
                    _chewieController != null
                        ? Padding(
                          padding: const EdgeInsets.only(
                            right: 20,
                            left: 20,
                            bottom: 50,
                            top: 60,
                          ),
                          child: Chewie(controller: _chewieController!),
                        )
                        : CircularProgressIndicator(
                          color: AppColors.primaryGreen(context),
                        ),
              ),
            ),
          ),
        );
      },
    );
  }
}
