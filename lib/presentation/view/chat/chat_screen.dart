import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/domain/api_structure/api_service.dart';
import 'package:flutter_projects/presentation/view/chat/pusher_chat.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../auth/login_screen.dart';
import '../community/component/utils/date_utils.dart';
import '../components/internet_alert.dart';
import '../components/login_required_alert.dart';
import '../dispute/dispute_chat/skeleton/chat_skeleton.dart';
import 'component/image_viewer.dart';
import 'component/video_message_widget.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatScreen extends StatefulWidget {
  final String threadId;
  final String threadType;
  final String userId;
  final String senderPhoto;
  final String senderName;
  bool isOnline;

  ChatScreen({
    required this.threadId,
    required this.threadType,
    required this.userId,
    required this.senderPhoto,
    required this.senderName,
    required this.isOnline,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  void openAppFiles(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Directionality(
          textDirection: Localization.textDirection,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.sheetBackgroundColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          Localization.translate("select_option"),
                          style: TextStyle(
                            color: AppColors.blackColor,
                            fontSize: FontSize.scale(context, 18),
                            fontFamily: AppFontFamily.mediumFont,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                          borderRadius: BorderRadius.circular(8.0),
                          color: AppColors.whiteColor,
                        ),
                        child: SizedBox(
                          height: 200,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildOptionItem(
                                  context,
                                  AppImages.uploadPhoto,
                                  _isUploading
                                      ? "${(Localization.translate('uploading') ?? '').trim() != 'uploading' && (Localization.translate('uploading') ?? '').trim().isNotEmpty ? Localization.translate('uploading') : 'Uploading...'}"
                                      : "${(Localization.translate('upload_photo') ?? '').trim() != 'upload_photo' && (Localization.translate('upload_photo') ?? '').trim().isNotEmpty ? Localization.translate('upload_photo') : "Upload photo"}",
                                  () => _pickImages(
                                    bottomSheetContext,
                                    setModalState,
                                  ),
                                  showLoader: _isUploading,
                                ),
                                Divider(
                                  color: AppColors.dividerColor,
                                  thickness: 1,
                                  height: 1,
                                ),
                                _buildOptionItem(
                                  context,
                                  AppImages.uploadVideo,
                                  _isVideoUploading
                                      ? "${(Localization.translate('uploading') ?? '').trim() != 'uploading' && (Localization.translate('uploading') ?? '').trim().isNotEmpty ? Localization.translate('uploading') : 'Uploading...'}"
                                      : "${(Localization.translate('upload_video') ?? '').trim() != 'upload_video' && (Localization.translate('upload_video') ?? '').trim().isNotEmpty ? Localization.translate('upload_video') : "Upload video"}",
                                  () => _pickVideo(
                                    bottomSheetContext,
                                    setModalState,
                                  ),
                                  showLoader: _isVideoUploading,
                                ),
                                Divider(
                                  color: AppColors.dividerColor,
                                  thickness: 1,
                                  height: 1,
                                ),
                                _buildOptionItem(
                                  context,
                                  AppImages.uploadFile,
                                  _isDocumentUploading
                                      ? "${(Localization.translate('uploading') ?? '').trim() != 'uploading' && (Localization.translate('uploading') ?? '').trim().isNotEmpty ? Localization.translate('uploading') : 'Uploading...'}"
                                      : "${(Localization.translate('upload_file') ?? '').trim() != 'upload_file' && (Localization.translate('upload_file') ?? '').trim().isNotEmpty ? Localization.translate('upload_file') : 'Upload file'}",
                                  () => _pickFile(
                                    bottomSheetContext,
                                    setModalState,
                                  ),
                                  showLoader: _isDocumentUploading,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    String iconPath,
    String text,
    VoidCallback onTap, {
    bool showLoader = false,
  }) {
    return ListTile(
      leading: SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        color: AppColors.checkIconColor,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              color: AppColors.greyColor(context),
              fontSize: FontSize.scale(context, 16),
              fontFamily: AppFontFamily.regularFont,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (showLoader)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryGreen(context),
              ),
            ),
        ],
      ),
      onTap: showLoader ? null : onTap,
    );
  }

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool isLoading = false;
  bool isRefreshing = false;
  int currentPage = 1;
  bool isLoadingMore = false;
  int page = 1;
  int totalPages = 1;
  List<Map<String, dynamic>> messagesList = [];
  List<String> eventNameList = [];
  IO.Socket? socket;
  Map<int, bool> userOnlineStatus = {};
  late ChatPusherService chatPusherService;

  void onMessageReceived(Map<String, dynamic> eventData) {
    final newMessageData = eventData["message"];
    final newMessage = ChatMessage.fromJson(newMessageData);

    setState(() {
      messagesList.add(newMessage.toJson());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _initializeSocket() {
    socket?.on("message-received", (data) {
      onMessageReceived(data);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMessages();
    _initializeSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    chatPusherService = ChatPusherService(
      id: userId.toString(),
      scrollToBottom: _scrollToBottom,
      onEventReceived: (String eventName, String eventData) {
        try {
          if (eventData == null || eventData.isEmpty) {
            return;
          }

          final Map<String, dynamic> data = jsonDecode(eventData);
          if (data.isEmpty || !data.containsKey('message')) {
            return;
          }

          final int userId = data['message']['userId'];
          if (mounted) {
            setState(() {
              if (eventName == 'user-is-online') {
                userOnlineStatus[userId] = true;
              } else if (eventName == 'user-is-offline') {
                userOnlineStatus[userId] = false;
              }
            });
          }
        } catch (e) {}
      },
    );

    chatPusherService.addListener(() {
      setState(() {
        messagesList.add(chatPusherService.messages.last.toJson());
      });
    });

    chatPusherService.initialize(context);
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void handleIncomingMessage(Map<String, dynamic> newMessage) {
    setState(() {
      messagesList.insert(0, newMessage);
    });
  }

  @override
  void dispose() {
    super.dispose();
    chatPusherService.dispose();
  }

  void _sendMessage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token!;
    final userId = authProvider.userId;

    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final DateTime now = DateTime.now();
    final formattedTime = _formatMessageTime(now);

    final tempMessage = {
      "threadId": widget.threadId,
      "body": messageText,
      "messageType": "text",
      "isSender": true,
      "createdAt": now.toIso8601String(),
      "messageTime": formattedTime,
      "userId": userId,
      "messageId": null,
    };

    setState(() {
      messagesList.add(tempMessage);
    });

    int tempIndex = messagesList.length - 1;

    _messageController.clear();

    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });

    try {
      final response = await sendMessage(
        token: token,
        threadId: widget.threadId,
        body: messageText,
        messageType: "text",
        isSender: true,
      );

      if (response['type'] == "success" ||
          response['status'] == 200 &&
              response['data'] != null &&
              response['data']['message'] != null) {
        final serverMessageId = response['data']['message']['messageId'];

        setState(() {
          messagesList[tempIndex] = {
            ...messagesList[tempIndex],
            'messageId': serverMessageId,
          };
        });

        socket?.emit("message-sent", {
          "threadId": widget.threadId,
          "body": messageText,
          "messageType": "text",
          "isSender": true,
          "createdAt": now.toIso8601String(),
          "messageTime": formattedTime,
          "messageId": serverMessageId,
        });
      } else if (response['status'] == 403) {
        showCustomToast(context, response['message'], false);
      } else {
        showCustomToast(context, response['message'], false);
      }
    } catch (e) {}
  }

  void _deleteMessages(int index) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token!;

    final messageId = messagesList[index]['messageId']?.toString();

    if (messageId == null || messageId.isEmpty) {
      await Future.delayed(Duration(milliseconds: 200));
      setState(() {});

      final updatedMessageId = messagesList[index]['messageId']?.toString();
      if (updatedMessageId == null || updatedMessageId.isEmpty) {
        return;
      }
    }

    try {
      final response = await deleteMessage(
        token: token,
        messageId: messagesList[index]['messageId'].toString(),
        threadId: widget.threadId,
      );

      if (response['status'] == 200 || response['type'] == 'success') {
        setState(() {
          messagesList[index]['deletedAt'] = DateTime.now().toIso8601String();
          messagesList[index]['body'] =
              "${(Localization.translate('message_deleted') ?? '').trim() != 'message_deleted' && (Localization.translate('message_deleted') ?? '').trim().isNotEmpty ? Localization.translate('message_deleted') : 'This message was deleted.'}";
        });
        await fetchMessages();
      } else if (response['status'] == 403) {
        showCustomToast(context, response['message'], false);
      } else {
        showCustomToast(context, response['message'], false);
      }
    } catch (e) {}
  }

  Future<void> fetchMessages({
    bool isLoadMore = false,
    bool isPrevious = false,
  }) async {
    if ((isLoadMore && (isLoadingMore || currentPage > totalPages)) ||
        (isPrevious && currentPage <= 1)) {
      return;
    }

    try {
      if (!isLoadMore) {
        setState(() {
          isLoading = true;
          messagesList.clear();
          currentPage = 1;
        });
      } else {
        setState(() {
          isLoadingMore = true;
        });
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (isPrevious) currentPage--;

      final response = await getMessages(
        token!,
        threadId: widget.threadId,
        threadType: widget.threadType,
        page: currentPage,
      );
      if (response['type'] == 'success' || response['status'] == 200) {
        if (response.containsKey('data') && response['data']['list'] is List) {
          List<Map<String, dynamic>> newMessages =
              (response['data']['list'] as List).map((item) {
                if (item['deletedAt'] != null) {
                  item['body'] =
                      "${(Localization.translate('message_deleted') ?? '').trim() != 'message_deleted' && (Localization.translate('message_deleted') ?? '').trim().isNotEmpty ? Localization.translate('message_deleted') : 'This message was deleted.'}";
                }

                return item as Map<String, dynamic>;
              }).toList();

          setState(() {
            if (isPrevious) {
              messagesList.insertAll(0, newMessages);
            } else {
              messagesList.addAll(newMessages);
              currentPage++;
            }
            totalPages = response['data']['pagination']['totalPages'];
          });
        }
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
      }
    } catch (e) {
    } finally {
      setState(() {
        isLoadingMore = false;
        isLoading = false;
      });
    }
  }

  void _openBottomSheet({int? index}) {
    if (messagesList.isEmpty ||
        index == null ||
        index < 0 ||
        index >= messagesList.length) {
      return;
    }

    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String buttonText =
            '${(Localization.translate('block_user') ?? '').trim() != 'block_user' && (Localization.translate('block_user') ?? '').trim().isNotEmpty ? Localization.translate('block_user') : "Block user"}';
        bool isLoading = false;

        String friendStatus = messagesList[index]['friendStatus'] ?? '';
        if (friendStatus == 'blocked') {
          buttonText =
              '${(Localization.translate('unblock_user') ?? '').trim() != 'unblock_user' && (Localization.translate('unblock_user') ?? '').trim().isNotEmpty ? Localization.translate('unblock_user') : "Unblock user"}';
        }

        String toTitleCase(String str) {
          return str
              .split(' ')
              .map(
                (word) =>
                    word.isNotEmpty
                        ? word[0].toUpperCase() +
                            word.substring(1).toLowerCase()
                        : '',
              )
              .join(' ');
        }

        return Directionality(
          textDirection: Localization.textDirection,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sheetBackgroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15.0,
                        vertical: 20.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: AppColors.topBottomSheetDismissColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(
                                  widget.senderPhoto != null &&
                                          widget.senderPhoto != ''
                                      ? widget.senderPhoto
                                      : '',
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        AppImages.placeHolderImage,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              widget.isOnline
                                  ? Positioned(
                                    bottom: -10,
                                    left: 28,
                                    child: Image.asset(
                                      AppImages.onlineIndicator,
                                      width: 16,
                                      height: 16,
                                    ),
                                  )
                                  : SizedBox.shrink(),
                            ],
                          ),
                          SizedBox(height: 14),
                          Text(
                            widget.senderName != null && widget.senderName != ''
                                ? toTitleCase(widget.senderName)
                                : "",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.blackColor,
                              fontSize: FontSize.scale(context, 20),
                              fontFamily: AppFontFamily.mediumFont,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 20),
                          Align(
                            alignment:
                                Localization.textDirection == TextDirection.rtl
                                    ? Alignment.topRight
                                    : Alignment.topLeft,
                            child: Text(
                              Localization.translate("select_option"),
                              style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: FontSize.scale(context, 14),
                                fontFamily: AppFontFamily.mediumFont,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.greyColor(
                                    context,
                                  ).withOpacity(0.04),
                                  spreadRadius: 1,
                                  blurRadius: 1,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: OutlinedButton(
                              onPressed: () async {
                                if (isLoading) return;

                                setState(() {
                                  isLoading = true;
                                });

                                String statusToUpdate =
                                    friendStatus == "blocked"
                                        ? "unblocked"
                                        : "blocked";

                                final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                                final token = authProvider.token;
                                final response = await updateFriendStatus(
                                  token!,
                                  widget.userId.toString(),
                                  statusToUpdate,
                                );

                                setState(() {
                                  isLoading = false;
                                });

                                if (response['type'] == 'success' ||
                                    response['status'] == 200) {
                                  setState(() {
                                    friendStatus = statusToUpdate;
                                    buttonText =
                                        friendStatus == "blocked"
                                            ? '${(Localization.translate('unblock_user') ?? '').trim() != 'unblock_user' && (Localization.translate('unblock_user') ?? '').trim().isNotEmpty ? Localization.translate('unblock_user') : "Unblock user"}'
                                            : '${(Localization.translate('block_user') ?? '').trim() != 'block_user' && (Localization.translate('block_user') ?? '').trim().isNotEmpty ? Localization.translate('block_user') : "Block user"}';
                                  });

                                  Navigator.pop(context);

                                  await fetchMessages();
                                } else if (response['status'] == 403) {
                                  showCustomToast(
                                    context,
                                    response['message'],
                                    false,
                                  );
                                } else {
                                  showCustomToast(
                                    context,
                                    response['message'],
                                    false,
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.redBackgroundColor,
                                side: BorderSide(
                                  color: AppColors.redBorderColor,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                minimumSize: Size(double.infinity, 50),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    buttonText,
                                    style: TextStyle(
                                      color: AppColors.redColor,
                                      fontSize: FontSize.scale(context, 14),
                                      fontFamily: AppFontFamily.mediumFont,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (isLoading) ...[
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
                          ),
                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  bool _isUploading = false;
  bool _isVideoUploading = false;
  bool _isDocumentUploading = false;

  void _pickImages(
    BuildContext bottomSheetContext,
    void Function(void Function()) setModalState,
  ) async {
    setModalState(() {
      _isUploading = true;
    });

    String currentTime = DateTime.now().toIso8601String();
    String formattedTime = formatTime(currentTime);

    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedImages = await picker.pickMultiImage();

    if (pickedImages != null && pickedImages.isNotEmpty) {
      List<File> imageFiles =
          pickedImages.map((image) => File(image.path)).toList();
      List<String> uploadedImageUrls = [];
      String? senderName;
      int? userId;
      String? senderPhoto;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token!;

      for (File image in imageFiles) {
        var response = await uploadImage(
          token: token,
          threadId: widget.threadId,
          imageFile: image,
        );

        await fetchMessages();

        if (response['status'] == 200 || response['type'] == "success") {
          if (response['data'] is Map) {
            var messageData = response['data']['message'];

            senderName = messageData['name'];
            userId = messageData['userId'];
            senderPhoto = messageData['photo'];

            List<dynamic> attachments = messageData['attachments'] ?? [];

            for (var attachment in attachments) {
              if (attachment is Map && attachment.containsKey('file')) {
                uploadedImageUrls.add(attachment['file']);
              } else {}
            }

            ChatMessage newMessage = ChatMessage(
              messageContent: "",
              messageType: "sender",
              messageTime: formattedTime,
              isImage: true,
              images: uploadedImageUrls,
              userId: userId,
              senderName: senderName,
              senderPhoto: senderPhoto,
            );

            setState(() {
              messagesList.insert(0, newMessage.toJson());
            });
          } else {}
        } else if (response['status'] == 403) {
          showCustomToast(context, response['message'], false);
        } else {
          showCustomToast(context, response['message'], false);
        }
      }

      setModalState(() {
        _isUploading = false;
      });

      Navigator.pop(bottomSheetContext);
    } else {
      setModalState(() {
        _isUploading = false;
      });

      Navigator.pop(bottomSheetContext);
    }
  }

  Future<void> _pickVideo(
    BuildContext bottomSheetContext,
    void Function(void Function()) setModalState,
  ) async {
    setModalState(() {
      _isVideoUploading = true;
    });

    final ImagePicker _picker = ImagePicker();
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      await _addVideoMessage(video.path, bottomSheetContext, setModalState);
    } else {
      setModalState(() {
        _isVideoUploading = false;
      });
      Navigator.pop(bottomSheetContext);
    }
  }

  Future<void> _addVideoMessage(
    String videoPath,
    BuildContext bottomSheetContext,
    void Function(void Function()) setModalState,
  ) async {
    String currentTime = DateTime.now().toIso8601String();
    String formattedTime = formatTime(currentTime);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token!;

    var response = await uploadVideo(
      token: token,
      threadId: widget.threadId,
      videoFile: File(videoPath),
    );

    await fetchMessages();

    if (response['status'] == 200 || response['type'] == "success") {
      if (response['data'] is Map) {
        var messageData = response['data']['message'];

        String senderName = messageData['name'];
        String senderPhoto = messageData['photo'];
        int userId = messageData['userId'];

        List<String> uploadedVideoUrls = [];

        List<dynamic> attachments = messageData['attachments'] ?? [];
        if (attachments.isNotEmpty) {
          for (var attachment in attachments) {
            if (attachment is Map && attachment.containsKey('file')) {
              uploadedVideoUrls.add(attachment['file']);
            }
          }
        }

        if (uploadedVideoUrls.isNotEmpty) {
          ChatMessage newMessage = ChatMessage(
            messageContent: "",
            messageType: "sender",
            messageTime: formattedTime,
            isImage: false,
            isVoice: false,
            isVideo: true,
            videoPath: uploadedVideoUrls[0],
            userId: userId,
            senderName: senderName,
            senderPhoto: senderPhoto,
          );

          setState(() {
            messagesList.insert(0, newMessage.toJson());
          });

          setModalState(() {
            _isVideoUploading = false;
          });
          Navigator.pop(bottomSheetContext);
        } else {}
      } else {
        setModalState(() {
          _isVideoUploading = false;
        });
        Navigator.pop(bottomSheetContext);
      }
    } else if (response['status'] == 403) {
      showCustomToast(context, response['message'], false);
    } else {
      setModalState(() {
        Navigator.pop(bottomSheetContext);
        _isVideoUploading = false;
      });
    }
  }

  void _pickFile(
    BuildContext bottomSheetContext,
    void Function(void Function()) setModalState,
  ) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    setModalState(() {
      _isDocumentUploading = true;
    });

    if (result != null && result.files.isNotEmpty) {
      String? filePath = result.files.single.path;
      String fileName = result.files.single.name;

      if (filePath != null) {
        setModalState(() {
          _isDocumentUploading = true;
        });

        await _addFileMessage(
          fileName,
          filePath,
          bottomSheetContext,
          setModalState,
        );
      } else {}
    } else {}
    Navigator.pop(bottomSheetContext);
  }

  Future<void> _addFileMessage(
    String fileName,
    String filePath,
    BuildContext bottomSheetContext,
    void Function(void Function()) setModalState,
  ) async {
    String currentTime = DateTime.now().toIso8601String();
    String formattedTime = formatTime(currentTime);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token!;

    var response = await uploadDocument(
      token: token,
      threadId: widget.threadId,
      documentFile: File(filePath),
    );

    await fetchMessages();

    if (response['type'] == 'success' || response['status'] == 200) {
      String senderName = response['data']['message']['name'];
      String senderPhoto = response['data']['message']['photo'];
      int userId = response['data']['message']['userId'];

      List<String> uploadedFileUrls = [
        response['data']['message']['attachments'][0]['file'],
      ];

      ChatMessage newMessage = ChatMessage(
        messageContent: fileName,
        messageType: "sender",
        messageTime: formattedTime,
        isImage: false,
        isVoice: false,
        isVideo: false,
        isFile: true,
        filePath: uploadedFileUrls[0],
        userId: userId,
        senderName: senderName,
        senderPhoto: senderPhoto,
      );

      setState(() {
        messagesList.insert(0, newMessage.toJson());
      });

      setModalState(() {
        _isDocumentUploading = false;
      });
      Navigator.pop(bottomSheetContext);
    } else if (response['status'] == 403) {
      showCustomToast(context, response['message'], false);
    } else {
      showCustomToast(context, response['message'], false);
      setModalState(() {
        _isDocumentUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    String _formatLastMessageTime(dynamic createdAt) {
      if (createdAt == null || createdAt.toString().isEmpty) return "";

      try {
        DateTime date;

        if (createdAt is DateTime) {
          date = createdAt;
        } else if (createdAt is String) {
          date = DateTime.parse(createdAt);
        } else {
          return "";
        }

        date = date.toLocal();

        return formatHourMinute(date);
      } catch (e) {
        return "";
      }
    }

    Widget buildInputOrBlockedMessage() {
      if (messagesList.isNotEmpty &&
          messagesList[0]['friendStatus'] == 'blocked') {
        return Container(
          width: 300,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          margin: EdgeInsets.symmetric(vertical: 60),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            border: Border.all(color: AppColors.dividerColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.greyColor(context).withOpacity(0.04),
                spreadRadius: 1,
                blurRadius: 1,
              ),
            ],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (messagesList[0]['blockedBy'] == null)
                      ? '${(Localization.translate('block_by_user') ?? '').trim() != 'block_by_user' && (Localization.translate('block_by_user') ?? '').trim().isNotEmpty ? Localization.translate('block_by_user') : "You have been blocked by the user"}'
                      : (messagesList[0]['blockedBy'] == userId)
                      ? '${(Localization.translate('user_blocked') ?? '').trim() != 'user_blocked' && (Localization.translate('user_blocked') ?? '').trim().isNotEmpty ? Localization.translate('user_blocked') : "You have blocked this user"}'
                      : '${(Localization.translate('blocked') ?? '').trim() != 'blocked' && (Localization.translate('blocked') ?? '').trim().isNotEmpty ? Localization.translate('blocked') : "User is blocked"}',
                  style: TextStyle(
                    color: AppColors.greyColor(context).withOpacity(0.6),
                    fontSize: FontSize.scale(context, 16),
                    fontFamily: AppFontFamily.mediumFont,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text:
                            '${(Localization.translate('unblock_now') ?? '').trim() != 'unblock_now' && (Localization.translate('unblock_now') ?? '').trim().isNotEmpty ? Localization.translate('unblock_now') : "Unblock now"}',
                        style: TextStyle(
                          color: AppColors.greyColor(context).withOpacity(0.6),
                          fontSize: FontSize.scale(context, 16),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationThickness: 1,
                          fontStyle: FontStyle.normal,
                          height: 1.1,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                _openBottomSheet(index: 0);
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return Container(
          padding: EdgeInsets.only(left: 20, bottom: 10, top: 10, right: 20),
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            border: Border(
              top: BorderSide(color: AppColors.dividerColor, width: 1),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  cursorColor: AppColors.blackColor,
                  controller: _messageController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText:
                        "${(Localization.translate('type_message') ?? '').trim() != 'type_message' && (Localization.translate('type_message') ?? '').trim().isNotEmpty ? Localization.translate('type_message') : 'Type your message here'}",
                    hintStyle: TextStyle(
                      color: AppColors.greyColor(context).withOpacity(0.8),
                      fontSize: FontSize.scale(context, 16),
                      fontFamily: AppFontFamily.regularFont,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: Container(
                      decoration: BoxDecoration(
                        color: AppColors.fadeColor.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: SvgPicture.asset(
                        AppImages.addFileIcon,
                        width: 55,
                        height: 55,
                      ),
                    ),
                    onPressed: () => openAppFiles(context),
                  ),
                  SizedBox(width: 185),
                  FloatingActionButton(
                    shape: RoundedRectangleBorder(
                      side: BorderSide.none,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onPressed:
                        _messageController.text.isEmpty ? null : _sendMessage,
                    child: SvgPicture.asset(
                      Localization.textDirection == TextDirection.rtl
                          ? AppImages.sendIconRtl
                          : AppImages.sendIcon,
                      width: 25,
                      height: 25,
                    ),
                    backgroundColor:
                        _messageController.text.isEmpty
                            ? AppColors.fadeColor
                            : AppColors.primaryGreen(context),
                    elevation: 0,
                  ),
                ],
              ),
              SizedBox(height: 15),
            ],
          ),
        );
      }
    }

    String toTitleCase(String str) {
      return str
          .split(' ')
          .map(
            (word) =>
                word.isNotEmpty
                    ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                    : '',
          )
          .join(' ');
    }

    String _getDateLabel(DateTime dateTime) {
      final now = DateTime.now().toLocal();
      final todayStart = DateTime(now.year, now.month, now.day);
      final yesterdayStart = todayStart.subtract(Duration(days: 1));

      if (dateTime.isAfter(todayStart)) {
        return "${(Localization.translate('today') ?? '').trim() != 'today' && (Localization.translate('today') ?? '').trim().isNotEmpty ? Localization.translate('today') : 'Today'}";
      } else if (dateTime.isAfter(yesterdayStart)) {
        return "${(Localization.translate('yesterday') ?? '').trim() != 'yesterday' && (Localization.translate('yesterday') ?? '').trim().isNotEmpty ? Localization.translate('yesterday') : 'Yesterday'}";
      } else {
        return formatYMMMd(dateTime);
      }
    }

    bool _isNewDay(String previousDate, String currentDate) {
      final previousDateTime = DateTime.parse(previousDate);
      final currentDateTime = DateTime.parse(currentDate);

      return previousDateTime.year != currentDateTime.year ||
          previousDateTime.month != currentDateTime.month ||
          previousDateTime.day != currentDateTime.day;
    }

    String _getFormattedMessageTime(DateTime dateTime) {
      return formatTimeJM(dateTime);
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
                preferredSize: Size.fromHeight(90.0),
                child: Container(
                  color: AppColors.whiteColor,
                  child: AppBar(
                    backgroundColor: AppColors.whiteColor,
                    automaticallyImplyLeading: false,
                    forceMaterialTransparency: true,
                    elevation: 0,
                    titleSpacing: 0,
                    flexibleSpace: SafeArea(
                      child: Container(
                        padding: EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: AppColors.blackColor,
                              ),
                            ),
                            SizedBox(width: 2),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    widget.senderPhoto != null &&
                                            widget.senderPhoto != ''
                                        ? widget.senderPhoto
                                        : '',
                                    width: 45,
                                    height: 45,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          AppImages.placeHolderImage,
                                          width: 45,
                                          height: 45,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (messagesList.isNotEmpty) ...[
                                  Positioned(
                                    top: -5,
                                    left: 38,
                                    child:
                                        widget.isOnline
                                            ? Image.asset(
                                              AppImages.onlineIndicator,
                                              width: 14,
                                              height: 14,
                                            )
                                            : SizedBox.shrink(),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    widget.senderName != null &&
                                            widget.senderName != ''
                                        ? toTitleCase(widget.senderName)
                                        : "",
                                    textScaler: TextScaler.noScaling,
                                    style: TextStyle(
                                      color: AppColors.blackColor,
                                      fontSize: FontSize.scale(context, 16),
                                      fontFamily: AppFontFamily.regularFont,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    messagesList.isNotEmpty &&
                                            messagesList.last['createdAt'] !=
                                                null &&
                                            messagesList.last['createdAt']
                                                .toString()
                                                .isNotEmpty
                                        ? "${(Localization.translate('last_chat') ?? '').trim() != 'last_chat' && (Localization.translate('last_chat') ?? '').trim().isNotEmpty ? Localization.translate('last_chat') : 'Last chatted on'} ${_formatLastMessageTime(messagesList.last['createdAt'])}"
                                        : "",
                                    textScaler: TextScaler.noScaling,
                                    style: TextStyle(
                                      color: AppColors.greyColor(context),
                                      fontSize: FontSize.scale(context, 12),
                                      fontFamily: AppFontFamily.regularFont,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 15.0, top: 35),
                        child: IconButton(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          icon: SvgPicture.asset(
                            AppImages.filterIcon,
                            width: 30,
                            height: 30,
                            color: AppColors.greyColor(context),
                          ),
                          onPressed:
                              () => {
                                if (messagesList.isNotEmpty)
                                  {_openBottomSheet(index: 0)},
                              },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              body:
                  isLoading
                      ? ShimmerChatList()
                      : Column(
                        children: <Widget>[
                          Expanded(
                            child: Stack(
                              children: <Widget>[
                                NotificationListener<ScrollNotification>(
                                  onNotification: (
                                    ScrollNotification scrollInfo,
                                  ) {
                                    if (scrollInfo.metrics.pixels ==
                                            scrollInfo
                                                .metrics
                                                .maxScrollExtent &&
                                        !isLoadingMore &&
                                        !isRefreshing &&
                                        messagesList.isNotEmpty) {
                                      fetchMessages(isLoadMore: true);
                                    }
                                    return false;
                                  },
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount:
                                        isLoadingMore
                                            ? messagesList.length + 1
                                            : messagesList.length,
                                    shrinkWrap: false,
                                    physics: AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.only(top: 10),
                                    itemBuilder: (context, index) {
                                      if (isLoadingMore &&
                                          index == messagesList.length) {
                                        return Center(
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              right: 10.0,
                                              left: 10,
                                              top: 10,
                                              bottom: 30,
                                            ),
                                            child: CircularProgressIndicator(
                                              color: AppColors.primaryGreen(
                                                context,
                                              ),
                                              strokeWidth: 2.0,
                                            ),
                                          ),
                                        );
                                      }
                                      if (index >= messagesList.length) {
                                        return SizedBox.shrink();
                                      }
                                      final messageJson = messagesList[index];

                                      final message = ChatMessage.fromJson(
                                        messageJson,
                                      );

                                      final authProvider =
                                          Provider.of<AuthProvider>(
                                            context,
                                            listen: false,
                                          );
                                      final isSender =
                                          message.userId == authProvider.userId;
                                      final createdAt = DateTime.parse(
                                        message.createdAt ??
                                            DateTime.now().toString(),
                                      );

                                      final formattedTime =
                                          _getFormattedMessageTime(createdAt);

                                      String? dateHeader;
                                      if (index == 0 ||
                                          _isNewDay(
                                            messagesList[index -
                                                1]['createdAt'],
                                            message.createdAt!,
                                          )) {
                                        dateHeader = _getDateLabel(createdAt);
                                      }

                                      bool showTimeAndCheckmark =
                                          message.body != null &&
                                              message.body!.isNotEmpty ||
                                          (message.attachments != null &&
                                              message.attachments!.isNotEmpty);

                                      return Column(
                                        children: [
                                          if (message
                                                  .messageContent
                                                  .isNotEmpty &&
                                              dateHeader != null) ...[
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 5,
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey
                                                          .withOpacity(0.1),
                                                      spreadRadius: 2,
                                                      blurRadius: 5,
                                                    ),
                                                  ],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.0,
                                                      ),
                                                  color:
                                                      AppColors.backgroundColor(
                                                        context,
                                                      ),
                                                ),
                                                child: Text(
                                                  dateHeader!,
                                                  style: TextStyle(
                                                    color: AppColors.greyColor(
                                                      context,
                                                    ),
                                                    fontSize: FontSize.scale(
                                                      context,
                                                      12,
                                                    ),
                                                    fontFamily:
                                                        AppFontFamily
                                                            .mediumFont,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                          Container(
                                            padding: EdgeInsets.only(
                                              left: 14,
                                              right: 14,
                                              top: 10,
                                              bottom: 10,
                                            ),
                                            child: Align(
                                              alignment:
                                                  (Localization.textDirection ==
                                                          TextDirection.rtl)
                                                      ? (isSender
                                                          ? Alignment.topLeft
                                                          : Alignment.topRight)
                                                      : (isSender
                                                          ? Alignment.topRight
                                                          : Alignment.topLeft),
                                              child: Column(
                                                crossAxisAlignment:
                                                    isSender
                                                        ? CrossAxisAlignment.end
                                                        : CrossAxisAlignment
                                                            .start,
                                                children: [
                                                  if (message.messageContent !=
                                                              null &&
                                                          message
                                                              .messageContent!
                                                              .isNotEmpty ||
                                                      (message.attachments !=
                                                              null &&
                                                          message
                                                              .attachments!
                                                              .isNotEmpty)) ...[
                                                    if (!isSender)
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            child: Image.network(
                                                              message.senderPhoto ??
                                                                  '',
                                                              width: 30,
                                                              height: 30,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (
                                                                context,
                                                                error,
                                                                stackTrace,
                                                              ) {
                                                                return ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        8,
                                                                      ),
                                                                  child: Image.asset(
                                                                    AppImages
                                                                        .placeHolderImage,
                                                                    width: 30,
                                                                    height: 30,
                                                                    fit:
                                                                        BoxFit
                                                                            .cover,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                message.senderName!.isNotEmpty &&
                                                                        message.senderName !=
                                                                            null
                                                                    ? toTitleCase(
                                                                      message.senderName ??
                                                                          "",
                                                                    )
                                                                    : "",
                                                                style: TextStyle(
                                                                  color:
                                                                      AppColors.greyColor(
                                                                        context,
                                                                      ),
                                                                  fontSize:
                                                                      FontSize.scale(
                                                                        context,
                                                                        14,
                                                                      ),
                                                                  fontFamily:
                                                                      AppFontFamily
                                                                          .mediumFont,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: 5,
                                                              ),
                                                              if (message
                                                                  .isImage)
                                                                _buildImageMessage(
                                                                  context,
                                                                  message,
                                                                  index,
                                                                )
                                                              else if (message
                                                                  .isVideo)
                                                                VideoMessageWidget(
                                                                  message:
                                                                      message,
                                                                  index: index,
                                                                  onDelete: (
                                                                    int index,
                                                                  ) {
                                                                    setState(() {
                                                                      _deleteMessages(
                                                                        index,
                                                                      );
                                                                    });
                                                                  },
                                                                )
                                                              else if (message
                                                                  .isFile)
                                                                _buildFileMessage(
                                                                  context,
                                                                  message,
                                                                  index,
                                                                )
                                                              else
                                                                _buildTextMessage(
                                                                  context,
                                                                  message,
                                                                  index,
                                                                ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                  if (isSender)
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        if (message.isImage)
                                                          _buildImageMessage(
                                                            context,
                                                            message,
                                                            index,
                                                          )
                                                        else if (message
                                                            .isVideo)
                                                          VideoMessageWidget(
                                                            message: message,
                                                            index: index,
                                                            onDelete: (
                                                              int index,
                                                            ) {
                                                              setState(() {
                                                                _deleteMessages(
                                                                  index,
                                                                );
                                                              });
                                                            },
                                                          )
                                                        else if (message.isFile)
                                                          _buildFileMessage(
                                                            context,
                                                            message,
                                                            index,
                                                          )
                                                        else
                                                          _buildTextMessage(
                                                            context,
                                                            message,
                                                            index,
                                                          ),
                                                      ],
                                                    ),
                                                  if (showTimeAndCheckmark) ...[
                                                    SizedBox(height: 5),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              isSender
                                                                  ? EdgeInsets
                                                                      .zero
                                                                  : EdgeInsets.only(
                                                                    left: 48.0,
                                                                  ),
                                                          child: Text(
                                                            formattedTime ?? '',
                                                            style: TextStyle(
                                                              color:
                                                                  AppColors.greyColor(
                                                                    context,
                                                                  ),
                                                              fontSize:
                                                                  FontSize.scale(
                                                                    context,
                                                                    12,
                                                                  ),
                                                              fontFamily:
                                                                  AppFontFamily
                                                                      .regularFont,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(width: 5),
                                                        if (isSender)
                                                          _buildMessageCheckmark(
                                                            message,
                                                            context,
                                                          ),
                                                        if (!isSender)
                                                          Container(),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          buildInputOrBlockedMessage(),
                        ],
                      ),
            ),
          ),
        );
      },
    );
  }

  void _showMessageOptions(
    BuildContext context,
    ChatMessage message,
    int index,
  ) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
      ),
      builder: (BuildContext context) {
        return Directionality(
          textDirection: Localization.textDirection,
          child: GestureDetector(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 20.0,
                  ),
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
                          _deleteMessages(index);
                          Navigator.pop(context);
                        },
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
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
              fontFamily: AppFontFamily.regularFont,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessage(
    BuildContext context,
    ChatMessage message,
    int index,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isSender = message.userId == authProvider.userId;

    if (message.deleted) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSender ? AppColors.senderMessageBgColor : AppColors.whiteColor,
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

    double imageSize = 130;
    double overlapOffset = 25.0;
    double opacityFactor = 0.85;

    if (message.images == null || message.images!.isEmpty) {
      if (message.attachments != null && message.attachments!.isNotEmpty) {
        message.images = List<String>.from(
          message.attachments!.map((x) => x['file'] ?? ''),
        );
      }
    }

    if (message.images == null || message.images!.isEmpty) {
      return Container();
    }

    if (message.images!.length == 1) {
      return GestureDetector(
        onLongPress:
            isSender
                ? () {
                  _showMessageOptions(context, message, index);
                }
                : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      ImageViewer(images: message.images!, initialIndex: 0),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color:
                isSender
                    ? AppColors.senderMessageBgColor
                    : AppColors.whiteColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CachedNetworkImage(
              imageUrl: message.images![0],
              height: imageSize,
              width: imageSize,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => SizedBox(
                    width: 50,
                    height: 50,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: AppColors.primaryGreen(context),
                      ),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Image.asset(
                    AppImages.placeHolderImage,
                    fit: BoxFit.cover,
                  ),
            ),
          ),
        ),
      );
    }

    double heightAdjustment = 0.0;
    if (message.images!.length == 2) {
      heightAdjustment = 25;
    } else if (message.images!.length >= 3) {
      heightAdjustment = overlapOffset * 2;
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: isSender ? AppColors.senderMessageBgColor : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: imageSize + heightAdjustment,
            width: imageSize + (overlapOffset * 2),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < message.images!.length && i < 3; i++)
                  Positioned(
                    left: i * overlapOffset,
                    top: i * overlapOffset,
                    child: GestureDetector(
                      onLongPress:
                          isSender
                              ? () {
                                _showMessageOptions(context, message, index);
                              }
                              : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ImageViewer(
                                  images: message.images!,
                                  initialIndex: 0,
                                ),
                          ),
                        );
                      },
                      child: Opacity(
                        opacity: (i == 2) ? 1.0 : opacityFactor - (i * 0.15),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: CachedNetworkImage(
                            imageUrl: message.images![i],
                            height: imageSize,
                            width: imageSize,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      color: AppColors.primaryGreen(context),
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Image.asset(
                                  AppImages.placeHolderImage,
                                  fit: BoxFit.cover,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (message.images!.length > 3)
                  Positioned(
                    left: 2 * overlapOffset,
                    top: 2 * overlapOffset,
                    child: GestureDetector(
                      onLongPress:
                          isSender
                              ? () {
                                _showMessageOptions(context, message, index);
                              }
                              : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ImageViewer(
                                  images: message.images!,
                                  initialIndex: 0,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        height: imageSize,
                        width: imageSize,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            "+${message.images!.length - 3}",
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: AppFontFamily.mediumFont,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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

  Widget _buildFileMessage(
    BuildContext context,
    ChatMessage message,
    int index,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isSender = message.userId == authProvider.userId;

    Widget fileNameText(String? filePath) {
      String fileName =
          (filePath != null && filePath.isNotEmpty)
              ? filePath.split('/').last
              : "";

      if (fileName.length > 10) {
        return Expanded(
          child: Text(
            fileName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.blackColor,
              fontSize: FontSize.scale(context, 12),
              fontFamily: AppFontFamily.regularFont,
              fontWeight: FontWeight.w400,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      } else {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 10),
            Text(
              fileName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 12),
                fontFamily: AppFontFamily.regularFont,
                fontWeight: FontWeight.w400,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }
    }

    if (message.deleted) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSender ? AppColors.senderMessageBgColor : AppColors.whiteColor,
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
        _showMessageOptions(context, message, index);
      },
      onTap: () {
        _openFile(context, message.filePath);
      },
      child: Container(
        width: 200,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSender ? AppColors.senderMessageBgColor : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SvgPicture.asset(
                AppImages.fileIcon,
                color: AppColors.greyColor(context),
                width: 25.0,
                height: 25.0,
              ),
            ),
            SizedBox(width: 10),
            fileNameText(message.filePath),
          ],
        ),
      ),
    );
  }

  void _openFile(BuildContext context, String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      return;
    }

    if (filePath.startsWith("https")) {
      if (await canLaunchUrl(Uri.parse(filePath))) {
        await launchUrl(
          Uri.parse(filePath),
          mode: LaunchMode.externalApplication,
        );
      } else {}
    } else {
      final file = File(filePath);
      if (await file.exists()) {
        OpenFile.open(filePath);
      } else {}
    }
  }

  Widget _buildTextMessage(
    BuildContext context,
    ChatMessage message,
    int index,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isSender = message.userId == authProvider.userId;

    if (message.messageContent.isEmpty) {
      return SizedBox.shrink();
    }

    if (message.deletedAt != null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSender ? AppColors.senderMessageBgColor : AppColors.whiteColor,
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
      onLongPress:
          isSender
              ? () {
                _showMessageOptions(context, message, index);
              }
              : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 280),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isSender
                    ? AppColors.senderMessageBgColor
                    : AppColors.whiteColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.messageContent,
            maxLines: null,
            overflow: TextOverflow.clip,
            style: TextStyle(
              color: AppColors.blackColor,
              fontSize: FontSize.scale(context, 14),
              fontFamily: AppFontFamily.regularFont,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildMessageCheckmark(ChatMessage message, BuildContext context) {
  if (message.deletedAt != null) {
    return Container();
  } else if (message.seenAt != null) {
    return Transform.translate(
      offset: const Offset(0.0, -3.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.check, color: AppColors.darkGreen, size: 15),
          Positioned(
            top: 5,
            left: 2,
            right: 10,
            bottom: 10,
            child: Icon(Icons.check, color: AppColors.darkGreen, size: 15),
          ),
        ],
      ),
    );
  } else if (message.deliveredAt != null) {
    return Transform.translate(
      offset: const Offset(0.0, -3.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.check, color: AppColors.greyColor(context), size: 15),
          Positioned(
            top: 5,
            left: 2,
            right: 10,
            bottom: 10,
            child: Icon(
              Icons.check,
              color: AppColors.greyColor(context),
              size: 15,
            ),
          ),
        ],
      ),
    );
  } else {
    return Icon(Icons.check, color: AppColors.greyColor(context), size: 15);
  }
}

class ChatMessage {
  String messageContent;
  String messageType;
  String messageTime;
  bool isImage;
  List<String>? images;
  bool isVoice;
  int? duration;
  bool isVideo;
  String? videoPath;
  bool isFile;
  String? filePath;
  bool deleted;
  String? deletedAt;
  String? senderName;
  String? senderPhoto;
  int? userId;
  String? createdAt;
  String? seenAt;
  String? deliveredAt;
  String? body;
  List<dynamic>? attachments;

  ChatMessage({
    required this.messageContent,
    required this.messageType,
    required this.messageTime,
    this.isImage = false,
    this.images,
    this.isVoice = false,
    this.duration,
    this.isVideo = false,
    this.videoPath,
    this.isFile = false,
    this.filePath,
    this.deleted = false,
    this.deletedAt,
    this.senderName,
    this.senderPhoto,
    this.userId,
    this.createdAt,
    this.seenAt,
    this.deliveredAt,
    this.body,
    this.attachments,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    String messageContent = json['body'] ?? json['messageContent'] ?? '';

    DateTime messageTime = DateTime.parse(
      json['createdAt'] ?? DateTime.now().toString(),
    );

    List<String> imageUrls = [];
    if (json['messageType'] == 'image' && json['attachments'] != null) {
      imageUrls = List<String>.from(
        json['attachments']
            .map((x) => x['file'])
            .where((url) => url != null && url.isNotEmpty),
      );
    }

    return ChatMessage(
      messageContent: messageContent,
      messageType: json['messageType'] ?? 'text',
      messageTime: _getFormattedMessageTime(messageTime),
      isImage: json['messageType'] == 'image',
      images: imageUrls.isNotEmpty ? imageUrls : null,
      isVoice: json['messageType'] == 'voice',
      isVideo: json['messageType'] == 'video',
      videoPath:
          json['attachments'] != null && json['attachments'].isNotEmpty
              ? json['attachments'][0]['file']
              : null,
      isFile: json['messageType'] == 'document',
      filePath:
          json['attachments'] != null && json['attachments'].isNotEmpty
              ? json['attachments'][0]['file']
              : null,
      deleted: json['deletedAt'] != null,
      deletedAt: json['deletedAt'],
      senderName: json['name'] ?? json['senderName'] ?? '',
      senderPhoto: json['photo'] ?? json['senderPhoto'] ?? '',
      userId: json['userId'],
      createdAt: json['createdAt'],
      seenAt: json['seenAt'],
      deliveredAt: json['deliveredAt'],
      body: json['body'],
      attachments: json['attachments'] ?? [],
    );
  }

  static String _getFormattedMessageTime(DateTime dateTime) {
    return formatTimeJM(dateTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'messageContent': messageContent,
      'messageType': messageType,
      'messageTime': messageTime,
      'isImage': isImage,
      'isVoice': isVoice,
      'isVideo': isVideo,
      'isFile': isFile,
      'deleted': deleted,
      'deletedAt': deletedAt,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'userId': userId,
      'createdAt': createdAt,
      'body': body,
      'attachments': attachments,
    };
  }
}

String _formatMessageTime(dynamic createdAt) {
  if (createdAt == null || createdAt.toString().isEmpty) return "";

  try {
    DateTime date;

    if (createdAt is DateTime) {
      date = createdAt;
    } else {
      date = DateTime.parse(createdAt.toString()).toLocal();
    }
    return formatHourMinute(date);
  } catch (e) {
    return "";
  }
}
