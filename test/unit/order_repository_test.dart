// ignore_for_file: subtype_of_sealed_class

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:handwerker_app/core/utils/app_exception.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/repositories/order_repository.dart';
import 'package:handwerker_app/data/services/api_service.dart';

import 'order_repository_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late MockApiService mockApi;
  late OrderRepository repository;

  setUp(() {
    mockApi = MockApiService();
    repository = OrderRepository(mockApi);
  });

  // ── fetchServiceCategories ───────────────────────────────────────────────

  group('fetchServiceCategories', () {
    test('returns list of categories on success', () async {
      when(mockApi.getServiceCategories()).thenAnswer(
        (_) async => Response(
          data: [
            {
              'id': '550e8400-e29b-41d4-a716-446655440000',
              'nameDE': 'Sanitär',
              'nameEN': 'Plumbing',
              'active': true,
            },
            {
              'id': '550e8400-e29b-41d4-a716-446655440001',
              'nameDE': 'Elektrik',
              'nameEN': 'Electrical',
              'active': true,
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/service-categories'),
        ),
      );

      final result = await repository.fetchServiceCategories();

      expect(result, hasLength(2));
      expect(result[0].id, '550e8400-e29b-41d4-a716-446655440000');
      expect(result[0].nameDE, 'Sanitär');
      expect(result[1].id, '550e8400-e29b-41d4-a716-446655440001');
    });

    test('wraps response in data key if backend returns pagination', () async {
      when(mockApi.getServiceCategories()).thenAnswer(
        (_) async => Response(
          data: {
            'data': [
              {'id': 'abc-123', 'nameDE': 'Heizung', 'active': true}
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/service-categories'),
        ),
      );

      final result = await repository.fetchServiceCategories();
      expect(result, hasLength(1));
      expect(result[0].id, 'abc-123');
    });

    test('throws NetworkException when no response', () async {
      when(mockApi.getServiceCategories()).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/service-categories'),
          message: 'No internet',
        ),
      );

      expect(
        () => repository.fetchServiceCategories(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws UnauthorizedException on 401', () async {
      when(mockApi.getServiceCategories()).thenThrow(
        DioException(
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/service-categories'),
          ),
          requestOptions: RequestOptions(path: '/service-categories'),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => repository.fetchServiceCategories(),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  // ── createOrder ──────────────────────────────────────────────────────────

  group('createOrder', () {
    final validRequest = CreateOrderRequest(
      serviceCategoryId: '550e8400-e29b-41d4-a716-446655440000',
      requestType: RequestType.immediate,
      descriptionText: 'Wasserrohr gebrochen',
      lat: 32.0853,
      lng: 34.7818,
      addressEncrypted: 'ENCRYPTED_TEST_VALUE',
      scheduledAt: null,
    );

    test('returns Order on success', () async {
      when(mockApi.createOrder(any)).thenAnswer(
        (_) async => Response(
          data: {
            'id': 'order-uuid-001',
            'orderNumber': 'ORD-2026-001',
            'status': 'REQUEST_CREATED',
            'serviceCategoryId': '550e8400-e29b-41d4-a716-446655440000',
            'requestType': 'IMMEDIATE',
            'lat': 32.0853,
            'lng': 34.7818,
            'createdAt': '2026-03-24T10:00:00.000Z',
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/orders'),
        ),
      );

      final order = await repository.createOrder(validRequest);

      expect(order.id, 'order-uuid-001');
      expect(order.orderNumber, 'ORD-2026-001');
    });

    test('sends exact DTO fields to API', () async {
      when(mockApi.createOrder(any)).thenAnswer(
        (_) async => Response(
          data: {'id': 'x', 'status': 'REQUEST_CREATED'},
          statusCode: 201,
          requestOptions: RequestOptions(path: '/orders'),
        ),
      );

      await repository.createOrder(validRequest);

      final captured =
          verify(mockApi.createOrder(captureAny)).captured.single as Map;

      expect(captured['serviceCategoryId'],
          '550e8400-e29b-41d4-a716-446655440000');
      expect(captured['requestType'], 'IMMEDIATE');
      expect(captured['descriptionText'], 'Wasserrohr gebrochen');
      expect(captured['lat'], 32.0853);
      expect(captured['lng'], 34.7818);
      expect(captured['addressEncrypted'], 'ENCRYPTED_TEST_VALUE');
      expect(captured['scheduledAt'], isNull);
    });

    test('throws UnauthorizedException on 401', () async {
      when(mockApi.createOrder(any)).thenThrow(
        DioException(
          response: Response(
            statusCode: 401,
            data: {'message': 'Unauthorized'},
            requestOptions: RequestOptions(path: '/orders'),
          ),
          requestOptions: RequestOptions(path: '/orders'),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => repository.createOrder(validRequest),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('throws ForbiddenException on 403', () async {
      when(mockApi.createOrder(any)).thenThrow(
        DioException(
          response: Response(
            statusCode: 403,
            data: {'message': 'Forbidden'},
            requestOptions: RequestOptions(path: '/orders'),
          ),
          requestOptions: RequestOptions(path: '/orders'),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => repository.createOrder(validRequest),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('throws NotFoundException on 404 with detail message', () async {
      when(mockApi.createOrder(any)).thenThrow(
        DioException(
          response: Response(
            statusCode: 404,
            data: {
              'detail':
                  'Service category 550e8400-e29b-41d4-a716-446655440000 not found'
            },
            requestOptions: RequestOptions(path: '/orders'),
          ),
          requestOptions: RequestOptions(path: '/orders'),
          type: DioExceptionType.badResponse,
        ),
      );

      Object? exception;
      try {
        await repository.createOrder(validRequest);
      } catch (e) {
        exception = e;
      }

      expect(exception, isA<NotFoundException>());
      expect((exception as NotFoundException).detail, contains('not found'));
    });

    test('throws ValidationException on 422 with field errors', () async {
      when(mockApi.createOrder(any)).thenThrow(
        DioException(
          response: Response(
            statusCode: 422,
            data: {
              'message': 'Validation failed',
              'errors': {
                'serviceCategoryId': 'Invalid UUID',
                'lat': 'Must be between -90 and 90',
              }
            },
            requestOptions: RequestOptions(path: '/orders'),
          ),
          requestOptions: RequestOptions(path: '/orders'),
          type: DioExceptionType.badResponse,
        ),
      );

      Object? exception;
      try {
        await repository.createOrder(validRequest);
      } catch (e) {
        exception = e;
      }

      expect(exception, isA<ValidationException>());
      final ve = exception as ValidationException;
      expect(ve.errors['serviceCategoryId'], 'Invalid UUID');
      expect(ve.errors['lat'], 'Must be between -90 and 90');
    });

    test('throws ValidationException when lat is NaN', () async {
      final badRequest = CreateOrderRequest(
        serviceCategoryId: 'uuid',
        requestType: RequestType.immediate,
        lat: double.nan,
        lng: 34.7818,
        addressEncrypted: 'enc',
      );

      expect(
        () => repository.createOrder(badRequest),
        throwsA(isA<ValidationException>()),
      );
      verifyNever(mockApi.createOrder(any));
    });

    test('throws ValidationException for SCHEDULED order without scheduledAt',
        () async {
      final scheduledNoDate = CreateOrderRequest(
        serviceCategoryId: 'uuid',
        requestType: RequestType.scheduled,
        lat: 32.0,
        lng: 34.7,
        addressEncrypted: 'enc',
        scheduledAt: null,
      );

      expect(
        () => repository.createOrder(scheduledNoDate),
        throwsA(isA<ValidationException>()),
      );
      verifyNever(mockApi.createOrder(any));
    });
  });
}


