// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:hams/core/identity/name_generator.dart';

void main() {
  test('generated names use the exact adjective noun format', () {
    final generator = NameGenerator();
    for (var i = 0; i < 500; i++) {
      final name = generator.generate();
      final parts = name.split(' ');
      expect(parts, hasLength(2));
      expect(adjectives, contains(parts[0]));
      expect(nouns, contains(parts[1]));
      expect(NameValidator.validate(name), isNull);
    }
  });

  test('rename validation normalizes whitespace and rejects excluded themes', () {
    expect(NameValidator.normalize('  Gentle   Mango '), 'Gentle Mango');
    expect(NameValidator.validate('Gentle   Mango'), isNull);
    expect(NameValidator.validate('Lucky Dog'), isNotNull);
    expect(NameValidator.validate('a' * 25), isNotNull);
    expect(NameValidator.validate('Name!'), isNotNull);
  });
}
