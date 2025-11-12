import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;
  DBHelper._init();

  // Getter database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('snackscan.db');
    return _database!;
  }

  // Inisialisasi database
  Future<void> initDB() async {
    await database;
  }

  // Buat database baru
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 4, onCreate: _createDB);
  }

  // Membuat tabel
  Future _createDB(Database db, int version) async {
    // Tabel users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        photo_path TEXT,
        phone TEXT,
        bio TEXT
      );
    ''');

    // Tabel favorites
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT,
        product_name TEXT,
        data TEXT,
        image_url TEXT,
        image_front_small_url TEXT,
        origin_country TEXT
      );
    ''');
  }

  // ======================
  // CRUD GENERIK
  // ======================
  Future<int> create(String table, Map<String, Object?> values) async {
    final db = await instance.database;
    return await db.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> queryAll(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<int> deleteWhere(
    String table,
    String where,
    List<dynamic> args,
  ) async {
    final db = await instance.database;
    return await db.delete(table, where: where, whereArgs: args);
  }

  Future<int> update(
    String table,
    Map<String, Object?> values,
    String where,
    List<dynamic> args,
  ) async {
    final db = await instance.database;
    return await db.update(table, values, where: where, whereArgs: args);
  }

  // ======================
  // USERS
  // ======================
  Future<Map<String, Object?>?> queryUserByEmail(String email) async {
    final db = await instance.database;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<int> updateUser(String email, Map<String, Object?> values) async {
    final db = await instance.database;
    return await db.update(
      'users',
      values,
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  // ======================
  // FAVORITES
  // ======================
  Future<Map<String, Object?>?> queryFavoriteByBarcode(String barcode) async {
    final db = await instance.database;
    final res = await db.query(
      'favorites',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<int> upsertFavorite(Map<String, Object?> product) async {
    final existing = await queryFavoriteByBarcode(
      product['barcode']?.toString() ?? '',
    );

    // Pastikan origin_country ada
    if (!product.containsKey('origin_country')) {
      product['origin_country'] = 'Tidak tersedia';
    }

    if (existing != null) {
      return await update('favorites', product, 'barcode = ?', [
        product['barcode'],
      ]);
    } else {
      return await create('favorites', product);
    }
  }
}
