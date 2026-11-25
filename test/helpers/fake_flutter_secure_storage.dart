import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

FlutterSecureStorage createInMemorySecureStorage([Map<String, String>? initialData]) {
  final storage = MockFlutterSecureStorage();
  final map = <String, String>{...?initialData};

  when(() => storage.read(key: any(named: 'key'))).thenAnswer((invocation) async {
    final key = invocation.namedArguments[#key] as String;
    return map[key];
  });

  when(() => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((invocation) async {
    final key = invocation.namedArguments[#key] as String;
    final value = invocation.namedArguments[#value] as String?;
    if (value != null) {
      map[key] = value;
    } else {
      map.remove(key);
    }
  });

  when(() => storage.delete(key: any(named: 'key'))).thenAnswer((invocation) async {
    final key = invocation.namedArguments[#key] as String;
    map.remove(key);
  });

  when(() => storage.readAll()).thenAnswer((_) async => Map.unmodifiable(map));

  return storage;
}
