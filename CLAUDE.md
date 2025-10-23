# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

The Book Tool is a Flutter application for book writing, helping authors organize chapters, characters, plot ideas, miscellaneous notes, AI prompts, and image assets. The app uses a stationary navigation panel layout (not a drawer) with six main sections: Book (chapters), Characters, Plots, Notes, Prompts, and Assets.

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
  - `TextSelectionHighlight`: Overlay widget for showing cursor/selection when TextField is unfocused (see AI Integration section)

All UI components should use design system widgets instead of raw Flutter widgets. Typography uses named constructors like `DSText.headlineSmall()`, `DSText.bodyLarge()`, etc. The `style` parameter on DSText components allows overriding specific properties while maintaining base styles.

**Color opacity**: Use `color.withValues(alpha: 0.6)` for color transparency (Flutter 3.27+ API). This replaces the deprecated `color.withOpacity()` method.

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
The app has a consistent pattern for entity types (chapters, characters, plots, misc_notes, prompts). To add a new entity type:

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
   - Tables: `manifest`, `chapters`, `characters`, `plots`, `misc_notes`, `prompts`, `assets`
   - Each entity has: `id`, timestamps (`created_at`, `updated_at`), and `order_index` for manual ordering
   - Boolean fields stored as INTEGER (0/1) in SQLite
   - Binary data (images, files) stored as BLOB in `assets` table

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

**Database Migration Pattern**: When adding new columns or renaming columns, use `PRAGMA table_info` to check existing schema and perform graceful migration without version bumps. See `prompts` table migration in `DatabaseService._onOpen()` for reference.

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

#### PopupMenuButton Pattern for Contextual Actions
For contextual actions on list items (e.g., delete), use `PopupMenuButton` with three-dot icon instead of direct delete buttons:

**Benefits**:
- Less visually aggressive than red delete icons
- Follows Material Design patterns
- Allows for future action expansion
- Provides confirmation dialogs for destructive actions

**Example** (from `DatabaseSelectionDialog`):
```dart
trailing: isCurrent
    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
    : PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        onSelected: (value) {
          if (value == 'delete') {
            _deleteDatabase(dbName);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 20),
                const SizedBox(width: 12),
                Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ),
          ),
        ],
      ),
```

**Notes**:
- Use `Icons.more_vert` for menu icon with reduced opacity (0.6)
- Destructive actions (delete) should use `Theme.of(context).colorScheme.error` color
- Always show confirmation dialog for destructive actions
- Icon size in menu items should be 20 (slightly smaller than default 24)

### Services
- **AIService**: OpenAI integration for AI-assisted writing, stores API key in SharedPreferences
- **PdfService**: PDF generation and export using the `pdf` package
- **BookDataService**: Aggregates all book data (chapters, characters, plots, misc notes) for AI context
- **WindowPreferencesService**: Saves/restores window position and size using `window_manager` and `shared_preferences`
- **DatabaseService**: Core database operations with graceful schema migrations
- **DatabaseManager**: Multi-database file management and switching

## Key Features

### Multiple Database Support
- Users can create and switch between multiple book projects (`.db` files)
- Each database is a separate book with its own chapters, characters, plots, and notes
- `DatabaseManager` handles file listing, switching, creation, and deletion
- Current database path stored in `SharedPreferences`
- Database deletion includes safety check: cannot delete currently active database
- Delete UI uses `PopupMenuButton` pattern with confirmation dialog (see Dialog Patterns section)

### AI Integration
- OpenAI API integration for AI-assisted writing
- Context-aware prompts include all book data (chapters, characters, plots, notes)
- Used in edit dialogs to improve or generate content
- API key stored in `SharedPreferences`, managed via settings dialog
- AI Context Prompt: Optional user-defined context stored in manifest (e.g., genre, style, themes)
  - Added to settings dialog as multi-line text field
  - Stored in manifest table with key `ContextPrompt`
  - Automatically inserted into AI system messages when present
  - No database version bump required - gracefully handles missing values with empty string default

#### Prompts System
The prompts system allows users to save, organize, and reuse AI prompts:

**Prompt Types**:
1. **Regular prompts**: Saved prompts that can be sent to AI, responses are stored and can be viewed
2. **Templates**: Prompts marked as templates appear in template popup menus across edit dialogs
3. **Command mode prompts**: Templates that enable AI to execute commands (create entities)

**Prompt Model** (`lib/models/prompt.dart`):
- `title`: Prompt name
- `content`: The actual prompt text
- `response`: Optional saved AI response (only for non-template, non-command prompts)
- `command`: Boolean flag indicating if prompt enables command mode
- `isTemplate`: Boolean flag indicating if prompt appears in template menus
- Standard fields: `id`, `orderIndex`, `createdAt`, `updatedAt`

**Template Substitution**: Templates support placeholder substitution when inserted:
- `{title}` or `{name}`: Replaced with item's title/name (interchangeable)
- `{chapter}`: Replaced with chapter designation (chapters only):
  - If first chapter (orderIndex 0) has title "Prologue" → `"Prologue"`
  - Otherwise adjusts chapter numbering based on prologue presence:
    - With prologue: `"Chapter 1: <title>"` for orderIndex 1
    - Without prologue: `"Chapter 1: <title>"` for orderIndex 0

**Template Availability**:
- Prompts are loaded in `AppShell.initState()` to be available app-wide
- Templates appear in `PopupMenuButton` with bookmark icon in edit dialogs
- Command templates filtered out in chapters and characters (no command mode support)
- All templates available in plots and misc notes (support command mode)

**Response Storage**:
- When sending non-template, non-command prompts, AI responses are saved to `response` field
- "View Response" button appears in edit dialog when response exists
- Response cleared if prompt content is modified
- Responses displayed as markdown in `AIResponseDialog`

#### AI Edit Dialog Integration
Edit dialogs (chapters, characters, plots, misc notes) integrate AI features when API key is configured:

- **Inline AI prompt field**: TextField with send button appears below content field
- **Command mode checkbox**: Present only in Plot and Misc Note dialogs (removed from Chapter and Character)
  - When enabled, AI can create new chapters, characters, plots, and notes using JSON commands
  - When disabled, AI inserts/replaces text at cursor position or selection
- **Loading state**: Content field becomes `readOnly` during AI processing (not `enabled: false`)
- **Cursor/selection preservation**: Uses `TextSelectionHighlight` overlay to maintain visual cursor/selection even when focus moves to AI prompt field

#### TextSelectionHighlight Overlay Pattern
Critical pattern for maintaining cursor/selection visibility when TextField loses focus (e.g., when clicking AI prompt field):

**Problem**: Flutter TextFields only show cursor when focused. When user clicks in AI prompt field, content field loses focus and cursor disappears, making it hard to see where AI will insert text.

**Solution**: Custom overlay widget (`lib/widgets/text_selection_overlay.dart`) that:
- Uses `CustomPaint` with `TextPainter` to render cursor and selection boxes
- Positioned over the TextField using `Stack` and `Positioned.fill`
- Only visible when field is unfocused (`!_contentFocusNode.hasFocus`)
- Uses `IgnorePointer` to prevent blocking touch events

**Implementation pattern** (from edit dialogs):
```dart
class _EditDialogState extends State<EditDialog> {
  late final TextEditingController _contentController;
  late final FocusNode _contentFocusNode;
  late final ScrollController _contentScrollController;
  TextSelection? _savedSelection;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: initialContent);
    _contentFocusNode = FocusNode();
    _contentScrollController = ScrollController();

    // Listen to focus changes to save/restore selection
    _contentFocusNode.addListener(_onContentFocusChange);

    // Listen to scroll changes to update overlay position
    _contentScrollController.addListener(_onContentScrollChange);

    // Listen to selection changes to update overlay when unfocused
    _contentController.addListener(_onContentSelectionChange);
  }

  void _onContentFocusChange() {
    setState(() {
      if (_contentFocusNode.hasFocus) {
        // Restore selection when gaining focus
        if (_savedSelection != null) {
          _contentController.selection = _savedSelection!;
        }
      } else {
        // Save selection when losing focus
        _savedSelection = _contentController.selection;
      }
    });
  }

  void _onContentScrollChange() {
    setState(() {
      _scrollOffset = _contentScrollController.offset;
    });
  }

  void _onContentSelectionChange() {
    // Update saved selection when selection changes while unfocused
    if (!_contentFocusNode.hasFocus) {
      setState(() {
        _savedSelection = _contentController.selection;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TextFormField(
          controller: _contentController,
          focusNode: _contentFocusNode,
          scrollController: _contentScrollController,
          readOnly: _isLoadingAi, // Use readOnly, not enabled
          showCursor: true,
          // ... other properties
        ),
        // Overlay only visible when unfocused
        if (!_contentFocusNode.hasFocus && _savedSelection != null)
          Positioned.fill(
            child: ClipRect(
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 19, 12, 20),
                  child: TextSelectionHighlight(
                    text: _contentController.text,
                    selection: _savedSelection!,
                    style: Theme.of(context).textTheme.bodyLarge ??
                           const TextStyle(fontSize: 16.0),
                    maxLines: 10,
                    scrollOffset: _scrollOffset,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

**CRITICAL: When AI inserts text**, update `_savedSelection` BEFORE calling `requestFocus()` to prevent focus listener from overwriting new selection:
```dart
final newSelection = TextSelection(
  baseOffset: selection.start,
  extentOffset: selection.start + response.text!.length,
);
_contentController.selection = newSelection;
_savedSelection = newSelection; // MUST happen before requestFocus
_contentFocusNode.requestFocus();
```

**Padding values**: The overlay padding (16, 19, 12, 20) has been reverse-engineered to exactly match TextFormField's internal padding. Do not change these values without testing alignment carefully.

### Assets System
The app includes a comprehensive asset management system for storing and referencing images within the book:

**Asset Model** (`lib/models/asset.dart`):
- `filename`: Original file name
- `alias`: User-defined reference name (used in markdown)
- `mimeType`: File MIME type (e.g., `image/png`, `image/jpeg`)
- `fileData`: Binary file content stored as `Uint8List` (BLOB in database)
- `fileSize`: File size in bytes
- `thumbnail`: Optional thumbnail for grid/list display
- Standard fields: `id`, `orderIndex`, `createdAt`, `updatedAt`

**Asset Services**:
- `AssetService`: Determines file types from MIME types (image, document, audio, video)
- `ThumbnailService`: Generates thumbnails for images (max 200x200px, 85% quality JPG)
- `FileTypeService`: Identifies MIME types from file bytes and extensions

**ImportAssetDialog** (`lib/widgets/import_asset_dialog.dart`):
Advanced image import dialog with:
- **Crop functionality**: Interactive crop tool using `crop_image` package
  - Free aspect ratio cropping
  - Iterative cropping (crop multiple times)
  - Preview mode on Import button hover (removes crop overlay)
- **Resolution control**: Slider to set maximum width
  - Dynamic range based on current image size (25% to 100% of width)
  - Minimum clamped to 100px for small images
  - Real-time clamping to prevent slider assertion errors
- **Quality control**: JPG quality slider (50-100%, default 85%)
- **Format preservation**: PNG for transparency, JPG for others
- **Image processing**: Resizes and re-encodes before storage

**Markdown Image Integration**:
Images can be embedded in chapter content and AI responses using custom markdown syntax:
```markdown
![description](alias)
![description](alias "width=400")
![description](alias "width=400 align=center")
![description](alias "align=right")
```

**Supported attributes**:
- `width`: Pixel width (e.g., `width=400`)
- `align`: Alignment - `left`, `center`, or `right` (default: left)

**Implementation** (`lib/widgets/markdown_asset_image_builder.dart`):
- Custom `MarkdownImageBuilder` that intercepts `![](alias)` syntax
- Looks up asset by alias in `AssetProvider`
- Parses attributes from title field: `"width=X align=Y"`
- Renders with proper spacing using `Sizes.imageTopSpacing` and `Sizes.imageBottomSpacing`
- Alignment handled via `Align` widget with `CrossAxisAlignment`
- PDF export also supports this syntax via `PdfService`

**Image Spacing** (`lib/sizes.dart`):
Centralized constants for consistent image spacing:
- `Sizes.imageTopSpacing = 8.0`
- `Sizes.imageBottomSpacing = 8.0`
- Used in both markdown rendering and PDF export

**Usage in Edit Dialogs**:
Edit dialogs for chapters, characters, plots, and misc notes include an "Insert Image" button that:
- Shows popup menu of all available assets
- Inserts markdown syntax at cursor position: `![description](alias)`
- Button only visible when assets are available

### PDF Export
- Export entire book to PDF with custom fonts and formatting
- Respects reading font and font size settings
- Handles markdown rendering if enabled, including image assets
- Markdown image syntax fully supported with width and alignment attributes
- Uses `file_selector` for save location dialog
- Chapter numbering automatically handles "Prologue" special case

### Theme Support
- Light and dark themes (Material 3)
- Theme mode persisted in `SharedPreferences` via `ThemeProvider`
- All design system components respect theme

### Reading Experience
- Custom fonts for chapter content (Roboto, Merriweather, OpenSans, SourceSerif4, Lora)
- Adjustable font size
- Optional markdown rendering for chapters using `flutter_markdown` package
- Settings stored in database manifest table

### Markdown Support
The app uses `flutter_markdown` package for rendering markdown content:
- AI responses displayed as markdown in `AIResponseDialog`
- Uses `MarkdownBody` with `selectable: true` for copyable text
- Custom `MarkdownStyleSheet` integrates with theme colors
- Markdown can be enabled for chapter content via settings

## Key Files
- `lib/main.dart`: Entry point, initializes database and window manager, sets up providers
- `lib/app.dart`: Root widget, configures `MaterialApp.router` with theme support
- `lib/index.dart`: Central export file - all files must be added here
- `lib/router.dart`: Route definitions using `ShellRoute` and `NoTransitionPage`
- `lib/layouts/app_shell.dart`: Main layout with 250px navigation panel
- `lib/design_system/`: Complete design system (theme, fonts, components)
- `lib/services/database_service.dart`: SQLite schema and initialization
- `lib/services/database_manager.dart`: Multi-database management
