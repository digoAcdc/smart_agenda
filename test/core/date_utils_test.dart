import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/core/utils/date_utils.dart';

void main() {
  test('start/end of day', () {
    final date = DateTime(2026, 3, 3, 15, 22);
    expect(DateUtilsEx.startOfDay(date), DateTime(2026, 3, 3));
    expect(
      DateUtilsEx.endOfDay(date),
      DateTime(2026, 3, 3, 23, 59, 59, 999),
    );
  });

  test('start/end of week and month', () {
    final date = DateTime(2026, 3, 3); // Tuesday
    expect(DateUtilsEx.startOfWeek(date), DateTime(2026, 3, 2));
    expect(DateUtilsEx.endOfWeek(date), DateTime(2026, 3, 8, 23, 59, 59, 999));
    expect(DateUtilsEx.startOfMonth(date), DateTime(2026, 3, 1));
    expect(DateUtilsEx.endOfMonth(date), DateTime(2026, 3, 31, 23, 59, 59, 999));
  });
}
