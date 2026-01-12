// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExportResolutionAdapter extends TypeAdapter<ExportResolution> {
  @override
  final int typeId = 5;

  @override
  ExportResolution read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExportResolution.hd720p;
      case 1:
        return ExportResolution.fullHd1080p;
      default:
        return ExportResolution.fullHd1080p;
    }
  }

  @override
  void write(BinaryWriter writer, ExportResolution obj) {
    switch (obj) {
      case ExportResolution.hd720p:
        writer.writeByte(0);
        break;
      case ExportResolution.fullHd1080p:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportResolutionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExportSettingsAdapter extends TypeAdapter<ExportSettings> {
  @override
  final int typeId = 6;

  @override
  ExportSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExportSettings(
      resolution:
          fields[0] as ExportResolution? ?? ExportResolution.fullHd1080p,
      videoBitrate: fields[1] as int? ?? 8000,
      audioBitrate: fields[2] as int? ?? 192,
      frameRate: fields[3] as int? ?? 30,
      outputFormat: fields[4] as String? ?? 'mp4',
    );
  }

  @override
  void write(BinaryWriter writer, ExportSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.resolution)
      ..writeByte(1)
      ..write(obj.videoBitrate)
      ..writeByte(2)
      ..write(obj.audioBitrate)
      ..writeByte(3)
      ..write(obj.frameRate)
      ..writeByte(4)
      ..write(obj.outputFormat);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
