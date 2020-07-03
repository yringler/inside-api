import 'package:flutter_wordpress/flutter_wordpress.dart';

void main(List<String> arguments) async {
  final wordPress = WordPress(baseUrl: 'http://localhost');

  var posts = await wordPress.fetchPosts(
    postParams: ParamsPostList(
      context: WordPressContext.view,
      pageNum: 1,
      perPage: 20,
      order: Order.desc,
      orderBy: PostOrderBy.date,
    ),
  );

  for (final post in posts.getRange(1, 3)) {
    print(post.title.rendered.trim());
    print(post.content.rendered.trim());
    print('\n');
  }
}
