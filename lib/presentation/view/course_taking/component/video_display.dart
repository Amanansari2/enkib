import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../../data/localization/localization.dart';
import '../../../../data/provider/auth_provider.dart';
import '../../../../data/provider/connectivity_provider.dart';
import '../../../../styles/app_styles.dart';
import '../../components/internet_alert.dart';

class VideoDisplay extends StatefulWidget {
  final String videoUrl;
  final List<Map<String, dynamic>> lessons;
  final int currentLessonIndex;
  final String courseId;
  final String curriculumId;
  final Function(String, String, List<Map<String, dynamic>>, int)
  onUpdateProgress;

  const VideoDisplay({
    Key? key,
    required this.videoUrl,
    required this.lessons,
    required this.currentLessonIndex,
    required this.courseId,
    required this.curriculumId,
    required this.onUpdateProgress,
  }) : super(key: key);

  @override
  _VideoDisplayState createState() => _VideoDisplayState();
}

class _VideoDisplayState extends State<VideoDisplay> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _showNextUpOverlay = false;
  late int _currentLessonIndex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _currentLessonIndex = widget.currentLessonIndex;
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
            allowFullScreen: false,
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
            }
          });

          _videoPlayerController.addListener(() async {
            if (_videoPlayerController.value.position >=
                _videoPlayerController.value.duration) {
              await widget.onUpdateProgress(
                widget.courseId,
                widget.curriculumId,
                widget.lessons,
                widget.currentLessonIndex,
              );

              setState(() {
                _showNextUpOverlay = true;
              });
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

  void _playNextVideo() {
    int nextLessonIndex = widget.currentLessonIndex + 1;
    if (nextLessonIndex < widget.lessons.length) {
      String nextVideoUrl = widget.lessons[nextLessonIndex]["media_path"];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => VideoDisplay(
                videoUrl: nextVideoUrl,
                lessons: widget.lessons,
                currentLessonIndex: nextLessonIndex,
                courseId: widget.courseId,
                curriculumId: widget.lessons[nextLessonIndex]["id"].toString(),
                onUpdateProgress: widget.onUpdateProgress,
              ),
        ),
      );
    } else {
      showCustomToast(
        context,
        "${(Localization.translate('courses_empty') ?? '').trim() != 'courses_empty' && (Localization.translate('courses_empty') ?? '').trim().isNotEmpty ? Localization.translate('courses_empty') : "No more course available!"}",
        false,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    int nextLessonIndex = _currentLessonIndex + 1;
    bool hasNextLesson = nextLessonIndex < widget.lessons.length;

    String nextLessonTitle =
        hasNextLesson
            ? widget.lessons[nextLessonIndex]["title"]
            : "${(Localization.translate('courses_empty') ?? '').trim() != 'courses_empty' && (Localization.translate('courses_empty') ?? '').trim().isNotEmpty ? Localization.translate('courses_empty') : "No more course available!"}";

    String nextLessonDescription =
        hasNextLesson
            ? widget.lessons[nextLessonIndex]["description"] ?? ""
            : "${(Localization.translate('courses_completed') ?? '').trim() != 'courses_completed' && (Localization.translate('courses_completed') ?? '').trim().isNotEmpty ? Localization.translate('courses_completed') : "All courses completed"}";

    if (nextLessonDescription.length > 100) {
      nextLessonDescription = nextLessonDescription.substring(0, 100) + "...";
    }

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
              appBar: AppBar(
                backgroundColor: AppColors.blackColor,
                elevation: 0,
                leading: IconButton(
                  padding: EdgeInsets.only(
                    left: 30.0,
                    right:
                        Localization.textDirection == TextDirection.rtl
                            ? 20.0
                            : 0.0,
                  ),
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.whiteColor,
                    size: 25,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              body: Stack(
                children: [
                  Center(
                    child:
                        _chewieController != null
                            ? Padding(
                              padding: const EdgeInsets.only(
                                right: 20,
                                left: 20,
                                bottom: 50,
                                top: 10,
                              ),
                              child: Chewie(controller: _chewieController!),
                            )
                            : CircularProgressIndicator(
                              color: AppColors.primaryGreen(context),
                            ),
                  ),
                  if (_showNextUpOverlay)
                    Positioned.fill(
                      child: Container(
                        color: AppColors.blackColor.withOpacity(0.6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 30,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasNextLesson
                                    ? "${(Localization.translate('next_up') ?? '').trim() != 'next_up' && (Localization.translate('next_up') ?? '').trim().isNotEmpty ? Localization.translate('next_up') : "Next Up"}"
                                    : "${(Localization.translate('course_completed') ?? '').trim() != 'course_completed' && (Localization.translate('course_completed') ?? '').trim().isNotEmpty ? Localization.translate('course_completed') : "Course completed"}",
                                style: TextStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFontFamily.mediumFont,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                nextLessonTitle,
                                style: TextStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: FontSize.scale(context, 20),
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFontFamily.mediumFont,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                nextLessonDescription,
                                style: TextStyle(
                                  color: AppColors.whiteColor.withOpacity(0.9),
                                  fontSize: FontSize.scale(context, 16),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: AppFontFamily.regularFont,
                                ),
                              ),
                              SizedBox(height: 15),
                              ElevatedButton.icon(
                                onPressed:
                                    hasNextLesson
                                        ? _playNextVideo
                                        : () {
                                          setState(() {
                                            _showNextUpOverlay = false;
                                          });
                                        },
                                icon: SvgPicture.asset(
                                  Localization.textDirection ==
                                          TextDirection.rtl
                                      ? AppImages.playIconFilledRTL
                                      : AppImages.playIconFilled,
                                  height: 15.0,
                                  color: AppColors.whiteColor,
                                ),
                                label: Text(
                                  hasNextLesson
                                      ? "${(Localization.translate('play_next') ?? '').trim() != 'play_next' && (Localization.translate('play_next') ?? '').trim().isNotEmpty ? Localization.translate('play_next') : "Play Next"}"
                                      : "${(Localization.translate('finish') ?? '').trim() != 'finish' && (Localization.translate('finish') ?? '').trim().isNotEmpty ? Localization.translate('finish') : "Finish"}",
                                  style: TextStyle(
                                    color: AppColors.whiteColor,
                                    fontSize: FontSize.scale(context, 16),
                                    fontWeight: FontWeight.w500,
                                    fontFamily: AppFontFamily.mediumFont,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      hasNextLesson
                                          ? AppColors.primaryGreen(context)
                                          : AppColors.greyColor(
                                            context,
                                          ).withOpacity(0.9),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
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
    );
  }
}
