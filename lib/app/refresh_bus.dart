import 'package:flutter/foundation.dart';

class RefreshBus extends ChangeNotifier {
  int _homeTick = 0;
  int _myReportsTick = 0;

  int get homeTick => _homeTick;
  int get myReportsTick => _myReportsTick;

  void pingHome() {
    _homeTick++;
    notifyListeners();
  }

  void pingMyReports() {
    _myReportsTick++;
    notifyListeners();
  }
}

final refreshBus = RefreshBus();
