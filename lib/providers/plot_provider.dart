import 'package:the_book_tool/index.dart';

class PlotProvider extends ChangeNotifier {
  final PlotRepository _repository = PlotRepository();
  List<Plot> _plots = [];
  bool _isLoading = false;

  List<Plot> get plots => _plots;
  bool get isLoading => _isLoading;

  Future<void> loadPlots() async {
    _isLoading = true;
    notifyListeners();

    try {
      _plots = await _repository.getAll();
    } catch (e) {
      debugPrint('Error loading plots: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPlot(String title, String description) async {
    final now = DateTime.now();
    final plot = Plot(
      title: title,
      description: description,
      orderIndex: 0, // Add at top
      createdAt: now,
      updatedAt: now,
    );

    try {
      // Get existing plots before inserting
      final existingPlots = List<Plot>.from(_plots);

      // Insert the new plot
      await _repository.insert(plot);

      // Reload to get the new plot with its database ID
      await loadPlots();

      // Find the newly inserted plot (it will be first due to orderIndex 0)
      final newPlot = _plots.first;

      // Create reordered list: new plot at top, then existing plots
      final reorderedPlots = [newPlot, ...existingPlots];

      // Update all orderIndex values
      await _repository.reorder(reorderedPlots);

      // Final reload to get correct order
      await loadPlots();
    } catch (e) {
      debugPrint('Error adding plot: $e');
    }
  }

  Future<void> updatePlot(Plot plot) async {
    try {
      final updatedPlot = plot.copyWith(updatedAt: DateTime.now());
      await _repository.update(updatedPlot);
      await loadPlots();
    } catch (e) {
      debugPrint('Error updating plot: $e');
    }
  }

  Future<void> deletePlot(int id) async {
    try {
      await _repository.delete(id);
      await loadPlots();
    } catch (e) {
      debugPrint('Error deleting plot: $e');
    }
  }

  Future<void> reorderPlots(List<Plot> plots) async {
    try {
      await _repository.reorder(plots);
      await loadPlots();
    } catch (e) {
      debugPrint('Error reordering plots: $e');
    }
  }
}
