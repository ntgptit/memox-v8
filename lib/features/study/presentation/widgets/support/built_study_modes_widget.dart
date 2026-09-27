import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The modes this build can run end to end (spec §3, "Unbuilt stages are
/// never offered"). Grows each phase; P4 deletes this gate once every mode
/// is built.
const Set<StudyMode> builtStudyModes = {StudyMode.browse};

/// A learning session runs its algorithm's whole stage chain (BR-MODE-004),
/// so Learn is offered only once every stage of it is built.
bool isLearningBuilt(SchedulerType type) =>
    stageSequenceOf(type).every(builtStudyModes.contains);

/// A review runs one of the algorithm's review modes (BR-STUDY-055), so it is
/// offered once any of them is built.
bool isReviewBuilt(SchedulerType type) =>
    reviewModesOf(type).any(builtStudyModes.contains);
