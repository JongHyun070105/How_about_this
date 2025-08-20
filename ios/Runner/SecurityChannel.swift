
import Foundation
import Flutter

class SecurityChannel {
    static let shared = SecurityChannel()
    let channelName = "security_channel"

    func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
        
        channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "getBundleIdentifier":
                result(self.getBundleIdentifier())
            case "isAppStoreVersion":
                result(self.isAppStoreVersion())
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func getBundleIdentifier() -> String? {
        return Bundle.main.bundleIdentifier
    }

    private func isAppStoreVersion() -> Bool {
        #if DEBUG
        // Debug builds are not from the App Store
        return false
        #else
        // Check for the App Store receipt
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
            // This is a good indicator of an App Store build
            return true
        }
        return false
        #endif
    }
}
