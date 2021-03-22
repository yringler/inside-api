import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:http/http.dart';
import 'package:inside_api/models.dart';
import 'package:path/path.dart' as p;

/// Version code for the data storage format.
const int dataVersion = 4;

/// [hivePath] is where the data should be stored.
/// [rawData] is the entirety of the site JSON.
Future<SiteBoxes> getSiteBoxesWithData(
    {String hivePath, String rawData}) async {
  final boxes = await _getSiteBoxesNoData(path: hivePath);

  if (boxes == null) {
    return null;
  }

  final jsonFile = File(p.join(hivePath, 'site.json'));

  if (await jsonFile.exists()) {
    rawData = await jsonFile.readAsString();
  }

  // Return what we have if there aren't any updates.
  if (rawData == null) {
    return boxes.createdDate != null ? boxes : null;
  }

  // We used it, now get rid of it.
  if (await jsonFile.exists()) {
    await jsonFile.delete();
  }

  return await _setHiveData(boxes: boxes, rawJson: rawData);
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
    final nullSectionContent = section.content
        .where(
            (element) => element.sectionId != null && element.section == null)
        .toList();

    await resolveIterable(nullSectionContent);

    return section;
  }

  /// Set the section references of passed in list.
  Future<List<SectionReference>> resolveIterable(
      List<SectionReference> references) async {
    final sectionFutures =
        references.map((e) => sections.get(e.sectionId)).toList();

    if (sectionFutures.isEmpty) {
      return references;
    }

    final sectionMap = Map.fromEntries(
        (await Future.wait(sectionFutures)).map((e) => MapEntry(e.id, e)));

    for (final s in references) {
      s.section = sectionMap[s.sectionId];
    }

    return references;
  }

  /// Download data update, for use next time data is loaded.
  Future<void> tryPrepareUpdate() async {
    final request = Request(
        'GET',
        Uri.parse(
            'https://inside-api.herokuapp.com/check?date=${createdDate.millisecondsSinceEpoch}&v=$dataVersion'));

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

/// Loads data into hive. Clears any data already there.
Future<SiteBoxes> _setHiveData({SiteBoxes boxes, String rawJson}) async {
  final site = Site.fromJson(json.decode(rawJson));

  // Clear all data before adding new data.
  await boxes.hive.deleteFromDisk();
  // Create the boxes again.
  boxes = await _getSiteBoxesNoData(path: boxes.path);

  await boxes.sections.putAll(site.sections);
  await boxes.topItems.putAll(
      Map.fromEntries(site.topItems.map((e) => MapEntry(e.sectionId, e))));
  await boxes.setCreatedDate(site.createdDate);

  return boxes;
}

/// A simple open of all the boxes which doesn't check wether they have data or not.
Future<SiteBoxes> _getSiteBoxesNoData({String path}) async {
  final hive = HiveImpl();
  await Directory(path).create();
  hive.init(path);

  var metaBox = await hive.openBox('meta');
  final currentVersionInUse = metaBox.get('dataversion', defaultValue: 0);

  // Don't try to load data if it's of an older type.
  if (currentVersionInUse < dataVersion) {
    await hive.deleteFromDisk();
    await Directory(path).delete(recursive: true);
  }

  metaBox = await hive.openBox('meta');

  try {
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

    // Save the current data version.
    await metaBox.put('dataversion', dataVersion);

    return siteBoxes;
  } catch (_) {
    await hive.deleteFromDisk();
    await Directory(path).delete(recursive: true);

    return null;
  }
}
