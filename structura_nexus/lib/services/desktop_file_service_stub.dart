// Stub interface for desktop file service
abstract class DesktopFilePlatform {
  bool get isDesktopPlatform;
  Future<String?> openModelFile();
  Future<bool> saveProjectFile(String fileName, String content);
  Future<String> exportDeliverable({
    required String fileName,
    required String content,
    required String fileType,
  });
}

DesktopFilePlatform getDesktopFilePlatform() =>
    throw UnsupportedError('Cannot create DesktopFilePlatform without io or html/js_interop');

