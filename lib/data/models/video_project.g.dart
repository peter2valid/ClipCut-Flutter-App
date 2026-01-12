// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_project.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoProjectAdapter extends TypeAdapter<VideoProject> {
  @override
  final int typeId = 0;

  @override
  VideoProject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoProject(
      id: fields[0] as String,
      name: fields[1] as String,
      sourceVideoPath: fields[2] as String,
      sourceDurationMs: fields[3] as int,
      sourceWidth: fields[4] as int,
      sourceHeight: fields[5] as int,
      clipDurationMs: fields[6] as int,
      clips: (fields[7] as List).cast<VideoClip>(),
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      sourceThumbnailPath: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VideoProject obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sourceVideoPath)
      ..writeByte(3)
      ..write(obj.sourceDurationMs)
      ..writeByte(4)
      ..write(obj.sourceWidth)
      ..writeByte(5)
      ..write(obj.sourceHeight)
      ..writeByte(6)
      ..write(obj.clipDurationMs)
      ..writeByte(7)
      ..write(obj.clips)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.sourceThumbnailPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
