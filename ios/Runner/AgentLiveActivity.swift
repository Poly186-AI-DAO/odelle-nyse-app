import ActivityKit
import WidgetKit
import SwiftUI

struct AgentLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AgentActivityAttributes.self) { context in
            // Lock Screen/Banner UI
            VStack(alignment: .leading) {
                HStack {
                    Text("\(context.attributes.agentEmoji) \(context.attributes.agentName)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    if context.state.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if context.state.isError {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                }
                
                Text(context.state.message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.agentEmoji)
                        .font(.title2)
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .padding(.trailing, 8)
                    } else if context.state.isError {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                            .padding(.trailing, 8)
                    } else {
                        ProgressView() // Default spinner
                            .padding(.trailing, 8)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading) {
                        Text(context.attributes.agentName)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(context.state.message)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                Text(context.attributes.agentEmoji)
                    .padding(.leading, 4)
            } compactTrailing: {
                if context.state.isComplete {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .font(.caption2)
                        .padding(.trailing, 4)
                } else if context.state.isError {
                    Image(systemName: "exclamationmark")
                        .foregroundColor(.red)
                        .font(.caption2)
                        .padding(.trailing, 4)
                } else {
                    // Simple animated arc or just a static icon for "processing"
                    Image(systemName: "ellipsis")
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing)
                        .foregroundStyle(.white)
                        .padding(.trailing, 4)
                }
            } minimal: {
                Text(context.attributes.agentEmoji)
            }
            .keylineTint(Color.cyan)
        }
    }
}
