import 'package:get/get.dart';

import '../../domain/entities/class_schedule_slot.dart';
import '../../domain/repositories/i_family_service.dart';

/// Grade sem Familia (pessoal) sempre editavel; da Familia segue o papel.
bool canEditClassSchedule(ClassSchedule? schedule) {
  if (schedule == null || !schedule.isFamily) return true;
  final family = Get.isRegistered<IFamilyService>()
      ? Get.find<IFamilyService>()
      : null;
  final ctx = family?.context;
  return ctx != null && ctx.familyId == schedule.familyId && ctx.canEditAgenda;
}
