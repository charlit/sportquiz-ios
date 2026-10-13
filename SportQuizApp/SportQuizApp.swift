import SwiftUI
import UIKit
import UserNotifications

@main
struct SportQuizApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Raccourcis de l'icône (appui long sur l'écran d'accueil) : Spécial Foot, Hardcore, Aventure, Classement.
// Définis dans Info.plist (UIApplicationShortcutItems) ; l'action est transmise à la page par QuizWebView.
enum Shortcuts {
    static let received = Notification.Name("QuizShortcut")
    static var pending: String?

    static func handle(_ item: UIApplicationShortcutItem) {
        pending = item.type.components(separatedBy: ".").last
        NotificationCenter.default.post(name: received, object: nil)
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NSUbiquitousKeyValueStore.default.synchronize()   // va chercher la progression iCloud au plus tôt
        return true
    }

    // Appui sur un rappel : ouvre le défi de la semaine ou les avant-matchs (même chemin que les raccourcis)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let action = response.notification.request.content.userInfo["action"] as? String, !action.isEmpty else { return }
        await MainActor.run {
            Shortcuts.pending = action
            NotificationCenter.default.post(name: Shortcuts.received, object: nil)
        }
    }

    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let item = options.shortcutItem { Shortcuts.handle(item) }   // app lancée par un raccourci
        let config = UISceneConfiguration(name: nil, sessionRole: session.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    // app déjà ouverte en arrière-plan
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        Shortcuts.handle(shortcutItem)
        completionHandler(true)
    }
}
