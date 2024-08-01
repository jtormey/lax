//
//  Lax.swift
//  Lax
//

import SwiftUI
import LiveViewNative
import Combine

@main
struct Lax: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(delegate)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    let didRegisterForRemoteNotifications = CurrentValueSubject<String?, any Error>(nil)
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        self.didRegisterForRemoteNotifications.send(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: any Error
    ) {
        self.didRegisterForRemoteNotifications.send(completion: .failure(error))
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func registerForRemoteNotifications(_ completion: @escaping (Result<String, any Error>) -> ()) {
        if let deviceToken = self.didRegisterForRemoteNotifications.value {
            completion(.success(deviceToken))
        } else {
            self.didRegisterForRemoteNotifications.sink {
                switch $0 {
                case .finished:
                    break
                case let .failure(error):
                    completion(.failure(error))
                }
            } receiveValue: { deviceToken in
                guard let deviceToken else { return }
                completion(.success(deviceToken))
            }
            .store(in: &cancellables)
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func registerForRemoteNotifications() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            registerForRemoteNotifications(continuation.resume(with:))
        }
    }
}

struct LiveAPNSHandlerModifier<Root: RootRegistry>: ViewModifier {
    let session: LiveSessionCoordinator<Root>
    @EnvironmentObject private var delegate: AppDelegate
    
    static var incomingEvent: String { "swiftui_register_apns" }
    static var outgoingEvent: String { "swiftui_apns_device_token" }
    
    func body(content: Content) -> some View {
        content.onReceive(session.receiveEvent(Self.incomingEvent)) { (coordinator, message) in
            Task {
                do {
                    let granted = try await UNUserNotificationCenter.current().requestAuthorization()
                    let deviceToken = try await delegate.registerForRemoteNotifications()
                    try await coordinator.pushEvent(type: "click", event: Self.outgoingEvent, value: [
                        "granted": granted,
                        "device_token": deviceToken
                    ])
                } catch {
                    try await coordinator.pushEvent(type: "click", event: Self.outgoingEvent, value: [
                        "granted": false,
                        "error": error.localizedDescription
                    ])
                }
            }
        }
    }
}

extension View {
    func liveAPNSHandler(session: LiveSessionCoordinator<some RootRegistry>) -> some View {
        modifier(LiveAPNSHandlerModifier(session: session))
    }
}
