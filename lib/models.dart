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

  Section(
      {this.id,
      String title,
      String description,
      List<SectionContent> content,
      this.audioCount})
      : content = content ?? List(),
        super(title: title, description: description) {
    ;
  }

  Map<String, dynamic> toJson() => _$SectionToJson(this);
  Section.fromJson(Map<String, dynamic> json) : this();

  Section copyWith({int audioCount}) => Section(
        id: id,
        audioCount: audioCount,
        content: content,
        title: title,
        description: description,
      );
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
      : _length = length.inMilliseconds,
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
