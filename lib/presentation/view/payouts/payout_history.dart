import 'package:flutter/material.dart';
import 'package:flutter_projects/presentation/view/payouts/skeleton/payout_history_skeleton.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:provider/provider.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import '../auth/login_screen.dart';
import '../components/login_required_alert.dart';

class PayoutsHistory extends StatefulWidget {
  @override
  State<PayoutsHistory> createState() => _PayoutsHistoryState();
}

class _PayoutsHistoryState extends State<PayoutsHistory> {
  late double screenWidth;
  late double screenHeight;
  bool _isLoading = false;
  bool isRefreshing = false;
  int currentPage = 1;
  int page = 1;
  int totalPages = 1;
  bool isLoadingMore = false;
  int totalPayouts = 0;

  List<Map<String, dynamic>> payout = [];

  Future<void> _fetchPayouts({bool isLoadMore = false}) async {
    if ((isLoadMore && (currentPage > totalPages || isLoadingMore)) ||
        currentPage <= 0) {
      return;
    }

    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
        payout.clear();
        currentPage = 1;
      });
    } else {
      setState(() {
        isLoadingMore = true;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userId;

      if (token != null && userId != null) {
        final response = await getPayouts(token, userId, page: currentPage);

        if (response['status'] == 401) {
          showCustomToast(
            context,
            '${Localization.translate("unauthorized_access")}',
            false,
          );
          setState(() {
            _isLoading = false;
          });

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
          setState(() {
            if (response.containsKey('data') &&
                response['data']['list'] is List) {
              List<Map<String, dynamic>> newPayouts =
                  List<Map<String, dynamic>>.from(response['data']['list']);
              if (isLoadMore) {
                payout.addAll(newPayouts);
                currentPage++;
              } else {
                payout = newPayouts;
              }
              totalPages = response['data']['pagination']['totalPages'];
              totalPayouts = response['data']['pagination']['total'];
            }
            _isLoading = false;
            isLoadingMore = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> refreshPayouts() async {
    try {
      setState(() {
        isRefreshing = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userId;

      final response = await getPayouts(token!, userId!, page: 1);

      if (response['status'] == 200) {
        if (response.containsKey('data') && response['data']['list'] is List) {
          setState(() {
            payout = List<Map<String, dynamic>>.from(response['data']['list']);
          });
        }
      } else if (response['status'] == 401) {
        showCustomToast(
          context,
          Localization.translate("unauthorized_access"),
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
        isRefreshing = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPayouts();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    return Directionality(
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
                      '${(Localization.translate('payouts_history') ?? '').trim() != 'payouts_history' && (Localization.translate('payouts_history') ?? '').trim().isNotEmpty ? Localization.translate('payouts_history') : 'Payout History'}',
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
                            text: "${payout.length} / ${totalPayouts}",
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 12),
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              fontFamily: AppFontFamily.mediumFont,
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
            _isLoading
                ? PayoutsHistorySkeleton()
                : payout.isEmpty
                ? Center(
                  child: Text(
                    Localization.translate("empty_payouts"),
                    style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 16),
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFontFamily.mediumFont,
                    ),
                  ),
                )
                : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: refreshPayouts,
                        color: AppColors.primaryGreen(context),
                        child: Stack(
                          children: [
                            if (payout.isNotEmpty || _isLoading) ...[
                              NotificationListener<ScrollNotification>(
                                onNotification: (
                                  ScrollNotification scrollInfo,
                                ) {
                                  if (scrollInfo.metrics.pixels ==
                                          scrollInfo.metrics.maxScrollExtent &&
                                      !isLoadingMore &&
                                      payout.isNotEmpty &&
                                      currentPage < totalPages) {
                                    _fetchPayouts(isLoadMore: true);
                                  }
                                  return false;
                                },
                                child: ListView.builder(
                                  padding: EdgeInsets.all(16),
                                  itemCount:
                                      isLoadingMore
                                          ? payout.length + 1
                                          : payout.length,
                                  itemBuilder: (context, index) {
                                    if (index == payout.length) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          right: 10.0,
                                          left: 10,
                                          top: 10,
                                          bottom: 50,
                                        ),
                                        child:
                                            isLoadingMore
                                                ? Center(
                                                  child: CircularProgressIndicator(
                                                    color:
                                                        AppColors.primaryGreen(
                                                          context,
                                                        ),
                                                    strokeWidth: 2.0,
                                                  ),
                                                )
                                                : SizedBox.shrink(),
                                      );
                                    }
                                    return PayoutHistoryCard(
                                      payout: payout[index],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class PayoutHistoryCard extends StatelessWidget {
  final Map<String, dynamic> payout;

  const PayoutHistoryCard({required this.payout});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusTextColor;
    String status = payout['status'] ?? 'unknown';

    String capitalizedStatus =
        status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1).toLowerCase()
            : status;

    switch (status.toLowerCase()) {
      case 'paid':
        statusColor = AppColors.completeStatusColor;
        statusTextColor = AppColors.completeStatusTextColor;
        break;
      case 'declined':
        statusColor = AppColors.redBorderColor;
        statusTextColor = AppColors.redColor;
        break;
      case 'pending':
        statusColor = AppColors.pendingStatusColor;
        statusTextColor = AppColors.blueColor;
        break;
      default:
        statusColor = AppColors.greyColor(context);
        statusTextColor = AppColors.greyColor(context);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.12,
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: '${Localization.translate("ref")}',
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                              fontFamily: AppFontFamily.regularFont,
                            ),
                          ),
                          TextSpan(text: ' '),
                          TextSpan(
                            text: '${payout['id']}',
                            style: TextStyle(
                              color: AppColors.blackColor,
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                              fontFamily: AppFontFamily.regularFont,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      ' /  ${payout['created_at'].toString().substring(0)}',
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 13),
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                        fontFamily: AppFontFamily.regularFont,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 17, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    capitalizedStatus,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: FontSize.scale(context, 12),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.normal,
                      fontFamily: AppFontFamily.mediumFont,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text.rich(
                  TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: '${Localization.translate("method")}',
                        style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                          fontFamily: AppFontFamily.regularFont,
                        ),
                      ),
                      TextSpan(text: ' '),
                      TextSpan(
                        text: '${payout['payout_method'] ?? ''}',
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                          fontFamily: AppFontFamily.regularFont,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 15),
                Text.rich(
                  TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: '${Localization.translate("amount")}',
                        style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                          fontFamily: AppFontFamily.regularFont,
                        ),
                      ),
                      TextSpan(text: ' '),
                      TextSpan(
                        text: '${payout['amount'] ?? '0.00'}',
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 14),
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
          ],
        ),
      ),
    );
  }
}
