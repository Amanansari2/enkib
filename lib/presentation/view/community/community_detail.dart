import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../components/internet_alert.dart';
import '../components/login_required_alert.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/localization/localization.dart';
import '../../../domain/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/presentation/view/community/component/comment_detail/forum_card.dart';
import 'package:flutter_projects/presentation/view/community/component/comment_detail/popular_topics_card.dart';
import 'package:flutter_projects/presentation/view/community/component/comment_detail/top_user_card.dart';
import 'package:flutter_projects/presentation/view/community/skeleton/community_detail_skeleton.dart';

class CommunityDetail extends StatefulWidget {
  final String slug;
  final String id;

  const CommunityDetail({Key? key, required this.slug, required this.id})
    : super(key: key);

  @override
  _CommunityDetailState createState() => _CommunityDetailState();
}

class _CommunityDetailState extends State<CommunityDetail> {
  int selectedTab = 0;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  late double screenWidth;
  late double screenHeight;

  bool isLoading = false;
  bool onPressLoading = false;
  Map<String, dynamic>? popularTopics;
  Map<String, dynamic>? topUsers;
  List<dynamic> topics = [];
  String? errorMessage;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPopularTopics();
    fetchTopUsers();
    fetchTopics();
  }

  Future<void> fetchPopularTopics() async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getPopularTopics(token);
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
        popularTopics = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchTopUsers() async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final categories = await getTopUsers(token);
      if (categories['status'] == 401) {
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
        topUsers = categories;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchTopics({String? filterType, String title = ''}) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final Map<String, dynamic> response = await getTopics(
        token,
        filterType: filterType,
        sortBy: 'asc',
        title: title,
        slug: widget.slug,
      );

      if (response['status'] == 200) {
        setState(() {
          topics = response['data'] ?? [];
          errorMessage = topics.isEmpty ? response['message'] : null;
          isLoading = false;
        });
      } else if (response['status'] == 401) {
        topics = [];
        isLoading = false;
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
          errorMessage = response['message'];
          topics = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred while fetching topics.';
        topics = [];
        isLoading = false;
      });
    }
  }

  Future<void> fetchTopicsSearch({
    String? filterType,
    String title = '',
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final Map<String, dynamic> response = await getTopics(
        token,
        filterType: filterType,
        sortBy: 'asc',
        title: title,
        slug: widget.slug,
      );

      if (response['status'] == 200) {
        setState(() {
          topics = response['data'] ?? [];
          errorMessage = topics.isEmpty ? response['message'] : null;
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
          errorMessage = response['message'];
          topics = [];
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred while fetching topics.';
        topics = [];
      });
    }
  }

  void _showBottomSheet(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController tagsController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    bool _isTitleValid = false;
    bool _isTagsValid = false;
    bool _isDescriptionValid = false;

    List<String> _tags = [];

    void _addTag(String tag, StateSetter setModalState) {
      if (tag.isNotEmpty && !_tags.contains(tag.trim())) {
        setModalState(() {
          _tags.add(tag.trim());
        });
        tagsController.clear();
      }
    }

    void _removeTag(String tag, StateSetter setModalState) {
      setModalState(() {
        _tags.remove(tag);
      });
    }

    bool _isPrivate = false;
    bool _isStatus = false;

    Future<void> _showPhotoActionSheet(StateSetter setModalState) async {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setModalState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }

    Future<void> _handleCreateTopic(StateSetter setModalState) async {
      try {
        setModalState(() {
          onPressLoading = true;
        });

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;

        setModalState(() {
          _isTitleValid = false;
          _isTagsValid = false;
          _isDescriptionValid = false;
        });

        if (titleController.text.isEmpty ||
            _tags.isEmpty ||
            descriptionController.text.isEmpty) {
          setModalState(() {
            if (titleController.text.isEmpty) _isTitleValid = true;
            if (_tags.isEmpty) _isTagsValid = true;
            if (descriptionController.text.isEmpty) _isDescriptionValid = true;
          });
          showCustomToast(
            context,
            "${Localization.translate("required_field")}",
            false,
          );
          return;
        }

        final response = await createTopic(
          token: token!,
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          tags: _tags,
          status: _isStatus ? true : false,
          type: _isPrivate ? true : false,
          forumId: widget.id,
          image: _selectedImage,
        );

        if (response['status'] == 200) {
          showCustomToast(context, response['message'], true);
          Navigator.pop(context);
          fetchTopics();
          setModalState(() {
            onPressLoading = false;
          });
        } else if (response['status'] == 401) {
          setModalState(() {
            onPressLoading = false;
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
              );
            },
          );
          return;
        } else if (response['status'] == 403) {
          setModalState(() {
            onPressLoading = false;
          });
          showCustomToast(context, response['message'], false);
        } else if (response['status'] == 422 && response['errors'] != null) {
          setModalState(() {
            onPressLoading = false;
          });
          final errors = response['errors'] as Map<String, dynamic>;
          setModalState(() {
            if (errors.containsKey('title')) _isTitleValid = true;
            if (errors.containsKey('tags')) _isTagsValid = true;
            if (errors.containsKey('description')) _isDescriptionValid = true;
          });
          errors.forEach((field, message) {
            showCustomToast(context, message.toString(), false);
          });
        } else {
          setModalState(() {
            onPressLoading = false;
          });
          showCustomToast(
            context,
            response['message'] ?? "Failed to create topic",
            false,
          );
        }
      } catch (e) {
        setModalState(() {
          onPressLoading = false;
        });
        showCustomToast(context, "An error occurred", false);
      } finally {
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
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.75,
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
                            '${Localization.translate("new_topic")}',
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
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(8.0),
                                color: AppColors.sheetBackgroundColor,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DottedBorder(
                                    color: AppColors.dividerColor,
                                    strokeWidth: 2.0,
                                    dashPattern: [12, 15],
                                    borderType: BorderType.RRect,
                                    radius: Radius.circular(12),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      width: screenWidth,
                                      decoration: BoxDecoration(
                                        color: AppColors.whiteColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              _showPhotoActionSheet(
                                                setModalState,
                                              );
                                            },
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                if (_selectedImage != null)
                                                  Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.rectangle,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      image: DecorationImage(
                                                        image: FileImage(
                                                          _selectedImage!,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  Image.asset(
                                                    AppImages.placeHolderImage,
                                                    fit: BoxFit.cover,
                                                    width: 50,
                                                    height: 50,
                                                  ),
                                                Positioned(
                                                  bottom: -8,
                                                  right: -8,
                                                  child: Container(
                                                    padding: EdgeInsets.all(2),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppColors.whiteColor,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color:
                                                            AppColors
                                                                .whiteColor,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        _showPhotoActionSheet(
                                                          setModalState,
                                                        );
                                                      },
                                                      child: CircleAvatar(
                                                        radius: 12,
                                                        backgroundColor:
                                                            AppColors.primaryGreen(
                                                              context,
                                                            ),
                                                        child: Icon(
                                                          Icons.add,
                                                          size: 16,
                                                          color:
                                                              AppColors
                                                                  .whiteColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 15),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${Localization.translate("upload_topic_image")}',
                                                  style: TextStyle(
                                                    color: AppColors.blackColor,
                                                    fontSize: FontSize.scale(
                                                      context,
                                                      13,
                                                    ),
                                                    fontFamily:
                                                        AppFontFamily
                                                            .regularFont,
                                                    fontWeight: FontWeight.w400,
                                                    fontStyle: FontStyle.normal,
                                                  ),
                                                ),
                                                Text(
                                                  '${Localization.translate("forum_image_extension")}',
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
                                                            .regularFont,
                                                    fontWeight: FontWeight.w400,
                                                    fontStyle: FontStyle.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  CustomTextField(
                                    hint:
                                        "${Localization.translate("add_title")}",
                                    mandatory: true,
                                    controller: titleController,
                                    hasError: _isTitleValid,
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Text(
                                        '${Localization.translate("select_topics_type")}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: FontSize.scale(context, 14),
                                          fontFamily: AppFontFamily.regularFont,
                                          color: AppColors.greyColor(context),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      SvgPicture.asset(
                                        AppImages.mandatory,
                                        height: 12.0,
                                        color: AppColors.redColor,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Container(
                                    height: 50,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.whiteColor,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.greyColor(
                                            context,
                                          ).withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${Localization.translate("private_type")}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: FontSize.scale(
                                              context,
                                              16,
                                            ),
                                            fontFamily:
                                                AppFontFamily.regularFont,
                                            color: AppColors.greyColor(context),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Transform.scale(
                                          scale: 0.9,
                                          child: Switch(
                                            value: _isPrivate,
                                            activeColor: AppColors.whiteColor,
                                            activeTrackColor:
                                                AppColors.blackColor,
                                            inactiveThumbColor:
                                                AppColors.whiteColor,
                                            inactiveTrackColor:
                                                AppColors.greyColor(
                                                  context,
                                                ).withOpacity(0.7),
                                            onChanged: (value) {
                                              setModalState(() {
                                                _isPrivate = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Text(
                                        '${Localization.translate("select_topics_status")} ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: FontSize.scale(context, 14),
                                          fontFamily: AppFontFamily.regularFont,
                                          color: AppColors.greyColor(context),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      SvgPicture.asset(
                                        AppImages.mandatory,
                                        height: 12.0,
                                        color: AppColors.redColor,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Container(
                                    height: 50,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.whiteColor,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.greyColor(
                                            context,
                                          ).withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${Localization.translate("inactive_status")}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: FontSize.scale(
                                              context,
                                              16,
                                            ),
                                            fontFamily:
                                                AppFontFamily.regularFont,
                                            color: AppColors.greyColor(context),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Transform.scale(
                                          scale: 0.9,
                                          child: Switch(
                                            value: _isStatus,
                                            activeColor: AppColors.whiteColor,
                                            activeTrackColor:
                                                AppColors.blackColor,
                                            inactiveThumbColor:
                                                AppColors.whiteColor,
                                            inactiveTrackColor:
                                                AppColors.greyColor(
                                                  context,
                                                ).withOpacity(0.7),
                                            onChanged: (value) {
                                              setModalState(() {
                                                _isStatus = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  CustomTextField(
                                    hint:
                                        "${Localization.translate("add_tags")}",
                                    mandatory: true,
                                    controller: tagsController,
                                    hasError: _isTagsValid,
                                    onChanged: (value) {
                                      if (value.endsWith(' ')) {
                                        _addTag(value.trim(), setModalState);
                                      }
                                    },
                                    onFieldSubmitted: (value) {
                                      _addTag(value.trim(), setModalState);
                                    },
                                  ),
                                  if (_tags.isNotEmpty) ...[
                                    SizedBox(height: 8),
                                  ],
                                  Wrap(
                                    spacing: 4.0,
                                    runSpacing: 2.0,
                                    children:
                                        _tags.map((tag) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4.0,
                                            ),
                                            child: Chip(
                                              label: Text(
                                                tag,
                                                style: TextStyle(
                                                  fontSize: FontSize.scale(
                                                    context,
                                                    14,
                                                  ),
                                                  color: AppColors.greyColor(
                                                    context,
                                                  ),
                                                  fontFamily:
                                                      AppFontFamily.mediumFont,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              backgroundColor:
                                                  AppColors.whiteColor,
                                              deleteIcon: Icon(
                                                Icons.close,
                                                color: AppColors.greyColor(
                                                  context,
                                                ),
                                                size: 20,
                                              ),
                                              onDeleted:
                                                  () => _removeTag(
                                                    tag,
                                                    setModalState,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                side: BorderSide(
                                                  color: AppColors.dividerColor,
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                  if (_tags.isEmpty) ...[SizedBox(height: 20)],
                                  if (_tags.isNotEmpty) ...[
                                    SizedBox(height: 8),
                                  ],
                                  CustomTextField(
                                    hint:
                                        "${Localization.translate("add_description")}",
                                    mandatory: true,
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
                                                    _handleCreateTopic(
                                                      setModalState,
                                                    );
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
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "${Localization.translate("save")}",
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
                                  SizedBox(height: 30),
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    List<String> popularTopicsImage = [];

    if (popularTopics != null && popularTopics!['status'] == 200) {
      final data = popularTopics!['data'] as List<dynamic>;
      if (data != null && data.isNotEmpty) {
        popularTopicsImage =
            data.map<String>((item) {
              final media = item['media'] as List<dynamic>?;
              return media != null && media.isNotEmpty
                  ? media[0]['path'] as String
                  : '';
            }).toList();
      }
    }

    List<String> topUsersImage = [];

    if (topUsers != null && topUsers!['status'] == 200) {
      final data = topUsers!['data'] as List<dynamic>;
      if (data != null && data.isNotEmpty) {
        topUsersImage =
            data.map<String>((item) {
              final image = item['image'] as String?;
              return image != null && image.isNotEmpty ? image : '';
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
                preferredSize: Size.fromHeight(80.0),
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
                      ? CommunityDetailSkeleton()
                      : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.whiteColor,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(20.0),
                                  bottomRight: Radius.circular(20.0),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15.0,
                                  vertical: 2,
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      child: Image.asset(
                                        AppImages.forumDetail,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height:
                                            Localization.textDirection ==
                                                    TextDirection.RTL
                                                ? 200
                                                : 180,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${Localization.translate("food_beverage")}',
                                            style: TextStyle(
                                              color: AppColors.blackColor,
                                              fontSize: FontSize.scale(
                                                context,
                                                20,
                                              ),
                                              fontFamily:
                                                  AppFontFamily.mediumFont,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '${Localization.translate("practical_forum")}',
                                            style: TextStyle(
                                              color: AppColors.greyColor(
                                                context,
                                              ),
                                              fontSize: FontSize.scale(
                                                context,
                                                14,
                                              ),
                                              fontFamily:
                                                  AppFontFamily.regularFont,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                          ElevatedButton(
                                            onPressed:
                                                () => _showBottomSheet(context),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primaryGreen(
                                                    context,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical: 12,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '${Localization.translate("new_topic")}',
                                                  style: TextStyle(
                                                    color: AppColors.whiteColor,
                                                    fontSize: FontSize.scale(
                                                      context,
                                                      16,
                                                    ),
                                                    fontFamily:
                                                        AppFontFamily
                                                            .mediumFont,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                SvgPicture.asset(
                                                  AppImages.type,
                                                  width: 20,
                                                  height: 20,
                                                  color: AppColors.whiteColor,
                                                ),
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
                            SizedBox(height: 20),
                            PopularTopicsCard(
                              title:
                                  '${Localization.translate("popular_topics")}',
                              subtitle:
                                  '${Localization.translate("related_discussions")}',
                              imageUrls:
                                  popularTopicsImage.isNotEmpty
                                      ? popularTopicsImage
                                      : [''],
                            ),
                            SizedBox(height: 10),
                            TopUsersCard(
                              title: '${Localization.translate('top_users')}',
                              subtitle:
                                  '${Localization.translate("engaged_members")}',
                              imageUrls:
                                  topUsersImage.isNotEmpty
                                      ? topUsersImage
                                      : [''],
                            ),
                            SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15.0,
                              ),
                              child: Text(
                                '${Localization.translate("topics")}',
                                style: TextStyle(
                                  color: AppColors.blackColor,
                                  fontSize: FontSize.scale(context, 18),
                                  fontFamily: AppFontFamily.mediumFont,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15.0,
                              ),
                              child: Text(
                                '${Localization.translate("different_topics")}',
                                style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 16),
                                  fontFamily: AppFontFamily.regularFont,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15.0,
                              ),
                              child: CustomTextField(
                                hint:
                                    '${Localization.translate("search_forums")}',
                                mandatory: false,
                                searchIcon: true,
                                controller: _searchController,
                                onChanged: (value) {
                                  fetchTopicsSearch(title: value);
                                },
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 16),
                              padding: EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.whiteColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.greyFadeColor.withOpacity(
                                      0.1,
                                    ),
                                    blurRadius: 2,
                                    spreadRadius: 1,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedTab = 0;
                                          fetchTopicsSearch();
                                        });
                                      },
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              selectedTab == 0
                                                  ? AppColors.greyFadeColor
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow:
                                              selectedTab == 0
                                                  ? [
                                                    BoxShadow(
                                                      color:
                                                          AppColors.greyColor(
                                                            context,
                                                          ).withOpacity(0.2),
                                                      blurRadius: 1,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ]
                                                  : [],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${Localization.translate("all")}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: FontSize.scale(
                                                context,
                                                14,
                                              ),
                                              fontFamily:
                                                  AppFontFamily.mediumFont,
                                              color:
                                                  selectedTab == 0
                                                      ? AppColors.blackColor
                                                      : AppColors.greyColor(
                                                        context,
                                                      ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedTab = 1;
                                          fetchTopicsSearch(filterType: 'my');
                                        });
                                      },
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              selectedTab == 1
                                                  ? AppColors.greyFadeColor
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow:
                                              selectedTab == 1
                                                  ? [
                                                    BoxShadow(
                                                      color:
                                                          AppColors.greyColor(
                                                            context,
                                                          ).withOpacity(0.2),
                                                      blurRadius: 1,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ]
                                                  : [],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${Localization.translate("my_topics")}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: FontSize.scale(
                                                context,
                                                14,
                                              ),
                                              fontFamily:
                                                  AppFontFamily.mediumFont,
                                              color:
                                                  selectedTab == 1
                                                      ? AppColors.blackColor
                                                      : AppColors.greyColor(
                                                        context,
                                                      ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            isLoading
                                ? CommunityDetailSkeleton()
                                : topics.isEmpty
                                ? Padding(
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    bottom: 50,
                                  ),
                                  child: Center(
                                    child: Text(
                                      errorMessage ?? 'No topics found',
                                      style: TextStyle(
                                        fontSize: FontSize.scale(context, 16),
                                        fontFamily: AppFontFamily.mediumFont,
                                        color: AppColors.greyColor(context),
                                      ),
                                    ),
                                  ),
                                )
                                : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                          selectedTab == 0
                                              ? const EdgeInsets.only(
                                                left: 16.0,
                                                top: 10.0,
                                                bottom: 10,
                                                right: 10,
                                              )
                                              : const EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                                vertical: 10.0,
                                              ),
                                      child: Text(
                                        selectedTab == 0
                                            ? '${Localization.translate("food")}'
                                            : '${Localization.translate("my_topics")}',
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: FontSize.scale(context, 14),
                                          fontFamily: AppFontFamily.mediumFont,
                                          color: AppColors.greyColor(context),
                                        ),
                                      ),
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: topics.length,
                                      itemBuilder: (context, index) {
                                        String formatDate(String dateTime) {
                                          try {
                                            final parsedDate = DateTime.parse(
                                              dateTime,
                                            );
                                            final formattedDate = DateFormat(
                                              'MMM yyyy, hh:mm a',
                                            ).format(parsedDate);
                                            return formattedDate;
                                          } catch (e) {
                                            return '';
                                          }
                                        }

                                        final topic = topics[index];
                                        return ForumCard(
                                          imageUrl: topic['media'] ?? '',
                                          profileImage:
                                              topic['creator']['profile']['image'] ??
                                              '',
                                          author:
                                              topic['creator']['profile']['first_name'] ??
                                              'Unknown',
                                          time: formatDate(
                                            topic['creator']['profile']['email_verified_at'] ??
                                                '',
                                          ),
                                          replies:
                                              topic['comments_count']
                                                  .toString(),
                                          postsCount:
                                              topic['posts_count'].toString(),
                                          views:
                                              topic['views_count'].toString(),
                                          title: topic['title'],
                                          description: topic['description'],
                                          slug: topic['slug'],
                                          id: topic['id'],
                                        );
                                      },
                                    ),
                                    SizedBox(height: 20),
                                  ],
                                ),
                          ],
                        ),
                      ),
            ),
          ),
        );
      },
    );
  }
}
