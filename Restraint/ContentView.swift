import SwiftUI
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    func requestPermission() async {
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            print("No permission")
        }
    }

    func setScheduled(enabled: Bool) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        guard enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Ping"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)
        let request = UNNotificationRequest(identifier: "timer", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}

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
                        nm.setScheduled(enabled: newValue)
                    }

                Text(isOn ? "ON" : "OFF")
                    .font(.title2)
                    .foregroundColor(isOn ? .green : .gray)
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
