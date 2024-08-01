//
//  ContentView.swift
//  Lax
//

import SwiftUI
import LiveViewNative
import LiveViewNativeLiveForm

struct ContentView: View {
    @StateObject private var session = LiveSessionCoordinator(
        .automatic(
            development: .localhost(path: "/"),
            // development: URL(string: "https://lax.ngrok.io")!,
            production: URL(string: "https://lax.fly.dev")!
        ),
        customRegistryType: LaxRegistry.self
    )
    
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

struct LaxRegistry: AggregateRegistry {
    #Registries<
        Addons.LiveForm<Self>
    >
}
