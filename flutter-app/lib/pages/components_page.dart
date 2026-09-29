import 'package:flutter/material.dart';

import '../widgets/section.dart';

/// Gallery of Material 3 buttons, chips, selection controls, indicators, menus.
class ComponentsPage extends StatefulWidget {
  const ComponentsPage({super.key});

  @override
  State<ComponentsPage> createState() => _ComponentsPageState();
}

class _ComponentsPageState extends State<ComponentsPage> {
  bool? _check = true;
  bool _switch = true;
  String _radio = 'Cash';
  double _slider = 40;
  RangeValues _range = const RangeValues(20, 80);
  final _tags = {'Flutter', 'Pi', 'POS', 'Dart'};
  String _choice = 'Small';
  final _filters = <String>{'Veg'};
  bool _toggled = false;
  String? _menuPick;
  String? _dropdownMenuPick;
  final _toggleSelection = [true, false, false];
  int _navIndex = 0;
  bool _pinned = true;

  void _tap(String what) => showSnack(context, '$what pressed');

  @override
  Widget build(BuildContext context) {
    const spacing = SizedBox(width: 8, height: 8);
    return PageBody(
      children: [
        Section(
          title: 'Buttons',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _tap('Elevated'),
                child: const Text('Elevated'),
              ),
              FilledButton(
                onPressed: () => _tap('Filled'),
                child: const Text('Filled'),
              ),
              FilledButton.tonal(
                onPressed: () => _tap('Tonal'),
                child: const Text('Tonal'),
              ),
              OutlinedButton(
                onPressed: () => _tap('Outlined'),
                child: const Text('Outlined'),
              ),
              TextButton(
                onPressed: () => _tap('Text'),
                child: const Text('Text'),
              ),
              FilledButton.icon(
                onPressed: () => _tap('Icon'),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('With icon'),
              ),
              const FilledButton(onPressed: null, child: Text('Disabled')),
            ],
          ),
        ),
        Section(
          title: 'Icon buttons & FABs',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                onPressed: () => _tap('Icon'),
                icon: const Icon(Icons.favorite_border),
              ),
              IconButton.filled(
                onPressed: () => _tap('Filled icon'),
                icon: const Icon(Icons.add),
              ),
              IconButton.filledTonal(
                onPressed: () => _tap('Tonal icon'),
                icon: const Icon(Icons.edit),
              ),
              IconButton.outlined(
                onPressed: () => _tap('Outlined icon'),
                icon: const Icon(Icons.share),
              ),
              IconButton(
                isSelected: _toggled,
                onPressed: () => setState(() => _toggled = !_toggled),
                icon: const Icon(Icons.bookmark_border),
                selectedIcon: const Icon(Icons.bookmark),
              ),
              FloatingActionButton.small(
                heroTag: 'fab-s',
                onPressed: () => _tap('Small FAB'),
                child: const Icon(Icons.add),
              ),
              FloatingActionButton(
                heroTag: 'fab',
                onPressed: () => _tap('FAB'),
                child: const Icon(Icons.qr_code_scanner),
              ),
              FloatingActionButton.extended(
                heroTag: 'fab-e',
                onPressed: () => _tap('Extended FAB'),
                icon: const Icon(Icons.point_of_sale),
                label: const Text('New sale'),
              ),
            ],
          ),
        ),
        Section(
          title: 'Segmented & toggle buttons',
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Small', label: Text('S')),
                  ButtonSegment(value: 'Medium', label: Text('M')),
                  ButtonSegment(value: 'Large', label: Text('L')),
                ],
                selected: {_choice},
                onSelectionChanged: (s) => setState(() => _choice = s.first),
              ),
              ToggleButtons(
                isSelected: _toggleSelection,
                onPressed: (i) =>
                    setState(() => _toggleSelection[i] = !_toggleSelection[i]),
                children: const [
                  Icon(Icons.format_bold),
                  Icon(Icons.format_italic),
                  Icon(Icons.format_underline),
                ],
              ),
            ],
          ),
        ),
        Section(
          title: 'Chips',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Chip(
                    avatar: Icon(Icons.info_outline),
                    label: Text('Chip'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.refresh),
                    label: const Text('Action'),
                    onPressed: () => _tap('Action chip'),
                  ),
                  for (final t in _tags)
                    InputChip(
                      label: Text(t),
                      onDeleted: () => setState(() => _tags.remove(t)),
                    ),
                ],
              ),
              spacing,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in ['Small', 'Medium', 'Large'])
                    ChoiceChip(
                      label: Text(c),
                      selected: _choice == c,
                      onSelected: (_) => setState(() => _choice = c),
                    ),
                  const SizedBox(width: 16),
                  for (final f in ['Veg', 'Vegan', 'Spicy'])
                    FilterChip(
                      label: Text(f),
                      selected: _filters.contains(f),
                      onSelected: (s) => setState(
                        () => s ? _filters.add(f) : _filters.remove(f),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Section(
          title: 'Selection controls',
          child: Wrap(
            spacing: 24,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    tristate: true,
                    value: _check,
                    onChanged: (v) => setState(() => _check = v),
                  ),
                  Text('Tristate: ${_check ?? 'null'}'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: _switch,
                    onChanged: (v) => setState(() => _switch = v),
                  ),
                  Text(_switch ? 'On' : 'Off'),
                ],
              ),
              RadioGroup<String>(
                groupValue: _radio,
                onChanged: (v) => setState(() => _radio = v!),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final r in ['Cash', 'Card', 'UPI']) ...[
                      Radio<String>(value: r),
                      Text(r),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Section(
          title: 'Sliders',
          child: Column(
            children: [
              Slider(
                value: _slider,
                max: 100,
                divisions: 10,
                label: _slider.round().toString(),
                onChanged: (v) => setState(() => _slider = v),
              ),
              RangeSlider(
                values: _range,
                max: 100,
                divisions: 20,
                labels: RangeLabels(
                  '₹${_range.start.round()}',
                  '₹${_range.end.round()}',
                ),
                onChanged: (v) => setState(() => _range = v),
              ),
            ],
          ),
        ),
        Section(
          title: 'Progress & badges',
          child: Wrap(
            spacing: 24,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const CircularProgressIndicator(),
              CircularProgressIndicator(value: _slider / 100),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(value: _slider / 100),
              ),
              const SizedBox(width: 200, child: LinearProgressIndicator()),
              const RefreshProgressIndicator(),
              const Badge(child: Icon(Icons.mail_outline)),
              Badge.count(
                count: 12,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              const Badge(
                label: Text('NEW'),
                child: Icon(Icons.local_offer_outlined),
              ),
            ],
          ),
        ),
        Section(
          title: 'Menus & tooltips',
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MenuAnchor(
                menuChildren: [
                  for (final m in ['Cut', 'Copy', 'Paste'])
                    MenuItemButton(
                      onPressed: () => setState(() => _menuPick = m),
                      child: Text(m),
                    ),
                  SubmenuButton(
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () => setState(() => _menuPick = 'PDF'),
                        child: const Text('PDF'),
                      ),
                      MenuItemButton(
                        onPressed: () => setState(() => _menuPick = 'CSV'),
                        child: const Text('CSV'),
                      ),
                    ],
                    child: const Text('Export'),
                  ),
                ],
                builder: (context, controller, _) => OutlinedButton.icon(
                  onPressed: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                  icon: const Icon(Icons.more_vert),
                  label: Text(
                    'MenuAnchor${_menuPick == null ? '' : ': $_menuPick'}',
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => v == 'Pinned'
                    ? setState(() => _pinned = !_pinned)
                    : _tap(v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'Refresh', child: Text('Refresh')),
                  const PopupMenuItem(value: 'Print', child: Text('Print')),
                  const PopupMenuDivider(),
                  CheckedPopupMenuItem(
                    value: 'Pinned',
                    checked: _pinned,
                    child: const Text('Pinned'),
                  ),
                ],
                child: const Chip(
                  avatar: Icon(Icons.arrow_drop_down),
                  label: Text('PopupMenuButton'),
                ),
              ),
              DropdownMenu<String>(
                label: const Text('DropdownMenu'),
                width: 220,
                enableFilter: true,
                initialSelection: _dropdownMenuPick,
                onSelected: (v) => setState(() => _dropdownMenuPick = v),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'blr', label: 'Bengaluru'),
                  DropdownMenuEntry(value: 'mys', label: 'Mysuru'),
                  DropdownMenuEntry(value: 'hub', label: 'Hubballi'),
                ],
              ),
              const Tooltip(
                message: 'I am a tooltip',
                child: Icon(Icons.help_outline, size: 32),
              ),
            ],
          ),
        ),
        Section(
          title: 'Navigation bar',
          subtitle: 'Bottom navigation, as used on phones',
          child: NavigationBar(
            selectedIndex: _navIndex,
            onDestinationSelected: (i) => setState(() => _navIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_outlined),
                selectedIcon: Icon(Icons.receipt),
                label: 'Orders',
              ),
              NavigationDestination(
                icon: Badge(
                  label: Text('2'),
                  child: Icon(Icons.inventory_2_outlined),
                ),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Stock',
              ),
            ],
          ),
        ),
        Section(
          title: 'Avatars',
          child: Wrap(
            spacing: 12,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: const Text('SK'),
              ),
              const CircleAvatar(child: Icon(Icons.store)),
              const CircleAvatar(child: Text('POS')),
            ],
          ),
        ),
        Section(
          title: 'Search',
          child: SearchAnchor.bar(
            barHintText: 'Search products',
            suggestionsBuilder: (context, controller) {
              const items = [
                'Masala Chai',
                'Milk 1L',
                'Bread Loaf',
                'Dish Soap',
              ];
              return items
                  .where(
                    (i) =>
                        i.toLowerCase().contains(controller.text.toLowerCase()),
                  )
                  .map(
                    (i) => ListTile(
                      leading: const Icon(Icons.search),
                      title: Text(i),
                      onTap: () => controller.closeView(i),
                    ),
                  );
            },
          ),
        ),
      ],
    );
  }
}
