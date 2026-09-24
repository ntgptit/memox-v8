import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';

/// A card as its detail screen shows it (BR-CARD-014).
final class CardDetail {
  const CardDetail({
    required this.card,
    required this.tags,
    required this.schedulerType,
    required this.schedule,
  });

  final CardEntity card;

  /// In folded-name order.
  final List<TagEntity> tags;

  /// The scheduler whose fields [schedule] holds; the other scheduler's
  /// fields are not shown (BR-CARD-014).
  final SchedulerType schedulerType;
  final CardScheduleState schedule;

  CardDisplayStatus get displayStatus => CardDisplayStatus.of(schedule);
}
