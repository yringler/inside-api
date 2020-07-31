import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:inside_api/models.dart';
import 'package:process_run/process_run.dart' as process;

final encoder = JsonEncoder.withIndent('\t');
final currentRawSiteFile = File('rawsite.current.json');

/// Reads (or queries) all lessons, creates lesson list and uses duration data.
/// Note that it doesn't compress the site. This allows incremental updates, because
/// we can be certain that all sections (categories) are present (and haven't been
/// compressed away).
/// It than creates a new site JSON, which can be compared with the first and
/// uploaded to dropbox if it's newer.
void main(List<String> arguments) async {
  Site site;

  if (await currentRawSiteFile.exists()) {
    site = await fromWordPress('https://insidechassidus.org/',
        base: Site.fromJson(json.decode(currentRawSiteFile.readAsStringSync())),
        createdDate: await _getCurrentVersionDate());
  } else {
    site = await fromWordPress('http://localhost');
  }

  site.setAudioCount();

  final classListFile = File('scriptlets/audiolength/classlist.json');
  final classList = _getClassList(site);
  await classListFile.writeAsString(
      encoder.convert(classList.map((e) => e.source).toSet().toList()));

  // Update our duration list if we need to.
  if (classList
      .where((element) => element.length == Duration.zero)
      .isNotEmpty) {
    print('running check_duration');
    await process.run('node', ['./scriptlets/audiolength/get_duration.js']);
  }

  await _setSiteDuration(site);

  await _updateLatestLocalCloud(site);
}

Future<DateTime> _getCurrentVersionDate() async {
  final file = File('.date.txt');
  if (await file.exists() && await currentRawSiteFile.exists()) {
    return DateTime.parse(await file.readAsString());
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}

Future<void> _setCurrentVersionDate(DateTime date) async {
  final file = File('.date.txt');
  await file.writeAsString(date.toIso8601String());
}

/// Handle - we got a new class!
Future _updateLatestLocalCloud(Site site) async {
  final rawContents = currentRawSiteFile.existsSync()
      ? currentRawSiteFile.readAsStringSync()
      : null;
  final newJson = encoder.convert(site);

  // If newest is diffirent from current.
  if (rawContents != newJson) {
    // Save site as being current.
    await currentRawSiteFile.writeAsString(newJson, flush: true);

    site.createdDate = DateTime.now();
    await _setCurrentVersionDate(site.createdDate);

    await _uploadToDropbox(site);
    await _notifyApiOfLatest(site.createdDate);
  }
}

/// Tell API what the newest version of data is.
Future<void> _notifyApiOfLatest(DateTime date) async {}

/// Upload newest version of data to dropbox.
/// (Thank you, Raj @https://stackoverflow.com/a/56572616)
Future<void> _uploadToDropbox(Site site) async {
  site.compressSections();
  final key = await File('.droptoken.txt').readAsString();

  var request = Request(
      'POST', Uri.parse('https://content.dropboxapi.com/2/files/upload'))
    ..headers.addAll({
      'Content-Type': 'application/octet-stream',
      'Authorization': 'Bearer $key',
      'Dropbox-API-Arg': json
          .encode({'path': '/site.json', 'mode': 'overwrite', 'mute': true}),
    })
    ..bodyBytes = utf8.encode(json.encode(site));

  final response = await request.send();
  var responseString = String.fromCharCodes(await response.stream.toBytes());
  print(responseString);

  final shareRequest = Request(
      'POST',
      Uri.parse(
          'https://api.dropboxapi.com/2/sharing/create_shared_link_with_settings'))
    ..bodyBytes = utf8.encode(json.encode({'path': '/site.json'}))
    ..headers.addAll(
        {'Authorization': 'Bearer $key', 'Content-Type': 'application/json'});

  final shareResponse = await shareRequest.send();
  final shareString =
      String.fromCharCodes(await shareResponse.stream.toBytes());
  print(shareString);
  final Map<String, dynamic> shareJson = json.decode(shareString);
  print(shareJson['url']);
}

List<Media> _getClassList(Site site) {
  final siteContent =
      site.sections.values.map((e) => e.content).expand((e) => e).toList();

  final nestedMedia = siteContent
      .where((element) => element.mediaSection != null)
      .expand((element) => element.mediaSection.media)
      .toList();

  final regularMedia = siteContent
      .where((element) => element.media != null)
      .map((e) => e.media)
      .toList();

  var allMedia = nestedMedia.toList()..addAll(regularMedia);

  allMedia = allMedia.toSet().toList();

  allMedia.sort((a, b) => a.source.compareTo(b.source));

  final allValidMedia = allMedia
      .where((element) => element.source.toLowerCase().endsWith('.mp3'))
      .toList();

  return allValidMedia;
}

void _setSiteDuration(Site site) {
  final durationJson = File('scriptlets/audiolength/duration.json');
  final dynamicDuration =
      json.decode(durationJson.readAsStringSync()) as Map<String, dynamic>;
  final duration = Map.castFrom<String, dynamic, String, int>(dynamicDuration);

  for (final sectionId in site.sections.keys.toList()) {
    final section = site.sections[sectionId];
    for (var i = 0; i < section.content.length; i++) {
      final content = section.content[i];

      if (content.media != null && duration[content.media.source] != null) {
        content.media.length =
            Duration(milliseconds: duration[content.media.source]);
      } else if (content.mediaSection != null) {
        for (final media in content.mediaSection.media) {
          if (duration[media.source] != null) {
            media.length = Duration(milliseconds: duration[media.source]);
          }
        }
      }
    }
  }
}
