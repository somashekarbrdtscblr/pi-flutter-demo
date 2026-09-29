import 'package:flutter/material.dart';

import '../widgets/section.dart';
import '../widgets/validators.dart';

class DialogsPage extends StatelessWidget {
  const DialogsPage({super.key});

  void _snack(BuildContext context, SnackBar bar) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(bar);
  }

  Future<void> _alert(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever),
        title: const Text('Delete item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (context.mounted) _snack(context, SnackBar(content: Text('Result: ${ok ?? 'dismissed'}')));
  }

  Future<void> _simple(BuildContext context) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select printer'),
        children: [
          for (final p in const ['Thermal 58mm', 'Thermal 80mm', 'A4 Laser'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p),
              child: ListTile(leading: const Icon(Icons.print), title: Text(p)),
            ),
        ],
      ),
    );
    if (choice != null && context.mounted) {
      _snack(context, SnackBar(content: Text('Selected: $choice')));
    }
  }

  Future<void> _formDialog(BuildContext context) async {
    final key = GlobalKey<FormState>();
    final name = TextEditingController();
    final price = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Add product'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => Validators.required(v, 'Name'),
              ),
              TextFormField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price', prefixText: '₹ '),
                validator: (v) => Validators.number(v, min: 1, field: 'Price'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(ctx, '${name.text} @ ₹${price.text}');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    name.dispose();
    price.dispose();
    if (result != null && context.mounted) {
      _snack(context, SnackBar(content: Text('Added $result')));
    }
  }

  void _fullScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => Scaffold(
        appBar: AppBar(
          title: const Text('New order'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('SAVE'))],
        ),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(children: [
            TextField(decoration: InputDecoration(labelText: 'Customer', border: OutlineInputBorder())),
            SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(labelText: 'Items', border: OutlineInputBorder()),
            ),
          ]),
        ),
      ),
    ));
  }

  Future<void> _loading(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(children: [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Text('Processing payment…'),
          ]),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;
    Navigator.of(context).pop();
    _snack(context, const SnackBar(content: Text('Payment successful'), behavior: SnackBarBehavior.floating));
  }

  void _bottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (icon, label) in const [
              (Icons.share, 'Share receipt'),
              (Icons.print, 'Print receipt'),
              (Icons.email, 'Email receipt'),
              (Icons.cancel, 'Void transaction'),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () {
                  Navigator.pop(ctx);
                  _snack(context, SnackBar(content: Text(label)));
                },
              ),
          ],
        ),
      ),
    );
  }

  void _draggableSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => ListView.builder(
          controller: scroll,
          itemCount: 30,
          itemBuilder: (_, i) => ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text('Transaction #${1000 + i}'),
            subtitle: Text('₹ ${(i + 1) * 57}'),
          ),
        ),
      ),
    );
  }

  void _banner(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showMaterialBanner(MaterialBanner(
      leading: const Icon(Icons.wifi_off),
      content: const Text('You are offline. Sales will sync when connection is restored.'),
      actions: [
        TextButton(onPressed: messenger.hideCurrentMaterialBanner, child: const Text('DISMISS')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget btn(String label, IconData icon, VoidCallback onTap) =>
        FilledButton.tonalIcon(onPressed: onTap, icon: Icon(icon), label: Text(label));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Section(title: 'Dialogs', children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            btn('Alert / confirm', Icons.warning_amber, () => _alert(context)),
            btn('Simple dialog', Icons.list, () => _simple(context)),
            btn('Form dialog', Icons.edit, () => _formDialog(context)),
            btn('Full-screen dialog', Icons.fullscreen, () => _fullScreen(context)),
            btn('Loading dialog', Icons.hourglass_top, () => _loading(context)),
            btn('About dialog', Icons.info_outline, () => showAboutDialog(
                  context: context,
                  applicationName: 'Chota POS Demo',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.point_of_sale),
                )),
            btn('Date range', Icons.date_range, () => showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                )),
          ]),
        ]),
        Section(title: 'Modals / bottom sheets', children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            btn('Modal bottom sheet', Icons.vertical_align_bottom, () => _bottomSheet(context)),
            btn('Draggable sheet', Icons.drag_handle, () => _draggableSheet(context)),
            Builder(
              builder: (ctx) => btn('Persistent sheet', Icons.push_pin, () {
                Scaffold.of(ctx).showBottomSheet((c) => Container(
                      height: 120,
                      width: double.infinity,
                      color: scheme.secondaryContainer,
                      alignment: Alignment.center,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Close persistent sheet'),
                      ),
                    ));
              }),
            ),
          ]),
        ]),
        Section(title: 'Snackbars & banners', children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            btn('Simple', Icons.message, () => _snack(context, const SnackBar(content: Text('Saved')))),
            btn('With action (Undo)', Icons.undo, () => _snack(
                  context,
                  SnackBar(
                    content: const Text('Item deleted'),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () => _snack(context, const SnackBar(content: Text('Restored'))),
                    ),
                  ),
                )),
            btn('Floating', Icons.flight, () => _snack(
                  context,
                  const SnackBar(
                    content: Text('Floating snackbar'),
                    behavior: SnackBarBehavior.floating,
                    showCloseIcon: true,
                  ),
                )),
            btn('Error', Icons.error_outline, () => _snack(
                  context,
                  SnackBar(
                    content: const Text('Printer not connected'),
                    backgroundColor: scheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                )),
            btn('Material banner', Icons.flag, () => _banner(context)),
          ]),
        ]),
        Section(title: 'Menus & tooltips', children: [
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            MenuAnchor(
              menuChildren: [
                MenuItemButton(leadingIcon: const Icon(Icons.copy), child: const Text('Copy'), onPressed: () {}),
                MenuItemButton(leadingIcon: const Icon(Icons.paste), child: const Text('Paste'), onPressed: () {}),
                SubmenuButton(menuChildren: [
                  MenuItemButton(child: const Text('PDF'), onPressed: () {}),
                  MenuItemButton(child: const Text('CSV'), onPressed: () {}),
                ], child: const Text('Export')),
              ],
              builder: (_, ctrl, _) => OutlinedButton.icon(
                onPressed: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
                icon: const Icon(Icons.menu_open),
                label: const Text('MenuAnchor'),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) => _snack(context, SnackBar(content: Text(v))),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'Edit', child: Text('Edit')),
                PopupMenuItem(value: 'Duplicate', child: Text('Duplicate')),
                CheckedPopupMenuItem(value: 'Pinned', checked: true, child: Text('Pinned')),
              ],
            ),
            const Tooltip(message: 'I am a tooltip', child: Icon(Icons.help_outline)),
          ]),
        ]),
      ],
    );
  }
}
