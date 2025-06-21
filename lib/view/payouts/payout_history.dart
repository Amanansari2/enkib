import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/localization/localization.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/components/login_required_alert.dart';
import 'package:flutter_projects/view/payouts/skeleton/payout_history_skeleton.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';

class PayoutsHistory extends StatefulWidget {
  @override
  State<PayoutsHistory> createState() => _PayoutsHistoryState();
}

class _PayoutsHistoryState extends State<PayoutsHistory> {
  late double screenWidth;
  late double screenHeight;
  bool _isLoading = false;

  List<Map<String, dynamic>> payout = [];

  Future<void> _fetchPayouts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;

    if (token != null && userId != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await getPayouts(token, userId);
        if (response['status'] == 401) {
         showCustomToast(context,
              '${Localization.translate("unauthorized_access")}', false);
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

        }

        setState(() {
          payout = List<Map<String, dynamic>>.from(response['data']['list']);
          _isLoading = false;
        });
      }


      catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
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
                title: Text(
                  Localization.translate("payouts_history"),
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: FontSize.scale(context, 20),
                    fontFamily: AppFontFamily.font,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.normal,
                  ),
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
                centerTitle: false,
              ),
            ),
          ),
        ),
        body: _isLoading
            ? PayoutsHistorySkeleton()
            : payout.isEmpty
                ? Center(
                    child: Text(
                      Localization.translate("empty_payouts"),
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 16),
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFontFamily.font,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: payout.length,
                          itemBuilder: (context, index) {
                            return PayoutHistoryCard(payout: payout[index]);
                          },
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

    String capitalizedStatus = status.isNotEmpty
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
                              fontFamily: AppFontFamily.font,
                            ),
                          ),
                          TextSpan(
                            text: ' ',
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                              fontFamily: AppFontFamily.font,
                            ),
                          ),
                          TextSpan(
                            text: '${payout['id']}',
                            style: TextStyle(
                              color: AppColors.blackColor,
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                              fontFamily: AppFontFamily.font,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      ' /  ${payout['created_at'].toString().substring(0, 10)}',
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 13),
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                        fontFamily: AppFontFamily.font,
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
                      fontFamily: AppFontFamily.font,
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
                          fontFamily: AppFontFamily.font,
                        ),
                      ),
                      TextSpan(
                        text: ' ',
                        style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                          fontFamily: AppFontFamily.font,
                        ),
                      ),
                      TextSpan(
                        text: '${payout['payout_method'] ?? 'Unknown'}',
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                          fontFamily: AppFontFamily.font,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
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
                          fontFamily: AppFontFamily.font,
                        ),
                      ),
                      TextSpan(
                        text: ' ',
                        style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                          fontFamily: AppFontFamily.font,
                        ),
                      ),
                      TextSpan(
                        text: '${payout['amount'] ?? '0.00'}',
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                          fontFamily: AppFontFamily.font,
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
