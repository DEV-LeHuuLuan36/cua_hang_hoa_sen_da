import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cua_hang_hoa_sen_da/database/contracts/order_contract.dart';
import 'package:cua_hang_hoa_sen_da/database/contracts/product_contract.dart';
import 'package:cua_hang_hoa_sen_da/database/daos/order_dao.dart';
import 'package:cua_hang_hoa_sen_da/database/database_helper.dart';
import 'package:cua_hang_hoa_sen_da/database/repositories/order_repository.dart';

void main() {
  late Database db;
  late OrderRepository repository;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    db = await DatabaseHelper.instance.database;
    repository = OrderRepository(orderDao: OrderDao());
  });

  setUp(() async {
    await db.delete('order_items');
    await db.delete('orders');
    await db.delete('cart_items');
    await db.delete('cart');
    await db.delete('products');
    await db.delete('addresses');
    await db.delete('users');
  });

  Future<void> seedBaseData() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('users', {
      'id': 'u1',
      'username': 'customer_1',
      'password': 'hashed_password',
      'full_name': 'Test User',
      'email': 'test@example.com',
      'phone': '0123456789',
      'role': 'CUSTOMER',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('addresses', {
      'id': 'a1',
      'user_id': 'u1',
      'full_name': 'Test User',
      'phone': '0123456789',
      'address_line': '123 Test Street',
      'city': 'HCM',
      'district': 'District 1',
      'ward': 'Ward 1',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('cart', {
      'id': 'c1',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now,
    });
  }

  group('OrderRepository.createOrder', () {
    test('creates order successfully when stock is sufficient', () async {
      await seedBaseData();
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert('products', {
        'id': 'p1',
        'category_id': 'cat_1',
        'name': 'Sen Da A',
        'price': 100000.0,
        ProductContract.colQuantity: 10,
        'created_at': now,
        'updated_at': now,
      });

      await db.insert('cart_items', {
        'id': 'ci1',
        'cart_id': 'c1',
        'product_id': 'p1',
        'quantity': 3,
        'added_at': now,
      });

      final result = await repository.createOrder(
        {
          'id': 'o1',
          'order_number': 'ORD-001',
          'user_id': 'u1',
          'address_id': 'a1',
          'subtotal': 300000.0,
          'shipping_fee': 0.0,
          'discount': 0.0,
          'total': 300000.0,
          'payment_method': 'COD',
          'created_at': now,
          'updated_at': now,
        },
        [
          {
            'id': 'oi1',
            'order_id': 'o1',
            OrderItemContract.colProductId: 'p1',
            'product_name': 'Sen Da A',
            OrderItemContract.colQuantity: 3,
            'price': 100000.0,
            'total': 300000.0,
          }
        ],
        'c1',
      );

      final orders = await db.query('orders', where: 'id = ?', whereArgs: ['o1']);
      final orderItems = await db.query('order_items', where: 'order_id = ?', whereArgs: ['o1']);
      final cartItems = await db.query('cart_items', where: 'cart_id = ?', whereArgs: ['c1']);
      final products = await db.query('products', where: 'id = ?', whereArgs: ['p1']);

      expect(result, isTrue);
      expect(orders.length, 1);
      expect(orderItems.length, 1);
      expect(cartItems, isEmpty);
      expect(products.first[ProductContract.colQuantity], 7);
    });

    test('rolls back whole transaction when one product is out of stock', () async {
      await seedBaseData();
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert('products', {
        'id': 'p1',
        'category_id': 'cat_1',
        'name': 'Sen Da A',
        'price': 100000.0,
        ProductContract.colQuantity: 10,
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('products', {
        'id': 'p2',
        'category_id': 'cat_1',
        'name': 'Sen Da B',
        'price': 50000.0,
        ProductContract.colQuantity: 1,
        'created_at': now,
        'updated_at': now,
      });

      await db.insert('cart_items', {
        'id': 'ci1',
        'cart_id': 'c1',
        'product_id': 'p1',
        'quantity': 2,
        'added_at': now,
      });
      await db.insert('cart_items', {
        'id': 'ci2',
        'cart_id': 'c1',
        'product_id': 'p2',
        'quantity': 5,
        'added_at': now,
      });

      final result = await repository.createOrder(
        {
          'id': 'o2',
          'order_number': 'ORD-002',
          'user_id': 'u1',
          'address_id': 'a1',
          'subtotal': 450000.0,
          'shipping_fee': 0.0,
          'discount': 0.0,
          'total': 450000.0,
          'payment_method': 'COD',
          'created_at': now,
          'updated_at': now,
        },
        [
          {
            'id': 'oi2',
            'order_id': 'o2',
            OrderItemContract.colProductId: 'p1',
            'product_name': 'Sen Da A',
            OrderItemContract.colQuantity: 2,
            'price': 100000.0,
            'total': 200000.0,
          },
          {
            'id': 'oi3',
            'order_id': 'o2',
            OrderItemContract.colProductId: 'p2',
            'product_name': 'Sen Da B',
            OrderItemContract.colQuantity: 5,
            'price': 50000.0,
            'total': 250000.0,
          }
        ],
        'c1',
      );

      final orders = await db.query('orders', where: 'id = ?', whereArgs: ['o2']);
      final orderItems = await db.query('order_items', where: 'order_id = ?', whereArgs: ['o2']);
      final cartItems = await db.query('cart_items', where: 'cart_id = ?', whereArgs: ['c1']);
      final p1 = await db.query('products', where: 'id = ?', whereArgs: ['p1']);
      final p2 = await db.query('products', where: 'id = ?', whereArgs: ['p2']);

      expect(result, isFalse);
      expect(orders, isEmpty);
      expect(orderItems, isEmpty);
      expect(cartItems.length, 2);
      expect(p1.first[ProductContract.colQuantity], 10);
      expect(p2.first[ProductContract.colQuantity], 1);
    });

    test('rolls back when quantity is null (NOT NULL constraint)', () async {
      await seedBaseData();
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert('products', {
        'id': 'p1',
        'category_id': 'cat_1',
        'name': 'Sen Da A',
        'price': 100000.0,
        ProductContract.colQuantity: 10,
        'created_at': now,
        'updated_at': now,
      });

      await db.insert('products', {
        'id': 'p2',
        'category_id': 'cat_1',
        'name': 'Sen Da B',
        'price': 80000.0,
        ProductContract.colQuantity: 9,
        'created_at': now,
        'updated_at': now,
      });

      await db.insert('cart_items', {
        'id': 'ci1',
        'cart_id': 'c1',
        'product_id': 'p1',
        'quantity': 2,
        'added_at': now,
      });
      await db.insert('cart_items', {
        'id': 'ci2',
        'cart_id': 'c1',
        'product_id': 'p2',
        'quantity': 1,
        'added_at': now,
      });

      final result = await repository.createOrder(
        {
          'id': 'o3',
          'order_number': 'ORD-003',
          'user_id': 'u1',
          'address_id': 'a1',
          'subtotal': 330000.0,
          'shipping_fee': 0.0,
          'discount': 0.0,
          'total': 330000.0,
          'payment_method': 'COD',
          'created_at': now,
          'updated_at': now,
        },
        [
          {
            'id': 'oi4',
            'order_id': 'o3',
            OrderItemContract.colProductId: 'p1',
            'product_name': 'Sen Da A',
            OrderItemContract.colQuantity: 2,
            'price': 100000.0,
            'total': 200000.0,
          },
          {
            'id': 'oi5',
            'order_id': 'o3',
            OrderItemContract.colProductId: 'p2',
            'product_name': 'Sen Da B',
            OrderItemContract.colQuantity: null,
            'price': 80000.0,
            'total': 80000.0,
          },
        ],
        'c1',
      );

      final orders = await db.query('orders', where: 'id = ?', whereArgs: ['o3']);
      final orderItems = await db.query('order_items', where: 'order_id = ?', whereArgs: ['o3']);
      final cartItems = await db.query('cart_items', where: 'cart_id = ?', whereArgs: ['c1']);
      final p1 = await db.query('products', where: 'id = ?', whereArgs: ['p1']);
      final p2 = await db.query('products', where: 'id = ?', whereArgs: ['p2']);

      expect(result, isFalse);
      expect(orders, isEmpty);
      expect(orderItems, isEmpty);
      expect(cartItems.length, 2);
      expect(p1.first[ProductContract.colQuantity], 10);
      expect(p2.first[ProductContract.colQuantity], 9);
    });

    test('skips stock deduction when quantity is <= 0', () async {
      await seedBaseData();
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert('products', {
        'id': 'p1',
        'category_id': 'cat_1',
        'name': 'Sen Da A',
        'price': 100000.0,
        ProductContract.colQuantity: 10,
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('products', {
        'id': 'p3',
        'category_id': 'cat_1',
        'name': 'Sen Da C',
        'price': 50000.0,
        ProductContract.colQuantity: 7,
        'created_at': now,
        'updated_at': now,
      });

      await db.insert('cart_items', {
        'id': 'ci1',
        'cart_id': 'c1',
        'product_id': 'p1',
        'quantity': 2,
        'added_at': now,
      });
      await db.insert('cart_items', {
        'id': 'ci3',
        'cart_id': 'c1',
        'product_id': 'p3',
        'quantity': 1,
        'added_at': now,
      });

      final result = await repository.createOrder(
        {
          'id': 'o4',
          'order_number': 'ORD-004',
          'user_id': 'u1',
          'address_id': 'a1',
          'subtotal': 250000.0,
          'shipping_fee': 0.0,
          'discount': 0.0,
          'total': 250000.0,
          'payment_method': 'COD',
          'created_at': now,
          'updated_at': now,
        },
        [
          {
            'id': 'oi7',
            'order_id': 'o4',
            OrderItemContract.colProductId: 'p1',
            'product_name': 'Sen Da A',
            OrderItemContract.colQuantity: 2,
            'price': 100000.0,
            'total': 200000.0,
          },
          {
            'id': 'oi8',
            'order_id': 'o4',
            OrderItemContract.colProductId: 'p3',
            'product_name': 'Sen Da C',
            OrderItemContract.colQuantity: 0,
            'price': 50000.0,
            'total': 50000.0,
          },
        ],
        'c1',
      );

      final orders = await db.query('orders', where: 'id = ?', whereArgs: ['o4']);
      final orderItems = await db.query('order_items', where: 'order_id = ?', whereArgs: ['o4']);
      final cartItems = await db.query('cart_items', where: 'cart_id = ?', whereArgs: ['c1']);
      final p1 = await db.query('products', where: 'id = ?', whereArgs: ['p1']);
      final p3 = await db.query('products', where: 'id = ?', whereArgs: ['p3']);

      expect(result, isTrue);
      expect(orders.length, 1);
      expect(orderItems.length, 2);
      expect(cartItems, isEmpty);
      expect(p1.first[ProductContract.colQuantity], 8);
      expect(p3.first[ProductContract.colQuantity], 7);
    });
  });
}
