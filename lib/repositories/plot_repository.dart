import 'package:the_book_tool/index.dart';

class PlotRepository extends BaseRepository<Plot> {
  @override
  String get tableName => 'plots';

  @override
  Plot fromMap(Map<String, dynamic> map) => Plot.fromMap(map);
}
