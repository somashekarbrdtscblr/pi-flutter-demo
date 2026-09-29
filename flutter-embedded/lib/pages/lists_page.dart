import 'package:flutter/material.dart';

class ListsPage extends StatelessWidget {
  const ListsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(tabs: [
            Tab(icon: Icon(Icons.swipe), text: 'Dismissible'),
            Tab(icon: Icon(Icons.reorder), text: 'Reorderable'),
            Tab(icon: Icon(Icons.grid_view), text: 'Grid'),
          ]),
          Expanded(
            child: TabBarView(children: [_DismissList(), _ReorderList(), _Grid()]),
          ),
        ],
      ),
    );
  }
}

class _DismissList extends StatefulWidget {
  const _DismissList();

  @override
  State<_DismissList> createState() => _DismissListState();
}

class _DismissListState extends State<_DismissList> {
  final _items = List.generate(15, (i) => 'Order #${2000 + i}');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = _items[i];
        return Dismissible(
          key: ValueKey(item),
          background: Container(
            color: scheme.errorContainer,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            child: const Icon(Icons.delete),
          ),
          secondaryBackground: Container(
            color: scheme.tertiaryContainer,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.archive),
          ),
          onDismissed: (dir) {
            setState(() => _items.removeAt(i));
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text('$item ${dir == DismissDirection.startToEnd ? 'deleted' : 'archived'}'),
                action: SnackBarAction(label: 'UNDO', onPressed: () => setState(() => _items.insert(i, item))),
              ));
          },
          child: ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(item),
            subtitle: const Text('Swipe left or right'),
            trailing: Text('₹ ${(i + 3) * 42}'),
          ),
        );
      },
    );
  }
}

class _ReorderList extends StatefulWidget {
  const _ReorderList();

  @override
  State<_ReorderList> createState() => _ReorderListState();
}

class _ReorderListState extends State<_ReorderList> {
  final _items = ['Rice', 'Dal', 'Oil', 'Sugar', 'Salt', 'Tea', 'Coffee', 'Milk'];

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      buildDefaultDragHandles: true,
      onReorderItem: (from, to) => setState(() => _items.insert(to, _items.removeAt(from))),
      children: [
        for (final item in _items)
          ListTile(key: ValueKey(item), leading: const Icon(Icons.drag_indicator), title: Text(item)),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid();

  static const _icons = [
    Icons.local_grocery_store, Icons.local_cafe, Icons.bakery_dining, Icons.icecream,
    Icons.local_drink, Icons.lunch_dining, Icons.set_meal, Icons.egg, Icons.rice_bowl,
    Icons.cookie, Icons.liquor, Icons.local_pizza,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _icons.length,
      itemBuilder: (context, i) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('Item ${i + 1} added to cart'))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icons[i], size: 40),
              const SizedBox(height: 8),
              Text('Item ${i + 1}'),
            ],
          ),
        ),
      ),
    );
  }
}
