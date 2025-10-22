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

    // Populate welcome note
    await _insertWelcomeNote(db);
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

    final welcomeContent = '''Welcome to The Book Tool!

This application is designed to help you write and organize your book. Here's a quick guide to get you started:

## Chapters
Write and organize your book chapters. You can:
- Reorder chapters by dragging them
- Expand all chapters to see full content
- Use text-to-speech to listen to your chapters (configure in Settings)

## Characters
Keep track of your characters and their descriptions. This helps maintain consistency throughout your book.

## Plots
Organize plot points, story arcs, and narrative threads. Use this section to plan and track your story's structure.

## Notes
This section! Use notes for general ideas, research, world-building details, or anything else that doesn't fit in the other categories.

## Prompts
AI-powered writing prompts to help you:
- Expand scenes with more detail
- Add dialogue and character interactions
- Describe settings vividly
- Continue writing when you're stuck
- Use command mode prompts to generate structured content

## Settings
Configure your book's title, author name, AI API key, theme, reading preferences, and text-to-speech voice.

## Assets
Upload and manage images and other files that you can reference in your chapters. Upload images in the Assets section and reference them using markdown:

```
![Description](asset_alias)
```

For example, if you upload an image with alias "hero_portrait", you can add it to a chapter with:

```
![The hero](hero_portrait)
```

### Image Width Control
You can control the width of images using the title parameter:

```
![Description](asset_alias "width=50%")        # 50% of available width
![Description](asset_alias "width=300px")      # Fixed 300 pixels
![Description](asset_alias "width=0.5")        # Fraction (50%)
![Description](asset_alias "width=small")      # 25% width
![Description](asset_alias "width=medium")     # 50% width
![Description](asset_alias "width=large")      # 75% width
```

### Image Alignment
Combine width with alignment (left, center, right):

```
![Description](asset_alias "width=50% align=center")
![Description](asset_alias "width=300px align=left")
![Description](asset_alias "width=medium align=right")
```

Default alignment is center when width is specified.

## Library
Create and switch between multiple book projects using the Library icon (storage icon) in the sidebar.

## Tips
- All your data is stored locally on your computer
- Use markdown formatting for rich text (enable in Settings)
- Select text in chapters and use AI prompts for assistance
- Reference uploaded images in your chapters with `![description](alias)` syntax
- Export your finished book to PDF
- Add `{not-for-ai}` to any title or content to exclude it from AI requests (useful for private notes or work-in-progress content)

Happy writing!''';

    await db.insert('misc_notes', {
      'title': 'Getting Started',
      'content': welcomeContent,
      'order_index': 0,
      'created_at': now,
      'updated_at': now,
    });

    debugPrint('Inserted welcome note');
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
}
