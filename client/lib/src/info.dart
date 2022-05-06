import 'database.dart';

/// A bundle of all available information on a work part.
class PartInfo {
  /// The work part itself.
  final WorkPart part;

  /// A list of instruments.
  ///
  /// This will include the instruments, that are specific to this part.
  final List<Instrument> instruments;

  /// The composer of this part.
  ///
  /// This is null, if this part doesn't have a specific composer.
  final Person composer;

  PartInfo({
    this.part,
    this.instruments,
    this.composer,
  });
}

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

  /// A list of persons, which will include all part composers.
  final List<Person> composers;

  /// All available information on the work parts.
  final List<PartInfo> parts;

  /// The sections of this work.
  final List<WorkSection> sections;

  WorkInfo({
    this.work,
    this.instruments,
    this.composers,
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
