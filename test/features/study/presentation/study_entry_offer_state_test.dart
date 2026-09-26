import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/presentation/states/study_entry_offer_state.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

// FE-A6 spec §3: what the Study Entry offers is what the app has built.

StudyEntry _entry({
  SchedulerType type = SchedulerType.eightBox,
  int fresh = 3,
  int due = 2,
  List<ReviewModeOption> reviews = const [],
}) => StudyEntry(
  schedulerType: type,
  cardLimit: 2,
  newCardCount: fresh,
  dueCardCount: due,
  overdueCardCount: 0,
  nextDueAt: null,
  reviewModes: reviews,
  resumable: null,
);

ReviewModeOption _mode(StudyMode mode, {ModeUnavailableReason? reason}) =>
    ReviewModeOption(
      mode: mode,
      cardCount: reason == null ? 2 : 0,
      unavailableReason: reason,
      isDirectionRequired: false,
    );

void main() {
  test('with nothing built, nothing is offered: Learn and every runnable '
      'mode are coming soon, an unrunnable mode keeps its reason', () {
    final offer = studyEntryOfferOf(
      _entry(
        reviews: [
          _mode(StudyMode.match),
          _mode(StudyMode.fill, reason: ModeUnavailableReason.noExample),
        ],
      ),
      built: const {},
    );

    expect(offer.canLearn, isFalse);
    expect(offer.isLearnComingSoon, isTrue);
    expect(offer.canContinue, isFalse);
    expect(
      [for (final review in offer.reviews) review.status],
      [ReviewOfferStatus.comingSoon, ReviewOfferStatus.unavailable],
    );
  });

  test('Learn is offered only when every stage of the sequence is built '
      '(BR-MODE-004)', () {
    final sequence = stageSequenceOf(SchedulerType.sm2).toSet();

    expect(
      studyEntryOfferOf(
        _entry(type: SchedulerType.sm2),
        built: sequence,
      ).canLearn,
      isTrue,
    );
    expect(
      studyEntryOfferOf(
        _entry(type: SchedulerType.sm2),
        built: {StudyMode.browse},
      ).canLearn,
      isFalse,
    );
  });

  test('a built runnable mode is available', () {
    final offer = studyEntryOfferOf(
      _entry(reviews: [_mode(StudyMode.recall)]),
      built: {StudyMode.recall},
    );

    expect(offer.reviews.single.status, ReviewOfferStatus.available);
  });

  test('no new card: Learn is neither offered nor coming soon; its count '
      'is capped by the session limit', () {
    expect(studyEntryOfferOf(_entry(fresh: 0)).isLearnComingSoon, isFalse);
    expect(studyEntryOfferOf(_entry(fresh: 5)).learnShown, 2);
  });

  test('nothing new and nothing due is the nothing-due state '
      '(BR-STUDY-008)', () {
    expect(studyEntryOfferOf(_entry(fresh: 0, due: 0)).isNothingDue, isTrue);
    expect(studyEntryOfferOf(_entry(fresh: 0, due: 1)).isNothingDue, isFalse);
  });

  test('P2 builds Browse and Self-assess: an sm2 deck offers Learn and its '
      'one review (spec §3)', () {
    final offer = studyEntryOfferOf(
      _entry(type: SchedulerType.sm2, reviews: [_mode(StudyMode.selfAssess)]),
    );

    expect(offer.canLearn, isTrue);
    expect(offer.reviewTarget?.mode, StudyMode.selfAssess);
    expect(entryFooterActionOf(offer), EntryFooterAction.review);
  });

  test('with nothing due the footer learns; with nothing new either it is '
      'not drawn', () {
    final onlyNew = studyEntryOfferOf(_entry(type: SchedulerType.sm2, due: 0));
    final nothing = studyEntryOfferOf(
      _entry(type: SchedulerType.sm2, fresh: 0, due: 0),
    );

    expect(onlyNew.reviewTarget, isNull);
    expect(entryFooterActionOf(onlyNew), EntryFooterAction.learn);
    expect(entryFooterActionOf(nothing), isNull);
  });

  test('eight_box reviews in its built modes; Learn waits for recall and '
      'fill (P3)', () {
    final offer = studyEntryOfferOf(
      _entry(reviews: [_mode(StudyMode.recall), _mode(StudyMode.match)]),
    );

    expect(offer.reviewTarget?.mode, StudyMode.match);
    expect(offer.isLearnComingSoon, isTrue);
    expect(entryFooterActionOf(offer), EntryFooterAction.review);
  });

  test('with several modes available the first is the target until one is '
      'picked (E1)', () {
    final entry = _entry(
      reviews: [_mode(StudyMode.match), _mode(StudyMode.guess)],
    );
    const built = {StudyMode.match, StudyMode.guess};

    expect(
      studyEntryOfferOf(entry, built: built).reviewTarget?.mode,
      StudyMode.match,
    );
    expect(
      studyEntryOfferOf(
        entry,
        built: built,
        picked: StudyMode.guess,
      ).reviewTarget?.mode,
      StudyMode.guess,
    );
  });

  test('a picked mode that stops being available falls back to the first '
      'available one (E1)', () {
    final entry = _entry(
      reviews: [
        _mode(StudyMode.match),
        _mode(StudyMode.guess, reason: ModeUnavailableReason.tooFewMeanings),
      ],
    );

    expect(
      studyEntryOfferOf(
        entry,
        built: const {StudyMode.match, StudyMode.guess},
        picked: StudyMode.guess,
      ).reviewTarget?.mode,
      StudyMode.match,
    );
  });

  test('P3 builds Match and Guess', () {
    expect(builtStudyModes, containsAll({StudyMode.match, StudyMode.guess}));
  });

  test('an unavailable self-assess review is no target', () {
    final offer = studyEntryOfferOf(
      _entry(
        type: SchedulerType.sm2,
        reviews: [
          _mode(
            StudyMode.selfAssess,
            reason: ModeUnavailableReason.tooFewPairs,
          ),
        ],
      ),
    );

    expect(offer.reviewTarget, isNull);
  });

  test('a review with no card to ask is no target, even when its mode runs: '
      'the entry reads a mode of nothing due as runnable (kit onlyNew)', () {
    final offer = studyEntryOfferOf(
      _entry(
        type: SchedulerType.sm2,
        due: 0,
        reviews: const [
          ReviewModeOption(
            mode: StudyMode.selfAssess,
            cardCount: 0,
            unavailableReason: null,
            isDirectionRequired: true,
          ),
        ],
      ),
    );

    expect(offer.reviewTarget, isNull);
    expect(entryFooterActionOf(offer), EntryFooterAction.learn);
  });
}
