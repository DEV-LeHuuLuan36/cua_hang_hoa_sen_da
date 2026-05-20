import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/daos/notification_dao.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/theme_helper.dart';
import '../../../widgets/common/shimmer_box.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationDao _notificationDao = NotificationDao();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final notifications = await _notificationDao.getNotifications();
    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _markAsRead(String id) async {
    await _notificationDao.markAsRead(id);
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    await _notificationDao.markAllAsRead();
    _loadNotifications();
  }

  Future<void> _deleteNotification(String id) async {
    await _notificationDao.deleteNotification(id);
    _loadNotifications();
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  IconData _getIconForPayload(String? payload) {
    switch (payload) {
      case 'order_list':
        return Icons.shopping_bag_rounded;
      case 'admin_order_list':
        return Icons.admin_panel_settings_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      case 'system':
        return Icons.settings_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForPayload(String? payload) {
    switch (payload) {
      case 'order_list':
        return Colors.blue;
      case 'admin_order_list':
        return Colors.purple;
      case 'promo':
        return Colors.orange;
      case 'system':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ThemeHelper.background(context),
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_notifications.any((n) => n['is_read'] == 0))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Đọc hết', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ShimmerListItem(height: 72, borderRadius: 12),
                ),
              )
            : _notifications.isEmpty
                ? _buildEmptyState(isDark)
                : _buildNotificationList(isDark),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: isDark ? AppColors.darkBorder : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có thông báo nào',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkTextSecondary : Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các thông báo sẽ xuất hiện ở đây',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final isRead = notification['is_read'] == 1;
          final payload = notification['payload'] as String?;
          final color = _getColorForPayload(payload);
          final icon = _getIconForPayload(payload);

          return Dismissible(
            key: Key(notification['id'] as String),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: AppColors.error,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _deleteNotification(notification['id'] as String),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (!isRead) _markAsRead(notification['id'] as String);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isRead 
                        ? Colors.transparent 
                        : AppColors.primary.withValues(alpha: 0.05),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification['title'] as String? ?? '',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                      color: ThemeHelper.textPrimary(context),
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification['body'] as String? ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: ThemeHelper.textSecondary(context),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(notification['created_at'] as int),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade500,
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
          );
        },
      ),
    );
  }
}
