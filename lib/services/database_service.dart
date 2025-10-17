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
        debugPrint('Migrating prompts table: creations -> command, adding response');

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
    await db.insert('manifest', {'key': 'Markdown', 'value': 'false'});

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
}
