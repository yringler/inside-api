import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_wordpress/flutter_wordpress.dart' as wp;
import 'models.dart';

part 'site.g.dart';

@JsonSerializable()

/// All data on the site.
class Site {
  Map<int, Section> sections = Map();
  List<TopItem> topItems = List();

  Map<String, dynamic> toJson() => _$SiteToJson(this);

  Site();

  Site.fromJson(Map<String, dynamic> json);

  /// Flatten the category tree as much as possible.
  void compressSections() {
  }

  /// Go through all the data and update the [Section.audioCount].
  void setAudioCount() {
    var processing = <int>{};
    for (final id in sections.keys) {
      _setAudioCount(processing, id);
    }
  }

  int _setAudioCount(Set<int> processing, int id) {
    if (processing.contains(id)) {
      return 0;
    }

    final section = sections[id];

    if (section.audioCount != null) {
      return section.audioCount;
    }

    // Handle empty sections.
    if (section.content.isEmpty) {
      sections[id] = sections[id].copyWith(audioCount: 0);
      return 0;
    }

    // Keep track so that if this section ends up, through its children,
    // referencing itself, we can gracefully return 0.
    processing.add(id);

    // Count how many classes are directly in this section.
    final directAudioCount = section.content.map((e) {
      if (e.media != null) {
        return 1;
      }
      if (e.mediaSection != null) {
        return e.mediaSection.media.length;
      }
      return 0;
    }).reduce((value, element) => value + element);

    // Count how many classes are in child sections, recursively.
    var childAudioCount = 0;
    final childSections = section.content
        .where((element) => element.sectionId != null)
        .map((e) => sections[e.sectionId]);

    if (childSections.isNotEmpty) {
      childAudioCount = childSections
          .map((e) => _setAudioCount(processing, e.id))
          .reduce((value, element) => value + element);
    }

    // Save the audio count.
    sections[id] =
        sections[id].copyWith(audioCount: directAudioCount + childAudioCount);

    processing.remove(id);

    return sections[id].audioCount;
  }
}

Future<Site> fromWordPress(String wordpressUrl) async {
  final wordPress = wp.WordPress(baseUrl: wordpressUrl);

  var posts = await wordPress.fetchPosts(
      postParams: wp.ParamsPostList(
        context: wp.WordPressContext.view,
        order: wp.Order.desc,
        orderBy: wp.PostOrderBy.date,
      ),
      fetchCategories: true,
      fetchAll: true);

  // Make request.
  var categories = await wordPress.fetchCategories(
      params: wp.ParamsCategoryList(
        context: wp.WordPressContext.view,
      ),
      fetchAll: true);

  // Load sections.
  final site = Site()
    ..sections = Map.fromEntries(categories.map((e) => MapEntry(
        e.id, Section(id: e.id, description: e.description, title: e.name))));

  // Connect sections.
  // Add any categories without parents to topItems.
  for (final category in categories) {
    if (category.parent != 0) {
      site.sections[category.parent].content
          .add(SectionContent(sectionId: category.id));
    } else {
      site.topItems.add(TopItem(sectionId: category.id));
    }
  }

  // Load posts
  for (final post in posts) {
    final content = _parsePost(site, post);

    for (final categoryId in post.categoryIDs) {
      site.sections[categoryId].content.add(content);
    }
  }

  return site;
}

SectionContent _parsePost(Site site, wp.Post post) {
  final xml = parse(post.content.rendered?.replaceAll('<br>', '\n'));

  final audios = xml.querySelectorAll('.wp-block-audio');

  for (final audio in audios) {
    audio.remove();
  }

  if (audios.isEmpty) {
    return null;
  }

  final description = xml.children.map((e) => e.text).join(' ').trim();

  if (audios.length == 1) {
    return SectionContent(
        media: _toMedia(audios.first, description: description));
  } else {
    return SectionContent(
        mediaSection: MediaSection(
            description: description, media: audios.map(_toMedia)));
  }
}

Media _toMedia(Element element, {String description}) {
  element.remove();
  final audioSource = element.querySelector('audio').attributes['src'];
  final audioTitle = element.querySelector('figcaption').text?.trim();

  return Media(
      source: audioSource, title: audioTitle, description: description);
}
