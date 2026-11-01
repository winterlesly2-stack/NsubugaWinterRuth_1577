import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class PosDatabase {
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;

    final databasePath = join(await getDatabasesPath(), 'freshbuy_pos.db');
    _database = await openDatabase(
      databasePath,
      version: 3,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            price REAL NOT NULL,
            stock INTEGER NOT NULL,
            emoji TEXT NOT NULL,
            color INTEGER NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            spent REAL NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            total REAL NOT NULL,
            payment TEXT NOT NULL,
            time INTEGER NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute('''
            UPDATE customers
            SET email = substr(email, 1, instr(email, '@') - 1) || '@gmail.com'
            WHERE lower(email) LIKE '%@example.com'
          ''');
        }
        if (oldVersion < 3) {
          await database.update(
            'products',
            {'emoji': '💧'},
            where: 'name = ?',
            whereArgs: ['Yacket water'],
          );
        }
      },
    );
    return _database!;
  }

  Future<void> seedIfEmpty({
    required List<Map<String, Object?>> products,
    required List<Map<String, Object?>> customers,
    required List<Map<String, Object?>> sales,
  }) async {
    final database = await _db;
    await database.transaction((transaction) async {
      for (final (table, rows) in [
        ('products', products),
        ('customers', customers),
        ('sales', sales),
      ]) {
        final count = Sqflite.firstIntValue(
          await transaction.rawQuery('SELECT COUNT(*) FROM $table'),
        );
        if (count == 0) {
          for (final row in rows) {
            await transaction.insert(table, row);
          }
        }
      }
      await transaction.insert(
        'settings',
        {'key': 'store_name', 'value': 'FreshBuy'},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await transaction.insert(
        'settings',
        {'key': 'offline', 'value': 'false'},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });
  }

  Future<List<Map<String, Object?>>> loadProducts() async =>
      (await _db).query('products', orderBy: 'id');

  Future<List<Map<String, Object?>>> loadCustomers() async =>
      (await _db).query('customers', orderBy: 'id');

  Future<List<Map<String, Object?>>> loadSales() async =>
      (await _db).query('sales', orderBy: 'id');

  Future<Map<String, String>> loadSettings() async {
    final rows = await (await _db).query('settings');
    return {for (final row in rows) row['key']! as String: row['value']! as String};
  }

  Future<int> insertProduct(Map<String, Object?> product) async =>
      (await _db).insert('products', product);

  Future<void> updateProductStock(int id, int stock) async {
    await (await _db).update(
      'products',
      {'stock': stock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertCustomer(Map<String, Object?> customer) async =>
      (await _db).insert('customers', customer);

  Future<void> recordSale({
    required double total,
    required String payment,
    required DateTime time,
    required Map<int, int> stockChanges,
  }) async {
    final database = await _db;
    await database.transaction((transaction) async {
      await transaction.insert('sales', {
        'total': total,
        'payment': payment,
        'time': time.millisecondsSinceEpoch,
      });
      for (final entry in stockChanges.entries) {
        await transaction.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [entry.value, entry.key],
        );
      }
    });
  }

  Future<void> saveSetting(String key, String value) async {
    await (await _db).insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}