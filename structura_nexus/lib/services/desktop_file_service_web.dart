// Web fallback for Desktop File Service
import 'desktop_file_service_stub.dart';
export 'desktop_file_service_stub.dart';

class DesktopFilePlatformWeb implements DesktopFilePlatform {
  @override
  bool get isDesktopPlatform => false;

  @override
  Future<String?> openModelFile() async {
    return null;
  }

  @override
  Future<bool> saveProjectFile(String fileName, String content) async {
    return true;
  }

  @override
  Future<String> exportDeliverable({
    required String fileName,
    required String content,
    required String fileType,
  }) async {
    return 'Web In-Memory Deliverable ($fileName.$fileType)';
  }
}

DesktopFilePlatform getDesktopFilePlatform() => DesktopFilePlatformWeb();
