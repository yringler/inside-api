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
  DateTime createdDate;

  Map<String, dynamic> toJson() => _$SiteToJson(this);

  Site({this.createdDate});

  factory Site.fromJson(Map<String, dynamic> json) => _$SiteFromJson(json);

  /// Flatten the category tree as much as possible.
  void compressSections() {
    var removedSomething = false;
    do {
      removedSomething = false;

      // Merge any section which has little content into its parent.
      final sectionsToRemove = Map<int, Section>.fromEntries(sections.values
          .where((element) => element.audioCount < 2)
          .map((e) => MapEntry(e.id, e)));

      for (final section in sectionsToRemove.values) {
        if (section.removeFrom(this, sectionsToRemove)) {
          removedSomething = true;
        }
      }
    } while (removedSomething);
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

/// Load site from wordpress. Supports incremental update - if a [base] site is
/// passed in, will only query posts from after [Site.createdDate].
Future<Site> fromWordPress(String wordpressUrl,
    {Site base, DateTime createdDate}) async {
  final site = base ?? Site();
  final wordPress = wp.WordPress(baseUrl: wordpressUrl);

  final afterDate = createdDate?.toIso8601String() ?? '';

  print('loading posts...');
  var posts = await wordPress.fetchPosts(
      postParams: wp.ParamsPostList(
          context: wp.WordPressContext.view, afterDate: afterDate),
      fetchCategories: true,
      fetchAll: true,
      customFieldNames: {'menu_order'});

  print('loading categories...');
  // Make request.
  var categories = (await wordPress.fetchCategories(
          params: wp.ParamsCategoryList(
            context: wp.WordPressContext.view,
          ),
          fetchAll: true))
      .where((element) => !site.sections.containsKey(element.id))
      .toList();

  print('Done loading');

  // Load sections. Will not to over-ride any that are already set.
  site.sections.addAll(Map.fromEntries(categories.map((e) => MapEntry(
      e.id,
      Section(
          id: e.id,
          description: e.description,
          title: e.name,
          parentId: e.parent)))));

  // Connect sections.
  // Add any categories without parents to topItems.
  for (final category in categories) {
    if (category.parent != 0 && category.parent != null) {
      site.sections[category.parent].content
          .add(SectionContent(sectionId: category.id));
    } else {
      site.topItems.add(TopItem(sectionId: category.id, title: category.name));
    }
  }

  // Load posts
  for (final post in posts) {
    final content = _parsePost(site, post);

    if (content == null) {
      continue;
    }

    for (final categoryId in post.categoryIDs) {
      site.sections[categoryId].content.add(content);
    }
  }

  // Sort sections
  for (final section in site.sections.values) {
    final originalOrder = List.from(section.content);
    
    section.content.sort((a, b) {
      // We have to do this because if we return 0, the order is undefined...
      if (a.media?.order == null || b.media?.order == null) {
        return originalOrder.indexOf(a).compareTo(originalOrder.indexOf(b));
      }

      return a.media.order.compareTo(b.media.order);
    });
  }

  site.topItems =
      site.topItems.where((element) => element.image != null).toList();

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

  var description = xml.children.map((e) => e.text).join(' ').trim();

  // If it doesn't have a good description, forget about it.
  // In particular, sometimes the description will be "MP3"
  if (description.length < 4) {
    description = null;
  }

  if (audios.length == 1) {
    final media = _toMedia(audios.first,
        description: description,
        title: post.title.rendered,
        order:
            post.customFields == null ? null : post.customFields['menu_order']);

    return media == null ? null : SectionContent(media: media);
  } else {
    final medias =
        audios.map(_toMedia).where((element) => element != null).toList();

    // Give any media without a good title the title of the post with a counter.
    for (var i = 0; i < medias.length; ++i) {
      if ((medias[i].title?.length ?? 0) <= 3 &&
          (post.title.rendered?.length ?? 0) > 3) {
        medias[i].title = '${post.title.rendered}: Class ${i + 1}';
      }
    }

    if (medias.isEmpty) {
      return null;
    }

    return SectionContent(
        mediaSection: MediaSection(
            description: description,
            media: medias,
            title: post.title.rendered));
  }
}

Media _toMedia(Element element, {String description, String title, int order}) {
  element.remove();
  final audioSource = element.querySelector('audio')?.attributes['src'];
  final audioTitle = title ?? element.querySelector('figcaption')?.text?.trim();

  if (audioSource?.isEmpty ?? true) {
    return null;
  }

  return Media(
      source: audioSource,
      title: audioTitle,
      description: description,
      order: order);
}
