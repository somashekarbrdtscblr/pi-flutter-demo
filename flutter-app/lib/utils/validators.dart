import 'package:flutter/widgets.dart';

/// Reusable form validators. Each returns null when valid, else an error string.
abstract final class Validators {
  static final _emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static FormFieldValidator<String> required([String field = 'This field']) =>
      (v) => (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!_emailRe.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  static FormFieldValidator<String> minLength(
    int n, [
    String field = 'Value',
  ]) =>
      (v) => (v == null || v.trim().length < n)
      ? '$field must be at least $n characters'
      : null;

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'At least 6 characters';
    if (!RegExp(r'\d').hasMatch(v)) return 'Must contain a number';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.isEmpty) return 'Phone is required';
    if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Enter 10 digits';
    return null;
  }

  static FormFieldValidator<String> numberRange(
    num min,
    num max, [
    String field = 'Value',
  ]) => (v) {
    final n = num.tryParse(v ?? '');
    if (n == null) return '$field must be a number';
    if (n < min || n > max) return '$field must be $min–$max';
    return null;
  };

  /// Runs validators in order and returns the first error.
  static FormFieldValidator<String> combine(
    List<FormFieldValidator<String>> validators,
  ) => (v) {
    for (final validate in validators) {
      final error = validate(v);
      if (error != null) return error;
    }
    return null;
  };
}
