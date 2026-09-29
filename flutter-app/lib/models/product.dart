const productCategories = [
  'Beverages',
  'Snacks',
  'Dairy',
  'Bakery',
  'Household',
];

/// Immutable product row. Edit with [copyWith].
class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.price,
    required this.qty,
    this.active = true,
  });

  final int id;
  final String sku;
  final String name;
  final String category;
  final double price;
  final int qty;
  final bool active;

  double get value => price * qty;
  bool get lowStock => qty < 20;

  Product copyWith({
    String? name,
    String? category,
    double? price,
    int? qty,
    bool? active,
  }) => Product(
    id: id,
    sku: sku,
    name: name ?? this.name,
    category: category ?? this.category,
    price: price ?? this.price,
    qty: qty ?? this.qty,
    active: active ?? this.active,
  );
}
