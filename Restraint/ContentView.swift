//
//  RestraintApp.swift
//  Restraint
//
//  Created by Ethan Tan on 4/8/2025
//

import SwiftUI
import UserNotifications
import Combine

// MARK: - App Delegate (for delegate conformance)
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Allow foreground banners
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
final class RestraintModel: ObservableObject {
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

    @Published var running = false
    @Published var elapsed: TimeInterval = 0
    @Published var ignoredCount = 0

    private var startDate: Date?
    private var cancellables = Set<AnyCancellable>()

    init() {
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.running, let start = self.startDate else { return }
                self.elapsed = Date().timeIntervalSince(start)
                self.updateIgnored()
            }
            .store(in: &cancellables)
    }

    func requestPermission() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func start() {
        running = true
        startDate = Date()
        schedulePattern()
    }

    func stop() {
        running = false
        center.removeAllPendingNotificationRequests()
    }

    private func schedulePattern() {
        center.removeAllPendingNotificationRequests()
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
                identifier: "pat-\(index)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    private func updateIgnored() {
        guard let start = startDate else { return }
        let elapsedMin = elapsed / 60
        var shouldHaveFired = 0
        var total = 0
        for min in minutes {
            total += min
            if Double(total) <= elapsedMin {
                shouldHaveFired += 1
            }
        }
        center.getPendingNotificationRequests { pending in
            DispatchQueue.main.async {
                self.ignoredCount = shouldHaveFired - (self.minutes.count - pending.count)
            }
        }
    }
}

// MARK: - SwiftUI View
struct RestraintView: View {
    @StateObject private var model = RestraintModel()

    var body: some View {
        VStack(spacing: 30) {
            Text("Restraint")
                .font(.largeTitle.bold())

            Button(action: {
                if model.running {
                    model.stop()
                } else {
                    model.start()
                }
            }) {
                Text(model.running ? "Stop" : "Start")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, minHeight: 60)
            }
            .buttonStyle(.borderedProminent)
            .tint(model.running ? .red : .green)
            .animation(.default, value: model.running)

            if model.running {
                Group {
                    Text("Time elapsed")
                    Text(String(format: "%.1f s", model.elapsed))
                        .font(.title2.monospacedDigit())

                    Text("Notifications ignored")
                    Text("\(model.ignoredCount)")
                        .font(.title2.monospacedDigit())
                }
                .transition(.opacity)
            }
        }
        .padding()
        .task {
            await model.requestPermission()
        }
    }
}

// MARK: - App Entry
@main
struct RestraintApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            RestraintView()
        }
    }
}
