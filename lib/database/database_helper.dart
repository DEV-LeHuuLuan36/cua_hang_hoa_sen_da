import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'contracts/user_contract.dart';
import 'contracts/category_contract.dart';
import 'contracts/product_contract.dart';
import 'contracts/order_contract.dart';
import 'contracts/address_contract.dart';
import 'contracts/cart_contract.dart';
import 'contracts/notification_contract.dart';

class DatabaseHelper {
  static const _databaseName = "HoaSenDa.db";
  static const _databaseVersion = 5;

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
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${NotificationContract.tableName} (
          ${NotificationContract.colId} TEXT PRIMARY KEY,
          ${NotificationContract.colTitle} TEXT NOT NULL,
          ${NotificationContract.colBody} TEXT,
          ${NotificationContract.colPayload} TEXT,
          ${NotificationContract.colIsRead} INTEGER DEFAULT 0,
          ${NotificationContract.colCreatedAt} INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await _seedProductsAndImages(db);
    }
    // Cập nhật từ version 4 lên 5: Thêm voucher_type và đổi end_date thành nullable
    if (oldVersion < 5) {
      // Thêm cột voucher_type nếu chưa có
      try {
        await db.execute("ALTER TABLE vouchers ADD COLUMN voucher_type TEXT DEFAULT 'discount'");
      } catch (_) {}
      // Cập nhật discount_type cho các voucher cũ: freeship -> shipping
      await db.rawUpdate(
        "UPDATE vouchers SET voucher_type = 'shipping' WHERE discount_type = 'freeship'",
      );
    }
  }

  Future _onCreate(Database db, int version) async {
    // 1. Bảng Users
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

    // 2. Bảng Categories
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

    // 3. Bảng Products
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

    // 4. Bảng Product Images
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

    // 5. Bảng Addresses
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

    await db.execute('''
        CREATE TABLE cart (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL UNIQUE,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

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

    await db.execute('''
        CREATE TABLE vouchers (
          id TEXT PRIMARY KEY,
          code TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          description TEXT,
          voucher_type TEXT DEFAULT 'discount',
          discount_type TEXT NOT NULL,
          discount_value REAL NOT NULL,
          min_order_value REAL DEFAULT 0,
          max_discount REAL,
          start_date INTEGER NOT NULL,
          end_date INTEGER,
          quantity INTEGER NOT NULL DEFAULT 0,
          used_count INTEGER DEFAULT 0,
          status TEXT DEFAULT 'ACTIVE',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

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

    await db.execute('''
        CREATE TABLE ${NotificationContract.tableName} (
          ${NotificationContract.colId} TEXT PRIMARY KEY,
          ${NotificationContract.colTitle} TEXT NOT NULL,
          ${NotificationContract.colBody} TEXT,
          ${NotificationContract.colPayload} TEXT,
          ${NotificationContract.colIsRead} INTEGER DEFAULT 0,
          ${NotificationContract.colCreatedAt} INTEGER NOT NULL
        )
      ''');

    await _seedInitialData(db);
    await _seedProductsAndImages(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final categories = [
      {'id': 'cat_senda', 'name': 'Sen Đá', 'description': 'Các loại sen đá đẹp', 'sort_order': 1, 'created_at': now, 'updated_at': now},
      {'id': 'cat_xuongrong', 'name': 'Xương Rồng', 'description': 'Các loại xương rồng', 'sort_order': 2, 'created_at': now, 'updated_at': now},
      {'id': 'cat_chausen', 'name': 'Chậu Sen Đá', 'description': 'Chậu sen đá trang trí', 'sort_order': 3, 'created_at': now, 'updated_at': now},
    ];

    for (var cat in categories) {
      await db.insert('categories', cat, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final vouchers = [
      {
        'id': 'vch_newuser',
        'code': 'NEWUSER10',
        'name': 'Giảm 10% cho khách mới',
        'description': 'Áp dụng cho đơn từ 200k',
        'voucher_type': 'discount',
        'discount_type': 'percent',
        'discount_value': 10.0,
        'min_order_value': 200000.0,
        'max_discount': 50000.0,
        'start_date': now - 86400000 * 30,
        'end_date': null,
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
        'voucher_type': 'shipping',
        'discount_type': 'fixed',
        'discount_value': 30000.0,
        'min_order_value': 0.0,
        'max_discount': null,
        'start_date': now - 86400000 * 30,
        'end_date': null,
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
        'voucher_type': 'discount',
        'discount_type': 'fixed',
        'discount_value': 50000.0,
        'min_order_value': 300000.0,
        'max_discount': null,
        'start_date': now - 86400000 * 30,
        'end_date': now + 86400000 * 30,
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

    await db.delete('product_images');
    await db.delete('products');

    final List<Map<String, dynamic>> masterProducts = [
      // === 1-10: SEN ĐÁ CÁC LOẠI ===
      {
        'baseName': 'Sen Đá Cổ Ngọc',
        'scientific': 'Echeveria Age of',
        'category': 'cat_senda',
        'description': 'Sen Đá Cổ Ngọc với thân cây lignified theo thời gian, tạo nên vẻ đẹp cổ điển độc đáo. Lá xếp tầng hoàn hảo, màu xanh ngọc bích sang trọng. Đây là giống sen đá quý hiếm, mang ý nghĩa tượng trưng cho sự trường tồn và bền vững.',
        'imageUrl': 'assets/images/products/sen-da-co-ngoc.jpg',
        'color': 'Xanh ngọc',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '6-8cm',
        'light': 'Ánh sáng vừa',
        'water': '7-10 ngày/lần',
        'basePrice': 95000.0,
      },
      {
        'baseName': 'Sen Đá Đắt Trắng',
        'scientific': 'Echeveria White Prince',
        'category': 'cat_senda',
        'description': 'Sen Đá Đắt Trắng gây ấn tượng với lớp phấn trắng tự nhiên bao phủ toàn bộ lá, tạo nên vẻ đẹp thuần khiết như tuyết. Khi tiếp xúc trực tiếp, lớp phấn có thể bị trôi, vì vậy hãy chạm nhẹ nhàng. Biểu tượng của sự thuần khiết và thanh lọc.',
        'imageUrl': 'assets/images/products/sen-da-dat-trang.jpg',
        'color': 'Trắng bạc',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '5-7cm',
        'light': 'Ánh sáng nhiều',
        'water': '10-14 ngày/lần',
        'basePrice': 85000.0,
      },
      {
        'baseName': 'Sen Đá Da Quang',
        'scientific': 'Graptopetalum Paraguayense',
        'category': 'cat_senda',
        'description': 'Sen Đá Da Quang sở hữu lớp da mỏng bóng như da, màu xanh pastel nhẹ nhàng. Lá xếp xoáy ốc đều đặn từ tâm ra ngoài. Điểm đặc biệt là khi đủ ánh sáng, mép lá sẽ chuyển sang màu hồng nhạt đầy lãng mạn.',
        'imageUrl': 'assets/images/products/sen-da-da-quang.jpg',
        'color': 'Xanh pastel',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '8-12cm',
        'light': 'Ánh sáng vừa',
        'water': '7-10 ngày/lần',
        'basePrice': 65000.0,
      },
      {
        'baseName': 'Sen Đá Hoa Hồng Xanh',
        'scientific': 'Echeveria Blue Rose',
        'category': 'cat_senda',
        'description': 'Sen Đá Hoa Hồng Xanh với hình dáng hoàn hảo như đóa hoa hồng xanh đang nở rộ. Màu xanh dương đặc trưng pha chút tím nhẹ tạo nên vẻ đẹp thanh nhã. Lá dày, mọng nước, xếp chặt chẽ từ tâm ra ngoài.',
        'imageUrl': 'assets/images/products/sen-da-hoa-hong-xanh.jpg',
        'color': 'Xanh dương',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '10-15cm',
        'light': 'Ánh sáng nhiều',
        'water': '7-10 ngày/lần',
        'basePrice': 120000.0,
      },
      {
        'baseName': 'Sen Đá Nhung Viền Đen',
        'scientific': 'Echeveria Black Prince',
        'category': 'cat_senda',
        'description': 'Sen Đá Nhung Viền Đen mang vẻ đẹp huyền bí với màu xanh đậm gần như đen tuyền. Mép lá có viền đỏ nổi bật, tạo nên sự tương phản quyến rũ. Đây là sen đá hiếm được nhiều người yêu thích.',
        'imageUrl': 'assets/images/products/sen-da-nhung-vien-den.jpg',
        'color': 'Đen đỏ',
        'origin': 'Mexico',
        'care': 'Trung bình',
        'size': '7-10cm',
        'light': 'Ánh sáng vừa',
        'water': '10-14 ngày/lần',
        'basePrice': 110000.0,
      },
      {
        'baseName': 'Sen Sỏi',
        'scientific': 'Graptopetalum Bellum',
        'category': 'cat_senda',
        'description': 'Sen Sỏi với hình dáng nhỏ nhắn như những viên sỏi màu hồng. Lá tròn đầy đặn, xếp thành bông hoa cúc mini đáng yêu. Màu sắc chuyển từ xanh bạc sang hồng phấn khi đủ ánh sáng. Dễ trồng, dễ chăm.',
        'imageUrl': 'assets/images/products/sen-soi.jpg',
        'color': 'Hồng bạc',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '4-6cm',
        'light': 'Ánh sáng vừa',
        'water': '10-14 ngày/lần',
        'basePrice': 45000.0,
      },
      {
        'baseName': 'Sen Đá Dola',
        'scientific': 'Echeveria Dola',
        'category': 'cat_senda',
        'description': 'Sen Đá Dola gây ấn tượng với màu xanh bạc đặc trưng, lá dài xếp tầng như bông hoa tulip đang nở. Thân cây có thể cao dần theo thời gian nếu thiếu ánh sáng. Một loại sen đá đẹp và dễ chăm sóc.',
        'imageUrl': 'assets/images/products/sen-da-dola.jpg',
        'color': 'Xanh bạc',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '10-15cm',
        'light': 'Ánh sáng nhiều',
        'water': '7-10 ngày/lần',
        'basePrice': 75000.0,
      },
      {
        'baseName': 'Sen Đá Cổ Tím',
        'scientific': 'Echeveria Violet',
        'category': 'cat_senda',
        'description': 'Sen Đá Cổ Tím với màu tím huyền bí từ gốc đến đầu lá. Càng tiếp xúc với ánh nắng, màu tím càng đậm đà và quyến rũ. Đây là biểu tượng của sự sang trọng và đẳng cấp trong thế giới sen đá.',
        'imageUrl': 'assets/images/products/sen-da-co-tim.jpg',
        'color': 'Tím đậm',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '8-12cm',
        'light': 'Ánh sáng nhiều',
        'water': '7-10 ngày/lần',
        'basePrice': 88000.0,
      },
      {
        'baseName': 'Sen Đá Đĩa Ảnh Kim',
        'scientific': 'Astrophytum Asterias',
        'category': 'cat_senda',
        'description': 'Sen Đá Đĩa Ảnh Kim có hình dáng phẳng đặc trưng như chiếc đĩa, với các đốm trắng li ti trên bề mặt tạo nên hoa văn đẹp mắt. Đây là loại sen đá hiếm, mang vẻ đẹp độc đáo không lẫn với bất kỳ loại nào.',
        'imageUrl': 'assets/images/products/sen-da-dia-anh-kim.jpg',
        'color': 'Xanh điểm trắng',
        'origin': 'Mexico',
        'care': 'Trung bình',
        'size': '5-8cm',
        'light': 'Ánh sáng vừa',
        'water': '14-21 ngày/lần',
        'basePrice': 150000.0,
      },
      {
        'baseName': 'Cây Sen Đá Nâu',
        'scientific': 'Echeveria Brown',
        'category': 'cat_senda',
        'description': 'Cây Sen Đá Nâu sở hữu màu nâu ấm áp như socola, tạo nên điểm nhấn ấn tượng trong bộ sưu tập sen đá. Lá dày, xếp chặt, đầu lá có màu nâu đậm hơn. Màu sắc đẹp nhất khi được phơi nắng nhẹ buổi sáng.',
        'imageUrl': 'assets/images/products/cay-sen-da-nau.jpg',
        'color': 'Nâu socola',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '6-10cm',
        'light': 'Ánh sáng vừa',
        'water': '7-10 ngày/lần',
        'basePrice': 55000.0,
      },
      // === 11-20: SEN ĐÁ TIẾP THEO ===
      {
        'baseName': 'Sen Đá Tím',
        'scientific': 'Echeveria Purple',
        'category': 'cat_senda',
        'description': 'Sen Đá Tím với sắc tím đầy mềm mại và lãng mạn. Lá hình thoi, xếp chồng lên nhau tạo thành bông hoa đều đặn. Màu tím đặc trưng pha chút hồng ở đầu lá tạo nên vẻ đẹp quyến rũ.',
        'imageUrl': 'assets/images/products/sen-da-tim.jpg',
        'color': 'Tím hồng',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '7-12cm',
        'light': 'Ánh sáng vừa',
        'water': '7-10 ngày/lần',
        'basePrice': 68000.0,
      },
      {
        'baseName': 'Sen Đá Mặt Trời',
        'scientific': 'Echeveria Sunburst',
        'category': 'cat_senda',
        'description': 'Sen Đá Mặt Trời với tên gọi như mặt trời đang tỏa sáng. Lá xếp tỏa ra đều đặn như các tia sáng, màu vàng chanh tươi sáng. Khi đủ ánh sáng, mép lá sẽ chuyển sang màu đỏ như ánh hoàng hôn.',
        'imageUrl': 'assets/images/products/sen-da-mat-troi.jpg',
        'color': 'Vàng chanh',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '8-15cm',
        'light': 'Ánh sáng nhiều',
        'water': '7-10 ngày/lần',
        'basePrice': 78000.0,
      },
      {
        'baseName': 'Sen Đá Móng Rồng',
        'scientific': 'Aloe Juvenda',
        'category': 'cat_senda',
        'description': 'Sen Đá Móng Rồng với lá xếp chồng lên nhau như vảy rồng, màu xanh đậm với viền đỏ hung dữ như móng vuốt của rồng. Cả cây tạo thành hình dáng mạnh mẽ, độc đáo. Mang ý nghĩa bảo vệ và sức mạnh.',
        'imageUrl': 'assets/images/products/sen-da-mong-rong.jpg',
        'color': 'Xanh đỏ',
        'origin': 'Nam Phi',
        'care': 'Dễ',
        'size': '10-15cm',
        'light': 'Ánh sáng vừa',
        'water': '10-14 ngày/lần',
        'basePrice': 72000.0,
      },
      {
        'baseName': 'Sen Đá Thạch Lan',
        'scientific': 'Haworthia Fasciata',
        'category': 'cat_senda',
        'description': 'Sen Đá Thạch Lan thuộc họ Haworthia với lá dựng đứng, màu xanh đậm có các sọc trắng nổi bật như thạch nhũ. Kích thước nhỏ gọn, thích hợp trồng chậu mini. Đặc biệt thích hợp với ánh sáng yếu.',
        'imageUrl': 'assets/images/products/sen-da-thach-lan.jpg',
        'color': 'Xanh sọc trắng',
        'origin': 'Nam Phi',
        'care': 'Dễ',
        'size': '5-8cm',
        'light': 'Ánh sáng yếu',
        'water': '14-21 ngày/lần',
        'basePrice': 62000.0,
      },
      {
        'baseName': 'Sen Đá Hồng Mập',
        'scientific': 'Echeveria Lagos',
        'category': 'cat_senda',
        'description': 'Sen Đá Hồng Mập với thân cây mập mạp, lá tròn đầy đặn như những viên kẹo ngọt. Màu hồng phấn đáng yêu trên nền xanh pastel. Đây là sen đá siêu mini được nhiều người yêu thích.',
        'imageUrl': 'assets/images/products/sen-da-hong-map.jpg',
        'color': 'Hồng phấn',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '3-5cm',
        'light': 'Ánh sáng vừa',
        'water': '10-14 ngày/lần',
        'basePrice': 48000.0,
      },
      {
        'baseName': 'Sen Đá Ngọc Gốc',
        'scientific': 'Sedum Morganianum',
        'category': 'cat_senda',
        'description': 'Sen Đá Ngọc Gốc với thân dây rủ xuống đầy ấn tượng, lá mập mạp xếp chồng lên nhau như những viên ngọc xanh. Thường được trồng trong chậu treo để khoe vẻ đẹp tuyệt vời. Dễ chăm, nhanh phát triển.',
        'imageUrl': 'assets/images/products/sen-da-ngoc-guoc.jpg',
        'color': 'Xanh ngọc',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '20-50cm (dây)',
        'light': 'Ánh sáng vừa',
        'water': '7-10 ngày/lần',
        'basePrice': 58000.0,
      },
      {
        'baseName': 'Sen Thạch Ngọc',
        'scientific': 'Lithops',
        'category': 'cat_senda',
        'description': 'Sen Thạch Ngọc là loại sen đá đặc biệt nhất với hình dáng giống hệt đá sỏi sống. Mỗi cặp lá mọc từ khe giữa, nở hoa đẹp mắt. Có nhiều màu sắc từ xám, nâu đến hồng. Đòi hỏi sự kiên nhẫn trong chăm sóc.',
        'imageUrl': 'assets/images/products/sen-thach-ngoc_1.jpg',
        'color': 'Xám nâu',
        'origin': 'Nam Phi',
        'care': 'Khó',
        'size': '2-4cm',
        'light': 'Ánh sáng nhiều',
        'water': '21-30 ngày/lần',
        'basePrice': 85000.0,
      },
      {
        'baseName': 'Sen Đá Rubby',
        'scientific': 'Echeveria Ruby',
        'category': 'cat_senda',
        'description': 'Sen Đá Rubby với màu đỏ ruby sang trọng từ đầu đến gốc lá. Càng để nắng nhiều, màu đỏ càng đậm và rực rỡ. Đây là sen đá được săn lùng nhiều nhất vì vẻ đẹp quý phái của nó.',
        'imageUrl': 'assets/images/products/sen-da-rubby.jpg',
        'color': 'Đỏ ruby',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '8-12cm',
        'light': 'Ánh sáng nhiều',
        'water': '7-10 ngày/lần',
        'basePrice': 98000.0,
      },
      {
        'baseName': 'Sen Tai Gấu Múp',
        'scientific': 'Kalanchoe Tomentosa',
        'category': 'cat_senda',
        'description': 'Sen Tai Gấu Múp với lá phủ lông mềm mại như nhung, màu xám bạc với viền nâu sẫm. Tên gọi bắt nguồn từ hình dáng lá giống tai gấu. Lông trên lá có tác dụng giữ ẩm và bảo vệ khỏi côn trùng.',
        'imageUrl': 'assets/images/products/sen-tai-gau-mup.jpg',
        'color': 'Xám lông',
        'origin': 'Madagascar',
        'care': 'Dễ',
        'size': '6-10cm',
        'light': 'Ánh sáng vừa',
        'water': '10-14 ngày/lần',
        'basePrice': 52000.0,
      },
      {
        'baseName': 'Sen Đá Kim',
        'scientific': 'Echeveria Metallica',
        'category': 'cat_senda',
        'description': 'Sen Đá Kim với bề mặt lá có ánh kim loại lấp lánh, màu xanh bạc pha chút tím. Hiệu ứng metallic tự nhiên tạo nên vẻ đẹp độc đáo khó tìm thấy ở các loại cây khác. Cực kỳ sang trọng.',
        'imageUrl': 'assets/images/products/sen-da-kim.jpg',
        'color': 'Xanh kim loại',
        'origin': 'Mexico',
        'care': 'Trung bình',
        'size': '8-15cm',
        'light': 'Ánh sáng vừa',
        'water': '10-14 ngày/lần',
        'basePrice': 92000.0,
      },
      // === 21-30: SEN ĐÁ TIẾP THEO ===
      {
        'baseName': 'Sen Đá Xanh',
        'scientific': 'Echeveria Green',
        'category': 'cat_senda',
        'description': 'Sen Đá Xanh thuần khiết với màu xanh tự nhiên như ngọc bích. Lá xếp đều đặn từ tâm ra ngoài tạo thành bông hoa hoàn hảo. Đây là loại sen đá cơ bản nhất nhưng không kém phần đẹp mắt, phù hợp cho người mới trồng.',
        'imageUrl': 'assets/images/products/sen-da-xanh.jpg',
        'color': 'Xanh ngọc',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '8-12cm',
        'light': 'Ánh sáng vừa',
        'water': '7-10 ngày/lần',
        'basePrice': 35000.0,
      },
      {
        'baseName': 'Sen Đá Bắp Cải Tím',
        'scientific': 'Aeonium',
        'category': 'cat_senda',
        'description': 'Sen Đá Bắp Cải Tím với hình dáng giống bắp cải tím, lá xếp lớp lớp tạo thành bông hoa lớn vô cùng ấn tượng. Màu tím đậm ở mép lá chuyển dần sang xanh ở tâm. Cực kỳ nổi bật trong bộ sưu tập.',
        'imageUrl': 'assets/images/products/sen-da-bap-cai-tim.jpg',
        'color': 'Tím xanh',
        'origin': 'Canary Islands',
        'care': 'Dễ',
        'size': '15-30cm',
        'light': 'Ánh sáng nhiều',
        'water': '7-10 ngày/lần',
        'basePrice': 68000.0,
      },
      {
        'baseName': 'Sen Đá Ba Màu',
        'scientific': 'Echeveria Tricolor',
        'category': 'cat_senda',
        'description': 'Sen Đá Ba Màu gây choáng ngợp với sự pha trộn hoàn hảo của ba màu: xanh, hồng và trắng trên cùng một cây. Mỗi lá là một tác phẩm nghệ thuật với dải màu chạy dọc. Đây là sen đá quý hiếm.',
        'imageUrl': 'assets/images/products/sen-da-ba-mau.jpg',
        'color': 'Xanh hồng trắng',
        'origin': 'Mexico',
        'care': 'Trung bình',
        'size': '8-12cm',
        'light': 'Ánh sáng nhiều',
        'water': '7-10 ngày/lần',
        'basePrice': 135000.0,
      },
      {
        'baseName': 'Sen Đá Hồng Phấn',
        'scientific': 'Echeveria Pink',
        'category': 'cat_senda',
        'description': 'Sen Đá Hồng Phấn với sắc hồng nhẹ nhàng như cánh hoa anh đào. Lá mỏng mịn, xếp tầng đều đặn tạo vẻ đẹp nữ tính. Màu hồng đậm hơn ở đầu lá, nhạt dần về gốc. Biểu tượng của tình yêu và sự dịu dàng.',
        'imageUrl': 'assets/images/products/sen-da-hong-phan.jpg',
        'color': 'Hồng nhạt',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '6-10cm',
        'light': 'Ánh sáng vừa',
        'water': '7-10 ngày/lần',
        'basePrice': 58000.0,
      },
      {
        'baseName': 'Sen Đá Thuốc Dược',
        'scientific': 'Aloe Vera',
        'category': 'cat_senda',
        'description': 'Sen Đá Thuốc Dược (Nha Đam) không chỉ đẹp mà còn có nhiều công dụng. Lá mập mạp chứa gel dưỡng ẩm, có thể dùng để trị bỏng nhẹ và dưỡng da. Xanh tươi quanh năm, dễ chăm sóc.',
        'imageUrl': 'assets/images/products/sen-da-thuoc-duoc.jpg',
        'color': 'Xanh đậm',
        'origin': 'Arabian Peninsula',
        'care': 'Dễ',
        'size': '10-20cm',
        'light': 'Ánh sáng nhiều',
        'water': '14-21 ngày/lần',
        'basePrice': 42000.0,
      },
      {
        'baseName': 'Sen Đá Vàng',
        'scientific': 'Echeveria Gold',
        'category': 'cat_senda',
        'description': 'Sen Đá Vàng với màu vàng rực rỡ như ánh mặt trời, mang đến năng lượng tích cực cho không gian sống. Lá xếp thành bông hoa cúc vàng óng ánh. Khi đủ ánh sáng, màu vàng càng thêm rực rỡ.',
        'imageUrl': 'assets/images/products/sen-da-vang.jpg',
        'color': 'Vàng rực',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '8-15cm',
        'light': 'Ánh sáng nhiều',
        'water': '7-10 ngày/lần',
        'basePrice': 62000.0,
      },
      {
        'baseName': 'Sen Đá Dụ',
        'scientific': 'Echeveria Elegans',
        'category': 'cat_senda',
        'description': 'Sen Đá Dụ (Elegans) với tên gọi nói lên tất cả - sự thanh lịch trong từng chi tiết. Lá mỏng mịn, xếp hoàn hảo tạo thành bông hoa trắng xanh như ngọc trai. Đây là sen đá cổ điển được yêu thích nhất.',
        'imageUrl': 'assets/images/products/sen-da-du.jpg',
        'color': 'Xanh trắng',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '10-20cm',
        'light': 'Ánh sáng vừa',
        'water': '7-10 ngày/lần',
        'basePrice': 48000.0,
      },
      {
        'baseName': 'Sen Đá Bông Hồng Đen',
        'scientific': 'Black Rose Succulent',
        'category': 'cat_senda',
        'description': 'Sen Đá Bông Hồng Đen với màu đen huyền bí như đóa hồng đen, tạo nên sự độc đáo và thu hút. Đây là sen đá mang phong cách Gothic, được những người yêu thích sắc màu đặc biệt săn đón.',
        'imageUrl': 'assets/images/products/sen-da-bong-hong-den.jpg',
        'color': 'Đen tím',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '8-12cm',
        'light': 'Ánh sáng vừa',
        'water': '7-10 ngày/lần',
        'basePrice': 88000.0,
      },
      {
        'baseName': 'Sen Đá Hoa Cúc',
        'scientific': 'Sempervivum',
        'category': 'cat_senda',
        'description': 'Sen Đá Hoa Cúc với hình dáng giống hệt đóa cúc đang nở, nhiều lớp lá xếp chồng tạo độ sâu ấn tượng. Màu xanh pha chút đỏ ở đầu lá. Đặc biệt, cây mẹ sẽ nở hoa và tạo cây con trước khi tàn.',
        'imageUrl': 'assets/images/products/sen-da-hoa-cuc.jpg',
        'color': 'Xanh đỏ',
        'origin': 'Europe',
        'care': 'Dễ',
        'size': '5-10cm',
        'light': 'Ánh sáng nhiều',
        'water': '10-14 ngày/lần',
        'basePrice': 38000.0,
      },
      {
        'baseName': 'Sen Đá Gác Nai',
        'scientific': 'Plush Plant',
        'category': 'cat_senda',
        'description': 'Sen Đá Gác Nai với bề mặt lá phủ lông tơ mịn như nhung, màu xanh bạc độc đáo. Lông mềm có tác dụng giảm bốc hơi nước và bảo vệ khỏi côn trùng. Khi chạm vào cảm giác vô cùng thú vị.',
        'imageUrl': 'assets/images/products/sen-da-gac-nai.jpg',
        'color': 'Xanh nhung',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '6-12cm',
        'light': 'Ánh sáng vừa',
        'water': '10-14 ngày/lần',
        'basePrice': 55000.0,
      },
      // === 31-42: SEN ĐÁ CUỐI ===
      {
        'baseName': 'Sen Đá Kim Cương',
        'scientific': 'Echeveria Imbricata',
        'category': 'cat_senda',
        'description': 'Sen Đá Kim Cương là giống sen đá lai phổ biến nhất, với lá xếp chồng tạo hình hoa cúc hoàn hảo. Màu xanh pha chút xanh dương, đầu lá có viền hồng nhạt. Dễ trồng, dễ nhân giống.',
        'imageUrl': 'assets/images/products/sen-da-kim-cuong.jpg',
        'color': 'Xanh ngọc',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '10-20cm',
        'light': 'Ánh sáng vừa',
        'water': '7-10 ngày/lần',
        'basePrice': 45000.0,
      },
      {
        'baseName': 'Sen Đá Phật Bà',
        'scientific': 'Echeveria Buddha',
        'category': 'cat_senda',
        'description': 'Sen Đá Phật Bà với hình dáng đặc trưng xếp chồng tạo thành hình giống như tượng Phật ngồi thiền. Mỗi lớp lá như một tầng phù đế. Đây là sen đá mang ý nghĩa tâm linh sâu sắc.',
        'imageUrl': 'assets/images/products/sen-da-phat-ba.jpg',
        'color': 'Xanh bạc',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '8-15cm',
        'light': 'Ánh sáng vừa',
        'water': '7-10 ngày/lần',
        'basePrice': 72000.0,
      },
      {
        'baseName': 'Sen Đá Lá Thơm',
        'scientific': 'Scented Geranium',
        'category': 'cat_senda',
        'description': 'Sen Đá Lá Thơm không chỉ đẹp mà còn tỏa hương thơm dịu nhẹ khi chạm vào. Lá có các thùy tròn đều đặn, màu xanh pha chút vàng. Hương thơm có thể giúp thư giãn và xua đuổi muỗi.',
        'imageUrl': 'assets/images/products/sen-da-la-thom.jpg',
        'color': 'Xanh vàng',
        'origin': 'South Africa',
        'care': 'Dễ',
        'size': '8-15cm',
        'light': 'Ánh sáng nhiều',
        'water': '7-10 ngày/lần',
        'basePrice': 58000.0,
      },
      {
        'baseName': 'Sen Đá Hăm Ca Mập',
        'scientific': 'Pachyveria',
        'category': 'cat_senda',
        'description': 'Sen Đá Hăm Ca Mập là kết quả lai giữa Echeveria và Pachyphytum, thừa hưởng vẻ đẹp từ cả hai giống. Lá mập mạp, màu xanh bạc pha chút hồng. Dễ chăm, phù hợp cho người mới.',
        'imageUrl': 'assets/images/products/sen-da-ham-ca-map.jpg',
        'color': 'Xanh hồng',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '6-12cm',
        'light': 'Ánh sáng vừa',
        'water': '10-14 ngày/lần',
        'basePrice': 52000.0,
      },
      {
        'baseName': 'Sen Đá Cánh Bướm',
        'scientific': 'Echeveria Peacock',
        'category': 'cat_senda',
        'description': 'Sen Đá Cánh Bướm với lá dẹt mỏng xếp tỏa ra như đôi cánh bướm đang bay. Màu xanh pha chút tím và hồng tạo nên vẻ đẹp mềm mại. Đây là sen đá mang nét đẹp nhẹ nhàng, thanh tao.',
        'imageUrl': 'assets/images/products/sen-da-canh-buom.jpg',
        'color': 'Xanh tím hồng',
        'origin': 'Mexico',
        'care': 'Trung bình',
        'size': '10-18cm',
        'light': 'Ánh sáng vừa',
        'water': '7-10 ngày/lần',
        'basePrice': 82000.0,
      },
      {
        'baseName': 'Sen Đá Viền Đỏ',
        'scientific': 'Echeveria Red Edge',
        'category': 'cat_senda',
        'description': 'Sen Đá Viền Đỏ với đặc điểm nổi bật là viền đỏ chạy dọc mép lá, tạo nên sự tương phản đẹp mắt với nền xanh. Lá xếp đều đặn tạo thành bông hoa cúc. Màu đỏ đậm hơn khi đủ ánh sáng.',
        'imageUrl': 'assets/images/products/sen-da-vien-do.jpg',
        'color': 'Xanh viền đỏ',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '8-15cm',
        'light': 'Ánh sáng nhiều',
        'water': '7-10 ngày/lần',
        'basePrice': 58000.0,
      },
      {
        'baseName': 'Sen Đá Tử Phường',
        'scientific': 'Echeveria Tuxpanensis',
        'category': 'cat_senda',
        'description': 'Sen Đá Tử Phường với tên gọi hoa mỹ mang vẻ đẹp cổ điển Phương Đông. Lá xếp chặt, màu xanh đậm pha chút tím ở gốc. Đầu lá nhọn tạo nên điểm nhấn độc đáo. Mang nét đẹp trầm lắng, cổ điển.',
        'imageUrl': 'assets/images/products/sen-da-tu-phuong.jpg',
        'color': 'Xanh tím',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '8-12cm',
        'light': 'Ánh sáng vừa',
        'water': '7-10 ngày/lần',
        'basePrice': 68000.0,
      },
      {
        'baseName': 'Sen Ngọc Bích',
        'scientific': 'Crassula Ovata',
        'category': 'cat_senda',
        'description': 'Sen Ngọc Bích (Cây Tiền) là loại sen đá phổ biến nhất thế giới với lá hình bầu dục, màu xanh bóng như ngọc. Theo phong thủy, cây mang lại tài lộc và may mắn. Có thể sống hàng chục năm, lớn dần thành cây gỗ nhỏ.',
        'imageUrl': 'assets/images/products/sen-ngoc-bich_1.jpg',
        'color': 'Xanh bóng',
        'origin': 'Nam Phi',
        'care': 'Dễ',
        'size': '20-100cm',
        'light': 'Ánh sáng nhiều',
        'water': '14-21 ngày/lần',
        'basePrice': 38000.0,
      },
      {
        'baseName': 'Sen Đá Giọt Lệ',
        'scientific': 'String of Pearls',
        'category': 'cat_senda',
        'description': 'Sen Đá Giọt Lệ với thân dây mảnh mai, lá hình giọt nước xếp dọc như những giọt lệ ngọc. Thường trồng trong chậu treo, thân cây rủ xuống đẹp mắt. Cực kỳ quyến rũ và được yêu thích.',
        'imageUrl': 'assets/images/products/sen-da-giot-le.jpg',
        'color': 'Xanh ngọc',
        'origin': 'Nam Phi',
        'care': 'Trung bình',
        'size': '30-100cm (dây)',
        'light': 'Ánh sáng vừa',
        'water': '10-14 ngày/lần',
        'basePrice': 75000.0,
      },
      {
        'baseName': 'Sen Đá Trái Tim',
        'scientific': 'Hoya Kerrii',
        'category': 'cat_senda',
        'description': 'Sen Đá Trái Tim với lá hình trái tim đáng yêu, màu xanh bóng bảo. Thường được tặng như quà Valentine. Có thể leo bám hoặc rủ xuống. Khi nở hoa, hương thơm ngọt ngào lan tỏa.',
        'imageUrl': 'assets/images/products/sen-da-trai-tim-1.jpg',
        'color': 'Xanh tim',
        'origin': 'Southeast Asia',
        'care': 'Dễ',
        'size': '10-30cm',
        'light': 'Ánh sáng vừa',
        'water': '10-14 ngày/lần',
        'basePrice': 48000.0,
      },
      {
        'baseName': 'Sen Đá Hồng Sao',
        'scientific': 'Echeveria Shanghai',
        'category': 'cat_senda',
        'description': 'Sen Đá Hồng Sao với màu hồng đặc trưng như cánh hoa sen hồng. Lá xếp tạo thành ngôi sao nhiều cánh, màu hồng đậm ở đầu lá chuyển dần sang xanh. Đẹp nhất khi được phơi nắng nhẹ.',
        'imageUrl': 'assets/images/products/sen-da-hong-sao.jpg',
        'color': 'Hồng đậm',
        'origin': 'Mexico',
        'care': 'Dễ',
        'size': '8-15cm',
        'light': 'Ánh sáng vừa',
        'water': '7-10 ngày/lần',
        'basePrice': 65000.0,
      },
    ];

    final List<Map<String, dynamic>> products = [];
    final List<Map<String, dynamic>> productImages = [];

    for (int i = 0; i < masterProducts.length; i++) {
      final master = masterProducts[i];
      final nowMs = now - (i * 600000);

      final productId = 'prod_${i}_$nowMs';
      products.add({
        'id': productId,
        'category_id': master['category'],
        'name': master['baseName'],
        'scientific_name': master['scientific'],
        'description': master['description'],
        'price': master['basePrice'],
        'sale_price': (i % 5 == 0) ? (master['basePrice'] * 0.85).roundToDouble() : null,
        'stock': 20 + (i * 3) % 31,
        'sku': 'SD${(i + 1).toString().padLeft(3, '0')}',
        'status': 'AVAILABLE',
        'size': master['size'],
        'color': master['color'],
        'origin': master['origin'],
        'care_level': master['care'],
        'light_requirement': master['light'],
        'water_requirement': master['water'],
        'is_bestseller': (i % 7 == 0) ? 1 : 0,
        'is_new': (i < 10) ? 1 : 0,
        'rating': 0.0,
        'review_count': 0,
        'views': 10 + (i * 17) % 100,
        'created_at': nowMs,
        'updated_at': nowMs,
      });

      productImages.add({
        'id': 'img_${i}_$nowMs',
        'product_id': productId,
        'image_url': master['imageUrl'],
        'is_primary': 1,
        'sort_order': 0,
        'created_at': nowMs,
      });
    }

    for (var product in products) {
      await db.insert('products', product, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    for (var img in productImages) {
      await db.insert('product_images', img, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}
