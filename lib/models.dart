import 'dart:convert';

import 'package:inside_api/site.dart';
import 'package:json_annotation/json_annotation.dart';
export 'site.dart';

part 'models.g.dart';

/// Basic site data which is common to all particular site data items.
abstract class SiteDataItem {
  final String title;
  final String description;

  SiteDataItem({this.description, this.title});
}

@JsonSerializable()

/// Onne section. A section contains any amount of media or child sections.
class Section extends SiteDataItem {
  final int id;
  final int audioCount;
  final List<SectionContent> content;
  @JsonKey(ignore: true)
  final int parentId;

  Section(
      {this.id,
      String title,
      String description,
      List<SectionContent> content,
      this.audioCount,
      this.parentId})
      : content = content ?? List(),
        super(title: title, description: description) {
    ;
  }

  Map<String, dynamic> toJson() => _$SectionToJson(this);
  Section.fromJson(Map<String, dynamic> json) : this();

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
      if (audioCount == 0) {
        site.sections.remove(id);

        site.topItems.removeWhere((element) => element.sectionId == id);

        return true;
      }

      return false;
    }

    final parent = site.sections[parentId];
    assert(parent != null);
    final index =
        parent.content.indexWhere((element) => element.sectionId == id);

    if (index >= 0) {
      // Save content if there is any.
      if (audioCount > 0) {
        parent.content.replaceRange(index, index + 1, content);
      } else {
        parent.content.removeAt(index);
      }
    } else {
      print("...That wasn't supposed to happen");
      print(json.encode(this));
    }

    site.sections.remove(id);

    // Give all children a new parent. Namely, the parent of this section, which
    // is being rmeoved.
    for (final section in content
        .where((element) => element.sectionId != null)
        .map((e) => site.sections[e.sectionId])) {
      site.sections[section.id] = section.copyWith(parentId: parentId);
    }

    return true;
  }
}

@JsonSerializable()

/// One item contained in a section. May be any one of a reference to a section,
/// a media item, or a small section.
/// It is an error to provide two data points to one [SectionContent].
class SectionContent {
  final int sectionId;
  final Media media;
  final MediaSection mediaSection;

  SectionContent({this.sectionId, this.media, this.mediaSection}) {
    if ([sectionId, media, mediaSection]
            .where((element) => element != null)
            .length >
        1) {
      throw 'Too many non-null arguments. Only one is allowed.';
    }
  }

  Map<String, dynamic> toJson() => _$SectionContentToJson(this);
  SectionContent.fromJson(Map<String, dynamic> json) : this();
}

@JsonSerializable()

/// One lecture. For now, only supports video.
class Media extends SiteDataItem {
  final String source;
  final int _length;

  Media({this.source, Duration length, String title, String description})
      : _length = length?.inMilliseconds ?? 0,
        super(title: title, description: description);

  Duration get length => Duration(milliseconds: _length);

  Map<String, dynamic> toJson() => _$MediaToJson(this);
  Media.fromJson(Map<String, dynamic> json) : this();

  Media copyWith({Duration length}) => Media(
      description: description,
      length: length ?? this.length,
      source: source,
      title: title);
}

@JsonSerializable()

/// A small section is a special case of section which only contains media
/// items.
class MediaSection extends SiteDataItem {
  final List<Media> media;

  MediaSection({this.media, title, String description})
      : super(title: title, description: description);

  Map<String, dynamic> toJson() => _$MediaSectionToJson(this);
  MediaSection.fromJson(Map<String, dynamic> json) : this();
}

@JsonSerializable()
class TopItem {
  final int sectionId;
  final String image;

  TopItem({this.sectionId, this.image});

  Map<String, dynamic> toJson() => _$TopItemToJson(this);
  TopItem.fromJson(Map<String, dynamic> json) : this();
}
