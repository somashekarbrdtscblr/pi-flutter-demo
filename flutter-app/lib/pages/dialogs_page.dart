import 'package:flutter/material.dart';

import '../utils/validators.dart';
import '../widgets/section.dart';

/// Dialogs, modals, bottom sheets, snackbars, banners and system pickers.
class DialogsPage extends StatelessWidget {
  const DialogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget grid(List<Widget> children) =>
        Wrap(spacing: 8, runSpacing: 8, children: children);

    return PageBody(
      children: [
        Section(
          title: 'Dialogs',
          child: grid([
            FilledButton.tonal(
              onPressed: () => _alert(context),
              child: const Text('Alert / confirm'),
            ),
            FilledButton.tonal(
              onPressed: () => _simple(context),
              child: const Text('Simple dialog'),
            ),
            FilledButton.tonal(
              onPressed: () => _inputDialog(context),
              child: const Text('Input dialog'),
            ),
            FilledButton.tonal(
              onPressed: () => _loading(context),
              child: const Text('Loading dialog'),
            ),
            FilledButton.tonal(
              onPressed: () => _fullscreen(context),
              child: const Text('Full-screen dialog'),
            ),
            FilledButton.tonal(
              onPressed: () => showAboutDialog(
                context: context,
                applicationName: 'Chota POS',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.point_of_sale, size: 40),
                children: const [
                  Text('Flutter on Raspberry Pi via flutter-pi.'),
                ],
              ),
              child: const Text('About dialog'),
            ),
          ]),
        ),
        Section(
          title: 'Bottom sheets (modals)',
          child: grid([
            FilledButton.tonal(
              onPressed: () => _modalSheet(context),
              child: const Text('Modal sheet'),
            ),
            FilledButton.tonal(
              onPressed: () => _draggableSheet(context),
              child: const Text('Draggable sheet'),
            ),
            Builder(
              // Needs a context below the shell Scaffold.
              builder: (context) => FilledButton.tonal(
                onPressed: () => _persistentSheet(context),
                child: const Text('Persistent sheet'),
              ),
            ),
          ]),
        ),
        Section(
          title: 'Snackbars & banners',
          child: grid([
            OutlinedButton(
              onPressed: () => showSnack(context, 'Simple snackbar'),
              child: const Text('Snackbar'),
            ),
            OutlinedButton(
              onPressed: () => showSnack(
                context,
                'Item archived',
                action: SnackBarAction(
                  label: 'UNDO',
                  onPressed: () => showSnack(context, 'Restored'),
                ),
              ),
              child: const Text('With action'),
            ),
            OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Payment failed. Printer offline.'),
                        ),
                      ],
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    showCloseIcon: true,
                    duration: const Duration(seconds: 6),
                  ),
                ),
              child: const Text('Error snackbar'),
            ),
            OutlinedButton(
              onPressed: () => _banner(context),
              child: const Text('Material banner'),
            ),
          ]),
        ),
        Section(
          title: 'System pickers',
          child: grid([
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text('Date'),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDate: DateTime.now(),
                );
                if (d != null && context.mounted) {
                  showSnack(
                    context,
                    'Picked ${d.toLocal().toString().split(' ').first}',
                  );
                }
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: const Text('Date range'),
              onPressed: () async {
                final r = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (r != null && context.mounted) {
                  showSnack(context, '${r.duration.inDays + 1} days selected');
                }
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.access_time),
              label: const Text('Time'),
              onPressed: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (t != null && context.mounted) {
                  showSnack(context, 'Picked ${t.format(context)}');
                }
              },
            ),
          ]),
        ),
      ],
    );
  }

  Future<void> _alert(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber),
        title: const Text('Void this bill?'),
        content: const Text(
          'Bill #1042 (₹340) will be voided. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Void'),
          ),
        ],
      ),
    );
    if (context.mounted) {
      showSnack(context, ok == true ? 'Bill voided' : 'Cancelled');
    }
  }

  Future<void> _simple(BuildContext context) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Payment method'),
        children: [
          for (final (icon, label) in [
            (Icons.money, 'Cash'),
            (Icons.credit_card, 'Card'),
            (Icons.qr_code, 'UPI'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, label),
              child: ListTile(leading: Icon(icon), title: Text(label)),
            ),
        ],
      ),
    );
    if (choice != null && context.mounted) {
      showSnack(context, 'Selected $choice');
    }
  }

  Future<void> _inputDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const _DiscountDialog(),
    );
    if (result != null && context.mounted) {
      showSnack(context, 'Applied $result% discount');
    }
  }

  Future<void> _loading(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 24),
              Text('Syncing…'),
            ],
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;
    // showDialog uses the root navigator; the page sits in the shell navigator.
    Navigator.of(context, rootNavigator: true).pop();
    showSnack(context, 'Sync complete');
  }

  void _fullscreen(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('New customer'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('SAVE'),
              ),
            ],
          ),
          body: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(decoration: InputDecoration(labelText: 'Name')),
                SizedBox(height: 12),
                TextField(decoration: InputDecoration(labelText: 'Phone')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _modalSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (icon, label) in [
              (Icons.print, 'Print receipt'),
              (Icons.share, 'Share receipt'),
              (Icons.email, 'Email receipt'),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showSnack(context, label);
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
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, controller) => ListView.builder(
          controller: controller,
          itemCount: 30,
          itemBuilder: (_, i) => ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text('Line item ${i + 1}'),
            trailing: Text('₹${(i + 1) * 10}'),
          ),
        ),
      ),
    );
  }

  void _persistentSheet(BuildContext context) {
    Scaffold.of(context).showBottomSheet(
      (sheetContext) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Persistent sheet: page stays interactive.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _banner(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showMaterialBanner(
      MaterialBanner(
        leading: const Icon(Icons.wifi_off),
        content: const Text('You are offline. Sales will sync when connected.'),
        actions: [
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: const Text('DISMISS'),
          ),
        ],
      ),
    );
  }
}

class _DiscountDialog extends StatefulWidget {
  const _DiscountDialog();

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  final _key = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    if (_key.currentState!.validate()) Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Apply discount'),
      content: Form(
        key: _key,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Discount',
            suffixText: '%',
          ),
          validator: Validators.numberRange(1, 50, 'Discount'),
          onFieldSubmitted: (_) => _apply(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _apply, child: const Text('Apply')),
      ],
    );
  }
}
