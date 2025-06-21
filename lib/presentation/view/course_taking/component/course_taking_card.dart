import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../../base_components/custom_toast.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import '../../../../data/localization/localization.dart';
import '../../../../data/provider/auth_provider.dart';
import '../../../../domain/api_structure/api_service.dart';
import '../../auth/login_screen.dart';
import '../../components/login_required_alert.dart';

class CourseTakingCard extends StatefulWidget {
  final String title;
  final String instructor;
  final String instructorImage;
  final String category;
  final String videoUrl;
  final String imageUrl;
  final bool isFavorite;
  final bool filledStar;
  final int courseId;
  final Future<void> Function(bool isFavorite) onFavouriteToggle;
  final ValueNotifier<bool> isFavoriteNotifier;
  final double progress;
  final VoidCallback onPressed;

  CourseTakingCard({
    required this.courseId,
    required this.title,
    required this.instructor,
    required this.instructorImage,
    required this.category,
    required this.videoUrl,
    required this.imageUrl,
    required this.isFavorite,
    this.filledStar = false,
    required this.onFavouriteToggle,
    required this.progress,
    required this.onPressed,
  }) : isFavoriteNotifier = ValueNotifier(isFavorite);

  @override
  _CourseTakingCardState createState() => _CourseTakingCardState();
}

class _CourseTakingCardState extends State<CourseTakingCard> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Timer? _autoHideTimer;

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
    Future.delayed(const Duration(seconds: 1), () {
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
    final isFavorite = authProvider.isCourseFavorite(widget.courseId);
    final userData = authProvider.userData;
    final String? role =
        userData != null && userData['user'] != null
            ? userData['user']['role']
            : null;

    Widget _buildTagChip(String tag) {
      return Text(
        tag,
        style: TextStyle(
          color: AppColors.greyColor(context),
          fontSize: FontSize.scale(context, 14),
          decoration: TextDecoration.underline,
          decorationColor: AppColors.greyColor(context),
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
          fontFamily: AppFontFamily.regularFont,
          height: 2.0,
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
                                      ? Image.asset(AppImages.placeHolderImage, fit: BoxFit.cover)
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
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                      if (role == 'student')
                        GestureDetector(
                          onTap:
                              isLoadingFavorite
                                  ? null
                                  : () {
                                    toggleFavorite(context);
                                  },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.dividerColor,
                              borderRadius: BorderRadius.circular(25.0),
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
                    ],
                  ),
                  SizedBox(height: 5),
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
                  if (widget.category != null &&
                      widget.category.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          '${(Localization.translate('category_in_text') ?? '').trim() != 'category_in_text' && (Localization.translate('category_in_text') ?? '').trim().isNotEmpty ? Localization.translate('category_in_text') : 'in'}',
                          style: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 12),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontFamily: AppFontFamily.regularFont,
                          ),
                        ),
                        SizedBox(width: 5),

                        Text(
                          widget.category,
                          style: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 14),
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.greyColor(context),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontFamily: AppFontFamily.regularFont,
                            height: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(Localization.translate('course_progress') ?? '').trim() != 'course_progress' && (Localization.translate('course_progress') ?? '').trim().isNotEmpty ? Localization.translate('course_progress') : 'Course Progress'}',
                        style: TextStyle(
                          color: AppColors.greyColor(context).withOpacity(0.7),
                          fontSize: FontSize.scale(context, 12),
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFontFamily.regularFont,
                        ),
                      ),
                      Text(
                        '${(widget.progress * 100).toInt()}${(Localization.translate('percent_symbol') ?? '').trim() != 'percent_symbol' && (Localization.translate('percent_symbol') ?? '').trim().isNotEmpty ? Localization.translate('percent_symbol') : '%'}',
                        style: TextStyle(
                          color: AppColors.greyColor(context).withOpacity(0.8),
                          fontSize: FontSize.scale(context, 12),
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFontFamily.mediumFont,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: widget.progress,
                      backgroundColor: AppColors.dividerColor,
                      color: AppColors.indicatorColor,
                      minHeight: 8,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: widget.onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen(context),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '${(Localization.translate('resume_course') ?? '').trim() != 'resume_course' && (Localization.translate('resume_course') ?? '').trim().isNotEmpty ? Localization.translate('resume_course') : 'Resume Course'}',
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: FontSize.scale(context, 16),
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
