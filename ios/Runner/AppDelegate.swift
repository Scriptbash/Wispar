import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  var pickerDelegate: FolderPickerDelegate?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "app.wispar.wispar/database_access",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    channel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard let self = self else { return }

      switch call.method {
      case "getExportDirectory":
        // Temporary access for export/import path selection
        self.presentDocumentPicker(
          for: .folder,
          completion: { path in
            result(path)
          })
      case "selectCustomDatabasePath":
        // Persistent access, returns Base64 bookmark string
        self.presentDocumentPicker(
          for: .folder,
          completion: { bookmarkString in
            result(bookmarkString)
          })
      case "startSecurityScopedAccess":
        guard let path = call.arguments as? String else {
          result(false)
          return
        }
        result(self.startSecurityScopedAccess(for: path))

      case "stopSecurityScopedAccess":
        guard let path = call.arguments as? String else {
          result(false)
          return
        }
        result(self.stopSecurityScopedAccess(for: path))
      case "resolveCustomPath":
        // Resolve the bookmark path for persistent access
        guard let bookmarkString = call.arguments as? String else {
          result(nil)
          return
        }
        result(self.resolvePathFromBookmark(bookmarkString: bookmarkString))

      default:
        result(FlutterMethodNotImplemented)
      }
    })
  }

  private func presentDocumentPicker(
    for contentType: UTType, completion: @escaping (String?) -> Void
  ) {
    if #available(iOS 14.0, *) {
      let documentPicker = UIDocumentPickerViewController(
        forOpeningContentTypes: [contentType], asCopy: false)
      documentPicker.allowsMultipleSelection = false

      let delegate = FolderPickerDelegate()
      delegate.pickerCompletionHandler = completion
      self.pickerDelegate = delegate
      documentPicker.delegate = delegate

      documentPicker.directoryURL = nil
      documentPicker.shouldShowFileExtensions = true

      guard
        let rootViewController = UIApplication.shared.connectedScenes
          .compactMap({ $0 as? UIWindowScene })
          .flatMap({ $0.windows })
          .first(where: { $0.isKeyWindow })?.rootViewController
      else {

        print("Error: Could not find the active root view controller.")
        completion(nil)
        return
      }

      rootViewController.present(documentPicker, animated: true, completion: nil)

    } else {
      completion(nil)
    }
  }

  private func resolvePathFromBookmark(bookmarkString: String) -> String? {
    guard let bookmarkData = Data(base64Encoded: bookmarkString) else {
      print("Error: Could not decode Base64 bookmark string.")
      return nil
    }

    var isStale = false
    do {
      let restoredURL = try URL(
        resolvingBookmarkData: bookmarkData,
        options: [.withoutUI],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
      if isStale {
        print("Bookmark data was stale. User must re-select the folder.")
        return nil
      }
      if restoredURL.startAccessingSecurityScopedResource() {
        return restoredURL.path
      } else {
        print("Failed to start accessing security-scoped resource with restored URL.")
        return nil
      }
    } catch {
      print("Error resolving bookmark: \(error)")
      return nil
    }
  }

  private func startSecurityScopedAccess(for path: String) -> Bool {
    let url = URL(fileURLWithPath: path)
    return url.startAccessingSecurityScopedResource()
  }

  private func stopSecurityScopedAccess(for path: String) -> Bool {
    let url = URL(fileURLWithPath: path)
    url.stopAccessingSecurityScopedResource()
    return true
  }
}
