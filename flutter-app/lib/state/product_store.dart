import 'package:flutter/foundation.dart';

import '../models/product.dart';

/// In-memory product list shared by the dashboard and products pages.
/// Survives page navigation, not app restart.
class ProductStore extends ChangeNotifier {
  ProductStore() {
    _add('Masala Chai', 'Beverages', 15, 120);
    _add('Filter Coffee', 'Beverages', 25, 80);
    _add('Potato Chips', 'Snacks', 20, 200);
    _add('Salted Peanuts', 'Snacks', 30, 45);
    _add('Milk 1L', 'Dairy', 56, 60);
    _add('Paneer 200g', 'Dairy', 90, 18);
    _add('Bread Loaf', 'Bakery', 40, 25);
    _add('Butter Cookies', 'Bakery', 60, 5, active: false);
    _add('Dish Soap', 'Household', 99, 30);
  }

  final _items = <Product>[];
  int _nextId = 1;

  List<Product> get items => List.unmodifiable(_items);
  int get lowStockCount => _items.where((p) => p.lowStock).length;
  double get inventoryValue => _items.fold(0, (sum, p) => sum + p.value);

  Product _add(
    String name,
    String category,
    double price,
    int qty, {
    bool active = true,
  }) {
    final id = _nextId++;
    final p = Product(
      id: id,
      sku: 'SKU-${id.toString().padLeft(4, '0')}',
      name: name,
      category: category,
      price: price,
      qty: qty,
      active: active,
    );
    _items.add(p);
    return p;
  }

  Product add({
    required String name,
    required String category,
    required double price,
    required int qty,
  }) {
    final p = _add(name, category, price, qty);
    notifyListeners();
    return p;
  }

  void update(Product updated) {
    final i = _items.indexWhere((p) => p.id == updated.id);
    if (i == -1) return;
    _items[i] = updated;
    notifyListeners();
  }

  /// Removes matching items and returns them with their original index, for undo.
  List<(int, Product)> removeWhere(bool Function(Product) test) {
    final removed = [
      for (var i = 0; i < _items.length; i++)
        if (test(_items[i])) (i, _items[i]),
    ];
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
