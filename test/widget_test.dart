import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack_app/models/models.dart';
import 'package:fintrack_app/state/app_state.dart';

void main() {
  test('formato de pesos colombianos', () {
    expect(money(63350), r'$ 63.350');
    expect(money(-3500), r'-$ 3.500');
    expect(money(120000, sign: true), r'+$ 120.000');
  });

  test('clasificación de gastos', () {
    expect(classify('Alimentos', 3500), kHormiga);
    expect(classify('Alimentos', 20000), kHormiga);
    expect(classify('Transporte', 25000), kNecesario);
    expect(classify('Hogar', 400000), kFijo);
  });
}
