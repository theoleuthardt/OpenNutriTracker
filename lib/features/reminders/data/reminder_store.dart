import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/features/reminders/domain/reminder.dart';

/// The user's reminders (#70), stored device-wide as JSON in the config
/// (field 118). The first read takes over the single daily reminder of
/// earlier versions when it was switched on. [changes] fires after every
/// save.
class ReminderStore {
  final ConfigDataSource _config;
  final changes = ValueNotifier<int>(0);

  ReminderStore(this._config);

  Future<List<Reminder>> load() async {
    final json = await _config.getRemindersJson();
    if (json != null) {
      return [
        for (final item in jsonDecode(json) as List)
          Reminder.fromJson(item as Map<String, dynamic>),
      ];
    }
    final config = await _config.getConfig();
    if (config.notificationsEnabled != true) return const [];
    return [
      Reminder(
        id: 'daily',
        type: ReminderType.logMeals,
        hour: config.notificationHour ?? 8,
        minute: config.notificationMinute ?? 0,
        weekdays: Reminder.everyDay,
        enabled: true,
      ),
    ];
  }

  Future<void> save(List<Reminder> reminders) async {
    await _config.setRemindersJson(
      jsonEncode([for (final reminder in reminders) reminder.toJson()]),
    );
    changes.value++;
  }
}
