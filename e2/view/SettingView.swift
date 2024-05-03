//
//  SettingView.swift
//  e2
//
//  Created by Anita Chen on 3/27/24.
//

import Foundation
import SwiftUI

import Foundation


class SettingDefault: ObservableObject, Codable {
    @Published var default_prior_day: Int = 0{
        didSet {setsave()}
    }
    @Published var default_enable_notify: Bool = false{
        didSet {setsave()}
    }
    @Published var default_notify_time: Date = Date().midnight(){
        didSet {setsave()}
    }
    
    private let defaults = UserDefaults.standard
    private let notifyTimeKey = "default_notify_time"
    private let priorDayKey = "default_prior_day"
    private let enableNotifyKey = "default_enable_notify"
        
//    init() {
//        setload()  // Load settings when the object is initialized
//        
//    }
    init() {
        default_prior_day = defaults.integer(forKey: priorDayKey)
        default_enable_notify = defaults.bool(forKey: enableNotifyKey)
        
        if let data = defaults.data(forKey: notifyTimeKey),
            let date = try? JSONDecoder().decode(Date.self, from: data) {
            default_notify_time = date
            
            print(default_notify_time)
        } else {
            default_notify_time = Date().midnight() // Define your midnight method or use a default value
        }
    }
    
    enum CodingKeys: String, CodingKey {
            case default_prior_day, default_enable_notify, default_notify_time
        }

        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            default_prior_day = try container.decode(Int.self, forKey: .default_prior_day)
            default_enable_notify = try container.decode(Bool.self, forKey: .default_enable_notify)
            default_notify_time = try container.decode(Date.self, forKey: .default_notify_time)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(default_prior_day, forKey: .default_prior_day)
            try container.encode(default_enable_notify, forKey: .default_enable_notify)
            try container.encode(default_notify_time, forKey: .default_notify_time)
        }
    
    private func setsave() {
        print("save")
        defaults.set(default_prior_day, forKey: priorDayKey)
        defaults.set(default_enable_notify, forKey: enableNotifyKey)
        
//        if let data = try? JSONEncoder().encode(default_notify_time) {
//            defaults.set(data, forKey: notifyTimeKey)
//        }
    }
    
    func loadSettings() {
            if let data = UserDefaults.standard.data(forKey: "notificationSetting") {
                if let decodedSetting = try? JSONDecoder().decode(SettingDefault.self, from: data) {
                    // Update the properties with the loaded settings
                    self.default_prior_day = decodedSetting.default_prior_day
                    self.default_enable_notify = decodedSetting.default_enable_notify
                    self.default_notify_time = decodedSetting.default_notify_time
                    print(self.default_prior_day)
                    print(self.default_enable_notify)
                    print(self.default_notify_time)
                    print("++++++++++++++++")
                }
            }
        }
        
        // Save settings
    func saveSettings() {
        if let encodedSetting = try? JSONEncoder().encode(self) {
            print(self.default_prior_day)
            print(self.default_enable_notify)
            print(self.default_notify_time)
            print("------------------------")
            UserDefaults.standard.set(encodedSetting, forKey: "notificationSetting")
        }
    }
        
//    private func setload() {
//        if let priorDayData = defaults.data(forKey: "default_prior_day"),
//            let day = try? JSONDecoder().decode(Int.self, from: priorDayData) {
//            default_prior_day = day
//        }
//        
//        default_enable_notify = defaults.bool(forKey: "default_enable_notify")
//        
//        if let notifyTimeData = defaults.data(forKey: "default_notify_time"),
//            let notifyTime = try? JSONDecoder().decode(Date.self, from: notifyTimeData) {
//            default_notify_time = notifyTime
//        }
//    }
}

struct SettingView: View {
    @Binding var items: [Item]
    @EnvironmentObject var settingDefault: SettingDefault
//    @State private var timeString: String = ""
    @State private var notificationTimeDef:Date=Date()
    @State private var notificationTimeAll:Date=Date()
    @State private var enableNotifyAll: Bool = false
    @State private var enableNotifyAllFlag: Bool = true
    @State private var priorDayAll: Int = 0
    
    init(items: Binding<[Item]>) {
        _items = items
//        _notificationTimeDef = State(initialValue: Date())  // Initialize with a dummy value
//        _notificationTimeAll = State(initialValue: Date())  // Initialize with a dummy value
    }

    
    var body: some View {
        
        
        VStack{
            
            Color.clear.frame(height: 20)
            
            Text("     Settings")
                .font(.system(size:26, weight: .bold))
                .foregroundColor(Color(hex: 0x535657))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)
            
            Color.clear.frame(height: 20)
            
            Text("       Default Notification Settings")
                .font(.system(size:16, weight: .bold))
                .foregroundColor(Color(hex: 0x535657))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)
            
            Toggle( isOn: $settingDefault.default_enable_notify){
                Text("    Notification Enable")
                    .foregroundColor(Color(hex: 0x535657))
            }
                .padding()
            
            HStack{
                Text("Notify at " + self.formattedTime(for: settingDefault.default_notify_time))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color(hex: 0x535657))
                    .padding(.horizontal)
                    .padding(.horizontal)
                
                DatePicker("", selection: $notificationTimeDef, displayedComponents: .hourAndMinute)
                    .onChange(of: notificationTimeDef) {
                        settingDefault.default_notify_time = notificationTimeDef
                    }
                    .onAppear {
                        settingDefault.default_notify_time = notificationTimeDef
                    }
                    .frame(width: 100)
                    .padding(.trailing)
                    .colorScheme(.dark)
            }
            
            Stepper(value: $settingDefault.default_prior_day, in: 0...30, step: 1) {
                Text("Notify \(settingDefault.default_prior_day) Days In Advance")
                    .foregroundStyle(Color(hex: 0x535657))
                    .padding(.leading)
            }
                .padding()
                .frame(maxWidth: .infinity)
                .colorScheme(.light)
            
            //--------------------------------------------------------------------------------
            
            
            //            Text("Notify \(settingDefault.default_prior_day) Days Prior to Expiration\n Notify \(settingDefault.default_notify_time)\n is enabled \(settingDefault.default_enable_notify)")
            //                .frame(maxWidth: .infinity, alignment: .leading)
            //                .foregroundColor(Color(hex: 0x535657))
            //                .padding()
            //                .padding()
                        
            //            Text(timeString)
            //                .onAppear {
            //                    // Update the view's state with the formatted date whenever the view appears
            //                    self.timeString = "Notify at " + self.formattedTime(for: settingDefault.default_notify_time)
            //                }
            //                .frame(maxWidth: .infinity, alignment: .leading)
            //                .foregroundColor(Color(hex: 0x535657))
            //                .padding()
            //                .padding()
            
            Text("       Existing Items Notification Settings")
                .font(.system(size:16, weight: .bold))
                .foregroundColor(Color(hex: 0x535657))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)
                        
            Toggle( isOn: $enableNotifyAll){
                Text("    All Items Notification Enable")
                    .foregroundColor(Color(hex: 0x535657))
            }
                .padding()
                .onChange(of: enableNotifyAll) {
//                    settingDefault.default_enable_notify = enableNotifyAll
                    if enableNotifyAllFlag{
                        if enableNotifyAll {
                            for item in items{
                                removeScheduledNotification(for: item)
                                item.isNotificationEnabled = true
                                scheduleNotification(for: item)
                            }
                        } else {
                            for item in items{
                                removeScheduledNotification(for: item)
                                item.isNotificationEnabled = false
                            }
                        }
                    }else{
                        enableNotifyAllFlag = true
                    }
                }
//                .onChange(of: settingDefault.default_enable_notify){
//                    if enableNotifyAll == true {
//                        if settingDefault.default_enable_notify == false{
//                            enableNotifyAll = false
//                            enableNotifyAllFlag = false
//                        }
//                    }
//                }
            
            HStack{
                Text("Existing Items Notify at " + self.formattedTime(for: notificationTimeAll))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color(hex: 0x535657))
                    .padding(.horizontal)
                    .padding(.horizontal)
                
                DatePicker("", selection: $notificationTimeAll, displayedComponents: .hourAndMinute)
                    .onChange(of: notificationTimeAll){
//                        settingDefault.default_notify_time = notificationTimeAll
                        for item in items{
                            let selectedComponents = Calendar.current.dateComponents([.hour, .minute], from: notificationTimeAll )

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
                        }
                    }
                    .onAppear {
                        settingDefault.default_notify_time = notificationTimeAll
                    }
                   
                    .frame(width: 100)
                    .padding(.trailing)
                    .colorScheme(.dark)
                    
            }
            
            Stepper(value: $priorDayAll, in: 0...30, step: 1) {
                Text("Notify \(priorDayAll) Days In Advance")
                    .foregroundStyle(Color(hex: 0x535657))
                    .padding(.leading)
            }
                .onChange(of: priorDayAll){
//                    settingDefault.default_prior_day = priorDayAll
                    for item in items{
                        let selectedComponents = Calendar.current.dateComponents([.hour, .minute], from: item.notificationTime ?? settingDefault.default_notify_time )

                        // Combine expiration date with the selected time
                        var calculatedNotificationDate = Calendar.current.date(bySettingHour: selectedComponents.hour ?? 0, minute: selectedComponents.minute ?? 0, second: 0, of: item.expirationDate ?? Date())

                        // Subtract daysPrior days from the calculated date
                        calculatedNotificationDate = Calendar.current.date(byAdding: .day, value: -priorDayAll, to: calculatedNotificationDate ?? Date())

                        // Update the item's notification time
                        item.notificationTime = calculatedNotificationDate

                        if item.isNotificationEnabled {
                            removeScheduledNotification(for: item)
                            scheduleNotification(for: item)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .colorScheme(.light)
            
//            if settingDefault.default_enable_notify{
//                Text("Notify \(settingDefault.default_prior_day) Days Prior to Expiration\n\(settingDefault.default_notify_time)\n is enabled")
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .foregroundColor(Color(hex: 0x535657))
//            }
//            else{
//                Text("Notify \(settingDefault.default_prior_day) Days Prior to Expiration\n\(settingDefault.default_notify_time)\n is not enabled")
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .foregroundColor(Color(hex: 0x535657))
//            }
                               
            Spacer()
        }
        .background(Color(hex: 0xdee7e7))
        .onAppear{
            settingDefault.loadSettings()
            self.notificationTimeDef=settingDefault.default_notify_time
//            self.notificationTimeAll=settingDefault.default_notify_time
            
        }
        .onDisappear{
            settingDefault.saveSettings()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)){ _ in
            settingDefault.saveSettings()
        }


    }
    
    private func scheduleNotification(for item: Item) {
        print("setting schedule")
        
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
    
    private func formattedTime(for date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"  // Use "hh:mm a" for 12-hour format
        return dateFormatter.string(from: date)
    }

}
