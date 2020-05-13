import 'package:moor/moor.dart';

part 'database.g.dart';

@UseMoor(include: {'database.moor'})
class ServerDatabase extends _$ServerDatabase {
  @override
  final schemaVersion = 0;

  ServerDatabase(QueryExecutor e) : super(e);

  Future<User> getUser(String name) async {
    return await (select(users)..where((u) => u.name.equals(name))).getSingle();
  }

  Future<void> updateUser(User user) async {
    await into(users).insert(user, mode: InsertMode.insertOrReplace);
  }

  Future<void> deleteUser(String name) async {
    await (delete(users)..where((u) => u.name.equals(name))).go();
  }
}
