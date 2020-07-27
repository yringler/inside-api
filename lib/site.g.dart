// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Site _$SiteFromJson(Map<String, dynamic> json) {
  return Site(
    createdDate: json['createdDate'] == null
        ? null
        : DateTime.parse(json['createdDate'] as String),
  )
    ..sections = (json['sections'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(int.parse(k),
          e == null ? null : Section.fromJson(e as Map<String, dynamic>)),
    )
    ..topItems = (json['topItems'] as List)
        ?.map((e) =>
            e == null ? null : TopItem.fromJson(e as Map<String, dynamic>))
        ?.toList();
}

Map<String, dynamic> _$SiteToJson(Site instance) => <String, dynamic>{
      'sections': instance.sections?.map((k, e) => MapEntry(k.toString(), e)),
      'topItems': instance.topItems,
      'createdDate': instance.createdDate?.toIso8601String(),
    };
