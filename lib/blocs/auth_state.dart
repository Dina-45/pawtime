import 'package:equatable/equatable.dart';

// Two kinds of users in PawTime.
enum UserRole { volunteer, staff }

// Immutable auth states.
// Equatable compares states by value (props), not by reference.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final String name;
  final String email;
  final UserRole role;

  const AuthSuccess({
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isStaff => role == UserRole.staff;

  @override
  List<Object?> get props => [name, email, role];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
