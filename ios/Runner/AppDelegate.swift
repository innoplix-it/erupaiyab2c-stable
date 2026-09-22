import Flutter
import UIKit
import Firebase
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "com.innoplix.erupaiya/screen_security"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    if #available(iOS 11.0, *) {
      if let controller = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(
          name: channelName,
          binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
          switch call.method {
          case "enableSecure":
            self?.setSecureOverlay(enabled: true)
            result(nil)
          case "disableSecure":
            self?.setSecureOverlay(enabled: false)
            result(nil)
          default:
            result(FlutterMethodNotImplemented)
          }
        }
        setSecureOverlay(enabled: true)
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    return .portrait
  }

  private func setSecureOverlay(enabled: Bool) {
    guard let window = window else { return }
    let tag = 99999
    if enabled {
      if window.viewWithTag(tag) != nil { return }
      let overlay = UIView(frame: window.bounds)
      overlay.backgroundColor = .white
      overlay.tag = tag
      overlay.isUserInteractionEnabled = false
      window.addSubview(overlay)
    } else {
      window.viewWithTag(tag)?.removeFromSuperview()
    }
  }
}
