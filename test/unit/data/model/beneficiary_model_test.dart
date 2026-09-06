import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/data/model/beneficiary_model.dart';

BeneficiaryModel _nomme(String name) => BeneficiaryModel.create(name: name);

void main() {
  group("les initiales d'un bénéficiaire", () {
    test('prennent la première lettre des deux premiers mots', () {
      expect(_nomme('Jean Dupont').initials, 'JD');
    });

    test('traitent un trait d\'union comme une séparation', () {
      expect(_nomme('Jean-Marc').initials, 'JM');
    });

    test('ignorent les espaces multiples', () {
      expect(_nomme('  Jean   Dupont  ').initials, 'JD');
    });

    test('sur un seul mot, gardent les deux premières lettres', () {
      expect(_nomme('marc').initials, 'Ma');
    });

    test('sur une seule lettre, la mettent en majuscule', () {
      expect(_nomme('m').initials, 'M');
    });

    test('sur un nom vide, valent un point d\'interrogation', () {
      expect(_nomme('').initials, '?');
      expect(_nomme('   ').initials, '?');
    });
  });
}
