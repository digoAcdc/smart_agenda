class DateUtilsEx {
  static DateTime startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }

  static DateTime startOfWeek(DateTime value) {
    final weekday = value.weekday;
    final monday = value.subtract(Duration(days: weekday - 1));
    return startOfDay(monday);
  }

  static DateTime endOfWeek(DateTime value) {
    final sunday = startOfWeek(value).add(const Duration(days: 6));
    return endOfDay(sunday);
  }

  static DateTime startOfMonth(DateTime value) {
    return DateTime(value.year, value.month, 1);
  }

  static DateTime endOfMonth(DateTime value) {
    final nextMonth = value.month == 12
        ? DateTime(value.year + 1, 1, 1)
        : DateTime(value.year, value.month + 1, 1);
    return endOfDay(nextMonth.subtract(const Duration(days: 1)));
  }
}
