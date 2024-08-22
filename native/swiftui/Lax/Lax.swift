//
//  Lax.swift
//  Lax
//

import SwiftUI
import LiveViewNative
import LiveViewNativeLiveForm
import Combine
import UserNotifications

@main
struct Lax: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    #else
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView(session: delegate.session)
                .environmentObject(delegate)
        }
    }
}

struct LaxRegistry: AggregateRegistry {
    #Registries<
        Addons.LiveForm<Self>,
        Addons.Lax<Self>
    >
}

@MainActor
class AppDelegate: NSObject {
    /// A subject that publishes a value when a notification is tapped.
    ///
    /// The current value is stored, and should be reset to `nil` after being handled.
    /// A `PassthroughSubject` may not have a subscriber setup before the delegate receives the notification event.
    let notificationNavigateRequest = CurrentValueSubject<String?, Never>(nil)
    
    /// A subject used internally by ``registerForRemoteNotifications()``.
    ///
    /// This subject enables the `didRegisterForRemoteNotificationsWithDeviceToken` event to be handled asynchronously.
    let didRegisterForRemoteNotifications = CurrentValueSubject<String?, any Error>(nil)
    
    /// The coordinator for the app's `LiveView`.
    private(set) var session = LiveSessionCoordinator(
        .automatic(
            development: .localhost(path: "/"),
            // development: URL(string: "https://lax.ngrok.io")!,
            production: URL(string: "https://lax.so")!
        ),
        customRegistryType: LaxRegistry.self
    )
    
    private var cancellables = Set<AnyCancellable>()
}

#if os(macOS)
extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }
    
    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.didRegisterForRemoteNotifications.send(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())
    }
    
    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        self.didRegisterForRemoteNotifications.send(completion: .failure(error))
    }
}
#else
extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
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
}
#endif

extension AppDelegate: UNUserNotificationCenterDelegate, ObservableObject {
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
            #if os(macOS)
            NSApplication.shared.registerForRemoteNotifications()
            #else
            UIApplication.shared.registerForRemoteNotifications()
            #endif
        }
    }
    
    /// Registers for remote notifications on the `UIApplication` asynchronously and returns the device token.
    func registerForRemoteNotifications() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            registerForRemoteNotifications(continuation.resume(with:))
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // display notifications when the app is foregrounded, and not already in the notification's chat.
        if let navigate = notification.request.content.userInfo["navigate"] as? String,
           session.navigationPath.last?.url.path() == "/chat/\(navigate)/"
        {
            return []
        } else {
            return [.list, .banner]
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if let navigate = response.notification.request.content.userInfo["navigate"] as? String {
            notificationNavigateRequest.send(navigate)
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
                    let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [
                        .alert,
                        .badge,
                        .sound
                    ])
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

/// A View that watches for navigation requests from tapping on a notification.
///
/// The event passed to `onReceive` will be sent when a notification is tapped.
///
/// ```html
/// <NotificationLaunchObserver onReceive="handle-notification" />
/// ```
///
/// ```elixir
/// def handle_event("handle-notification", %{ "id" => channel_id }, socket) do
///   ...
/// end
/// ```
@LiveElement
struct NotificationLaunchObserver<Root: RootRegistry>: View {
    @LiveElementIgnored
    @EnvironmentObject
    private var delegate: AppDelegate
    
    private var onReceive: String = ""
    
    private var replace: Bool = false
    
    var body: some View {
        VStack {}
            .hidden()
            .onReceive(delegate.notificationNavigateRequest) { channelID in
                guard let channelID else { return }
                delegate.notificationNavigateRequest.value = nil
                Task {
                    do {
                        try await $liveElement.context.coordinator.pushEvent(type: "click", event: onReceive, value: ["id": channelID, "replace": replace])
                    } catch {
                        print(error)
                    }
                }
            }
    }
}

extension Addons {
    @Addon
    struct Lax<Root: RootRegistry> {
        enum TagName: String {
            case notificationLaunchObserver = "NotificationLaunchObserver"
        }
        
        static func lookup(_ name: TagName, element: ElementNode) -> some View {
            switch name {
            case .notificationLaunchObserver:
                NotificationLaunchObserver<Root>()
            }
        }
    }
}
