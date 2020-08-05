import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:http/http.dart';
import 'package:inside_api/models.dart';
import 'package:path/path.dart' as p;

/// [hivePath] is where the data should be stored.
/// [currentVersion] is the date which any saved data should be newer than or equal to.
/// [rawData] is the entirety of the site JSON.
Future<SiteBoxes> getSiteBoxesWithData(
    {String hivePath, String rawData}) async {
  final boxes = await _getSiteBoxesNoData(path: hivePath);

  final jsonFile = File(p.join(hivePath, 'site.json'));

  if (await jsonFile.exists()) {
    rawData = await jsonFile.readAsString();
  }

  // Return what we have if there aren't any updates.
  if (rawData == null) {
    try {
      return boxes.createdDate != null ? boxes : null;
    } finally {
      await boxes.hive.close();
    }
  }

  await boxes.hive.close();

  await _setHiveData(hivePath: hivePath, rawJson: rawData);

  // We used it, now get rid of it.
  if (await jsonFile.exists()) {
    await jsonFile.delete();
  }

  // Returned re-opened boxes.
  return await _getSiteBoxesNoData(path: hivePath);
}

class SiteBoxes {
  final String path;
  final HiveImpl hive;
  final LazyBox<Section> sections;
  final Box<TopItem> topItems;

  /// Contians assorted bits of information
  final Box data;

  DateTime get createdDate =>
      data.containsKey('date') ? data.get('date') as DateTime : null;

  Future<void> setCreatedDate(DateTime value) async => data.put('date', value);

  /// Goes through all content and loads any sections.
  Future<Section> resolve(Section section) async {
    final nullSectionContent = section.content.where(
        (element) => element.sectionId != null && element.section == null);

    final sectionFutures =
        nullSectionContent.map((e) => sections.get(e.sectionId));

    if (sectionFutures.isEmpty) {
      return section;
    }

    final sectionMap = Map.fromEntries(
        (await Future.wait(sectionFutures)).map((e) => MapEntry(e.id, e)));

    for (final s in nullSectionContent) {
      s.section = sectionMap[s.sectionId];
    }

    return section;
  }

  /// Download data update, for use next time data is loaded.
  Future<void> tryPrepareUpdate() async {
    final request = Request(
        'GET',
        Uri.parse(
            'https://inside-api.herokuapp.com/check?date=${createdDate.millisecondsSinceEpoch}'));

    try {
      final response = await request.send();

      if (response.statusCode == HttpStatus.ok) {
        await File(p.join(path, 'site.json'))
            .writeAsBytes(GZipCodec().decode(await response.stream.toBytes()));
      }
    } catch (ex) {
      print(ex);
    }
  }

  Future<void> _setTopSections() async {
    if (topItems.isEmpty) {
      return;
    }

    for (final top in topItems.values) {
      top.section = await sections.get(top.sectionId);
    }
  }

  SiteBoxes({this.hive, this.sections, this.topItems, this.data, this.path});
}

/// Loads data into hive.
void _setHiveData({String hivePath, String rawJson}) async {
  final site = Site.fromJson(json.decode(rawJson));
  final boxes = await _getSiteBoxesNoData(path: hivePath);

  await boxes.sections.putAll(site.sections);
  await boxes.topItems.putAll(
      Map.fromEntries(site.topItems.map((e) => MapEntry(e.sectionId, e))));
  await boxes.setCreatedDate(site.createdDate);

  // Close so that can be opened on other isolate.
  await boxes.hive.close();
}

/// A simple open of all the boxes which doesn't check wether they have data or not.
Future<SiteBoxes> _getSiteBoxesNoData({String path}) async {
  final hive = HiveImpl();
  await Directory(path).create();
  hive.init(path);

  // Don't worry if we register an adapter twice.
  try {
    hive.registerAdapter(SectionAdapter());
    hive.registerAdapter(SectionContentAdapter());
    hive.registerAdapter(MediaAdapter());
    hive.registerAdapter(MediaSectionAdapter());
    hive.registerAdapter(TopItemAdapter());
  } catch (_) {}

  final siteBoxes = SiteBoxes(
      hive: hive,
      path: path,
      data: await hive.openBox('data'),
      sections: await hive.openLazyBox<Section>('sections'),
      topItems: await hive.openBox<TopItem>('topitems'));

  await siteBoxes._setTopSections();

  return siteBoxes;
}
