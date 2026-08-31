import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/core/utils/custom_loading.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/bus_info_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/bus_monthly_report_service.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/trip_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/widgets/driver_monthly_report_service.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/widgets/factory_monthly_report_service.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
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
            onPressed: tripsState.hasValue
                ? () {
                    final allTrips = tripsState.value!;
                    final filtered = _applyFilters(
                      allTrips,
                      selectedPeriod,
                      selectedRecordType,
                      customMonth,
                    );
                    if (filtered.isEmpty) return;
                    _printReport(filtered, selectedPeriod, selectedRecordType,
                        customMonth);
                  }
                : null,
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
          _invalidateTrips();
          await _readTripsFuture();
        },
        child: tripsState.when(
          loading: () => const Center(child: CustomLoading()),
          error: (error, stackTrace) => ListView(
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
          ),
          data: (trips) {
            final periodFiltered = _applyPeriodFilter(
              trips,
              selectedPeriod,
              customMonth,
            );

            final filtered = _applyTypeFilter(
              periodFiltered,
              selectedRecordType,
            );

            return Column(
              children: [
                if (widget.entity is BusEntity)
                  BusInfoCard(bus: widget.entity as BusEntity),

                _buildPeriodFilter(selectedPeriod, customMonth),
                _buildTypeFilter(periodFiltered, selectedRecordType),

                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState(selectedRecordType)
                      : _buildTripsList(filtered),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  AsyncValue<List<TripEntity>> _watchTrips() {
    final entity = widget.entity;
    if (entity is BusEntity) {
      return ref.watch(busTripsProvider(entity.id!));
    } else if (entity is DriverEntity) {
      return ref.watch(driverTripsProvider(entity.id));
    } else if (entity is FactoryEntity) {
      return ref.watch(factoryTripsProvider(entity.id));
    }
    throw ArgumentError('Unsupported entity type: ${entity.runtimeType}');
  }

  void _invalidateTrips() {
    final entity = widget.entity;
    if (entity is BusEntity) {
      ref.invalidate(busTripsProvider(entity.id!));
    } else if (entity is DriverEntity) {
      ref.invalidate(driverTripsProvider(entity.id));
    } else if (entity is FactoryEntity) {
      ref.invalidate(factoryTripsProvider(entity.id));
    }
  }

  Future<void> _readTripsFuture() async {
    final entity = widget.entity;
    if (entity is BusEntity) {
      await ref.read(busTripsProvider(entity.id!).future);
    } else if (entity is DriverEntity) {
      await ref.read(driverTripsProvider(entity.id).future);
    } else if (entity is FactoryEntity) {
      await ref.read(factoryTripsProvider(entity.id).future);
    }
  }

  List<TripEntity> _applyPeriodFilter(
    List<TripEntity> trips,
    AllTripsPeriodType period,
    DateTime? customMonth,
  ) {
    final now = DateTime.now();

    switch (period) {
      case AllTripsPeriodType.currentMonth:
        return trips.where((t) {
          final d = t.effectiveDate;
          return d.year == now.year && d.month == now.month;
        }).toList();
      case AllTripsPeriodType.previousMonth:
        final prevMonth = now.month == 1 ? 12 : now.month - 1;
        final prevYear = now.month == 1 ? now.year - 1 : now.year;
        return trips.where((t) {
          final d = t.effectiveDate;
          return d.year == prevYear && d.month == prevMonth;
        }).toList();
      case AllTripsPeriodType.customMonth:
        if (customMonth != null) {
          return trips.where((t) {
            final d = t.effectiveDate;
            return d.year == customMonth.year &&
                d.month == customMonth.month;
          }).toList();
        }
        return List.from(trips);
      case AllTripsPeriodType.all:
        return List.from(trips);
    }
  }

  List<TripEntity> _applyTypeFilter(
    List<TripEntity> trips,
    AllTripsRecordType recordType,
  ) {
    switch (recordType) {
      case AllTripsRecordType.trips:
        return trips.where((t) => t.isTrip).toList();
      case AllTripsRecordType.nightOutings:
        return trips.where((t) => t.isNightOuting).toList();
      case AllTripsRecordType.all:
        return trips;
    }
  }

  List<TripEntity> _applyFilters(
    List<TripEntity> trips,
    AllTripsPeriodType period,
    AllTripsRecordType recordType,
    DateTime? customMonth,
  ) {
    return _applyTypeFilter(
      _applyPeriodFilter(trips, period, customMonth),
      recordType,
    );
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

  Widget _buildTripsList(List<TripEntity> trips) {
    final entity = widget.entity;
    String? busId;
    if (entity is BusEntity) {
      busId = entity.id;
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return TripCard(
          trip: trips[index],
          busId: busId,
          showBus: entity is DriverEntity || entity is FactoryEntity,
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
