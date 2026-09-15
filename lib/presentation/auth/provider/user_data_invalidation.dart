import 'package:elostaz_travel/core/services/bus_local_image_service.dart';
import 'package:elostaz_travel/core/services/driver_local_image_service.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_advance_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_wage_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/financial_summary/provider/company_financial_summary_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/provider/home_stats_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/trip/provider/trip_provider.dart'
    as home_trip;
import 'package:elostaz_travel/presentation/trip/provider/paginated_trips_provider.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Invalidates every account-scoped data provider so the next read re-resolves
/// against the current Firebase user.
///
/// Called from the root auth listener whenever the authenticated user changes
/// (logout → null, or login as a different account). Without this, cached
/// provider state from the previous account stays visible to the next account.
void invalidateUserScopedData(WidgetRef ref) {
  ref.invalidate(busProvider);
  ref.invalidate(driversProvider);
  ref.invalidate(factoriesProvider);

  ref.invalidate(home_trip.monthlyTripsProvider);
  ref.invalidate(home_trip.allTripsProvider);
  ref.invalidate(tripProvider);
  ref.invalidate(busTripsProvider);
  ref.invalidate(driverTripsProvider);
  ref.invalidate(factoryTripsProvider);
  ref.invalidate(busTripsLimitedProvider);
  ref.invalidate(driverTripsLimitedProvider);
  ref.invalidate(factoryTripsLimitedProvider);
  ref.invalidate(busPaginatedTripsProvider);
  ref.invalidate(driverPaginatedTripsProvider);
  ref.invalidate(factoryPaginatedTripsProvider);
  ref.invalidate(busTripsForReportProvider);
  ref.invalidate(driverTripsForReportProvider);
  ref.invalidate(factoryTripsForReportProvider);

  ref.invalidate(driverWageEntriesProvider);
  ref.invalidate(driverWagePaymentsProvider);
  ref.invalidate(allDriverWageEntriesProvider);
  ref.invalidate(allDriverWagePaymentsProvider);
  ref.invalidate(driverAdvancesProvider);

  ref.invalidate(homeStatsProvider);
  ref.invalidate(companyFinancialSummaryProvider);

  ref.invalidate(busLocalImagesProvider);
  ref.invalidate(driverLocalImagesProvider);
}