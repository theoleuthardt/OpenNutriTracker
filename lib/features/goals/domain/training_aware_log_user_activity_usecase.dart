import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/log_user_activity_usecase.dart';
import 'package:opennutritracker/features/goals/domain/auto_training_day_usecase.dart';

/// [LogUserActivityUsecase] that also applies automatic training days
/// (#36), so every activity written through it (quick add, the workout
/// import) can make its day a training day. Kept as a subclass so
/// upstream's usecase stays as it is.
class TrainingAwareLogUserActivityUsecase extends LogUserActivityUsecase {
  final AutoTrainingDayUsecase _autoTrainingDayUsecase;

  TrainingAwareLogUserActivityUsecase(
    super._addUserActivityUsecase,
    super._addTrackedDayUsecase,
    super._getKcalGoalUsecase,
    super._getMacroGoalUsecase,
    this._autoTrainingDayUsecase,
  );

  @override
  Future<void> logActivity(
    UserActivityEntity activity, {
    required DateTime day,
  }) async {
    await super.logActivity(activity, day: day);
    await _autoTrainingDayUsecase.applyAutomatic(day);
  }
}
