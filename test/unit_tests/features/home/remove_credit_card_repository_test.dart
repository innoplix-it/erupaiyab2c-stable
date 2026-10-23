import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/constants/api_constants.dart';
import 'package:e_rupaiya/features/home/models/credit_card_item.dart';
import 'package:e_rupaiya/features/home/models/home_state.dart';
import 'package:e_rupaiya/features/home/controllers/home_controller.dart';
import 'package:e_rupaiya/features/home/repositories/home_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? options;
  int statusCode = 200;
  String body = '{"success":true}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    this.options = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RemoveRepo extends HomeRepository {
  _RemoveRepo() : super(dio: Dio());

  final calls = <String>[];
  bool succeed = false;

  @override
  Future<bool> removeCreditCard(String maskedIdentifier) async {
    calls.add(maskedIdentifier);
    if (!succeed) throw Exception('remove failed');
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('POST /api/remove-card sends only that card masked_identifier',
      () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = HomeRepository(dio: dio);

    final ok = await repository.removeCreditCard('****2656');

    expect(ok, isTrue);
    final request = adapter.options;
    expect(request, isNotNull);
    expect(request!.method, 'POST');
    expect(request.uri.toString(), ApiConstants.removeCardEndpoint);
    final body = request.data is String
        ? jsonDecode(request.data as String) as Map<String, dynamic>
        : Map<String, dynamic>.from(request.data as Map);
    expect(body, {'masked_identifier': '****2656'});
  });

  test('failed remove does not report success', () async {
    final adapter = _CaptureAdapter()
      ..statusCode = 200
      ..body = '{"success":false,"message":"Card not found"}';
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = HomeRepository(dio: dio);

    final ok = await repository.removeCreditCard('****9513');

    expect(ok, isFalse);
    final body = Map<String, dynamic>.from(adapter.options!.data as Map);
    expect(body, {'masked_identifier': '****9513'});
  });

  test('controller keeps the card list when remove fails', () async {
    final repo = _RemoveRepo();
    final controller = HomeController(repository: repo);
    const kept = [
      CreditCardItem(
        billerName: 'HSBC Credit Card',
        maskedIdentifier: '****9513',
      ),
      CreditCardItem(
        billerName: 'Saraswat Co-Operative Bank Ltd',
        maskedIdentifier: '****2656',
      ),
    ];
    controller.state = const HomeState(creditCardActions: kept);

    final ok = await controller.removeCreditCard('****2656');

    expect(ok, isFalse);
    expect(repo.calls, ['****2656']);
    expect(
      controller.state.creditCardActions
          ?.map((card) => card.maskedIdentifier)
          .toList(),
      ['****9513', '****2656'],
    );
    expect(controller.state.isFetchingCreditCards, isFalse);
  });

  test('a second remove while one is running does not post again', () async {
    final repo = _RemoveRepo();
    final controller = HomeController(repository: repo);
    controller.state = const HomeState(
      creditCardActions: [
        CreditCardItem(maskedIdentifier: '****2656'),
      ],
    );

    final first = controller.removeCreditCard('****2656');
    final second = controller.removeCreditCard('****9513');
    final results = await Future.wait([first, second]);

    expect(repo.calls, ['****2656']);
    expect(results, [isFalse, isFalse]);
  });
}
