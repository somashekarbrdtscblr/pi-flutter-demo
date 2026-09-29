import 'package:flutter/material.dart';

import '../widgets/section.dart';

/// Tabs with lists (dismissible, reorderable), card variants, expansion
/// panels, stepper and grid.
class LayoutPage extends StatelessWidget {
  const LayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'Lists'),
              Tab(icon: Icon(Icons.credit_card), text: 'Cards'),
              Tab(icon: Icon(Icons.linear_scale), text: 'Stepper'),
              Tab(icon: Icon(Icons.grid_on), text: 'Grid'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_ListsTab(), _CardsTab(), _StepperTab(), _GridTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListsTab extends StatefulWidget {
  const _ListsTab();

  @override
  State<_ListsTab> createState() => _ListsTabState();
}

class _ListsTabState extends State<_ListsTab> {
  final _items = List.generate(6, (i) => 'Order #${1040 + i}');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Swipe to delete', style: theme.textTheme.titleSmall),
        for (final item in _items)
          Dismissible(
            key: ValueKey(item),
            background: Container(
              color: theme.colorScheme.errorContainer,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete),
            ),
            secondaryBackground: Container(
              color: theme.colorScheme.tertiaryContainer,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.archive),
            ),
            onDismissed: (dir) {
              final index = _items.indexOf(item);
              setState(() => _items.remove(item));
              showSnack(
                context,
                '$item ${dir == DismissDirection.startToEnd ? 'deleted' : 'archived'}',
                action: SnackBarAction(
                  label: 'UNDO',
                  onPressed: () => setState(() => _items.insert(index, item)),
                ),
              );
            },
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.receipt)),
              title: Text(item),
              subtitle: const Text('3 items · ₹250'),
              trailing: const Icon(Icons.drag_handle),
            ),
          ),
        const Divider(height: 32),
        Text('ListTile variants', style: theme.textTheme.titleSmall),
        const ListTile(title: Text('One-line')),
        const ListTile(
          title: Text('Two-line'),
          subtitle: Text('Supporting text'),
        ),
        const ListTile(
          isThreeLine: true,
          leading: Icon(Icons.person),
          title: Text('Three-line'),
          subtitle: Text(
            'Longer supporting text that wraps onto a second line '
            'to show the three-line layout.',
          ),
        ),
        CheckboxListTile(
          value: true,
          onChanged: (_) {},
          title: const Text('CheckboxListTile'),
        ),
        SwitchListTile(
          value: false,
          onChanged: (_) {},
          title: const Text('SwitchListTile'),
        ),
        const Divider(height: 32),
        Text('Expansion', style: theme.textTheme.titleSmall),
        const ExpansionTile(
          leading: Icon(Icons.help_outline),
          title: Text('How do I refund a bill?'),
          children: [
            ListTile(title: Text('Open the bill, tap ⋮ → Refund, confirm.')),
          ],
        ),
        const ExpansionTile(
          leading: Icon(Icons.help_outline),
          title: Text('Can I work offline?'),
          children: [
            ListTile(title: Text('Yes. Sales sync automatically when online.')),
          ],
        ),
      ],
    );
  }
}

class _CardsTab extends StatelessWidget {
  const _CardsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget body(String title) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Cards group related content and actions.'),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(width: 260, child: Card(child: body('Elevated card'))),
          SizedBox(width: 260, child: Card.filled(child: body('Filled card'))),
          SizedBox(
            width: 260,
            child: Card.outlined(child: body('Outlined card')),
          ),
          SizedBox(
            width: 260,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.tertiary,
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.local_cafe,
                      size: 48,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const ListTile(
                    title: Text('Media card'),
                    subtitle: Text('Header, content and actions'),
                  ),
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () {}, child: const Text('SHARE')),
                      TextButton(onPressed: () {}, child: const Text('BUY')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperTab extends StatefulWidget {
  const _StepperTab();

  @override
  State<_StepperTab> createState() => _StepperTabState();
}

class _StepperTabState extends State<_StepperTab> {
  int _step = 0;
  final _stepKey = GlobalKey<FormState>();

  static const _titles = ['Customer', 'Items', 'Payment'];

  @override
  Widget build(BuildContext context) {
    return Stepper(
      currentStep: _step,
      onStepTapped: (i) => setState(() => _step = i),
      onStepCancel: _step == 0 ? null : () => setState(() => _step--),
      onStepContinue: () {
        if (_step == 0 && !_stepKey.currentState!.validate()) return;
        if (_step < _titles.length - 1) {
          setState(() => _step++);
        } else {
          showSnack(context, 'Checkout complete');
          setState(() => _step = 0);
        }
      },
      steps: [
        Step(
          title: Text(_titles[0]),
          isActive: _step >= 0,
          state: _step > 0 ? StepState.complete : StepState.indexed,
          content: Form(
            key: _stepKey,
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Customer name'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Required to continue'
                  : null,
            ),
          ),
        ),
        Step(
          title: Text(_titles[1]),
          isActive: _step >= 1,
          state: _step > 1 ? StepState.complete : StepState.indexed,
          content: const Text('2 × Masala Chai, 1 × Bread Loaf'),
        ),
        Step(
          title: Text(_titles[2]),
          isActive: _step >= 2,
          content: const Text('Total ₹70 — pay by UPI'),
        ),
      ],
    );
  }
}

class _GridTab extends StatelessWidget {
  const _GridTab();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const icons = [
      Icons.local_cafe,
      Icons.bakery_dining,
      Icons.icecream,
      Icons.lunch_dining,
      Icons.local_pizza,
      Icons.ramen_dining,
      Icons.cookie,
      Icons.liquor,
      Icons.egg,
      Icons.set_meal,
      Icons.rice_bowl,
      Icons.soup_kitchen,
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: icons.length,
      itemBuilder: (context, i) => Card.filled(
        color: scheme.secondaryContainer,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showSnack(context, 'Tile ${i + 1}'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icons[i], size: 36, color: scheme.onSecondaryContainer),
              const SizedBox(height: 8),
              Text('Item ${i + 1}'),
            ],
          ),
        ),
      ),
    );
  }
}
