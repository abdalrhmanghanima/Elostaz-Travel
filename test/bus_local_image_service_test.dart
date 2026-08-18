import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:elostaz_travel/core/services/bus_local_image_service.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;
  FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bus_local_image_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BusLocalImageService Tests', () {
    test('saveBusImage and getBusImage persist and retrieve correctly', () async {
      final service = BusLocalImageService.instance;
      final sourceFile = File('${tempDir.path}/source_bus.jpg');
      await sourceFile.writeAsString('sample_bus_image_content');

      final savedFile = await service.saveBusImage('bus_123', sourceFile);
      expect(savedFile, isNotNull);
      expect(await savedFile!.exists(), isTrue);

      final retrievedFile = await service.getBusImage('bus_123');
      expect(retrievedFile, isNotNull);
      expect(await retrievedFile!.readAsString(), 'sample_bus_image_content');
    });

    test('saveLicenseImage and getLicenseImage persist and retrieve correctly', () async {
      final service = BusLocalImageService.instance;
      final sourceFile = File('${tempDir.path}/source_license.jpg');
      await sourceFile.writeAsString('sample_license_image_content');

      final savedFile = await service.saveLicenseImage('bus_123', sourceFile);
      expect(savedFile, isNotNull);
      expect(await savedFile!.exists(), isTrue);

      final retrievedFile = await service.getLicenseImage('bus_123');
      expect(retrievedFile, isNotNull);
      expect(await retrievedFile!.readAsString(), 'sample_license_image_content');
    });

    test('deleteBusImages removes both bus and license local files', () async {
      final service = BusLocalImageService.instance;
      final busSource = File('${tempDir.path}/temp_b.jpg')..writeAsStringSync('bus');
      final licSource = File('${tempDir.path}/temp_l.jpg')..writeAsStringSync('lic');

      await service.saveBusImage('bus_456', busSource);
      await service.saveLicenseImage('bus_456', licSource);

      expect(await service.getBusImage('bus_456'), isNotNull);
      expect(await service.getLicenseImage('bus_456'), isNotNull);

      await service.deleteBusImages('bus_456');

      expect(await service.getBusImage('bus_456'), isNull);
      expect(await service.getLicenseImage('bus_456'), isNull);
    });
  });
}
