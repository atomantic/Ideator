import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == "daily-prompt" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .dailyPromptTriggered, object: nil)
            }
        }
        completionHandler()
    }
}

extension Notification.Name {
    static let dailyPromptTriggered = Notification.Name("dailyPromptTriggered")
    static let promptsReloaded = Notification.Name("promptsReloaded")
}
