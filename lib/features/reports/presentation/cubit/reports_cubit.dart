import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/reports_timeframe.dart';
import '../../domain/repositories/reports_repository.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final ReportsRepository _reportsRepository;

  ReportsCubit(this._reportsRepository) : super(const ReportsInitial());

  ReportsTimeframe _currentTimeframe = ReportsTimeframe.thisMonth;
  DateTimeRange? _currentCustomRange;
  ReportsView _currentView = ReportsView.cashFlow;

  ReportsTimeframe get currentTimeframe => _currentTimeframe;
  DateTimeRange? get currentCustomRange => _currentCustomRange;
  ReportsView get currentView => _currentView;

  Future<void> loadReports() async {
    emit(const ReportsLoading());
    try {
      final cashFlow = await _reportsRepository.getCashFlowReport(
        _currentTimeframe,
        customStart: _currentCustomRange?.start,
        customEnd: _currentCustomRange?.end,
      );
      final categoryBreakdown = await _reportsRepository.getCategoryBreakdownReport(
        _currentTimeframe,
        customStart: _currentCustomRange?.start,
        customEnd: _currentCustomRange?.end,
      );
      final netWorth = await _reportsRepository.getNetWorthTrendReport(
        _currentTimeframe,
        customStart: _currentCustomRange?.start,
        customEnd: _currentCustomRange?.end,
      );

      emit(
        ReportsLoaded(
          timeframe: _currentTimeframe,
          customRange: _currentCustomRange,
          selectedView: _currentView,
          cashFlowReport: cashFlow,
          categoryBreakdownReport: categoryBreakdown,
          netWorthTrendReport: netWorth,
        ),
      );
    } catch (e) {
      emit(ReportsError('Failed to load financial reports: $e'));
    }
  }

  void changeView(ReportsView view) {
    _currentView = view;
    if (state is ReportsLoaded) {
      emit((state as ReportsLoaded).copyWith(selectedView: view));
    } else {
      loadReports();
    }
  }

  Future<void> changeTimeframe(
    ReportsTimeframe timeframe, {
    DateTimeRange? customRange,
  }) async {
    _currentTimeframe = timeframe;
    _currentCustomRange = customRange;
    await loadReports();
  }
}
