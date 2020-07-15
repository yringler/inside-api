import 'dart:convert';
import 'dart:io';

import 'package:inside_api/models.dart';

void main(List<String> arguments) async {
  final site = await fromWordPress('http://localhost');
  site.setAudioCount();
  site.compressSections();
  final file = File('site.json');
  await file.writeAsString(json.encode(site), flush: true);

  final media = site.sections.values
      .map((section) => section.content
          .map((content) =>
              [content.media?.source] ??
              content.mediaSection?.media?.map((e) => e.source) ??
              [])
          .expand((element) => element))
      .expand(((e) => e))
      .where((element) => element != null)
      // There's this one blob URL - blob:https://insidechassidus.org/5522f127-0038-42e0-abef-2710100ee32a
      // Something to look in to.
      .where((element) => element.toLowerCase().endsWith('.mp3'))
      .toSet()
      .toList()
        ..sort();

  final durationFile = File('durations.json');
  await durationFile.writeAsString(json.encode(media));
}
