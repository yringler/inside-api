import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:inside_api/models.dart';

/// [hivePath] is where the data should be stored.
/// [currentVersion] is the date which any saved data should be newer than or equal to.
/// [rawData] is the entirety of the site JSON.
Future<SiteBoxes> getSiteBoxesWithData(
    {String hivePath, DateTime currentVersion, String rawData}) async {
  final boxes = await _getSiteBoxesNoData(path: hivePath);

  if (boxes.createdDate != null &&
      (currentVersion == null ||
          boxes.createdDate.isAfter(currentVersion) ||
          boxes.createdDate.isAtSameMomentAs(currentVersion))) {
    return boxes;
  }

  // We don't have data, or no current data, so load up the boxes
  // on another isolate.

  await boxes.hive.close();

  final completer = Completer();
  final recievePort = ReceivePort();

  await Isolate.spawn(_setHiveData, [recievePort.sendPort, hivePath, rawData]);

  recievePort.listen((_) => completer.complete());

  await completer.future;

  // Returned re-opened boxes.
  return await _getSiteBoxesNoData(path: hivePath);
}

class SiteBoxes {
  final HiveImpl hive;
  final LazyBox<Section> sections;
  final Box<TopItem> topItems;

  /// Contians assorted bits of information
  final Box data;

  DateTime get createdDate => data.containsKey('date')
      ? DateTime.fromMillisecondsSinceEpoch(data.get('date'))
      : null;

  Future<void> setCreatedDate(DateTime value) async =>
      data.put('date', value.millisecondsSinceEpoch);

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

  Future<void> _setTopSections() async {
    if (topItems.isEmpty) {
      return;
    }

    for (final top in topItems.values) {
      top.section = await sections.get(top.sectionId);
    }
  }

  SiteBoxes({this.hive, this.sections, this.topItems, this.data});
}

/// Loads data into hive.
void _setHiveData(dynamic arguments) async {
  final dynamicArguments = List.castFrom(arguments);
  final sendPort = dynamicArguments[0] as SendPort;
  final hivePath = dynamicArguments[1] as String;
  final rawJson = dynamicArguments[2] as String;

  final site = Site.fromJson(json.decode(rawJson));
  final boxes = await _getSiteBoxesNoData(path: hivePath);

  await boxes.sections.putAll(site.sections);
  await boxes.topItems.putAll(
      Map.fromEntries(site.topItems.map((e) => MapEntry(e.sectionId, e))));
  await boxes
      .setCreatedDate(DateTime.fromMillisecondsSinceEpoch(site.createdDate));

  // Close so that can be opened on other isolate.
  await boxes.hive.close();
  sendPort.send(true);
}

/// A smiple open of all the boxes which doesn't check wether they have data or not.
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
      data: await hive.openBox('data'),
      sections: await hive.openLazyBox<Section>('sections'),
      topItems: await hive.openBox<TopItem>('topitems'));

  await siteBoxes._setTopSections();

  return siteBoxes;
}
