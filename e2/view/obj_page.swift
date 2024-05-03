import SwiftUI
import UserNotifications

struct ChangeDateView: View {
    @ObservedObject var item: Item
    @State private var expirationDateInput: String
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var showingKeyBoard: Bool
    @State private var invalidDate = false
    @State private var saveDate = false

    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    init(item: Item) {
        self.item = item
        self._expirationDateInput = State(initialValue: dateFormatter.string(from: item.expirationDate ?? Date()))
    }

    var body: some View {
        VStack{
            Section(header: Text("Change Expiration Date\n").font(.title2).foregroundStyle(.white)) {  // hex: 0xdee7e7
                HStack{
                    Spacer()
                    
                    Image(systemName: "pencil")
                        .foregroundColor(.white)
                    
                    TextField("", text: $expirationDateInput)
                        .focused($showingKeyBoard)
                        .keyboardType(.numberPad)
                        .onChange(of: expirationDateInput) {
                            if expirationDateInput.count > 10 {
                                expirationDateInput = String(expirationDateInput.prefix(10))
                            }
                            var withoutHyphen = String(expirationDateInput.replacingOccurrences(of: "-", with: "").prefix(8))
                            if withoutHyphen.count > 6 {
                                withoutHyphen.insert("-", at: expirationDateInput.index(expirationDateInput.startIndex, offsetBy: 6))
                                expirationDateInput = withoutHyphen
                            }
                            if withoutHyphen.count > 4 {
                                withoutHyphen.insert("-", at: expirationDateInput.index(expirationDateInput.startIndex, offsetBy: 4))
                                expirationDateInput = withoutHyphen
                            } else {
                                expirationDateInput = withoutHyphen
                            }
                        }
                        .placeholder(when: expirationDateInput.isEmpty) {
                            Text("Enter MM-DD-YYYY")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                        }
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    DatePicker("", selection: Binding(
                        get: {
                            dateFormatter.date(from: expirationDateInput) ?? Date()
                        },
                        set: {
                            expirationDateInput = dateFormatter.string(from: $0)
                        }
                    ), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .frame(width: 120)
                    .colorScheme(.dark)
                    
                    Spacer()
                }

            }
                .frame(maxWidth: 350)
            
            Text("\n")
                .frame(maxWidth:.infinity)

            Button("Save") {
                if let date = dateFormatter.date(from: expirationDateInput) {
                    item.expirationDate = date
                    expirationDateInput = ""
                    saveDate = true
                } else {
                    invalidDate = true
                }
            }
            .foregroundColor(.white)
            .alert("Invalid Date", isPresented: $invalidDate){
                Button("OK"){
                }
            }
            .alert("Change Notification Time", isPresented: $saveDate){
                Button("Yes"){
                    // Extract components from the selected notification time
                    let selectedComponents = Calendar.current.dateComponents([.hour, .minute], from: item.notificationTime ?? Date())

                    // Combine expiration date with the selected time
                    var calculatedNotificationDate = Calendar.current.date(bySettingHour: selectedComponents.hour ?? 0, minute: selectedComponents.minute ?? 0, second: 0, of: item.expirationDate ?? Date())

                    // Subtract daysPrior days from the calculated date
                    calculatedNotificationDate = Calendar.current.date(byAdding: .day, value: -item.priordate, to: calculatedNotificationDate ?? Date())

                    // Update the item's notification time
                    item.notificationTime = calculatedNotificationDate

                    if item.isNotificationEnabled {
                        removeScheduledNotification(for: item)
                        scheduleNotification(for: item)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                Button("No"){
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Would you like to change the notification time based on your change?")
            }
        }
        .frame(maxHeight: .infinity*0.4)
        .background(Color(hex: 0x89a9a9))
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else {
            return "Not specified"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func removeScheduledNotification(for item: Item) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
        print("Notification removed successfully.")
    }
    
    private func scheduleNotification(for item: Item) {
        print("schedule obj_page")
        
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

}

