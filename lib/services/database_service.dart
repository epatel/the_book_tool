import 'package:the_book_tool/index.dart';

class DatabaseService {
  static Database? _database;
  static const int _databaseVersion = 1;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<void> initialize() async {
    // Initialize sqflite_common_ffi for desktop platforms
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    await database;
  }

  static Future<Database> _initDatabase() async {
    // Get the current database path from DatabaseManager
    final databaseManager = DatabaseManager();
    final dbPath = await databaseManager.getCurrentDatabasePath();

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      ),
    );
  }

  static Future<void> _onOpen(Database db) async {
    // Check if prompts table exists and create it if it doesn't
    // This allows graceful migration for existing version 1 databases
    final tables = await db.query(
      'sqlite_master',
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'prompts'],
    );

    if (tables.isEmpty) {
      // No table exists, create with all columns
      await db.execute('''
        CREATE TABLE prompts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          response TEXT,
          command INTEGER NOT NULL DEFAULT 0,
          is_template INTEGER NOT NULL DEFAULT 0,
          order_index INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      debugPrint('Created prompts table with all columns');

      // Populate default prompts
      await _insertDefaultPrompts(db);
    } else {
      // Table exists, check what columns it has
      final tableInfo = await db.rawQuery('PRAGMA table_info(prompts)');
      final columnNames = tableInfo.map((col) => col['name'] as String).toSet();

      final hasCreationsColumn = columnNames.contains('creations');
      final hasCommandColumn = columnNames.contains('command');
      final hasResponseColumn = columnNames.contains('response');

      if (hasCreationsColumn && !hasCommandColumn) {
        // Old schema: migrate "creations" to "command" and add "response"
        debugPrint(
          'Migrating prompts table: creations -> command, adding response',
        );

        await db.execute('''
          CREATE TABLE prompts_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            response TEXT,
            command INTEGER NOT NULL DEFAULT 0,
            is_template INTEGER NOT NULL DEFAULT 0,
            order_index INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        // Copy data, mapping creations -> command
        await db.execute('''
          INSERT INTO prompts_new
            (id, title, content, response, command, is_template, order_index, created_at, updated_at)
          SELECT
            id, title, content, NULL, creations, is_template, order_index, created_at, updated_at
          FROM prompts
        ''');

        await db.execute('DROP TABLE prompts');
        await db.execute('ALTER TABLE prompts_new RENAME TO prompts');

        debugPrint('Prompts table migration completed');
      } else if (hasCommandColumn && !hasResponseColumn) {
        // Has command but missing response column
        await db.execute('ALTER TABLE prompts ADD COLUMN response TEXT');
        debugPrint('Added response column to prompts table');
      }
      // If has both command and response, no migration needed
    }

    // Check and create assets table
    final assetsTables = await db.query(
      'sqlite_master',
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'assets'],
    );

    if (assetsTables.isEmpty) {
      await db.execute('''
        CREATE TABLE assets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          filename TEXT NOT NULL,
          alias TEXT NOT NULL,
          mime_type TEXT NOT NULL,
          file_data BLOB NOT NULL,
          file_size INTEGER NOT NULL,
          order_index INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          thumbnail BLOB
        )
      ''');
      debugPrint('Created assets table');
    } else {
      // Check if thumbnail column exists
      final assetsTableInfo = await db.rawQuery('PRAGMA table_info(assets)');
      final assetsColumnNames = assetsTableInfo
          .map((col) => col['name'] as String)
          .toSet();

      if (!assetsColumnNames.contains('thumbnail')) {
        await db.execute('ALTER TABLE assets ADD COLUMN thumbnail BLOB');
        debugPrint('Added thumbnail column to assets table');
      }
    }

    // Check and create prompt_history table
    final promptHistoryTables = await db.query(
      'sqlite_master',
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'prompt_history'],
    );

    if (promptHistoryTables.isEmpty) {
      await db.execute('''
        CREATE TABLE prompt_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          prompt_text TEXT NOT NULL,
          response_text TEXT,
          context_type TEXT NOT NULL,
          context_id INTEGER,
          context_name TEXT NOT NULL,
          was_command INTEGER NOT NULL DEFAULT 0,
          prompt_tokens INTEGER,
          completion_tokens INTEGER,
          total_tokens INTEGER,
          model TEXT,
          created_at INTEGER NOT NULL
        )
      ''');
      debugPrint('Created prompt_history table');
    }

    // Gracefully add new manifest keys if they don't exist
    await _ensureManifestKeys(db);
  }

  static Future<void> _ensureManifestKeys(Database db) async {
    final manifestKeys = await db.query('manifest');
    final existingKeys = manifestKeys
        .map((row) => row['key'] as String)
        .toSet();

    // Add LastSection if it doesn't exist
    if (!existingKeys.contains('LastSection')) {
      await db.insert('manifest', {'key': 'LastSection', 'value': '/book'});
      debugPrint('Added LastSection to manifest');
    }

    // Add ExpandedAll if it doesn't exist
    if (!existingKeys.contains('ExpandedAll')) {
      await db.insert('manifest', {'key': 'ExpandedAll', 'value': 'false'});
      debugPrint('Added ExpandedAll to manifest');
    }

    // Add ContextPrompt if it doesn't exist
    if (!existingKeys.contains('ContextPrompt')) {
      await db.insert('manifest', {'key': 'ContextPrompt', 'value': ''});
      debugPrint('Added ContextPrompt to manifest');
    }

    // Add ReadingFont if it doesn't exist
    if (!existingKeys.contains('ReadingFont')) {
      await db.insert('manifest', {'key': 'ReadingFont', 'value': 'lora'});
      debugPrint('Added ReadingFont to manifest');
    }

    // Add FontSize if it doesn't exist
    if (!existingKeys.contains('FontSize')) {
      await db.insert('manifest', {'key': 'FontSize', 'value': '14.0'});
      debugPrint('Added FontSize to manifest');
    }

    // Add token usage tracking if it doesn't exist
    if (!existingKeys.contains('TotalPromptTokens')) {
      await db.insert('manifest', {'key': 'TotalPromptTokens', 'value': '0'});
      debugPrint('Added TotalPromptTokens to manifest');
    }

    if (!existingKeys.contains('TotalCompletionTokens')) {
      await db.insert('manifest', {
        'key': 'TotalCompletionTokens',
        'value': '0',
      });
      debugPrint('Added TotalCompletionTokens to manifest');
    }

    if (!existingKeys.contains('TotalTokens')) {
      await db.insert('manifest', {'key': 'TotalTokens', 'value': '0'});
      debugPrint('Added TotalTokens to manifest');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Create manifest table
    await db.execute('''
      CREATE TABLE manifest (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Insert default values
    await db.insert('manifest', {'key': 'Name', 'value': 'The Book'});
    await db.insert('manifest', {'key': 'Author', 'value': ''});
    await db.insert('manifest', {
      'key': 'Version',
      'value': version.toString(),
    });
    await db.insert('manifest', {'key': 'Markdown', 'value': 'true'});
    await db.insert('manifest', {'key': 'ContextPrompt', 'value': ''});
    await db.insert('manifest', {'key': 'ReadingFont', 'value': 'lora'});
    await db.insert('manifest', {'key': 'FontSize', 'value': '14.0'});
    await db.insert('manifest', {'key': 'LastSection', 'value': '/misc'});
    await db.insert('manifest', {'key': 'ExpandedAll', 'value': 'true'});
    await db.insert('manifest', {'key': 'TotalPromptTokens', 'value': '0'});
    await db.insert('manifest', {'key': 'TotalCompletionTokens', 'value': '0'});
    await db.insert('manifest', {'key': 'TotalTokens', 'value': '0'});

    // Create chapters table
    await db.execute('''
      CREATE TABLE chapters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create characters table
    await db.execute('''
      CREATE TABLE characters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create plots table
    await db.execute('''
      CREATE TABLE plots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create misc_notes table
    await db.execute('''
      CREATE TABLE misc_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create prompts table
    await db.execute('''
      CREATE TABLE prompts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        response TEXT,
        command INTEGER NOT NULL DEFAULT 0,
        is_template INTEGER NOT NULL DEFAULT 0,
        order_index INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Populate default prompts
    await _insertDefaultPrompts(db);

    // Create assets table
    await db.execute('''
      CREATE TABLE assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filename TEXT NOT NULL,
        alias TEXT NOT NULL,
        mime_type TEXT NOT NULL,
        file_data BLOB NOT NULL,
        file_size INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        thumbnail BLOB
      )
    ''');

    // Create prompt_history table
    await db.execute('''
      CREATE TABLE prompt_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prompt_text TEXT NOT NULL,
        response_text TEXT,
        context_type TEXT NOT NULL,
        context_id INTEGER,
        context_name TEXT NOT NULL,
        was_command INTEGER NOT NULL DEFAULT 0,
        prompt_tokens INTEGER,
        completion_tokens INTEGER,
        total_tokens INTEGER,
        model TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Populate initial notes
    await _insertWelcomeNote(db);
    await _insertImageGuideNote(db);
    await _insertAdvancedFeaturesNote(db);
  }

  static Future<void> insertDefaultPrompts() async {
    final db = await database;
    await _insertDefaultPrompts(db);
  }

  static Future<void> _insertDefaultPrompts(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final defaultPrompts = [
      {
        'title': 'Expand Scene',
        'content':
            'Expand the selected text into a more detailed scene. Add sensory details, character emotions, and vivid descriptions while maintaining the original intent and tone.',
        'command': 0,
        'is_template': 1,
        'order_index': 0,
      },
      {
        'title': 'Add Dialogue',
        'content':
            'Add natural dialogue to the selected scene. The dialogue should reveal character personalities, advance the plot, and feel authentic to each character\'s voice.',
        'command': 0,
        'is_template': 1,
        'order_index': 1,
      },
      {
        'title': 'Describe Setting',
        'content':
            'Provide a rich, immersive description of the setting. Include visual details, atmosphere, sounds, smells, and how the environment affects the mood of the scene.',
        'command': 0,
        'is_template': 1,
        'order_index': 2,
      },
      {
        'title': 'Continue Writing',
        'content':
            'Continue writing from where the text ends. Maintain the established tone, style, and pacing. Keep the narrative flowing naturally.',
        'command': 0,
        'is_template': 1,
        'order_index': 3,
      },
      {
        'title': 'Show Don\'t Tell',
        'content':
            'Rewrite the selected text using "show don\'t tell" technique. Replace exposition with action, dialogue, and sensory details that demonstrate rather than state.',
        'command': 0,
        'is_template': 1,
        'order_index': 4,
      },
      {
        'title': 'Generate Chapter Outline',
        'content':
            'Based on the book context, create an outline for {chapter}. Generate 3-5 key scenes that advance the plot and develop the characters. Use command mode to create these as separate notes.',
        'command': 1,
        'is_template': 1,
        'order_index': 5,
      },
    ];

    for (final prompt in defaultPrompts) {
      await db.insert('prompts', {
        'title': prompt['title'],
        'content': prompt['content'],
        'response': null,
        'command': prompt['command'],
        'is_template': prompt['is_template'],
        'order_index': prompt['order_index'],
        'created_at': now,
        'updated_at': now,
      });
    }

    debugPrint('Inserted ${defaultPrompts.length} default prompts');
  }

  static Future<void> _insertWelcomeNote(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final welcomeContent = '''# Welcome to The Book Tool! 📚

Your new book project is ready. Here's how to get started:

## Quick Start

1. **Chapters** - Write your book content here (this is where you'll spend most of your time)
2. **Characters** - Track character details to maintain consistency
3. **Plots** - Organize story arcs and plot threads
4. **Notes** - Store research, ideas, and other notes (you're reading one now!)
5. **Prompts** - AI-powered writing assistance
6. **Assets** - Upload images to reference in chapters: `![Description](alias)`

## Your First Steps

- ✏️ Add your first chapter in the Chapters section
- 📝 Update the book title in Settings
- 🎨 Choose your preferred theme (light/dark) in Settings

## Tips

- All data is stored locally on your computer
- Use markdown formatting for rich text (enabled by default)
- Select text and use AI prompts for writing assistance
- Add `{not-for-ai}` to exclude content from AI requests
- Export your book to PDF when ready

## Need Help?

Check the other notes in this section for:
- 🖼️ "Image Reference Guide" - How to use uploaded images
- ⚡ "Advanced Features" - AI command mode, TTS, and more

Happy writing! 🚀''';

    await db.insert('misc_notes', {
      'title': 'Getting Started',
      'content': welcomeContent,
      'order_index': 0,
      'created_at': now,
      'updated_at': now,
    });

    debugPrint('Inserted welcome note');
  }

  static Future<void> _insertImageGuideNote(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final imageGuideContent = '''# Image Reference Guide 🖼️

Learn how to upload and use images in your chapters.

## Uploading Images

1. Go to the **Assets** section
2. Click the + button or drag & drop image files
3. Crop and resize the image as needed
4. Choose output format (JPG or PNG)
5. Enter a unique alias (e.g., "hero_portrait", "castle_exterior")

## Basic Image Syntax

Reference uploaded images in your chapters using markdown:

```
![Description](alias)
```

**Example:**
If you upload an image with alias "hero_portrait", use:

```
![The hero standing tall](hero_portrait)
```

## Controlling Image Width

Add width specifications using the title parameter:

```
![Description](alias "width=50%")        # 50% of available width
![Description](alias "width=300px")      # Fixed 300 pixels
![Description](alias "width=0.5")        # Fraction (50%)
```

### Named Width Presets

Use convenient preset names:

```
![Description](alias "width=small")      # 25% width
![Description](alias "width=medium")     # 50% width
![Description](alias "width=large")      # 75% width
![Description](alias "width=full")       # 100% width
```

## Image Alignment

Control where images appear on the page:

```
![Description](alias "width=50% align=left")
![Description](alias "width=50% align=center")
![Description](alias "width=50% align=right")
```

**Note:** Default alignment is center when width is specified.

## Examples

```
![A mysterious forest](forest "width=large align=center")
![Character portrait](hero "width=small align=left")
![Full-width banner](banner "width=full")
```

## Tips

- Use descriptive aliases (e.g., "chapter3_sunset" instead of "img1")
- JPG is smaller for photos, PNG preserves transparency
- Resize images before uploading to reduce file size
- Test different widths to find what works best for your content''';

    await db.insert('misc_notes', {
      'title': 'Image Reference Guide {not-for-ai}',
      'content': imageGuideContent,
      'order_index': 1,
      'created_at': now,
      'updated_at': now,
    });

    debugPrint('Inserted image guide note');
  }

  static Future<void> _insertAdvancedFeaturesNote(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final advancedFeaturesContent = '''# Advanced Features ⚡

Explore powerful features to enhance your writing workflow.

## AI Writing Assistance

### Using AI Prompts

1. Select text in any chapter, character description, or note
2. Click the AI button (robot icon) in the toolbar
3. Choose a prompt template or write your own
4. AI will generate content based on your selection and prompt

### AI Command Mode

Some prompts use **command mode** to generate structured content:

- **Generate Chapter Outline**: Creates multiple scene notes automatically
- Add `{chapter}` placeholder in prompts for chapter-specific generation
- Command mode prompts generate content directly into your book

**Example command prompt:**
```
Create 3 scene outlines for {chapter}. Each should be a separate note.
```

### Custom Prompts

Create your own AI prompts in the Prompts section:
- **Regular prompts**: Generate text to insert
- **Template prompts**: Reusable prompts shown in the toolbar
- **Command prompts**: Auto-generate structured content (chapters, notes, etc.)

## Text-to-Speech (TTS)

Listen to your chapters being read aloud:

1. Go to **Settings** → **Text-to-Speech**
2. Select your preferred voice
3. In the Chapters section, click the play button on any chapter
4. Use pause/resume/stop controls in the app bar

**Benefits:**
- Catch awkward phrasing and repetition
- Hear dialogue flow naturally
- Proofread while doing other tasks

## Multiple Book Projects

Manage multiple book projects simultaneously:

1. Click the Library icon in the sidebar
2. Create a new book project or switch between existing ones
3. Each project has its own database with separate:
   - Chapters, characters, plots, notes
   - Prompts, assets, settings
   - AI usage tracking

## Export to PDF

Generate a professional PDF of your book:

1. Go to **Settings** → **Export**
2. Choose export options (font, spacing, chapters to include)
3. Click "Export to PDF"
4. Select save location

## Privacy Features

### Not-for-AI Marker

Exclude content from AI requests by adding `{not-for-ai}` to any title or content:

```
Chapter Title: Draft Ideas {not-for-ai}
```

- Content marked this way won't be sent to AI services
- Useful for personal notes, work-in-progress content, or sensitive information
- A badge will appear indicating the content is excluded

## Markdown Support

Enable rich text formatting in Settings:

- **Bold**: `**text**` or `__text__`
- **Italic**: `*text*` or `_text_`
- **Headers**: `# H1`, `## H2`, `### H3`
- **Lists**: `- item` or `1. item`
- **Links**: `[text](url)`
- **Images**: `![alt](alias)` (from Assets)
- **Code**: `` `inline` `` or ` ```block``` `

## Keyboard Shortcuts

- **Ctrl/Cmd + S**: Save changes
- **Ctrl/Cmd + F**: Search
- **Ctrl/Cmd + N**: New item
- **Ctrl/Cmd + ,**: Settings

## Tips for Power Users

- Use the search feature to find content across all sections
- Organize with the "Not for AI" marker for drafts and notes
- Create custom prompt templates for your writing style
- Export regularly to back up your work
- Use command mode prompts to quickly generate structure''';

    await db.insert('misc_notes', {
      'title': 'Advanced Features',
      'content': advancedFeaturesContent,
      'order_index': 2,
      'created_at': now,
      'updated_at': now,
    });

    debugPrint('Inserted advanced features note');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // No migrations needed - starting fresh at version 1
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  static Future<int> numberOfChapters() async {
    final db = await database;
    // Select COUNT(*) from chapters
    final count = await db
        .query('chapters', columns: ['COUNT(*)'])
        .then((value) => value.first['COUNT(*)']);
    return count as int;
  }

  static Future<int> numberOfCharacters() async {
    final db = await database;
    // Select COUNT(*) from characters
    final count = await db
        .query('characters', columns: ['COUNT(*)'])
        .then((value) => value.first['COUNT(*)']);
    return count as int;
  }

  static Future<int> numberOfPlots() async {
    final db = await database;
    // Select COUNT(*) from plots
    final count = await db
        .query('plots', columns: ['COUNT(*)'])
        .then((value) => value.first['COUNT(*)']);
    return count as int;
  }

  static Future<int> numberOfMiscNotes() async {
    final db = await database;
    // Select COUNT(*) from misc_notes
    final count = await db
        .query('misc_notes', columns: ['COUNT(*)'])
        .then((value) => value.first['COUNT(*)']);
    return count as int;
  }

  static Future<int> numberOfPrompts() async {
    final db = await database;
    // Select COUNT(*) from prompts
    final count = await db
        .query('prompts', columns: ['COUNT(*)'])
        .then((value) => value.first['COUNT(*)']);
    return count as int;
  }

  static Future<int> numberOfAssets() async {
    final db = await database;
    // Select COUNT(*) from assets
    final count = await db
        .query('assets', columns: ['COUNT(*)'])
        .then((value) => value.first['COUNT(*)']);
    return count as int;
  }

  static Future<int> numberOfPromptHistory() async {
    final db = await database;
    // Select COUNT(*) from prompt_history
    final count = await db
        .query('prompt_history', columns: ['COUNT(*)'])
        .then((value) => value.first['COUNT(*)']);
    return count as int;
  }
}
