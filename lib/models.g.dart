// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SectionAdapter extends TypeAdapter<Section> {
  @override
  final int typeId = 1;

  @override
  Section read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Section(
      audioCount: fields[4] as int,
    )
      ..content = (fields[5] as List)?.cast<SectionContent>()
      ..id = fields[0] as int
      ..parentId = fields[1] as int
      ..title = fields[2] as String
      ..description = fields[3] as String;
  }

  @override
  void write(BinaryWriter writer, Section obj) {
    writer
      ..writeByte(6)
      ..writeByte(4)
      ..write(obj.audioCount)
      ..writeByte(5)
      ..write(obj.content)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parentId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SectionContentAdapter extends TypeAdapter<SectionContent> {
  @override
  final int typeId = 2;

  @override
  SectionContent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionContentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MediaAdapter extends TypeAdapter<Media> {
  @override
  final int typeId = 3;

  @override
  Media read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Media(
      source: fields[4] as String,
      order: fields[6] as int,
    )
      .._length = fields[5] as int
      ..id = fields[0] as int
      ..parentId = fields[1] as int
      ..title = fields[2] as String
      ..description = fields[3] as String;
  }

  @override
  void write(BinaryWriter writer, Media obj) {
    writer
      ..writeByte(7)
      ..writeByte(4)
      ..write(obj.source)
      ..writeByte(5)
      ..write(obj._length)
      ..writeByte(6)
      ..write(obj.order)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parentId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MediaSectionAdapter extends TypeAdapter<MediaSection> {
  @override
  final int typeId = 4;

  @override
  MediaSection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MediaSection(
      media: (fields[4] as List)?.cast<Media>(),
      order: fields[5] as int,
    )
      ..id = fields[0] as int
      ..parentId = fields[1] as int
      ..title = fields[2] as String
      ..description = fields[3] as String;
  }

  @override
  void write(BinaryWriter writer, MediaSection obj) {
    writer
      ..writeByte(6)
      ..writeByte(4)
      ..write(obj.media)
      ..writeByte(5)
      ..write(obj.order)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parentId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaSectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TopItemAdapter extends TypeAdapter<TopItem> {
  @override
  final int typeId = 5;

  @override
  TopItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Section _$SectionFromJson(Map<String, dynamic> json) {
  return Section(
    id: json['id'] as int,
    parentId: json['parentId'] as int,
    title: json['title'],
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
      'id': instance.id,
      'parentId': instance.parentId,
      'title': instance.title,
      'description': instance.description,
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
    id: json['id'] as int,
    parentId: json['parentId'] as int,
    title: json['title'] as String,
    description: json['description'] as String,
    source: json['source'] as String,
    order: json['order'] as int,
    length: json['length'] == null
        ? null
        : Duration(microseconds: json['length'] as int),
  );
}

Map<String, dynamic> _$MediaToJson(Media instance) => <String, dynamic>{
      'id': instance.id,
      'parentId': instance.parentId,
      'title': instance.title,
      'description': instance.description,
      'source': instance.source,
      'order': instance.order,
      'length': instance.length?.inMicroseconds,
    };

MediaSection _$MediaSectionFromJson(Map<String, dynamic> json) {
  return MediaSection(
    id: json['id'] as int,
    parentId: json['parentId'] as int,
    title: json['title'],
    description: json['description'] as String,
    media: (json['media'] as List)
        ?.map(
            (e) => e == null ? null : Media.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    order: json['order'] as int,
  );
}

Map<String, dynamic> _$MediaSectionToJson(MediaSection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parentId': instance.parentId,
      'title': instance.title,
      'description': instance.description,
      'media': instance.media,
      'order': instance.order,
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
