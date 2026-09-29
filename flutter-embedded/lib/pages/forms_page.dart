import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/section.dart';
import '../widgets/validators.dart';

enum Payment { cash, card, upi }

enum Plan { basic, pro, enterprise }

class FormsPage extends StatefulWidget {
  const FormsPage({super.key});

  @override
  State<FormsPage> createState() => _FormsPageState();
}

class _FormsPageState extends State<FormsPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _notes = TextEditingController();
  final _date = TextEditingController();
  final _time = TextEditingController();

  static const _cities = ['Bengaluru', 'Mysuru', 'Chennai', 'Hyderabad', 'Mumbai', 'Pune', 'Delhi'];
  static const _categories = ['Grocery', 'Dairy', 'Bakery', 'Beverages', 'Snacks'];

  String? _city;
  String? _category;
  String _autocomplete = '';
  Payment _payment = Payment.cash;
  Set<Plan> _plan = {Plan.basic};
  final Set<String> _tags = {'Retail'};
  bool _newsletter = true;
  double _discount = 10;
  RangeValues _price = const RangeValues(100, 800);
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _qty, _notes, _date, _time]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      initialDate: DateTime(now.year - 25),
      helpText: 'Date of birth',
    );
    if (d != null) _date.text = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null && mounted) _time.text = t.format(context);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text('Please fix the errors in the form'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green),
        title: const Text('Form valid'),
        content: SingleChildScrollView(
          child: Text([
            'Name: ${_name.text}',
            'Email: ${_email.text}',
            'Phone: ${_phone.text}',
            'City: $_city',
            'Category: $_category',
            'Product: $_autocomplete',
            'DOB: ${_date.text}',
            'Delivery: ${_time.text}',
            'Qty: ${_qty.text}',
            'Payment: ${_payment.name}',
            'Plan: ${_plan.first.name}',
            'Tags: ${_tags.join(', ')}',
            'Discount: ${_discount.round()}%',
            'Price: ₹${_price.start.round()} – ₹${_price.end.round()}',
            'Newsletter: $_newsletter',
          ].join('\n')),
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  void _reset() {
    _formKey.currentState!.reset();
    for (final c in [_name, _email, _phone, _password, _notes, _date, _time]) {
      c.clear();
    }
    _qty.text = '1';
    setState(() {
      _city = null;
      _category = null;
      _payment = Payment.cash;
      _plan = {Plan.basic};
      _discount = 10;
      _price = const RangeValues(100, 800);
    });
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16, width: 16);
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Section(
            title: 'Text inputs',
            children: [
              ResponsiveRow(children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => Validators.required(v, 'Name'),
                ),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.email,
                ),
              ]),
              gap,
              ResponsiveRow(children: [
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
                  decoration: const InputDecoration(
                    labelText: 'Phone *',
                    prefixText: '+91 ',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.phone,
                ),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    helperText: 'Min 8 chars',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => Validators.minLength(v, 8, 'Password'),
                ),
              ]),
              gap,
              ResponsiveRow(children: [
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password *',
                    prefixIcon: Icon(Icons.lock_reset),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                ),
                TextFormField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Quantity (1-99) *',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => Validators.number(v, min: 1, max: 99, field: 'Quantity'),
                ),
              ]),
              gap,
              TextFormField(
                controller: _notes,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Notes (filled style)',
                  alignLabelWithHint: true,
                  filled: true,
                ),
              ),
            ],
          ),
          Section(
            title: 'Pickers & dropdowns',
            children: [
              ResponsiveRow(children: [
                DropdownButtonFormField<String>(
                  initialValue: _city,
                  decoration: const InputDecoration(
                    labelText: 'City *',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  items: [for (final c in _cities) DropdownMenuItem(value: c, child: Text(c))],
                  onChanged: (v) => setState(() => _city = v),
                  validator: (v) => v == null ? 'Select a city' : null,
                ),
                FormField<String>(
                  validator: (_) => _category == null ? 'Select a category' : null,
                  builder: (field) => DropdownMenu<String>(
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Category (DropdownMenu) *'),
                    leadingIcon: const Icon(Icons.category_outlined),
                    enableFilter: true,
                    errorText: field.errorText,
                    dropdownMenuEntries: [
                      for (final c in _categories) DropdownMenuEntry(value: c, label: c),
                    ],
                    onSelected: (v) {
                      setState(() => _category = v);
                      field.didChange(v);
                    },
                  ),
                ),
              ]),
              gap,
              Autocomplete<String>(
                optionsBuilder: (v) => v.text.isEmpty
                    ? const Iterable<String>.empty()
                    : const ['Apple', 'Banana', 'Bread', 'Butter', 'Milk', 'Mango', 'Rice', 'Sugar', 'Tea', 'Coffee']
                        .where((o) => o.toLowerCase().contains(v.text.toLowerCase())),
                onSelected: (v) => _autocomplete = v,
                fieldViewBuilder: (context, ctrl, focus, onSubmit) => TextFormField(
                  controller: ctrl,
                  focusNode: focus,
                  onChanged: (v) => _autocomplete = v,
                  decoration: const InputDecoration(
                    labelText: 'Product (Autocomplete: try "b" or "m")',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              gap,
              ResponsiveRow(children: [
                TextFormField(
                  controller: _date,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: 'Date of birth *',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => Validators.required(v, 'Date'),
                ),
                TextFormField(
                  controller: _time,
                  readOnly: true,
                  onTap: _pickTime,
                  decoration: const InputDecoration(
                    labelText: 'Delivery time',
                    prefixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder(),
                  ),
                ),
              ]),
            ],
          ),
          Section(
            title: 'Selection controls',
            children: [
              const Text('Payment (Radio)'),
              RadioGroup<Payment>(
                groupValue: _payment,
                onChanged: (v) => setState(() => _payment = v!),
                child: Wrap(
                  children: [
                    for (final p in Payment.values)
                      SizedBox(
                        width: 160,
                        child: RadioListTile<Payment>(value: p, title: Text(p.name.toUpperCase())),
                      ),
                  ],
                ),
              ),
              gap,
              const Text('Plan (SegmentedButton)'),
              const SizedBox(height: 8),
              SegmentedButton<Plan>(
                segments: const [
                  ButtonSegment(value: Plan.basic, label: Text('Basic'), icon: Icon(Icons.star_border)),
                  ButtonSegment(value: Plan.pro, label: Text('Pro'), icon: Icon(Icons.star_half)),
                  ButtonSegment(value: Plan.enterprise, label: Text('Ent.'), icon: Icon(Icons.star)),
                ],
                selected: _plan,
                onSelectionChanged: (s) => setState(() => _plan = s),
              ),
              gap,
              const Text('Tags (FilterChip)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in const ['Retail', 'Wholesale', 'VIP', 'Online', 'Credit'])
                    FilterChip(
                      label: Text(t),
                      selected: _tags.contains(t),
                      onSelected: (s) => setState(() => s ? _tags.add(t) : _tags.remove(t)),
                    ),
                ],
              ),
              gap,
              Text('Discount (Slider): ${_discount.round()}%'),
              Slider(
                value: _discount,
                max: 50,
                divisions: 10,
                label: '${_discount.round()}%',
                onChanged: (v) => setState(() => _discount = v),
              ),
              Text('Price range (RangeSlider): ₹${_price.start.round()} – ₹${_price.end.round()}'),
              RangeSlider(
                values: _price,
                max: 1000,
                divisions: 20,
                labels: RangeLabels('₹${_price.start.round()}', '₹${_price.end.round()}'),
                onChanged: (v) => setState(() => _price = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Subscribe to newsletter (Switch)'),
                value: _newsletter,
                onChanged: (v) => setState(() => _newsletter = v),
              ),
              FormField<bool>(
                initialValue: false,
                validator: (v) => v == true ? null : 'You must accept the terms',
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('I accept the terms & conditions *'),
                      value: field.value,
                      onChanged: field.didChange,
                    ),
                    if (field.hasError)
                      Text(field.errorText!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh), label: const Text('Reset')),
              gap,
              FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.send), label: const Text('Submit')),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
