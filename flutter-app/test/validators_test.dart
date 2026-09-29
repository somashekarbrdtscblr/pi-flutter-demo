import 'package:flutter_app/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email', () {
    expect(Validators.email(''), 'Email is required');
    expect(Validators.email('nope'), 'Enter a valid email');
    expect(Validators.email('a@b.co'), isNull);
  });

  test('password needs 6 chars and a digit', () {
    expect(Validators.password('abc1'), 'At least 6 characters');
    expect(Validators.password('abcdef'), 'Must contain a number');
    expect(Validators.password('admin123'), isNull);
  });

  test('numberRange', () {
    final v = Validators.numberRange(1, 10, 'Qty');
    expect(v('x'), 'Qty must be a number');
    expect(v('0'), 'Qty must be 1–10');
    expect(v('5'), isNull);
  });

  test('combine returns first error', () {
    final v = Validators.combine([
      Validators.required('Name'),
      Validators.minLength(3, 'Name'),
    ]);
    expect(v(''), 'Name is required');
    expect(v('ab'), 'Name must be at least 3 characters');
    expect(v('abc'), isNull);
  });
}
