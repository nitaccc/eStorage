// ItemDetailView.swift
import SwiftUI
import UserNotifications

struct ItemDetailView: View {
    @ObservedObject var item: Item
    @State private var showingNotificationSetting = false
    @State private var showingDateChange = false
    @State private var notifyEnable = false
    @FocusState private var showingKeyBoard: Bool

    var body: some View {
        VStack {
            Spacer()
            TextField("", text: $item.name)
                .focused($showingKeyBoard)
                .placeholder(when: item.name.isEmpty) {
                    Text("\(item.name)\n")
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(hex: 0xfafaff))
                        .font(.title)
                }
                .onChange(of: item.name) {
                    if item.name.count > 40 {
                        item.name = String(item.name.prefix(40))
                    }
                }
                .underline()
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: 0xfafaff))
                .font(.title)
                .padding()
            
//            Text("\(item.name)\n")
//                .frame(maxWidth: .infinity)
//                .font(.title)
//                .foregroundColor(Color(hex: 0xfafaff))
            
//            Button(action: {
//                showingDateChange = true
//            }) {
//                Label("Best by \(formattedDate(item.expirationDate))\n", systemImage: "pencil")
//                    .foregroundColor(Color(hex: 0xfafaff))
//            }
//                .padding()
//                .sheet(isPresented: $showingDateChange){
//                    ChangeDateView(item: item)
//                        .presentationDetents([.fraction(0.4)])
//                }
            
            HStack{
                Text("Best by \(formattedDate(item.expirationDate))\n")
                    .foregroundColor(Color(hex: 0xdee7e7))
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    showingDateChange = true
                }) {
                    Label("", systemImage: "pencil.line")
                        .foregroundColor(Color(hex: 0xfafaff))
                }
                    .sheet(isPresented: $showingDateChange){
                        ChangeDateView(item: item)
                            .presentationDetents([.fraction(0.4)])
                    }
            }
            
            Text("Notify on \(formattedDateTime(item.notificationTime))")
                .foregroundColor(Color(hex: 0xdee7e7))
            
            Spacer()
            
            Toggle( isOn: $item.isNotificationEnabled){
                Label("Notification", systemImage: "bell")
                    .foregroundColor(Color(hex: 0xfafaff))
            }
            .frame(width: 200)
                .onChange(of: item.isNotificationEnabled) {
                    if item.isNotificationEnabled {
                        // If notifications are enabled, schedule the notification
                        scheduleNotification(for: item)
                    } else {
                        // If notifications are disabled, remove the existing notification
                        removeScheduledNotification(for: item)
                    }
                }

            // Navigation button to NotificationSettingView
            Button(action: {
                showingNotificationSetting = true
            }) {
                Label("Go to Notification Setting", systemImage: "gear")
                    .foregroundColor(Color(hex: 0xfafaff))
            }
                .padding()
                .sheet(isPresented: $showingNotificationSetting){
                    NotificationSettingView(item: item)
                        .presentationDetents([.fraction(0.4)])
                }
            
            Spacer()
        }
            .padding()
            .background(Color(hex: 0x4f646f))
    
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else {
            return "Not specified"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formattedDateTime(_ date: Date?) -> String {
        guard let date = date else {
            return "Not specified"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func scheduleNotification(for item: Item) {
        print("schedule itemDetail")
        guard item.isNotificationEnabled,
              let notificationTime = item.notificationTime else {
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "eStorage Notification"
        content.body = "\(item.name) will expire soon."

        // Extract components from the notification time
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)

        // Create notification trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create notification request
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)

        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully.")
            }
        }
    }

    private func removeScheduledNotification(for item: Item) {
        // Remove the scheduled notification with the item's identifier
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
        print("Notification removed successfully.")
    }
}
