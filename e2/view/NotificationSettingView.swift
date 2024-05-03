import SwiftUI
import UserNotifications

struct NotificationSettingView: View {
    @ObservedObject var item: Item
    @State private var daysPrior: Int = 0
    @State private var selectedNotificationDate: Date = Date()
    @Environment(\.presentationMode) var presentationMode
    
    init(item: Item) {
        self.item = item
        self._daysPrior = State(initialValue: item.priordate)
    }

    var body: some View {
        VStack{
            Section(header: Text("Notification Settings\n").font(.title2).foregroundStyle(.white)) {  // hex: 0xdee7e7
                Stepper(value: $daysPrior, in: 0...30, step: 1) {
                    Text("Notify \(daysPrior) Days Prior to Expiration")
                        .foregroundStyle(.white)
                }
                    .colorScheme(.dark)
                
                Text("")

                if let notificationTime = item.notificationTime {
                    DatePicker("Notification Sending Time", selection: $selectedNotificationDate, displayedComponents: .hourAndMinute)
                        .onAppear {
                            self.selectedNotificationDate = notificationTime
                        }
                        .colorScheme(.dark)
                }
            }
                .frame(maxWidth: 350)
            
            Text("\n")
                .frame(maxWidth:.infinity)

            Button("Save") {
                saveNotificationSettings()
            }
            .foregroundColor(.white)
        }
        .frame(maxHeight: .infinity*0.4)
        .background(Color(hex: 0x89a9a9))
    }

    private func saveNotificationSettings() {
        let notificationsEnabled = item.isNotificationEnabled

        if notificationsEnabled {
            removeScheduledNotification(for: item)
        }

        if let expirationDate = item.expirationDate {
            // Extract components from the selected notification time
            let selectedComponents = Calendar.current.dateComponents([.hour, .minute], from: selectedNotificationDate)

            // Combine expiration date with the selected time
            var calculatedNotificationDate = Calendar.current.date(bySettingHour: selectedComponents.hour ?? 0, minute: selectedComponents.minute ?? 0, second: 0, of: expirationDate)

            // Subtract daysPrior days from the calculated date
            calculatedNotificationDate = Calendar.current.date(byAdding: .day, value: -daysPrior, to: calculatedNotificationDate ?? Date())

            // Update the item's notification time
            item.notificationTime = calculatedNotificationDate
            item.priordate = daysPrior

            if notificationsEnabled {
                scheduleNotification(for: item)
            }
        } else {
            print("Error: expirationDate is nil.")
        }

        presentationMode.wrappedValue.dismiss()
    }



    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func scheduleNotification(for item: Item) {
        print("schedule NotificationSetting View")
        
        guard item.isNotificationEnabled,
              let notificationTime = item.notificationTime else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "eStorage Notification"
        content.body = "\(item.name) will expire soon."

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully.")
            }
        }
    }

    private func removeScheduledNotification(for item: Item) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
        print("Notification removed successfully.")
    }
}

