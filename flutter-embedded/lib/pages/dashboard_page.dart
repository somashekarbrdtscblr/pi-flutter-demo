import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const _stats = [
    ('Sales Today', '₹ 24,580', Icons.currency_rupee, '+12%'),
    ('Orders', '138', Icons.receipt_long, '+5%'),
    ('Customers', '96', Icons.people_alt, '+3%'),
    ('Low Stock', '7', Icons.inventory_2, '-2'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 900 ? 4 : (c.maxWidth > 500 ? 2 : 1);
            final w = (c.maxWidth - (cols - 1) * 12) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final s in _stats)
                  SizedBox(
                    width: w,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: scheme.primaryContainer,
                              child: Icon(s.$3, color: scheme.onPrimaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.$1, style: text.labelLarge),
                                  Text(s.$2, style: text.headlineSmall),
                                ],
                              ),
                            ),
                            Chip(label: Text(s.$4), visualDensity: VisualDensity.compact),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly Sales', style: text.titleMedium),
                const SizedBox(height: 16),
                SizedBox(height: 140, child: _BarChart(values: const [40, 65, 30, 80, 55, 90, 70])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card.filled(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Targets', style: text.titleMedium),
                const SizedBox(height: 12),
                for (final (label, v) in const [('Monthly sales', 0.72), ('New customers', 0.45), ('Inventory audit', 0.9)]) ...[
                  Text('$label — ${(v * 100).round()}%'),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: v, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 100,
                color: scheme.tertiaryContainer,
                alignment: Alignment.center,
                child: Icon(Icons.local_offer, size: 48, color: scheme.onTertiaryContainer),
              ),
              const ListTile(
                title: Text('Festival Offer'),
                subtitle: Text('Flat 10% off on all groceries this weekend.'),
              ),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () {}, child: const Text('Dismiss')),
                  FilledButton.tonal(onPressed: () {}, child: const Text('Activate')),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

/// Minimal bar chart built from Containers (no chart dependency).
class _BarChart extends StatelessWidget {
  const _BarChart({required this.values});
  final List<double> values;
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final max = values.reduce((a, b) => a > b ? a : b);
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: '${values[i].round()}k',
                    child: Container(
                      height: 110 * values[i] / max,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_days[i], style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
