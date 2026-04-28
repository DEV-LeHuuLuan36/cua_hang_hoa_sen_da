import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../database/daos/notification_dao.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final NotificationDao _notificationDao = NotificationDao();
  bool _isInitialized = false;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    if (navigatorKey.currentState == null) return;

    switch (payload) {
      case 'order_list':
        navigatorKey.currentState?.pushNamed('/order-list');
        break;
      case 'admin_order_list':
        navigatorKey.currentState?.pushNamed('/admin-order-list');
        break;
      default:
        break;
    }
  }

  Future<void> showOrderSuccess({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'order_channel',
      'Đơn hàng',
      channelDescription: 'Thông báo về đơn hàng',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    await _notificationDao.insertNotification(
      id: 'notif_$notificationId',
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> showNotification({
    required String id,
    required String title,
    String? body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general_channel',
      'Thông báo chung',
      channelDescription: 'Thông báo chung',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id.hashCode,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    await _notificationDao.insertNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
