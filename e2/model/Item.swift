import Foundation
import UserNotifications

class Item: Identifiable, ObservableObject, Equatable, Codable {
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }

    var id = UUID()
    @Published var name: String
    @Published var expirationDate: Date?
    @Published var notificationTime: Date?
    @Published var isNotificationEnabled: Bool
    @Published var priordate: Int

    init(name: String, expirationDate: Date? = nil, notifyTime: Date, ifEnable: Bool, priorDay: Int) {
        self.name = name
        self.expirationDate = expirationDate
        self.isNotificationEnabled = ifEnable
        self.priordate = priorDay
        self.notificationTime = Date()
        
        let selectedComponents = Calendar.current.dateComponents([.hour, .minute], from: notifyTime )

        // Combine expiration date with the selected time
        var calculatedNotificationDate = Calendar.current.date(bySettingHour: selectedComponents.hour ?? 0, minute: selectedComponents.minute ?? 0, second: 0, of: self.expirationDate ?? Date())

        // Subtract daysPrior days from the calculated date
        calculatedNotificationDate = Calendar.current.date(byAdding: .day, value: -self.priordate, to: calculatedNotificationDate ?? Date())

        // Update the item's notification time
        self.notificationTime = calculatedNotificationDate

        if self.isNotificationEnabled {
            scheduleNotification(for: self)
        }
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, expirationDate, notificationTime, isNotificationEnabled, priordate
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        expirationDate = try container.decodeIfPresent(Date.self, forKey: .expirationDate)
        notificationTime = try container.decodeIfPresent(Date.self, forKey: .notificationTime)
        isNotificationEnabled = try container.decode(Bool.self, forKey: .isNotificationEnabled)
        priordate = try container.decode(Int.self, forKey: .priordate)

        // id is optional because it's generated during initialization
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(expirationDate, forKey: .expirationDate)
        try container.encode(notificationTime, forKey: .notificationTime)
        try container.encode(isNotificationEnabled, forKey: .isNotificationEnabled)
        try container.encode(priordate, forKey: .priordate)
    }
    
    private func scheduleNotification(for item: Item) {
        print("schedule Item")
        
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

extension Date {
    func midnight() -> Date {
        return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }
}
