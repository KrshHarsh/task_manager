import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/app_theme.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task; // null = create mode, non-null = edit mode

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TaskProvider _provider;
  DateTime? _dueDate;
  TaskStatus _status = TaskStatus.todo;
  String? _blockedByTaskId;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _provider = context.read<TaskProvider>();

    if (isEditing) {
      // Edit mode: populate from existing task
      _titleController = TextEditingController(text: widget.task!.title);
      _descriptionController =
          TextEditingController(text: widget.task!.description);
      _dueDate = widget.task!.dueDate;
      _status = widget.task!.status;
      _blockedByTaskId = widget.task!.blockedByTaskId;
    } else {
      // Create mode: restore from draft
      _titleController = TextEditingController(text: _provider.draft.title);
      _descriptionController =
          TextEditingController(text: _provider.draft.description);
      _dueDate = _provider.draft.dueDate;
      _blockedByTaskId = _provider.draft.blockedByTaskId;
    }
  }

  @override
  void dispose() {
    // Save draft on dispose (only in create mode)
    if (!isEditing) {
      _provider.draft.title = _titleController.text;
      _provider.draft.description = _descriptionController.text;
      _provider.draft.dueDate = _dueDate;
      _provider.draft.blockedByTaskId = _blockedByTaskId;
    }
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.accent,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return;
    }

    final provider = context.read<TaskProvider>();

    try {
      if (isEditing) {
        final updated = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: _dueDate,
          status: _status,
          blockedByTaskId: () => _blockedByTaskId,
        );
        await provider.updateTask(updated);
      } else {
        final newTask = Task(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: _dueDate!,
          status: _status,
          blockedByTaskId: _blockedByTaskId,
        );
        await provider.createTask(newTask);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final theme = Theme.of(context);
    final blockerOptions = provider.availableBlockers(widget.task?.id);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Title ──
            _SectionLabel(label: 'TITLE'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'What needs to be done?',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Description ──
            _SectionLabel(label: 'DESCRIPTION'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              style: theme.textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Add more details...',
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Due Date ──
            _SectionLabel(label: 'DUE DATE'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate != null
                          ? DateFormat('EEEE, MMM d, yyyy').format(_dueDate!)
                          : 'Select a date',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: _dueDate != null
                            ? AppTheme.textPrimary
                            : AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Status ──
            _SectionLabel(label: 'STATUS'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TaskStatus>(
                  value: _status,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  borderRadius: BorderRadius.circular(12),
                  items: TaskStatus.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppTheme.statusColor(s.label),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(s.label,
                                    style: theme.textTheme.bodyLarge),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Blocked By ──
            _SectionLabel(label: 'BLOCKED BY (OPTIONAL)'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _blockedByTaskId,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  borderRadius: BorderRadius.circular(12),
                  hint: Text('None',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: AppTheme.textTertiary)),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child:
                          Text('None', style: theme.textTheme.bodyLarge),
                    ),
                    ...blockerOptions.map((t) => DropdownMenuItem<String?>(
                          value: t.id,
                          child: Text(
                            t.title,
                            style: theme.textTheme.bodyLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (v) => setState(() => _blockedByTaskId = v),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── Save Button ──
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: provider.isSaving ? null : _save,
                child: provider.isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(isEditing ? 'Update Task' : 'Create Task'),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: AppTheme.textTertiary,
          ),
    );
  }
}
