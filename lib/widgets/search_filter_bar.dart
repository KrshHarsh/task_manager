import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/app_theme.dart';

class SearchFilterBar extends StatefulWidget {
  const SearchFilterBar({super.key});

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // ── Search bar ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isSearchExpanded ? AppTheme.accent : AppTheme.divider,
                width: _isSearchExpanded ? 1.5 : 0.5,
              ),
              boxShadow: _isSearchExpanded
                  ? [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color:
                      _isSearchExpanded ? AppTheme.accent : AppTheme.textTertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      provider.setSearchQuery(value);
                    },
                    onTap: () => setState(() => _isSearchExpanded = true),
                    onTapOutside: (_) {
                      FocusScope.of(context).unfocus();
                      if (_searchController.text.isEmpty) {
                        setState(() => _isSearchExpanded = false);
                      }
                    },
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Search tasks...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      provider.clearSearch();
                      setState(() => _isSearchExpanded = false);
                      FocusScope.of(context).unfocus();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: AppTheme.textTertiary),
                    ),
                  ),
                const SizedBox(width: 6),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Filter chips ──
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: provider.statusFilter == null,
                  onTap: () => provider.setStatusFilter(null),
                ),
                const SizedBox(width: 8),
                ...TaskStatus.values.map((status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: status.label,
                        isSelected: provider.statusFilter == status,
                        color: AppTheme.statusColor(status.label),
                        onTap: () => provider.setStatusFilter(
                          provider.statusFilter == status ? null : status,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withOpacity(0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? effectiveColor : AppTheme.divider,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? effectiveColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
