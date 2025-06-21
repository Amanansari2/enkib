import 'package:flutter/material.dart';
import 'package:flutter_projects/data/localization/localization.dart';
import 'package:flutter_projects/data/provider/auth_provider.dart';
import 'package:flutter_projects/domain/api_structure/api_service.dart';
import 'package:flutter_projects/presentation/view/components/login_required_alert.dart';
import 'package:flutter_projects/presentation/view/dispute/component/dispute_card.dart';
import 'package:flutter_projects/presentation/view/dispute/dispute_detail.dart';
import 'package:provider/provider.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../../../styles/app_styles.dart';
import '../auth/login_screen.dart';
import '../components/internet_alert.dart';
import 'component/dispute_listing_skeleton.dart';

class DisputeListing extends StatefulWidget {
  const DisputeListing({super.key});

  @override
  State<DisputeListing> createState() => _DisputeListingState();
}

class _DisputeListingState extends State<DisputeListing> {
  List<dynamic> disputes = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  int totalPages = 1;
  int totalDispute = 0;

  @override
  void initState() {
    super.initState();
    fetchDisputes();
  }

  Future<void> fetchDisputes({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        setState(() {
          isLoadingMore = true;
        });
      } else {
        setState(() {
          isLoading = true;
        });
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await getDisputeListing(token!, page: currentPage);

      if (response['status'] == 200) {
        final newDisputes = response['data']['list'];
        final pagination = response['data']['pagination'];

        setState(() {
          if (isLoadMore) {
            disputes.addAll(newDisputes);
          } else {
            disputes = newDisputes;
          }

          totalPages = pagination['totalPages'];
          currentPage = pagination['currentPage'];
          totalDispute = pagination['total'];
          isLoading = false;
          isLoadingMore = false;
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
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch disputes');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _loadMoreDisputes() {
    if (currentPage < totalPages && !isLoadingMore) {
      currentPage++;
      fetchDisputes(isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final String? role =
        userData != null && userData['user'] != null
            ? userData['user']['role']
            : null;
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
                      forceMaterialTransparency: true,
                      elevation: 0,
                      titleSpacing: 0,
                      title: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(Localization.translate('manage_dispute') ?? '').trim() != 'manage_dispute' && (Localization.translate('manage_dispute') ?? '').trim().isNotEmpty ? Localization.translate('manage_dispute') : 'Manage dispute'}',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: AppColors.blackColor,
                              fontSize: FontSize.scale(context, 20),
                              fontFamily: AppFontFamily.mediumFont,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "${disputes.length} / ${totalDispute}",
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
                                      '${((Localization.translate('dispute') ?? '').trim() != 'dispute' && (Localization.translate('dispute') ?? '').trim().isNotEmpty ? Localization.translate('dispute') : 'Dispute')}${totalDispute > 1 ? 's' : ''}',
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
                        padding: const EdgeInsets.only(top: 3.0),
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
                      centerTitle: false,
                    ),
                  ),
                ),
              ),
              body:
                  isLoading
                      ? ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return DisputeListingSkeleton();
                        },
                      )
                      : disputes.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: AssetImage(
                                AppImages.disputeEmpty,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${(Localization.translate('dispute_empty') ?? '').trim() != 'dispute_empty' && (Localization.translate('dispute_empty') ?? '').trim().isNotEmpty ? Localization.translate('dispute_empty') : 'No Disputes Found'}',
                              style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: FontSize.scale(context, 14),
                                fontFamily: AppFontFamily.mediumFont,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                      : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels ==
                                  scrollInfo.metrics.maxScrollExtent &&
                              !isLoadingMore) {
                            _loadMoreDisputes();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          itemCount:
                              isLoadingMore
                                  ? disputes.length + 1
                                  : disputes.length,
                          itemBuilder: (context, index) {
                            if (index == disputes.length) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryGreen(context),
                                    strokeWidth: 2.0,
                                  ),
                                ),
                              );
                            }

                            final dispute = disputes[index];
                            final disputeId = dispute['id'];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            DisputeDetails(id: disputeId),
                                  ),
                                );
                              },
                              child: DisputeCard(
                                disputeId: dispute['uuid'] as String,
                                name:
                                    role == "student"
                                        ? dispute['responsible_by']['profile']['full_name']
                                            as String
                                        : dispute['creator_by']['profile']['full_name']
                                            as String,
                                dateCreated: dispute['created_at'] as String,
                                reason: dispute['dispute_title'] as String,
                                status: getStatusText(
                                  dispute['status'] as String,
                                ),
                                statusColor: _getStatusColor(dispute['status']),
                                statusColorBackground: _getStatusBgColor(
                                  dispute['status'],
                                ),
                                profileImageUrl:
                                    role == "student"
                                        ? dispute['responsible_by']['profile']['image']
                                            as String
                                        : dispute['creator_by']['profile']['image']
                                            as String,
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'closed':
        return AppColors.statusCloseText;
      case 'under_review':
        return AppColors.statusInDiscussionText;
      case 'pending':
        return AppColors.statusPendingText;
      default:
        return AppColors.statusOpenText;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'closed':
        return AppColors.statusCloseBg;
      case 'under_review':
        return AppColors.statusInDiscussionBg;
      case 'pending':
        return AppColors.statusPendingBg;
      default:
        return AppColors.statusOpenBg;
    }
  }
}

String getStatusText(String status) {
  switch (status) {
    case "closed":
      return '${(Localization.translate('closed_status') ?? '').trim() != 'closed_status' && (Localization.translate('closed_status') ?? '').trim().isNotEmpty ? Localization.translate('closed_status') : 'Closed'}';
    case "under_review":
      return '${(Localization.translate('under_review_status') ?? '').trim() != 'under_review_status' && (Localization.translate('under_review_status') ?? '').trim().isNotEmpty ? Localization.translate('under_review_status') : 'Under Review'}';
    case "pending":
      return '${(Localization.translate('pending_status') ?? '').trim() != 'pending_status' && (Localization.translate('pending_status') ?? '').trim().isNotEmpty ? Localization.translate('pending_status') : 'Pending'}';
    case "in_discussion":
      return '${(Localization.translate('in_discussion_status') ?? '').trim() != 'in_discussion_status' && (Localization.translate('in_discussion_status') ?? '').trim().isNotEmpty ? Localization.translate('in_discussion_status') : 'In Discussion'}';
    default:
      return '${(Localization.translate('unknown_status') ?? '').trim() != 'unknown_status' && (Localization.translate('unknown_status') ?? '').trim().isNotEmpty ? Localization.translate('unknown_status') : 'Unknown'}';
  }
}
