import 'database.dart';

/// A bundle information on a work.
///
/// This includes all available information except for recordings of this work.
class WorkInfo {
  /// The work itself.
  final Work work;

  /// A list of instruments.
  ///
  /// This will not the include the instruments, that are specific to the work
  /// parts.
  final List<Instrument> instruments;

  /// The work's composer.
  final Person composer;

  /// All available information on the work parts.
  final List<WorkPart> parts;

  /// The sections of this work.
  final List<WorkSection> sections;

  WorkInfo({
    this.work,
    this.instruments,
    this.composer,
    this.parts,
    this.sections,
  });
}

/// All available information on a performance within a recording.
class PerformanceInfo {
  /// The performing person.
  ///
  /// This will be null, if this is an ensemble.
  final Person person;

  /// The performing ensemble.
  ///
  /// This will be null, if this is a person.
  final Ensemble ensemble;

  /// The instrument/role or null.
  final Instrument role;

  PerformanceInfo({
    this.person,
    this.ensemble,
    this.role,
  });
}

/// All available information on a recording.
///
/// This doesn't include the recorded work, because probably it's already
/// available.
class RecordingInfo {
  /// The recording itself.
  final Recording recording;

  /// Information on the performances within this recording.
  final List<PerformanceInfo> performances;

  RecordingInfo({
    this.recording,
    this.performances,
  });
}
