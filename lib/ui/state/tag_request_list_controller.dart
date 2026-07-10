import 'package:flutter/foundation.dart';

import '../../models/tag_request.dart';
import '../../repositories/tag_request_repository.dart';

class TagRequestListController extends ChangeNotifier {
  final TagRequestRepository _repo;

  TagRequestListController({TagRequestRepository? repository})
      : _repo = repository ?? TagRequestRepository();

  List<TagRequest> _requests = [];
  bool loading = false;

  String? statusFilter;
  int? bayFilter;

  List<TagRequest> get requests => List.unmodifiable(_requests);

  Future<void> load() async {
    loading = true;
    notifyListeners();
    _requests = await _repo.getAll(status: statusFilter, bay: bayFilter);
    loading = false;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    statusFilter = status;
    load();
  }

  void setBayFilter(int? bay) {
    bayFilter = bay;
    load();
  }

  Future<void> create(TagRequest request) async {
    await _repo.create(request);
    await load();
  }

  Future<void> update(TagRequest request) async {
    await _repo.update(request);
    await load();
  }

  Future<void> markCompleted(int id) async {
    await _repo.markCompleted(id);
    await load();
  }

  Future<void> markNeeded(int id) async {
    await _repo.markNeeded(id);
    await load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load();
  }
}
