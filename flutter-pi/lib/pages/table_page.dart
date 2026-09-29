import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/product_store.dart';
import '../utils/validators.dart';
import '../widgets/section.dart';

enum _Field { name, price, qty }

enum _ViewMode { table, cards }

/// Editable table: tap a Name/Price/Qty cell to edit inline (Enter = save,
/// Esc = cancel), change category via dropdown, toggle active, sort columns,
/// multi-select + bulk delete with undo, add/edit rows via dialog form.
class TablePage extends StatefulWidget {
  const TablePage({super.key});

  @override
  State<TablePage> createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  final _store = ProductStore.instance;
  final _selected = <int>{};
  final _search = TextEditingController();
  int _sortColumn = 0;
  bool _sortAsc = true;
  _ViewMode _mode = _ViewMode.table;

  // Inline edit state.
  (int, _Field)? _editing;
  final _cellController = TextEditingController();
  final _cellFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _search.dispose();
    _cellController.dispose();
    super.dispose();
  }

  List<Product> get _rows {
    final q = _search.text.trim().toLowerCase();
    final rows = _store.items
        .where(
          (p) =>
              q.isEmpty ||
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q),
        )
        .toList();
    int cmp(Product a, Product b) => switch (_sortColumn) {
      0 => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      1 => a.category.compareTo(b.category),
      2 => a.price.compareTo(b.price),
      3 => a.qty.compareTo(b.qty),
      _ => a.value.compareTo(b.value),
    };
    rows.sort((a, b) => _sortAsc ? cmp(a, b) : cmp(b, a));
    return rows;
  }

  void _sort(int column, bool asc) => setState(() {
    _sortColumn = column;
    _sortAsc = asc;
  });

  void _startEdit(Product p, _Field field) {
    setState(() {
      _editing = (p.id, field);
      _cellController.text = switch (field) {
        _Field.name => p.name,
        _Field.price => p.price.toStringAsFixed(2),
        _Field.qty => '${p.qty}',
      };
    });
  }

  void _commitEdit(Product p) {
    if (!_cellFormKey.currentState!.validate()) return;
    final field = _editing!.$2;
    final v = _cellController.text.trim();
    final updated = p.copy();
    switch (field) {
      case _Field.name:
        updated.name = v;
      case _Field.price:
        updated.price = double.parse(v);
      case _Field.qty:
        updated.qty = int.parse(v);
    }
    _store.update(updated);
    setState(() => _editing = null);
  }

  void _cancelEdit() => setState(() => _editing = null);

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

  DataCell _editableCell(
    Product p,
    _Field field,
    String display, {
    double width = 120,
  }) {
    final editing = _editing == (p.id, field);
    if (!editing) {
      return DataCell(
        Text(display),
        showEditIcon: true,
        onTap: () => _startEdit(p, field),
      );
    }
    final numeric = field != _Field.name;
    return DataCell(
      SizedBox(
        width: width,
        child: Form(
          key: _cellFormKey,
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): _cancelEdit,
            },
            child: TextFormField(
              controller: _cellController,
              autofocus: true,
              keyboardType: numeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              inputFormatters: numeric
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
                  : null,
              validator: _validatorFor(field),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                errorStyle: const TextStyle(fontSize: 10, height: 0.8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                suffixIcon: IconButton(
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Save',
                  icon: const Icon(Icons.check),
                  onPressed: () => _commitEdit(p),
                ),
              ),
              onFieldSubmitted: (_) => _commitEdit(p),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openRowDialog([Product? existing]) async {
    final result = await showDialog<Product>(
      context: context,
      builder: (_) => _ProductDialog(product: existing),
    );
    if (result == null || !mounted) return;
    if (existing == null) {
      _store.add(
        name: result.name,
        category: result.category,
        price: result.price,
        qty: result.qty,
      );
      showSnack(context, 'Added "${result.name}"');
    } else {
      _store.update(result);
      showSnack(context, 'Updated "${result.name}"');
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
    final removed = _store.removeWhere((p) => ids.contains(p.id));
    setState(() => _selected.removeAll(ids));
    showSnack(
      context,
      'Deleted ${removed.length} item(s)',
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () => _store.restore(removed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final rows = _rows;
        return PageBody(
          children: [
            _toolbar(context),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No products match your search.')),
                ),
              )
            else if (_mode == _ViewMode.table)
              _table(context, rows)
            else
              _cards(context, rows),
            const SizedBox(height: 12),
            _totals(context),
          ],
        );
      },
    );
  }

  Widget _toolbar(BuildContext context) {
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
              hintText: 'Search name or category',
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
          onPressed: () => _openRowDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Add row'),
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

  Widget _table(BuildContext context, List<Product> rows) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: _sortColumn,
          sortAscending: _sortAsc,
          showCheckboxColumn: true,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 72,
          onSelectAll: (all) => setState(() {
            all == true
                ? _selected.addAll(rows.map((p) => p.id))
                : _selected.clear();
          }),
          columns: [
            DataColumn(label: const Text('Name'), onSort: _sort),
            DataColumn(label: const Text('Category'), onSort: _sort),
            DataColumn(
              label: const Text('Price ₹'),
              numeric: true,
              onSort: _sort,
            ),
            DataColumn(label: const Text('Qty'), numeric: true, onSort: _sort),
            DataColumn(
              label: const Text('Value ₹'),
              numeric: true,
              onSort: _sort,
            ),
            const DataColumn(label: Text('Active')),
            const DataColumn(label: Text('Actions')),
          ],
          rows: [
            for (final p in rows)
              DataRow(
                selected: _selected.contains(p.id),
                onSelectChanged: (v) => setState(
                  () =>
                      v == true ? _selected.add(p.id) : _selected.remove(p.id),
                ),
                cells: [
                  _editableCell(p, _Field.name, p.name, width: 180),
                  DataCell(
                    DropdownButton<String>(
                      value: p.category,
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final c in productCategories)
                          DropdownMenuItem(value: c, child: Text(c)),
                      ],
                      onChanged: (c) {
                        if (c == null) return;
                        _store.update(p.copy()..category = c);
                      },
                    ),
                  ),
                  _editableCell(p, _Field.price, p.price.toStringAsFixed(2)),
                  _editableCell(p, _Field.qty, '${p.qty}', width: 100),
                  DataCell(Text(p.value.toStringAsFixed(2))),
                  DataCell(
                    Switch(
                      value: p.active,
                      onChanged: (v) => _store.update(p.copy()..active = v),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _openRowDialog(p),
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
          ],
        ),
      ),
    );
  }

  Widget _cards(BuildContext context, List<Product> rows) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final p in rows)
          SizedBox(
            width: 250,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openRowDialog(p),
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
                          if (p.qty < 20) const Badge(label: Text('Low')),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(p.category),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(height: 8),
                      Text('₹${p.price.toStringAsFixed(2)} × ${p.qty}'),
                      Text(
                        'Value ₹${p.value.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Row(
                        children: [
                          Text(p.active ? 'Active' : 'Inactive'),
                          const Spacer(),
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
            ),
          ),
      ],
    );
  }

  Widget _totals(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '${_store.items.length} products · Inventory value ₹${_store.inventoryValue.toStringAsFixed(2)}'
      '  —  Tip: tap a cell with ✎ to edit inline. Enter saves, Esc cancels.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Add / edit product form dialog with validation.
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
    Navigator.pop(
      context,
      Product(
        id: widget.product?.id ?? -1,
        name: _name.text.trim(),
        category: _category!,
        price: double.parse(_price.text),
        qty: int.parse(_qty.text),
        active: widget.product?.active ?? true,
      ),
    );
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
