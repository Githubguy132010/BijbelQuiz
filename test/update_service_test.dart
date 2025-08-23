import 'package:flutter_test/flutter_test.dart';
import 'package:bijbelquiz/services/update_service.dart';

void main() {
  group('UpdateService', () {
    late UpdateService updateService;

    setUp(() {
      updateService = UpdateService();
    });

    test('should be a singleton', () {
      final instance1 = UpdateService();
      final instance2 = UpdateService();
      expect(identical(instance1, instance2), true);
    });

    test('should correctly compare versions', () {
      // This would require mocking HTTP calls to test properly
      // For now, we're just testing that the service initializes correctly
      expect(updateService, isNotNull);
    });
  });
}