//
//  SpamPingApp.swift
//  SpamPing
//
//  Created by Ethan on 4/8/2025
//

import SwiftUI
import UserNotifications

// MARK: - App Delegate
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

// MARK: - Manager
@MainActor
final class PingManager: ObservableObject {
    private let center = UNUserNotificationCenter.current()

    func requestPermission() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func startSpam() {
        center.removeAllPendingNotificationRequests()
        let content = UNMutableNotificationContent()
        content.title = "ping"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: true)
        let request = UNNotificationRequest(identifier: "spam", content: content, trigger: trigger)
        center.add(request)
    }

    func stopSpam() {
        center.removeAllPendingNotificationRequests()
    }
}

// MARK: - View
struct ContentView: View {
    @State private var isOn = false
    @StateObject private var manager = PingManager()

    var body: some View {
        VStack(spacing: 40) {
            Text("Spam Ping")
                .font(.largeTitle.bold())

            Toggle("Send pings", isOn: $isOn)
                .onChange(of: isOn) { _, newValue in
                    if newValue {
                        manager.startSpam()
                    } else {
                        manager.stopSpam()
                    }
                }
                .padding()
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .scaleEffect(1.5)
        }
        .padding()
        .task {
            await manager.requestPermission()
        }
    }
}

// MARK: - App
@main
struct SpamPingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
