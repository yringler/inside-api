// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Section _$SectionFromJson(Map<String, dynamic> json) {
  return Section(
    id: json['id'] as int,
    title: json['title'] as String,
    description: json['description'] as String,
    content: (json['content'] as List)
        ?.map((e) => e == null
            ? null
            : SectionContent.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    audioCount: json['audioCount'] as int,
  );
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
    mediaSection: json['mediaSection'] == null
        ? null
        : MediaSection.fromJson(json['mediaSection'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$SectionContentToJson(SectionContent instance) =>
    <String, dynamic>{
      'sectionId': instance.sectionId,
      'media': instance.media,
      'mediaSection': instance.mediaSection,
    };

Media _$MediaFromJson(Map<String, dynamic> json) {
  return Media(
    source: json['source'] as String,
    length: json['length'] == null
        ? null
        : Duration(microseconds: json['length'] as int),
    title: json['title'] as String,
    description: json['description'] as String,
  );
}

Map<String, dynamic> _$MediaToJson(Media instance) => <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'source': instance.source,
      'length': instance.length?.inMicroseconds,
    };

MediaSection _$MediaSectionFromJson(Map<String, dynamic> json) {
  return MediaSection(
    media: (json['media'] as List)
        ?.map(
            (e) => e == null ? null : Media.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    title: json['title'],
    description: json['description'] as String,
  );
}

Map<String, dynamic> _$MediaSectionToJson(MediaSection instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'media': instance.media,
    };

TopItem _$TopItemFromJson(Map<String, dynamic> json) {
  return TopItem(
    sectionId: json['sectionId'] as int,
    image: json['image'] as String,
    title: json['title'] as String,
  );
}

Map<String, dynamic> _$TopItemToJson(TopItem instance) => <String, dynamic>{
      'sectionId': instance.sectionId,
      'title': instance.title,
      'image': instance.image,
    };
