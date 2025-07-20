// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_attachment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImageAttachmentAdapter extends TypeAdapter<ImageAttachment> {
  @override
  final int typeId = 10;

  @override
  ImageAttachment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImageAttachment(
      id: fields[0] as int?,
      path: fields[1] as String,
      associatedId: fields[3] as int?,
      attachmentType: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ImageAttachment obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.path)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.associatedId)
      ..writeByte(4)
      ..write(obj.attachmentType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageAttachmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
