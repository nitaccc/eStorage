import SwiftUI
import UserNotifications

@main

struct e2App: App {
    var settings = SettingDefault()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(settings)
                .onAppear(perform: {
                    let defaults = UserDefaults.standard
                    if defaults.bool(forKey: "NotificationPermissionRequested") == false {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                            if granted {
                                print("Notification authorization granted")
                                defaults.set(true, forKey: "NotificationPermissionRequested")
                            } else {
                                print("Notification authorization denied")
                            }
                        }
                    }
                })
        }
    }
}

