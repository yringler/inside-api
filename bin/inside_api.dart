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
      fetchCategories: true);

  for (final post in posts) {
    print(post.title.rendered.trim());
    print(post.content.rendered);

    for (final category in post.categories) {
      print('category: ' + category.name);
      print(category.description);
      print('endcategory');
    }

    print('\n');
  }
}
