import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../../../../data/localization/localization.dart';
import '../../../../data/provider/auth_provider.dart';
import '../chat_screen.dart';

class VideoMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final int index;
  final Function(int) onDelete;

  VideoMessageWidget({required this.message, required this.index, required this.onDelete});

  @override
  _VideoMessageWidgetState createState() => _VideoMessageWidgetState();
}

class _VideoMessageWidgetState extends State<VideoMessageWidget> {
  VideoPlayerController? _controller;
  bool isVideoLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    if (widget.message.videoPath != null && widget.message.videoPath!.isNotEmpty) {
      if (widget.message.videoPath!.startsWith('http')) {
        _controller = VideoPlayerController.network(widget.message.videoPath!)
          ..initialize().then((_) {
            setState(() {
              isVideoLoaded = true;
            });
          });
      } else {
        _controller = VideoPlayerController.file(File(widget.message.videoPath!))
          ..initialize().then((_) {
            setState(() {
              isVideoLoaded = true;
            });
          });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isSender = widget.message.userId == authProvider.userId;

    if (widget.message.deleted) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSender ? AppColors.senderMessageBgColor : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "${(Localization.translate('message_deleted') ?? '').trim() != 'message_deleted' && (Localization.translate('message_deleted') ?? '').trim().isNotEmpty ? Localization.translate('message_deleted') : 'This message was deleted.'}",
          style: TextStyle(
            color: AppColors.blackColor,
            fontSize: FontSize.scale(context, 14),
            fontFamily: AppFontFamily.regularFont,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }
    return GestureDetector(
      onLongPress: () {
        _showMessageOptions(context, widget.message, widget.index);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isSender ? AppColors.senderMessageBgColor : AppColors.whiteColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: isVideoLoaded && _controller != null
                  ? Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                  IconButton(
                    icon: Icon(
                      _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: AppColors.primaryGreen(context),
                      size: 35,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(AppColors.whiteColor),
                      shape: MaterialStateProperty.all(CircleBorder()),
                    ),
                  ),
                ],
              )
                  : Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryGreen(context),
                  strokeWidth: 2.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showMessageOptions(BuildContext context, ChatMessage message, int index) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.sheetBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${(Localization.translate('message_options') ?? '').trim() != 'message_options' && (Localization.translate('message_options') ?? '').trim().isNotEmpty ? Localization.translate('message_options') : 'Message Options'}",
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 20),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildOptionTile(
                      context,
                      Icons.delete,
                      "${(Localization.translate('delete_text') ?? '').trim() != 'delete_text' && (Localization.translate('delete_text') ?? '').trim().isNotEmpty ? Localization.translate('delete_text') : 'Delete'}",
                          () {
                        _deleteMessage();
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildOptionTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: AppColors.blackColor),
          title: Text(
            title,
            style: TextStyle(
              color: AppColors.blackColor,
              fontSize: FontSize.scale(context, 16),
              fontWeight: FontWeight.w400,
              fontFamily: AppFontFamily.regularFont
            ),
          ),
        ),
      ),
    );
  }

  void _deleteMessage() {
    setState(() {
      widget.message.deleted = true;
    });
    widget.onDelete(widget.index);
  }
}