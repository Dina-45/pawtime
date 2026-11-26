import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_state.dart';

class _Account {
  final String password;
  final String name;
  final UserRole role;
  const _Account(this.password, this.name, this.role);
}

// Cubit: no events, the UI calls methods directly (login / logout).
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial());

  static const volunteerEmail = 'aliya@narxoz.kz';
  static const staffEmail = 'staff@pawtime.kz';
  static const testPassword = '123456';

  // Fake user database (there is no backend yet)
  static const _accounts = {
    volunteerEmail: _Account(testPassword, 'Aliya', UserRole.volunteer),
    staffEmail: _Account(testPassword, 'Dana (staff)', UserRole.staff),
  };

  Future<void> login(String email, String password) async {
    // 1) Tell the screen that we are checking
    emit(const AuthLoading());

    // 2) Fake server request
    await Future.delayed(const Duration(seconds: 2));

    final cleanEmail = email.trim().toLowerCase();
    final account = _accounts[cleanEmail];

    // 3) Result: error or success (with the user's role)
    if (cleanEmail.isEmpty || password.isEmpty) {
      emit(const AuthError('Please enter email and password'));
    } else if (account == null || account.password != password) {
      emit(const AuthError('Invalid email or password'));
    } else {
      emit(
        AuthSuccess(name: account.name, email: cleanEmail, role: account.role),
      );
    }
  }

  void logout() => emit(const AuthInitial());
}
