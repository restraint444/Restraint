import SwiftUI
import UserNotifications

// MARK: - 1. NotificationManager (merged)
@MainActor
final class NotificationManager: ObservableObject {
    private let center = UNUserNotificationCenter.current()

    func requestPermission() async {
        do {
            try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            print("No permission")
        }
    }

    /// Drop every pending ping
    func clearAll() {
        center.removeAllPendingNotificationRequests()
    }

    /// Schedule the 1-hour pattern
    func schedulePattern() {
        clearAll()

        let minutes = [15, 20, 13, 10, 10, 18, 11, 12, 14, 14,
                       16, 13, 18, 12, 18, 12, 17, 20, 18, 11]

        var cumulative = 0.0
        for (index, min) in minutes.enumerated() {
            cumulative += Double(min) * 60
            let content = UNMutableNotificationContent()
            content.title = "Ping"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: cumulative,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "ping-\(index)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }
}

// MARK: - 2. CustomSwitch (unchanged)
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

// MARK: - 3. ContentView (merged)
struct ContentView: View {
    @State private var isOn = false
    @StateObject private var nm = NotificationManager()

    var body: some View {
        ZStack {
            Color.gray.opacity(0.2).edgesIgnoringSafeArea(.all)
            VStack(spacing: 16) {
                Text("Notifications")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 8)

                CustomSwitch(isOn: $isOn)
                    .onChange(of: isOn) { _, newValue in
                        if newValue {
                            nm.schedulePattern()
                        } else {
                            nm.clearAll()
                        }
                    }

                Text(isOn ? "ON" : "OFF")
                    .font(.title2)
                    .foregroundColor(isOn ? .green : .gray)

                // NEW: small “1-hour pattern” button when OFF
                if !isOn {
                    Button("1-hour pattern") {
                        isOn = true
                        nm.schedulePattern()
                    }
                    .font(.callout)
                    .foregroundColor(.blue)
                }
            }
            .padding(32)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .onAppear {
            Task {
                await nm.requestPermission()
            }
        }
    }
}
