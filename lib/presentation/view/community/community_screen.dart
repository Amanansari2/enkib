import 'package:flutter/material.dart';
import 'package:flutter_projects/presentation/view/community/skeleton/community_screen_skeleton.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';
import '../components/internet_alert.dart';
import '../components/login_required_alert.dart';
import 'community_detail.dart';
import 'component/bouncer.dart';

class CommunityPage extends StatefulWidget {
  final VoidCallback? onBackPressed;
  CommunityPage({this.onBackPressed});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  bool isLoading = false;

  Map<String, dynamic>? categoriesResponse;
  TextEditingController _searchController = TextEditingController();
  final _bounce = Bouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    fetchForums();
  }

  Future<void> fetchForums({String title = ''}) async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final categories = await getForums(token, sortBy: 'asc', title: title);

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
        categoriesResponse = categories;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchSearchForums({String title = ''}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final categories = await getForums(token, sortBy: 'asc', title: title);

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
        categoriesResponse = categories;
      });
    } catch (e) {}
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
              backgroundColor: AppColors.backgroundColor(context),
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(70.0),
                child: Container(
                  color: AppColors.whiteColor,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: AppBar(
                      backgroundColor: AppColors.whiteColor,
                      elevation: 0,
                      titleSpacing: 0,
                      forceMaterialTransparency: true,
                      title: Text(
                        Localization.translate("community") ?? "",
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 20),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      leading: Padding(
                        padding: const EdgeInsets.only(top: 3.0),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.arrow_back_ios,
                            size: 20,
                            color: AppColors.blackColor,
                          ),
                          onPressed: () {
                            if (widget.onBackPressed != null) {
                              widget.onBackPressed!();
                            }
                          },
                        ),
                      ),
                      centerTitle: false,
                    ),
                  ),
                ),
              ),
              body:
                  isLoading
                      ? CommunityPageSkeleton()
                      : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.only(left: 15, right: 15.0),
                              decoration: BoxDecoration(
                                color: AppColors.whiteColor,
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(20.0),
                                  bottomLeft: Radius.circular(20.0),
                                ),
                              ),
                              child: Container(
                                padding: EdgeInsets.only(
                                  left: 20.0,
                                  top: 30,
                                  right: 20,
                                  bottom:
                                      Localization.textDirection ==
                                              TextDirection.rtl
                                          ? 55.0
                                          : 35.0,
                                ),
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(AppImages.forumBg),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Localization.translate(
                                        "welcome_community",
                                      ),
                                      style: TextStyle(
                                        color: AppColors.blackColor,
                                        fontSize: FontSize.scale(context, 20),
                                        fontFamily: AppFontFamily.mediumFont,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      Localization.translate("join_community"),
                                      style: TextStyle(
                                        color: AppColors.greyColor(context),
                                        fontSize: FontSize.scale(context, 14),
                                        fontFamily: AppFontFamily.regularFont,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Container(
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width -
                                              150,
                                          child: CustomTextField(
                                            hint: Localization.translate(
                                              "search_discussions",
                                            ),
                                            controller: _searchController,
                                            mandatory: false,
                                            onChanged: (value) {
                                              _bounce.run(() {
                                                String searchQuery =
                                                    _searchController.text
                                                        .trim();
                                                fetchSearchForums(
                                                  title: searchQuery,
                                                );
                                              });
                                            },
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap:
                                              _searchController.text
                                                      .trim()
                                                      .isEmpty
                                                  ? null
                                                  : () {
                                                    String searchQuery =
                                                        _searchController.text
                                                            .trim();
                                                    fetchForums(
                                                      title: searchQuery,
                                                    );
                                                  },
                                          child: Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color:
                                                  _searchController.text
                                                          .trim()
                                                          .isEmpty
                                                      ? AppColors.fadeColor
                                                      : AppColors.primaryGreen(
                                                        context,
                                                      ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                15.0,
                                              ),
                                              child: SvgPicture.asset(
                                                AppImages.search,
                                                width: 18,
                                                height: 18,
                                                color: AppColors.whiteColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10.0,
                              ),
                              child: Text(
                                Localization.translate("forums"),
                                style: TextStyle(
                                  color: AppColors.blackColor,
                                  fontSize: FontSize.scale(context, 18),
                                  fontFamily: AppFontFamily.mediumFont,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 1.0,
                              ),
                              child: Text(
                                Localization.translate("browse_forums"),
                                style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 14),
                                  fontFamily: AppFontFamily.regularFont,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            SizedBox(height: 10.0),
                            if (categoriesResponse != null &&
                                categoriesResponse!['data'] != null &&
                                categoriesResponse!['data'].isNotEmpty)
                              ...categoriesResponse!['data'].map<Widget>((
                                category,
                              ) {
                                return _buildSection(
                                  category['name'],
                                  category['forums'],
                                  _getColorFromLabelColor(
                                    category['label_color'],
                                  ),
                                );
                              }).toList()
                            else
                              Center(
                                child: Text(
                                  '${Localization.translate("forums_not_found")}',
                                  style: TextStyle(
                                    color: AppColors.blackColor,
                                    fontSize: FontSize.scale(context, 16),
                                    fontFamily: AppFontFamily.mediumFont,
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
    );
  }

  Color _getColorFromLabelColor(String colorString) {
    try {
      return Color(int.parse(colorString));
    } catch (e) {
      return AppColors.greyColor(context);
    }
  }

  Widget _buildSection(String title, List<dynamic> forums, Color titleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 5.0),
          child: Container(
            padding:
                Localization.textDirection == TextDirection.rtl
                    ? EdgeInsets.only(bottom: 8, left: 18, right: 10, top: 8)
                    : EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: titleColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: FontSize.scale(context, 12),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        forums.isEmpty
            ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '${Localization.translate("forums_not_found")}',
                  style: TextStyle(
                    color: AppColors.greyColor(context),
                    fontSize: FontSize.scale(context, 14),
                    fontFamily: AppFontFamily.regularFont,
                  ),
                ),
              ),
            )
            : ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: forums.length,
              itemBuilder: (context, index) {
                final forum = forums[index];
                return _buildForumCard(
                  forum['media'] != null && forum['media'].isNotEmpty
                      ? forum['media'][0]['path']
                      : 'placeholder_image_path',
                  forum['title'],
                  forum['description'],
                  forum['topics_count'].toString(),
                  forum['posts_count'].toString(),
                  forum['slug'],
                  forum['id'].toString(),
                );
              },
            ),
      ],
    );
  }

  Widget _buildForumCard(
    String imagePath,
    String title,
    String subtitle,
    String topics,
    String posts,
    String slug,
    String id,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityDetail(slug: slug, id: id),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 8.0,
                ),
                child: Container(
                  width: 100,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    image: DecorationImage(
                      image:
                          (imagePath != null && imagePath.isNotEmpty)
                              ? NetworkImage(imagePath)
                              : AssetImage(AppImages.placeHolderImage)
                                  as ImageProvider<Object>,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: FontSize.scale(context, 14),
                                fontFamily: AppFontFamily.mediumFont,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Localization.textDirection == TextDirection.rtl
                              ? SvgPicture.asset(
                                AppImages.arrowTopLeft,
                                width: 15,
                                height: 15,
                                color: AppColors.blueColor,
                              )
                              : SvgPicture.asset(
                                AppImages.arrowTopRight,
                                width: 20,
                                height: 20,
                                color: AppColors.blueColor,
                              ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.regularFont,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          SvgPicture.asset(
                            AppImages.type,
                            width: 20,
                            height: 20,
                            color: AppColors.primaryGreen(context),
                          ),
                          SizedBox(width: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: topics,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: FontSize.scale(context, 14),
                                    fontFamily: AppFontFamily.mediumFont,
                                    color: AppColors.greyColor(context),
                                  ),
                                ),
                                TextSpan(text: " "),
                                TextSpan(
                                  text: "${Localization.translate("topics")}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: FontSize.scale(context, 14),
                                    fontFamily: AppFontFamily.regularFont,
                                    color: AppColors.greyColor(
                                      context,
                                    ).withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          SvgPicture.asset(
                            AppImages.posts,
                            width: 20,
                            height: 20,
                            color: AppColors.redColor,
                          ),
                          SizedBox(width: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: posts,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: FontSize.scale(context, 14),
                                    fontFamily: AppFontFamily.mediumFont,
                                    color: AppColors.greyColor(context),
                                  ),
                                ),
                                TextSpan(text: " "),
                                TextSpan(
                                  text: "${Localization.translate("posts")}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: FontSize.scale(context, 14),
                                    fontFamily: AppFontFamily.regularFont,
                                    color: AppColors.greyColor(
                                      context,
                                    ).withOpacity(0.7),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
