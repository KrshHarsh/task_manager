/// Stores draft form data so users don't lose typed content
/// when they accidentally navigate away or minimize the app.
class TaskDraft {
  String title;
  String description;
  DateTime? dueDate;
  String? blockedByTaskId;

  TaskDraft({
    this.title = '',
    this.description = '',
    this.dueDate,
    this.blockedByTaskId,
  });

  bool get isEmpty =>
      title.trim().isEmpty &&
      description.trim().isEmpty &&
      dueDate == null &&
      blockedByTaskId == null;

  void clear() {
    title = '';
    description = '';
    dueDate = null;
    blockedByTaskId = null;
  }
}
