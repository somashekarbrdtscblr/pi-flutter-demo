import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/product_store.dart';
import '../utils/validators.dart';
import '../widgets/section.dart';

enum _Col { sku, name, category, price, qty, value }

enum _Field { name, price, qty }

enum _ViewMode { table, cards }

typedef _ProductInput = ({String name, String category, double price, int qty});

// Column widths. Name takes the remaining space (at least _nameMinWidth).
const _checkW = 56.0, _skuW = 100.0, _categoryW = 150.0, _priceW = 110.0;
const _qtyW = 100.0, _valueW = 110.0, _activeW = 80.0, _actionsW = 104.0;
const _nameMinWidth = 180.0;
const _minTableWidth =
    _checkW +
    _skuW +
    _nameMinWidth +
    _categoryW +
    _priceW +
    _qtyW +
    _valueW +
    _activeW +
    _actionsW;
const _rowHeight = 64.0;

/// Editable product table. Rows are built lazily (ListView.builder), so only
/// visible rows cost CPU/RAM — important on the Pi with large lists.
///
/// Tap a Name/Price/Qty cell to edit inline (Enter saves, Esc cancels), change
/// category via dropdown, toggle active, sort by header, multi-select + bulk
/// delete with undo, add/edit rows via dialog.
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _selected = <int>{};
  final _search = TextEditingController();
  _Col _sortCol = _Col.name;
  bool _sortAsc = true;
  _ViewMode _mode = _ViewMode.table;

  (int, _Field)? _editing;
  final _cellController = TextEditingController();
  final _cellFormKey = GlobalKey<FormState>();

  ProductStore get _store => context.read<ProductStore>();

  @override
  void dispose() {
    _search.dispose();
    _cellController.dispose();
    super.dispose();
  }

  List<Product> _visibleRows(List<Product> items) {
    final q = _search.text.trim().toLowerCase();
    final rows = [
      for (final p in items)
        if (q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
          p,
    ];
    int cmp(Product a, Product b) => switch (_sortCol) {
      _Col.sku => a.sku.compareTo(b.sku),
      _Col.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      _Col.category => a.category.compareTo(b.category),
      _Col.price => a.price.compareTo(b.price),
      _Col.qty => a.qty.compareTo(b.qty),
      _Col.value => a.value.compareTo(b.value),
    };
    rows.sort((a, b) => _sortAsc ? cmp(a, b) : cmp(b, a));
    return rows;
  }

  void _sort(_Col col) => setState(() {
    _sortAsc = _sortCol == col ? !_sortAsc : true;
    _sortCol = col;
  });

  // ---- Inline editing -------------------------------------------------------

  void _startEdit(Product p, _Field field) => setState(() {
    _editing = (p.id, field);
    _cellController.text = switch (field) {
      _Field.name => p.name,
      _Field.price => p.price.toStringAsFixed(2),
      _Field.qty => '${p.qty}',
    };
  });

  void _cancelEdit() => setState(() => _editing = null);

  void _commitEdit(Product p) {
    final form = _cellFormKey.currentState;
    if (form == null) return _cancelEdit();
    if (!form.validate()) return;
    final v = _cellController.text.trim();
    _store.update(switch (_editing!.$2) {
      _Field.name => p.copyWith(name: v),
      _Field.price => p.copyWith(price: double.parse(v)),
      _Field.qty => p.copyWith(qty: int.parse(v)),
    });
    setState(() => _editing = null);
  }

  FormFieldValidator<String> _validatorFor(_Field f) => switch (f) {
    _Field.name => Validators.combine([
      Validators.required('Name'),
      Validators.minLength(2, 'Name'),
    ]),
    _Field.price => Validators.numberRange(0.01, 100000, 'Price'),
    _Field.qty =>
      (v) => int.tryParse(v ?? '') == null
          ? 'Whole number'
          : Validators.numberRange(0, 9999, 'Qty')(v),
  };

  // ---- Add / edit / delete --------------------------------------------------

  Future<void> _openDialog([Product? existing]) async {
    final input = await showDialog<_ProductInput>(
      context: context,
      builder: (_) => _ProductDialog(product: existing),
    );
    if (input == null || !mounted) return;
    if (existing == null) {
      _store.add(
        name: input.name,
        category: input.category,
        price: input.price,
        qty: input.qty,
      );
      showSnack(context, 'Added "${input.name}"');
    } else {
      _store.update(
        existing.copyWith(
          name: input.name,
          category: input.category,
          price: input.price,
          qty: input.qty,
        ),
      );
      showSnack(context, 'Updated "${input.name}"');
    }
  }

  Future<void> _delete(Set<int> ids) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text('Delete ${ids.length} item${ids.length == 1 ? '' : 's'}?'),
        content: const Text('You can undo from the snackbar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final store = _store;
    final removed = store.removeWhere((p) => ids.contains(p.id));
    setState(() => _selected.removeAll(ids));
    showSnack(
      context,
      'Deleted ${removed.length} item(s)',
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () => store.restore(removed),
      ),
    );
  }

  // ---- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();
    final rows = _visibleRows(store.items);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _toolbar(),
          const SizedBox(height: 12),
          Expanded(
            child: rows.isEmpty
                ? const Card(
                    child: Center(
                      child: Text('No products match your search.'),
                    ),
                  )
                : _mode == _ViewMode.table
                ? _table(rows)
                : _cards(rows),
          ),
          const SizedBox(height: 8),
          Text(
            '${store.items.length} products · Inventory value ₹${store.inventoryValue.toStringAsFixed(2)}'
            '  —  Tap a cell with ✎ to edit. Enter saves, Esc cancels.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search name, SKU or category',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(_search.clear),
                    ),
            ),
          ),
        ),
        SegmentedButton<_ViewMode>(
          segments: const [
            ButtonSegment(
              value: _ViewMode.table,
              icon: Icon(Icons.table_rows),
              label: Text('Table'),
            ),
            ButtonSegment(
              value: _ViewMode.cards,
              icon: Icon(Icons.grid_view),
              label: Text('Cards'),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        FilledButton.icon(
          onPressed: _openDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add product'),
        ),
        if (_selected.isNotEmpty)
          FilledButton.tonalIcon(
            onPressed: () => _delete({..._selected}),
            icon: const Icon(Icons.delete_outline),
            label: Text('Delete (${_selected.length})'),
          ),
      ],
    );
  }

  Widget _table(List<Product> rows) {
    final ids = rows.map((p) => p.id).toSet();
    final selectedVisible = _selected.intersection(ids).length;
    final allState = selectedVisible == 0
        ? false
        : (selectedVisible == ids.length ? true : null);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(constraints.maxWidth, _minTableWidth),
            child: Column(
              children: [
                _HeaderRow(
                  sortCol: _sortCol,
                  sortAsc: _sortAsc,
                  onSort: _sort,
                  allSelected: allState,
                  onSelectAll: (all) => setState(
                    () =>
                        all ? _selected.addAll(ids) : _selected.removeAll(ids),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: rows.length,
                    itemExtent: _rowHeight,
                    itemBuilder: (context, i) => _row(rows[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(Product p) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selected.contains(p.id);
    return Container(
      color: selected ? scheme.primaryContainer.withValues(alpha: 0.4) : null,
      child: Row(
        children: [
          SizedBox(
            width: _checkW,
            child: Checkbox(
              value: selected,
              onChanged: (v) => setState(
                () => v == true ? _selected.add(p.id) : _selected.remove(p.id),
              ),
            ),
          ),
          _cell(_skuW, Text(p.sku)),
          Expanded(child: _editableCell(p, _Field.name, p.name)),
          _cell(
            _categoryW,
            DropdownButton<String>(
              value: p.category,
              isDense: true,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                for (final c in productCategories)
                  DropdownMenuItem(
                    value: c,
                    child: Text(c, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (c) {
                if (c != null) _store.update(p.copyWith(category: c));
              },
            ),
          ),
          SizedBox(
            width: _priceW,
            child: _editableCell(p, _Field.price, p.price.toStringAsFixed(2)),
          ),
          SizedBox(
            width: _qtyW,
            child: _editableCell(p, _Field.qty, '${p.qty}', warn: p.lowStock),
          ),
          _cell(_valueW, Text(p.value.toStringAsFixed(2)), numeric: true),
          _cell(
            _activeW,
            Switch(
              value: p.active,
              onChanged: (v) => _store.update(p.copyWith(active: v)),
            ),
          ),
          SizedBox(
            width: _actionsW,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openDialog(p),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete({p.id}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(double width, Widget child, {bool numeric = false}) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Align(
        alignment: numeric ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
    ),
  );

  Widget _editableCell(
    Product p,
    _Field field,
    String display, {
    bool warn = false,
  }) {
    final numeric = field != _Field.name;
    if (_editing != (p.id, field)) {
      final scheme = Theme.of(context).colorScheme;
      return InkWell(
        onTap: () => _startEdit(p, field),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: numeric
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  display,
                  overflow: TextOverflow.ellipsis,
                  style: warn
                      ? TextStyle(
                          color: scheme.error,
                          fontWeight: FontWeight.w600,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 14, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Form(
        key: _cellFormKey,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): _cancelEdit,
          },
          child: TextFormField(
            controller: _cellController,
            autofocus: true,
            textAlign: numeric ? TextAlign.end : TextAlign.start,
            keyboardType: numeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: numeric
                ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
                : null,
            validator: _validatorFor(field),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              isDense: true,
              errorStyle: TextStyle(fontSize: 10, height: 0.8),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onFieldSubmitted: (_) => _commitEdit(p),
            onTapOutside: (_) => _commitEdit(p),
          ),
        ),
      ),
    );
  }

  Widget _cards(List<Product> rows) {
    final theme = Theme.of(context);
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 180,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final p = rows[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openDialog(p),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (p.lowStock) const Badge(label: Text('Low')),
                    ],
                  ),
                  Text(p.sku, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(p.category),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '₹${p.price.toStringAsFixed(2)} × ${p.qty}',
                        ),
                      ),
                      Text(
                        p.active ? 'Active' : 'Inactive',
                        style: theme.textTheme.bodySmall,
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete({p.id}),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.sortCol,
    required this.sortAsc,
    required this.onSort,
    required this.allSelected,
    required this.onSelectAll,
  });

  final _Col sortCol;
  final bool sortAsc;
  final ValueChanged<_Col> onSort;
  final bool? allSelected;
  final ValueChanged<bool> onSelectAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget header(String label, {_Col? col, bool numeric = false}) {
      final active = col != null && col == sortCol;
      final text = Row(
        mainAxisAlignment: numeric
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ),
          if (active)
            Icon(sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
        ],
      );
      return col == null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: text,
            )
          : InkWell(
              onTap: () => onSort(col),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 16,
                ),
                child: text,
              ),
            );
    }

    return Container(
      height: 52,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          SizedBox(
            width: _checkW,
            child: Checkbox(
              tristate: true,
              value: allSelected,
              onChanged: (_) => onSelectAll(allSelected != true),
            ),
          ),
          SizedBox(
            width: _skuW,
            child: header('SKU', col: _Col.sku),
          ),
          Expanded(child: header('Name', col: _Col.name)),
          SizedBox(
            width: _categoryW,
            child: header('Category', col: _Col.category),
          ),
          SizedBox(
            width: _priceW,
            child: header('Price ₹', col: _Col.price, numeric: true),
          ),
          SizedBox(
            width: _qtyW,
            child: header('Qty', col: _Col.qty, numeric: true),
          ),
          SizedBox(
            width: _valueW,
            child: header('Value ₹', col: _Col.value, numeric: true),
          ),
          SizedBox(width: _activeW, child: header('Active')),
          SizedBox(width: _actionsW, child: header('Actions')),
        ],
      ),
    );
  }
}

/// Add / edit product form with validation. Returns the entered values.
class _ProductDialog extends StatefulWidget {
  const _ProductDialog({this.product});

  final Product? product;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _price = TextEditingController(
    text: widget.product?.price.toStringAsFixed(2),
  );
  late final _qty = TextEditingController(text: widget.product?.qty.toString());
  late String? _category = widget.product?.category;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final _ProductInput input = (
      name: _name.text.trim(),
      category: _category!,
      price: double.parse(_price.text),
      qty: int.parse(_qty.text),
    );
    Navigator.pop(context, input);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.product == null;
    return AlertDialog(
      title: Text(isNew ? 'Add product' : 'Edit product'),
      scrollable: true,
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: Validators.combine([
                  Validators.required('Name'),
                  Validators.minLength(2, 'Name'),
                ]),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in productCategories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => _category = v,
                validator: (v) => v == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: '₹ ',
                      ),
                      validator: Validators.numberRange(0.01, 100000, 'Price'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _qty,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Qty'),
                      validator: Validators.numberRange(0, 9999, 'Qty'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: Text(isNew ? 'Add' : 'Save')),
      ],
    );
  }
}
