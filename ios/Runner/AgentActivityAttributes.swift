import ActivityKit
import Foundation

struct AgentActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state that changes over time
        var message: String
        var isError: Bool
        var isComplete: Bool
        var timestamp: Date
    }

    // Static data that doesn't change
    var agentType: String
    var agentEmoji: String
    var agentName: String
}
