import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/task_card.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/empty_state.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );

    // Load tasks and animate FAB
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks().then((_) {
        _fabController.forward();
      });
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _openCreateForm() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const TaskFormScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _openEditForm(Task task) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => TaskFormScreen(task: task),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<TaskProvider>().deleteTask(task.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${task.title}" deleted'),
                  action: SnackBarAction(
                    label: 'OK',
                    onPressed: () {},
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final theme = Theme.of(context);
    final tasks = provider.filteredTasks;
    final allTasks = provider.allTasks;
    final hasFilters =
        provider.searchQuery.isNotEmpty || provider.statusFilter != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tasks', style: theme.textTheme.displayLarge),
                        const SizedBox(height: 2),
                        Text(
                          '${allTasks.where((t) => t.status != TaskStatus.done).length} remaining · ${allTasks.where((t) => t.status == TaskStatus.done).length} completed',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  // Small task count badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${allTasks.length}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Search + Filter ──
            const SearchFilterBar(),

            const SizedBox(height: 8),

            // ── Task List ──
            Expanded(
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    )
                  : tasks.isEmpty
                      ? EmptyState(isFiltered: hasFilters)
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 100),
                          itemCount: tasks.length,
                          proxyDecorator: (child, index, animation) {
                            final animValue = Tween<double>(begin: 1.0, end: 1.03)
                                .animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            ));
                            return AnimatedBuilder(
                              animation: animValue,
                              builder: (context, _) {
                                return Transform.scale(
                                  scale: animValue.value,
                                  child: Material(
                                    color: Colors.transparent,
                                    elevation: 8,
                                    shadowColor: AppTheme.accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    child: child,
                                  ),
                                );
                              },
                            );
                          },
                          onReorder: (oldIdx, newIdx) {
                            provider.reorderTasks(oldIdx, newIdx);
                          },
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            final isBlocked = task.isBlocked(allTasks);
                            final blockerTitle =
                                task.getBlockerTitle(allTasks);

                            return TaskCard(
                              key: ValueKey(task.id),
                              task: task,
                              isBlocked: isBlocked,
                              isSaving: provider.isTaskSaving(task.id),
                              blockerTitle: blockerTitle,
                              searchQuery: provider.searchQuery,
                              onTap: () => _openEditForm(task),
                              onDelete: () => _confirmDelete(context, task),
                              onStatusChanged: (newStatus) {
                                provider.quickStatusUpdate(
                                    task.id, newStatus);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _openCreateForm,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text('New Task'),
        ),
      ),
    );
  }
}
