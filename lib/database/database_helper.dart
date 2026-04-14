import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'contracts/user_contract.dart';
import 'contracts/category_contract.dart';
import 'contracts/product_contract.dart';
import 'contracts/order_contract.dart';
import 'contracts/address_contract.dart';
import 'contracts/cart_contract.dart';

class DatabaseHelper {
  static const _databaseName = "HoaSenDa.db";
  static const _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // 1. Bảng Users [4]
    await db.execute('''
      CREATE TABLE ${UserContract.tableName} (
        ${UserContract.colId} TEXT PRIMARY KEY,
        ${UserContract.colUsername} TEXT NOT NULL UNIQUE,
        ${UserContract.colPassword} TEXT NOT NULL,
        ${UserContract.colFullName} TEXT NOT NULL,
        ${UserContract.colEmail} TEXT NOT NULL,
        ${UserContract.colPhone} TEXT NOT NULL,
        ${UserContract.colAvatar} TEXT,
        ${UserContract.colRole} TEXT NOT NULL DEFAULT 'CUSTOMER',
        ${UserContract.colMembershipLevel} TEXT DEFAULT 'BRONZE',
        ${UserContract.colPoints} INTEGER DEFAULT 0,
        ${UserContract.colTotalSpent} REAL DEFAULT 0.0,
        ${UserContract.colCreatedAt} INTEGER NOT NULL,
        ${UserContract.colUpdatedAt} INTEGER NOT NULL,
        ${UserContract.colLastLogin} INTEGER
      )
    ''');

    // 2. Bảng Categories [5]
    await db.execute('''
      CREATE TABLE ${CategoryContract.tableName} (
        ${CategoryContract.colId} TEXT PRIMARY KEY,
        ${CategoryContract.colName} TEXT NOT NULL UNIQUE,
        ${CategoryContract.colDescription} TEXT,
        ${CategoryContract.colIcon} TEXT,
        ${CategoryContract.colImage} TEXT,
        ${CategoryContract.colParentId} TEXT,
        ${CategoryContract.colSortOrder} INTEGER DEFAULT 0,
        ${CategoryContract.colCreatedAt} INTEGER NOT NULL,
        ${CategoryContract.colUpdatedAt} INTEGER NOT NULL
      )
    ''');

    // 3. Bảng Products [6]
    await db.execute('''
      CREATE TABLE ${ProductContract.tableName} (
        ${ProductContract.colId} TEXT PRIMARY KEY,
        ${ProductContract.colCategoryId} TEXT NOT NULL,
        ${ProductContract.colName} TEXT NOT NULL,
        ${ProductContract.colScientificName} TEXT,
        ${ProductContract.colDescription} TEXT,
        ${ProductContract.colPrice} REAL NOT NULL,
        ${ProductContract.colSalePrice} REAL,
        ${ProductContract.colStock} INTEGER NOT NULL DEFAULT 0,
        ${ProductContract.colSku} TEXT UNIQUE,
        ${ProductContract.colStatus} TEXT DEFAULT 'AVAILABLE',
        ${ProductContract.colSize} TEXT,
        ${ProductContract.colColor} TEXT,
        ${ProductContract.colOrigin} TEXT,
        ${ProductContract.colCareLevel} TEXT,
        ${ProductContract.colLightRequirement} TEXT,
        ${ProductContract.colWaterRequirement} TEXT,
        ${ProductContract.colIsBestseller} INTEGER DEFAULT 0,
        ${ProductContract.colIsNew} INTEGER DEFAULT 1,
        ${ProductContract.colRating} REAL DEFAULT 0.0,
        ${ProductContract.colReviewCount} INTEGER DEFAULT 0,
        ${ProductContract.colViews} INTEGER DEFAULT 0,
        ${ProductContract.colCreatedAt} INTEGER NOT NULL,
        ${ProductContract.colUpdatedAt} INTEGER NOT NULL
      )
    ''');

    // 4. Bảng Product Images [7]
    await db.execute('''
      CREATE TABLE ${ProductImageContract.tableName} (
        ${ProductImageContract.colId} TEXT PRIMARY KEY,
        ${ProductImageContract.colProductId} TEXT NOT NULL,
        ${ProductImageContract.colImageUrl} TEXT NOT NULL,
        ${ProductImageContract.colIsPrimary} INTEGER DEFAULT 0,
        ${ProductImageContract.colSortOrder} INTEGER DEFAULT 0,
        ${ProductImageContract.colCreatedAt} INTEGER NOT NULL
      )
    ''');

    // 5. Bảng Addresses [8]
    await db.execute('''
      CREATE TABLE ${AddressContract.tableName} (
        ${AddressContract.colId} TEXT PRIMARY KEY,
        ${AddressContract.colUserId} TEXT NOT NULL,
        ${AddressContract.colFullName} TEXT NOT NULL,
        ${AddressContract.colPhone} TEXT NOT NULL,
        ${AddressContract.colAddressLine} TEXT NOT NULL,
        ${AddressContract.colCity} TEXT NOT NULL,
        ${AddressContract.colDistrict} TEXT NOT NULL,
        ${AddressContract.colWard} TEXT NOT NULL,
        ${AddressContract.colAddressType} TEXT DEFAULT 'HOME',
        ${AddressContract.colIsDefault} INTEGER DEFAULT 0,
        ${AddressContract.colCreatedAt} INTEGER NOT NULL,
        ${AddressContract.colUpdatedAt} INTEGER NOT NULL
      )
    ''');
    // Tạo bảng cart
    await db.execute('''
        CREATE TABLE cart (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL UNIQUE,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');
    // Tạo bảng cart_items
    await db.execute('''
        CREATE TABLE cart_items (
          id TEXT PRIMARY KEY,
          cart_id TEXT NOT NULL,
          product_id TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          variant TEXT,
          added_at INTEGER NOT NULL,
          FOREIGN KEY (cart_id) REFERENCES cart (id),
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');
    // Tạo bảng orders
    await db.execute('''
        CREATE TABLE orders (
          id TEXT PRIMARY KEY,
          order_number TEXT NOT NULL UNIQUE,
          user_id TEXT NOT NULL,
          address_id TEXT NOT NULL,
          voucher_id TEXT,
          subtotal REAL NOT NULL,
          shipping_fee REAL NOT NULL DEFAULT 0,
          discount REAL NOT NULL DEFAULT 0,
          total REAL NOT NULL,
          payment_method TEXT NOT NULL,
          payment_status TEXT DEFAULT 'UNPAID',
          order_status TEXT DEFAULT 'PENDING',
          note TEXT,
          payment_date INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id),
          FOREIGN KEY (address_id) REFERENCES addresses (id)
        )
      ''');

    // Tạo bảng order_items
    await db.execute('''
        CREATE TABLE order_items (
          id TEXT PRIMARY KEY,
          order_id TEXT NOT NULL,
          product_id TEXT NOT NULL,
          product_name TEXT NOT NULL,
          variant TEXT,
          quantity INTEGER NOT NULL,
          price REAL NOT NULL,
          total REAL NOT NULL,
          FOREIGN KEY (order_id) REFERENCES orders (id),
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');
    // Tạo bảng favorites (Sản phẩm yêu thích)
    await db.execute('''
        CREATE TABLE favorites (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          product_id TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id),
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');

    // Tạo bảng recently_viewed (Đã xem gần đây)
    await db.execute('''
        CREATE TABLE recently_viewed (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          product_id TEXT NOT NULL,
          viewed_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id),
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');
    // Tạm thời tạo 5 bảng lõi này trước, các bảng Đơn Hàng (Orders) & Giỏ hàng (Cart) ta có thể add thêm sau nếu cần.
  }
}