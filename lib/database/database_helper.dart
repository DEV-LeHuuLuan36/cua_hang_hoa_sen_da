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
  static const _databaseVersion = 2;

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
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _seedProductsAndImages(db);
    }
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
    // Tạo bảng vouchers
    await db.execute('''
        CREATE TABLE vouchers (
          id TEXT PRIMARY KEY,
          code TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          description TEXT,
          discount_type TEXT NOT NULL,
          discount_value REAL NOT NULL,
          min_order_value REAL DEFAULT 0,
          max_discount REAL,
          start_date INTEGER NOT NULL,
          end_date INTEGER NOT NULL,
          quantity INTEGER NOT NULL DEFAULT 0,
          used_count INTEGER DEFAULT 0,
          status TEXT DEFAULT 'ACTIVE',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    // Tạo bảng user_vouchers
    await db.execute('''
        CREATE TABLE user_vouchers (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          voucher_id TEXT NOT NULL,
          used_at INTEGER,
          order_id TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id),
          FOREIGN KEY (voucher_id) REFERENCES vouchers (id)
        )
      ''');

    // Seed data ban đầu
    await _seedInitialData(db);
    await _seedProductsAndImages(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Seed Categories
    final categories = [
      {'id': 'cat_senda', 'name': 'Sen Đá', 'description': 'Các loại sen đá đẹp', 'sort_order': 1, 'created_at': now, 'updated_at': now},
      {'id': 'cat_xuongrong', 'name': 'Xương Rồng', 'description': 'Các loại xương rồng', 'sort_order': 2, 'created_at': now, 'updated_at': now},
      {'id': 'cat_chausen', 'name': 'Chậu Sen Đá', 'description': 'Chậu sen đá trang trí', 'sort_order': 3, 'created_at': now, 'updated_at': now},
    ];

    for (var cat in categories) {
      await db.insert('categories', cat, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Seed Vouchers
    final vouchers = [
      {
        'id': 'vch_newuser',
        'code': 'NEWUSER10',
        'name': 'Giảm 10% cho khách mới',
        'description': 'Áp dụng cho đơn từ 200k',
        'discount_type': 'percent',
        'discount_value': 10.0,
        'min_order_value': 200000.0,
        'max_discount': 50000.0,
        'start_date': now - 86400000 * 30,
        'end_date': now + 86400000 * 365,
        'quantity': 100,
        'used_count': 0,
        'status': 'ACTIVE',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'vch_freeship',
        'code': 'FREESHIP',
        'name': 'Miễn phí vận chuyển',
        'description': 'Freeship cho mọi đơn hàng',
        'discount_type': 'freeship',
        'discount_value': 0.0,
        'min_order_value': 0.0,
        'max_discount': null,
        'start_date': now - 86400000 * 30,
        'end_date': now + 86400000 * 365,
        'quantity': 50,
        'used_count': 0,
        'status': 'ACTIVE',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'vch_50k',
        'code': 'GIAM50K',
        'name': 'Giảm 50.000đ',
        'description': 'Giảm trực tiếp 50.000đ',
        'discount_type': 'fixed',
        'discount_value': 50000.0,
        'min_order_value': 300000.0,
        'max_discount': null,
        'start_date': now - 86400000 * 30,
        'end_date': now + 86400000 * 365,
        'quantity': 30,
        'used_count': 0,
        'status': 'ACTIVE',
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (var vch in vouchers) {
      await db.insert('vouchers', vch, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _seedProductsAndImages(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Xóa dữ liệu cũ và chèn lại
    await db.delete('product_images');
    await db.delete('products');

    final products = [
      {
        'id': 'prod_kimcuong',
        'category_id': 'cat_senda',
        'name': 'Sen đá Kim Cương',
        'scientific_name': 'Echeveria Diamond',
        'description': 'Sen đá Kim Cương với lá xếp tầng như bông hoa, màu xanh ngọc sang trọng. Dễ chăm sóc, phù hợp cho người mới bắt đầu.',
        'price': 85000.0,
        'sale_price': null,
        'stock': 25,
        'sku': 'SA-KC-001',
        'status': 'AVAILABLE',
        'size': 'M',
        'color': 'Xanh ngọc',
        'origin': 'Mexico',
        'care_level': 'Dễ',
        'light_requirement': 'Ánh sáng vừa',
        'water_requirement': '1-2 tuần/lần',
        'is_bestseller': 1,
        'is_new': 0,
        'rating': 4.8,
        'review_count': 45,
        'views': 320,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod_nau',
        'category_id': 'cat_senda',
        'name': 'Sen đá Nâu',
        'scientific_name': 'Echeveria Chocolate',
        'description': 'Sen đá Nâu với màu sắc độc đáo từ nâu đỏ đến nâu socola. Lá dày, mọng nước.',
        'price': 75000.0,
        'sale_price': 65000.0,
        'stock': 30,
        'sku': 'SA-N-002',
        'status': 'AVAILABLE',
        'size': 'M',
        'color': 'Nâu',
        'origin': 'Mexico',
        'care_level': 'Dễ',
        'light_requirement': 'Ánh sáng nhiều',
        'water_requirement': '1-2 tuần/lần',
        'is_bestseller': 1,
        'is_new': 0,
        'rating': 4.6,
        'review_count': 38,
        'views': 280,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod_hoahong',
        'category_id': 'cat_senda',
        'name': 'Sen đá Hoa Hồng',
        'scientific_name': 'Echeveria Rose',
        'description': 'Sen đá Hoa Hồng với hình dáng giống như bông hoa hồng đang nở. Màu sắc từ xanh đến hồng nhạt.',
        'price': 120000.0,
        'sale_price': null,
        'stock': 15,
        'sku': 'SA-HH-003',
        'status': 'AVAILABLE',
        'size': 'L',
        'color': 'Hồng nhạt',
        'origin': 'Mexico',
        'care_level': 'Trung bình',
        'light_requirement': 'Ánh sáng nhiều',
        'water_requirement': '1 tuần/lần',
        'is_bestseller': 0,
        'is_new': 1,
        'rating': 4.9,
        'review_count': 22,
        'views': 190,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod_taitho',
        'category_id': 'cat_xuongrong',
        'name': 'Xương rồng Tai Thỏ',
        'scientific_name': 'Opuntia Microdasys',
        'description': 'Xương rồng Tai Thỏ với hình dáng đáng yêu như tai thỏ. Gai nhỏ không quá nguy hiểm.',
        'price': 55000.0,
        'sale_price': null,
        'stock': 40,
        'sku': 'XR-TT-004',
        'status': 'AVAILABLE',
        'size': 'S',
        'color': 'Xanh',
        'origin': 'Mỹ',
        'care_level': 'Rất dễ',
        'light_requirement': 'Ánh sáng nhiều',
        'water_requirement': '2-3 tuần/lần',
        'is_bestseller': 0,
        'is_new': 0,
        'rating': 4.5,
        'review_count': 55,
        'views': 410,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod_uongdong',
        'category_id': 'cat_senda',
        'name': 'Sen đá Móng Rồng',
        'scientific_name': 'Aloe Dragon Scale',
        'description': 'Sen đá Móng Rồng với lá xếp chồng lên nhau như vảy rồng. Màu xanh đậm với viền đỏ.',
        'price': 95000.0,
        'sale_price': 80000.0,
        'stock': 20,
        'sku': 'SA-MR-005',
        'status': 'AVAILABLE',
        'size': 'M',
        'color': 'Xanh đậm',
        'origin': 'Nam Phi',
        'care_level': 'Dễ',
        'light_requirement': 'Ánh sáng vừa',
        'water_requirement': '1-2 tuần/lần',
        'is_bestseller': 1,
        'is_new': 0,
        'rating': 4.7,
        'review_count': 33,
        'views': 250,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod_mix',
        'category_id': 'cat_chausen',
        'name': 'Chậu Sen Đá Mix',
        'scientific_name': 'Mixed Succulent Bowl',
        'description': 'Chậu sen đá mix nhiều loại với chậu gốm trắng sang trọng. Phù hợp trang trí bàn làm việc, kệ sách.',
        'price': 250000.0,
        'sale_price': null,
        'stock': 10,
        'sku': 'CS-MIX-006',
        'status': 'AVAILABLE',
        'size': 'L',
        'color': 'Mix',
        'origin': 'Việt Nam',
        'care_level': 'Dễ',
        'light_requirement': 'Ánh sáng vừa',
        'water_requirement': '1 tuần/lần',
        'is_bestseller': 1,
        'is_new': 1,
        'rating': 4.9,
        'review_count': 67,
        'views': 520,
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (var product in products) {
      await db.insert('products', product, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Chèn ảnh cho từng sản phẩm
    final productImages = [
      {
        'id': 'img_kc_1',
        'product_id': 'prod_kimcuong',
        'image_url': 'https://images.unsplash.com/photo-1520302630591-fc11eff115de?q=80&w=800&auto=format&fit=crop',
        'is_primary': 1,
        'sort_order': 0,
        'created_at': now,
      },
      {
        'id': 'img_nau_1',
        'product_id': 'prod_nau',
        'image_url': 'https://images.unsplash.com/photo-1459411552884-841db9b3cc2a?q=80&w=800&auto=format&fit=crop',
        'is_primary': 1,
        'sort_order': 0,
        'created_at': now,
      },
      {
        'id': 'img_hh_1',
        'product_id': 'prod_hoahong',
        'image_url': 'https://images.unsplash.com/photo-1485955900006-10f4d324d411?q=80&w=800&auto=format&fit=crop',
        'is_primary': 1,
        'sort_order': 0,
        'created_at': now,
      },
      {
        'id': 'img_tt_1',
        'product_id': 'prod_taitho',
        'image_url': 'https://images.unsplash.com/photo-1453904300235-0f2f60b15b5d?q=80&w=800&auto=format&fit=crop',
        'is_primary': 1,
        'sort_order': 0,
        'created_at': now,
      },
      {
        'id': 'img_mr_1',
        'product_id': 'prod_uongdong',
        'image_url': 'https://images.unsplash.com/photo-1509423350716-97f9360b4e09?q=80&w=800&auto=format&fit=crop',
        'is_primary': 1,
        'sort_order': 0,
        'created_at': now,
      },
      {
        'id': 'img_mix_1',
        'product_id': 'prod_mix',
        'image_url': 'https://images.unsplash.com/photo-1463320898484-cdefe81be339?q=80&w=800&auto=format&fit=crop',
        'is_primary': 1,
        'sort_order': 0,
        'created_at': now,
      },
    ];

    for (var img in productImages) {
      await db.insert('product_images', img, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}