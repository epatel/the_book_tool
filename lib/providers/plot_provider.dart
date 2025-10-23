import 'package:the_book_tool/index.dart';

class PlotProvider extends BaseEntityProvider<Plot, PlotRepository> {
  PlotProvider() : super(PlotRepository());

  @override
  String get entityName => 'plots';

  @override
  bool get addAtTop => true; // Plots are added at top

  @override
  Plot createEntity(Map<String, dynamic> params) {
    return Plot(
      title: params['title'] as String,
      description: params['description'] as String,
      orderIndex: params['orderIndex'] as int,
      createdAt: params['createdAt'] as DateTime,
      updatedAt: params['updatedAt'] as DateTime,
    );
  }

  // Convenience getters and methods with specific names
  List<Plot> get plots => entities;

  Future<void> loadPlots() => load();

  Future<void> addPlot(String title, String description) {
    return add({'title': title, 'description': description});
  }

  Future<void> updatePlot(Plot plot) => update(plot);

  Future<void> deletePlot(int id) => delete(id);

  Future<void> reorderPlots(List<Plot> plots) => reorder(plots);
}
