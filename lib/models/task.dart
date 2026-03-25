import 'package:uuid/uuid.dart';

enum TaskStatus {
  todo('To-Do'),
  inProgress('In Progress'),
  done('Done');

  final String label;
  const TaskStatus(this.label);

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => TaskStatus.todo,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final String? blockedByTaskId;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    String? id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = TaskStatus.todo,
    this.blockedByTaskId,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    String? Function()? blockedByTaskId,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedByTaskId:
          blockedByTaskId != null ? blockedByTaskId() : this.blockedByTaskId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'blockedByTaskId': blockedByTaskId,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
      status: TaskStatus.fromString(map['status'] as String),
      blockedByTaskId: map['blockedByTaskId'] as String?,
      sortOrder: map['sortOrder'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  bool isBlocked(List<Task> allTasks) {
    if (blockedByTaskId == null) return false;
    final blocker = allTasks.where((t) => t.id == blockedByTaskId).firstOrNull;
    if (blocker == null) return false;
    return blocker.status != TaskStatus.done;
  }

  String? getBlockerTitle(List<Task> allTasks) {
    if (blockedByTaskId == null) return null;
    final blocker = allTasks.where((t) => t.id == blockedByTaskId).firstOrNull;
    return blocker?.title;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Task && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
