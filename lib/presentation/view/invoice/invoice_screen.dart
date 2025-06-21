import 'package:flutter/material.dart';
import 'package:flutter_projects/presentation/view/invoice/skeleton/invoices_screen_skeleton.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:provider/provider.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/settings_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import '../auth/login_screen.dart';
import '../components/login_required_alert.dart';

class InvoicesScreen extends StatefulWidget {
  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  late double screenWidth;
  late double screenHeight;
  List<Map<String, dynamic>> invoices = [];
  bool isLoading = false;
  bool isRefreshing = false;
  int currentPage = 1;
  int page = 1;
  int totalPages = 1;
  bool isLoadingMore = false;
  int totalInvoices = 0;

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }


  Future<void> _fetchInvoices({
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
          invoices.clear();
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
      final response = await getInvoices(token!, page: currentPage);

      if (response['status'] == 200) {
        if (response.containsKey('data') && response['data']['list'] is List) {
          setState(() {
            List<Map<String, dynamic>> newCourses =
            List<Map<String, dynamic>>.from(response['data']['list']);

            if (isPrevious) {
              invoices.insertAll(0, newCourses);
            } else {
              invoices.addAll(newCourses);
              currentPage++;
            }
            totalPages = response['data']['pagination']['totalPages'];
            totalInvoices = response['data']['pagination']['total'];
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
      } else {
      }
    } catch (e) {
    } finally {
      setState(() {
        isLoadingMore = false;
        isLoading = false;
      });
    }
  }


  Future<void> refreshInvoices() async {
    try {
      setState(() {
        isRefreshing = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getInvoices(token!, page: 1);

      if (response['status'] == 200) {
        if (response.containsKey('data') && response['data']['list'] is List) {
          setState(() {
            invoices = List<Map<String, dynamic>>.from(response['data']['list']);
          });
        }
      } else if (response['status'] == 401) {
        showCustomToast(
            context, Localization.translate("unauthorized_access"), false);
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
                forceMaterialTransparency: true,
                centerTitle: false,
                backgroundColor: AppColors.whiteColor,
                elevation: 0,
                titleSpacing: 0,
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(Localization.translate('invoices') ?? '').trim() != 'invoices' && (Localization.translate('invoices') ?? '').trim().isNotEmpty ? Localization.translate('invoices') : 'My Invoices'}',
                      style: TextStyle(
                        color: AppColors.blackColor,
                        fontSize: FontSize.scale(context, 20),
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${invoices.length} / ${totalInvoices}",
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
                    icon: Icon(Icons.arrow_back_ios,
                        size: 20, color: AppColors.blackColor),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        body: isLoading
            ? InvoicesScreenSkeleton()
            : invoices.isEmpty
                ? Center(
                    child: Text(
                      '${Localization.translate("unavailable_invoices")}',
                      style: TextStyle(
                        fontSize: FontSize.scale(context, 16),
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w500,
                        color: AppColors.greyColor(context),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: refreshInvoices,
                          color: AppColors.primaryGreen(context),
                          child: Stack(
                            children: [
                              if (invoices.isNotEmpty || isLoading)
                              NotificationListener(
                                onNotification:
                                    (ScrollNotification scrollInfo) {
                                  if (scrollInfo.metrics.pixels ==
                                      scrollInfo
                                          .metrics.maxScrollExtent &&
                                      !isLoadingMore &&
                                      invoices.isNotEmpty) {
                                    _fetchInvoices(isLoadMore: true);
                                  }
                                  return false;
                                },
                                child: ListView.builder(
                                  padding: EdgeInsets.all(16),
                                  itemCount: isLoadingMore
                                      ? invoices.length + 1
                                      : invoices.length,
                                  itemBuilder: (context, index) {
                                    if (index == invoices.length) {
                                      return Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              right: 10.0,
                                              left: 10,
                                              top: 10,
                                              bottom: 50),
                                          child: CircularProgressIndicator(
                                            color: AppColors.primaryGreen(
                                                context),
                                            strokeWidth: 2.0,
                                          ),
                                        ),
                                      );
                                    }
                                    return InvoiceCard(invoice: invoices[index]);
                                  },
                                ),
                              ),
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

class InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> invoice;

  const InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {

    final settingsProvider = Provider.of<SettingsProvider>(context);

    final tutorName =
    settingsProvider.getSetting('data')?['_lernen']?['tutor_display_name'];

    Color statusColor;
    Color statusTextColor;

    final status = invoice['status'] ?? '';
    final formattedStatus =
        status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : '';

    switch (status) {
      case 'complete':
        statusColor = AppColors.completeStatusColor;
        statusTextColor = AppColors.completeStatusTextColor;
        break;
      case 'processed':
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
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${Localization.translate("order")}',
                            style: TextStyle(
                                color: AppColors.greyColor(context),
                                fontSize: FontSize.scale(context, 14),
                                fontFamily: AppFontFamily.regularFont,
                                fontWeight: FontWeight.w400),
                          ),
                          TextSpan(
                            text: ' ',
                          ),
                          TextSpan(
                            text: '${invoice['order_id']}',
                            style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: FontSize.scale(context, 14),
                                fontFamily: AppFontFamily.regularFont,
                                fontWeight: FontWeight.w400),
                          ),
                          TextSpan(
                            text: '  ',
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '/  ${invoice['created_at'] ?? ''}',
                      style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 13),
                          fontFamily: AppFontFamily.regularFont,
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    formattedStatus,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: FontSize.scale(context, 12),
                      fontFamily: AppFontFamily.mediumFont,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${Localization.translate("transaction_id")}   ',
                  style: TextStyle(
                    color: AppColors.greyColor(context),
                    fontSize: FontSize.scale(context, 14),
                    fontFamily: AppFontFamily.regularFont,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Flexible(
                  child: Text(
                    '${invoice['transaction_id'] ?? ''}',
                    style: TextStyle(
                      color: AppColors.blackColor,
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: AppFontFamily.regularFont,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${tutorName}:',
                          style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: AppFontFamily.regularFont,
                              fontWeight: FontWeight.w400),
                        ),
                        TextSpan(
                          text: ' ',
                        ),
                        TextSpan(
                          text: '${invoice['tutor_name']}',
                          style: TextStyle(
                              color: AppColors.blackColor,
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: AppFontFamily.regularFont,
                              fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${Localization.translate("subject")}',
                          style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: AppFontFamily.regularFont,
                              fontWeight: FontWeight.w400),
                        ),
                        TextSpan(
                          text: ' ',
                        ),
                        TextSpan(
                          text: '${invoice['subject']}',
                          style: TextStyle(
                              color: AppColors.blackColor,
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: AppFontFamily.regularFont,
                              fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${Localization.translate("amount")}',
                    style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 14),
                        fontFamily: AppFontFamily.regularFont,
                        fontWeight: FontWeight.w400),
                  ),
                  TextSpan(
                    text: ' ',
                  ),
                  TextSpan(
                    text: '${invoice['price']}',
                    style: TextStyle(
                        color: AppColors.blackColor,
                        fontSize: FontSize.scale(context, 14),
                        fontFamily: AppFontFamily.regularFont,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
