import SwiftUI
import WidgetKit

// This file is the entry point for the AgentWidget extension
// It must be added to the AgentWidget target in Xcode

@main
struct AgentWidgetBundle: WidgetBundle {
    var body: some Widget {
        AgentLiveActivity()
    }
}
