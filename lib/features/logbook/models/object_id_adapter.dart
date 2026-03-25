import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

class ObjectIdAdapter extends TypeAdapter<ObjectId> {
  @override
  final int typeId = 100; // Pilih angka yang belum dipakai adapter lain

  @override
  ObjectId read(BinaryReader reader) {
    // Membaca string dari memori Hive dan mengubahnya kembali jadi ObjectId
    final hexString = reader.readString();
    return ObjectId.fromHexString(hexString);
  }

  @override
  void write(BinaryWriter writer, ObjectId obj) {
    // Mengubah ObjectId menjadi string untuk disimpan di dalam Hive
    writer.writeString(obj.toHexString());
  }
}
