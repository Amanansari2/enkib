import 'package:flutter/material.dart';
import 'package:flutter_projects/presentation/view/dispute/dispute_chat/skeleton/chat_skeleton.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../../base_components/custom_toast.dart';
import '../../../../data/localization/localization.dart';
import '../../../../data/provider/auth_provider.dart';
import '../../../../data/provider/connectivity_provider.dart';
import '../../../../data/provider/dispute_discussion_provider.dart';
import '../../../../domain/api_structure/api_service.dart';
import '../../auth/login_screen.dart';
import '../../community/component/utils/date_utils.dart';
import '../../components/internet_alert.dart';
import '../../components/login_required_alert.dart';

class DisputeChatScreen extends StatefulWidget {
  final int id;
  final String disputeId;
  final String status;

  const DisputeChatScreen({
    Key? key,
    required this.id,
    required this.disputeId,
    required this.status,
  }) : super(key: key);

  @override
  _DisputeChatScreenState createState() => _DisputeChatScreenState();
}

class _DisputeChatScreenState extends State<DisputeChatScreen> {
  late TextEditingController _messageController = TextEditingController();
  late ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token != null) {
      Provider.of<DisputeDiscussionProvider>(
        context,
        listen: false,
      ).fetchDisputeDiscussion(context, token, widget.id);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 1.0,
            left: 16.0,
            right: 16.0,
            child: CustomToast(message: message, isSuccess: isSuccess),
          ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 500), () {
      overlayEntry.remove();
    });
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();

    if (messageText.isNotEmpty) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userId;

      try {
        final response = await disputeReply(
          token: token!,
          disputeId: widget.id,
          message: messageText,
        );

        if (response['status'] == 200) {
          showCustomToast(context, response['message'], true);

          final discussionProvider = Provider.of<DisputeDiscussionProvider>(
            context,
            listen: false,
          );
          final now = formatTime(DateTime.now().toIso8601String());
          setState(() {
            discussionProvider.disputeDiscussion.add({
              'message': messageText,
              'created_at': now,
              'user': {
                'id': userId,
                'profile': {'image': '', 'full_name': ''},
              },
            });
            discussionProvider.notifyListeners();
            _messageController.clear();

            Future.delayed(Duration(milliseconds: 10), () {
              _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              );
            });
          });
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
        } else if (response['status'] == 403) {
          showCustomToast(context, response['message'], false);
        } else {
          showCustomToast(context, response['message'], false);
        }
      } catch (e) {}
    }
  }

  Widget _buildSendMessageInput() {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 60),
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        border: Border(
          top: BorderSide(color: AppColors.dividerColor, width: 1),
        ),
      ),
      child: Row(
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
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed:
                (widget.status == 'closed' ||
                        widget.status == 'pending' ||
                        _messageController.text.isEmpty)
                    ? null
                    : _sendMessage,
            child: SvgPicture.asset(
              Localization.textDirection == TextDirection.rtl
                  ? AppImages.sendIconRtl
                  : AppImages.sendIcon,
              width: 20,
              height: 20,
            ),
            backgroundColor:
                (widget.status == 'closed' ||
                        widget.status == 'pending' ||
                        _messageController.text.isEmpty)
                    ? AppColors.fadeColor
                    : AppColors.primaryGreen(context),
            elevation: 0,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    final provider = Provider.of<DisputeDiscussionProvider>(context);

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
            if (provider.isLoading) {
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
                  child: Padding(
                    padding: EdgeInsets.only(top: 10.0),
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
                                  Navigator.pop(context);
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
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      provider.userProfileImage,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Icon(
                                          Icons.person,
                                          size: 25,
                                          color: Colors.grey,
                                        );
                                      },
                                    ),
                                  ),
                                  if (provider.onlineStatus)
                                    Positioned(
                                      top: -7,
                                      left: 40,
                                      child: Image.asset(
                                        AppImages.onlineIndicator,
                                        width: 16,
                                        height: 16,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Row(
                                      children: [
                                        Text(
                                          provider.userFullName,
                                          style: TextStyle(
                                            color: AppColors.blackColor,
                                            fontSize: FontSize.scale(
                                              context,
                                              16,
                                            ),
                                            fontFamily:
                                                AppFontFamily.regularFont,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        Spacer(),
                                        Text(
                                          '${(Localization.translate('dispute_id') ?? '').trim() != 'dispute_id' && (Localization.translate('dispute_id') ?? '').trim().isNotEmpty ? Localization.translate('dispute_id') : 'Dispute ID:'}',
                                          style: TextStyle(
                                            color: AppColors.greyColor(context),
                                            fontSize: FontSize.scale(
                                              context,
                                              12,
                                            ),
                                            fontFamily:
                                                AppFontFamily.regularFont,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        if (Localization.textDirection ==
                                            TextDirection.rtl)
                                          SizedBox(width: 8),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        provider.lastChattedTime.isNotEmpty
                                            ? RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        "${(Localization.translate('last_chat') ?? '').trim() != 'last_chat' && (Localization.translate('last_chat') ?? '').trim().isNotEmpty ? Localization.translate('last_chat') : 'Last chatted on'}",
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.greyColor(
                                                            context,
                                                          ),
                                                      fontSize: FontSize.scale(
                                                        context,
                                                        12,
                                                      ),
                                                      fontFamily:
                                                          AppFontFamily
                                                              .regularFont,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                  TextSpan(text: " "),
                                                  TextSpan(
                                                    text:
                                                        provider
                                                            .lastChattedTime,
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .blackColor
                                                          .withOpacity(0.8),
                                                      fontSize: FontSize.scale(
                                                        context,
                                                        12,
                                                      ),
                                                      fontFamily:
                                                          AppFontFamily
                                                              .regularFont,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            : SizedBox.shrink(),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: widget.disputeId,
                                                style: TextStyle(
                                                  color: AppColors.greyColor(
                                                    context,
                                                  ),
                                                  fontSize: FontSize.scale(
                                                    context,
                                                    14,
                                                  ),
                                                  fontFamily:
                                                      AppFontFamily.mediumFont,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (Localization.textDirection ==
                                                  TextDirection.rtl)
                                                WidgetSpan(
                                                  child: SizedBox(width: 8),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      centerTitle: false,
                    ),
                  ),
                ),
              ),
              body:
                  provider.isLoading
                      ? ShimmerChatList()
                      : Column(
                        children: <Widget>[
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: provider.disputeDiscussion.length,
                              shrinkWrap: true,
                              padding: EdgeInsets.only(top: 10),
                              itemBuilder: (context, index) {
                                final discussion =
                                    provider.disputeDiscussion[index];
                                final createdAt =
                                    discussion['created_at'] ?? '';
                                final user = discussion['user'];
                                final profileImage =
                                    user['profile']['image'] ?? '';
                                final fullName =
                                    user['profile']['full_name'] ?? '';
                                final message = discussion['message'] ?? '';
                                final bool isSender = user['id'] == userId;

                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 14,
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
                                              : CrossAxisAlignment.start,
                                      children: [
                                        if (!isSender)
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: Image.network(
                                                  profileImage,
                                                  width: 25,
                                                  height: 25,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Icon(
                                                      Icons.person,
                                                      size: 25,
                                                      color: Colors.grey,
                                                    );
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      fullName,
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
                                                            FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(height: 5),
                                                    ConstrainedBox(
                                                      constraints: BoxConstraints(
                                                        maxWidth: 280,
                                                      ),

                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                          10,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.whiteColor,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          message,
                                                          style: TextStyle(
                                                            color: AppColors
                                                                .blackColor,
                                                            fontSize:
                                                                FontSize.scale(
                                                                  context,
                                                                  14,
                                                                ),
                                                            fontFamily:
                                                                AppFontFamily
                                                                    .regularFont,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                          maxLines: null,
                                                          overflow:
                                                              TextOverflow.clip,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        message.trim().isNotEmpty
                                            ? Column(
                                          crossAxisAlignment:
                                          isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                          children: [
                                            if (isSender)
                                              ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: 280,
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: AppColors.senderMessageBgColor,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  padding: EdgeInsets.all(16),
                                                  child: Text(
                                                    message,
                                                    maxLines: null,
                                                    overflow:
                                                    TextOverflow.clip,
                                                    style: TextStyle(
                                                      color: AppColors.blackColor,
                                                      fontSize: FontSize.scale(context, 14),
                                                      fontFamily: AppFontFamily.regularFont,
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            SizedBox(height: 2),
                                            Padding(
                                              padding: isSender
                                                  ? EdgeInsets.only(right: 10.0, top: 6.0)
                                                  : EdgeInsets.only(left: 35.0, top: 6.0),
                                              child: Text(
                                                createdAt,
                                                style: TextStyle(
                                                  color: AppColors.greyColor(context),
                                                  fontSize: FontSize.scale(context, 12),
                                                  fontFamily: AppFontFamily.regularFont,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                            : SizedBox.shrink(),

                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          _buildSendMessageInput(),
                        ],
                      ),
            ),
          ),
        );
      },
    );
  }
}
