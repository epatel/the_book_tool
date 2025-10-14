import 'dart:convert';

/// Response from AI service containing optional text and commands
class AIResponse {
  final String? text;
  final List<AICommand> commands;

  const AIResponse({
    this.text,
    this.commands = const [],
  });

  bool get hasText => text != null && text!.isNotEmpty;
  bool get hasCommands => commands.isNotEmpty;
}

/// Base class for AI commands
abstract class AICommand {
  const AICommand();

  /// Parse a JSON object into an AICommand
  static AICommand? fromJson(Map<String, dynamic> json) {
    final action = json['action'] as String?;
    final data = json['data'] as Map<String, dynamic>?;

    if (action == null || data == null) {
      return null;
    }

    switch (action) {
      case 'add_chapter':
        return AddChapterCommand.fromJson(data);
      case 'add_character':
        return AddCharacterCommand.fromJson(data);
      case 'add_plot':
        return AddPlotCommand.fromJson(data);
      case 'add_misc_note':
        return AddMiscNoteCommand.fromJson(data);
      default:
        return null;
    }
  }

  /// Parse response text to extract commands
  static List<AICommand> parseFromResponse(String response) {
    final commands = <AICommand>[];

    // Extract JSON from markdown code blocks
    final codeBlockRegex = RegExp(
      r'```(?:json)?\s*\n([\s\S]*?)\n```',
      multiLine: true,
    );

    final matches = codeBlockRegex.allMatches(response);

    for (final match in matches) {
      final jsonString = match.group(1)?.trim();
      if (jsonString == null || jsonString.isEmpty) continue;

      try {
        final decoded = jsonDecode(jsonString);

        // Handle both single object and array of objects
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final command = AICommand.fromJson(item);
              if (command != null) {
                commands.add(command);
              }
            }
          }
        } else if (decoded is Map<String, dynamic>) {
          final command = AICommand.fromJson(decoded);
          if (command != null) {
            commands.add(command);
          }
        }
      } catch (e) {
        // Skip invalid JSON
        continue;
      }
    }

    return commands;
  }
}

/// Command to add a new chapter
class AddChapterCommand extends AICommand {
  final String title;
  final String content;

  const AddChapterCommand({
    required this.title,
    required this.content,
  });

  factory AddChapterCommand.fromJson(Map<String, dynamic> json) {
    return AddChapterCommand(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  bool get isValid => title.isNotEmpty && content.isNotEmpty;
}

/// Command to add a new character
class AddCharacterCommand extends AICommand {
  final String name;
  final String description;

  const AddCharacterCommand({
    required this.name,
    required this.description,
  });

  factory AddCharacterCommand.fromJson(Map<String, dynamic> json) {
    return AddCharacterCommand(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  bool get isValid => name.isNotEmpty && description.isNotEmpty;
}

/// Command to add a new plot
class AddPlotCommand extends AICommand {
  final String title;
  final String description;

  const AddPlotCommand({
    required this.title,
    required this.description,
  });

  factory AddPlotCommand.fromJson(Map<String, dynamic> json) {
    return AddPlotCommand(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  bool get isValid => title.isNotEmpty && description.isNotEmpty;
}

/// Command to add a new misc note
class AddMiscNoteCommand extends AICommand {
  final String title;
  final String content;

  const AddMiscNoteCommand({
    required this.title,
    required this.content,
  });

  factory AddMiscNoteCommand.fromJson(Map<String, dynamic> json) {
    return AddMiscNoteCommand(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  bool get isValid => title.isNotEmpty && content.isNotEmpty;
}
