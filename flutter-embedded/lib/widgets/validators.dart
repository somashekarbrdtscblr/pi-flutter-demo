/// Reusable form validators. Return null when valid, error message otherwise.
class Validators {
  static final _emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final _phoneRe = RegExp(r'^\+?[0-9]{10,13}$');

  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    return _emailRe.hasMatch(v.trim()) ? null : 'Enter a valid email';
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone is required';
    return _phoneRe.hasMatch(v.trim()) ? null : 'Enter 10-13 digits';
  }

  static String? minLength(String? v, int min, [String field = 'Value']) {
    if (v == null || v.isEmpty) return '$field is required';
    return v.length < min ? '$field must be at least $min characters' : null;
  }

  static String? number(String? v, {num? min, num? max, String field = 'Value'}) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    final n = num.tryParse(v.trim());
    if (n == null) return '$field must be a number';
    if (min != null && n < min) return '$field must be ≥ $min';
    if (max != null && n > max) return '$field must be ≤ $max';
    return null;
  }
}
