import 'package:the_book_tool/index.dart';

/// Result of executing a single command
class CommandResult {
  final AICommand command;
  final bool success;
  final String? error;
  final String? successMessage;

  const CommandResult({
    required this.command,
    required this.success,
    this.error,
    this.successMessage,
  });
}

/// Service to execute AI commands
class AICommandExecutor {
  /// Execute a list of commands
  Future<List<CommandResult>> executeCommands(
    BuildContext context,
    List<AICommand> commands,
  ) async {
    final results = <CommandResult>[];

    for (final command in commands) {
      final result = await _executeCommand(context, command);
      results.add(result);
    }

    return results;
  }

  /// Execute a single command
  Future<CommandResult> _executeCommand(
    BuildContext context,
    AICommand command,
  ) async {
    try {
      if (command is AddChapterCommand) {
        return await _executeAddChapter(context, command);
      } else if (command is AddCharacterCommand) {
        return await _executeAddCharacter(context, command);
      } else if (command is AddPlotCommand) {
        return await _executeAddPlot(context, command);
      } else if (command is AddMiscNoteCommand) {
        return await _executeAddMiscNote(context, command);
      } else {
        return CommandResult(
          command: command,
          success: false,
          error: 'Unknown command type',
        );
      }
    } catch (e) {
      return CommandResult(
        command: command,
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<CommandResult> _executeAddChapter(
    BuildContext context,
    AddChapterCommand command,
  ) async {
    if (!command.isValid) {
      return CommandResult(
        command: command,
        success: false,
        error: 'Invalid chapter data: title and content are required',
      );
    }

    try {
      final provider = Provider.of<ChapterProvider>(context, listen: false);
      await provider.addChapter(command.title, command.content);

      return CommandResult(
        command: command,
        success: true,
        successMessage: 'Added chapter: ${command.title}',
      );
    } catch (e) {
      return CommandResult(
        command: command,
        success: false,
        error: 'Failed to add chapter: $e',
      );
    }
  }

  Future<CommandResult> _executeAddCharacter(
    BuildContext context,
    AddCharacterCommand command,
  ) async {
    if (!command.isValid) {
      return CommandResult(
        command: command,
        success: false,
        error: 'Invalid character data: name and description are required',
      );
    }

    try {
      final provider = Provider.of<CharacterProvider>(context, listen: false);
      await provider.addCharacter(command.name, command.description);

      return CommandResult(
        command: command,
        success: true,
        successMessage: 'Added character: ${command.name}',
      );
    } catch (e) {
      return CommandResult(
        command: command,
        success: false,
        error: 'Failed to add character: $e',
      );
    }
  }

  Future<CommandResult> _executeAddPlot(
    BuildContext context,
    AddPlotCommand command,
  ) async {
    if (!command.isValid) {
      return CommandResult(
        command: command,
        success: false,
        error: 'Invalid plot data: title and description are required',
      );
    }

    try {
      final provider = Provider.of<PlotProvider>(context, listen: false);
      await provider.addPlot(command.title, command.description);

      return CommandResult(
        command: command,
        success: true,
        successMessage: 'Added plot: ${command.title}',
      );
    } catch (e) {
      return CommandResult(
        command: command,
        success: false,
        error: 'Failed to add plot: $e',
      );
    }
  }

  Future<CommandResult> _executeAddMiscNote(
    BuildContext context,
    AddMiscNoteCommand command,
  ) async {
    if (!command.isValid) {
      return CommandResult(
        command: command,
        success: false,
        error: 'Invalid misc note data: title and content are required',
      );
    }

    try {
      final provider = Provider.of<MiscNoteProvider>(context, listen: false);
      await provider.addNote(command.title, command.content);

      return CommandResult(
        command: command,
        success: true,
        successMessage: 'Added misc note: ${command.title}',
      );
    } catch (e) {
      return CommandResult(
        command: command,
        success: false,
        error: 'Failed to add misc note: $e',
      );
    }
  }
}
