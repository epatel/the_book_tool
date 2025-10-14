# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

The Book Tool is a Flutter application for book writing, helping authors organize chapters, characters, plot ideas, and miscellaneous notes. The app uses a stationary navigation panel layout (not a drawer) with four main sections.

## Development Commands

### Running the App
```bash
flutter run
```

### Testing
```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Analyze for errors
# Use the mcp__dart__analyze_files tool instead of running dart analyze directly
```

### Code Quality
```bash
# Format code
flutter pub run dart format .

# Get dependencies
flutter pub get
```

## Architecture

### Import System
**Critical**: This project uses a centralized import system via `lib/index.dart`. All Dart files in the project must import from this single file using absolute package imports:

```dart
import 'package:the_book_tool/index.dart';
```

The `index.dart` file:
- Uses relative paths for its exports
- Exports all external packages (flutter/material, go_router, provider)
- Exports all design system components
- Exports all local files (pages, layouts, etc.)

When adding new files, always:
1. Import from `package:the_book_tool/index.dart` at the top
2. Add the new file's export to `index.dart` using a relative path

### Design System
The app has a comprehensive design system in `lib/design_system/`:

- **Theme** (`theme.dart`): Defines both light and dark themes with Material 3 color schemes
  - Colors: Primary, secondary, surface, error colors for both themes
  - Typography: Material 3 text styles (display, headline, title, body, label) as static constants
  - Spacing: `spacing4` through `spacing48` constants
  - Other constants: Border radius, elevation, layout widths, icon sizes, opacity values
  - `AppTheme.lightTheme` and `AppTheme.darkTheme` provide complete `ThemeData` objects

- **Reading Fonts** (`reading_fonts.dart`): Custom font system for chapter content
  - Enum with Roboto, Merriweather, OpenSans, SourceSerif4, and Lora (system font)
  - Fonts loaded from `assets/fonts/` with regular, bold, italic, and bold-italic variants
  - Use `readingFont.getTextStyle()` to apply custom fonts with size and color

- **Components** (`widgets/`):
  - `DSText`: Typography component with named constructors for each text style
  - `DSCard`: Card with consistent styling and optional tap handling
  - `DSButton`: Primary, secondary, and text button variants
  - `DSAppBar`: Custom app bar with title and optional actions
  - `DSSpacing`: Spacing widgets for consistent vertical gaps
  - `DSListTile`: List item component
  - `DSTextField`: Text input with consistent styling
  - `DSDialog`: Dialog wrapper with consistent styling
  - `DSEmptyState`: Empty state placeholder with icon and text
  - `DSLoading`: Loading indicator

All UI components should use design system widgets instead of raw Flutter widgets. Typography uses named constructors like `DSText.headlineSmall()`, `DSText.bodyLarge()`, etc. The `style` parameter on DSText components allows overriding specific properties while maintaining base styles.

### Navigation Architecture
Uses `go_router` with a `ShellRoute` pattern:

- **AppShell** (`lib/layouts/app_shell.dart`): Wraps all pages with a stationary 250px navigation panel on the left
- **Router** (`lib/router.dart`): Defines routes using `NoTransitionPage` to disable animations
- Initial route is `/book`
- Navigation panel shows the current selected route

When adding new pages:
1. Create the page in `lib/pages/`
2. Add route to `router.dart` inside the `ShellRoute.routes` array
3. Add navigation item to `AppShell`'s navigation panel
4. Export the page in `index.dart`

### Adding New Entity Types
The app has a consistent pattern for entity types (chapters, characters, plots, misc_notes). To add a new entity type:

1. **Model** (`lib/models/`): Create model class with:
   - Properties: `id?`, entity-specific fields, `orderIndex`, `createdAt`, `updatedAt`
   - Methods: `toMap()`, `fromMap()`, `copyWith()`

2. **Database** (`lib/services/database_service.dart`):
   - Add table creation in `_onCreate()`
   - Include standard columns: `id`, `order_index`, `created_at`, `updated_at`

3. **Repository** (`lib/repositories/`): Create repository with:
   - `getAll()`, `get(id)`, `insert()`, `update()`, `delete()`, `reorder()`
   - Query table ordered by `order_index ASC`

4. **Provider** (`lib/providers/`): Create provider extending `ChangeNotifier` with:
   - Private repository instance
   - List of entities and `isLoading` state
   - Methods: `loadEntities()`, `addEntity()`, `updateEntity()`, `deleteEntity()`, `reorderEntities()`
   - Register provider in `main.dart`'s `MultiProvider`

5. **Dialogs** (`lib/widgets/`):
   - Create `AddEntityDialog` and `EditEntityDialog`
   - Follow existing dialog patterns (return maps, handle delete)

6. **Page** (`lib/pages/`): Create page using standard structure
   - Show list with `ReorderableListView` for drag-and-drop
   - Floating action button for add
   - Use `Consumer<EntityProvider>` for reactive updates

7. **Exports**: Add all new files to `lib/index.dart`

### Page Structure
All pages follow this pattern:
```dart
class PageName extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DSAppBar(title: 'Page Title'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            children: [
              // Page content using design system widgets
            ],
          ),
        ),
      ],
    );
  }
}
```

Do not wrap pages in `Scaffold` - the `AppShell` handles this.

### State Management
Uses `provider` package with `ChangeNotifier` pattern:

- **Providers** wrap the app in `main.dart` using `MultiProvider`
- Provider classes (in `lib/providers/`):
  - `ThemeProvider`: Manages theme mode (light/dark/system)
  - `ChapterProvider`, `CharacterProvider`, `PlotProvider`, `MiscNoteProvider`: Manage CRUD operations for each entity type
- Each provider follows the pattern: Repository → Provider → UI
- Providers expose loading state (`isLoading`) and data lists
- Use `Provider.of<T>(context, listen: false)` for mutations, `Consumer<T>` for reactive UI

### Data Architecture
The app uses a three-layer architecture:

1. **Database Layer** (`lib/services/`):
   - `DatabaseService`: SQLite database initialization and schema management using `sqflite_common_ffi`
   - `DatabaseManager`: Handles multiple database files, database switching, and file management
   - Tables: `manifest`, `chapters`, `characters`, `plots`, `misc_notes`
   - Each entity has: `id`, timestamps (`created_at`, `updated_at`), and `order_index` for manual ordering

2. **Repository Layer** (`lib/repositories/`):
   - Pure data access logic (no business logic)
   - Standard CRUD operations: `getAll()`, `get(id)`, `insert()`, `update()`, `delete()`
   - `reorder()` method for entities with manual ordering
   - Returns domain models (from `lib/models/`)

3. **Provider Layer** (`lib/providers/`):
   - Extends `ChangeNotifier` for state management
   - Contains business logic and error handling
   - Calls repository methods and notifies listeners
   - Exposes data and loading state to UI

Models use `fromMap()` and `toMap()` for serialization, plus `copyWith()` for immutable updates.

### Dialog Patterns
Dialogs follow a consistent pattern across the app:

- All dialogs in `lib/widgets/` directory
- Add/Edit dialogs for each entity type (chapters, characters, plots, misc notes)
- Use `showDialog<Map<String, dynamic>>()` to show dialogs and return results
- Dialogs return data as maps (e.g., `{'title': '...', 'content': '...'}`)
- Delete operations return `{'delete': true}` from edit dialogs
- The `SettingsDialog` and `DatabaseSelectionDialog` manage app-wide settings
- Edit dialogs can integrate AI features when API key is present (`hasApiKey` parameter)

Example dialog usage:
```dart
final result = await showDialog<Map<String, String>>(
  context: context,
  builder: (dialogContext) => const AddChapterDialog(),
);

if (result != null && mounted) {
  await Provider.of<ChapterProvider>(context, listen: false)
      .addChapter(result['title']!, result['content']!);
}
```

### Services
- **AIService**: OpenAI integration for AI-assisted writing, stores API key in SharedPreferences
- **PdfService**: PDF generation and export using the `pdf` package
- **BookDataService**: Aggregates all book data (chapters, characters, plots, misc notes) for context
- **WindowPreferencesService**: Saves/restores window position and size using `window_manager` and `shared_preferences`

## Key Features

### Multiple Database Support
- Users can create and switch between multiple book projects (`.db` files)
- Each database is a separate book with its own chapters, characters, plots, and notes
- `DatabaseManager` handles file listing and switching
- Current database path stored in `SharedPreferences`

### AI Integration
- OpenAI API integration for AI-assisted writing
- Context-aware prompts include all book data (chapters, characters, plots, notes)
- Used in edit dialogs to improve or generate content
- API key stored in `SharedPreferences`, managed via settings dialog

### PDF Export
- Export entire book to PDF with custom fonts and formatting
- Respects reading font and font size settings
- Handles markdown rendering if enabled
- Uses `file_selector` for save location dialog
- Chapter numbering automatically handles "Prologue" special case

### Theme Support
- Light and dark themes (Material 3)
- Theme mode persisted in `SharedPreferences` via `ThemeProvider`
- All design system components respect theme

### Reading Experience
- Custom fonts for chapter content (Roboto, Merriweather, OpenSans, SourceSerif4, Lora)
- Adjustable font size
- Optional markdown rendering for chapters
- Settings stored in database manifest table

## Key Files
- `lib/main.dart`: Entry point, initializes database and window manager, sets up providers
- `lib/app.dart`: Root widget, configures `MaterialApp.router` with theme support
- `lib/index.dart`: Central export file - all files must be added here
- `lib/router.dart`: Route definitions using `ShellRoute` and `NoTransitionPage`
- `lib/layouts/app_shell.dart`: Main layout with 250px navigation panel
- `lib/design_system/`: Complete design system (theme, fonts, components)
- `lib/services/database_service.dart`: SQLite schema and initialization
- `lib/services/database_manager.dart`: Multi-database management
