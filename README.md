# The Book Tool

A Flutter desktop application for book writing. It helps authors organize chapters, characters, plot ideas, notes, reusable AI prompts, and image assets — with AI-assisted writing built in.

## Features

- **Six workspaces** — Book (chapters), Characters, Plots, Notes, Prompts, and Assets, navigated from a stationary side panel.
- **AI-assisted writing** — OpenAI-powered content generation and editing directly inside edit dialogs, with full context awareness of your book (chapters, characters, plots, notes).
- **Command mode** — let the AI create new chapters, characters, plots, and notes from a single prompt.
- **Prompt history** — every AI interaction is logged with token usage, model, and a readable summary.
- **Reusable prompts & templates** — save prompts, mark them as templates, and insert them with placeholder substitution (`{title}`, `{name}`, `{chapter}`).
- **Multiple book projects** — create and switch between separate `.db` files, each its own book.
- **Image assets** — import, crop, resize, and embed images in content via custom markdown (`![alt](alias "width=400 align=center")`).
- **Reading experience** — custom reading fonts, adjustable font size, optional markdown rendering.
- **PDF export** — export the whole book with fonts, formatting, and embedded images.
- **Light & dark themes** — Material 3, persisted across sessions.

## Getting Started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (Dart SDK ^3.9.2)
- A desktop target (macOS, Windows, or Linux)

### Install & Run

```bash
flutter pub get
flutter run
```

### AI Setup

Add your OpenAI API key in **Settings** inside the app. The key is stored securely using `flutter_secure_storage`. An optional AI Context Prompt (genre, style, themes) can be set in Settings to steer generated content.

## Development

```bash
# Run all tests
flutter test

# Run a specific test
flutter test test/widget_test.dart

# Format code
flutter pub run dart format .

# Generate launcher icons
dart run icons_launcher:create
```

## Architecture

The app uses a three-layer data architecture (Database → Repository → Provider) with `provider` for state management and `go_router` for navigation.

- **`lib/index.dart`** — centralized export file; all files import from `package:the_book_tool/index.dart`.
- **`lib/design_system/`** — Material 3 theme, reading fonts, and reusable `DS*` components.
- **`lib/layouts/app_shell.dart`** — main layout with the 250px navigation panel.
- **`lib/router.dart`** — routes defined via `ShellRoute`.
- **`lib/services/`** — database, AI, PDF, and asset services.
- **`lib/repositories/`** — data access (CRUD + reordering).
- **`lib/providers/`** — `ChangeNotifier` state holders.
- **`lib/models/`** — domain models with `toMap()` / `fromMap()` / `copyWith()`.

See [`CLAUDE.md`](CLAUDE.md) for detailed architecture and contribution patterns.

## Tech Stack

Flutter · SQLite (`sqflite_common_ffi`) · `provider` · `go_router` · `openai_dart` · `flutter_markdown` · `pdf` · `window_manager`
