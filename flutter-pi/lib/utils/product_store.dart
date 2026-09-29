import 'package:flutter/foundation.dart';

const productCategories = [
  'Beverages',
  'Snacks',
  'Dairy',
  'Bakery',
  'Household',
];

class Product {
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.qty,
    this.active = true,
  });

  final int id;
  String name;
  String category;
  double price;
  int qty;
  bool active;

  double get value => price * qty;

  Product copy() => Product(
    id: id,
    name: name,
    category: category,
    price: price,
    qty: qty,
    active: active,
  );
}

/// In-memory product list shared by the dashboard and table pages.
/// Survives page navigation (not app restart).
class ProductStore extends ChangeNotifier {
  ProductStore._();
  static final instance = ProductStore._();

  int _nextId = 1;
  late final List<Product> _items = [
    _make('Masala Chai', 'Beverages', 15, 120),
    _make('Filter Coffee', 'Beverages', 25, 80),
    _make('Potato Chips', 'Snacks', 20, 200),
    _make('Salted Peanuts', 'Snacks', 30, 45),
    _make('Milk 1L', 'Dairy', 56, 60),
    _make('Paneer 200g', 'Dairy', 90, 18),
    _make('Bread Loaf', 'Bakery', 40, 25),
    _make('Butter Cookies', 'Bakery', 60, 5, active: false),
    _make('Dish Soap', 'Household', 99, 30),
  ];

  Product _make(
    String name,
    String cat,
    double price,
    int qty, {
    bool active = true,
  }) => Product(
    id: _nextId++,
    name: name,
    category: cat,
    price: price,
    qty: qty,
    active: active,
  );

  List<Product> get items => List.unmodifiable(_items);

  int get lowStockCount => _items.where((p) => p.qty < 20).length;
  double get inventoryValue => _items.fold(0, (sum, p) => sum + p.value);

  Product add({
    required String name,
    required String category,
    required double price,
    required int qty,
  }) {
    final p = _make(name, category, price, qty);
    _items.add(p);
    notifyListeners();
    return p;
  }

  void update(Product updated) {
    final i = _items.indexWhere((p) => p.id == updated.id);
    if (i != -1) {
      _items[i] = updated;
      notifyListeners();
    }
  }

  /// Returns removed items with their original index, for undo.
  List<(int, Product)> removeWhere(bool Function(Product) test) {
    final removed = <(int, Product)>[];
    for (var i = 0; i < _items.length; i++) {
      if (test(_items[i])) removed.add((i, _items[i]));
    }
    _items.removeWhere(test);
    notifyListeners();
    return removed;
  }

  void restore(List<(int, Product)> removed) {
    for (final (index, p) in removed) {
      _items.insert(index.clamp(0, _items.length), p);
    }
    notifyListeners();
  }
}
