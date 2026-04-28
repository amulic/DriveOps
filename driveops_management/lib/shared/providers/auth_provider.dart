import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/user.dart';

final authProvider = Provider<User>((ref) {
  return const User(
    id: 'admin-001',
    email: 'admin@driveops.com',
    firstName: 'Admin',
    lastName: 'Manager',
    userType: UserType.admin,
    isActive: true,
  );
});
