import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:inside_api/models.dart';

/// Provide access to site data. Stored using HiveDB
class SiteService {
  final _SiteBoxes boxes;

  SiteService({this.boxes});

  /// [hivePath] is where the data should be stored.
  /// [currentVersion] is the date which any saved data should be newer than or equal to.
  /// [dataSource] is (for now) a file path which contains JSON of the entire site.
  static Future<SiteService> create(
      {String hivePath, DateTime currentVersion, String dataSource}) async {
    final boxes = await getHive();

    if (boxes.createdDate != null &&
        (currentVersion == null ||
            boxes.createdDate.isAfter(currentVersion) ||
            boxes.createdDate.isAtSameMomentAs(currentVersion))) {
      return SiteService(boxes: boxes);
    }

    // We don't have data, or no current data, so load up the boxes
    // on another isolate.

    await boxes.hive.close();

    final completer = Completer();
    final recievePort = ReceivePort();

    await Isolate.spawn(
        setHiveData, [recievePort.sendPort, hivePath, dataSource]);

    recievePort.listen((_) => completer.complete());

    await completer.future;

    // Returned re-opened boxes.
    return SiteService(boxes: await getHive(path: hivePath));
  }
}

/// Loads data into hive.
void setHiveData(dynamic arguments) async {
  final dynamicArguments = List.castFrom(arguments);
  final sendPort = dynamicArguments[0] as SendPort;
  final hivePath = dynamicArguments[1] as String;
  final dataSource = dynamicArguments[2] as String;

  final site = Site.fromJson(json.decode(File(dataSource).readAsStringSync()));
  final boxes = await getHive(path: hivePath);

  await boxes.sections.putAll(site.sections);
  await boxes.topItems.putAll(
      Map.fromEntries(site.topItems.map((e) => MapEntry(e.sectionId, e))));
  await boxes
      .setCreatedDate(DateTime.fromMillisecondsSinceEpoch(site.createdDate));

  await boxes.hive.close();

  sendPort.send(true);
}

class _SiteBoxes {
  final HiveImpl hive;
  final LazyBox<Section> sections;
  final Box<TopItem> topItems;

  /// Contians assorted bits of information
  final Box data;

  DateTime get createdDate => data.containsKey('date')
      ? DateTime.fromMillisecondsSinceEpoch(data.get('date'))
      : null;

  Future<void> setCreatedDate(DateTime value) async =>
      data.put('key', value.millisecondsSinceEpoch);

  _SiteBoxes({this.hive, this.sections, this.topItems, this.data});
}

Future<_SiteBoxes> getHive({String path}) async {
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

  return _SiteBoxes(
      hive: hive,
      data: await hive.openBox('data'),
      sections: await hive.openLazyBox('sections'),
      topItems: await hive.openBox<TopItem>('topitems'));
}
