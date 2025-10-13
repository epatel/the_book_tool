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

- **Theme** (`theme.dart`): Colors, typography, spacing constants, border radius, elevation values
- **Components** (`widgets/`): `DSText`, `DSCard`, `DSButton`, `DSAppBar`, `DSSpacing`, `DSListTile`

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
Currently uses `provider` (installed but not actively used). The counter example was removed in favor of the book writing features.

## Key Files
- `lib/main.dart`: Entry point, calls `runApp(const App())`
- `lib/app.dart`: `App` widget (renamed from `MyApp`), configures `MaterialApp.router` with `AppTheme.lightTheme`
- `lib/index.dart`: Central export file - all files must be added here
- `lib/router.dart`: Route definitions using ShellRoute and NoTransitionPage
- `lib/layouts/app_shell.dart`: Main layout with navigation panel
- `lib/design_system/`: Complete design system implementation
