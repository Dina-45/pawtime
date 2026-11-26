import 'package:flutter_bloc/flutter_bloc.dart';

// Favorite dogs (by name). Replaces the Set + callbacks that were passed
// through MainScreen -> HomeScreen -> FavoritesScreen.
class FavoritesCubit extends Cubit<Set<String>> {
  FavoritesCubit() : super(const <String>{});

  void toggle(String dogName) {
    // New Set every time: the old state is never mutated
    final next = {...state};
    if (!next.remove(dogName)) next.add(dogName);
    emit(next);
  }
}
