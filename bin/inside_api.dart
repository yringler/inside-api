import 'dart:convert';

import 'package:flutter_wordpress/flutter_wordpress.dart' as wp;
import 'package:html/parser.dart';
import 'models.dart';

void main(List<String> arguments) async {
  final wordPress = wp.WordPress(baseUrl: 'http://localhost');

  var posts = await wordPress.fetchPosts(
      postParams: wp.ParamsPostList(
        context: wp.WordPressContext.view,
        pageNum: 1,
        perPage: 20,
        order: wp.Order.desc,
        orderBy: wp.PostOrderBy.date,
      ),
      fetchCategories: true);

  var categories = await wordPress.fetchCategories(
      params: wp.ParamsCategoryList(
    context: wp.WordPressContext.view,
    pageNum: 1,
    perPage: 20,
  ));

  final site = Site()
    ..sections = Map.fromEntries(categories.map((e) => MapEntry(
        e.id,
        Section(
            id: e.id.toString(), description: e.description, title: e.name))));

  for (final category in categories) {
    if (category.parent != 0) {
      site.sections[category.parent].content
          .add(SectionContent(sectionId: category.id));
    }
  }

  for (final post in posts) {
    final media = parsePost(post);
    final content = SectionContent(media: media);

    for (final categoryId in post.categoryIDs) {
      site.sections[categoryId].content.add(content);
    }
  }

  print(jsonEncode(site));
}

Media parsePost(wp.Post post) {
  final xml = parse(post.content.rendered?.replaceAll('<br>', '\n'));

  final audio = xml.querySelector('.wp-block-audio');
  audio.remove();
  final audioSource = audio.querySelector('audio').attributes['src'];
  final audioTitle = audio.querySelector('figcaption').text?.trim();

  return Media(
      description: xml.children.map((e) => e.text).join(' ').trim(),
      source: audioSource,
      title: audioTitle);
}
