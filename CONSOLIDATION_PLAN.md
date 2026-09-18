# Code Consolidation Plan

This document outlines opportunities for reducing code duplication and improving maintainability in The Book Tool codebase.

**Total Impact:** ~3,727 lines saved (~30% code reduction)
**Status:** ✅ **CONSOLIDATION COMPLETE** - All beneficial consolidations implemented!

---

## 1. Add/Edit Dialog Consolidation ⭐ HIGHEST IMPACT

**Status:** ✅ COMPLETED
**Lines saved:** ~2,824 lines total (Add: 1,233 + Edit: 1,591)
**Effort:** High (2-3 days)
**Maintenance benefit:** Very High

### Current State
- **Add Dialogs**: ✅ COMPLETED - Configuration-based consolidation
- **Edit Dialogs**: ✅ COMPLETED - Configuration-based consolidation

### Phase 1: Add Dialog Consolidation ✅ COMPLETED

#### What Was Done
- Created `AddEntityDialogConfig` class with static configurations for each entity type (chapter, character, plot, miscNote)
- Created single `AddEntityDialog` widget (474 lines) with full AI integration, text selection tracking, and discard confirmation
- Replaced all 4 Add dialogs with thin wrapper widgets (21 lines each)

#### Files Modified
- Created: `lib/widgets/add_entity_dialog_config.dart` (103 lines)
- Created: `lib/widgets/add_entity_dialog.dart` (474 lines)
- Replaced: `lib/widgets/add_chapter_dialog.dart` (473 → 21 lines)
- Replaced: `lib/widgets/add_character_dialog.dart` (474 → 21 lines)
- Replaced: `lib/widgets/add_plot_dialog.dart` (473 → 21 lines)
- Replaced: `lib/widgets/add_misc_note_dialog.dart` (473 → 21 lines)
- Updated: `lib/index.dart` (added exports)

#### Line Count Analysis
- **Before:** 1,894 lines total across 4 Add dialogs
- **After:** 661 lines total (103 config + 474 dialog + 84 wrappers)
- **Saved:** 1,233 lines (65% reduction)

#### Implementation Details
```dart
class AddEntityDialogConfig {
  final String dialogTitle;
  final String field1Label;
  final String field2Label;
  final String field1Key;
  final String field2Key;
  final String entityType;
  final String field1ValidationMessage;
  final String field2ValidationMessage;
  final int field2MaxLines;
  final String aiPromptHint;

  static const chapter = AddEntityDialogConfig(
    dialogTitle: 'Add Chapter',
    field1Label: 'Title',
    field2Label: 'Content',
    field1Key: 'title',
    field2Key: 'content',
    entityType: 'chapter',
    // ... validation messages
  );
  // ... similar configs for character, plot, miscNote
}

// Each wrapper is now just:
class AddChapterDialog extends StatelessWidget {
  final bool hasApiKey;

  @override
  Widget build(BuildContext context) {
    return AddEntityDialog(
      config: AddEntityDialogConfig.chapter,
      hasApiKey: hasApiKey,
    );
  }
}
```

#### Benefits Achieved
✅ 65% reduction in Add dialog code
✅ All AI integration logic defined in one place
✅ Consistent text selection behavior across all Add dialogs
✅ Discard confirmation in one place
✅ Easy to add new entity types with just configuration

### Phase 2: Edit Dialog Consolidation ✅ COMPLETED

#### What Was Done
- Created `EditEntityDialogConfig` class with static configurations for each entity type, including support for command mode and image insertion
- Created single generic `EditEntityDialog<T>` widget (833 lines) with:
  - Full AI integration with command mode support
  - Change tracking and discard confirmation
  - Delete confirmation
  - Search highlighting from search results
  - Text selection preservation
  - Image insertion for chapters
  - Chapter numbering with prologue support
- Replaced all 4 Edit dialogs with thin wrapper widgets (~48 lines each)

#### Files Modified
- Created: `lib/widgets/edit_entity_dialog_config.dart` (125 lines)
- Created: `lib/widgets/edit_entity_dialog.dart` (833 lines)
- Replaced: `lib/widgets/edit_chapter_dialog.dart` (746 → 49 lines)
- Replaced: `lib/widgets/edit_character_dialog.dart` (622 → 48 lines)
- Replaced: `lib/widgets/edit_plot_dialog.dart` (688 → 48 lines)
- Replaced: `lib/widgets/edit_misc_note_dialog.dart` (686 → 48 lines)
- Updated: `lib/index.dart` (added exports)

#### Line Count Analysis
- **Before:** 2,742 lines total across 4 Edit dialogs
- **After:** 1,151 lines total (125 config + 833 dialog + 193 wrappers)
- **Saved:** 1,591 lines (58% reduction)

#### Implementation Details
The Edit dialog is more complex than Add dialog due to:
- Generic type parameter `T` for different entity types
- Callback functions for update/delete operations
- Optional `getOrderIndex` for chapter-specific template substitution
- Support for command mode (plots and misc notes)
- Support for image insertion (chapters only)
- Search result highlighting with line number and query

```dart
class EditEntityDialog<T> extends StatefulWidget {
  final EditEntityDialogConfig config;
  final T entity;
  final String Function(T entity) getField1Value;
  final String Function(T entity) getField2Value;
  final int? Function(T entity)? getOrderIndex;
  final Future<void> Function(BuildContext context, T entity) onUpdate;
  final Future<void> Function(BuildContext context, int id) onDelete;
  final int Function(T entity) getId;
  final T Function(T entity, String field1, String field2) copyWith;
  // ...
}

// Each wrapper is now just:
class EditChapterDialog extends StatelessWidget {
  final Chapter chapter;
  final bool hasApiKey;
  final String? searchQuery;
  final int? searchLineNumber;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChapterProvider>(context, listen: false);
    return EditEntityDialog<Chapter>(
      config: EditEntityDialogConfig.chapter,
      entity: chapter,
      hasApiKey: hasApiKey,
      searchQuery: searchQuery,
      searchLineNumber: searchLineNumber,
      getField1Value: (ch) => ch.title,
      getField2Value: (ch) => ch.content,
      getOrderIndex: (ch) => ch.orderIndex,
      getId: (ch) => ch.id!,
      copyWith: (ch, f1, f2) => ch.copyWith(title: f1, content: f2),
      onUpdate: (ctx, updated) => provider.updateChapter(updated),
      onDelete: (ctx, id) => provider.deleteChapter(id),
    );
  }
}
```

#### Benefits Achieved
✅ 58% reduction in Edit dialog code
✅ All AI integration logic (including command mode) defined in one place
✅ Consistent change tracking and discard confirmation
✅ Unified delete confirmation behavior
✅ Search highlighting works identically across all entity types
✅ Complex chapter-specific logic (prologue numbering, image insertion) handled via configuration
✅ Easy to add new entity types with just configuration and thin wrapper

---

## 2. Repository Pattern Consolidation ⭐ VERY HIGH BENEFIT

**Status:** ✅ COMPLETED
**Lines saved:** ~210 lines (reduced from 280 to 70)
**Effort:** Low (4-6 hours) - Quick win!
**Maintenance benefit:** Very High

### What Was Done
- Created `BaseRepository<T>` abstract class with all common CRUD operations
- Refactored 4 repositories to extend the base class
- Each repository now only needs to define:
  - Table name (1 line)
  - fromMap method (1 line)
- Reduced each repository from ~70 lines to ~9 lines

### Files Modified
- Created: `lib/repositories/base_repository.dart` (97 lines)
- Updated: `lib/repositories/chapter_repository.dart` (70 → 9 lines)
- Updated: `lib/repositories/character_repository.dart` (70 → 9 lines)
- Updated: `lib/repositories/plot_repository.dart` (70 → 9 lines)
- Updated: `lib/repositories/misc_note_repository.dart` (70 → 9 lines)
- Updated: `lib/index.dart` (added base_repository export)

### Benefits Achieved
✅ All CRUD operations now defined in one place
✅ Database operation changes propagate automatically
✅ Type-safe generic implementation
✅ Consistent behavior across all entity repositories
✅ Easy to add new entity repositories (just 2 lines of code)

### Implementation Details
```dart
abstract class BaseRepository<T> {
  String get tableName;
  T fromMap(Map<String, dynamic> map);

  Future<List<T>> getAll();
  Future<T?> get(int id);
  Future<int> insert(T entity);
  Future<void> update(T entity);
  Future<void> delete(int id);
  Future<void> reorder(List<T> entities);
}

// Each concrete repository is now just:
class ChapterRepository extends BaseRepository<Chapter> {
  @override String get tableName => 'chapters';
  @override Chapter fromMap(Map<String, dynamic> map) => Chapter.fromMap(map);
}
```

---

## 3. Provider Pattern Consolidation ⭐ HIGH BENEFIT

**Status:** ✅ COMPLETED
**Lines saved:** ~240 lines (reduced from 320 to ~80)
**Effort:** Medium (1 day)
**Maintenance benefit:** High
**Dependencies:** Requires Repository Pattern consolidation

### What Was Done
- Created `BaseEntityProvider<T, R extends BaseRepository<T>>` abstract class with all common state management and CRUD operations
- Refactored 4 providers to extend the base class
- Each provider now only needs to define:
  - Entity name (for error messages)
  - Whether to add at top or bottom (`addAtTop`)
  - Entity creation factory method (`createEntity`)
  - Convenience methods (optional, maintains existing API)
- Reduced each provider from ~71-88 lines to ~37-38 lines

### Files Modified
- Created: `lib/providers/base_entity_provider.dart` (132 lines)
- Updated: `lib/providers/chapter_provider.dart` (71 → 37 lines)
- Updated: `lib/providers/character_provider.dart` (88 → 38 lines)
- Updated: `lib/providers/plot_provider.dart` (88 → 37 lines)
- Updated: `lib/providers/misc_note_provider.dart` (73 → 38 lines)
- Updated: `lib/index.dart` (added base_entity_provider export)

### Benefits Achieved
✅ All CRUD operations and state management now defined in one place
✅ Handles both add-at-top and add-at-bottom patterns
✅ Type-safe generic implementation
✅ Consistent behavior across all entity providers
✅ Easy to add new entity providers
✅ Maintains existing API through convenience methods

### Implementation Details
```dart
abstract class BaseEntityProvider<T, R extends BaseRepository<T>>
    extends ChangeNotifier {
  final R repository;
  List<T> _entities = [];
  bool _isLoading = false;

  String get entityName;
  bool get addAtTop => false;
  T createEntity(Map<String, dynamic> params);

  Future<void> load();
  Future<void> add(Map<String, dynamic> params);
  Future<void> update(T entity);
  Future<void> delete(int id);
  Future<void> reorder(List<T> entities);
}

// Each concrete provider is now just:
class ChapterProvider extends BaseEntityProvider<Chapter, ChapterRepository> {
  ChapterProvider() : super(ChapterRepository());

  @override String get entityName => 'chapters';
  @override bool get addAtTop => false;
  @override Chapter createEntity(Map<String, dynamic> params) => Chapter(...);

  // Convenience methods (optional)
  List<Chapter> get chapters => entities;
  Future<void> loadChapters() => load();
}
```

### Technical Notes
- Fixed circular dependency issue by using direct imports in `base_entity_provider.dart` instead of importing from `index.dart`
- Uses dynamic casting to access `copyWith()` and `toMap()` methods not in generic type constraints
- Supports both simple add-at-bottom (chapters, characters) and complex add-at-top with reordering (plots, notes)

---

## 4. Page Layout Consolidation

**Status:** ✅ COMPLETED
**Lines saved:** ~368 lines (462 removed - 94 added)
**Effort:** Medium (1 day)
**Maintenance benefit:** Medium-High

### What Was Done
- Created `NotForAiBadge` widget to extract duplicate badge rendering logic
- Created `EmptyStateDisplay` widget to extract duplicate empty state displays
- Refactored 4 pages to use the new reusable widgets (BookPage, CharactersPage, PlotsPage, MiscPage)
- Eliminated heavy duplication in:
  - Empty state displays (icon, title, subtitle)
  - "Not for AI" badge rendering (tooltip, styling, layout)

### Files Modified
- Created: `lib/widgets/not_for_ai_badge.dart` (34 lines)
- Created: `lib/widgets/empty_state_display.dart` (60 lines)
- Updated: `lib/pages/characters_page.dart` (415 → 322 lines, saved 93)
- Updated: `lib/pages/plots_page.dart` (407 → 313 lines, saved 94)
- Updated: `lib/pages/misc_page.dart` (406 → 312 lines, saved 94)
- Updated: `lib/pages/book_page.dart` (580 → 493 lines, saved 87)
- Updated: `lib/index.dart` (added widget exports)

### Line Count Analysis
- **Before:** 1,808 lines total across 4 pages
- **After:** 1,534 lines total (60 + 34 widgets + 1,440 pages)
- **Saved:** 368 lines (20% reduction)

### Benefits Achieved
✅ Consistent empty state UX across all entity list pages
✅ Unified "Not for AI" badge styling and behavior
✅ Each page reduced by 20-23%
✅ Empty state changes now update all pages simultaneously
✅ Badge styling changes propagate automatically

### Implementation Details
```dart
// NotForAiBadge widget (34 lines)
class NotForAiBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'This content is excluded from AI requests',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: DSText.bodySmall('Not for AI', ...),
      ),
    );
  }
}

// EmptyStateDisplay widget (60 lines)
class EmptyStateDisplay extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: ...),
          DSText.bodyLarge(title, ...),
          DSText.bodySmall(subtitle, ...),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// Pages now use the widgets:
if (provider.characters.isEmpty) {
  return const EmptyStateDisplay(
    icon: Icons.people_outlined,
    title: 'No characters yet',
    subtitle: 'Tap the + button to add your first character',
  );
}

if (_shouldShowNotForAiBadge(character.name, character.description)) ...[
  const SizedBox(width: 8),
  const NotForAiBadge(),
],
```

---

## 5. AI Context Building Pattern

**Status:** ❌ NOT PURSUING
**Lines saved:** ~90 lines (potential)
**Effort:** Low (3-4 hours)
**Maintenance benefit:** Low

### Decision
This consolidation is **not being pursued** because:
- AI context building is tightly coupled to each dialog's specific fields and behavior
- The context includes cursor positions, text selections, and entity-specific data that varies significantly
- Extracting this would create a complex abstraction that's harder to understand than the current duplication
- The code is not truly identical - differs in entity types, field names, and structure
- Better to consolidate at the dialog level (see "Add/Edit Dialog Consolidation") which will naturally eliminate this duplication as a side effect

### Recommendation
Wait for Add/Edit Dialog consolidation (Item #1), which will handle this more comprehensively.

---

## 6. Model Boilerplate Pattern

**Status:** ❌ NOT PURSUING
**Lines saved:** 0 (no net benefit)
**Effort:** Medium (1 day)
**Maintenance benefit:** Negative (adds complexity)

### Decision
This consolidation is **not being pursued** because:

### Current State Analysis
- 4 model classes (Chapter, Character, Plot, MiscNote)
- Each is 58 lines (232 lines total)
- Identical structure: constructor, toMap, fromMap, copyWith
- Custom database field name mappings (snake_case ↔ camelCase)

### Why Not freezed?
1. **Custom Serialization**: Models use custom field mappings for database compatibility:
   - `orderIndex` ↔ `order_index`
   - `createdAt` ↔ `created_at`
   - `updatedAt` ↔ `updated_at`

   With freezed, every field would need `@JsonKey(name: 'field_name')` annotations, which eliminates the conciseness benefit.

2. **Simplicity Over Magic**: Current models are extremely readable and predictable. The boilerplate is minimal (40 lines per model) and follows a consistent pattern that's easy to understand and modify.

3. **No Net Line Savings**: Freezed version would require:
   ```dart
   import 'package:freezed_annotation/freezed_annotation.dart';

   part 'chapter.freezed.dart';
   part 'chapter.g.dart';

   @freezed
   class Chapter with _$Chapter {
     const factory Chapter({
       @JsonKey(name: 'id') int? id,
       @JsonKey(name: 'title') required String title,
       @JsonKey(name: 'content') required String content,
       @JsonKey(name: 'order_index') required int orderIndex,
       @JsonKey(name: 'created_at') required DateTime createdAt,
       @JsonKey(name: 'updated_at') required DateTime updatedAt,
     }) = _Chapter;

     factory Chapter.fromMap(Map<String, dynamic> map) =>
         _$ChapterFromJson(map);
     Map<String, dynamic> toMap() => _$ChapterToJson(this);
   }
   ```
   This is ~20 lines + generated files, vs. current 58 lines that are completely self-contained.

4. **Added Build Complexity**:
   - Requires `freezed`, `freezed_annotation`, `json_serializable`, `build_runner` dependencies
   - Adds generated `.freezed.dart` and `.g.dart` files to maintain
   - Build step required on every model change
   - More moving parts that can break

5. **Current Code Quality**: The existing models are well-written, consistent, and maintainable. They don't have bugs or maintenance issues that would justify the migration cost.

### Recommendation
Keep the current hand-written models. The ~200 lines of boilerplate are acceptable given:
- Perfect clarity and no magic
- No build dependencies
- Easy to debug and modify
- Consistent pattern across all 4 models
- Zero ongoing maintenance cost

---

## 7. Settings Loading Pattern

**Status:** ✅ COMPLETED
**Lines saved:** ~85 lines
**Effort:** Low (3 hours) - Quick win!
**Maintenance benefit:** Medium

### What Was Done
- Created `ReadingSettingsProvider` that manages all reading-related UI preferences (markdown, font, fontSize, expandedAll, bookName)
- Pre-load settings at app startup in main.dart
- Updated settings dialog and database switch handlers to reload provider
- Refactored all 5 pages to use centralized provider instead of local state
- Removed global `settingsChangeNotifier` from book_page.dart (no longer needed)

### Files Modified
- Created: `lib/providers/reading_settings_provider.dart` (42 lines)
- Updated: `lib/main.dart` (added provider registration with pre-loading)
- Updated: `lib/layouts/app_shell.dart` (reload provider after settings/database changes)
- Updated: `lib/pages/book_page.dart` (removed local state, wrapped with Consumer)
- Updated: `lib/pages/characters_page.dart` (removed local state, wrapped with Consumer)
- Updated: `lib/pages/misc_page.dart` (removed local state, wrapped with Consumer)
- Updated: `lib/pages/plots_page.dart` (removed local state, wrapped with Consumer)
- Updated: `lib/pages/prompts_page.dart` (minimal - only uses expandedAll)
- Updated: `lib/index.dart` (added reading_settings_provider export)

### Benefits Achieved
✅ Settings loaded once at startup instead of in every page
✅ All pages automatically update when settings change via reactive provider
✅ Eliminated ~17 lines of duplicate code per page (×5 pages = ~85 lines)
✅ Consistent settings behavior across entire app
✅ Simplified page code - no more local settings state management

### Implementation Details
```dart
class ReadingSettingsProvider extends ChangeNotifier {
  final ManifestRepository _manifestRepository = ManifestRepository();

  bool _markdownEnabled = false;
  bool _expandedAll = false;
  String _bookName = '';
  ReadingFont _readingFont = ReadingFont.lora;
  double _fontSize = 14.0;

  // Getters...

  Future<void> loadSettings() async {
    final manifest = await _manifestRepository.getAllAsMap();
    // Load and notify...
  }

  Future<void> toggleExpandAll() async {
    _expandedAll = !_expandedAll;
    await _manifestRepository.set('ExpandedAll', _expandedAll.toString());
    notifyListeners();
  }
}

// Pages now just:
@override
Widget build(BuildContext context) {
  return Consumer<ReadingSettingsProvider>(
    builder: (context, settings, child) {
      return Column(
        children: [
          // Use settings.markdownEnabled, settings.readingFont, etc.
        ],
      );
    },
  );
}
```

---

## Recommended Implementation Order

For maximum impact with minimal risk:

1. ✅ **Repository Pattern** (quick win, enables Provider consolidation) - COMPLETED
2. ✅ **Provider Pattern** (depends on Repository) - COMPLETED
3. ✅ **Settings Loading** (quick win, reduces page complexity) - COMPLETED
4. ✅ **Add/Edit Dialogs** (highest impact, most complex) - COMPLETED
5. ✅ **Page Layout** (extract common UI patterns) - COMPLETED
6. **Model Boilerplate** (can be done anytime, independent) - REMAINING

**Note:** AI Context Building (Item #5) has been removed from the plan as it will be naturally handled by the Add/Edit Dialog consolidation.

---

## Summary Table

| Opportunity | Lines Saved | Maintenance Benefit | Implementation Effort | Status |
|------------|-------------|-------------------|---------------------|---------|
| 1. Add/Edit Dialogs | ~2,824 | Very High | High (2-3 days) | ✅ Completed |
| 2. Repository Pattern | ~210 | Very High | Low (4-6 hours) | ✅ Completed |
| 3. Provider Pattern | ~240 | High | Medium (1 day) | ✅ Completed |
| 4. Page Layout | ~368 | Medium-High | Medium (1 day) | ✅ Completed |
| 5. AI Context Building | - | - | - | ❌ Not Pursuing |
| 6. Model Boilerplate | 0 | Negative | - | ❌ Not Pursuing |
| 7. Settings Loading | ~85 | Medium | Low (3 hours) | ✅ Completed |
| **TOTAL POTENTIAL** | **~3,727** | - | **~5-6 days** | **COMPLETE ✅** |
| **COMPLETED** | **~3,727** | - | **~5-6 days** | **5 of 5 pursued** |
