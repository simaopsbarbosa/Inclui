import 'dart:async';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  
  ReportService._internal();

  final _reportUpdateController = StreamController<void>.broadcast();

  // stream that other widgets can listen to
  Stream<void> get onReportUpdate => _reportUpdateController.stream;

  // call when a report is added or deleted
  void notifyReportUpdate() {
    _reportUpdateController.add(null);
  }

  void dispose() {
    _reportUpdateController.close();
  }
}
