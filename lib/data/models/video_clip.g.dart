// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_clip.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoClipAdapter extends TypeAdapter<VideoClip> {
  @override
  final int typeId = 1;

  @override
  VideoClip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoClip(
      id: fields[0] as String,
      index: fields[1] as int,
      startTimeMs: fields[2] as int,
      endTimeMs: fields[3] as int,
      thumbnailPath: fields[4] as String?,
      settings: fields[5] as ClipSettings,
      exportedPath: fields[6] as String?,
      isSelected: fields[7] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, VideoClip obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.index)
      ..writeByte(2)
      ..write(obj.startTimeMs)
      ..writeByte(3)
      ..write(obj.endTimeMs)
      ..writeByte(4)
      ..write(obj.thumbnailPath)
      ..writeByte(5)
      ..write(obj.settings)
      ..writeByte(6)
      ..write(obj.exportedPath)
      ..writeByte(7)
      ..write(obj.isSelected);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoClipAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
