import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/daos/order_dao.dart';
import '../../database/daos/product_dao.dart';
import '../../database/daos/user_dao.dart';
import '../../database/repositories/order_repository.dart';
import '../../models/enums/order_status.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/shimmer_box.dart';

enum ReportFilter { day, week, month, year }

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  late final OrderRepository _orderRepository;
  late final ProductDao _productDao;
  late final UserDao _userDao;

  bool _isLoading = true;
  ReportFilter _selectedFilter = ReportFilter.week;

  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _newCustomers = 0;
  int _lowStockCount = 0;

  List<Map<String, dynamic>> _chartData = [];

  static const Color _chartColor = AppColors.primary;
  static const Color _gridColor = Color(0xFFE0E0E0);
  static const Color _textSecondary = AppColors.textSecondary;

  @override
  void initState() {
    super.initState();
    _orderRepository = OrderRepository(orderDao: OrderDao());
    _productDao = ProductDao();
    _userDao = UserDao();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    final (startDate, endDate) = _getDateRange(_selectedFilter);
    final allOrders = await _orderRepository.getAllOrders();

    double revenue = 0;
    int orderCount = 0;
    List<Map<String, dynamic>> chartData = _generateEmptyChartData();

    for (final order in allOrders) {
      final statusStr = order['order_status']?.toString().toUpperCase() ?? '';
      final isCompleted = _isCompletedStatus(statusStr);
      final createdAt = order['created_at'];
      DateTime? orderDate;

      if (createdAt is int) {
        orderDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
      } else if (createdAt is String) {
        orderDate = DateTime.tryParse(createdAt);
      }

      if (orderDate != null &&
          orderDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          orderDate.isBefore(endDate.add(const Duration(days: 1)))) {
        orderCount++;
        if (isCompleted) {
          final total = (order['total'] as num?)?.toDouble() ?? 0;
          revenue += total;
          _aggregateToChart(chartData, orderDate, total);
        }
      }
    }

    final newCustomers = await _userDao.countNewCustomers(startDate, endDate);
    final lowStock = await _productDao.countLowStockProducts();

    if (!mounted) return;
    setState(() {
      _totalRevenue = revenue;
      _totalOrders = orderCount;
      _newCustomers = newCustomers;
      _lowStockCount = lowStock;
      _chartData = chartData;
      _isLoading = false;
    });
  }

  bool _isCompletedStatus(String status) {
    return status == OrderStatus.DELIVERED.name ||
        status == 'COMPLETED' ||
        status == 'COMPLETE';
  }

  (DateTime, DateTime) _getDateRange(ReportFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case ReportFilter.day:
        return (today, today.add(const Duration(days: 1)));
      case ReportFilter.week:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return (startOfWeek, endOfWeek);
      case ReportFilter.month:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1);
        return (startOfMonth, endOfMonth);
      case ReportFilter.year:
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year + 1, 1, 1);
        return (startOfYear, endOfYear);
    }
  }

  List<Map<String, dynamic>> _generateEmptyChartData() {
    switch (_selectedFilter) {
      case ReportFilter.day:
        return List.generate(24, (i) => {'label': '$i:00', 'revenue': 0.0});
      case ReportFilter.week:
        return List.generate(7, (i) => {
          'label': ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][i],
          'revenue': 0.0
        });
      case ReportFilter.month:
        final now = DateTime.now();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        return List.generate(daysInMonth, (i) => {'label': '${i + 1}', 'revenue': 0.0});
      case ReportFilter.year:
        return List.generate(12, (i) => {
          'label': ['T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12'][i],
          'revenue': 0.0
        });
    }
  }

  void _aggregateToChart(List<Map<String, dynamic>> chartData, DateTime date, double revenue) {
    switch (_selectedFilter) {
      case ReportFilter.day:
        final hour = date.hour;
        if (hour >= 0 && hour < chartData.length) {
          chartData[hour]['revenue'] = (chartData[hour]['revenue'] as double) + revenue;
        }
        break;
      case ReportFilter.week:
        final dayIndex = date.weekday - 1;
        if (dayIndex >= 0 && dayIndex < chartData.length) {
          chartData[dayIndex]['revenue'] = (chartData[dayIndex]['revenue'] as double) + revenue;
        }
        break;
      case ReportFilter.month:
        final dayIndex = date.day - 1;
        if (dayIndex >= 0 && dayIndex < chartData.length) {
          chartData[dayIndex]['revenue'] = (chartData[dayIndex]['revenue'] as double) + revenue;
        }
        break;
      case ReportFilter.year:
        final monthIndex = date.month - 1;
        if (monthIndex >= 0 && monthIndex < chartData.length) {
          chartData[monthIndex]['revenue'] = (chartData[monthIndex]['revenue'] as double) + revenue;
        }
        break;
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return NumberFormat('#,###').format(value.toInt());
  }

  String _formatFullCurrency(double value) {
    return NumberFormat('#,###', 'vi_VN').format(value.toInt());
  }

  void _onFilterChanged(ReportFilter? filter) {
    if (filter != null && filter != _selectedFilter) {
      setState(() => _selectedFilter = filter);
      _loadReportData();
    }
  }

  void _showChartDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChartDetailSheet(
        chartData: _chartData,
        filter: _selectedFilter,
        totalRevenue: _totalRevenue,
        formatCurrency: _formatFullCurrency,
        formatShortCurrency: _formatCurrency,
      ),
    );
  }

  int _getLabelInterval() {
    switch (_selectedFilter) {
      case ReportFilter.day:
        return 4;
      case ReportFilter.week:
        return 1;
      case ReportFilter.month:
        return 5;
      case ReportFilter.year:
        return 1;
    }
  }

  bool _shouldShowLabel(int index) {
    final interval = _getLabelInterval();
    if (_selectedFilter == ReportFilter.week) return true;
    return index % interval == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Báo cáo thống kê', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadReportData,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 3,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: ShimmerListItem(height: 120, borderRadius: 12),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildFilterButtons(),
                        const SizedBox(height: 20),
                        _buildStatGrid(constraints.maxWidth),
                        const SizedBox(height: 24),
                        _buildRevenueChart(constraints.maxWidth),
                        const SizedBox(height: 24),
                        _buildLowStockSection(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHeader() {
    String periodLabel;
    switch (_selectedFilter) {
      case ReportFilter.day:
        periodLabel = 'Hôm nay';
        break;
      case ReportFilter.week:
        periodLabel = 'Tuần này';
        break;
      case ReportFilter.month:
        periodLabel = 'Tháng này';
        break;
      case ReportFilter.year:
        periodLabel = 'Năm nay';
        break;
    }

    return Row(
      children: [
        const Icon(Icons.calendar_month, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          'Tổng quan $periodLabel',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(ReportFilter.day, 'Ngày', Icons.today),
          const SizedBox(width: 8),
          _buildFilterChip(ReportFilter.week, 'Tuần', Icons.date_range),
          const SizedBox(width: 8),
          _buildFilterChip(ReportFilter.month, 'Tháng', Icons.calendar_view_month),
          const SizedBox(width: 8),
          _buildFilterChip(ReportFilter.year, 'Năm', Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ReportFilter filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onFilterChanged(filter),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : _textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : _textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatGrid(double screenWidth) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Doanh thu', _formatCurrency(_totalRevenue), 'đ', Icons.attach_money_rounded, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Đơn hàng', _totalOrders.toString(), 'đơn', Icons.shopping_bag_rounded, Colors.blue)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Khách mới', _newCustomers.toString(), 'người', Icons.people_rounded, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Sắp hết hàng', _lowStockCount.toString(), 'sản phẩm', Icons.inventory_2_rounded, Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(unit, style: const TextStyle(fontSize: 12, color: _textSecondary)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(double chartWidth) {
    final maxRevenue = _chartData.fold<double>(0, (max, item) {
      final revenue = (item['revenue'] as double?) ?? 0;
      return revenue > max ? revenue : max;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart_rounded, color: _chartColor),
            const SizedBox(width: 8),
            const Text(
              'Biểu đồ doanh thu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Spacer(),
            if (_totalRevenue > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Tổng: ${_formatCurrency(_totalRevenue)}đ',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Bấm vào biểu đồ để xem chi tiết',
          style: TextStyle(fontSize: 11, color: _textSecondary.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showChartDetail,
          child: Container(
            height: 260,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (maxRevenue > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, right: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Đơn vị: ${_formatCurrency(maxRevenue)}đ',
                          style: const TextStyle(fontSize: 10, color: _textSecondary),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _buildChartBars(maxRevenue),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartBars(double maxRevenue) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxHeight - 20;
        final barCount = _chartData.length;
        final spacing = barCount > 15 ? 2.0 : (barCount > 7 ? 3.0 : 4.0);
        final totalSpacing = spacing * (barCount - 1);
        final barWidth = ((constraints.maxWidth - totalSpacing - 16) / barCount).clamp(6.0, 40.0);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(barCount, (index) {
            final revenue = (_chartData[index]['revenue'] as double?) ?? 0;
            final barHeight = maxRevenue > 0 ? (revenue / maxRevenue) * chartHeight : 0.0;
            final label = _chartData[index]['label']?.toString() ?? '';
            final showLabel = _shouldShowLabel(index);
            final isYear = _selectedFilter == ReportFilter.year;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (revenue > 0)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatCurrency(revenue),
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                        ),
                      ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: barWidth,
                      height: barHeight.clamp(0, chartHeight - 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_chartColor, _chartColor.withValues(alpha: 0.7)],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (showLabel)
                      Transform.rotate(
                        angle: isYear ? math.pi / 4 : 0,
                        child: Text(
                          label,
                          style: TextStyle(fontSize: isYear ? 8 : 10, fontWeight: FontWeight.w500, color: _textSecondary),
                          textAlign: isYear ? TextAlign.right : TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildLowStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Sản phẩm sắp hết hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const Spacer(),
            Text('$_lowStockCount sản phẩm', style: const TextStyle(fontSize: 12, color: _textSecondary)),
          ],
        ),
        const SizedBox(height: 12),
        if (_lowStockCount == 0)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('Tất cả sản phẩm đều có đủ hàng!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.inventory_2, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cần nhập thêm hàng', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('Còn $_lowStockCount sản phẩm có số lượng dưới 5', style: const TextStyle(fontSize: 12, color: _textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChartDetailSheet extends StatelessWidget {
  final List<Map<String, dynamic>> chartData;
  final ReportFilter filter;
  final double totalRevenue;
  final String Function(double) formatCurrency;
  final String Function(double) formatShortCurrency;

  const _ChartDetailSheet({
    required this.chartData,
    required this.filter,
    required this.totalRevenue,
    required this.formatCurrency,
    required this.formatShortCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxRevenue = chartData.fold<double>(0, (max, item) {
      final revenue = (item['revenue'] as double?) ?? 0;
      return revenue > max ? revenue : max;
    });

    return Container(
      height: screenHeight * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.analytics_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chi tiết doanh thu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      if (totalRevenue > 0)
                        Text(
                          'Tổng: ${formatCurrency(totalRevenue)}đ',
                          style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: math.max(chartData.length * 60.0 + 40, MediaQuery.of(context).size.width - 32),
                    height: screenHeight * 0.5,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final chartHeight = constraints.maxHeight - 60;
                        final barCount = chartData.length;
                        final barWidth = 40.0;
                        final spacing = 20.0;
                        final totalWidth = barCount * (barWidth + spacing);

                        return Column(
                          children: [
                            if (maxRevenue > 0)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'Đơn vị: ${formatShortCurrency(maxRevenue)}đ',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(barCount, (index) {
                                  final revenue = (chartData[index]['revenue'] as double?) ?? 0;
                                  final barHeight = maxRevenue > 0 ? (revenue / maxRevenue) * chartHeight : 0.0;
                                  final label = chartData[index]['label']?.toString() ?? '';

                                  return Container(
                                    width: barWidth,
                                    margin: EdgeInsets.only(right: spacing),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (revenue > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryDark,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              formatShortCurrency(revenue),
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 500),
                                          width: barWidth,
                                          height: barHeight.clamp(0, chartHeight - 40),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                                            ),
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          label,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
