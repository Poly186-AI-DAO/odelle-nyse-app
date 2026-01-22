import UIKit
import Flutter
import ActivityKit

// AgentActivityAttributes is defined in AgentActivityAttributes.swift
// Both Runner and Widget Extension targets must include that file

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var liveActivityChannel: FlutterMethodChannel?
    // Keep track of the current activity to update it later. Type erased to Any to avoid availability issues.
    private var currentActivity: Any?
    
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
        guard #available(iOS 16.2, *) else {
            result(FlutterError(code: "UNSUPPORTED", message: "Live Activities require iOS 16.2+", details: nil))
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
                // If it's a minor update, we might still have these, but check just in case
                result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
                return
            }
            
            let isError = args["isError"] as? Bool ?? false
            let isComplete = args["isComplete"] as? Bool ?? false
            
            updateLiveActivity(
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
    
    @available(iOS 16.2, *)
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
        
        // Static data
        let attributes = AgentActivityAttributes(
            agentType: agentType,
            agentEmoji: agentEmoji,
            agentName: agentName
        )
        
        // Initial dynamic state
        let contentState = AgentActivityAttributes.ContentState(
            message: message,
            isError: false,
            isComplete: false,
            timestamp: Date()
        )
        
        do {
            let activity = try Activity<AgentActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil // We aren't using push tokens for updates for now, local updates only
            )
            
            self.currentActivity = activity
            print("🚀 Live Activity START: ID \(activity.id)")
            result(activity.id)
        } catch {
            print("❌ Failed to start Live Activity: \(error.localizedDescription)")
            result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
        }
    }
    
    @available(iOS 16.2, *)
    private func updateLiveActivity(
        message: String,
        isError: Bool,
        isComplete: Bool,
        result: @escaping FlutterResult
    ) {
        // Cast the stored Any? back to the specific Activity type
        guard let activity = currentActivity as? Activity<AgentActivityAttributes> else {
            result(FlutterError(code: "NO_ACTIVITY", message: "No active Live Activity found", details: nil))
            return
        }
        
        let updatedState = AgentActivityAttributes.ContentState(
            message: message,
            isError: isError,
            isComplete: isComplete,
            timestamp: Date()
        )
        
        Task {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
            print("🔄 Live Activity UPDATED: \(message)")
            result(nil)
        }
    }
    
    @available(iOS 16.2, *)
    private func endLiveActivity(result: @escaping FlutterResult) {
        guard let activity = currentActivity as? Activity<AgentActivityAttributes> else {
            // It might have already ended or never started, just return success
            result(nil)
            return
        }
        
        // Use final content state if you want to leave a final message, 
        // otherwise just end it immediately or with a dismissal policy.
        // We'll end it immediately for now, but with 'default' policy it stays for a bit.
        
        Task {
            await activity.end(
                nil, // Could provide final content state here
                dismissalPolicy: .default // Stays on lock screen for a short time (standard iOS behavior)
            )
            self.currentActivity = nil
            print("🛑 Live Activity ENDED")
            result(nil)
        }
    }
}
