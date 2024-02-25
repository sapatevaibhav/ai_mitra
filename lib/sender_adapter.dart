import 'package:hive/hive.dart';
import 'message.dart';

class SenderAdapter extends TypeAdapter<Sender> {
  @override
  final int typeId = 1;

  @override
  Sender read(BinaryReader reader) {
    return Sender.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, Sender obj) {
    writer.writeByte(obj.index);
  }
}
