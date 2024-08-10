//
//  ContentView.swift
//  Lax
//

import SwiftUI
import LiveViewNative

struct ContentView: View {
    @ObservedObject var session: LiveSessionCoordinator<LaxRegistry>
    
    init(session: LiveSessionCoordinator<LaxRegistry>) {
        self._session = .init(wrappedValue: session)
    }
    
    var body: some View {
        LiveView(registry: LaxRegistry.self, session: session) {
            ConnectingView()
        } disconnected: {
            DisconnectedView()
        } reconnecting: { content, isReconnecting in
            ReconnectingView(isReconnecting: isReconnecting) {
                content
            }
        } error: { error in
            ErrorView(error: error)
        }
        .liveAPNSHandler(session: session)
    }
}
