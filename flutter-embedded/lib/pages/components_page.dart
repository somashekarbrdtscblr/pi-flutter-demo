import 'package:flutter/material.dart';

import '../widgets/section.dart';

class ComponentsPage extends StatefulWidget {
  const ComponentsPage({super.key});

  @override
  State<ComponentsPage> createState() => _ComponentsPageState();
}

class _ComponentsPageState extends State<ComponentsPage> {
  int _step = 0;
  bool _fav = false;
  int _navIndex = 0;
  final _chips = ['Rice', 'Milk', 'Bread', 'Tea'];
  String _choice = 'Small';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const gap = SizedBox(height: 12);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Section(title: 'Buttons', children: [
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
            FilledButton(onPressed: () {}, child: const Text('Filled')),
            FilledButton.tonal(onPressed: () {}, child: const Text('Tonal')),
            OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
            TextButton(onPressed: () {}, child: const Text('Text')),
            const FilledButton(onPressed: null, child: Text('Disabled')),
            IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
            IconButton.filled(onPressed: () {}, icon: const Icon(Icons.add)),
            IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.add)),
            IconButton.outlined(onPressed: () {}, icon: const Icon(Icons.add)),
            IconButton(
              isSelected: _fav,
              onPressed: () => setState(() => _fav = !_fav),
              icon: const Icon(Icons.favorite_border),
              selectedIcon: const Icon(Icons.favorite, color: Colors.red),
            ),
          ]),
          gap,
          Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            FloatingActionButton.small(heroTag: 'f1', onPressed: () {}, child: const Icon(Icons.add)),
            FloatingActionButton(heroTag: 'f2', onPressed: () {}, child: const Icon(Icons.add)),
            FloatingActionButton.extended(
                heroTag: 'f3', onPressed: () {}, icon: const Icon(Icons.shopping_cart), label: const Text('Checkout')),
            ToggleButtons(
              isSelected: const [true, false, false],
              onPressed: (_) {},
              children: const [Icon(Icons.format_bold), Icon(Icons.format_italic), Icon(Icons.format_underline)],
            ),
          ]),
        ]),
        Section(title: 'Chips & badges', children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            const Chip(avatar: Icon(Icons.person), label: Text('Chip')),
            ActionChip(avatar: const Icon(Icons.refresh), label: const Text('Action'), onPressed: () {}),
            for (final s in const ['Small', 'Medium', 'Large'])
              ChoiceChip(label: Text(s), selected: _choice == s, onSelected: (_) => setState(() => _choice = s)),
            for (final c in _chips)
              InputChip(label: Text(c), onDeleted: () => setState(() => _chips.remove(c))),
          ]),
          gap,
          const Wrap(spacing: 24, children: [
            Badge(child: Icon(Icons.mail_outline)),
            Badge(label: Text('12'), child: Icon(Icons.shopping_cart_outlined)),
            Badge(label: Text('99+'), child: Icon(Icons.notifications_outlined)),
          ]),
        ]),
        Section(title: 'Progress indicators', children: [
          const LinearProgressIndicator(),
          gap,
          const LinearProgressIndicator(value: 0.6),
          gap,
          const Wrap(spacing: 24, children: [
            CircularProgressIndicator(),
            CircularProgressIndicator(value: 0.75),
            RefreshProgressIndicator(),
          ]),
        ]),
        Section(title: 'Cards', children: [
          ResponsiveRow(children: [
            const Card(child: ListTile(title: Text('Elevated card'), subtitle: Text('Card()'))),
            const Card.filled(child: ListTile(title: Text('Filled card'), subtitle: Text('Card.filled()'))),
            const Card.outlined(child: ListTile(title: Text('Outlined card'), subtitle: Text('Card.outlined()'))),
          ]),
        ]),
        Section(title: 'Stepper', children: [
          Stepper(
            physics: const NeverScrollableScrollPhysics(),
            currentStep: _step,
            onStepTapped: (i) => setState(() => _step = i),
            onStepContinue: () => setState(() => _step = (_step + 1).clamp(0, 2)),
            onStepCancel: () => setState(() => _step = (_step - 1).clamp(0, 2)),
            steps: [
              Step(title: const Text('Scan items'), content: const Text('Scan barcodes to add to cart.'), isActive: _step >= 0),
              Step(title: const Text('Payment'), content: const Text('Choose cash, card or UPI.'), isActive: _step >= 1),
              Step(title: const Text('Receipt'), content: const Text('Print or share receipt.'), isActive: _step >= 2),
            ],
          ),
        ]),
        Section(title: 'Navigation bar', children: [
          NavigationBar(
            selectedIndex: _navIndex,
            onDestinationSelected: (i) => setState(() => _navIndex = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.receipt_outlined), selectedIcon: Icon(Icons.receipt), label: 'Orders'),
              NavigationDestination(
                  icon: Badge(label: Text('2'), child: Icon(Icons.inventory_2_outlined)), label: 'Stock'),
            ],
          ),
        ]),
        Section(title: 'Misc', children: [
          Row(children: [
            CircleAvatar(backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary, child: const Text('SK')),
            const SizedBox(width: 8),
            const CircleAvatar(child: Icon(Icons.store)),
            const SizedBox(width: 16),
            const Expanded(child: Divider()),
          ]),
          gap,
          const ExpansionTile(
            title: Text('ExpansionTile'),
            leading: Icon(Icons.expand_more),
            children: [ListTile(title: Text('Hidden content revealed'))],
          ),
          const Tooltip(
            message: 'Long press or hover',
            child: ListTile(leading: Icon(Icons.info), title: Text('ListTile with tooltip')),
          ),
        ]),
      ],
    );
  }
}
