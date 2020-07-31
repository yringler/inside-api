import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:inside_api/site.dart';
import 'package:json_annotation/json_annotation.dart';
import 'site-service.dart';
export 'site.dart';

part 'models.g.dart';

/// Basic site data which is common to all particular site data items.
class SiteDataItem {
  @HiveField(0)
  String title;
  @HiveField(1)
  String description;
}

abstract class CountableSiteDataItem implements SiteDataItem {
  int get audioCount;
}

@HiveType(typeId: 1)
@JsonSerializable()

/// Onne section. A section contains any amount of media or child sections.
class Section extends SiteDataItem implements CountableSiteDataItem {
  @HiveField(2)
  final int id;
  @override
  @HiveField(3)
  int audioCount;
  @HiveField(4)
  List<SectionContent> content;
  @HiveField(5)
  final int parentId;

  Section({
    this.id,
    title,
    String description,
    List<SectionContent> content,
    this.audioCount,
    this.parentId,
  }) : content = content ?? List() {
    this.title = title;
    this.description = description;
  }

  Map<String, dynamic> toJson() => _$SectionToJson(this);
  factory Section.fromJson(Map<String, dynamic> json) =>
      _$SectionFromJson(json);

  Section copyWith({int audioCount, int parentId}) => Section(
      id: id,
      audioCount: audioCount ?? this.audioCount,
      content: content,
      title: title,
      description: description,
      parentId: parentId ?? this.parentId);

  /// Remove this section from the site. If it has any children, they will be
  /// attached to all parents of this section.
  /// Returns true if the item is able to be removed.
  bool removeFrom(Site site) {
    // If this is a top level item, get rid of it if we can.
    if (parentId == null || parentId == 0) {
      return false;
    }

    final parent = site.sections[parentId];
    assert(parent != null);
    final index =
        parent.content.indexWhere((element) => element.sectionId == id);

    if (index >= 0 && audioCount > 0) {
      parent.content.replaceRange(index, index + 1, content);
    }

    if (index == -1) {
      stderr.writeln('Not found in parent: $id in $parentId');
    }

    site.sections.remove(id);
    parent.content.removeWhere((element) => element.sectionId == id);

    // Give all children a new parent. Namely, the parent of this section, which
    // is being removed.
    for (final id in content
        .where((element) => element.sectionId != null)
        .map((e) => e.sectionId)) {
      final section = site.sections[id];
      if (section == null) {
        // This happens because these items where removed in site.remove without
        // removing them from their parents
        stderr.writeln('Error: not found: $id in ${this.id}');
      } else {
        site.sections[section.id] = section.copyWith(parentId: parentId);
      }
    }

    return true;
  }
}

@JsonSerializable()
@HiveType(typeId: 2)

/// One item contained in a section. May be any one of a reference to a section,
/// a media item, or a small section.
/// It is an error to provide two data points to one [SectionContent].
class SectionContent {
  @HiveField(0)
  final int sectionId;
  @HiveField(1)
  final Media media;
  @HiveField(2)
  final MediaSection mediaSection;

  /// Will be null unless used after [SiteBoxes.resolve]
  Section section;

  SectionContent({this.sectionId, this.media, this.mediaSection}) {
    if ([sectionId, media, mediaSection]
            .where((element) => element != null)
            .length >
        1) {
      throw 'Too many non-null arguments. Only one is allowed.';
    }
  }

  Map<String, dynamic> toJson() => _$SectionContentToJson(this);
  factory SectionContent.fromJson(Map<String, dynamic> json) =>
      _$SectionContentFromJson(json);
}

@HiveType(typeId: 3)
@JsonSerializable()

/// One lecture. For now, only supports video.
class Media extends SiteDataItem {
  @HiveField(2)
  final String source;
  @HiveField(3)
  int _length;

  /// This field isn't used yet.
  @HiveField(4)
  final int parentId;
  @HiveField(5)
  final int order;

  Media(
      {this.source,
      this.parentId,
      this.order,
      Duration length,
      String title,
      String description})
      : _length = length?.inMilliseconds ?? 0 {
    this.title = title;
    this.description = description;
  }

  Duration get length => Duration(milliseconds: _length);
  set length(Duration value) => _length = value.inMilliseconds;

  Map<String, dynamic> toJson() => _$MediaToJson(this);
  factory Media.fromJson(Map<String, dynamic> json) => _$MediaFromJson(json);

  Media copyWith({Duration length}) => Media(
      description: description,
      length: length ?? this.length,
      source: source,
      title: title);
}

@HiveType(typeId: 4)
@JsonSerializable()

/// A small section is a special case of section which only contains media
/// items.
class MediaSection extends SiteDataItem implements CountableSiteDataItem {
  @HiveField(2)
  final List<Media> media;
  @HiveField(3)

  /// This field isn't used yet.
  final int parentId;

  MediaSection({this.media, this.parentId, String title, String description}) {
    this.title = title;
    this.description = description;
  }

  Map<String, dynamic> toJson() => _$MediaSectionToJson(this);
  factory MediaSection.fromJson(Map<String, dynamic> json) =>
      _$MediaSectionFromJson(json);

  MediaSection copyWith(List<Media> media) => MediaSection(
      description: description, media: media ?? this.media, title: title);

  @override
  int get audioCount => media.length;
}

@HiveType(typeId: 5)
@JsonSerializable()
class TopItem {
  @HiveField(0)
  final int sectionId;
  @HiveField(1)
  final String title;
  Section section;

  String get image => _topImage[sectionId];

  TopItem({this.sectionId, this.title});

  Map<String, dynamic> toJson() => _$TopItemToJson(this);
  factory TopItem.fromJson(Map<String, dynamic> json) =>
      _$TopItemFromJson(json);
}

// const _topImage = {
//   21: 'https://insidechassidus.org/wp-content/uploads/Hayom-Yom-and-Rebbe-Audio-Classes-6.jpg',
//   4: 'https://insidechassidus.org/wp-content/uploads/Chassidus-of-the-Year-Shiurim.jpg',
//   56: 'https://insidechassidus.org/wp-content/uploads/History-and-Kaballah.jpg',
//   28: 'https://insidechassidus.org/wp-content/uploads/Maamarim-and-handwriting.jpg',
//   34: 'https://insidechassidus.org/wp-content/uploads/Rebbe-Sicha-and-Lekutei-Sichos.jpg',
//   45: 'https://insidechassidus.org/wp-content/uploads/Talks-by-Rabbi-Paltiel.jpg',
//   14: 'https://insidechassidus.org/wp-content/uploads/Tanya-Audio-Classes-Alter-Rebbe-2.jpg',
//   40: 'https://insidechassidus.org/wp-content/uploads/Tefillah.jpg',
//   13: 'https://insidechassidus.org/wp-content/uploads/Parsha-of-the-Week-Audio-Classes.jpg'
// };

const _topImage = {
  16: 'https://insidechassidus.org/wp-content/uploads/Hayom-Yom-and-Rebbe-Audio-Classes-6.jpg',
  1475:
      'https://insidechassidus.org/wp-content/uploads/Chassidus-of-the-Year-Shiurim.jpg',
  19: 'https://insidechassidus.org/wp-content/uploads/History-and-Kaballah.jpg',
  17: 'https://insidechassidus.org/wp-content/uploads/Maamarim-and-handwriting.jpg',
  18: 'https://insidechassidus.org/wp-content/uploads/Rebbe-Sicha-and-Lekutei-Sichos.jpg',
  20: 'https://insidechassidus.org/wp-content/uploads/Talks-by-Rabbi-Paltiel.jpg',
  6: 'https://insidechassidus.org/wp-content/uploads/Tanya-Audio-Classes-Alter-Rebbe-2.jpg',
  15: 'https://insidechassidus.org/wp-content/uploads/Tefillah.jpg',
  1447:
      'https://insidechassidus.org/wp-content/uploads/Parsha-of-the-Week-Audio-Classes.jpg'
};
