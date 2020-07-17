import 'dart:convert';
import 'dart:io';

import 'package:inside_api/site.dart';

void main() async {
  final siteJson = File('site.json');
  final site = Site.fromJson(json.decode(siteJson.readAsStringSync()));

  final durationJson = File('scriptlets/audiolength/duration.json');
  final dynamicDuration =
      json.decode(durationJson.readAsStringSync()) as Map<String, dynamic>;
  final duration = Map.castFrom<String, dynamic, String, int>(dynamicDuration);
  
  print(duration);
}
