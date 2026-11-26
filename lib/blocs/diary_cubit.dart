import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/diary_entry.dart';

// Offline walk photo journal (kept in memory while the app runs).
class DiaryCubit extends Cubit<List<DiaryEntry>> {
  DiaryCubit() : super(const []);

  // Newest entry first
  void add(DiaryEntry entry) => emit([entry, ...state]);

  void remove(String id) => emit(state.where((e) => e.id != id).toList());
}
