import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:driveops_mobile/services/chat_api_service.dart';
import 'package:driveops_mobile/shared/providers/location_signalr_provider.dart';
import 'package:driveops_mobile/shared/providers/notification_signalr_provider.dart';
import 'package:driveops_mobile/shared/dtos/requests/trip_requests.dart';
import 'package:driveops_mobile/shared/models/conversation_summary.dart';
import 'package:driveops_mobile/shared/models/trip.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';

/// All of the customer's trips, newest first (server ordering). Used by the
/// history screen; the active trip is pinned client-side from
/// [customerActiveTripProvider].
final customerTripsProvider = FutureProvider.autoDispose<List<Trip>>((ref) async {
  final customer = await ref.watch(currentCustomerProvider.future);
  if (customer == null) return [];
  final repo = ref.watch(tripRepositoryProvider);
  return repo.getTripsByCustomer(customer.id);
});

/// The customer's single live trip (Requested → InProgress), if any.
///
/// There is no customer "active trip" endpoint, so this filters the customer
/// trips list (fresh fetch, cache bypassed) and re-polls every 30 s — the
/// fallback for events that carry no push (a driver Decline publishes no
/// RabbitMQ event). Pushes and mutations invalidate it for instant updates.
final customerActiveTripProvider = StreamProvider.autoDispose<Trip?>((ref) async* {
  final customer = await ref.watch(currentCustomerProvider.future);
  if (customer == null) {
    yield null;
    return;
  }
  final repo = ref.watch(tripRepositoryProvider);

  Future<Trip?> fetch() async {
    final trips = await repo.getTripsByCustomer(customer.id, bypassCache: true);
    final active = trips
        .where((t) =>
            t.tripStatus == TripStatus.requested ||
            t.tripStatus == TripStatus.assigned ||
            t.tripStatus == TripStatus.driverEnRoute ||
            t.tripStatus == TripStatus.inProgress)
        .toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return active.isEmpty ? null : active.first;
  }

  yield await fetch();
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    yield await fetch();
  }
});

/// Push → invalidate → REST refetch (mirrors driverTripPushProvider).
/// Customers receive TripAssigned and TripStatusChanged on user-{keycloakSub}.
final customerTripPushProvider = Provider<void>((ref) {
  ref.watch(notificationSignalrConnectionProvider);
  final signalr = ref.watch(notificationSignalrServiceProvider);

  void handler(List<dynamic>? args) {
    ref.invalidate(customerActiveTripProvider);
    ref.invalidate(customerTripsProvider);
  }

  signalr.on('TripAssigned', handler);
  signalr.on('TripStatusChanged', handler);
  ref.onDispose(() {
    signalr.off('TripAssigned');
    signalr.off('TripStatusChanged');
  });
});

/// Live driver GPS for a trip: subscribes to the `trip-location-{tripId}`
/// group on the location hub and maps `ReceiveDriverLocation` payloads
/// (positional args: driverId, latitude, longitude, timestamp) to [LatLng].
/// Emits null until the first fix arrives; auto-disposed with the trip screen
/// (unsubscribes the group + removes the hub handler).
final customerLiveDriverLocationProvider = StreamProvider.autoDispose
    .family<LatLng?, String>((ref, tripId) async* {
  ref.watch(locationSignalrConnectionProvider);
  final hub = ref.watch(locationSignalrServiceProvider);

  // Wait for the keep-alive connection before subscribing, otherwise the
  // group join is silently dropped (invoke on a null/starting connection).
  if (!hub.isConnected) {
    try {
      await hub.connectionState
          .firstWhere((s) => s == HubConnectionState.Connected)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Never connected — no live tracking this session; the REST-driven
      // trip data still renders. A later reconnect re-subscribes via the
      // service's tracked trip ids.
    }
  }

  final controller = StreamController<LatLng?>();

  void handler(List<dynamic>? args) {
    if (args == null || args.length < 3) return;
    final lat = (args[1] as num?)?.toDouble();
    final lng = (args[2] as num?)?.toDouble();
    if (lat != null && lng != null) {
      controller.add(LatLng(lat, lng));
    }
  }

  hub.on('ReceiveDriverLocation', handler);
  try {
    await hub.subscribeToTripLocation(tripId);
  } catch (_) {
    // Best-effort — reconnect re-subscribes tracked trip ids.
  }

  ref.onDispose(() {
    hub.off('ReceiveDriverLocation');
    hub.unsubscribeFromTripLocation(tripId);
    unawaited(controller.close());
  });

  yield* controller.stream;
});

/// The auto-created customer ↔ driver trip conversation (participants are the
/// two Keycloak ids; created server-side on trip.assigned). Null when the
/// conversation is not visible yet (event race right after assignment).
final customerTripConversationProvider = FutureProvider.autoDispose
    .family<ConversationSummary?, String>((ref, tripId) async {
  final chatApi = ref.watch(chatApiServiceProvider);
  final conversations = await chatApi.getMyConversations();
  for (final c in conversations) {
    if (c.tripId == tripId) return c;
  }
  return null;
});

/// Customer trip mutations. Every action refreshes the active trip + the
/// trips list so the UI flips without waiting for the 30 s poll.
class CustomerTripActions {
  final Ref _ref;

  CustomerTripActions(this._ref);

  Future<Trip> requestTrip(CreateTripRequest request) async {
    // Client-side pre-check of the one-trip rule (the API enforces it too —
    // a 409 there is the race-safe backstop for double-taps / two devices).
    final active = await _ref.read(customerActiveTripProvider.future);
    if (active != null) {
      throw StateError('You already have an active trip.');
    }
    final repo = _ref.read(tripRepositoryProvider);
    final trip = await repo.createTrip(request);
    _refresh();
    return trip;
  }

  Future<Trip> cancelActiveTrip(String tripId) async {
    final repo = _ref.read(tripRepositoryProvider);
    final trip = await repo.cancelTrip(tripId, reason: 'Cancelled by customer');
    _refresh();
    return trip;
  }

  void _refresh() {
    _ref.invalidate(customerActiveTripProvider);
    _ref.invalidate(customerTripsProvider);
  }
}

final customerTripActionsProvider =
    Provider<CustomerTripActions>((ref) => CustomerTripActions(ref));
