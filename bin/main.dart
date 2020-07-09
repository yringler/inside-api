import 'dart:convert';

import 'package:inside_api/models.dart';

void main(List<String> arguments) async {
  final site = await fromWordPress('http://localhost');
  print(jsonEncode(site));
}
