import 'package:html/parser.dart' as html;


void main(List<String> arguments)  {
  final emptyHtml = html.parse('<html><body></body></html>');
  final notHtmlParsed = html.parse('hah, thought you would get html?');
  final emptyText = emptyHtml.children.map((e) => e.text).join(' ').trim();
  final notHtmlText = notHtmlParsed.children.map((e) => e.text).join(' ').trim();

  print(emptyText);
  print(notHtmlText);
}