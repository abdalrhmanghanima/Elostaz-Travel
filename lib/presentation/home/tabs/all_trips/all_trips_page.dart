import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/core/utils/custom_loading.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/bus_info_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/bus_monthly_report_service.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/trip_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/widgets/driver_monthly_report_service.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/widgets/factory_monthly_report_service.dart';
import 'package:elostaz_travel/presentation/trip/provider/paginated_trips_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AllTripsPeriodType { all, currentMonth, previousMonth, customMonth }

enum AllTripsRecordType { all, trips, nightOutings }

final _selectedPeriodProvider =
    StateProvider<AllTripsPeriodType>((ref) => AllTripsPeriodType.all);

final _selectedRecordTypeProvider =
    StateProvider<AllTripsRecordType>((ref) => AllTripsRecordType.all);

final _selectedCustomMonthProvider = StateProvider<DateTime?>((ref) => null);

class AllTripsPage extends ConsumerStatefulWidget {
  final dynamic entity;
  final String title;

  const AllTripsPage({
    super.key,
    required this.entity,
    required this.title,
  });

  @override
  ConsumerState<AllTripsPage> createState() => _AllTripsPageState();
}

class _AllTripsPageState extends ConsumerState<AllTripsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_selectedPeriodProvider.notifier).state =
          AllTripsPeriodType.all;
      ref.read(_selectedRecordTypeProvider.notifier).state =
          AllTripsRecordType.all;
      ref.read(_selectedCustomMonthProvider.notifier).state = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripsState = _watchTrips();

    final selectedPeriod = ref.watch(_selectedPeriodProvider);
    final selectedRecordType = ref.watch(_selectedRecordTypeProvider);
    final customMonth = ref.watch(_selectedCustomMonthProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: widget.title,
        fontColor: AppColors.white,
        fontSize: 20.sp,
        iconPath: AppIcons.arrowLeft,
        onPressed: () => NavigatorHandler.pop(),
        actions: [
          IconButton(
            tooltip: 'مشاركة التقرير PDF',
            onPressed: () => _generateReport(),
            icon: Icon(
              Icons.print_outlined,
              color: AppColors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.white,
        onRefresh: () async {
          _refreshTrips();
        },
        child: _buildBody(tripsState, selectedPeriod, selectedRecordType, customMonth),
      ),
    );
  }

  Widget _buildBody(
    PaginatedTripsState tripsState,
    AllTripsPeriodType selectedPeriod,
    AllTripsRecordType selectedRecordType,
    DateTime? customMonth,
  ) {
    if (tripsState.isInitialLoading) {
      return const Center(child: CustomLoading());
    }

    if (tripsState.error != null && tripsState.trips.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 150.h),
          Center(
            child: CustomText(
              title: 'حدث خطأ في تحميل الرحلات',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    // The trip list is already filtered server-side by the active period and
    // record type, so we render the paginated result set directly.
    final trips = tripsState.trips;

    return Column(
      children: [
        if (widget.entity is BusEntity)
          BusInfoCard(bus: widget.entity as BusEntity),

        _buildPeriodFilter(selectedPeriod, customMonth),
        _buildTypeFilter(trips, selectedRecordType),

        Expanded(
          child: trips.isEmpty && !tripsState.isLoadingMore
              ? _buildEmptyState(selectedRecordType)
              : _buildTripsList(trips, tripsState),
        ),
      ],
    );
  }

  /// Builds the active page request (entity id + server-side filter) from the
  /// currently selected period/record type/month.
  PaginatedTripsRequest _buildRequest() {
    final filter = _buildFilter(
      ref.read(_selectedPeriodProvider),
      ref.read(_selectedRecordTypeProvider),
      ref.read(_selectedCustomMonthProvider),
    );
    return PaginatedTripsRequest(entityId: _entityId(), filter: filter);
  }

  String _entityId() {
    final entity = widget.entity;
    if (entity is BusEntity) {
      return entity.id!;
    } else if (entity is DriverEntity) {
      return entity.id;
    } else if (entity is FactoryEntity) {
      return entity.id;
    }
    throw ArgumentError('Unsupported entity type: ${entity.runtimeType}');
  }

  /// Translates the selected period + custom month into a Firestore date range
  /// (half-open: [start, end)).
  (DateTime, DateTime)? _buildDateRange(
    AllTripsPeriodType period,
    DateTime? customMonth,
  ) {
    final now = DateTime.now();
    DateTime start;
    switch (period) {
      case AllTripsPeriodType.all:
        return null;
      case AllTripsPeriodType.currentMonth:
        start = DateTime(now.year, now.month, 1);
        break;
      case AllTripsPeriodType.previousMonth:
        start = now.month == 1
            ? DateTime(now.year - 1, 12, 1)
            : DateTime(now.year, now.month - 1, 1);
        break;
      case AllTripsPeriodType.customMonth:
        if (customMonth == null) return null;
        start = DateTime(customMonth.year, customMonth.month, 1);
        break;
    }
    final end = DateTime(start.year, start.month + 1, 1);
    return (start, end);
  }

  /// Builds the server-side filter used for the paginated query.
  TripListFilter _buildFilter(
    AllTripsPeriodType period,
    AllTripsRecordType recordType,
    DateTime? customMonth,
  ) {
    final range = _buildDateRange(period, customMonth);

    String? recordTypeValue;
    switch (recordType) {
      case AllTripsRecordType.trips:
        recordTypeValue = TripType.trip;
        break;
      case AllTripsRecordType.nightOutings:
        recordTypeValue = TripType.nightOuting;
        break;
      case AllTripsRecordType.all:
        recordTypeValue = null;
        break;
    }

    return TripListFilter(
      startDate: range?.$1,
      endDate: range?.$2,
      recordType: recordTypeValue,
    );
  }

  PaginatedTripsState _watchTrips() {
    final entity = widget.entity;
    if (entity is BusEntity) {
      return ref.watch(busPaginatedTripsProvider(_buildRequest()));
    } else if (entity is DriverEntity) {
      return ref.watch(driverPaginatedTripsProvider(_buildRequest()));
    } else if (entity is FactoryEntity) {
      return ref.watch(factoryPaginatedTripsProvider(_buildRequest()));
    }
    throw ArgumentError('Unsupported entity type: ${entity.runtimeType}');
  }

  PaginatedTripsNotifier<PaginatedTripsRequest> _notifier() {
    final entity = widget.entity;
    final request = _buildRequest();
    if (entity is BusEntity) {
      return ref.read(busPaginatedTripsProvider(request).notifier);
    } else if (entity is DriverEntity) {
      return ref.read(driverPaginatedTripsProvider(request).notifier);
    } else if (entity is FactoryEntity) {
      return ref.read(factoryPaginatedTripsProvider(request).notifier);
    }
    throw ArgumentError('Unsupported entity type: ${entity.runtimeType}');
  }

  void _loadMore() {
    _notifier().loadMore();
  }

  void _refreshTrips() {
    _notifier().refresh();
  }

  Widget _buildPeriodFilter(AllTripsPeriodType selected, DateTime? customMonth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            _buildPeriodTab(
              type: AllTripsPeriodType.all,
              label: 'الكل',
              isSelected: selected == AllTripsPeriodType.all,
            ),
            SizedBox(width: 3.w),
            _buildPeriodTab(
              type: AllTripsPeriodType.currentMonth,
              label: 'الشهر الحالي',
              isSelected: selected == AllTripsPeriodType.currentMonth,
            ),
            SizedBox(width: 3.w),
            _buildPeriodTab(
              type: AllTripsPeriodType.previousMonth,
              label: 'الشهر السابق',
              isSelected: selected == AllTripsPeriodType.previousMonth,
            ),
            SizedBox(width: 3.w),
            _buildPeriodTab(
              type: AllTripsPeriodType.customMonth,
              label: selected == AllTripsPeriodType.customMonth &&
                      customMonth != null
                  ? _formatMonthLabel(customMonth)
                  : 'اختيار شهر',
              isSelected: selected == AllTripsPeriodType.customMonth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab({
    required AllTripsPeriodType type,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (type == AllTripsPeriodType.customMonth &&
              !(ref.read(_selectedPeriodProvider) ==
                      AllTripsPeriodType.customMonth &&
                  ref.read(_selectedCustomMonthProvider) != null)) {
            _showMonthPicker(context);
            return;
          }
          ref.read(_selectedPeriodProvider.notifier).state = type;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 7.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: CustomText(
              title: label,
              fontSize: 11.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontColor:
                  isSelected ? AppColors.primary : const Color(0xFF6B7280),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilter(
      List<TripEntity> allTrips, AllTripsRecordType selected) {
    final tripsCount = allTrips.where((t) => t.isTrip).length;
    final nightCount = allTrips.where((t) => t.isNightOuting).length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            _buildTypeTab(
              type: AllTripsRecordType.all,
              label: 'الكل (${allTrips.length})',
              isSelected: selected == AllTripsRecordType.all,
            ),
            SizedBox(width: 3.w),
            _buildTypeTab(
              type: AllTripsRecordType.trips,
              label: 'الرحلات ($tripsCount)',
              isSelected: selected == AllTripsRecordType.trips,
            ),
            SizedBox(width: 3.w),
            _buildTypeTab(
              type: AllTripsRecordType.nightOutings,
              label: 'السهرات ($nightCount)',
              isSelected: selected == AllTripsRecordType.nightOutings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab({
    required AllTripsRecordType type,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(_selectedRecordTypeProvider.notifier).state = type;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 7.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: CustomText(
              title: label,
              fontSize: 11.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontColor:
                  isSelected ? AppColors.primary : const Color(0xFF6B7280),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AllTripsRecordType type) {
    final entity = widget.entity;
    String entityLabel;
    if (entity is BusEntity) {
      entityLabel = 'هذا الأتوبيس';
    } else if (entity is DriverEntity) {
      entityLabel = 'هذا السواق';
    } else {
      entityLabel = 'هذا المصنع';
    }

    String message;
    switch (type) {
      case AllTripsRecordType.nightOutings:
        message = 'لا توجد سهرات مسجلة ل$entityLabel';
        break;
      case AllTripsRecordType.trips:
        message = 'لا توجد رحلات مسجلة ل$entityLabel';
        break;
      case AllTripsRecordType.all:
        message = 'لا توجد رحلات مسجلة ل$entityLabel';
        break;
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 80.h),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.directions_bus_outlined,
                size: 48.sp,
                color: const Color(0xFFD1D5DB),
              ),
              SizedBox(height: 10.h),
              CustomText(
                title: message,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                fontColor: const Color(0xFF777B85),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripsList(List<TripEntity> trips, PaginatedTripsState tripsState) {
    final entity = widget.entity;
    String? busId;
    if (entity is BusEntity) {
      busId = entity.id;
    }

    final showBus = entity is DriverEntity || entity is FactoryEntity;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      itemCount: trips.length + 1,
      itemBuilder: (context, index) {
        if (index == trips.length) {
          if (tripsState.isLoadingMore) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          if (!tripsState.hasMore) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Center(
                child: CustomText(
                  title: 'لا توجد رحلات أخرى',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  fontColor: const Color(0xFF999999),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final trip = trips[index];

        if (index >= trips.length - 3) {
          _loadMore();
        }

        return TripCard(
          trip: trip,
          busId: busId,
          showBus: showBus,
        );
      },
    );
  }

  String _formatMonthLabel(DateTime date) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showMonthPicker(BuildContext context) {
    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final years =
                List.generate(now.year - 2020 + 1, (i) => 2020 + i)
                    .reversed
                    .toList();

            const monthNames = [
              'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
              'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
            ];

            return Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    title: 'اختر الشهر والسنة',
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    fontColor: AppColors.primary,
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedMonth,
                          decoration: InputDecoration(
                            labelText: 'الشهر',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          items: List.generate(12, (i) {
                            return DropdownMenuItem(
                              value: i + 1,
                              child: Text(monthNames[i]),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedMonth = val);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedYear,
                          decoration: InputDecoration(
                            labelText: 'السنة',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          items: years.map((y) {
                            return DropdownMenuItem(
                              value: y,
                              child: Text('$y'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedYear = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: CustomText(
                            title: 'إلغاء',
                            fontColor: AppColors.gray,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: () {
                            final picked =
                                DateTime(selectedYear, selectedMonth);
                            if (picked.isAfter(now)) return;
                            ref
                                .read(_selectedCustomMonthProvider.notifier)
                                .state = picked;
                            ref
                                .read(_selectedPeriodProvider.notifier)
                                .state = AllTripsPeriodType.customMonth;
                            Navigator.pop(ctx);
                          },
                          child: CustomText(
                            title: 'تأكيد',
                            fontColor: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Fetches ALL matching trips from Firestore (independent of UI pagination)
  /// and generates the PDF report for the currently selected filters.
  Future<void> _generateReport() async {
    final request = _buildRequest();
    final selectedPeriod = ref.read(_selectedPeriodProvider);
    final selectedRecordType = ref.read(_selectedRecordTypeProvider);
    final customMonth = ref.read(_selectedCustomMonthProvider);

    final provider = _reportProviderFor(request);
    if (provider == null) return;

    try {
      final allTrips = await ref.read(provider(request).future);
      if (!mounted) return;

      if (allTrips.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد رحلات مطابقة للتقرير'),
          ),
        );
        return;
      }

      _printReport(
        allTrips,
        selectedPeriod,
        selectedRecordType,
        customMonth,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء تجهيز التقرير'),
        ),
      );
    }
  }

  /// Returns the report FutureProvider family matching [request]'s entity.
  FutureProviderFamily<List<TripEntity>, PaginatedTripsRequest>?
      _reportProviderFor(PaginatedTripsRequest request) {
    final entity = widget.entity;
    if (entity is BusEntity) {
      return busTripsForReportProvider;
    } else if (entity is DriverEntity) {
      return driverTripsForReportProvider;
    } else if (entity is FactoryEntity) {
      return factoryTripsForReportProvider;
    }
    return null;
  }

  void _printReport(
    List<TripEntity> trips,
    AllTripsPeriodType period,
    AllTripsRecordType recordType,
    DateTime? customMonth,
  ) {
    final entity = widget.entity;
    final periodLabel = _getPeriodLabel(period, customMonth);
    final typeLabel = _getTypeLabel(recordType);

    if (entity is DriverEntity) {
      DriverMonthlyReportService.shareCurrentMonthReport(
        driver: entity,
        trips: trips,
        periodLabel: periodLabel,
        typeFilterLabel: typeLabel,
      );
    } else if (entity is BusEntity) {
      BusMonthlyReportService.shareCurrentMonthReport(
        bus: entity,
        trips: trips,
        periodLabel: periodLabel,
        typeFilterLabel: typeLabel,
      );
    } else if (entity is FactoryEntity) {
      FactoryMonthlyReportService.shareFactoryReport(
        factory: entity,
        trips: trips,
        periodLabel: periodLabel,
        typeFilterLabel: typeLabel,
      );
    }
  }

  String _getPeriodLabel(AllTripsPeriodType period, DateTime? customMonth) {
    switch (period) {
      case AllTripsPeriodType.all:
        return 'الكل';
      case AllTripsPeriodType.currentMonth:
        return 'الشهر الحالي';
      case AllTripsPeriodType.previousMonth:
        return 'الشهر السابق';
      case AllTripsPeriodType.customMonth:
        return customMonth != null ? _formatMonthLabel(customMonth) : 'الكل';
    }
  }

  String _getTypeLabel(AllTripsRecordType type) {
    switch (type) {
      case AllTripsRecordType.all:
        return '';
      case AllTripsRecordType.trips:
        return 'الرحلات';
      case AllTripsRecordType.nightOutings:
        return 'السهرات';
    }
  }
}
