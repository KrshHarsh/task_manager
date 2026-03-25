import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/task_draft.dart';
import '../utils/database_helper.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Task> _tasks = [];
  String _searchQuery = '';
  TaskStatus? _statusFilter;
  bool _isLoading = false;
  bool _isSaving = false;
  final Set<String> _savingTaskIds = {};
  Timer? _debounceTimer;

  // Draft persistence for the creation form
  final TaskDraft draft = TaskDraft();

  // ── Getters ──
  List<Task> get allTasks => List.unmodifiable(_tasks);
  String get searchQuery => _searchQuery;
  TaskStatus? get statusFilter => _statusFilter;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool isTaskSaving(String id) => _savingTaskIds.contains(id);

  List<Task> get filteredTasks {
    var result = List<Task>.from(_tasks);

    // Apply status filter
    if (_statusFilter != null) {
      result = result.where((t) => t.status == _statusFilter).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result =
          result.where((t) => t.title.toLowerCase().contains(query)).toList();
    }

    return result;
  }

  // ── Initialization ──
  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _db.getAllTasks();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── CRUD Operations ──
  Future<void> createTask(Task task) async {
    _isSaving = true;
    notifyListeners();

    try {
      // Simulate 2-second network delay as required
      await Future.delayed(const Duration(seconds: 2));

      final newTask = task.copyWith(
        sortOrder: _tasks.isEmpty ? 0 : _tasks.last.sortOrder + 1,
      );
      await _db.insertTask(newTask);
      _tasks.add(newTask);
      draft.clear();
    } catch (e) {
      debugPrint('Error creating task: $e');
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateTask(Task task) async {
    _isSaving = true;
    notifyListeners();

    try {
      // Simulate 2-second network delay as required
      await Future.delayed(const Duration(seconds: 2));

      final updated = task.copyWith(updatedAt: DateTime.now());
      await _db.updateTask(updated);
      final index = _tasks.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
        _tasks[index] = updated;
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _db.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
      // Also clear blocked references in memory
      _tasks = _tasks.map((t) {
        if (t.blockedByTaskId == id) {
          return t.copyWith(blockedByTaskId: () => null);
        }
        return t;
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  // ── Quick status update (2s delay matches spec requirement for all updates) ──
  Future<void> quickStatusUpdate(String taskId, TaskStatus newStatus) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    _savingTaskIds.add(taskId);
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      final updated = _tasks[index].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      _tasks[index] = updated;
      await _db.updateTask(updated);
    } catch (e) {
      debugPrint('Error updating status: $e');
    } finally {
      _savingTaskIds.remove(taskId);
      notifyListeners();
    }
  }

  // ── Reorder (Stretch goal: drag-and-drop) ──
  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    final filtered = filteredTasks;
    if (oldIndex < 0 || oldIndex >= filtered.length) return;
    if (newIndex > oldIndex) newIndex--;
    if (newIndex < 0 || newIndex >= filtered.length) return;
    if (oldIndex == newIndex) return;

    // Work on filtered list, then map back to _tasks
    final reordered = List<Task>.from(filtered);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    // Build new full list: keep non-filtered tasks in place,
    // replace filtered tasks with reordered versions
    final filteredIds = reordered.map((t) => t.id).toSet();
    final newTasks = <Task>[];
    int reorderIdx = 0;

    for (final task in _tasks) {
      if (filteredIds.contains(task.id)) {
        newTasks.add(reordered[reorderIdx]);
        reorderIdx++;
      } else {
        newTasks.add(task);
      }
    }

    // Reassign sort orders
    for (int i = 0; i < newTasks.length; i++) {
      newTasks[i] = newTasks[i].copyWith(sortOrder: i);
    }
    _tasks = newTasks;
    notifyListeners();

    try {
      await _db.updateSortOrders(_tasks);
    } catch (e) {
      debugPrint('Error saving sort order: $e');
    }
  }

  // ── Search (debounced at 300ms for stretch goal) ──
  void setSearchQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      notifyListeners();
    });
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    _searchQuery = '';
    notifyListeners();
  }

  // ── Filter ──
  void setStatusFilter(TaskStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  // ── Helpers ──
  Task? getTaskById(String id) {
    return _tasks.where((t) => t.id == id).firstOrNull;
  }

  /// Returns tasks that can be selected as a blocker for the given task id.
  /// Excludes the task itself and any candidate that would create a cycle.
  List<Task> availableBlockers(String? excludeTaskId) {
    return _tasks.where((t) {
      if (t.id == excludeTaskId) return false;
      if (excludeTaskId == null) return true;
      return !_wouldCreateCycle(candidateId: t.id, taskId: excludeTaskId);
    }).toList();
  }

  /// Returns true if making [candidateId] a blocker of [taskId] would create a cycle.
  bool _wouldCreateCycle({required String candidateId, required String taskId}) {
    String? current = candidateId;
    final visited = <String>{};
    while (current != null) {
      if (current == taskId) return true;
      if (!visited.add(current)) break; // already seen — existing cycle, stop
      current = _tasks.where((t) => t.id == current).firstOrNull?.blockedByTaskId;
    }
    return false;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
