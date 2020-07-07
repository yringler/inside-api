/// Basic site data which is common to all particular site data items.
abstract class SiteDataItem {
  final String title;
  final String description;

  SiteDataItem({this.description, this.title});
}

/// All data on the site.
class Site {
  Map<String, Section> sections;
  List<TopItem> topItems;
}

/// Onne section. A section contains any amount of media or child sections.
class Section extends SiteDataItem {
  final String id;
  int audioCount;
  List<SectionContent> content;

  Section({this.id});
}

/// One item contained in a section. May be any one of a reference to a section,
/// a media item, or a small section.
/// It is an error to provide two data points to one [SectionContent].
class SectionContent {
  final String sectionId;
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
}

/// One lecture. For now, only supports video.
class Media extends SiteDataItem {
  final String source;

  Media({this.source});
}

/// A small section is a special case of section which only contains two media
/// items.
class SmallSection extends SiteDataItem {
  List<Media> media;
}

class TopItem {
  final String sectionId;
  final String image;

  TopItem({this.sectionId, this.image});
}
