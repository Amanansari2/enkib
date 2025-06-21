import 'package:flutter/material.dart';
import 'package:flutter_projects/domain/api_structure/api_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/settings_provider.dart';
import 'chat_screen.dart';

class ChatPusherService extends ChangeNotifier {
  final String id;
  late PusherChannelsFlutter pusher;
  bool isConnected = false;
  final Function scrollToBottom;
  List<ChatMessage> messages = [];

  final Set<String> channels = {};

  final Function(String eventName, String eventData) onEventReceived;

  ChatPusherService({required this.id,required this.scrollToBottom,
    required this.onEventReceived,

  }) {
    pusher = PusherChannelsFlutter.getInstance();
  }


  Future<void> initialize(BuildContext context) async {
    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      String? apiKey = settingsProvider.getSetting('data')?['broadcasting']?['key'];
      String? cluster = settingsProvider.getSetting('data')?['broadcasting']?['options']?['cluster'];

      if (apiKey == null || cluster == null) {
        return;
      }
      pusher = PusherChannelsFlutter.getInstance();
      await pusher.init(
        apiKey: apiKey,
        cluster: cluster,
        onConnectionStateChange: onConnectionStateChange,
        onError: onError,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onEvent: _handleIncomingEvent,
        onSubscriptionError: onSubscriptionError,
        onDecryptionFailure: onDecryptionFailure,
        onMemberAdded: onMemberAdded,
        onMemberRemoved: onMemberRemoved,
        onSubscriptionCount: onSubscriptionCount,
        onAuthorizer: (channelName, socketId, options) => onAuthorizer(channelName, socketId, options, context),
      );

      await pusher.connect();
      isConnected = true;
      subscribeToPublicEvents();
      subscribeToPrivateEvents(context);
    } catch (e) {
    }
  }

  void onConnectionStateChange(dynamic currentState, dynamic previousState) {

    if (currentState == "DISCONNECTED") {
      pusher.connect();
    }
  }

  dynamic onAuthorizer(String channelName, String socketId, dynamic options, BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;
    var authUrl = "$baseUrl/broadcasting/auth";

    try {

      var result = await http.post(
        Uri.parse(authUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'socket_id': socketId,
          'channel_name': 'private-events-${userId}',
        },
      );

      if (result.statusCode == 200) {
        var json = jsonDecode(result.body);
        return json;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> subscribeToPublicEvents() async {
    try {
      await pusher.subscribe(channelName: 'events');
      final channel = pusher.getChannel('events');
      if (channel != null) {
        channel.onEvent?.call((event) {
          logEventResponse(event);
          if (event.eventName == 'user-is-online') {
          } else if (event.eventName == 'user-is-offline') {
          }
        });
      }
    } catch (e) {
    }
  }

  Future<void> subscribeToPrivateEvents(BuildContext context) async {
    if (!isConnected) {
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;
      await pusher.subscribe(channelName: 'private-events-$userId');
      final channel = pusher.getChannel('private-events-$userId');
      if (channel != null) {
        channel.onEvent?.call((event) {
          _handleIncomingEvent(event);
        });
      }
      for (var channelName in channels) {
        await pusher.subscribe(channelName: 'private-$channelName');
        final channel = pusher.getChannel('private-$channelName');
        if (channel != null) {
          channel.onEvent?.call((event) {
            _handleIncomingEvent(event);
          });
        }
      }
    } catch (e) {
    }
  }

  void _handleIncomingEvent(PusherEvent event) {
    try {
      if (event.data is String) {
        final parsedData = jsonDecode(event.data);
        onEventReceived(event.eventName, event.data);

        if (event.eventName == 'message-received') {
          if (parsedData.containsKey('message') && parsedData['message'] != null) {
            final messageData = parsedData['message'];

            final messageBody = messageData['body'] ?? 'No message';

            if (messageBody.isNotEmpty) {
              final message = ChatMessage.fromJson(messageData);

              messages.add(message);
              notifyListeners();

              scrollToBottom();
            }
          } else {
          }
        }
      } else {
      }
    } catch (e) {
    }
  }

  Future<void> disconnect() async {
    await pusher.disconnect();
  }

  void onError(String message, int? code, dynamic e) {
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
  }

  void onSubscriptionError(String message, dynamic e) {
  }

  void onDecryptionFailure(String event, String reason) {
  }

  void onMemberAdded(String channelName, PusherMember member) {
  }

  void onMemberRemoved(String channelName, PusherMember member) {
  }

  void onSubscriptionCount(String channelName, int count) {
  }

  void logEventResponse(PusherEvent event) {
  }

  void addChannel(String channelName) {
    channels.add(channelName);
  }

  void removeChannel(String channelName) {
    channels.remove(channelName);
  }
}



