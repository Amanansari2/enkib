import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../../../data/localization/localization.dart';
import '../../../../data/provider/auth_provider.dart';
import '../../../../data/provider/settings_provider.dart';
import '../../../../domain/api_structure/api_service.dart';
import '../../auth/login_screen.dart';
import '../../components/login_required_alert.dart';
import '../payment_methods.dart';

class OrderSummaryBottomSheet extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final Map<String, dynamic> profileDta;
  final List<Map<String, dynamic>> cartData;
  final String total;
  final String subtotal;

  const OrderSummaryBottomSheet({
    Key? key,
    required this.sessionData,
    required this.profileDta,
    required this.cartData,
    required this.total,
    required this.subtotal,
  }) : super(key: key);

  @override
  _OrderSummaryBottomSheetState createState() =>
      _OrderSummaryBottomSheetState();
}

class _OrderSummaryBottomSheetState extends State<OrderSummaryBottomSheet> {
  List<Map<String, dynamic>> _sessions = [];
  String _subtotal = "";
  String _grandTotal = "";

  @override
  void initState() {
    super.initState();
    _sessions = widget.cartData;
    _subtotal = widget.subtotal;
    _grandTotal = widget.total;
  }

  void _recalculateTotals() {
    double newSubtotal = 0.0;

    for (var item in _sessions) {
      String priceString = item['price'].toString();
      String numericPrice = priceString.replaceAll(RegExp(r'[^0-9.]'), '');
      double itemPrice = double.tryParse(numericPrice) ?? 0.0;
      newSubtotal += itemPrice;
    }

    setState(() {
      _subtotal =
          _sessions.isEmpty
              ? ""
              : _sessions.first['price'][0] + newSubtotal.toStringAsFixed(2);
      _grandTotal =
          _sessions.isEmpty
              ? ""
              : _sessions.first['price'][0] + newSubtotal.toStringAsFixed(2);
    });
  }

  Future<void> _removeSessionDirectly(int index) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final int sessionId = _sessions[index]['id'];

    if (token != null) {
      try {
        final response = await deleteBookingCart(token, sessionId);

        if (response['status'] == 200) {
          setState(() {
            _sessions.removeAt(index);
            _recalculateTotals();
          });

          showCustomToast(
            context,
            response['message'] ??
                '${Localization.translate("session_removed")}',
            true,
          );
        } else if (response['status'] == 403) {
          showCustomToast(context, response['message'], false);
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
          showCustomToast(
            context,
            response['message'] ??
                '${Localization.translate("failed_book_session")}',
            false,
          );
        }
      } catch (e) {
        showCustomToast(
          context,
          '${Localization.translate("error_message")} $e',
          false,
        );
      }
    } else {
      showCustomToast(
        context,
        '${Localization.translate("unauthorized_access")}',
        false,
      );
    }
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

    if (mounted) {
      Overlay.of(context).insert(overlayEntry);
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Localization.textDirection,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${Localization.translate("order_summary")}',
                    style: TextStyle(
                      fontSize: FontSize.scale(context, 18),
                      color: AppColors.blackColor,
                      fontFamily: AppFontFamily.mediumFont,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.dividerColor, thickness: 2, height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    if (_sessions.isEmpty)
                      Center(
                        child: Text(
                          '${Localization.translate("empty_cart")}',
                          style: TextStyle(
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFontFamily.mediumFont,
                            color: AppColors.greyColor(context),
                          ),
                        ),
                      )
                    else
                      ..._sessions.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> session = entry.value;
                        Map<String, dynamic> itemCart = session;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  itemCart['session_time'] ??
                                      itemCart['category'],
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 14),
                                    fontFamily: AppFontFamily.mediumFont,
                                    color: AppColors.greyColor(context),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),

                                Text(
                                  itemCart['price'] ?? '',
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 16),
                                    fontFamily: AppFontFamily.mediumFont,
                                    color: AppColors.blackColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    itemCart['item_name'] ?? '',
                                    style: TextStyle(
                                      fontSize: FontSize.scale(context, 16),
                                      fontFamily: AppFontFamily.mediumFont,
                                      color: AppColors.blackColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed:
                                      () => _removeSessionDirectly(index),
                                  child: Text(
                                    '${Localization.translate("remove")}',
                                    style: TextStyle(
                                      fontSize: FontSize.scale(context, 14),
                                      color: AppColors.redColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            itemCart['subject_group'] != null &&
                                    itemCart['subject_group']
                                        .toString()
                                        .isNotEmpty
                                ? Text(
                                  itemCart['subject_group'],
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 14),
                                    fontFamily: AppFontFamily.mediumFont,
                                    color: AppColors.greyColor(context),
                                    fontWeight: FontWeight.w400,
                                  ),
                                )
                                : SizedBox.shrink(),
                            SizedBox(height: 2),
                            if (index != _sessions.length - 1)
                              Divider(
                                color: AppColors.dividerColor,
                                thickness: 1,
                              ),
                          ],
                        );
                      }).toList(),
                    SizedBox(height: 15),

                    if (_subtotal != null &&
                        _subtotal.toString().isNotEmpty) ...[
                      Divider(
                        color: AppColors.dividerColor,
                        thickness: 2,
                        height: 1,
                      ),
                      SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${Localization.translate("subtotal")}',
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: AppFontFamily.mediumFont,
                              color: AppColors.greyColor(context),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            _subtotal.isEmpty ? '' : '$_subtotal',
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: AppFontFamily.mediumFont,
                              color: AppColors.greyColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (_grandTotal != null &&
                        _grandTotal.toString().isNotEmpty) ...[
                      SizedBox(height: 20),
                      Divider(
                        color: AppColors.dividerColor,
                        thickness: 2,
                        height: 1,
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${Localization.translate("grand_total")}',
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 16),
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFontFamily.mediumFont,
                              color: AppColors.greyColor(context),
                            ),
                          ),
                          Text(
                            _grandTotal.isEmpty ? '' : '$_grandTotal',
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 18),
                              fontFamily: AppFontFamily.mediumFont,
                              color: AppColors.blackColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed:
                          (_subtotal == null ||
                                  _subtotal.toString().isEmpty ||
                                  _grandTotal == null ||
                                  _grandTotal.toString().isEmpty)
                              ? null
                              : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PaymentScreen(
                                          cartData: _sessions,
                                          sessionData: widget.sessionData,
                                        ),
                                  ),
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (_subtotal == null ||
                                    _subtotal.toString().isEmpty ||
                                    _grandTotal == null ||
                                    _grandTotal.toString().isEmpty)
                                ? AppColors.fadeColor
                                : AppColors.primaryGreen(context),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      child: Text(
                        '${Localization.translate("proceed_order")}',
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 16),
                          color: AppColors.whiteColor,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFontFamily.mediumFont,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen(
                              context,
                            ).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: SvgPicture.asset(
                            AppImages.lockIcon,
                            width: 20,
                            height: 20,
                            color: AppColors.primaryGreen(context),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${Localization.translate("secure_payment_title")}',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 14),
                              color: AppColors.greyColor(
                                context,
                              ).withOpacity(0.7),
                              fontFamily: AppFontFamily.mediumFont,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
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
