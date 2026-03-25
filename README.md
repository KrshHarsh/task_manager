# Task Manager — Flodo AI Take-Home

A polished, feature-complete task management app built with Flutter, following **Track B: The Mobile Specialist**.

## ✨ Features

### Core Requirements (All Implemented)
- **CRUD Operations** — Create, read, update, and delete tasks with title, description, due date, status, and optional "blocked by" dependency
- **Blocked Task Visualization** — Tasks blocked by an incomplete dependency appear visually greyed out with a lock indicator and blocked status badge
- **Draft Persistence** — If you start typing a new task and accidentally navigate away (back swipe, minimize), your text remains when you return to the creation screen
- **Search** — Debounced text search (300ms) that filters tasks by title in real-time
- **Filter** — Horizontal filter chips to filter by status (To-Do, In Progress, Done)
- **2-Second Save Delay** — Simulated on both create and update; shows a loading spinner, disables the save button to prevent double-taps, and keeps the UI responsive

### Stretch Goal: Debounced Autocomplete Search
- Search input debounces at 300ms after the user stops typing
- Matching text within task titles is **highlighted** with the accent color
- Smooth animated search bar with focus state transitions

### Bonus: Persistent Drag-and-Drop Reordering
- Long-press to drag tasks and reorder them
- Custom sort order is persisted to SQLite and survives app restarts
- Lift animation with subtle scale + shadow feedback

## 🏗 Architecture

```
lib/
├── main.dart                  # App entry point
├── models/
│   ├── task.dart              # Task data model with enum status
│   └── task_draft.dart        # Draft model for form persistence
├── providers/
│   └── task_provider.dart     # Central state management (ChangeNotifier + Provider)
├── screens/
│   ├── task_list_screen.dart  # Main list view with header, FAB, reorder
│   └── task_form_screen.dart  # Create/edit form with validation
├── widgets/
│   ├── task_card.dart         # Task card with status chip, blocked state, slidable delete
│   ├── search_filter_bar.dart # Search input + filter chips
│   └── empty_state.dart       # Empty/no-results placeholder
└── utils/
    ├── app_theme.dart         # Design system: colors, typography, decorations
    └── database_helper.dart   # SQLite CRUD + batch sort order updates
```

### Key Technical Decisions

1. **Provider + ChangeNotifier** — Chosen over Riverpod/Bloc for simplicity given the app scope. Clean separation between UI and business logic without boilerplate overhead.

2. **SQLite via sqflite** — Relational database is a natural fit for task dependencies (`blockedByTaskId` foreign key). Handles cascading cleanup on delete (clears blocked references).

3. **Draft persistence in memory** — The `TaskDraft` object lives in the provider and survives navigation. It's cleared only on successful save, meaning accidental back-swipes, home button presses, or app minimization all preserve the user's typed content.

4. **Debounced search with Timer** — A 300ms `Timer` in the provider ensures we don't re-filter on every keystroke, while still feeling instant to the user.

5. **Design system as a single source of truth** — `AppTheme` centralizes every color, font, and decoration. No magic hex codes scattered across widgets.

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK ≥ 3.1.0 ([install guide](https://docs.flutter.dev/get-started/install))
- Dart SDK (bundled with Flutter)
- Android Studio / Xcode for device/emulator

### Run the app

```bash
# Clone the repository
git clone https://github.com/KrshHarsh/task_manager
cd task_manager

# Generate platform-specific files (android/, ios/, web/, etc.)
flutter create . --project-name task_manager

# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

> **Note:** The `flutter create .` step generates the android/, ios/, and web/ directories. 
> It won't overwrite any existing Dart source files — it only adds the missing platform scaffolding.

### Run on specific platform

```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# Chrome (web)
flutter run -d chrome
```

## 📋 Track & Stretch Goal

| Item | Choice |
|------|--------|
| **Track** | B — The Mobile Specialist |
| **Stretch Goal** | Debounced Autocomplete Search (with highlighted matches) |
| **Bonus** | Persistent Drag-and-Drop Reordering |

## 🤖 AI Usage Report

AI tools (Claude) were used to accelerate development.

### Most Helpful Prompts

- **SQLite schema + DatabaseHelper scaffold:**
  > "Write a Flutter DatabaseHelper singleton using sqflite. The tasks table needs: id (TEXT PRIMARY KEY), title, description, dueDate (INTEGER unix ms), status (TEXT), blockedByTaskId (TEXT nullable), sortOrder (INTEGER), createdAt, updatedAt. Include getAllTasks(), insertTask(), updateTask(), deleteTask(), and a batch updateSortOrders() method."

- **Debounced search with text highlighting:**
  > "In Flutter, implement a 300ms debounced search using dart:async Timer in a ChangeNotifier provider. Then in a StatelessWidget, render a RichText that highlights all case-insensitive matches of the search query within a title string using a contrasting background color."

- **ReorderableListView with filtered data:**
  > "I have a ReorderableListView.builder showing a filtered subset of a list. When the user reorders, I need to map the old/new indices back to the full unfiltered list and persist the new sortOrder to SQLite. Show me the reorderTasks() method in my ChangeNotifier."

- **Circular dependency guard for the blockedBy dropdown:**
  > "In my task manager, a task can be blocked by one other task. Write a method availableBlockers(String? excludeTaskId) that filters out the task itself and any candidate that would create a cycle — e.g. if A is already blocked by B, then B should not be allowed to be blocked by A."

### AI Corrections Needed

- **Deprecated color API:** Initial generated code used `.withOpacity()`, which is deprecated in Flutter 3.x. Manually updated all calls to `.withValues(alpha:)`.
- **ReorderableListView proxy decorator:** The AI's first attempt at the drag-lift animation used a plain `Material` wrapper that caused a layout exception. Fixed by wrapping in an explicit `AnimatedBuilder` with a `Transform.scale`.
- **Draft persistence on edit vs. create:** The AI saved draft state in both create and edit modes. Manually added the `if (!isEditing)` guard in `dispose()` so editing an existing task never overwrites the creation draft.

## 📱 Demo

[Link to demo video on Google Drive]
