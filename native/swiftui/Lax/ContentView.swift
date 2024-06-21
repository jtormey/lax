//
//  ContentView.swift
//  Lax
//

import SwiftUI
import LiveViewNative
import LiveViewNativeLiveForm

struct ContentView: View {
    var body: some View {
        #LiveView(
            .automatic(
                development: .localhost(path: "/"),
                // development: URL(string: "https://lax.ngrok.io")!,
                production: URL(string: "https://lax.fly.dev")!
            ),
            addons: [
                .liveForm
            ]
        ) {
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
    }
}
