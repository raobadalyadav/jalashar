enum UserRole {
  client,
  vendor,
  admin,
  superAdmin,
  support;

  static UserRole fromString(String? value) {
    switch (value) {
      case 'vendor':
        return UserRole.vendor;
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
        return UserRole.superAdmin;
      case 'support':
        return UserRole.support;
      default:
        return UserRole.client;
    }
  }

  String get value => switch (this) {
        UserRole.client => 'client',
        UserRole.vendor => 'vendor',
        UserRole.admin => 'admin',
        UserRole.superAdmin => 'super_admin',
        UserRole.support => 'support',
      };

  bool get isStaff =>
      this == UserRole.admin || this == UserRole.superAdmin || this == UserRole.support;
}
