import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/task.dart';
import '../utils/app_theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool isBlocked;
  final bool isSaving;
  final String? blockerTitle;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<TaskStatus> onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.isBlocked,
    this.isSaving = false,
    this.blockerTitle,
    this.searchQuery = '',
    required this.onTap,
    required this.onDelete,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue =
        task.dueDate.isBefore(DateTime.now()) && task.status != TaskStatus.done;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Slidable(
        key: ValueKey(task.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            CustomSlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppTheme.error,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                  SizedBox(height: 4),
                  Text('Delete',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration:
                isBlocked ? AppTheme.blockedCardDecoration : AppTheme.cardDecoration,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row: Status chip + Due date ──
                  Row(
                    children: [
                      _StatusChip(
                        status: task.status,
                        isBlocked: isBlocked,
                        isSaving: isSaving,
                        onChanged: (isBlocked || isSaving) ? null : onStatusChanged,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: isOverdue
                            ? AppTheme.error
                            : isBlocked
                                ? AppTheme.blocked
                                : AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(task.dueDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isOverdue
                              ? AppTheme.error
                              : isBlocked
                                  ? AppTheme.blocked
                                  : null,
                          fontWeight: isOverdue ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Title with optional search highlighting ──
                  _HighlightedTitle(
                    title: task.title,
                    query: searchQuery,
                    isBlocked: isBlocked,
                    isDone: task.status == TaskStatus.done,
                    style: theme.textTheme.titleMedium!,
                  ),

                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            isBlocked ? AppTheme.blocked : AppTheme.textSecondary,
                      ),
                    ),
                  ],

                  // ── Blocked indicator ──
                  if (isBlocked && blockerTitle != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.warningLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              size: 13, color: AppTheme.warning),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Blocked by "$blockerTitle"',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.warning,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status Chip ──
class _StatusChip extends StatelessWidget {
  final TaskStatus status;
  final bool isBlocked;
  final bool isSaving;
  final ValueChanged<TaskStatus>? onChanged;

  const _StatusChip({
    required this.status,
    required this.isBlocked,
    this.isSaving = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isBlocked ? AppTheme.blocked : AppTheme.statusColor(status.label);
    final bgColor = isBlocked
        ? AppTheme.blockedBg
        : AppTheme.statusBgColor(status.label);

    final chipChild = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSaving)
            SizedBox(
              width: 9,
              height: 9,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 6),
          Text(
            isBlocked ? 'Blocked' : status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (!isBlocked && !isSaving) ...[
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: color),
          ],
        ],
      ),
    );

    if (isSaving || isBlocked) return chipChild;

    return PopupMenuButton<TaskStatus>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 36),
      itemBuilder: (_) => TaskStatus.values
          .map((s) => PopupMenuItem(
                value: s,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.statusColor(s.label),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(s.label),
                  ],
                ),
              ))
          .toList(),
      child: chipChild,
    );
  }
}

// ── Highlighted title for search results ──
class _HighlightedTitle extends StatelessWidget {
  final String title;
  final String query;
  final bool isBlocked;
  final bool isDone;
  final TextStyle style;

  const _HighlightedTitle({
    required this.title,
    required this.query,
    required this.isBlocked,
    required this.isDone,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style.copyWith(
      color: isBlocked ? AppTheme.blocked : null,
      decoration: isDone ? TextDecoration.lineThrough : null,
      decorationColor: AppTheme.textTertiary,
    );

    if (query.isEmpty) {
      return Text(title, style: baseStyle, maxLines: 2, overflow: TextOverflow.ellipsis);
    }

    final lowerTitle = title.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lowerTitle.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: title.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: title.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: title.substring(idx, idx + query.length),
        style: TextStyle(
          backgroundColor: AppTheme.accentLight,
          color: AppTheme.accent,
          fontWeight: FontWeight.w700,
        ),
      ));
      start = idx + query.length;
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
