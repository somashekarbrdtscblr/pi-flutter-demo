import 'package:flutter/material.dart';

import '../app_state.dart';
import '../utils/product_store.dart';
import '../widgets/section.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const _weekSales = [42.0, 58, 35, 71, 64, 90, 77];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = ProductStore.instance;
    final user = AppScope.of(context).user ?? '';

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => PageBody(
        children: [
          Text(
            'Hello, ${user.split('@').first} 👋',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                icon: Icons.inventory_2,
                label: 'Products',
                value: '${store.items.length}',
                color: Colors.indigo,
              ),
              _StatCard(
                icon: Icons.currency_rupee,
                label: 'Inventory value',
                value: store.inventoryValue.toStringAsFixed(0),
                color: Colors.teal,
              ),
              _StatCard(
                icon: Icons.warning_amber,
                label: 'Low stock',
                value: '${store.lowStockCount}',
                color: Colors.orange,
              ),
              const _StatCard(
                icon: Icons.receipt_long,
                label: 'Orders today',
                value: '128',
                color: Colors.pink,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Section(
            title: 'Sales this week',
            subtitle: 'Pure-widget bar chart (no chart package)',
            child: SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < _weekSales.length; i++)
                    Expanded(
                      child: Tooltip(
                        message: '${_days[i]}: ₹${_weekSales[i].toInt()}k',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: _weekSales[i] * 1.4,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_days[i], style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Section(
            title: 'Monthly target',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LinearProgressIndicator(value: 0.68, minHeight: 10),
                const SizedBox(height: 8),
                Text('68% of ₹5,00,000', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Section(
            title: 'Recent activity',
            child: Column(
              children: const [
                ListTile(
                  leading: CircleAvatar(child: Icon(Icons.shopping_cart)),
                  title: Text('Order #1042 completed'),
                  subtitle: Text('2 min ago · ₹340'),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
                  leading: CircleAvatar(child: Icon(Icons.inventory)),
                  title: Text('Stock updated: Milk 1L'),
                  subtitle: Text('15 min ago'),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
                  leading: CircleAvatar(child: Icon(Icons.person_add)),
                  title: Text('New customer registered'),
                  subtitle: Text('1 hr ago'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: theme.textTheme.titleLarge),
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
