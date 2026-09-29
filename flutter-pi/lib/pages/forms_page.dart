import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/validators.dart';
import '../widgets/section.dart';

enum Role { cashier, manager, admin }

/// Registration-style form covering every common input + validation.
class FormsPage extends StatefulWidget {
  const FormsPage({super.key});

  @override
  State<FormsPage> createState() => _FormsPageState();
}

class _FormsPageState extends State<FormsPage> {
  static const _countries = [
    'India',
    'Indonesia',
    'Ireland',
    'Israel',
    'Italy',
    'Japan',
    'Kenya',
    'Nepal',
    'Singapore',
    'Sri Lanka',
    'United Kingdom',
    'United States',
  ];
  static const _interests = [
    'Retail',
    'Inventory',
    'Billing',
    'Reports',
    'Loyalty',
  ];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _age = TextEditingController();
  final _dob = TextEditingController();
  final _time = TextEditingController();
  final _address = TextEditingController();
  String? _country;
  String? _gender;
  Role _role = Role.cashier;
  String _shift = 'Morning';
  double _experience = 2;
  bool _newsletter = true;
  bool _obscure = true;
  Set<String> _lastInterests = {};
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  // Bumped on reset so keyed custom fields rebuild with initial values.
  int _formVersion = 0;

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _password,
      _confirm,
      _age,
      _dob,
      _time,
      _address,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null) {
      _dob.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && mounted) _time.text = picked.format(context);
  }

  void _reset() {
    _formKey.currentState!.reset();
    for (final c in [
      _name,
      _email,
      _phone,
      _password,
      _confirm,
      _age,
      _dob,
      _time,
      _address,
    ]) {
      c.clear();
    }
    setState(() {
      _country = null;
      _gender = null;
      _role = Role.cashier;
      _shift = 'Morning';
      _experience = 2;
      _newsletter = true;
      _autovalidate = AutovalidateMode.disabled;
      _formVersion++;
    });
  }

  void _submit() {
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) {
      showSnack(context, 'Please fix the errors in the form');
      return;
    }
    _formKey.currentState!.save();
    final data = {
      'Name': _name.text,
      'Email': _email.text,
      'Phone': _phone.text,
      'Age': _age.text,
      'Gender': _gender ?? '-',
      'Country': _country ?? '-',
      'DOB': _dob.text,
      'Shift start': _time.text.isEmpty ? '-' : _time.text,
      'Role': _role.name,
      'Shift': _shift,
      'Experience': '${_experience.round()} yrs',
      'Interests': _lastInterests.join(', '),
      'Newsletter': '$_newsletter',
    };
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green),
        title: const Text('Form submitted'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in data.entries)
              ListTile(
                dense: true,
                title: Text(e.key),
                trailing: Text(e.value),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    Widget pair(Widget a, Widget b) => wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 12),
              Expanded(child: b),
            ],
          )
        : Column(children: [a, const SizedBox(height: 12), b]);
    const gap = SizedBox(height: 12);

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidate,
      child: PageBody(
        children: [
          Section(
            title: 'Text inputs',
            subtitle:
                'Required, email, phone, password rules, cross-field match',
            child: Column(
              children: [
                pair(
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: Validators.combine([
                      Validators.required('Name'),
                      Validators.minLength(3, 'Name'),
                    ]),
                  ),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email_outlined),
                      helperText: 'We never share your email',
                    ),
                    validator: Validators.email,
                  ),
                ),
                gap,
                pair(
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Phone *',
                      prefixText: '+91 ',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: Validators.phone,
                  ),
                  TextFormField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Age *',
                      suffixText: 'years',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    validator: Validators.numberRange(18, 99, 'Age'),
                  ),
                ),
                gap,
                pair(
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      helperText: 'Min 6 chars incl. a number',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: Validators.password,
                  ),
                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscure,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password *',
                      prefixIcon: Icon(Icons.lock_reset),
                    ),
                    validator: (v) =>
                        v != _password.text ? 'Passwords do not match' : null,
                  ),
                ),
                gap,
                TextFormField(
                  controller: _address,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    alignLabelWithHint: true,
                    hintText: 'Street, city, PIN',
                  ),
                ),
              ],
            ),
          ),
          Section(
            title: 'Pickers & selects',
            subtitle: 'Dropdown, autocomplete, date & time pickers',
            child: Column(
              children: [
                pair(
                  DropdownButtonFormField<String>(
                    key: ValueKey('gender$_formVersion'),
                    initialValue: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender *',
                      prefixIcon: Icon(Icons.wc),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                    validator: (v) => v == null ? 'Select gender' : null,
                  ),
                  Autocomplete<String>(
                    key: ValueKey('country$_formVersion'),
                    optionsBuilder: (value) => value.text.isEmpty
                        ? const Iterable.empty()
                        : _countries.where(
                            (c) => c.toLowerCase().startsWith(
                              value.text.toLowerCase(),
                            ),
                          ),
                    onSelected: (v) => _country = v,
                    fieldViewBuilder: (context, controller, focus, onSubmit) =>
                        TextFormField(
                          controller: controller,
                          focusNode: focus,
                          decoration: const InputDecoration(
                            labelText: 'Country * (type to search)',
                            prefixIcon: Icon(Icons.public),
                          ),
                          validator: (v) => _countries.contains(v)
                              ? null
                              : 'Pick a country from the list',
                          onFieldSubmitted: (_) => onSubmit(),
                        ),
                  ),
                ),
                gap,
                pair(
                  TextFormField(
                    controller: _dob,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date of birth *',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: _pickDate,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Pick a date';
                      final dob = DateTime.parse(v);
                      final age = DateTime.now().difference(dob).inDays ~/ 365;
                      return age < 18 ? 'Must be 18+' : null;
                    },
                  ),
                  TextFormField(
                    controller: _time,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Preferred shift start',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
          ),
          Section(
            title: 'Choices',
            subtitle: 'Radio, segmented button, filter chips, slider, switch, checkbox',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Role', style: Theme.of(context).textTheme.labelLarge),
                RadioGroup<Role>(
                  groupValue: _role,
                  onChanged: (v) => setState(() => _role = v!),
                  child: Wrap(
                    children: [
                      for (final r in Role.values)
                        SizedBox(
                          width: 180,
                          child: RadioListTile<Role>(
                            value: r,
                            title: Text(
                              r.name[0].toUpperCase() + r.name.substring(1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                gap,
                Text('Shift', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Morning',
                      icon: Icon(Icons.wb_sunny_outlined),
                      label: Text('Morning'),
                    ),
                    ButtonSegment(
                      value: 'Evening',
                      icon: Icon(Icons.wb_twilight),
                      label: Text('Evening'),
                    ),
                    ButtonSegment(
                      value: 'Night',
                      icon: Icon(Icons.nightlight_outlined),
                      label: Text('Night'),
                    ),
                  ],
                  selected: {_shift},
                  onSelectionChanged: (s) => setState(() => _shift = s.first),
                ),
                gap,
                // Custom FormField: validates chip selection.
                FormField<Set<String>>(
                  key: ValueKey('interests$_formVersion'),
                  initialValue: const {},
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Pick at least one interest'
                      : null,
                  onSaved: (v) => _lastInterests = v ?? {},
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interests *',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final i in _interests)
                            FilterChip(
                              label: Text(i),
                              selected: field.value!.contains(i),
                              onSelected: (sel) {
                                final next = {...field.value!};
                                sel ? next.add(i) : next.remove(i);
                                field.didChange(next);
                              },
                            ),
                        ],
                      ),
                      if (field.hasError) _ErrorText(field.errorText!),
                    ],
                  ),
                ),
                gap,
                Text(
                  'Experience: ${_experience.round()} years',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Slider(
                  value: _experience,
                  max: 20,
                  divisions: 20,
                  label: '${_experience.round()}',
                  onChanged: (v) => setState(() => _experience = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Subscribe to newsletter'),
                  value: _newsletter,
                  onChanged: (v) => setState(() => _newsletter = v),
                ),
                FormField<bool>(
                  key: ValueKey('terms$_formVersion'),
                  initialValue: false,
                  validator: (v) =>
                      v == true ? null : 'You must accept the terms',
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('I accept the terms & conditions *'),
                        value: field.value,
                        isError: field.hasError,
                        onChanged: field.didChange,
                      ),
                      if (field.hasError) _ErrorText(field.errorText!),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send),
                label: const Text('Submit'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 12),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
