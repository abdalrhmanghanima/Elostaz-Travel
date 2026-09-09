import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/repository/trip_repository.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/trip/use_case/get_bus_trips_paginated_use_case.dart';
import '../../../domain/trip/use_case/get_driver_trips_paginated_use_case.dart';
import '../../../domain/trip/use_case/get_factory_trips_paginated_use_case.dart';

/// Composite key used to identify a paginated trips query.
///
/// It combines the [entityId] (bus/driver/factory) and the active server-side
/// [filter]. Because the filter is part of the provider identity, changing a
/// filter creates a brand-new notifier which re-runs the initial page, so stale
/// pages from a previous filter are never carried over.
class PaginatedTripsRequest {
  final String entityId;
  final TripListFilter filter;

  const PaginatedTripsRequest({
    required this.entityId,
    this.filter = const TripListFilter(),
  });

  @override
  bool operator ==(Object other) =>
      other is PaginatedTripsRequest &&
      other.entityId == entityId &&
      other.filter == filter;

  @override
  int get hashCode => Object.hash(entityId, filter);
}

class PaginatedTripsState {
  final List<TripEntity> trips;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final StackTrace? stackTrace;

  const PaginatedTripsState({
    this.trips = const [],
    this.lastDocument,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.stackTrace,
  });

  PaginatedTripsState copyWith({
    List<TripEntity>? trips,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return PaginatedTripsState(
      trips: trips ?? this.trips,
      lastDocument: lastDocument ?? this.lastDocument,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      stackTrace: stackTrace,
    );
  }

  bool get isInitialLoading => isLoading && trips.isEmpty;
}

abstract class PaginatedTripsNotifier<T> extends StateNotifier<PaginatedTripsState> {
  final PaginatedTripsRequest request;
  final int pageSize;

  PaginatedTripsNotifier(this.request, {this.pageSize = 10})
      : super(const PaginatedTripsState()) {
    loadInitial();
  }

  Future<PaginatedTripsResult> fetchPage(
    String id,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  );

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null, stackTrace: null);

    try {
      final result = await fetchPage(
          request.entityId, pageSize, null, request.filter);
      state = PaginatedTripsState(
        trips: result.trips,
        lastDocument: result.lastDocument,
        isLoading: false,
        hasMore: result.hasMore,
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await fetchPage(
          request.entityId, pageSize, state.lastDocument, request.filter);
      final newTrips = [...state.trips, ...result.trips];

      state = state.copyWith(
        trips: newTrips,
        lastDocument: result.lastDocument,
        isLoadingMore: false,
        hasMore: result.hasMore,
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e,
        stackTrace: st,
      );
    }
  }

  void refresh() {
    state = const PaginatedTripsState();
    loadInitial();
  }
}

class BusPaginatedTripsNotifier extends PaginatedTripsNotifier<PaginatedTripsRequest> {
  final GetBusTripsPaginatedUseCase _useCase;

  BusPaginatedTripsNotifier(PaginatedTripsRequest request, this._useCase,
      {super.pageSize = 10})
      : super(request);

  @override
  Future<PaginatedTripsResult> fetchPage(
    String id,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  ) {
    return _useCase.call(id, limit, lastDocument, filter);
  }
}

class DriverPaginatedTripsNotifier extends PaginatedTripsNotifier<PaginatedTripsRequest> {
  final GetDriverTripsPaginatedUseCase _useCase;

  DriverPaginatedTripsNotifier(PaginatedTripsRequest request, this._useCase,
      {super.pageSize = 10})
      : super(request);

  @override
  Future<PaginatedTripsResult> fetchPage(
    String id,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  ) {
    return _useCase.call(id, limit, lastDocument, filter);
  }
}

class FactoryPaginatedTripsNotifier extends PaginatedTripsNotifier<PaginatedTripsRequest> {
  final GetFactoryTripsPaginatedUseCase _useCase;

  FactoryPaginatedTripsNotifier(PaginatedTripsRequest request, this._useCase,
      {super.pageSize = 10})
      : super(request);

  @override
  Future<PaginatedTripsResult> fetchPage(
    String id,
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    TripListFilter filter,
  ) {
    return _useCase.call(id, limit, lastDocument, filter);
  }
}

final busPaginatedTripsProvider = StateNotifierProvider.family<
    BusPaginatedTripsNotifier, PaginatedTripsState, PaginatedTripsRequest>(
  (ref, request) {
    return BusPaginatedTripsNotifier(
        request, ref.read(getBusTripsPaginatedUseCaseProvider));
  },
);

final driverPaginatedTripsProvider = StateNotifierProvider.family<
    DriverPaginatedTripsNotifier, PaginatedTripsState, PaginatedTripsRequest>(
  (ref, request) {
    return DriverPaginatedTripsNotifier(
        request, ref.read(getDriverTripsPaginatedUseCaseProvider));
  },
);

final factoryPaginatedTripsProvider = StateNotifierProvider.family<
    FactoryPaginatedTripsNotifier, PaginatedTripsState, PaginatedTripsRequest>(
  (ref, request) {
    return FactoryPaginatedTripsNotifier(
        request, ref.read(getFactoryTripsPaginatedUseCaseProvider));
  },
);

/// Fetch ALL matching trips for a given [PaginatedTripsRequest] (print/report
/// flow). Unlike the paginated notifiers above, this intentionally retrieves
/// every document matching the filter (batching internally in the data source)
/// so the PDF is complete regardless of UI pagination.
final busTripsForReportProvider =
    FutureProvider.family<List<TripEntity>, PaginatedTripsRequest>(
  (ref, request) {
    return ref
        .read(getBusTripsForReportUseCaseProvider)
        .call(request.entityId, request.filter);
  },
);

final driverTripsForReportProvider =
    FutureProvider.family<List<TripEntity>, PaginatedTripsRequest>(
  (ref, request) {
    return ref
        .read(getDriverTripsForReportUseCaseProvider)
        .call(request.entityId, request.filter);
  },
);

final factoryTripsForReportProvider =
    FutureProvider.family<List<TripEntity>, PaginatedTripsRequest>(
  (ref, request) {
    return ref
        .read(getFactoryTripsForReportUseCaseProvider)
        .call(request.entityId, request.filter);
  },
);
