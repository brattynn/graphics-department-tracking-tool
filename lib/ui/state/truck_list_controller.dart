import 'package:flutter/foundation.dart';

import '../../models/truck.dart';
import '../../repositories/truck_repository.dart';

enum TruckSortField { bay, stage, scheduleStatus, dueDate }

class TruckListController extends ChangeNotifier {
  final TruckRepository _repo;

  TruckListController({TruckRepository? repository})
      : _repo = repository ?? TruckRepository();

  List<Truck> _active = [];
  List<Truck> _archived = [];
  bool loading = false;

  int? bayFilter;
  String? stageFilter;
  String? scheduleStatusFilter;
  TruckSortField sortField = TruckSortField.bay;
  bool sortAscending = true;

  List<Truck> get archived => List.unmodifiable(_archived);

  Future<void> load() async {
    loading = true;
    notifyListeners();
    _active = await _repo.getActive();
    _archived = await _repo.getArchived();
    loading = false;
    notifyListeners();
  }

  void setBayFilter(int? bay) {
    bayFilter = bay;
    notifyListeners();
  }

  void setStageFilter(String? stage) {
    stageFilter = stage;
    notifyListeners();
  }

  void setScheduleStatusFilter(String? status) {
    scheduleStatusFilter = status;
    notifyListeners();
  }

  void setSort(TruckSortField field) {
    if (sortField == field) {
      sortAscending = !sortAscending;
    } else {
      sortField = field;
      sortAscending = true;
    }
    notifyListeners();
  }

  void clearFilters() {
    bayFilter = null;
    stageFilter = null;
    scheduleStatusFilter = null;
    notifyListeners();
  }

  List<Truck> get visibleTrucks {
    var list = _active.where((t) {
      if (bayFilter != null && t.bayNumber != bayFilter) return false;
      if (stageFilter != null && t.currentStage != stageFilter) return false;
      if (scheduleStatusFilter != null &&
          t.scheduleStatus != scheduleStatusFilter) {
        return false;
      }
      return true;
    }).toList();

    int cmp(Truck a, Truck b) {
      switch (sortField) {
        case TruckSortField.bay:
          return a.bayNumber.compareTo(b.bayNumber);
        case TruckSortField.stage:
          return a.currentStage.compareTo(b.currentStage);
        case TruckSortField.scheduleStatus:
          return a.scheduleStatus.compareTo(b.scheduleStatus);
        case TruckSortField.dueDate:
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
      }
    }

    list.sort(sortAscending ? cmp : (a, b) => cmp(b, a));
    return list;
  }

  Future<Truck> createTruck(Truck truck) async {
    final created = await _repo.create(truck);
    await load();
    return created;
  }

  Future<void> updateTruckDetails(Truck truck) async {
    await _repo.updateDetails(truck);
    await load();
  }

  Future<Truck> changeStage(int truckId, String newStage) async {
    final updated = await _repo.changeStage(truckId, newStage);
    await load();
    return updated;
  }

  Future<void> setScheduleStatus(int truckId, String status) async {
    await _repo.setScheduleStatus(truckId, status);
    await load();
  }

  Future<void> deleteTruck(int truckId) async {
    await _repo.delete(truckId);
    await load();
  }

  Future<List<int>> availableBays({int? excludingTruckId}) {
    return _repo.availableBays(excludingTruckId: excludingTruckId);
  }
}
