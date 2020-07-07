import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

/// Basic site data which is common to all particular site data items.
abstract class SiteDataItem {
  final String title;
  final String description;

  SiteDataItem({this.description, this.title});
}

@JsonSerializable()

/// All data on the site.
class Site {
  Map<int, Section> sections = Map();
  List<TopItem> topItems = List();

  Map<String, dynamic> toJson() => _$SiteToJson(this);

  Site();

  Site.fromJson(Map<String, dynamic> json);
}

@JsonSerializable()

/// Onne section. A section contains any amount of media or child sections.
class Section extends SiteDataItem {
  final String id;
  int audioCount;
  List<SectionContent> content;

  Section({this.id, String title, String description, this.content})
      : super(title: title, description: description) {
    content ??= List();
  }

  Map<String, dynamic> toJson() => _$SectionToJson(this);
  Section.fromJson(Map<String, dynamic> json) : this();
}

@JsonSerializable()

/// One item contained in a section. May be any one of a reference to a section,
/// a media item, or a small section.
/// It is an error to provide two data points to one [SectionContent].
class SectionContent {
  final int sectionId;
  final Media media;
  final SmallSection smallSection;

  SectionContent({this.sectionId, this.media, this.smallSection}) {
    if ([sectionId, media, smallSection]
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

  Media({this.source, String title, String description})
      : super(title: title, description: description);

  Map<String, dynamic> toJson() => _$MediaToJson(this);
  Media.fromJson(Map<String, dynamic> json) : this();
}

@JsonSerializable()

/// A small section is a special case of section which only contains two media
/// items.
class SmallSection extends SiteDataItem {
  List<Media> media;

  SmallSection({String title, String description})
      : super(title: title, description: description);

  Map<String, dynamic> toJson() => _$SmallSectionToJson(this);
  SmallSection.fromJson(Map<String, dynamic> json) : this();
}

@JsonSerializable()
class TopItem {
  final int sectionId;
  final String image;

  TopItem({this.sectionId, this.image});

  Map<String, dynamic> toJson() => _$TopItemToJson(this);
  TopItem.fromJson(Map<String, dynamic> json) : this();
}
