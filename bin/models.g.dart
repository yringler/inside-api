// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Site _$SiteFromJson(Map<String, dynamic> json) {
  return Site()
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
    };

Section _$SectionFromJson(Map<String, dynamic> json) {
  return Section(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    content: (json['content'] as List)
        ?.map((e) => e == null
            ? null
            : SectionContent.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  )..audioCount = json['audioCount'] as int;
}

Map<String, dynamic> _$SectionToJson(Section instance) => <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'id': instance.id,
      'audioCount': instance.audioCount,
      'content': instance.content,
    };

SectionContent _$SectionContentFromJson(Map<String, dynamic> json) {
  return SectionContent(
    sectionId: json['sectionId'] as int,
    media: json['media'] == null
        ? null
        : Media.fromJson(json['media'] as Map<String, dynamic>),
    smallSection: json['smallSection'] == null
        ? null
        : SmallSection.fromJson(json['smallSection'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$SectionContentToJson(SectionContent instance) =>
    <String, dynamic>{
      'sectionId': instance.sectionId,
      'media': instance.media,
      'smallSection': instance.smallSection,
    };

Media _$MediaFromJson(Map<String, dynamic> json) {
  return Media(
    source: json['source'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
  );
}

Map<String, dynamic> _$MediaToJson(Media instance) => <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'source': instance.source,
    };

SmallSection _$SmallSectionFromJson(Map<String, dynamic> json) {
  return SmallSection(
    title: json['title'] as String,
    description: json['description'] as String,
  )..media = (json['media'] as List)
      ?.map((e) => e == null ? null : Media.fromJson(e as Map<String, dynamic>))
      ?.toList();
}

Map<String, dynamic> _$SmallSectionToJson(SmallSection instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'media': instance.media,
    };

TopItem _$TopItemFromJson(Map<String, dynamic> json) {
  return TopItem(
    sectionId: json['sectionId'] as int,
    image: json['image'] as String,
  );
}

Map<String, dynamic> _$TopItemToJson(TopItem instance) => <String, dynamic>{
      'sectionId': instance.sectionId,
      'image': instance.image,
    };
