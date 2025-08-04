//
//  RestraintApp.swift
//  Restraint
//
//  Created by Ethan Tan on 4/8/2025
//

import SwiftUI
import UserNotifications

// MARK: - App Delegate (ensures foreground banners)
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

// MARK: - Notification Manager
@MainActor
final class NotificationManager: ObservableObject {
    private let center = UNUserNotificationCenter.current()

    // 120-step pattern
    private let minutes: [Int] = [
        15, 20, 13, 10, 10, 18, 11, 12, 14, 14,
        16, 13, 18, 12, 18, 12, 17, 20, 18, 11,
        20, 18, 20, 14, 14, 15, 18, 19, 12, 14,
        16, 11, 18, 17, 14, 11, 20, 12, 10, 12,
        17, 15, 12, 14, 14, 10, 16, 17, 19, 20,
        14, 20, 13, 13, 11, 11, 17, 18, 15, 20,
        20, 15, 16, 10, 15, 13, 20, 15, 13, 13,
        20, 12, 11, 19, 20, 10, 16, 11, 18, 20,
        19, 15, 19, 14, 15, 10, 19, 16, 11, 10,
        15, 15, 20, 10, 10, 17, 12, 11, 18, 12,
        10, 16, 17, 14, 14, 19, 20, 11, 13, 11,
        11, 15, 20, 20, 10, 20, 11, 18, 20, 16
    ]

    func requestPermission() async {
        do {
            try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            print("No permission")
        }
    }

    func setScheduled(enabled: Bool) {
        center.removeAllPendingNotificationRequests()
        guard enabled else { return }

        var cumulative = 0.0
        for (index, min) in minutes.enumerated() {
            cumulative += Double(min) * 60
            let content = UNMutableNotificationContent()
            content.title = "ping"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: cumulative,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "pattern-\(index)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }
}

// MARK: - Custom Switch (unchanged look)
struct CustomSwitch: View {
    @Binding var isOn: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 25)
            .frame(width: 60, height: 35)
            .scaleEffect(isOn ? 1.5 : 1.0)
            .foregroundColor(isOn ? .green : .gray)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .frame(width: 35, height: 35)
                    .foregroundColor(isOn ? .white : .gray)
                    .offset(x: isOn ? 25 : 0, y: 0)
            )
            .onTapGesture {
                withAnimation {
                    isOn.toggle()
                }
            }
            .padding(.vertical, 8)
    }
}

// MARK: - Content View
struct ContentView: View {
    @State private var isOn = false
    @StateObject private var nm = NotificationManager()

    var body: some View {
        ZStack {
            Color.gray.opacity(0.2).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Notifications")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 8)

                CustomSwitch(isOn: $isOn)
                    .onChange(of: isOn) { _, newValue in
                        nm.setScheduled(enabled: newValue)
                    }

                Text(isOn ? "ON" : "OFF")
                    .font(.title2)
                    .foregroundColor(isOn ? .green : .gray)
            }
            .padding(32)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .onAppear {
            Task {
                await nm.requestPermission()
            }
        }
    }
}

// MARK: - App Entry
@main
struct RestraintApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
