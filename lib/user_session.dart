/// Simple in-memory singleton that holds the currently logged-in user.
/// Populate it after a successful login or registration response.
class UserSession {
  UserSession._();
  static final UserSession _i = UserSession._();
  static UserSession get instance => _i;

  String name   = '';
  String userId = '';
  String email  = '';

  /// True when an email has been stored (i.e., user is logged in).
  bool get isLoggedIn => email.isNotEmpty;

  /// Store data returned by the login / register endpoints.
  void set({
    required String name,
    required String userId,
    required String email,
  }) {
    this.name   = name;
    this.userId = userId;
    this.email  = email;
  }

  /// Clear on sign-out.
  void clear() {
    name   = '';
    userId = '';
    email  = '';
  }
}
