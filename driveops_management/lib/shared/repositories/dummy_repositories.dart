import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/shared/models/trip.dart';
import 'package:driveops_management/shared/models/vehicle.dart';
import 'package:driveops_management/shared/repositories/repositories.dart';
import 'package:driveops_management/shared/dtos/requests/driver_requests.dart';
import 'package:driveops_management/shared/dtos/requests/vehicle_requests.dart';

class DummyDriverRepository implements DriverRepository {
  final List<Driver> _drivers = _buildDummyDrivers();

  static List<Driver> _buildDummyDrivers() {
    return [
      Driver(
        id: 'd1',
        keycloakId: 'a1b2c3d4-0002-4000-8000-000000000002',
        firstName: 'Marcus',
        lastName: 'Johnson',
        email: 'marcus.johnson@driveops.com',
        phoneNumber: '+1-555-0101',
        licenseNumber: 'DL-001234',
        licenseExpiryDate: DateTime(2027, 6, 15),
        status: DriverStatus.active,
        rating: 4.9,
        totalTrips: 342,
        totalRevenue: 8450,
        isOnline: true,
        createdAt: DateTime(2024, 1, 15),
        activeTimeHours: 142.5,
      ),
      Driver(
        id: 'd2',
        keycloakId: 'a1b2c3d4-0003-4000-8000-000000000003',
        firstName: 'Sarah',
        lastName: 'Williams',
        email: 'sarah.williams@driveops.com',
        phoneNumber: '+1-555-0102',
        licenseNumber: 'DL-005678',
        licenseExpiryDate: DateTime(2026, 9, 20),
        status: DriverStatus.active,
        rating: 4.8,
        totalTrips: 289,
        totalRevenue: 7125,
        isOnline: true,
        createdAt: DateTime(2024, 2, 1),
        activeTimeHours: 128.3,
      ),
      Driver(
        id: 'd3',
        keycloakId: 'a1b2c3d4-0004-4000-8000-000000000004',
        firstName: 'David',
        lastName: 'Chen',
        email: 'david.chen@driveops.com',
        phoneNumber: '+1-555-0103',
        licenseNumber: 'DL-009012',
        licenseExpiryDate: DateTime(2027, 3, 10),
        status: DriverStatus.active,
        rating: 4.7,
        totalTrips: 256,
        totalRevenue: 6340,
        isOnline: true,
        createdAt: DateTime(2024, 2, 15),
        activeTimeHours: 115.8,
      ),
      Driver(
        id: 'd4',
        keycloakId: 'a1b2c3d4-0005-4000-8000-000000000005',
        firstName: 'Emily',
        lastName: 'Rodriguez',
        email: 'emily.rodriguez@driveops.com',
        phoneNumber: '+1-555-0104',
        licenseNumber: 'DL-003456',
        licenseExpiryDate: DateTime(2026, 11, 5),
        status: DriverStatus.active,
        rating: 4.6,
        totalTrips: 198,
        totalRevenue: 4890,
        isOnline: true,
        createdAt: DateTime(2024, 3, 1),
        activeTimeHours: 98.2,
      ),
      Driver(
        id: 'd5',
        keycloakId: 'a1b2c3d4-0006-4000-8000-000000000006',
        firstName: 'James',
        lastName: 'Brown',
        email: 'james.brown@driveops.com',
        phoneNumber: '+1-555-0105',
        licenseNumber: 'DL-007890',
        licenseExpiryDate: DateTime(2027, 1, 25),
        status: DriverStatus.active,
        rating: 4.5,
        totalTrips: 176,
        totalRevenue: 4320,
        isOnline: true,
        createdAt: DateTime(2024, 3, 15),
        activeTimeHours: 86.5,
      ),
      Driver(
        id: 'd6',
        keycloakId: 'a1b2c3d4-0007-4000-8000-000000000007',
        firstName: 'Aisha',
        lastName: 'Patel',
        email: 'aisha.patel@driveops.com',
        phoneNumber: '+1-555-0106',
        licenseNumber: 'DL-002345',
        licenseExpiryDate: DateTime(2026, 8, 30),
        status: DriverStatus.active,
        rating: 4.4,
        totalTrips: 145,
        totalRevenue: 3560,
        isOnline: true,
        createdAt: DateTime(2024, 4, 1),
        activeTimeHours: 72.1,
      ),
      Driver(
        id: 'd7',
        keycloakId: 'a1b2c3d4-0008-4000-8000-000000000008',
        firstName: 'Michael',
        lastName: "O'Brien",
        email: 'michael.obrien@driveops.com',
        phoneNumber: '+1-555-0107',
        licenseNumber: 'DL-006789',
        licenseExpiryDate: DateTime(2027, 4, 12),
        status: DriverStatus.active,
        rating: 4.3,
        totalTrips: 124,
        totalRevenue: 3050,
        isOnline: true,
        createdAt: DateTime(2024, 4, 15),
        activeTimeHours: 65.4,
      ),
      Driver(
        id: 'd8',
        keycloakId: 'a1b2c3d4-0009-4000-8000-000000000009',
        firstName: 'Lisa',
        lastName: 'Kim',
        email: 'lisa.kim@driveops.com',
        phoneNumber: '+1-555-0108',
        licenseNumber: 'DL-00123',
        licenseExpiryDate: DateTime(2026, 7, 18),
        status: DriverStatus.active,
        rating: 4.2,
        totalTrips: 98,
        totalRevenue: 2410,
        isOnline: true,
        createdAt: DateTime(2024, 5, 1),
        activeTimeHours: 52.3,
      ),
      Driver(
        id: 'd9',
        keycloakId: 'a1b2c3d4-000a-4000-8000-000000000010',
        firstName: 'Robert',
        lastName: 'Garcia',
        email: 'robert.garcia@driveops.com',
        phoneNumber: '+1-555-0109',
        licenseNumber: 'DL-00678',
        licenseExpiryDate: DateTime(2026, 5, 22),
        status: DriverStatus.suspended,
        rating: 3.8,
        totalTrips: 67,
        totalRevenue: 1650,
        isOnline: false,
        createdAt: DateTime(2024, 5, 15),
        activeTimeHours: 38.7,
      ),
      Driver(
        id: 'd10',
        keycloakId: 'a1b2c3d4-000b-4000-8000-000000000011',
        firstName: 'Fatima',
        lastName: 'Al-Hassan',
        email: 'fatima.alhassan@driveops.com',
        phoneNumber: '+1-555-0110',
        licenseNumber: 'DL-00901',
        licenseExpiryDate: DateTime(2027, 2, 14),
        status: DriverStatus.suspended,
        rating: 3.9,
        totalTrips: 45,
        totalRevenue: 1100,
        isOnline: false,
        createdAt: DateTime(2024, 6, 1),
        activeTimeHours: 28.9,
      ),
      Driver(
        id: 'd11',
        keycloakId: 'a1b2c3d4-000c-4000-8000-000000000012',
        firstName: 'Thomas',
        lastName: 'Wright',
        email: 'thomas.wright@driveops.com',
        phoneNumber: '+1-555-0111',
        licenseNumber: 'DL-00345',
        licenseExpiryDate: DateTime(2026, 12, 3),
        status: DriverStatus.inactive,
        rating: 4.1,
        totalTrips: 89,
        totalRevenue: 2190,
        isOnline: false,
        createdAt: DateTime(2024, 6, 15),
        activeTimeHours: 44.1,
      ),
      Driver(
        id: 'd12',
        keycloakId: 'a1b2c3d4-000d-4000-8000-000000000013',
        firstName: 'Maria',
        lastName: 'Santos',
        email: 'maria.santos@driveops.com',
        phoneNumber: '+1-555-0112',
        licenseNumber: 'DL-00789',
        licenseExpiryDate: DateTime(2027, 8, 9),
        status: DriverStatus.inactive,
        rating: 4.0,
        totalTrips: 54,
        totalRevenue: 1320,
        isOnline: false,
        createdAt: DateTime(2024, 7, 1),
        activeTimeHours: 31.2,
      ),
    ];
  }

  @override
  Future<List<Driver>> getAllDrivers() async => _drivers;

  @override
  Future<List<Driver>> getActiveDrivers() async =>
      _drivers.where((d) => d.status == DriverStatus.active).toList();

  @override
  Future<List<Driver>> getAvailableDrivers() async =>
      _drivers.where((d) => d.status == DriverStatus.active && d.isOnline).toList();

  @override
  Future<Driver?> getDriverById(String id) async {
    try {
      return _drivers.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Driver?> getDriverByKeycloakId(String keycloakId) async {
    try {
      return _drivers.firstWhere((d) => d.keycloakId == keycloakId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Driver>> getNearbyDrivers(
      double latitude, double longitude, double radiusKm) async {
    return getAvailableDrivers();
  }

  @override
  Future<Driver> createDriver(CreateDriverRequest request) async {
    final newDriver = Driver(
      id: 'd-new-${DateTime.now().millisecondsSinceEpoch}',
      keycloakId: request.keycloakId,
      firstName: request.firstName,
      lastName: request.lastName,
      email: request.email,
      phoneNumber: request.phoneNumber,
      licenseNumber: request.licenseNumber,
      licenseExpiryDate: request.licenseExpiryDate,
      status: DriverStatus.pending,
      rating: 5.0,
      totalTrips: 0,
      totalRevenue: 0,
      isOnline: false,
      emergencyContactName: request.emergencyContactName,
      emergencyContactPhone: request.emergencyContactPhone,
    );
    _drivers.add(newDriver);
    return newDriver;
  }

  @override
  Future<Driver> updateDriver(String id, UpdateDriverRequest request) async {
    final idx = _drivers.indexWhere((d) => d.id == id);
    if (idx == -1) throw Exception('Driver not found');
    final d = _drivers[idx];
    final updated = d.copyWith(
      firstName: request.firstName ?? d.firstName,
      lastName: request.lastName ?? d.lastName,
      email: request.email ?? d.email,
      phoneNumber: request.phoneNumber ?? d.phoneNumber,
      licenseNumber: request.licenseNumber ?? d.licenseNumber,
      licenseExpiryDate: request.licenseExpiryDate ?? d.licenseExpiryDate,
      emergencyContactName: request.emergencyContactName ?? d.emergencyContactName,
      emergencyContactPhone: request.emergencyContactPhone ?? d.emergencyContactPhone,
    );
    _drivers[idx] = updated;
    return updated;
  }

  @override
  Future<void> suspendDriver(String id) async {
    final idx = _drivers.indexWhere((d) => d.id == id);
    if (idx != -1) _drivers[idx] = _drivers[idx].copyWith(status: DriverStatus.suspended, isOnline: false);
  }

  @override
  Future<void> activateDriver(String id) async {
    final idx = _drivers.indexWhere((d) => d.id == id);
    if (idx != -1) _drivers[idx] = _drivers[idx].copyWith(status: DriverStatus.active);
  }

  @override
  Future<void> setDriverStatus(String id, bool isOnline) async {
    final idx = _drivers.indexWhere((d) => d.id == id);
    if (idx != -1) _drivers[idx] = _drivers[idx].copyWith(isOnline: isOnline);
  }
}

class DummyTripRepository implements TripRepository {
  final List<Trip> _trips = _buildDummyTrips();

  static List<Trip> _buildDummyTrips() {
    final now = DateTime.now();
    return [
      Trip(
        id: 't1', customerId: 'c1', customerName: 'John Doe',
        driverId: 'd1', driverName: 'Marcus Johnson',
        vehicleId: 'v1', vehiclePlate: 'ABC-1234',
        tripStatus: TripStatus.completed, tripType: TripType.standard,
        pickupLatitude: 40.7128, pickupLongitude: -74.0060,
        pickupAddress: '123 Main St, Downtown',
        dropoffLatitude: 40.7580, dropoffLongitude: -73.9855,
        dropoffAddress: '456 Oak Ave, Uptown',
        requestedAt: now.subtract(const Duration(hours: 2)),
        pickupTime: now.subtract(const Duration(hours: 1, minutes: 50)),
        dropoffTime: now.subtract(const Duration(hours: 1, minutes: 30)),
        actualDistance: 5.2, actualDuration: 18,
        estimatedFare: 22.00, actualFare: 24.50,
        paymentMethod: PaymentMethod.creditCard, paymentStatus: PaymentStatus.completed,
        customerRating: 5, driverRating: 5,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Trip(
        id: 't2', customerId: 'c2', customerName: 'Jane Smith',
        driverId: 'd2', driverName: 'Sarah Williams',
        vehicleId: 'v2', vehiclePlate: 'DEF-5678',
        tripStatus: TripStatus.completed, tripType: TripType.premium,
        pickupLatitude: 40.7282, pickupLongitude: -73.7949,
        pickupAddress: '789 Pine Rd, Midtown',
        dropoffLatitude: 40.7484, dropoffLongitude: -73.9857,
        dropoffAddress: '321 Elm St, Eastside',
        requestedAt: now.subtract(const Duration(hours: 5)),
        pickupTime: now.subtract(const Duration(hours: 4, minutes: 45)),
        dropoffTime: now.subtract(const Duration(hours: 4, minutes: 15)),
        actualDistance: 12.8, actualDuration: 35,
        estimatedFare: 35.00, actualFare: 38.00,
        paymentMethod: PaymentMethod.creditCard, paymentStatus: PaymentStatus.completed,
        customerRating: 5, driverRating: 4,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      Trip(
        id: 't3', customerId: 'c3', customerName: 'Bob Wilson',
        driverId: 'd3', driverName: 'David Chen',
        vehicleId: 'v3', vehiclePlate: 'GHI-9012',
        tripStatus: TripStatus.inProgress, tripType: TripType.standard,
        pickupLatitude: 40.7589, pickupLongitude: -73.9851,
        pickupAddress: '555 Cedar Ln, Westend',
        dropoffLatitude: 40.7489, dropoffLongitude: -73.9680,
        dropoffAddress: '888 Maple Dr, Southside',
        requestedAt: now.subtract(const Duration(minutes: 15)),
        pickupTime: now.subtract(const Duration(minutes: 10)),
        estimatedDistance: 4.5, estimatedDuration: 15,
        estimatedFare: 18.75,
        paymentMethod: PaymentMethod.creditCard, paymentStatus: PaymentStatus.pending,
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
      Trip(
        id: 't4', customerId: 'c4', customerName: 'Alice Brown',
        tripStatus: TripStatus.cancelled, tripType: TripType.standard,
        pickupLatitude: 40.7614, pickupLongitude: -73.9776,
        pickupAddress: '222 Birch Ave, Northside',
        dropoffLatitude: 40.7527, dropoffLongitude: -73.9772,
        dropoffAddress: '333 Spruce Way, Downtown',
        requestedAt: now.subtract(const Duration(hours: 8)),
        cancellationReason: 'Customer requested cancellation',
        estimatedFare: 22.00,
        paymentMethod: PaymentMethod.cash, paymentStatus: PaymentStatus.refunded,
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      Trip(
        id: 't5', customerId: 'c5', customerName: 'Charlie Davis',
        driverId: 'd4', driverName: 'Emily Rodriguez',
        vehicleId: 'v4', vehiclePlate: 'JKL-3456',
        tripStatus: TripStatus.completed, tripType: TripType.standard,
        pickupLatitude: 40.7549, pickupLongitude: -73.9840,
        pickupAddress: '444 Walnut St, Midtown',
        dropoffLatitude: 40.7628, dropoffLongitude: -73.9731,
        dropoffAddress: '666 Cherry Blvd, Uptown',
        requestedAt: now.subtract(const Duration(days: 1)),
        pickupTime: now.subtract(const Duration(days: 1, hours: 23)),
        dropoffTime: now.subtract(const Duration(days: 1, hours: 22, minutes: 30)),
        actualDistance: 3.9, actualDuration: 14,
        estimatedFare: 28.00, actualFare: 31.25,
        paymentMethod: PaymentMethod.digitalWallet, paymentStatus: PaymentStatus.completed,
        customerRating: 4, driverRating: 5,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Trip(
        id: 't6', customerId: 'c6', customerName: 'Diana Evans',
        tripStatus: TripStatus.noDriverAvailable, tripType: TripType.premium,
        pickupLatitude: 40.7484, pickupLongitude: -73.9857,
        pickupAddress: '111 Oakridge Dr, Suburb',
        dropoffLatitude: 40.7580, dropoffLongitude: -73.9855,
        dropoffAddress: '999 Sunset Blvd, Airport',
        requestedAt: now.subtract(const Duration(days: 1, hours: 3)),
        estimatedDistance: 18.5, estimatedDuration: 45,
        estimatedFare: 45.00,
        paymentMethod: PaymentMethod.creditCard, paymentStatus: PaymentStatus.failed,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      Trip(
        id: 't7', customerId: 'c7', customerName: 'Frank Green',
        driverId: 'd5', driverName: 'James Brown',
        vehicleId: 'v5', vehiclePlate: 'MNO-7890',
        tripStatus: TripStatus.completed, tripType: TripType.standard,
        pickupLatitude: 40.7420, pickupLongitude: -74.0060,
        pickupAddress: '777 Pinecone Ter, Eastside',
        dropoffLatitude: 40.7580, dropoffLongitude: -73.9855,
        dropoffAddress: '888 Willow Ln, Westend',
        requestedAt: now.subtract(const Duration(days: 2)),
        pickupTime: now.subtract(const Duration(days: 2, hours: 23, minutes: 45)),
        dropoffTime: now.subtract(const Duration(days: 2, hours: 23, minutes: 20)),
        actualDistance: 6.8, actualDuration: 22,
        estimatedFare: 14.00, actualFare: 15.50,
        paymentMethod: PaymentMethod.cash, paymentStatus: PaymentStatus.completed,
        customerRating: 5, driverRating: 5,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Trip(
        id: 't8', customerId: 'c8', customerName: 'Grace Hall',
        driverId: 'd1', driverName: 'Marcus Johnson',
        vehicleId: 'v1', vehiclePlate: 'ABC-1234',
        tripStatus: TripStatus.completed, tripType: TripType.premium,
        pickupLatitude: 40.7061, pickupLongitude: -74.0088,
        pickupAddress: '123 Harbor View, Waterfront',
        dropoffLatitude: 40.7527, dropoffLongitude: -73.9772,
        dropoffAddress: '456 Downtown Plaza, Central',
        requestedAt: now.subtract(const Duration(days: 2, hours: 5)),
        pickupTime: now.subtract(const Duration(days: 2, hours: 4, minutes: 50)),
        dropoffTime: now.subtract(const Duration(days: 2, hours: 4, minutes: 10)),
        actualDistance: 8.2, actualDuration: 28,
        estimatedFare: 40.00, actualFare: 42.75,
        paymentMethod: PaymentMethod.creditCard, paymentStatus: PaymentStatus.completed,
        customerRating: 5, driverRating: 5,
        createdAt: now.subtract(const Duration(days: 2, hours: 5)),
      ),
      Trip(
        id: 't9', customerId: 'c9', customerName: 'Henry Jackson',
        tripStatus: TripStatus.cancelled, tripType: TripType.standard,
        pickupLatitude: 40.7484, pickupLongitude: -73.9857,
        pickupAddress: '234 Green Park, Northside',
        dropoffLatitude: 40.7580, dropoffLongitude: -73.9855,
        dropoffAddress: '567 Blue Bay Rd, Southside',
        requestedAt: now.subtract(const Duration(days: 3)),
        cancellationReason: 'Driver cancelled',
        estimatedFare: 28.00,
        paymentMethod: PaymentMethod.debitCard, paymentStatus: PaymentStatus.refunded,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Trip(
        id: 't10', customerId: 'c10', customerName: 'Ivy Thomas',
        driverId: 'd6', driverName: 'Aisha Patel',
        vehicleId: 'v6', vehiclePlate: 'PQR-2345',
        tripStatus: TripStatus.completed, tripType: TripType.standard,
        pickupLatitude: 40.7505, pickupLongitude: -73.9934,
        pickupAddress: '890 Hilltop Ave, Midtown',
        dropoffLatitude: 40.7549, dropoffLongitude: -73.9840,
        dropoffAddress: '901 Valley View, Suburb',
        requestedAt: now.subtract(const Duration(days: 3, hours: 2)),
        pickupTime: now.subtract(const Duration(days: 3, hours: 1, minutes: 55)),
        dropoffTime: now.subtract(const Duration(days: 3, hours: 1, minutes: 35)),
        actualDistance: 2.8, actualDuration: 10,
        estimatedFare: 17.50, actualFare: 19.25,
        paymentMethod: PaymentMethod.cash, paymentStatus: PaymentStatus.completed,
        customerRating: 4, driverRating: 4,
        createdAt: now.subtract(const Duration(days: 3, hours: 2)),
      ),
    ];
  }

  @override
  Future<List<Trip>> getAllTrips() async => _trips;

  @override
  Future<Trip?> getTripById(String id) async {
    try {
      return _trips.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Trip>> getTripsByCustomer(String customerId) async {
    return _trips.where((t) => t.customerId == customerId).toList();
  }

  @override
  Future<List<Trip>> getTripsByDriver(String driverId) async {
    return _trips.where((t) => t.driverId == driverId).toList();
  }

  @override
  Future<List<Trip>> getActiveTripsByDriver(String driverId) async {
    return _trips
        .where((t) =>
            t.driverId == driverId &&
            (t.tripStatus == TripStatus.inProgress ||
                t.tripStatus == TripStatus.assigned ||
                t.tripStatus == TripStatus.driverEnRoute))
        .toList();
  }
}

class DummyVehicleRepository implements VehicleRepository {
  final List<Vehicle> _vehicles = _buildDummyVehicles();

  static List<Vehicle> _buildDummyVehicles() {
    final now = DateTime.now();
    return [
      Vehicle(
        id: 'v1', licensePlate: 'ABC-1234', make: 'Toyota', model: 'Camry',
        year: 2022, color: 'Silver', vin: 'VIN00123456789012',
        insurancePolicyNumber: 'INS-001', status: VehicleStatus.available,
        mileage: 45200, fuelType: FuelType.petrol, seatingCapacity: 5,
        assignedDriverId: 'd1', assignedDriverName: 'Marcus Johnson',
        insuranceExpiryDate: now.add(const Duration(days: 300)),
        registrationExpiryDate: now.add(const Duration(days: 450)),
        createdAt: DateTime(2024, 1, 10),
      ),
      Vehicle(
        id: 'v2', licensePlate: 'DEF-5678', make: 'Honda', model: 'Civic',
        year: 2023, color: 'Black', vin: 'VIN56789012345678',
        insurancePolicyNumber: 'INS-002', status: VehicleStatus.available,
        mileage: 28500, fuelType: FuelType.petrol, seatingCapacity: 5,
        assignedDriverId: 'd2', assignedDriverName: 'Sarah Williams',
        insuranceExpiryDate: now.subtract(const Duration(days: 10)),
        registrationExpiryDate: now.add(const Duration(days: 365)),
        createdAt: DateTime(2024, 1, 25),
      ),
      Vehicle(
        id: 'v3', licensePlate: 'GHI-9012', make: 'Tesla', model: 'Model 3',
        year: 2023, color: 'White', vin: 'VIN90123456789012',
        insurancePolicyNumber: 'INS-003', status: VehicleStatus.available,
        mileage: 15800, fuelType: FuelType.electric, seatingCapacity: 5,
        assignedDriverId: 'd3', assignedDriverName: 'David Chen',
        insuranceExpiryDate: now.add(const Duration(days: 180)),
        registrationExpiryDate: now.add(const Duration(days: 180)),
        createdAt: DateTime(2024, 2, 5),
      ),
      Vehicle(
        id: 'v4', licensePlate: 'JKL-3456', make: 'Hyundai', model: 'Ioniq',
        year: 2022, color: 'Blue', vin: 'VIN34567890123456',
        insurancePolicyNumber: 'INS-004', status: VehicleStatus.inUse,
        mileage: 52100, fuelType: FuelType.hybrid, seatingCapacity: 5,
        assignedDriverId: 'd4', assignedDriverName: 'Emily Rodriguez',
        insuranceExpiryDate: now.subtract(const Duration(days: 60)),
        registrationExpiryDate: now.add(const Duration(days: 300)),
        createdAt: DateTime(2024, 2, 20),
      ),
      Vehicle(
        id: 'v5', licensePlate: 'MNO-7890', make: 'Ford', model: 'Escape',
        year: 2021, color: 'Red', vin: 'VIN78901234567890',
        insurancePolicyNumber: 'INS-005', status: VehicleStatus.available,
        mileage: 67300, fuelType: FuelType.petrol, seatingCapacity: 5,
        assignedDriverId: 'd5', assignedDriverName: 'James Brown',
        insuranceExpiryDate: now.subtract(const Duration(days: 25)),
        registrationExpiryDate: now.add(const Duration(days: 35)),
        createdAt: DateTime(2024, 3, 1),
      ),
      Vehicle(
        id: 'v6', licensePlate: 'PQR-2345', make: 'Chevrolet', model: 'Bolt',
        year: 2023, color: 'Gray', vin: 'VIN23456789012345',
        insurancePolicyNumber: 'INS-006', status: VehicleStatus.available,
        mileage: 12400, fuelType: FuelType.electric, seatingCapacity: 5,
        assignedDriverId: 'd6', assignedDriverName: 'Aisha Patel',
        insuranceExpiryDate: now.add(const Duration(days: 200)),
        registrationExpiryDate: now.add(const Duration(days: 500)),
        createdAt: DateTime(2024, 3, 15),
      ),
      Vehicle(
        id: 'v7', licensePlate: 'STU-6789', make: 'BMW', model: '3 Series',
        year: 2020, color: 'Black', vin: 'VIN67890123456789',
        insurancePolicyNumber: 'INS-007', status: VehicleStatus.maintenance,
        mileage: 98700, fuelType: FuelType.diesel, seatingCapacity: 5,
        insuranceExpiryDate: now.subtract(const Duration(days: 120)),
        registrationExpiryDate: now.subtract(const Duration(days: 120)),
        createdAt: DateTime(2024, 3, 20),
      ),
      Vehicle(
        id: 'v8', licensePlate: 'VWX-0123', make: 'Toyota', model: 'RAV4',
        year: 2021, color: 'White', vin: 'VIN01234567890123',
        insurancePolicyNumber: 'INS-008', status: VehicleStatus.available,
        mileage: 58900, fuelType: FuelType.hybrid, seatingCapacity: 5,
        assignedDriverId: 'd7', assignedDriverName: "Michael O'Brien",
        insuranceExpiryDate: now.add(const Duration(days: 80)),
        registrationExpiryDate: now.subtract(const Duration(days: 10)),
        createdAt: DateTime(2024, 4, 1),
      ),
    ];
  }

  @override
  Future<List<Vehicle>> getAllVehicles() async => _vehicles;

  @override
  Future<List<Vehicle>> getAvailableVehicles() async =>
      _vehicles.where((v) => v.status == VehicleStatus.available).toList();

  @override
  Future<Vehicle?> getVehicleById(String id) async {
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Vehicle>> getVehiclesNeedingService() async {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    return _vehicles.where((v) {
      if (v.status == VehicleStatus.maintenance) return true;
      if (v.insuranceExpiryDate.isBefore(thirtyDaysFromNow)) return true;
      if (v.registrationExpiryDate.isBefore(thirtyDaysFromNow)) return true;
      return false;
    }).toList();
  }

  @override
  Future<Vehicle> assignVehicle(String vehicleId, String driverId) async {
    final idx = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (idx == -1) throw Exception('Vehicle not found');
    _vehicles[idx] = _vehicles[idx].copyWith(
      status: VehicleStatus.inUse,
      assignedDriverId: driverId,
      assignedDriverName: 'Assigned Driver',
    );
    return _vehicles[idx];
  }

  @override
  Future<void> unassignVehicle(String vehicleId) async {
    final idx = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (idx != -1) {
      _vehicles[idx] = _vehicles[idx].copyWith(
        assignedDriverId: null,
        assignedDriverName: null,
        status: VehicleStatus.available,
      );
    }
  }
}
