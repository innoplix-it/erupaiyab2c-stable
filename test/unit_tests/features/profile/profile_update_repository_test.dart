import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/constants/api_constants.dart';
import 'package:e_rupaiya/features/profile/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? options;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    this.options = options;
    return ResponseBody.fromString(
      '{"success":true,"data":{"id":"1","name":"Ada Lovelace","mobile":"9999999999","email":"ada@example.com","address":"Pune","profile_photo_url":"https://cdn.example/ada.jpg"}}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('profile_update_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Save posts name, email, address and profile_photo', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = ProfileRepository(dio: dio);
    final image = File('${tempDir.path}/avatar.jpg')
      ..writeAsBytesSync([1, 2, 3]);

    final profile = await repository.updateProfile(
      name: 'Ada Lovelace',
      email: 'ada@example.com',
      address: 'Pune',
      image: image,
    );

    final request = adapter.options;
    expect(request, isNotNull);
    expect(request!.method, 'POST');
    expect(request.uri.toString(), ApiConstants.profileUpdateEndpoint);
    final form = request.data as FormData;
    final fields = {for (final field in form.fields) field.key: field.value};
    expect(fields['name'], 'Ada Lovelace');
    expect(fields['email'], 'ada@example.com');
    expect(fields['address'], 'Pune');
    expect(form.files.map((file) => file.key), contains('profile_photo'));
    expect(profile.name, 'Ada Lovelace');
    expect(profile.profilePhotoUrl, 'https://cdn.example/ada.jpg');
  });

  test('details-only save omits profile_photo', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = ProfileRepository(dio: dio);

    await repository.updateProfile(
      name: 'Ada Lovelace',
      email: 'ada@example.com',
      address: 'Pune',
    );

    final form = adapter.options!.data as FormData;
    expect(form.files, isEmpty);
    expect(form.fields.map((field) => field.key),
        containsAll(['name', 'email', 'address']));
  });
}
