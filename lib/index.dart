// External packages
export 'package:flutter/material.dart';
export 'package:go_router/go_router.dart';
export 'package:provider/provider.dart';
export 'package:sqflite_common_ffi/sqflite_ffi.dart';
export 'package:path_provider/path_provider.dart';
export 'package:flutter_markdown/flutter_markdown.dart';
export 'package:shared_preferences/shared_preferences.dart';
export 'package:flutter_secure_storage/flutter_secure_storage.dart';
export 'package:window_manager/window_manager.dart';
export 'package:openai_dart/openai_dart.dart' hide Image, Batch;
export 'package:google_fonts/google_fonts.dart';
export 'package:url_launcher/url_launcher.dart';
export 'package:flutter_tts/flutter_tts.dart';

// Design System
export 'design_system/theme.dart';
export 'design_system/reading_fonts.dart';
export 'design_system/widgets/ds_add_icon.dart';
export 'design_system/widgets/ds_app_bar.dart';
export 'design_system/widgets/ds_button.dart';
export 'design_system/widgets/ds_card.dart';
export 'design_system/widgets/ds_dialog.dart';
export 'design_system/widgets/ds_empty_state.dart';
export 'design_system/widgets/ds_list_tile.dart';
export 'design_system/widgets/ds_loading.dart';
export 'design_system/widgets/ds_spacing.dart';
export 'design_system/widgets/ds_text.dart';
export 'design_system/widgets/ds_text_field.dart';

// Models
export 'models/manifest_entry.dart';
export 'models/chapter.dart';
export 'models/character.dart';
export 'models/plot.dart';
export 'models/misc_note.dart';
export 'models/prompt.dart';
export 'models/ai_command.dart';
export 'models/model_pricing.dart';

// Services
export 'services/database_service.dart';
export 'services/database_manager.dart';
export 'services/window_preferences_service.dart';
export 'services/ui_preferences_service.dart';
export 'services/book_data_service.dart';
export 'services/ai_service.dart';
export 'services/ai_command_executor.dart';
export 'services/pdf_service.dart';
export 'services/tts_service.dart';

// Repositories
export 'repositories/manifest_repository.dart';
export 'repositories/chapter_repository.dart';
export 'repositories/character_repository.dart';
export 'repositories/plot_repository.dart';
export 'repositories/misc_note_repository.dart';
export 'repositories/prompt_repository.dart';

// Providers
export 'providers/theme_provider.dart';
export 'providers/chapter_provider.dart';
export 'providers/character_provider.dart';
export 'providers/plot_provider.dart';
export 'providers/misc_note_provider.dart';
export 'providers/prompt_provider.dart';
export 'providers/tts_provider.dart';
export 'providers/ai_usage_provider.dart';

// Widgets
export 'widgets/add_chapter_dialog.dart';
export 'widgets/add_character_dialog.dart';
export 'widgets/add_plot_dialog.dart';
export 'widgets/add_misc_note_dialog.dart';
export 'widgets/add_prompt_dialog.dart';
export 'widgets/edit_chapter_dialog.dart';
export 'widgets/edit_character_dialog.dart';
export 'widgets/edit_plot_dialog.dart';
export 'widgets/edit_misc_note_dialog.dart';
export 'widgets/edit_prompt_dialog.dart';
export 'widgets/settings_dialog.dart';
export 'widgets/database_selection_dialog.dart';
export 'widgets/text_selection_overlay.dart';
export 'widgets/ai_response_dialog.dart';

// Local files
export 'app.dart';
export 'config.dart';
export 'router.dart';
export 'layouts/app_shell.dart';
export 'pages/book_page.dart';
export 'pages/characters_page.dart';
export 'pages/plots_page.dart';
export 'pages/misc_page.dart';
export 'pages/prompts_page.dart';
