import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/domain/entities/reminder_config.dart';

void main() {
  test('quando enabled for false, minutesBefore deve ser null', () {
    const config = ReminderConfig(
      enabled: false,
      minutesBefore: null,
      notificationId: 10,
    );
    expect(config.enabled, false);
    expect(config.minutesBefore, isNull);
  });

  test('assert dispara se enabled false e minutesBefore preenchido', () {
    expect(
      () => ReminderConfig(
        enabled: false,
        minutesBefore: 10,
        notificationId: 11,
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
