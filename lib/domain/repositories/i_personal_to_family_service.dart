import '../../core/result/result.dart';

/// O que a pessoa tinha so para si (eventos e grades) e pode levar para a Familia.
class PersonalDataSummary {
  const PersonalDataSummary({required this.items, required this.schedules});

  final int items;
  final int schedules;

  bool get isEmpty => items == 0 && schedules == 0;
}

abstract class IPersonalToFamilyService {
  Future<PersonalDataSummary> summary();

  /// Leva eventos/tarefas e grades pessoais para a Familia.
  Future<Result<PersonalDataSummary>> moveAllToFamily(String familyId);
}
