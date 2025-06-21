import 'package:flutter/material.dart';
import 'package:flutter_projects/domain/api_structure/api_service.dart';
import 'package:flutter_projects/presentation/view/chat/chat_list.dart';
import 'package:flutter_projects/presentation/view/chat/skeleton/chat_list_skeleton.dart';
import 'package:flutter_projects/styles/app_styles.dart';
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

class TutorChatListScreen extends StatefulWidget {
  @override
  State<TutorChatListScreen> createState() => _TutorChatListScreenState();
}

class _TutorChatListScreenState extends State<TutorChatListScreen> {
  int page = 1;
  int totalPages = 1;
  int totalTutors = 0;
  bool isLoadingMore = false;

  TextEditingController _searchController = TextEditingController();
  final _bounce = Bouncer(milliseconds: 500);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> chatContactList = [];

  bool isLoading = false;
  bool isRefreshing = false;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    fetchContactList();
  }

  Future<void> fetchContactList({
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
          chatContactList.clear();
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

      final response = await getContactList(
        token!,
        search: search,
        page: currentPage,
      );

      if (response['type'] == 'success') {
        if (response.containsKey('data') && response['data']['list'] is Map) {
          final contactList =
              (response['data']['list'] as Map).cast<String, dynamic>();

          List<Map<String, dynamic>> newCourses =
              contactList.entries.map((entry) {
                return {
                  ...entry.value as Map<String, dynamic>,
                  'threadKey': entry.key,
                };
              }).toList();

          setState(() {
            if (isPrevious) {
              chatContactList.insertAll(0, newCourses);
            } else {
              chatContactList.addAll(newCourses);
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

  Future<void> searchContactList({String? search}) async {
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

      final response = await getContactList(token, search: search);

      if (response['type'] == 'success') {
        if (response.containsKey('data') &&
            response['data'].containsKey('list') &&
            response['data']['list'] is Map) {
          final contactList = response['data']['list'] as Map<String, dynamic>;

          if (contactList.isNotEmpty) {
            List<Map<String, dynamic>> newContacts =
                contactList.entries.map((entry) {
                  return {
                    ...entry.value as Map<String, dynamic>,
                    'threadKey': entry.key,
                  };
                }).toList();

            setState(() {
              chatContactList = newContacts;
            });
          } else {
            setState(() {
              chatContactList = [];
            });
          }
        } else {
          setState(() {
            chatContactList = [];
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

  Future<void> refreshContactList() async {
    try {
      setState(() {
        isRefreshing = true;
        isLoadingMore = false;
        currentPage = 1;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getContactList(token!, page: 1);

      if (response['type'] == 'success') {
        if (response.containsKey('data') && response['data']['list'] is Map) {
          setState(() {
            chatContactList =
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
                            '${(Localization.translate('all_tutors') ?? '').trim() != 'all_tutors' && (Localization.translate('all_tutors') ?? '').trim().isNotEmpty ? Localization.translate('all_tutors') : 'All Tutors'}',
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
                                      "${chatContactList.length} / ${totalTutors}",
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
                                      '${(Localization.translate("tutors")).trim().isNotEmpty ? (totalTutors <= 1 ? Localization.translate("tutors").replaceAll("Tutors", "Tutor") : Localization.translate("tutors")) : (totalTutors <= 1 ? "Tutor" : "Tutors")}',
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
                          Container(
                            width: MediaQuery.of(context).size.width - 50,
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
                                  searchContactList(search: searchQuery);
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 20),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text(
                                '${(Localization.translate('select_tutors_chat') ?? '').trim() != 'select_tutors_chat' && (Localization.translate('select_tutors_chat') ?? '').trim().isNotEmpty ? Localization.translate('select_tutors_chat') : 'Select tutors to start chat'}',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 14),
                                  fontFamily: AppFontFamily.mediumFont,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),

                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: refreshContactList,
                              color: AppColors.primaryGreen(context),
                              child: Stack(
                                children: [
                                  if (chatContactList.isNotEmpty || isLoading)
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
                                            chatContactList.isNotEmpty) {
                                          fetchContactList(isLoadMore: true);
                                        }
                                        return false;
                                      },
                                      child: ListView.builder(
                                        itemCount:
                                            isLoadingMore
                                                ? chatContactList.length + 1
                                                : chatContactList.length,
                                        itemBuilder: (context, index) {
                                          if (isLoadingMore &&
                                              index == chatContactList.length) {
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
                                          if (index >= chatContactList.length) {
                                            return SizedBox.shrink();
                                          }

                                          final contact =
                                              chatContactList[index];

                                          return ChatListItem(
                                            imagePath: contact['photo'] ?? '',
                                            tutorName: contact['name'] ?? '',
                                            lastMessage: contact['body'] ?? '',
                                            online:
                                                contact['isOnline'] ?? false,
                                            onPressed: () async {
                                              final authProvider =
                                                  Provider.of<AuthProvider>(
                                                    context,
                                                    listen: false,
                                                  );
                                              final token = authProvider.token;
                                              final userId =
                                                  contact['userId'].toString();
                                              final response = await startChat(
                                                token: token!,
                                                userId: userId,
                                              );
                                              if (response['status'] == 200 ||
                                                  response['type'] ==
                                                      'success') {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            ChatListScreen(),
                                                  ),
                                                );
                                              } else if (response['status'] ==
                                                  403) {
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
                                          );
                                        },
                                      ),
                                    ),
                                  if (chatContactList.isEmpty && !isLoading)
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
                                            '${(Localization.translate('start_chat_label') ?? '').trim() != 'start_chat_label' && (Localization.translate('start_chat_label') ?? '').trim().isNotEmpty ? Localization.translate('start_chat_label') : "It's nice to chat with someone"}',
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
                                  if (chatContactList.isEmpty && !isLoading)
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
  final bool online;
  final VoidCallback onPressed;

  ChatListItem({
    required this.tutorName,
    required this.lastMessage,
    required this.imagePath,
    required this.online,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
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
              Positioned(
                top: -5,
                left: 38,
                child:
                    online
                        ? Image.asset(
                          AppImages.onlineIndicator,
                          width: 16,
                          height: 16,
                        )
                        : Container(),
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
