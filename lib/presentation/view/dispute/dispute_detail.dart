import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../../../data/provider/settings_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import '../../../styles/app_styles.dart';
import '../auth/login_screen.dart';
import '../components/internet_alert.dart';
import '../components/login_required_alert.dart';
import 'component/dispute_details_skeleton.dart';
import 'dispute_chat/dispute_chat_screen.dart';

class DisputeDetails extends StatefulWidget {
  final int id;

  const DisputeDetails({Key? key, required this.id}) : super(key: key);

  @override
  State<DisputeDetails> createState() => _DisputeDetailsState();
}

class _DisputeDetailsState extends State<DisputeDetails> {
  String? errorMessage;
  Map<String, dynamic>? disputeDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDisputeDetails();
  }

  Future<void> _fetchDisputeDetails() async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw '${Localization.translate("unauthorized_access")}';
      }

      final response = await getDisputeDetail(token, widget.id);

      if (response['status'] == 200) {
        setState(() {
          disputeDetails = response['data'];
          isLoading = false;
        });
      } else if (response['status'] == 401) {
        showCustomToast(
            context, '${Localization.translate("unauthorized_access")}', false);
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
      } else {
        throw Exception(response['message'] ?? '');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      rethrow;
    }
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    final studentName = settingsProvider.getSetting('data')?['_lernen']
            ?['student_display_name'] ??
        'Student';
    final tutorName = settingsProvider.getSetting('data')?['_lernen']
            ?['tutor_display_name'] ??
        '';

    String translatedText = Localization.translate("session");
    String formattedText = capitalizeFirstLetter(translatedText);

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
                    title: Text(
                      '${(Localization.translate('dispute_details') ?? '').trim() != 'dispute_details' && (Localization.translate('dispute_details') ?? '').trim().isNotEmpty ? Localization.translate('dispute_details') : 'Dispute details'}',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: AppColors.blackColor,
                        fontSize: FontSize.scale(context, 20),
                        fontFamily: AppFontFamily.mediumFont,
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
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    centerTitle: false,
                  ),
                ),
              ),
            ),
            body: isLoading
                ? DisputeDetailsSkeleton()
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: AppColors.whiteColor,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.greyColor(context)
                                      .withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      disputeDetails?['uuid'] ?? '',
                                      style: TextStyle(
                                        color: AppColors.blackColor,
                                        fontSize: FontSize.scale(context, 16),
                                        fontFamily: AppFontFamily.mediumFont,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.0, vertical: 4.0),
                                      decoration: BoxDecoration(
                                        color: _getStatusBgColor(
                                            disputeDetails?['status']),
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8.0,
                                            height: 8.0,
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                  disputeDetails?['status']),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: 4.0),
                                          Text(
                                            getStatusText(
                                                disputeDetails?['status']
                                                    as String),
                                            style: TextStyle(
                                              color: _getStatusColor(
                                                  disputeDetails?['status']),
                                              fontWeight: FontWeight.w500,
                                              fontSize:
                                                  FontSize.scale(context, 12),
                                              fontFamily:
                                                  AppFontFamily.mediumFont,
                                              fontStyle: FontStyle.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                InfoRow(
                                    label:
                                        '${(Localization.translate('date_created') ?? '').trim() != 'date_created' && (Localization.translate('date_created') ?? '').trim().isNotEmpty ? Localization.translate('date_created') : 'Date Created'}',
                                    value: disputeDetails?['created_at'] ?? ''),
                                SizedBox(
                                  height: 20,
                                ),
                                InfoRow(
                                    label:
                                        '${(Localization.translate('reason') ?? '').trim() != 'reason' && (Localization.translate('reason') ?? '').trim().isNotEmpty ? Localization.translate('reason') : 'Reason'}',
                                    value:
                                        disputeDetails?['dispute_title'] ?? ''),
                                SizedBox(
                                  height: 20,
                                ),
                                InfoRow(
                                  label: '$formattedText',
                                  value: disputeDetails?['subject'] ?? '',
                                  subValue: disputeDetails?['group'] ?? '',
                                  startTime: disputeDetails?['start_time'],
                                  endTime: disputeDetails?['end_time'],
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                InfoRow(
                                  label: tutorName ?? 'Tutor',
                                  value: disputeDetails?['responsible_by']
                                          ['profile']['full_name'] ??
                                      '',
                                  withAvatar: true,
                                  imageUrl: disputeDetails?['responsible_by']
                                          ['profile']['image'] ??
                                      '',
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                InfoRow(
                                  label: studentName ?? 'Student',
                                  value: disputeDetails?['creator_by']
                                          ['profile']['full_name'] ??
                                      '',
                                  withAvatar: true,
                                  imageUrl: disputeDetails?['creator_by']
                                          ['profile']['image'] ??
                                      '',
                                ),
                                SizedBox(height: 20.0),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DisputeChatScreen(
                                          id: disputeDetails?['id'],
                                          disputeId: disputeDetails?['uuid'],
                                          status: disputeDetails?['status'],
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.primaryGreen(context),
                                    minimumSize: Size(double.infinity, 45),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "${(Localization.translate('start_chat') ?? '').trim() != 'start_chat' && (Localization.translate('start_chat') ?? '').trim().isNotEmpty ? Localization.translate('start_chat') : 'Start chat'}",
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 16),
                                          color: AppColors.whiteColor,
                                          fontFamily: AppFontFamily.mediumFont,
                                          fontWeight: FontWeight.w500,
                                          fontStyle: FontStyle.normal,
                                        ),
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
          ),
        ),
      );
    });
  }
}

class InfoRow extends StatelessWidget {
  final String? label;
  final String? value;
  final bool withAvatar;
  final String? imageUrl;
  final String? subValue;
  final String? startTime;
  final String? endTime;

  InfoRow({
    required this.label,
    required this.value,
    this.subValue,
    this.startTime,
    this.endTime,
    this.withAvatar = false,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label ?? '',
            style: TextStyle(
              fontSize: FontSize.scale(context, 14),
              color: AppColors.greyColor(context),
              fontFamily: AppFontFamily.regularFont,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: FontSize.scale(context, 14),
                        color: AppColors.greyColor(context),
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subValue != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "($subValue) ${startTime ?? ''} - ${endTime ?? ''}",
                          style: TextStyle(
                            fontSize: FontSize.scale(context, 12),
                            color: AppColors.greyColor(context),
                            fontFamily: AppFontFamily.regularFont,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                  ],
                ),
              ),
              if (withAvatar)
                Padding(
                  padding: EdgeInsets.only(
                      left: 8.0,
                      right: Localization.textDirection == TextDirection.rtl
                          ? 8.0
                          : 0.0),
                  child: CircleAvatar(
                    radius: 12.0,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: NetworkImage(
                      imageUrl ?? '',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
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
