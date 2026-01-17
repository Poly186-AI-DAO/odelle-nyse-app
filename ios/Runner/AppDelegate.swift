import UIKit
import Flutter
import ActivityKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var liveActivityChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        // Set up Live Activity MethodChannel
        if let controller = window?.rootViewController as? FlutterViewController {
            liveActivityChannel = FlutterMethodChannel(
                name: "com.poly186.odellenyse/live_activity",
                binaryMessenger: controller.binaryMessenger
            )
            
            liveActivityChannel?.setMethodCallHandler { [weak self] call, result in
                self?.handleLiveActivityMethod(call: call, result: result)
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func handleLiveActivityMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else {
            result(FlutterError(code: "UNSUPPORTED", message: "Live Activities require iOS 16.1+", details: nil))
            return
        }
        
        switch call.method {
        case "isSupported":
            result(ActivityAuthorizationInfo().areActivitiesEnabled)
            
        case "start":
            guard let args = call.arguments as? [String: Any],
                  let agentType = args["agentType"] as? String,
                  let agentEmoji = args["agentEmoji"] as? String,
                  let agentName = args["agentName"] as? String,
                  let message = args["message"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
                return
            }
            
            startLiveActivity(
                agentType: agentType,
                agentEmoji: agentEmoji,
                agentName: agentName,
                message: message,
                result: result
            )
            
        case "update":
            guard let args = call.arguments as? [String: Any],
                  let agentType = args["agentType"] as? String,
                  let agentEmoji = args["agentEmoji"] as? String,
                  let agentName = args["agentName"] as? String,
                  let message = args["message"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
                return
            }
            
            let isError = args["isError"] as? Bool ?? false
            let isComplete = args["isComplete"] as? Bool ?? false
            
            updateLiveActivity(
                agentType: agentType,
                agentEmoji: agentEmoji,
                agentName: agentName,
                message: message,
                isError: isError,
                isComplete: isComplete,
                result: result
            )
            
        case "end":
            endLiveActivity(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    @available(iOS 16.1, *)
    private func startLiveActivity(
        agentType: String,
        agentEmoji: String,
        agentName: String,
        message: String,
        result: @escaping FlutterResult
    ) {
        // Check if Live Activities are authorized
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            result(FlutterError(code: "DISABLED", message: "Live Activities are disabled by user", details: nil))
            return
        }
        
        // For now, we'll just log the intent - actual ActivityKit implementation
        // requires a Widget Extension target added via Xcode
        print("🚀 Live Activity START: [\(agentEmoji) \(agentName)] \(message)")
        result("activity_\(UUID().uuidString)")
    }
    
    @available(iOS 16.1, *)
    private func updateLiveActivity(
        agentType: String,
        agentEmoji: String,
        agentName: String,
        message: String,
        isError: Bool,
        isComplete: Bool,
        result: @escaping FlutterResult
    ) {
        // Log the update - full implementation requires Widget Extension
        let status = isError ? "❌" : (isComplete ? "✅" : "🔄")
        print("\(status) Live Activity UPDATE: [\(agentEmoji) \(agentName)] \(message)")
        result(nil)
    }
    
    @available(iOS 16.1, *)
    private func endLiveActivity(result: @escaping FlutterResult) {
        print("🛑 Live Activity END")
        result(nil)
    }
}
