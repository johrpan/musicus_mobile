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

  factory PartInfo.fromJson(Map<String, dynamic> json) => PartInfo(
        part: WorkPart.fromJson(json['part']),
        instruments: json['instruments']
            .map<Instrument>((j) => Instrument.fromJson(j))
            .toList(),
        composer:
            json['composer'] != null ? Person.fromJson(json['composer']) : null,
      );

  Map<String, dynamic> toJson() => {
        'part': part.toJson(),
        'instruments': instruments.map((i) => i.toJson()).toList(),
        'composers': composer?.toJson(),
      };
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

  /// Deserialize work info from JSON.
  ///
  /// If [sync] is set to true, all contained items will have their sync
  /// property set to true.
  // TODO: Local versions should not be overriden, if their sync property is
  // set to false.
  factory WorkInfo.fromJson(Map<String, dynamic> json, {bool sync = false}) =>
      WorkInfo(
        work: Work.fromJson(json['work']).copyWith(
          sync: sync,
          synced: sync,
        ),
        instruments: json['instruments']
            .map<Instrument>((j) => Instrument.fromJson(j).copyWith(
                  sync: sync,
                  synced: sync,
                ))
            .toList(),
        composers: json['composers']
            .map<Person>((j) => Person.fromJson(j).copyWith(
                  sync: sync,
                  synced: sync,
                ))
            .toList(),
        parts:
            json['parts'].map<PartInfo>((j) => PartInfo.fromJson(j)).toList(),
        sections: json['sections']
            .map<WorkSection>((j) => WorkSection.fromJson(j))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'work': work.toJson(),
        'instruments': instruments.map((i) => i.toJson()).toList(),
        'composers': composers.map((c) => c.toJson()).toList(),
        'parts': parts.map((c) => c.toJson()).toList(),
        'sections': sections.map((s) => s.toJson()).toList(),
      };
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

  factory PerformanceInfo.fromJson(Map<String, dynamic> json,
          {bool sync = false}) =>
      PerformanceInfo(
        person: json['person'] != null
            ? Person.fromJson(json['person']).copyWith(
                sync: sync,
                synced: sync,
              )
            : null,
        ensemble: json['ensemble'] != null
            ? Ensemble.fromJson(json['ensemble']).copyWith(
                sync: sync,
                synced: sync,
              )
            : null,
        role: json['role'] != null
            ? Instrument.fromJson(json['role']).copyWith(
                sync: sync,
                synced: sync,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        'person': person?.toJson(),
        'ensemble': ensemble?.toJson(),
        'role': role?.toJson(),
      };
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

  /// Deserialize recording info from JSON.
  ///
  /// If [sync] is set to true, all contained items will have their sync
  /// property set to true.
  // TODO: Local versions should not be overriden, if their sync property is
  // set to false.
  factory RecordingInfo.fromJson(Map<String, dynamic> json,
          {bool sync = false}) =>
      RecordingInfo(
        recording: Recording.fromJson(json['recording']).copyWith(
          sync: sync,
          synced: sync,
        ),
        performances: json['performances']
            .map<PerformanceInfo>(
                (j) => PerformanceInfo.fromJson(j, sync: sync))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'recording': recording.toJson(),
        'performances': performances.map((p) => p.toJson()).toList(),
      };
}
