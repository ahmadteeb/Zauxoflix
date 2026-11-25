import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = registrar(forPlugin: "ZauxoflixDownloadStorage") {
      FlutterMethodChannel(
        name: "zauxoflix/download_storage",
        binaryMessenger: registrar.messenger()
      ).setMethodCallHandler { call, result in
        guard call.method == "freeBytes" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let path = call.arguments as? String else {
          result(nil)
          return
        }
        let attributes = try? FileManager.default.attributesOfFileSystem(forPath: path)
        result((attributes?[.systemFreeSize] as? NSNumber)?.int64Value)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
