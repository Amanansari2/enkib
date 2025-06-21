import 'dart:io';
import '../../../data/provider/connectivity_provider.dart';
import '../auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../components/internet_alert.dart';
import '../components/login_required_alert.dart';
import 'component/forum_detail/contributors.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/localization/localization.dart';
import '../../../domain/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'component/forum_detail/comment_widget_card.dart';
import 'component/forum_detail/related_topics_card.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/presentation/view/community/component/utils/date_utils.dart';
import 'package:flutter_projects/presentation/view/community/skeleton/forum_detail_skeleton.dart';

class ForumDetail extends StatefulWidget {
  final String slug;
  final int id;

  const ForumDetail({Key? key, required this.slug, required this.id})
    : super(key: key);

  @override
  State<ForumDetail> createState() => _ForumDetailState();
}

class _ForumDetailState extends State<ForumDetail> {
  bool isLoading = false;
  Map<String, dynamic>? contributors;
  Map<String, dynamic> topicDetails = {};
  Map<String, dynamic>? relatedTopics;
  bool onPressLoading = false;

  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    super.initState();
    fetchContributors();
    fetchTopicDetails();
    fetchRelatedTopics();
    fetchComments();
  }

  Future<void> fetchContributors() async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getTopicContributors(token!, widget.slug);

      if (response['status'] == 200) {
        setState(() {
          contributors = response;
          isLoading = false;
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
        return;
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchTopicDetails() async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getTopicDetails(token!, widget.slug);

      if (response['status'] == 401) {
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

      if (response['status'] == 200 && response['data'] != null) {
        setState(() {
          topicDetails = response['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          topicDetails = {};
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        topicDetails = {};
        isLoading = false;
      });
    }
  }

  Future<void> submitVote() async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await voteTopic(
        type: "vote",
        token: token!,
        topicId: widget.id.toString(),
      );

      if (response['status'] == 200) {
        showCustomToast(context, response['message'], true);
        await fetchTopicDetails();
        setState(() {
          isLoading = false;
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
        setState(() {
          isLoading = false;
        });
        return;
      } else if (response['status'] == 403) {
        setState(() {
          isLoading = false;
        });
        showCustomToast(context, response['message'], false);
      } else {
        setState(() {
          isLoading = false;
        });
        showCustomToast(
          context,
          response['message'] ?? "Failed to create topic",
          false,
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showCustomToast(context, "An error occurred", false);
    }
  }

  Future<void> fetchRelatedTopics() async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getRelatedTopics(token, widget.slug);

      if (response['status'] == 401) {
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

      setState(() {
        relatedTopics = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchComments() async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getComments(token, widget.id);
      if (response['status'] == 200 && response['data'] != null) {
        setState(() {
          comments = List<Map<String, dynamic>>.from(response['data']);
          isLoading = false;
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
        return;
      } else {
        setState(() {
          comments = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showBottomSheet(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();
    bool _isDescriptionValid = false;

    Future<void> submitReply(StateSetter setModalState) async {
      try {
        setModalState(() {
          onPressLoading = true;
        });

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;

        setModalState(() {
          _isDescriptionValid = false;
          onPressLoading = false;
        });

        if (descriptionController.text.isEmpty) {
          setModalState(() {
            if (descriptionController.text.isEmpty) _isDescriptionValid = true;
          });
          showCustomToast(
            context,
            '${Localization.translate("description_required")}',
            false,
          );
          return;
        }

        final response = await replyComment(
          token: token!,
          description: descriptionController.text.trim(),
          topicId: widget.id.toString(),
        );

        if (response['status'] == 200) {
          showCustomToast(context, response['message'], true);
          Navigator.pop(context);
          fetchComments();
          setModalState(() {
            onPressLoading = false;
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
          setModalState(() {
            onPressLoading = false;
          });
          return;
        } else if (response['status'] == 403) {
          showCustomToast(context, response['message'], false);

          setModalState(() {
            onPressLoading = false;
          });
        } else if (response['status'] == 422 && response['errors'] != null) {
          final errors = response['errors'] as Map<String, dynamic>;
          setModalState(() {
            if (errors.containsKey('description')) _isDescriptionValid = true;
          });
          errors.forEach((field, message) {
            showCustomToast(context, message.toString(), false);
          });

          setModalState(() {
            onPressLoading = false;
          });
        } else {
          showCustomToast(
            context,
            response['message'] ?? "Failed to create topic",
            false,
          );
          setModalState(() {
            onPressLoading = false;
          });
        }
      } catch (e) {
        showCustomToast(context, "An error occurred", false);
        setModalState(() {
          onPressLoading = false;
        });
      }
    }

    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: Localization.textDirection,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.4,
                    decoration: BoxDecoration(
                      color: AppColors.sheetBackgroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 10.0,
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
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              '${Localization.translate("reply_topic")}',
                              style: TextStyle(
                                fontSize: FontSize.scale(context, 18),
                                color: AppColors.blackColor,
                                fontFamily: AppFontFamily.mediumFont,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTextField(
                                    hint:
                                        '${Localization.translate("type_here")}',
                                    mandatory: false,
                                    controller: descriptionController,
                                    multiLine: true,
                                    hasError: _isDescriptionValid,
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.greyColor(
                                                  context,
                                                ).withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                            borderRadius: BorderRadius.circular(
                                              10.0,
                                            ),
                                          ),
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.whiteColor,
                                              side: BorderSide(
                                                color: Colors.transparent,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 15,
                                              ),
                                            ),
                                            child: Text(
                                              "${Localization.translate("cancel")}",
                                              style: TextStyle(
                                                fontSize: FontSize.scale(
                                                  context,
                                                  16,
                                                ),
                                                color: AppColors.greyColor(
                                                  context,
                                                ),
                                                fontFamily:
                                                    AppFontFamily.mediumFont,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed:
                                              onPressLoading
                                                  ? null
                                                  : () {
                                                    submitReply(setModalState);
                                                  },
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor:
                                                onPressLoading
                                                    ? AppColors.fadeColor
                                                    : AppColors.primaryGreen(
                                                      context,
                                                    ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            side: BorderSide(
                                              width: onPressLoading ? 2 : 0,
                                              color:
                                                  onPressLoading
                                                      ? AppColors.dividerColor
                                                      : Colors.transparent,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 15,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "${Localization.translate("submit_reply")}",
                                                style: TextStyle(
                                                  fontSize: FontSize.scale(
                                                    context,
                                                    16,
                                                  ),
                                                  color:
                                                      onPressLoading
                                                          ? AppColors.greyColor(
                                                            context,
                                                          )
                                                          : AppColors
                                                              .whiteColor,
                                                  fontFamily:
                                                      AppFontFamily.mediumFont,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (onPressLoading) ...[
                                                SizedBox(width: 10),
                                                SizedBox(
                                                  height: 16,
                                                  width: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color:
                                                        AppColors.primaryGreen(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
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

  Widget _buildRestrictedUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 50),
          Image.asset(
            AppImages.restricted,
            fit: BoxFit.cover,
            width: 60,
            height: 60,
          ),
          SizedBox(height: 10),
          Text(
            '${Localization.translate("private_forum")}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: FontSize.scale(context, 14),
              fontFamily: AppFontFamily.mediumFont,
              color: AppColors.blackColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${Localization.translate("restricted_content")}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: FontSize.scale(context, 14),
              fontFamily: AppFontFamily.mediumFont,
              color: AppColors.greyColor(context).withOpacity(0.7),
            ),
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackColor.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.blackColor.withOpacity(0.05),
                side: BorderSide(color: Colors.transparent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              ),
              child: Text(
                "${Localization.translate("back_topics")}",
                style: TextStyle(
                  fontSize: FontSize.scale(context, 14),
                  color: AppColors.greyColor(context),
                  fontFamily: AppFontFamily.mediumFont,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> contributorsImageUrl = [];
    if (contributors != null && contributors!['status'] == 200) {
      final data = contributors!['data'] as List<dynamic>;
      if (data.isNotEmpty) {
        contributorsImageUrl =
            data.map<String>((item) {
              final image = item['image'] as String?;
              return image != null && image.isNotEmpty ? image : '';
            }).toList();
      }
    }

    List<String> relatedTopicsImage = [];

    if (relatedTopics != null && relatedTopics!['status'] == 200) {
      final data = relatedTopics!['data'] as List<dynamic>;
      if (data.isNotEmpty) {
        relatedTopicsImage =
            data.map<String>((item) {
              final media = item['media'] as String?;
              return media != null && media.isNotEmpty ? media : '';
            }).toList();
      }
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
                preferredSize: Size.fromHeight(60.0),
                child: Container(
                  color: AppColors.whiteColor,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: AppBar(
                      backgroundColor: AppColors.whiteColor,
                      forceMaterialTransparency: true,
                      leading: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.blackColor,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                      ),
                      centerTitle: false,
                      elevation: 0,
                      titleSpacing: 0,
                      title: Text(
                        '${Localization.translate("forums")}',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 20),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              body:
                  isLoading
                      ? ForumDetailSkeleton()
                      : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.whiteColor,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(20.0),
                                  bottomRight: Radius.circular(20.0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        height: 130,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image:
                                                (topicDetails.isNotEmpty &&
                                                        topicDetails['media'] !=
                                                            null &&
                                                        topicDetails['media']
                                                            .isNotEmpty)
                                                    ? NetworkImage(
                                                      topicDetails['media'],
                                                    )
                                                    : const AssetImage(
                                                          AppImages
                                                              .placeHolderImage,
                                                        )
                                                        as ImageProvider<
                                                          Object
                                                        >,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -15,
                                        left: 15,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.whiteColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.greyColor(
                                                  context,
                                                ).withOpacity(0.3),
                                                blurRadius: 5,
                                                spreadRadius: 2,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 24,
                                            backgroundColor:
                                                AppColors.whiteColor,
                                            child: CircleAvatar(
                                              radius: 22,
                                              backgroundImage:
                                                  (topicDetails.isNotEmpty &&
                                                          topicDetails['creator'] !=
                                                              null &&
                                                          topicDetails['creator']['profile'] !=
                                                              null &&
                                                          topicDetails['creator']['profile']['image'] !=
                                                              null &&
                                                          topicDetails['creator']['profile']['image']
                                                              .isNotEmpty)
                                                      ? NetworkImage(
                                                        topicDetails['creator']['profile']['image'],
                                                      )
                                                      : AssetImage(
                                                            AppImages
                                                                .placeHolderImage,
                                                          )
                                                          as ImageProvider<
                                                            Object
                                                          >,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height:
                                        Localization.textDirection ==
                                                TextDirection.rtl
                                            ? 30.0
                                            : 15.0,
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              topicDetails.isNotEmpty &&
                                                      topicDetails['creator'] !=
                                                          null &&
                                                      topicDetails['creator']['profile'] !=
                                                          null
                                                  ? topicDetails['creator']['profile']['first_name'] ??
                                                      ' '
                                                  : ' ',
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
                                                fontWeight: FontWeight.w600,
                                                fontStyle: FontStyle.normal,
                                              ),
                                            ),
                                            Localization.textDirection ==
                                                    TextDirection.rtl
                                                ? Row(
                                                  children: [
                                                    if (topicDetails.isEmpty ||
                                                        (topicDetails['votes_count'] ==
                                                                null ||
                                                            topicDetails['votes_count'] ==
                                                                0)) ...[
                                                      GestureDetector(
                                                        onTap: submitVote,
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 14,
                                                                vertical: 8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors: [
                                                                AppColors
                                                                    .beginGradientColor,
                                                                AppColors
                                                                    .endGradientColor,
                                                              ],
                                                            ),
                                                            border: Border.all(
                                                              color:
                                                                  AppColors
                                                                      .whiteColor,
                                                              width: 2,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10.0,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            '${Localization.translate("vote")}',
                                                            style: TextStyle(
                                                              color:
                                                                  AppColors
                                                                      .whiteColor,
                                                              fontSize:
                                                                  FontSize.scale(
                                                                    context,
                                                                    14,
                                                                  ),
                                                              fontFamily:
                                                                  AppFontFamily
                                                                      .regularFont,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .normal,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                    Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal:
                                                            topicDetails['votes_count'] ==
                                                                    0
                                                                ? 14
                                                                : 25,
                                                        vertical: 8,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppColors.greyColor(
                                                              context,
                                                            ).withOpacity(0.2),
                                                        borderRadius:
                                                            topicDetails['votes_count'] ==
                                                                    0
                                                                ? BorderRadius.horizontal(
                                                                  left:
                                                                      Radius.circular(
                                                                        10,
                                                                      ),
                                                                )
                                                                : BorderRadius.circular(
                                                                  10.0,
                                                                ),
                                                      ),
                                                      child: Text(
                                                        topicDetails.isNotEmpty &&
                                                                topicDetails['votes_count'] !=
                                                                    null
                                                            ? topicDetails['votes_count']
                                                                .toString()
                                                            : '0',
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
                                                          fontStyle:
                                                              FontStyle.normal,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                                : Padding(
                                                  padding: EdgeInsets.only(
                                                    top:
                                                        Localization.textDirection ==
                                                                TextDirection
                                                                    .rtl
                                                            ? 10.0
                                                            : 8.0,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal:
                                                                  topicDetails['votes_count'] ==
                                                                          0
                                                                      ? 14
                                                                      : 25,
                                                              vertical: 8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              AppColors.greyColor(
                                                                context,
                                                              ).withOpacity(
                                                                0.2,
                                                              ),
                                                          borderRadius:
                                                              topicDetails['votes_count'] ==
                                                                      0
                                                                  ? BorderRadius.horizontal(
                                                                    left:
                                                                        Radius.circular(
                                                                          10,
                                                                        ),
                                                                  )
                                                                  : BorderRadius.circular(
                                                                    10.0,
                                                                  ),
                                                        ),
                                                        child: Text(
                                                          topicDetails.isNotEmpty &&
                                                                  topicDetails['votes_count'] !=
                                                                      null
                                                              ? topicDetails['votes_count']
                                                                  .toString()
                                                              : '0',
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
                                                            fontStyle:
                                                                FontStyle
                                                                    .normal,
                                                          ),
                                                        ),
                                                      ),
                                                      if (topicDetails
                                                              .isEmpty ||
                                                          (topicDetails['votes_count'] ==
                                                                  null ||
                                                              topicDetails['votes_count'] ==
                                                                  0))
                                                        GestureDetector(
                                                          onTap: submitVote,
                                                          child: Container(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      14,
                                                                  vertical: 8,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              gradient: LinearGradient(
                                                                colors: [
                                                                  AppColors
                                                                      .beginGradientColor,
                                                                  AppColors
                                                                      .endGradientColor,
                                                                ],
                                                              ),
                                                              border: Border.all(
                                                                color:
                                                                    AppColors
                                                                        .whiteColor,
                                                                width: 2,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    10.0,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              '${Localization.translate("vote")}',
                                                              style: TextStyle(
                                                                color:
                                                                    AppColors
                                                                        .whiteColor,
                                                                fontSize:
                                                                    FontSize.scale(
                                                                      context,
                                                                      14,
                                                                    ),
                                                                fontFamily:
                                                                    AppFontFamily
                                                                        .regularFont,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .normal,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          topicDetails.isNotEmpty &&
                                                  topicDetails['title'] != null
                                              ? topicDetails['title']
                                              : ' ',
                                          style: TextStyle(
                                            color: AppColors.blackColor,
                                            fontSize: FontSize.scale(
                                              context,
                                              18,
                                            ),
                                            fontFamily:
                                                AppFontFamily.mediumFont,
                                            fontWeight: FontWeight.w500,
                                            fontStyle: FontStyle.normal,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          topicDetails.isNotEmpty &&
                                                  topicDetails['description'] !=
                                                      null
                                              ? topicDetails['description']
                                              : ' ',
                                          style: TextStyle(
                                            color: AppColors.greyColor(context),
                                            fontSize: FontSize.scale(
                                              context,
                                              16,
                                            ),
                                            fontFamily:
                                                AppFontFamily.regularFont,
                                            fontWeight: FontWeight.w400,
                                            fontStyle: FontStyle.normal,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          '${Localization.translate("tags")}',
                                          style: TextStyle(
                                            color: AppColors.greyColor(context),
                                            fontSize: FontSize.scale(
                                              context,
                                              14,
                                            ),
                                            fontFamily:
                                                AppFontFamily.mediumFont,
                                            fontWeight: FontWeight.w500,
                                            fontStyle: FontStyle.normal,
                                          ),
                                        ),
                                        SizedBox(
                                          height:
                                              Localization.textDirection ==
                                                      TextDirection.rtl
                                                  ? 12
                                                  : 6,
                                        ),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children:
                                              topicDetails.isNotEmpty &&
                                                      topicDetails['tags'] !=
                                                          null
                                                  ? List<Widget>.from(
                                                    (topicDetails['tags']
                                                            as List<dynamic>)
                                                        .map((tag) {
                                                          final formattedTag =
                                                              tag
                                                                  .toString()
                                                                  .substring(
                                                                    0,
                                                                    1,
                                                                  )
                                                                  .toUpperCase() +
                                                              tag
                                                                  .toString()
                                                                  .substring(1);
                                                          return _buildTag(
                                                            formattedTag,
                                                            context,
                                                          );
                                                        }),
                                                  )
                                                  : [
                                                    Center(
                                                      child: Text(
                                                        '${Localization.translate("tags_unavailable").isNotEmpty == true ? Localization.translate("tags_unavailable") : "Tags Unavailable"}',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize:
                                                              FontSize.scale(
                                                                context,
                                                                12,
                                                              ),
                                                          fontFamily:
                                                              AppFontFamily
                                                                  .regularFont,
                                                          color:
                                                              AppColors.greyColor(
                                                                context,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                        ),
                                        const SizedBox(height: 10),
                                        Contributors(
                                          title:
                                              '${Localization.translate("contributors")}',
                                          imageUrls:
                                              contributorsImageUrl.isNotEmpty
                                                  ? contributorsImageUrl
                                                  : [''],
                                        ),
                                        SizedBox(height: 10),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal:
                                                Platform.isAndroid ? 10.0 : 0.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Row(
                                                children: [
                                                  Localization.textDirection ==
                                                          TextDirection.rtl
                                                      ? SvgPicture.asset(
                                                        AppImages.replyForward,
                                                        width: 15,
                                                        height: 15,
                                                      )
                                                      : SvgPicture.asset(
                                                        AppImages.reply,
                                                        width: 20,
                                                        height: 20,
                                                      ),
                                                  SizedBox(width: 10),
                                                  RichText(
                                                    text: TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              topicDetails.isNotEmpty &&
                                                                      topicDetails['comments_count'] !=
                                                                          null
                                                                  ? topicDetails['comments_count']
                                                                      .toString()
                                                                  : ' ',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize:
                                                                FontSize.scale(
                                                                  context,
                                                                  14,
                                                                ),
                                                            fontFamily:
                                                                AppFontFamily
                                                                    .mediumFont,
                                                            color:
                                                                AppColors.greyColor(
                                                                  context,
                                                                ),
                                                          ),
                                                        ),
                                                        TextSpan(text: " "),
                                                        TextSpan(
                                                          text:
                                                              "${Localization.translate("replies")}",
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontSize:
                                                                FontSize.scale(
                                                                  context,
                                                                  14,
                                                                ),
                                                            fontFamily:
                                                                AppFontFamily
                                                                    .regularFont,
                                                            color:
                                                                AppColors.greyColor(
                                                                  context,
                                                                ).withOpacity(
                                                                  0.8,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Spacer(),
                                              Row(
                                                children: [
                                                  Transform.translate(
                                                    offset:
                                                        Localization.textDirection ==
                                                                TextDirection
                                                                    .rtl
                                                            ? Offset(0, 2)
                                                            : Offset(0, 0),
                                                    child: SvgPicture.asset(
                                                      AppImages.showIcon,
                                                      width: 18,
                                                      height: 18,
                                                      color:
                                                          AppColors.orangeColor,
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  RichText(
                                                    text: TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              topicDetails.isNotEmpty &&
                                                                      topicDetails['views_count'] !=
                                                                          null
                                                                  ? topicDetails['views_count']
                                                                      .toString()
                                                                  : ' ',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize:
                                                                FontSize.scale(
                                                                  context,
                                                                  14,
                                                                ),
                                                            fontFamily:
                                                                AppFontFamily
                                                                    .mediumFont,
                                                            color:
                                                                AppColors.greyColor(
                                                                  context,
                                                                ),
                                                          ),
                                                        ),
                                                        TextSpan(text: " "),
                                                        TextSpan(
                                                          text:
                                                              "${Localization.translate("views")}",
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontSize:
                                                                FontSize.scale(
                                                                  context,
                                                                  14,
                                                                ),
                                                            fontFamily:
                                                                AppFontFamily
                                                                    .regularFont,
                                                            color:
                                                                AppColors.greyColor(
                                                                  context,
                                                                ).withOpacity(
                                                                  0.8,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height:
                                              Localization.textDirection ==
                                                      TextDirection.rtl
                                                  ? 8
                                                  : 10,
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal:
                                                Platform.isIOS ? 2.0 : 10.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Transform.translate(
                                                offset:
                                                    Localization.textDirection ==
                                                            TextDirection.rtl
                                                        ? Offset(0, 2)
                                                        : Offset(0, 0),
                                                child: SvgPicture.asset(
                                                  AppImages.activity,
                                                  width: 20,
                                                  height: 20,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          topicDetails.isNotEmpty &&
                                                                  topicDetails['updated_at'] !=
                                                                      null
                                                              ? formatDate(
                                                                topicDetails['updated_at']
                                                                    .toString(),
                                                              )
                                                              : ' ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize:
                                                            FontSize.scale(
                                                              context,
                                                              14,
                                                            ),
                                                        fontFamily:
                                                            AppFontFamily
                                                                .mediumFont,
                                                        color:
                                                            AppColors.greyColor(
                                                              context,
                                                            ),
                                                      ),
                                                    ),
                                                    TextSpan(text: " "),
                                                    TextSpan(
                                                      text:
                                                          "${Localization.translate("last_activity")}",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize:
                                                            FontSize.scale(
                                                              context,
                                                              14,
                                                            ),
                                                        fontFamily:
                                                            AppFontFamily
                                                                .regularFont,
                                                        color:
                                                            AppColors.greyColor(
                                                              context,
                                                            ).withOpacity(0.8),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Spacer(),
                                              Row(
                                                children: [
                                                  SvgPicture.asset(
                                                    AppImages.type,
                                                    width: 20,
                                                    height: 20,
                                                    color: AppColors.blueColor,
                                                  ),
                                                  SizedBox(width: 6),
                                                  RichText(
                                                    text: TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              topicDetails.isNotEmpty &&
                                                                      topicDetails['posts_count'] !=
                                                                          null
                                                                  ? topicDetails['posts_count']
                                                                      .toString()
                                                                  : ' ',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize:
                                                                FontSize.scale(
                                                                  context,
                                                                  14,
                                                                ),
                                                            fontFamily:
                                                                AppFontFamily
                                                                    .mediumFont,
                                                            color:
                                                                AppColors.greyColor(
                                                                  context,
                                                                ),
                                                          ),
                                                        ),
                                                        TextSpan(text: " "),
                                                        TextSpan(
                                                          text:
                                                              "${Localization.translate("posts")}",
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontSize:
                                                                FontSize.scale(
                                                                  context,
                                                                  14,
                                                                ),
                                                            fontFamily:
                                                                AppFontFamily
                                                                    .regularFont,
                                                            color:
                                                                AppColors.greyColor(
                                                                  context,
                                                                ).withOpacity(
                                                                  0.8,
                                                                ),
                                                          ),
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
                                  SizedBox(height: 20),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            RelatedTopicsCard(
                              title:
                                  Localization.translate(
                                            "related_topics",
                                          ).isNotEmpty ==
                                          true
                                      ? Localization.translate("related_topics")
                                      : 'Related Topics',
                              subtitle:
                                  Localization.translate(
                                            "related_discussion",
                                          ).isNotEmpty ==
                                          true
                                      ? Localization.translate(
                                        "related_discussion",
                                      )
                                      : 'Related Discussions in the Community',
                              imageUrls:
                                  relatedTopicsImage.isNotEmpty
                                      ? relatedTopicsImage
                                      : [],
                            ),
                            const SizedBox(height: 16),
                            comments.isEmpty
                                ? _buildRestrictedUI()
                                : ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: comments.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      padding: const EdgeInsets.only(
                                        left: 16.0,
                                        right: 16.0,
                                        bottom: 14.0,
                                      ),
                                      child: CommentWidget(
                                        comment: comments[index],
                                      ),
                                    );
                                  },
                                ),
                            SizedBox(height: 30),
                          ],
                        ),
                      ),
              floatingActionButton:
                  isLoading
                      ? FloatingActionButtonSkeleton()
                      : (comments.isEmpty)
                      ? null
                      : FloatingActionButton.extended(
                        elevation: 0.0,
                        onPressed: () => _showBottomSheet(context),
                        label: Transform.translate(
                          offset:
                              Localization.textDirection == TextDirection.rtl
                                  ? Offset(0, -5)
                                  : Offset(0, 0),
                          child: Text(
                            '${Localization.translate("reply")}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: AppFontFamily.mediumFont,
                              color: AppColors.whiteColor,
                            ),
                          ),
                        ),
                        icon:
                            Localization.textDirection == TextDirection.rtl
                                ? SvgPicture.asset(
                                  AppImages.replyForward,
                                  width: 15,
                                  height: 15,
                                  color: AppColors.whiteColor,
                                )
                                : SvgPicture.asset(
                                  AppImages.reply,
                                  width: 20,
                                  height: 20,
                                  color: AppColors.whiteColor,
                                ),
                        backgroundColor: AppColors.primaryGreen(context),
                      ),
            ),
          ),
        );
      },
    );
  }
}

Widget _buildTag(String text, BuildContext context) {
  return Container(
    margin: const EdgeInsets.only(right: 8.0),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.fadeColor,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: FontSize.scale(context, 12),
        fontFamily: AppFontFamily.regularFont,
        color: AppColors.greyColor(context),
      ),
    ),
  );
}
