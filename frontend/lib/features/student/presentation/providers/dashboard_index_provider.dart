import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentDashboardIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final studentDashboardIndexProvider =
    NotifierProvider<StudentDashboardIndexNotifier, int>(() {
      return StudentDashboardIndexNotifier();
    });
