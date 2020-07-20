import 'dart:convert';
import 'dart:io';

import 'package:inside_api/models.dart';

/// Reads (or queries) all lessons, creates lesson list and uses duration data.
void main(List<String> arguments) async {
  Site site;
  final file = File('site.json');

  if (await file.exists()) {
    site = Site.fromJson(json.decode(file.readAsStringSync()));
  } else {
    site = await fromWordPress('http://localhost');
    site.setAudioCount();
    site.compressSections();
    await file.writeAsString(json.encode(site), flush: true);
  }

  final siteContent =
      site.sections.values.map((e) => e.content).expand((e) => e).toList();

  final nestedMedia = siteContent
      .where((element) => element.mediaSection != null)
      .expand((element) => element.mediaSection.media)
      .map((e) => e.source)
      .toList();

  final regularMedia = siteContent
      .where((element) => element.media != null)
      .map((e) => e.media.source)
      .toList();

  final allMedia = nestedMedia.toList()
    ..addAll(regularMedia)
    ..toSet()
    ..toList()
    ..sort();

  final allValidMedia = allMedia
      .where((element) => element.toLowerCase().endsWith('.mp3'))
      .toList();

  final classList = File('scriptlets/audiolength/classlist.json');
  await classList.writeAsString(json.encode(allValidMedia));

  setSiteDuration(site);
  file.writeAsStringSync(json.encode(site));
}

void setSiteDuration(Site site) {
  final durationJson = File('scriptlets/audiolength/duration.json');
  final dynamicDuration =
      json.decode(durationJson.readAsStringSync()) as Map<String, dynamic>;
  final duration = Map.castFrom<String, dynamic, String, int>(dynamicDuration);

  for (final sectionId in site.sections.keys.toList()) {
    final section = site.sections[sectionId];
    for (var i = 0; i < section.content.length; i++) {
      final content = section.content[i];

      if (content.media != null) {
        section.content.replaceRange(i, i + 1, [
          SectionContent(
              media: content.media.copyWith(
                  length: Duration(
                      milliseconds: duration[content.media.source] ?? 0)))
        ]);
      } else if (content.mediaSection != null) {
        final sectionWithDuration = content.mediaSection.media
            .map((e) => e.copyWith(
                length: Duration(milliseconds: duration[e.source] ?? 0)))
            .toList();

        content.mediaSection.media.clear();
        content.mediaSection.media.addAll(sectionWithDuration);
      }
    }
  }
}
