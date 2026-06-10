import 'package:progressio_mobile/model/calendar_item.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class CalendarProvider extends BaseProvider<CalendarItem> {
  CalendarProvider() : super('calendar');

  @override
  CalendarItem fromJson(dynamic json) => CalendarItem.fromJson(json);

  Future<List<CalendarItem>> getToday() async {
    final data = await getRaw('calendar/today', query: {'page': 1, 'pageSize': 20});
    if (data is List) return data.map((e) => CalendarItem.fromJson(e)).toList();
    if (data is Map && data['items'] != null) {
      return (data['items'] as List).map((e) => CalendarItem.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<CalendarItem>> getUpcoming({int days = 30}) async {
    final data = await getRaw('calendar/upcoming', query: {'days': days, 'page': 1, 'pageSize': 50});
    if (data is List) return data.map((e) => CalendarItem.fromJson(e)).toList();
    if (data is Map && data['items'] != null) {
      return (data['items'] as List).map((e) => CalendarItem.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<CalendarItem>> getMonth(int year, int month) async {
    final data = await getRaw('calendar/month/$year/$month', query: {'page': 1, 'pageSize': 100});
    if (data is List) return data.map((e) => CalendarItem.fromJson(e)).toList();
    if (data is Map && data['items'] != null) {
      return (data['items'] as List).map((e) => CalendarItem.fromJson(e)).toList();
    }
    return [];
  }
}