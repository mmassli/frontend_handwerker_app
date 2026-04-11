// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:handwerker_app/core/utils/app_exception.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';
import 'package:handwerker_app/data/repositories/order_repository.dart';

import 'create_order_notifier_test.mocks.dart';

@GenerateMocks([OrderRepository])
void main() {
  late MockOrderRepository mockRepo;
  late ProviderContainer container;

  // Helper – builds a valid request for reuse across tests
  CreateOrderRequest makeRequest() => const CreateOrderRequest(
        serviceCategoryId: '550e8400-e29b-41d4-a716-446655440000',
        requestType: RequestType.immediate,
        description: 'Wasserschaden',
        location: AddressInput(
          street: 'Musterstr. 1',
          city: 'Berlin',
          postalCode: '10115',
          latitude: 32.0853,
          longitude: 34.7818,
        ),
      );

  setUp(() {
    mockRepo = MockOrderRepository();
    container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  // ── Initial state ──────────────────────────────────────────────────────

  test('initial state is empty, not loading', () {
    final state = container.read(createOrderProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.createdOrder, isNull);
  });

  // ── Happy path ─────────────────────────────────────────────────────────

  test('sets createdOrder on success', () async {
    final fakeOrder = Order(
      id: 'order-1',
      orderNumber: 'ORD-2026-001',
      status: OrderStatus.requestCreated,
    );

    when(mockRepo.createOrder(any)).thenAnswer((_) async => fakeOrder);

    await container.read(createOrderProvider.notifier).submit(makeRequest());

    final state = container.read(createOrderProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.createdOrder?.id, 'order-1');
    expect(state.createdOrder?.orderNumber, 'ORD-2026-001');
  });

  // ── Loading state ──────────────────────────────────────────────────────

  test('sets isLoading while request is in-flight', () async {
    final completer = Completer<Order>();
    when(mockRepo.createOrder(any))
        .thenAnswer((_) async => completer.future);

    // Don't await yet — we want to inspect the loading state mid-flight
    final future =
        container.read(createOrderProvider.notifier).submit(makeRequest());

    expect(container.read(createOrderProvider).isLoading, isTrue);

    // Now let the repository call complete
    completer.complete(Order(id: 'x'));
    await future;

    expect(container.read(createOrderProvider).isLoading, isFalse);
  });

  // ── Error mapping ──────────────────────────────────────────────────────

  test('sets UnauthorizedException in state on 401', () async {
    when(mockRepo.createOrder(any)).thenThrow(const UnauthorizedException());

    await container.read(createOrderProvider.notifier).submit(makeRequest());

    final state = container.read(createOrderProvider);
    expect(state.isLoading, isFalse);
    expect(state.createdOrder, isNull);
    expect(state.error, isA<UnauthorizedException>());
  });

  test('sets ForbiddenException in state on 403', () async {
    when(mockRepo.createOrder(any)).thenThrow(const ForbiddenException());

    await container.read(createOrderProvider.notifier).submit(makeRequest());

    expect(container.read(createOrderProvider).error, isA<ForbiddenException>());
  });

  test('sets ValidationException in state on 422', () async {
    when(mockRepo.createOrder(any)).thenThrow(
      const ValidationException(
        errors: {'serviceCategoryId': 'Invalid UUID'},
        detail: 'Validation failed',
      ),
    );

    await container.read(createOrderProvider.notifier).submit(makeRequest());

    final state = container.read(createOrderProvider);
    expect(state.error, isA<ValidationException>());
    final ve = state.error as ValidationException;
    expect(ve.errors['serviceCategoryId'], 'Invalid UUID');
  });

  test('wraps unknown exception in NetworkException', () async {
    when(mockRepo.createOrder(any)).thenThrow(Exception('unexpected error'));

    await container.read(createOrderProvider.notifier).submit(makeRequest());

    expect(container.read(createOrderProvider).error, isA<NetworkException>());
  });

  // ── Reset ──────────────────────────────────────────────────────────────

  test('reset() clears state', () async {
    when(mockRepo.createOrder(any)).thenThrow(const UnauthorizedException());

    await container.read(createOrderProvider.notifier).submit(makeRequest());

    expect(container.read(createOrderProvider).error, isNotNull);

    container.read(createOrderProvider.notifier).reset();

    final cleared = container.read(createOrderProvider);
    expect(cleared.error, isNull);
    expect(cleared.isLoading, isFalse);
    expect(cleared.createdOrder, isNull);
  });
}


