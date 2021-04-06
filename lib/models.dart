import 'dart:io';

import 'package:hive/hive.dart';
import 'package:inside_api/site.dart';
import 'package:json_annotation/json_annotation.dart';
import 'site-service.dart';
export 'site.dart';

part 'models.g.dart';

/// Basic site data which is common to all particular site data items.
class SiteDataItem implements SectionReference {
  @HiveField(0)
  int id;

  @override
  @HiveField(1)
  int parentId;
  @HiveField(2)
  String title;
  @HiveField(3)
  String description;

  @override
  SiteDataItem parent;

  @override
  Section section;

  @override
  int get sectionId => parentId;

  @override
  bool operator ==(Object other) {
    if (other is SiteDataItem) {
      return id == other.id &&
          parentId == other.parentId &&
          title == other.title;
    }

    return false;
  }

  SiteDataItem({this.id, this.parentId, this.title, this.description});
}

abstract class CountableSiteDataItem implements SiteDataItem {
  int get audioCount;
}

// A class which contains a reference to a section.
abstract class SectionReference implements ParentReference {
  int get sectionId;
  Section section;

  @override
  int get parentId => sectionId;
  @override
  SiteDataItem get parent => section;
  @override
  set parent(SiteDataItem value) => section = value;
}

extension SectionReferenceExtensions on SectionReference {
  bool get hasSection => this != null && (sectionId ?? 0) > 0;
  bool get hasParent => this != null && (parentId ?? 0) > 0;
}

abstract class ParentReference {
  int get parentId;
  SiteDataItem parent;
}

/// One section. A section contains any amount of media or child sections.
@HiveType(typeId: 1)
@JsonSerializable()
class Section extends SiteDataItem implements CountableSiteDataItem {
  @override
  @HiveField(4)
  int audioCount;
  @HiveField(5)
  List<SectionContent> content;

  Section({
    int id,
    int parentId,
    title,
    String description,
    List<SectionContent> content,
    this.audioCount,
  })  : content = content ?? [],
        super(
          id: id,
          parentId: parentId,
          title: title,
          description: description,
        );

  Map<String, dynamic> toJson() => _$SectionToJson(this);
  factory Section.fromJson(Map<String, dynamic> json) =>
      _$SectionFromJson(json);

  Section copyWith({int audioCount, int parentId}) => Section(
        id: id,
        parentId: parentId ?? this.parentId,
        title: title,
        description: description,
        audioCount: audioCount ?? this.audioCount,
        content: content,
      );

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
      /*
       * Move content to parent.
       * Media, media sections, and child sections all need their parents set to
       * new parent.
       */

      // Start with the easy stuff: media and media section.
      final newContentInParent =
          content.map((e) => e.copyWith(parentId)).toList();

      // Update child sections.
      for (final contentId in newContentInParent
          .where((element) => element.sectionId != null)
          .map((e) => e.sectionId)) {
        final section = site.sections[contentId];
        if (section == null) {
          // This happens because these items where removed in site.remove without
          // removing them from their parents
          stderr.writeln('Error: not found: $contentId in ${id}');
        } else {
          site.sections[section.id].parentId = parentId;
        }
      }
      parent.content.replaceRange(
        index,
        index + 1,
        newContentInParent,
      );
    }

    if (index == -1) {
      stderr.writeln('Not found in parent: $id in $parentId');
    }

    // Purge references to this section.
    site.sections.remove(id);
    parent.content.removeWhere((element) => element.sectionId == id);

    return true;
  }
}

/// One item contained in a section. May be any one of a reference to a section,
/// a media item, or a small section.
/// It is an error to provide two data points to one [SectionContent].
@JsonSerializable()
@HiveType(typeId: 2)
class SectionContent extends SectionReference {
  @HiveField(0)
  @override
  final int sectionId;
  @HiveField(1)
  final Media media;
  @HiveField(2)
  final MediaSection mediaSection;

  /// Will be null unless used after [SiteBoxes.resolve]
  @override
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

  /// Create copy of current data, but with parent set to given parent.
  SectionContent copyWith(int parentId) => SectionContent(
      media: media?.copyWith(parentId: parentId),
      mediaSection: mediaSection?.copyWith(parentId: parentId),
      sectionId: sectionId);
}

@HiveType(typeId: 3)
@JsonSerializable()

/// One lecture. For now, only supports audio.
class Media extends SiteDataItem {
  @HiveField(4)
  final String source;
  @HiveField(5)
  int _length;
  @HiveField(6)
  final int order;

  /// In a [MediaSection], [parentId] is the ID of that [MediaSection] and [sectionId]
  /// is the ID of the [Section] in which the [MediaSection] resides.
  @HiveField(7)
  @override
  final int sectionId;

  Media({
    int id,
    int parentId,
    String title,
    String description,
    this.source,
    this.order,
    this.sectionId,
    Duration length,
  })  : _length = length?.inMilliseconds ?? 0,
        super(
          id: id,
          parentId: parentId,
          title: title,
          description: description,
        );

  Duration get length => Duration(milliseconds: _length);
  set length(Duration value) => _length = value.inMilliseconds;

  Map<String, dynamic> toJson() => _$MediaToJson(this);
  factory Media.fromJson(Map<String, dynamic> json) => _$MediaFromJson(json);

  @override
  bool operator ==(Object other) {
    if (other is Media) {
      return source == other.source;
    }

    return false;
  }

  Media copyWith(
          {Duration length, int parentId, String source, int sectionId}) =>
      Media(
          description: description,
          length: length ?? this.length,
          source: source ?? this.source,
          title: title,
          order: order,
          parentId: parentId ?? this.parentId,
          sectionId: sectionId ?? this.sectionId,
          id: id);
}

/// A small section is a special case of section which only contains media
/// items.
@HiveType(typeId: 4)
@JsonSerializable()
class MediaSection extends SiteDataItem implements CountableSiteDataItem {
  @HiveField(4)
  final List<Media> media;

  @HiveField(5)
  final int order;

  MediaSection(
      {int id, int parentId, title, String description, this.media, this.order})
      : super(
          id: id,
          parentId: parentId,
          title: title,
          description: description,
        );

  Map<String, dynamic> toJson() => _$MediaSectionToJson(this);
  factory MediaSection.fromJson(Map<String, dynamic> json) =>
      _$MediaSectionFromJson(json);

  MediaSection copyWith({List<Media> media, int parentId}) => MediaSection(
      description: description,
      media: media ??
          (parentId == null
                  ? this.media
                  : this.media.map((e) => e.copyWith(sectionId: parentId)))
              .toList(),
      title: title,
      order: order,
      id: id,
      parentId: parentId ?? this.parentId);

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

  String get image => topImages[sectionId];

  TopItem({this.sectionId, this.title});

  Map<String, dynamic> toJson() => _$TopItemToJson(this);
  factory TopItem.fromJson(Map<String, dynamic> json) =>
      _$TopItemFromJson(json);
}

// var topImages = {
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

var topImages = {
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
      'https://insidechassidus.org/wp-content/uploads/Parsha-of-the-Week-Audio-Classes.jpg',
  1104:
      'https://insidechassidus.org/wp-content/uploads/stories-of-rebbeim-1.jpg'
};
