import 'package:flutter_test/flutter_test.dart';
import 'package:handwerker_app/core/utils/validators.dart';
import 'package:handwerker_app/core/extensions/extensions.dart';
import 'package:handwerker_app/data/models/models.dart';

void main() {
  group('Validators', () {
    group('phone', () {
      test('accepts valid German number', () {
        expect(Validators.phone('+4915112345678'), isNull);
      });

      test('rejects empty', () {
        expect(Validators.phone(''), isNotNull);
        expect(Validators.phone(null), isNotNull);
      });

      test('rejects without country code', () {
        expect(Validators.phone('015112345678'), isNotNull);
      });

      test('rejects too short', () {
        expect(Validators.phone('+491'), isNotNull);
      });
    });

    group('otp', () {
      test('accepts 6 digits', () {
        expect(Validators.otp('123456'), isNull);
      });

      test('rejects 5 digits', () {
        expect(Validators.otp('12345'), isNotNull);
      });

      test('rejects letters', () {
        expect(Validators.otp('12345a'), isNotNull);
      });
    });

    group('price', () {
      test('accepts valid price', () {
        expect(Validators.price('59.99'), isNull);
      });

      test('rejects zero', () {
        expect(Validators.price('0'), isNotNull);
      });

      test('rejects negative', () {
        expect(Validators.price('-10'), isNotNull);
      });

      test('respects minimum bound', () {
        expect(Validators.price('5', min: 10), isNotNull);
        expect(Validators.price('15', min: 10), isNull);
      });

      test('respects maximum bound', () {
        expect(Validators.price('500', max: 300), isNotNull);
        expect(Validators.price('200', max: 300), isNull);
      });

      test('handles German comma notation', () {
        expect(Validators.price('59,99'), isNull);
      });
    });

    group('eta', () {
      test('accepts valid minutes', () {
        expect(Validators.eta('15'), isNull);
      });

      test('rejects zero', () {
        expect(Validators.eta('0'), isNotNull);
      });

      test('rejects over 8 hours', () {
        expect(Validators.eta('500'), isNotNull);
      });
    });

    group('payoutAmount', () {
      test('rejects under 10', () {
        expect(Validators.payoutAmount('5'), isNotNull);
      });

      test('accepts 10', () {
        expect(Validators.payoutAmount('10'), isNull);
      });

      test('rejects over balance', () {
        expect(Validators.payoutAmount('100', maxBalance: 50), isNotNull);
      });
    });

    group('postalCode', () {
      test('accepts 5-digit German PLZ', () {
        expect(Validators.postalCode('66111'), isNull);
      });

      test('rejects 4 digits', () {
        expect(Validators.postalCode('6611'), isNotNull);
      });

      test('rejects letters', () {
        expect(Validators.postalCode('66AB1'), isNotNull);
      });
    });

    group('iban', () {
      test('accepts valid IBAN', () {
        expect(Validators.iban('DE89370400440532013000'), isNull);
      });

      test('rejects too short', () {
        expect(Validators.iban('DE89'), isNotNull);
      });
    });
  });

  group('String extensions', () {
    test('capitalized', () {
      expect('hello'.capitalized, 'Hello');
      expect(''.capitalized, '');
    });

    test('initials', () {
      expect('Max Müller'.initials, 'MM');
      expect('Hans'.initials, 'H');
    });

    test('truncate', () {
      expect('Hello World'.truncate(5), 'Hello...');
      expect('Hi'.truncate(5), 'Hi');
    });

    test('isValidPhone', () {
      expect('+4915112345678'.isValidPhone, isTrue);
      expect('0151123'.isValidPhone, isFalse);
    });

    test('isValidEmail', () {
      expect('test@example.com'.isValidEmail, isTrue);
      expect('notanemail'.isValidEmail, isFalse);
    });
  });

  group('DateTime extensions', () {
    test('formatted', () {
      final dt = DateTime(2025, 3, 15);
      expect(dt.formatted, '15.03.2025');
    });

    test('timeOnly', () {
      final dt = DateTime(2025, 1, 1, 14, 5);
      expect(dt.timeOnly, '14:05');
    });

    test('isToday', () {
      expect(DateTime.now().isToday, isTrue);
      expect(
        DateTime.now().subtract(const Duration(days: 1)).isToday,
        isFalse,
      );
    });
  });

  group('Double extensions', () {
    test('asCurrency', () {
      expect(59.99.asCurrency, '€59.99');
    });

    test('asKm', () {
      expect(3.5.asKm, '3.5 km');
    });
  });

  group('OrderStatus extensions', () {
    test('canCancel', () {
      expect(OrderStatus.requestCreated.canCancel, isTrue);
      expect(OrderStatus.matching.canCancel, isTrue);
      expect(OrderStatus.craftsmanAssigned.canCancel, isFalse);
    });

    test('canDispute', () {
      expect(OrderStatus.paymentCaptured.canDispute, isTrue);
      expect(OrderStatus.jobInProgress.canDispute, isFalse);
    });
  });

  group('Models', () {
    test('Order.isActive', () {
      final active = Order(status: OrderStatus.jobInProgress);
      expect(active.isActive, isTrue);

      final closed = Order(status: OrderStatus.orderClosed);
      expect(closed.isActive, isFalse);

      final cancelled = Order(status: OrderStatus.cancelled);
      expect(cancelled.isActive, isFalse);
    });

    test('Order.statusLabel returns German', () {
      final order = Order(status: OrderStatus.craftsmanOnTheWay);
      expect(order.statusLabel, 'Handwerker unterwegs');
    });

    test('Proposal.priceFormatted', () {
      final p = Proposal(price: 89.50);
      expect(p.priceFormatted, '€89.50');
    });

    test('ServiceCategory.priceRange', () {
      final cat = ServiceCategory(priceMin: 50, priceMax: 200);
      expect(cat.priceRange, '€50 – €200');
    });

    test('CustomerProfile.isComplete', () {
      final complete = CustomerProfile(
        firstName: 'Max',
        lastName: 'Müller',
        address: Address(street: 'Musterstr. 1'),
      );
      expect(complete.isComplete, isTrue);

      final incomplete = CustomerProfile(firstName: 'Max');
      expect(incomplete.isComplete, isFalse);
    });

    test('Rating.average', () {
      final r = Rating(
        quality: 5,
        punctuality: 4,
        professionalism: 5,
        value: 4,
      );
      expect(r.average, 4.5);
    });

    test('AppNotification.isRead', () {
      final unread = AppNotification(readAt: null);
      expect(unread.isRead, isFalse);

      final read = AppNotification(readAt: DateTime.now());
      expect(read.isRead, isTrue);
    });
  });
}
