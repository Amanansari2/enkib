import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../base_components/custom_toast.dart';
import '../../domain/api_structure/api_service.dart';
import '../../presentation/view/auth/login_screen.dart';
import '../../presentation/view/components/login_required_alert.dart';
import '../localization/localization.dart';
import 'auth_provider.dart';

class DisputeDiscussionProvider with ChangeNotifier {
  bool isLoading = true;
  List<dynamic> disputeDiscussion = [];
  String userProfileImage = "";
  String userFullName = "${Localization.translate("loading")}";
  String lastChattedTime = "";
  bool onlineStatus = false;


  Future<void> fetchDisputeDiscussion(BuildContext context, String token, int id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      isLoading = true;
      notifyListeners();

      final response = await getDisputeDiscussion(token, id);

      if (response['status'] == 200) {
        final List<dynamic> data = response['data'];
        disputeDiscussion = data;

        final userId = authProvider.userId;

        String selectedProfileImage = "";
        String selectedFullName = "";
        String selectedLastChattedTime = "";
        bool selectedOnlineStatus = false;

        for (var message in data) {
          if (message['user']['id'] != userId) {
            selectedProfileImage = message['user']['profile']['image'] ?? "";
            selectedFullName = message['user']['profile']['full_name'] ?? "";
            selectedLastChattedTime = message['created_at'] ?? "";
            selectedOnlineStatus = message['user']['is_online'] ?? false;
            break;
          }
        }

        if (selectedFullName.isNotEmpty) {
          userProfileImage = selectedProfileImage;
          userFullName = selectedFullName;
          lastChattedTime = selectedLastChattedTime;
          onlineStatus = selectedOnlineStatus;
        }

      } else if (response['status'] == 401) {
        showCustomToast(context, Localization.translate("unauthorized_access"), false);
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
        throw Exception(response['message'] ?? '');
      }
    } catch (e) {
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

}

void showCustomToast(BuildContext context, String message, bool isSuccess) {
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 5.0,
      left: 16.0,
      right: 16.0,
      child: CustomToast(
        message: message,
        isSuccess: isSuccess,
      ),
    ),
  );

  Overlay.of(context).insert(overlayEntry);
  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}

