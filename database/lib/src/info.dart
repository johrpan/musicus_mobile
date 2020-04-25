import 'database.dart';

/// A bundle of all available information on a work part.
class PartInfo {
  /// The work part itself.
  final Work work;

  /// A list of instruments.
  ///
  /// This will include the instruments, that are specific to this part.
  final List<Instrument> instruments;

  /// The composer of this part.
  /// 
  /// This is null, if this part doesn't have a specific composer.
  final Person composer;

  PartInfo({
    this.work,
    this.instruments,
    this.composer,
  });

  factory PartInfo.fromJson(Map<String, dynamic> json) => PartInfo(
        work: Work.fromJson(json['work']),
        instruments: json['instruments']
            .map<Instrument>((j) => Instrument.fromJson(j))
            .toList(),
        composer:
            json['composer'] != null ? Person.fromJson(json['composer']) : null,
      );

  Map<String, dynamic> toJson() => {
        'work': work.toJson(),
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

  WorkInfo({
    this.work,
    this.instruments,
    this.composers,
    this.parts,
  });

  factory WorkInfo.fromJson(Map<String, dynamic> json) => WorkInfo(
        work: Work.fromJson(json['work']),
        instruments: json['instruments']
            .map<Instrument>((j) => Instrument.fromJson(j))
            .toList(),
        composers:
            json['composers'].map<Person>((j) => Person.fromJson(j)).toList(),
        parts:
            json['parts'].map<WorkInfo>((j) => WorkInfo.fromJson(j)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'work': work.toJson(),
        'instruments': instruments.map((i) => i.toJson()).toList(),
        'composers': composers.map((c) => c.toJson()).toList(),
        'parts': parts.map((c) => c.toJson()).toList(),
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

  factory PerformanceInfo.fromJson(Map<String, dynamic> json) =>
      PerformanceInfo(
        person: json['person'] != null ? Person.fromJson(json['person']) : null,
        ensemble: json['ensemble'] != null
            ? Ensemble.fromJson(json['ensemble'])
            : null,
        role: json['role'] != null ? Instrument.fromJson(json['role']) : null,
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

  factory RecordingInfo.fromJson(Map<String, dynamic> json) => RecordingInfo(
        recording: Recording.fromJson(json['recording']),
        performances: json['performances']
            .map<PerformanceInfo>((j) => PerformanceInfo.fromJson(j))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'recording': recording.toJson(),
        'performances': performances.map((p) => p.toJson()).toList(),
      };
}
