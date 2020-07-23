// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SectionAdapter extends TypeAdapter<Section> {
  @override
  final typeId = 1;

  @override
  Section read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Section(
      id: fields[2] as int,
      audioCount: fields[3] as int,
      parentId: fields[5] as int,
    )
      ..title = fields[0] as String
      ..description = fields[1] as String;
  }

  @override
  void write(BinaryWriter writer, Section obj) {
    writer
      ..writeByte(6)
      ..writeByte(2)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.audioCount)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.parentId)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description);
  }
}

class SectionContentAdapter extends TypeAdapter<SectionContent> {
  @override
  final typeId = 2;

  @override
  SectionContent read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SectionContent(
      sectionId: fields[0] as int,
      media: fields[1] as Media,
      mediaSection: fields[2] as MediaSection,
    );
  }

  @override
  void write(BinaryWriter writer, SectionContent obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.sectionId)
      ..writeByte(1)
      ..write(obj.media)
      ..writeByte(2)
      ..write(obj.mediaSection);
  }
}

class MediaAdapter extends TypeAdapter<Media> {
  @override
  final typeId = 3;

  @override
  Media read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Media(
      source: fields[2] as String,
      parentId: fields[4] as int,
    )
      ..title = fields[0] as String
      ..description = fields[1] as String;
  }

  @override
  void write(BinaryWriter writer, Media obj) {
    writer
      ..writeByte(5)
      ..writeByte(2)
      ..write(obj.source)
      ..writeByte(3)
      ..write(obj._length)
      ..writeByte(4)
      ..write(obj.parentId)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description);
  }
}

class MediaSectionAdapter extends TypeAdapter<MediaSection> {
  @override
  final typeId = 4;

  @override
  MediaSection read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MediaSection(
      media: (fields[2] as List)?.cast<Media>(),
      parentId: fields[3] as int,
    )
      ..title = fields[0] as String
      ..description = fields[1] as String;
  }

  @override
  void write(BinaryWriter writer, MediaSection obj) {
    writer
      ..writeByte(4)
      ..writeByte(2)
      ..write(obj.media)
      ..writeByte(3)
      ..write(obj.parentId)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description);
  }
}

class TopItemAdapter extends TypeAdapter<TopItem> {
  @override
  final typeId = 5;

  @override
  TopItem read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TopItem(
      sectionId: fields[0] as int,
      title: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TopItem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.sectionId)
      ..writeByte(1)
      ..write(obj.title);
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Section _$SectionFromJson(Map<String, dynamic> json) {
  return Section(
    id: json['id'] as int,
    title: json['title'],
    description: json['description'] as String,
    content: (json['content'] as List)
        ?.map((e) => e == null
            ? null
            : SectionContent.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    audioCount: json['audioCount'] as int,
    parentId: json['parentId'] as int,
  );
}

Map<String, dynamic> _$SectionToJson(Section instance) => <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'id': instance.id,
      'audioCount': instance.audioCount,
      'content': instance.content,
      'parentId': instance.parentId,
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
  )..section = json['section'] == null
      ? null
      : Section.fromJson(json['section'] as Map<String, dynamic>);
}

Map<String, dynamic> _$SectionContentToJson(SectionContent instance) =>
    <String, dynamic>{
      'sectionId': instance.sectionId,
      'media': instance.media,
      'mediaSection': instance.mediaSection,
      'section': instance.section,
    };

Media _$MediaFromJson(Map<String, dynamic> json) {
  return Media(
    source: json['source'] as String,
    parentId: json['parentId'] as int,
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
      'parentId': instance.parentId,
      'length': instance.length?.inMicroseconds,
    };

MediaSection _$MediaSectionFromJson(Map<String, dynamic> json) {
  return MediaSection(
    media: (json['media'] as List)
        ?.map(
            (e) => e == null ? null : Media.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    parentId: json['parentId'] as int,
    title: json['title'],
    description: json['description'] as String,
  );
}

Map<String, dynamic> _$MediaSectionToJson(MediaSection instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'media': instance.media,
      'parentId': instance.parentId,
    };

TopItem _$TopItemFromJson(Map<String, dynamic> json) {
  return TopItem(
    sectionId: json['sectionId'] as int,
    title: json['title'] as String,
  )..section = json['section'] == null
      ? null
      : Section.fromJson(json['section'] as Map<String, dynamic>);
}

Map<String, dynamic> _$TopItemToJson(TopItem instance) => <String, dynamic>{
      'sectionId': instance.sectionId,
      'title': instance.title,
      'section': instance.section,
    };
