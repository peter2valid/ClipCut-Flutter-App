// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AspectRatioTypeAdapter extends TypeAdapter<AspectRatioType> {
  @override
  final int typeId = 3;

  @override
  AspectRatioType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AspectRatioType.portrait9x16;
      case 1:
        return AspectRatioType.square1x1;
      case 2:
        return AspectRatioType.landscape16x9;
      default:
        return AspectRatioType.portrait9x16;
    }
  }

  @override
  void write(BinaryWriter writer, AspectRatioType obj) {
    switch (obj) {
      case AspectRatioType.portrait9x16:
        writer.writeByte(0);
        break;
      case AspectRatioType.square1x1:
        writer.writeByte(1);
        break;
      case AspectRatioType.landscape16x9:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AspectRatioTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BackgroundTypeAdapter extends TypeAdapter<BackgroundType> {
  @override
  final int typeId = 4;

  @override
  BackgroundType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BackgroundType.blur;
      case 1:
        return BackgroundType.blackBars;
      case 2:
        return BackgroundType.solidColor;
      default:
        return BackgroundType.blur;
    }
  }

  @override
  void write(BinaryWriter writer, BackgroundType obj) {
    switch (obj) {
      case BackgroundType.blur:
        writer.writeByte(0);
        break;
      case BackgroundType.blackBars:
        writer.writeByte(1);
        break;
      case BackgroundType.solidColor:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackgroundTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ClipSettingsAdapter extends TypeAdapter<ClipSettings> {
  @override
  final int typeId = 2;

  @override
  ClipSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClipSettings(
      trimStartMs: fields[0] as int? ?? 0,
      trimEndMs: fields[1] as int? ?? 0,
      aspectRatio:
          fields[2] as AspectRatioType? ?? AspectRatioType.portrait9x16,
      backgroundType: fields[3] as BackgroundType? ?? BackgroundType.blur,
      backgroundColor: fields[4] as int?,
      audioPath: fields[5] as String?,
      audioVolume: fields[6] as double? ?? 1.0,
      muteOriginalAudio: fields[7] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, ClipSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.trimStartMs)
      ..writeByte(1)
      ..write(obj.trimEndMs)
      ..writeByte(2)
      ..write(obj.aspectRatio)
      ..writeByte(3)
      ..write(obj.backgroundType)
      ..writeByte(4)
      ..write(obj.backgroundColor)
      ..writeByte(5)
      ..write(obj.audioPath)
      ..writeByte(6)
      ..write(obj.audioVolume)
      ..writeByte(7)
      ..write(obj.muteOriginalAudio);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClipSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
