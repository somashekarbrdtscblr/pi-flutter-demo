import 'package:flutter/material.dart';

import '../widgets/validators.dart';

class Product {
  Product(this.sku, this.name, this.category, this.qty, this.price, {this.active = true});
  String sku;
  String name;
  String category;
  int qty;
  double price;
  bool active;
  bool selected = false;
}

const _categories = ['Grocery', 'Dairy', 'Bakery', 'Beverages', 'Snacks'];

class TablePage extends StatefulWidget {
  const TablePage({super.key});

  @override
  State<TablePage> createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  final _rows = <Product>[
    Product('SKU-001', 'Basmati Rice 5kg', 'Grocery', 24, 649),
    Product('SKU-002', 'Toned Milk 1L', 'Dairy', 60, 54),
    Product('SKU-003', 'Brown Bread', 'Bakery', 15, 45),
    Product('SKU-004', 'Masala Tea 250g', 'Beverages', 32, 140),
    Product('SKU-005', 'Potato Chips', 'Snacks', 4, 20, active: false),
    Product('SKU-006', 'Paneer 200g', 'Dairy', 18, 90),
  ];

  // Inline edit state
  final _editKey = GlobalKey<FormState>();
  Product? _editing;
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _editCategory = _categories.first;

  String _query = '';
  int? _sortCol;
  bool _asc = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  List<Product> get _visible => _rows
      .where((p) =>
          _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
          p.sku.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  void _sort<T extends Comparable<Object>>(T Function(Product) key, int col, bool asc) {
    setState(() {
      _rows.sort((a, b) => asc ? key(a).compareTo(key(b)) : key(b).compareTo(key(a)));
      _sortCol = col;
      _asc = asc;
    });
  }

  void _startEdit(Product p) {
    setState(() {
      _editing = p;
      _nameCtrl.text = p.name;
      _qtyCtrl.text = '${p.qty}';
      _priceCtrl.text = p.price.toStringAsFixed(2);
      _editCategory = p.category;
    });
  }

  void _saveEdit() {
    if (!_editKey.currentState!.validate()) return;
    setState(() {
      _editing!
        ..name = _nameCtrl.text.trim()
        ..qty = int.parse(_qtyCtrl.text)
        ..price = double.parse(_priceCtrl.text)
        ..category = _editCategory;
      _editing = null;
    });
    _snack('Row saved');
  }

  void _snack(String msg, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), action: action));
  }

  void _add() {
    final p = Product('SKU-${(_rows.length + 1).toString().padLeft(3, '0')}', '', _categories.first, 0, 0);
    setState(() {
      _rows.insert(0, p);
      _query = '';
    });
    _startEdit(p);
  }

  void _delete(List<Product> items) {
    final backup = List<Product>.of(_rows);
    setState(() {
      _rows.removeWhere(items.contains);
      if (items.contains(_editing)) _editing = null;
    });
    _snack(
      'Deleted ${items.length} row(s)',
      action: SnackBarAction(label: 'UNDO', onPressed: () => setState(() {
        _rows
          ..clear()
          ..addAll(backup);
      })),
    );
  }

  Widget _cellField(TextEditingController c, String? Function(String?) validator,
          {bool number = false, double width = 120}) =>
      SizedBox(
        width: width,
        child: TextFormField(
          controller: c,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          decoration: const InputDecoration(isDense: true, errorMaxLines: 2),
          validator: validator,
          onFieldSubmitted: (_) => _saveEdit(),
        ),
      );

  DataRow _row(Product p) {
    final editing = identical(p, _editing);
    final low = p.qty < 10;
    final scheme = Theme.of(context).colorScheme;
    return DataRow(
      selected: p.selected,
      onSelectChanged: editing ? null : (v) => setState(() => p.selected = v ?? false),
      color: WidgetStateProperty.resolveWith(
          (s) => editing ? scheme.secondaryContainer.withValues(alpha: 0.5) : null),
      cells: [
        DataCell(Text(p.sku)),
        editing
            ? DataCell(_cellField(_nameCtrl, (v) => Validators.required(v, 'Name'), width: 180))
            : DataCell(Text(p.name.isEmpty ? '—' : p.name), showEditIcon: true, onTap: () => _startEdit(p)),
        editing
            ? DataCell(DropdownButton<String>(
                value: _editCategory,
                isDense: true,
                items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(c))],
                onChanged: (v) => setState(() => _editCategory = v!),
              ))
            : DataCell(Text(p.category)),
        editing
            ? DataCell(_cellField(_qtyCtrl, (v) => Validators.number(v, min: 0, max: 9999, field: 'Qty'),
                number: true, width: 80))
            : DataCell(
                Chip(
                  label: Text('${p.qty}'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: low ? scheme.errorContainer : null,
                  avatar: low ? Icon(Icons.warning, size: 16, color: scheme.error) : null,
                ),
                onTap: () => _startEdit(p),
              ),
        editing
            ? DataCell(_cellField(_priceCtrl, (v) => Validators.number(v, min: 0.01, field: 'Price'),
                number: true, width: 100))
            : DataCell(Text('₹ ${p.price.toStringAsFixed(2)}'), onTap: () => _startEdit(p)),
        DataCell(Switch(
          value: p.active,
          onChanged: (v) => setState(() => p.active = v),
        )),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: editing
              ? [
                  IconButton(tooltip: 'Save', icon: const Icon(Icons.check), onPressed: _saveEdit),
                  IconButton(
                    tooltip: 'Cancel',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      if (p.name.isEmpty) _rows.remove(p); // discard unsaved new row
                      _editing = null;
                    }),
                  ),
                ]
              : [
                  IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit), onPressed: () => _startEdit(p)),
                  IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: () => _delete([p])),
                ],
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final selected = _rows.where((p) => p.selected).toList();
    final total = visible.fold<double>(0, (s, p) => s + p.qty * p.price);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _editing == null ? _add : null,
        icon: const Icon(Icons.add),
        label: const Text('Add row'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: SearchBar(
                  hintText: 'Search name or SKU',
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (selected.isNotEmpty)
                FilledButton.tonalIcon(
                  onPressed: () => _delete(selected),
                  icon: const Icon(Icons.delete_sweep),
                  label: Text('Delete ${selected.length} selected'),
                ),
              Text('Tap a cell to edit inline',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          Card.outlined(
            clipBehavior: Clip.antiAlias,
            child: Form(
              key: _editKey,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortColumnIndex: _sortCol,
                  sortAscending: _asc,
                  showCheckboxColumn: true,
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 80,
                  headingRowColor: WidgetStatePropertyAll(
                      Theme.of(context).colorScheme.surfaceContainerHighest),
                  columns: [
                    DataColumn(label: const Text('SKU'), onSort: (i, a) => _sort((p) => p.sku, i, a)),
                    DataColumn(label: const Text('Name'), onSort: (i, a) => _sort((p) => p.name, i, a)),
                    DataColumn(label: const Text('Category'), onSort: (i, a) => _sort((p) => p.category, i, a)),
                    DataColumn(label: const Text('Qty'), numeric: true, onSort: (i, a) => _sort((p) => p.qty, i, a)),
                    DataColumn(label: const Text('Price'), numeric: true, onSort: (i, a) => _sort((p) => p.price, i, a)),
                    const DataColumn(label: Text('Active')),
                    const DataColumn(label: Text('Actions')),
                  ],
                  rows: [for (final p in visible) _row(p)],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Stock value: ₹ ${total.toStringAsFixed(2)}  •  ${visible.length} rows',
                style: Theme.of(context).textTheme.titleSmall),
          ),
        ],
      ),
    );
  }
}
