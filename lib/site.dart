import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:html_unescape/html_unescape_small.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_wordpress/flutter_wordpress.dart' as wp;
import 'models.dart';

part 'site.g.dart';

final htmlUnescape = HtmlUnescape();

@JsonSerializable()

/// All data on the site.
class Site {
  Map<int, Section>? sections = {};
  List<TopItem>? topItems = [];
  DateTime? createdDate;

  Map<String, dynamic> toJson() => _$SiteToJson(this);

  Site({this.createdDate});

  factory Site.fromJson(Map<String, dynamic> json) => _$SiteFromJson(json);

  /// Flatten the category tree as much as possible.
  void compressSections() {
    if (sections == null) {
      return;
    }

    // Remove empty sections.
    final emptyIds = sections!.values
        .where((value) => value.audioCount == 0 || value.audioCount == null)
        .map((e) => e.id)
        .toList();

    for (final id in emptyIds) {
      sections!.remove(id);
    }

    // Remove references to empty sections.
    for (final section in sections!.values) {
      section.content
          .removeWhere((element) => emptyIds.contains(element.sectionId));
    }

    var removedSomething = false;
    do {
      removedSomething = false;

      // Merge any section which has little content into its parent.
      final sectionsToRemove = sections!.values
          .where((element) => element.audioCount == 1)
          .map((e) => e.id)
          .toList();

      for (final id in sectionsToRemove) {
        if (sections![id!]!.removeFrom(this)) {
          removedSomething = true;
        }
      }
    } while (removedSomething);
  }

  /// Go through all the data and update the [Section.audioCount].
  void setAudioCount() {
    for (final section in sections!.values) {
      section.audioCount = null;
    }

    var processing = <int?>{};
    for (final id in sections!.keys) {
      _setAudioCount(processing, id);
    }
  }

  int? _setAudioCount(Set<int?> processing, int? id) {
    if (processing.contains(id)) {
      return 0;
    }

    final section = sections![id!]!;

    if (section.audioCount != null) {
      return section.audioCount;
    }

    // Handle empty sections.
    if (section.content.isEmpty) {
      sections![id] = sections![id]!.copyWith(audioCount: 0);
      return 0;
    }

    // Keep track so that if this section ends up, through its children,
    // referencing itself, we can gracefully return 0.
    processing.add(id);

    // Count how many classes are directly in this section.
    final audioCount = section.content.map((e) {
      if (e.media != null) {
        return 1;
      }
      if (e.mediaSection != null) {
        return e.mediaSection!.media!.length;
      }
      return _setAudioCount(processing, e.sectionId);
    }).reduce((value, element) => value! + element!);

    // Save the audio count.
    sections![id] = sections![id]!.copyWith(audioCount: audioCount);

    processing.remove(id);

    return sections![id]!.audioCount;
  }

  /// Go through all content, make sure it's plain text, not HTML.
  void parseHTML() {
    sections!.values.toList().forEach((section) {
      parseDataXml(section);
      section.content.toList().forEach((content) {
        parseDataXml(content.media);
        parseDataXml(content.mediaSection);
        content.mediaSection?.media?.toList().forEach(parseDataXml);
      });
    });
  }
}

/// Load site from wordpress. Supports incremental update - if a [base] site is
/// passed in, will only query posts from after [Site.createdDate].
Future<Site> fromWordPress(String wordpressUrl,
    {Site? base, DateTime? createdDate}) async {
  final site = base ?? Site();
  final wordPress = wp.WordPress(
      baseUrl: wordpressUrl,
      authenticator: wp.WordPressAuthenticator.ApplicationPasswords);

  final afterDate = createdDate?.toIso8601String() ?? '';

  print('loading');
  var posts = await wordPress.fetchPosts(
      postParams: wp.ParamsPostList(
          context: wp.WordPressContext.view, afterDate: afterDate),
      fetchAll: true,
      customFieldNames: {'menu_order'});

  if (posts.isEmpty) {
    return site;
  }

  // Make request.
  final allCategories = (await wordPress.fetchCategories(
          params: wp.ParamsCategoryList(
            context: wp.WordPressContext.view,
          ),
          fetchAll: true))
      .toList();

  final newCategories = allCategories
      .where((element) => !site.sections!.containsKey(element.id))
      .toList();

  print('Done loading');

  // Load sections. Will not to over-ride any that are already set.
  site.sections!.addAll(Map.fromEntries(newCategories.map(((e) => MapEntry(
      e.id!,
      Section(
        id: e.id,
        parentId: e.parent,
        title: e.name,
        description: e.description,
      ))))));

  // Connect sections.
  for (final category in allCategories) {
    if (category.parent != 0 &&
        category.parent != null &&
        site.sections![category.parent!]!.content
            .where((element) => element.sectionId == category.id)
            .isEmpty) {
      site.sections![category.parent!]!.content
          .add(SectionContent(sectionId: category.id));
    }
  }

  // Load posts
  for (final post in posts) {
    final content = _parsePost(site, post);

    if (content == null) {
      continue;
    }

    for (final categoryId in post.categoryIDs!) {
      site.sections![categoryId]!.content.add(content.copyWith(categoryId));
    }
  }

  // Map of category id to sort value.
  final sectionOrder = Map<int?, int>.fromEntries(allCategories
      .map((e) => e.id)
      .toList()
      .asMap()
      .entries
      .map((e) => MapEntry(e.value, e.key)));

  site.topItems = topImages.keys
      .map((e) => TopItem(sectionId: e, title: site.sections![e]!.title))
      .toList();

  site.topItems!.sort((a, b) =>
      sectionOrder[a.sectionId]!.compareTo(sectionOrder[b.sectionId]!));

  // Sort sections
  for (final section in site.sections!.values) {
    final originalOrder = List.from(section.content);

    section.content.sort((a, b) {
      final aMediaSort = a.media?.order ?? a.mediaSection?.order;
      final bMediaSort = b.media?.order ?? b.mediaSection?.order;

      if (aMediaSort != null && bMediaSort != null) {
        return aMediaSort.compareTo(bMediaSort);
      }
      if (a.sectionId != null && b.sectionId != null) {
        final sectionAOrder = sectionOrder[a.sectionId];
        final sectionBOrder = sectionOrder[b.sectionId];

        if (sectionAOrder == null) {
          stderr.writeln('err: order null : ${a.sectionId}');
        }
        if (sectionBOrder == null) {
          stderr.writeln('err: order null : ${b.sectionId}');
        }

        if (sectionAOrder != null && sectionBOrder != null) {
          return sectionOrder[a.sectionId]!
              .compareTo(sectionOrder[b.sectionId]!);
        }
      }

      // We have to do this because if we return 0, the order is undefined...
      return originalOrder.indexOf(a).compareTo(originalOrder.indexOf(b));
    });
  }

  return site;
}

void parseDataXml(SiteDataItem? dataItem) {
  if (dataItem == null) {
    return;
  }

  dataItem.title = parseXml(dataItem.title);

  dataItem.description = parseXml(dataItem.description);
}

String? parseXml(String? xmlString) {
  if (xmlString == null) {
    return null;
  }

  final xml = html.parse(xmlString.replaceAll('<br>', '\n'));
  final returnValue = xml.children.map((e) => e.text).join(' ').trim();

  return returnValue.isEmpty ? '' : htmlUnescape.convert(returnValue);
}

SectionContent? _parsePost(Site site, wp.Post post) {
  final xml = html.parse(post.content!.rendered);

  final audios = xml.querySelectorAll('.wp-block-audio');

  for (final audio in audios) {
    audio.remove();
  }

  if (audios.isEmpty) {
    return null;
  }

  var description = parseXml(xml.outerHtml)!;

  // If it doesn't have a good description, forget about it.
  // In particular, sometimes the description will be "MP3"
  if (description.length < 4) {
    description = '';
  }

  if (audios.length == 1) {
    final media = _toMedia(audios.first,
        description: description,
        title: post.title!.rendered,
        order:
            post.customFields == null ? null : post.customFields!['menu_order'])
      ?..id = post.id;

    return media == null ? null : SectionContent(media: media);
  } else {
    final medias = audios
        .map(_toMedia)
        // The direct parent of the media item medias is the media section.
        .map((e) => e?.copyWith(parentId: post.id))
        .where((element) => element != null)
        .toList() as List<Media>;

    // Give any media without a good title the title of the post with a counter.
    for (var i = 0; i < medias.length; ++i) {
      if ((medias[i].title?.length ?? 0) <= 3 &&
          (post.title!.rendered?.length ?? 0) > 3) {
        medias[i].title = '${post.title!.rendered}: Class ${i + 1}';
      }
    }

    if (medias.isEmpty) {
      return null;
    }

    return SectionContent(
        mediaSection: MediaSection(
            id: post.id,
            // Media content is duplicated for each section which has it, and
            // it's set (in a copy) when added to a section.
            parentId: null,
            title: post.title!.rendered,
            description: description,
            media: medias,
            order: post.customFields!['menu_order']));
  }
}

Media? _toMedia(Element element,
    {String? description, String? title, int? order}) {
  element.remove();
  final audioSource = element.querySelector('audio')?.attributes['src'];
  final audioTitle = title ?? element.querySelector('figcaption')?.text.trim();

  if (audioSource?.isEmpty ?? true) {
    return null;
  }

  return Media(
      source: audioSource,
      title: audioTitle,
      description: description,
      order: order);
}
