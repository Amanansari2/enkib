import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_projects/domain/api_structure/api_service.dart';
import 'package:flutter_projects/presentation/view/chat/chat_screen.dart';
import 'package:flutter_projects/presentation/view/chat/pusher_chat.dart';
import 'package:flutter_projects/presentation/view/chat/skeleton/chat_list_skeleton.dart';
import 'package:flutter_projects/presentation/view/chat/tutor_chat_list.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../base_components/textfield.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../auth/login_screen.dart';
import '../community/component/bouncer.dart';
import '../components/internet_alert.dart';
import '../components/login_required_alert.dart';

class ChatListScreen extends StatefulWidget {
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int page = 1;
  int totalPages = 1;
  int totalTutors = 0;
  bool isLoadingMore = false;

  TextEditingController _searchController = TextEditingController();
  final _bounce = Bouncer(milliseconds: 500);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> chatThreadList = [];
  List<String> eventNameList = [];

  ChatPusherService? pusherService;
  Map<int, bool> userOnlineStatus = {};

  bool isLoading = false;
  bool isRefreshing = false;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    fetchThreadList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dataId = authProvider.userId;

    if (pusherService == null) {
      pusherService = ChatPusherService(
        id: dataId.toString(),
        scrollToBottom: () {},
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
                  if (userOnlineStatus[userId] != true) {
                    userOnlineStatus[userId] = true;
                  }
                } else if (eventName == 'user-is-offline') {
                  if (userOnlineStatus[userId] != false) {
                    userOnlineStatus[userId] = false;
                  }
                }
              });
            }
          } catch (e) {}
        },
      );

      pusherService!.initialize(context);
    }
  }

  @override
  void dispose() {
    pusherService?.dispose();
    super.dispose();
  }

  Future<void> fetchThreadList({
    bool isLoadMore = false,
    String? search,
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
          chatThreadList.clear();
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

      final response = await getThreadList(
        token!,
        search: search,
        page: currentPage,
      );

      if (response['type'] == 'success' || response['status'] == 200) {
        if (response.containsKey('data') && response['data']['list'] is Map) {
          final threadList =
              (response['data']['list'] as Map).cast<String, dynamic>();

          List<Map<String, dynamic>> newCourses =
              threadList.entries.map((entry) {
                return {
                  ...entry.value as Map<String, dynamic>,
                  'threadKey': entry.key,
                };
              }).toList();

          setState(() {
            if (isPrevious) {
              chatThreadList.insertAll(0, newCourses);
            } else {
              chatThreadList.addAll(newCourses);
              currentPage++;
            }
            totalPages = response['data']['pagination']['totalPages'];
            totalTutors = response['data']['pagination']['total'];
          });
        }
      } else if (response['status'] == 401) {
        showCustomToast(context, response['message'], false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: Localization.translate("invalidToken"),
              content: Localization.translate("loginAgain"),
              buttonText: Localization.translate("goToLogin"),
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
      } else {}
    } catch (e) {
    } finally {
      setState(() {
        isLoadingMore = false;
        isLoading = false;
      });
    }
  }

  Future<void> searchThreadList({String? search}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        showCustomToast(
          context,
          '${Localization.translate("unauthorized_access")}',
          false,
        );
        return;
      }

      final response = await getThreadList(token, search: search);

      if (response['type'] == 'success' || response['status'] == 200) {
        if (response.containsKey('data') &&
            response['data'].containsKey('list') &&
            response['data']['list'] is Map) {
          final threadList = response['data']['list'] as Map<String, dynamic>;

          if (threadList.isNotEmpty) {
            List<Map<String, dynamic>> newThreads =
                threadList.entries.map((entry) {
                  return {
                    ...entry.value as Map<String, dynamic>,
                    'threadKey': entry.key,
                  };
                }).toList();

            setState(() {
              chatThreadList = newThreads;
            });
          } else {
            setState(() {
              chatThreadList = [];
            });
          }
        } else {
          setState(() {
            chatThreadList = [];
          });
        }
      } else if (response['status'] == 401) {
        showCustomToast(context, response['message'], false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: Localization.translate("invalidToken"),
              content: Localization.translate("loginAgain"),
              buttonText: Localization.translate("goToLogin"),
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
      } else {}
    } catch (e) {}
  }

  Future<void> refreshThreadList() async {
    try {
      setState(() {
        isRefreshing = true;
        isLoadingMore = false;
        currentPage = 1;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getThreadList(token!, page: 1);

      if (response['status'] == 200 || response['type'] == "success") {
        if (response.containsKey('data') && response['data']['list'] is Map) {
          setState(() {
            chatThreadList =
                (response['data']['list'] as Map).values
                    .map((thread) => Map<String, dynamic>.from(thread))
                    .toList();

            totalPages = response['data']['pagination']['totalPages'];
            totalTutors = response['data']['pagination']['total'];
            currentPage++;
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
        return;
      }
    } catch (e) {
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
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
            if (isLoading) {
              return false;
            } else {
              return true;
            }
          },
          child: Directionality(
            textDirection: Localization.textDirection,
            child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: AppColors.backgroundColor(context),
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(70.0),
                child: Container(
                  color: AppColors.whiteColor,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: AppBar(
                      backgroundColor: AppColors.whiteColor,
                      automaticallyImplyLeading: false,
                      forceMaterialTransparency: true,
                      centerTitle: false,
                      elevation: 0,
                      titleSpacing: 0,
                      title: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(Localization.translate('chats') ?? '').trim() != 'chats' && (Localization.translate('chats') ?? '').trim().isNotEmpty ? Localization.translate('chats') : "Chats"}',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: AppColors.blackColor,
                              fontSize: FontSize.scale(context, 20),
                              fontFamily: AppFontFamily.mediumFont,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      "${chatThreadList.length} / ${totalTutors}",
                                  style: TextStyle(
                                    color: AppColors.greyColor(context),
                                    fontSize: FontSize.scale(context, 12),
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
                                    fontFamily: AppFontFamily.mediumFont,
                                  ),
                                ),
                                TextSpan(text: " "),
                                TextSpan(
                                  text:
                                      '${(Localization.translate("tutors")).trim().isNotEmpty ? (totalTutors <= 1 ? Localization.translate("tutors")?.replaceAll("Tutors", "Tutor") : Localization.translate("tutors")) : (totalTutors <= 1 ? "Tutor" : "Tutors")}',
                                  style: TextStyle(
                                    color: AppColors.greyColor(
                                      context,
                                    ).withOpacity(0.7),
                                    fontSize: FontSize.scale(context, 12),
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

                      leading: Padding(
                        padding: EdgeInsets.only(top: 3.0),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.arrow_back_ios,
                            size: 20,
                            color: AppColors.blackColor,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              body:
                  isLoading
                      ? Column(
                        children: [
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width - 100,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.whiteColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              SizedBox(width: 15),
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.whiteColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 5.0),
                                  child: ChatListSkeleton(),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                      : Column(
                        children: [
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width - 100,
                                child: CustomTextField(
                                  hint:
                                      '${(Localization.translate('search_keyword') ?? '').trim() != 'search_keyword' && (Localization.translate('search_keyword') ?? '').trim().isNotEmpty ? Localization.translate('search_keyword') : 'Search by keyword'}',
                                  searchIcon: true,
                                  controller: _searchController,
                                  mandatory: false,
                                  onChanged: (value) {
                                    _bounce.run(() {
                                      String searchQuery =
                                          _searchController.text.trim();
                                      searchThreadList(search: searchQuery);
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 15),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => TutorChatListScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen(context),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: SvgPicture.asset(
                                      AppImages.addIcon,
                                      width: 40,
                                      height: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),

                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: refreshThreadList,
                              color: AppColors.primaryGreen(context),
                              child: Stack(
                                children: [
                                  if (chatThreadList.isNotEmpty || isLoading)
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
                                            chatThreadList.isNotEmpty) {
                                          fetchThreadList(isLoadMore: true);
                                        }
                                        return false;
                                      },
                                      child: ListView.builder(
                                        itemCount:
                                            isLoadingMore
                                                ? chatThreadList.length + 1
                                                : chatThreadList.length,
                                        itemBuilder: (context, index) {
                                          if (isLoadingMore &&
                                              index == chatThreadList.length) {
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
                                          if (index >= chatThreadList.length) {
                                            return SizedBox.shrink();
                                          }

                                          final thread = chatThreadList[index];
                                          final senderPhoto =
                                              thread['photo'] ?? '';
                                          final senderName =
                                              thread['name'] ?? '';

                                          final threadId = thread['threadId'];
                                          final threadType =
                                              thread['threadType'];
                                          String userId =
                                              thread['userId'].toString();

                                          final createdAt =
                                              thread['createdAt'] != null &&
                                                      thread['createdAt']
                                                          is String
                                                  ? DateTime.parse(
                                                    thread['createdAt'],
                                                  )
                                                  : DateTime.now();

                                          final localCreatedAt =
                                              createdAt.toLocal();
                                          final dateFormatted = DateFormat(
                                            'hh:mm',
                                          ).format(localCreatedAt);

                                          final unseenMessages =
                                              (thread['unSeenMessages']
                                                      as List?)
                                                  ?.isNotEmpty ??
                                              false;

                                          String capitalizeName(String name) {
                                            return name
                                                .split(' ')
                                                .map(
                                                  (word) =>
                                                      word.isNotEmpty
                                                          ? word[0]
                                                                  .toUpperCase() +
                                                              word
                                                                  .substring(1)
                                                                  .toLowerCase()
                                                          : '',
                                                )
                                                .join(' ');
                                          }

                                          bool onlineStatus =
                                              userOnlineStatus[thread['userId']] ??
                                              false;

                                          return ChatListItem(
                                            imagePath: thread['photo'] ?? '',
                                            tutorName:
                                                capitalizeName(
                                                  thread['name'],
                                                ) ??
                                                '',
                                            lastMessage: thread['body'] ?? '',
                                            date: dateFormatted,
                                            unseenMessage: unseenMessages,
                                            messageType: thread['messageType'],
                                            online: onlineStatus,
                                            friendStatus:
                                                thread['friendStatus'] ?? '',
                                            blockedBy:
                                                thread['blockedBy'] ?? '',
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) => ChatScreen(
                                                        threadId:
                                                            threadId.toString(),
                                                        threadType: threadType,
                                                        userId:
                                                            userId.toString(),
                                                        isOnline: onlineStatus,
                                                        senderPhoto:
                                                            senderPhoto,
                                                        senderName: senderName,
                                                      ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  if (chatThreadList.isEmpty && !isLoading)
                                    Positioned.fill(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            AppImages.emptyChat,
                                            width: 100,
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            '${(Localization.translate('click_icon') ?? '').trim() != 'click_icon' && (Localization.translate('click_icon') ?? '').trim().isNotEmpty ? Localization.translate('click_icon') : "Click on + icon"}',

                                            style: TextStyle(
                                              color: AppColors.blackColor,
                                              fontSize: FontSize.scale(
                                                context,
                                                14,
                                              ),
                                              fontFamily:
                                                  AppFontFamily.mediumFont,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            '${(Localization.translate('start_chat_tutor') ?? '').trim() != 'start_chat_tutor' && (Localization.translate('start_chat_tutor') ?? '').trim().isNotEmpty ? Localization.translate('start_chat_tutor') : "Find the right tutor and start chatting instantly!"}',
                                            style: TextStyle(
                                              color: AppColors.greyColor(
                                                context,
                                              ).withOpacity(0.7),
                                              fontSize: FontSize.scale(
                                                context,
                                                14,
                                              ),
                                              fontFamily:
                                                  AppFontFamily.mediumFont,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (chatThreadList.isEmpty && !isLoading)
                                    ListView(
                                      physics: AlwaysScrollableScrollPhysics(),
                                      children: [SizedBox(height: 1)],
                                    ),
                                ],
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

class ChatListItem extends StatelessWidget {
  final String tutorName;
  final String lastMessage;
  final String imagePath;
  final String date;
  final bool unseenMessage;
  final bool online;
  final String messageType;
  final VoidCallback onPressed;
  final String friendStatus;
  final dynamic blockedBy;

  ChatListItem({
    required this.tutorName,
    required this.lastMessage,
    required this.imagePath,
    required this.date,
    required this.unseenMessage,
    required this.online,
    required this.messageType,
    required this.friendStatus,
    required this.blockedBy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2))],
        ),
        child: ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  imagePath,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        AppImages.placeHolderImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
              if (online)
                Positioned(
                  top: -5,
                  left: 38,
                  child: Image.asset(
                    AppImages.onlineIndicator,
                    width: 16,
                    height: 16,
                  ),
                ),
            ],
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tutorName,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: AppColors.blackColor,
                  fontSize: FontSize.scale(context, 16),
                  fontFamily: AppFontFamily.regularFont,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Row(
                children: [
                  Text(
                    date,
                    style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 12),
                      fontFamily: AppFontFamily.regularFont,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 5),
                  unseenMessage
                      ? Image.asset(
                        AppImages.unseenMessages,
                        width: 16,
                        height: 16,
                      )
                      : Container(),
                ],
              ),
            ],
          ),
          subtitle: Row(
            children: [
              if (messageType == 'document' || messageType == 'image')
                SvgPicture.asset(
                  AppImages.attachmentIcon,
                  width: 15,
                  height: 15,
                ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  friendStatus.toLowerCase() == 'blocked' && blockedBy == null
                      ? '${(Localization.translate('block_by_user') ?? '').trim() != 'block_by_user' && (Localization.translate('block_by_user') ?? '').trim().isNotEmpty ? Localization.translate('block_by_user') : "You have been blocked by the user"}'
                      : (friendStatus.toLowerCase() == 'blocked' &&
                              blockedBy == userId
                          ? '${(Localization.translate('user_blocked') ?? '').trim() != 'user_blocked' && (Localization.translate('user_blocked') ?? '').trim().isNotEmpty ? Localization.translate('user_blocked') : "You have blocked this user"}'
                          : (messageType == 'document' || messageType == 'image'
                              ? '${(Localization.translate('sent_attachment') ?? '').trim() != 'sent_attachment' && (Localization.translate('sent_attachment') ?? '').trim().isNotEmpty ? Localization.translate('sent_attachment') : "Sent you an attachment"}'
                              : lastMessage)),
                  textScaler: TextScaler.noScaling,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.greyColor(context),
                    fontSize: FontSize.scale(context, 12),
                    fontFamily: AppFontFamily.regularFont,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          onTap: onPressed,
        ),
      ),
    );
  }
}

class Chat {
  final String imagePath;
  final String tutorName;
  final String lastMessage;
  final String date;
  final String status;
  final String messageType;

  Chat({
    required this.imagePath,
    required this.tutorName,
    required this.lastMessage,
    required this.date,
    required this.status,
    required this.messageType,
  });
}
