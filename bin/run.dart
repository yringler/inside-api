import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:inside_api/models.dart';
import 'package:process_run/process_run.dart' as process;

final encoder = JsonEncoder.withIndent('\t');
final currentRawSiteFile = File('rawsite.current.json');

const dataVersion = 2;
const dropBoxFile = '/site.v$dataVersion.json.gz';
const isDebug = true;
const sourceUrl = 'https://insidechassidus.org/';

/// The number of media URLs which 404, and will always have duration 0
const numInvalidMedia = 4;

/// Reads (or queries) all lessons, creates lesson list and uses duration data.
/// Note that it doesn't compress the site. This allows incremental updates, because
/// we can be certain that all sections (categories) are present (and haven't been
/// compressed away).
/// It than creates a new site JSON, which can be compared with the first and
/// uploaded to dropbox if it's newer.
void main(List<String> arguments) async {
  Site site;

  if (await currentRawSiteFile.exists()) {
    site = await fromWordPress(sourceUrl,
        base: Site.fromJson(json.decode(currentRawSiteFile.readAsStringSync())),
        createdDate: await _getCurrentVersionDate());
  } else {
    site = await fromWordPress(sourceUrl);
  }

  site.setAudioCount();

  final classListFile = File('scriptlets/audiolength/classlist.json');
  final classList = _getClassList(site);
  await classListFile.writeAsString(
      encoder.convert(classList.map((e) => e.source).toSet().toList()));

  // Update our duration list if we need to.
  if (classList.where((element) => element.length == Duration.zero).length >
      numInvalidMedia) {
    print('running check_duration');
    await process.run('node', ['./scriptlets/audiolength/get_duration.js']);
  }
  print('set duration');
  await _setSiteDuration(site);

  await _updateLatestLocalCloud(site);
  print('returning');
  exit(0);
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
  await File('.dateepoch.txt')
      .writeAsString(date.millisecondsSinceEpoch.toString());
}

/// Handle - we got a new class!
Future<void> _updateLatestLocalCloud(Site site) async {
  final rawContents = currentRawSiteFile.existsSync()
      ? currentRawSiteFile.readAsStringSync()
      : null;
  var newJson = encoder.convert(site);

  // If newest is diffirent from current.
  if (rawContents != newJson || isDebug) {
    print('update latest');

    site.createdDate = DateTime.now();
    site.parseHTML();

    // Save site as being current.
    await currentRawSiteFile.writeAsString(newJson, flush: true);

    await _setCurrentVersionDate(site.createdDate);

    print('uploading...');
    await _uploadToDropbox(site);
    if (!isDebug) {
      print('notifying...');
      await _notifyApiOfLatest(site.createdDate);
    } else {
      print('in debug mode');
    }
    print('done');
  }
}

/// Tell API what the newest version of data is.
Future<void> _notifyApiOfLatest(DateTime date) async {
  var password = await File('.updatepassword').readAsString();
  var request = Request(
      'GET',
      Uri.parse(
          'https://inside-api.herokuapp.com/update?auth=$password&date=${date.millisecondsSinceEpoch}&v=$dataVersion'));

  final response = await request.send();

  if (response.statusCode != HttpStatus.noContent) {
    await File('.errorlog').writeAsStringSync('Error! Setting failed');
  }
}

/// Upload newest version of data to dropbox.
/// (Thank you, Raj @https://stackoverflow.com/a/56572616)
Future<void> _uploadToDropbox(Site site) async {
  site.compressSections();
  final key = await File('.droptoken.txt').readAsString();
  await File('dropbox.json').writeAsString(json.encode(site));

  if (isDebug) {
    return;
  }

  var request = Request(
      'POST', Uri.parse('https://content.dropboxapi.com/2/files/upload'))
    ..headers.addAll({
      'Content-Type': 'application/octet-stream',
      'Authorization': 'Bearer $key',
      'Dropbox-API-Arg':
          json.encode({'path': dropBoxFile, 'mode': 'overwrite', 'mute': true}),
    })
    ..bodyBytes = GZipCodec(level: 9).encode(utf8.encode(json.encode(site)));

  await request.send();
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
